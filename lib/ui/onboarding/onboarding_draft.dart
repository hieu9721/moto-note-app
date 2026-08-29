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
import '../../domain/catalog.dart';
import '../../domain/id.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/oil_presets.dart';

class OnboardingDraft {
  VehicleType? type;
  String? name;
  String? plate;
  int? currentOdoKm;
  double? avgDailyKm;
  Set<String> selectedCodes = {};
  OilGrade? oilGrade;

  /// Maps [selectedCodes] through `kCatalog` to `MaintenanceItem` rows.
  /// Per P2-D-05, codes NOT in [selectedCodes] produce no row at all — an
  /// unchecked catalog entry is never created, not even with
  /// `enabled: false`.
  ///
  /// Every selected item is seeded with a "không nhớ" baseline
  /// (§6.1's default for every non-oil item; plan 05 adds the
  /// engine-oil-only step-6 override): `lastServiceDate` is the commit
  /// timestamp, `lastServiceOdo` is the current ODO reading, and
  /// `baselineIsGuess` is true.
  List<MaintenanceItem> buildSelectedItems(String vehicleId) {
    final now = DateTime.now().toUtc();
    return kCatalog.where((entry) => selectedCodes.contains(entry.code)).map((
      entry,
    ) {
      // CAT-03: the engine-oil row's interval is REPLACED by the
      // selected grade's preset, never accumulated — always derived
      // from the current [oilGrade], not the catalog entry's defaults.
      final isEngineOilWithGrade =
          entry.code == 'engine_oil' && oilGrade != null;
      final preset = isEngineOilWithGrade ? kOilPresets[oilGrade] : null;
      return MaintenanceItem(
        id: newId(),
        vehicleId: vehicleId,
        catalogCode: entry.code,
        name: entry.nameVi,
        intervalKm: preset?.km ?? entry.intervalKm,
        intervalMonths: preset?.months ?? entry.intervalMonths,
        enabled: true,
        lastServiceOdo: currentOdoKm,
        lastServiceDate: now,
        baselineIsGuess: true,
        oilGrade: entry.code == 'engine_oil' ? oilGrade : null,
      );
    }).toList();
  }
}
