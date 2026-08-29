// lib/ui/onboarding/onboarding_draft.dart — plain mutable Dart class, never
// Freezed, never serialised, never a Riverpod provider (02-RESEARCH.md
// Pattern 2 and its Anti-Patterns list). `OnboardingFlow` owns exactly one
// instance and mutates its fields via `setState`; nothing here reaches disk
// until `AppNotifier.completeOnboarding` runs its single `_mutate` call.
//
// The full field set is declared now so later plans (02, 05) only fill in
// UI for fields this plan already reserves.
//
// CAT-03 (plan 02): when [oilGrade] is set, [buildSelectedItems] applies
// `kOilPresets[oilGrade]`'s km/months to the `engine_oil` row instead of
// the catalog entry's own 2000/3 defaults — the interval swap is applied
// here, at the single commit point, never by mutating the catalog or the
// draft mid-flow.
//
// §6.1 (plan 05): [lastOilChoice] drives the same commit-time application
// for the `engine_oil` row's `lastServiceDate`/`lastServiceOdo` baseline —
// asked for engine oil alone, never for any other selected item.
import '../../domain/catalog.dart';
import '../../domain/id.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/oil_presets.dart';

/// §6.1's four last-oil-change answers. `dontRemember` is also the safe
/// fallback [buildSelectedItems] applies when the user reaches the flow's
/// end without answering — silence, never a guessed reminder.
enum LastOilChoice { under1Month, oneToThreeMonths, over3Months, dontRemember }

/// §6.1's day-offset table, keyed by [LastOilChoice]. `null` for
/// [LastOilChoice.dontRemember] — that answer leaves the baseline at "now"
/// with no offset, not a zero-day offset (the distinction matters only as
/// documentation; the arithmetic already treats them identically).
int? _daysBackFor(LastOilChoice choice) => switch (choice) {
  LastOilChoice.under1Month => 15,
  LastOilChoice.oneToThreeMonths => 60,
  LastOilChoice.over3Months => 100,
  LastOilChoice.dontRemember => null,
};

class OnboardingDraft {
  VehicleType? type;
  String? name;
  String? plate;
  int? currentOdoKm;
  double? avgDailyKm;
  Set<String> selectedCodes = {};
  OilGrade? oilGrade;
  LastOilChoice? lastOilChoice;

  /// Maps [selectedCodes] through `kCatalog` to `MaintenanceItem` rows.
  /// Per P2-D-05, codes NOT in [selectedCodes] produce no row at all — an
  /// unchecked catalog entry is never created, not even with
  /// `enabled: false`.
  ///
  /// Every selected item is seeded with a "không nhớ" baseline by default
  /// (§6.1's default for every non-oil item): `lastServiceDate` is the
  /// commit timestamp, `lastServiceOdo` is the current ODO reading, and
  /// `baselineIsGuess` is true. The `engine_oil` row alone is overridden by
  /// [lastOilChoice] per the §6.1 table — asked for engine oil alone,
  /// because §6.1 is explicit that asking about every item is the fastest
  /// way to make someone abandon onboarding.
  List<MaintenanceItem> buildSelectedItems(String vehicleId) {
    final now = DateTime.now().toUtc();
    final choice = lastOilChoice ?? LastOilChoice.dontRemember;
    final odo = currentOdoKm ?? 0;
    final avg = avgDailyKm ?? 0.0;

    return kCatalog.where((entry) => selectedCodes.contains(entry.code)).map((
      entry,
    ) {
      // CAT-03: the engine-oil row's interval is REPLACED by the
      // selected grade's preset, never accumulated — always derived
      // from the current [oilGrade], not the catalog entry's defaults.
      final isEngineOilWithGrade =
          entry.code == 'engine_oil' && oilGrade != null;
      final preset = isEngineOilWithGrade ? kOilPresets[oilGrade] : null;

      // Default "không nhớ" baseline for every item.
      var lastServiceDate = now;
      var lastServiceOdo = odo;

      if (entry.code == 'engine_oil') {
        final daysBack = _daysBackFor(choice);
        if (daysBack != null) {
          lastServiceDate = now.subtract(Duration(days: daysBack));
          // §6.1: ODO − days × avgDailyKm, rounded to an int before
          // subtracting (lastServiceOdo is an int, avgDailyKm a double),
          // then floored at 0 — a nearly-new bike (ODO 500, 45 km/day,
          // "Trên 3 tháng") would otherwise get lastServiceOdo = -4000,
          // making kmLeft exceed the interval and progress negative, so
          // the item would silently never come due.
          final computedOdo = odo - (daysBack * avg).round();
          lastServiceOdo = computedOdo < 0 ? 0 : computedOdo;
        }
        // LastOilChoice.dontRemember: lastServiceDate/lastServiceOdo stay
        // at the "không nhớ" default already set above.
      }

      return MaintenanceItem(
        id: newId(),
        vehicleId: vehicleId,
        catalogCode: entry.code,
        name: entry.nameVi,
        intervalKm: preset?.km ?? entry.intervalKm,
        intervalMonths: preset?.months ?? entry.intervalMonths,
        enabled: true,
        lastServiceOdo: lastServiceOdo,
        lastServiceDate: lastServiceDate,
        baselineIsGuess: true,
        oilGrade: entry.code == 'engine_oil' ? oilGrade : null,
      );
    }).toList();
  }
}
