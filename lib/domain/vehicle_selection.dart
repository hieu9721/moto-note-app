// lib/domain/vehicle_selection.dart — 06-01 (P6-D-01/P6-D-02/P6-D-03). Pure
// Dart (D-31) — this file must never import the Flutter SDK.
//
// Exports the ONE function permitted to decide "the current vehicle" in this
// codebase. Every other file — Trang chủ, the ODO deep link, the garage
// screen, the switcher — reads through this function or through
// `lib/state/derived.dart`'s `selectedVehicleProvider`, which is a one-line
// delegation to it. No call site outside this file may index
// `AppData.vehicles.first` as its own shortcut for "the current vehicle" —
// that duplication is exactly how the plural refactor would silently
// regress to singular.
//
// Resolution rule, in order:
//   1. If `data.settings.selectedVehicleId` is non-null, look it up in
//      `data.vehicles` (the nullable-loop idiom this codebase already uses —
//      see `item_detail_screen.dart`'s `_findVehicle`) and return the match
//      if there is one.
//   2. Otherwise — no selection recorded, or a selection that no longer
//      resolves — fall back to the first vehicle in `data.vehicles`, if the
//      list is non-empty. This is the NORMALISATION RULE for an unset or
//      stale selection, reached by every pre-Phase-6 document (which has
//      never written `selectedVehicleId`), every Drive restore of one, and
//      the single frame between a vehicle deletion and the router's
//      redirect. This file is the one place in `lib/` permitted to resolve
//      "the first vehicle" for exactly this reason.
//   3. Otherwise — an empty vehicle list — return null. Never throws, for
//      any input, including an empty document.
import 'models/app_data.dart';
import 'models/vehicle.dart';

/// Resolves [data] to the single vehicle every screen reading "the current
/// vehicle" should render. See the file header for the exact resolution
/// rule. Returns the same [Vehicle] instance held by [data.vehicles] — a
/// caller may rely on identity, not just equality.
Vehicle? selectedVehicle(AppData data) {
  final selectedId = data.settings.selectedVehicleId;
  if (selectedId != null) {
    for (final v in data.vehicles) {
      if (v.id == selectedId) return v;
    }
  }
  if (data.vehicles.isNotEmpty) return data.vehicles.first;
  return null;
}
