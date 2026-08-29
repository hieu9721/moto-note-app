// lib/ui/onboarding/onboarding_draft.dart — plain mutable Dart class, never
// Freezed, never serialised, never a Riverpod provider (02-RESEARCH.md
// Pattern 2 and its Anti-Patterns list). `OnboardingFlow` owns exactly one
// instance and mutates its fields via `setState`; nothing here reaches disk
// until `AppNotifier.completeOnboarding` runs its single `_mutate` call.
//
// The full field set is declared now so later plans (02, 05) only fill in
// UI for fields this plan already reserves.
import '../../domain/catalog.dart';
import '../../domain/id.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/vehicle.dart';

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
    return kCatalog
        .where((entry) => selectedCodes.contains(entry.code))
        .map(
          (entry) => MaintenanceItem(
            id: newId(),
            vehicleId: vehicleId,
            catalogCode: entry.code,
            name: entry.nameVi,
            intervalKm: entry.intervalKm,
            intervalMonths: entry.intervalMonths,
            enabled: true,
            lastServiceOdo: currentOdoKm,
            lastServiceDate: now,
            baselineIsGuess: true,
          ),
        )
        .toList();
  }
}
