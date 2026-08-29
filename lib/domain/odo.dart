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
// day of truncation error (see 02-RESEARCH.md Pitfall 3 for the full
// rationale). `refineAvgDailyKm` itself is added by plan 03 — only
// `estimateOdo` is needed for this plan's tracer slice.
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
