// lib/domain/item_seed.dart — Phase 6 (SET-01, P6-D-07/P6-D-09). Pure Dart
// (D-31) — this directory must never import the Flutter SDK.
//
// This is §6.1's "không nhớ" (don't-remember) baseline — the same default
// `OnboardingDraft.buildSelectedItems` (lib/state/onboarding_draft.dart)
// already applies to every non-oil item it creates at onboarding time —
// extracted here as a standalone, testable function so
// lib/ui/settings/item_management_screen.dart can seed a `MaintenanceItem`
// for a catalog entry the user enables AFTER onboarding, not only during
// it.
//
// Why this matters: a catalog entry enabled with no baseline on either
// axis (`lastServiceOdo == null && lastServiceDate == null`) makes
// `computeDue` (lib/domain/due.dart) return null for it forever — the item
// renders as on, produces no due card and schedules no notification, with
// nothing anywhere reporting a problem. Without this function, turning the
// switch on in the item-management screen would silently create exactly
// that item. See 06-06-PLAN.md's threat T-06-06-02.
//
// Deliberately does NOT touch lib/state/onboarding_draft.dart —
// `buildSelectedItems` carries onboarding's CAT-03 oil-preset branch and
// its §6.1 day-offset arithmetic, both UAT'd behaviour from Phase 2;
// folding them together here would be a change to shipped onboarding for
// no requirement this phase asks for. The resulting duplication (the
// "không nhớ" baseline fields exist in both places) is filed to
// BACKLOG.md — see 06-06-SUMMARY.md for the assigned BL-NN id.
import 'catalog.dart';
import 'id.dart';
import 'models/maintenance_item.dart';
import 'models/vehicle.dart';

/// Builds a [MaintenanceItem] for [entry] against [vehicle], seeded exactly
/// like onboarding's "không nhớ" default: `lastServiceDate` is [now] (or
/// the current UTC instant when omitted), `lastServiceOdo` is the
/// vehicle's current odometer reading, `baselineIsGuess` is always true,
/// and the intervals come from the catalog entry's own defaults, never a
/// hardcoded pair.
///
/// `oilGrade` is deliberately left null here, even for `engine_oil` —
/// flagged assumption 1 in 06-06-PLAN.md: onboarding applies
/// `kOilPresets[oilGrade]` instead of the catalog defaults for that one
/// code, but oil grade is a property of the item, which does not exist yet
/// at the moment it is being seeded. The item's grade and intervals both
/// stay editable afterwards through the item-management screen.
MaintenanceItem seedMaintenanceItem(
  CatalogEntry entry,
  Vehicle vehicle, {
  DateTime? now,
}) {
  final seededAt = now ?? DateTime.now().toUtc();
  return MaintenanceItem(
    id: newId(),
    vehicleId: vehicle.id,
    catalogCode: entry.code,
    name: entry.nameVi,
    intervalKm: entry.intervalKm,
    intervalMonths: entry.intervalMonths,
    enabled: true,
    lastServiceOdo: vehicle.currentOdoKm,
    lastServiceDate: seededAt,
    baselineIsGuess: true,
    oilGrade: null,
  );
}
