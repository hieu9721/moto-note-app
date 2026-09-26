// lib/domain/odo.dart — pure Dart (D-31); this directory must never import
// the Flutter SDK.
//
// §9.1's estimation formula, extracted as a standalone function instead of
// staying inlined only inside computeDue (02-RESEARCH.md Pattern 3). Phase
// 3's home header and Phase 4's monthly reminder both need this same
// number, so it is exported here once rather than re-derived at each call
// site.
//
// Pitfall 3 (02-RESEARCH.md): refineAvgDailyKm's day-delta deliberately
// uses raw, truncating `.inDays` — unlike due.dart's `daysLeft`, which
// normalises through `_dateOnly` first. Do not "fix" this into consistency
// with due.dart; the two functions have different tolerance for a single
// day of truncation error. `computeDue`'s `daysLeft` drives single-day
// status transitions, where a 23-hour gap truncating to "0 days" is a
// real, user-visible bug (that is exactly what due.dart's own truncation
// guard exists to prevent). `refineAvgDailyKm` only runs once its own
// `days < 14` guard has passed, so at most one day of truncation moves
// `measured` by ~7% — well inside the 70/30 smoothing's tolerance. Do not
// "fix" this function into consistency with due.dart by adding a
// normalisation step here (see 02-RESEARCH.md Pitfall 3 for the full
// rationale).
import 'models/app_data.dart';
import 'models/misc.dart';
import 'models/vehicle.dart';

/// §9.1: odoƯớcTính = odoLầnNhậpCuối + kmMỗiNgày × sốNgàyTừLầnNhậpCuối.
///
/// `now` defaults to `DateTime.now().toUtc()`, not bare `DateTime.now()` —
/// Phase 1 stores every persisted wall-clock timestamp in UTC
/// (app_data.dart:40, app_state.dart:158); comparing a local `now` against a
/// UTC `odoUpdatedAt` would reintroduce an off-by-a-day error near midnight
/// (02-RESEARCH.md Pitfall 2).
int estimateOdo(Vehicle vehicle, {DateTime? now}) {
  final n = now ?? DateTime.now().toUtc();
  final avg = vehicle.avgDailyKm <= 0 ? 0.5 : vehicle.avgDailyKm;
  final daysSinceOdo = n.difference(vehicle.odoUpdatedAt).inDays;
  return vehicle.currentOdoKm + (avg * daysSinceOdo).round();
}

/// §9.2's return value: the refined average and where it came from. A plain
/// `const` class — never Freezed, never serialized on its own (the values
/// it carries land on `Vehicle.avgDailyKm`/`avgDailyKmSource`, which are).
class RefinedAvg {
  final double avgDailyKm;
  final AvgKmSource source;
  const RefinedAvg(this.avgDailyKm, this.source);
}

/// §9.2, transcribed line for line. Five behaviours, in the source's own
/// order:
///
/// 1. No previous reading to compare against → return the vehicle's current
///    average and source, unchanged (not a default, not computed).
/// 2. `days`/`km` are the raw deltas between the two readings — `days` uses
///    the truncating `.inDays` deliberately, see the file header comment.
/// 3. Too short an interval, or the odometer went backwards → same as (1),
///    unchanged.
/// 4. `measured = km / days`. A `user`-sourced average (a rough onboarding
///    declaration, P2-D-06) is REPLACED outright by the first real
///    measurement — no blending — because P2-D-10 depends on that exact
///    behaviour to make Phase 6's offline error measurement reconstructible
///    from the `OdoReading` list alone. Every later measurement instead
///    smooths 70% measured / 30% previous.
/// 5. The smoothed result is clamped to `[0.5, 400]` and stamped `computed`.
///    This clamp is a defensive floor on a MEASURED value — never a
///    substitute for validating what a user typed at entry (that
///    validation is P2-D-08's `[0.5, 400]` UI-level check, a separate
///    concern from this internal safety clamp).
RefinedAvg refineAvgDailyKm(
  Vehicle vehicle,
  OdoReading newReading,
  OdoReading? prevReading,
) {
  if (prevReading == null) {
    return RefinedAvg(vehicle.avgDailyKm, vehicle.avgDailyKmSource);
  }

  final days = newReading.date.difference(prevReading.date).inDays;
  final km = newReading.odoKm - prevReading.odoKm;

  if (days < 14 || km < 0) {
    return RefinedAvg(vehicle.avgDailyKm, vehicle.avgDailyKmSource);
  }

  final measured = km / days;

  final smoothed = vehicle.avgDailyKmSource == AvgKmSource.user
      ? measured
      : 0.7 * measured + 0.3 * vehicle.avgDailyKm;

  return RefinedAvg(smoothed.clamp(0.5, 400).toDouble(), AvgKmSource.computed);
}

/// §5.2 calls this but never defines it. Returns the most recent
/// [OdoReading] for [vehicleId] by `date` — not by list position, since a
/// service-sourced reading can be appended out of order — or `null` when
/// there is none yet.
OdoReading? latestReadingFor(AppData data, String vehicleId) {
  OdoReading? latest;
  for (final reading in data.odoReadings) {
    if (reading.vehicleId != vehicleId) continue;
    if (latest == null || reading.date.isAfter(latest.date)) {
      latest = reading;
    }
  }
  return latest;
}
