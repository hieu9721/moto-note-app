// lib/domain/vehicle_cascade.dart — 06-02 (P6-D-06/P6-D-25). Pure Dart —
// this file must never import the Flutter SDK.
//
// Exports the single source of truth for what "deleting a vehicle" means in
// this codebase. `AppNotifier.deleteVehicle` (lib/state/app_state.dart) is a
// one-line `_mutate` wrapper around `applyVehicleDeletion` below — the
// cascade rules live here, in a pure function, precisely so they are
// `dart test`-reachable under D-31 rather than buried inside the notifier
// (P6-D-25's own reversibility note).
//
// What deleting a vehicle removes, in one `copyWith`:
//   - the `Vehicle` itself, from `AppData.vehicles`;
//   - every `MaintenanceItem`, `ServiceLog` and `OdoReading` whose
//     `vehicleId` equals the deleted id;
//   - every `Note` whose `vehicleId` equals the deleted id — but NEVER a
//     `Note` whose `vehicleId` is null. A vehicle-less note belongs to the
//     user, not to any bike (`Note.vehicleId` is nullable by design,
//     confirmed against `lib/domain/models/misc.dart`), and the filter below
//     is an explicit equality check a null can never satisfy.
//   - `Settings.selectedVehicleId` is re-pointed in the same write: if it
//     named the deleted vehicle, it becomes the first remaining vehicle's id
//     when any vehicle remains, and null when none does. If it names some
//     other vehicle, it is left exactly as it is.
//
// What this function deliberately does NOT do: touch the filesystem. It is
// pure and takes no filesystem-package dependency, so receipt-photo *files* on disk
// (`ServiceLog.photoPaths`, `Vehicle.photoPath`) are NOT swept by a
// per-vehicle delete — SET-03's delete-all-data owns bulk file removal, and
// a per-vehicle photo sweep is not in P6-D-06's list. The caller
// (`AppNotifier.deleteVehicle`, via `_mutate`) is responsible for
// rescheduling notifications after a successful save — `_mutate` already
// does this for every mutation, so nothing extra is needed here.
//
// An id that matches no vehicle is an honest no-op: this function returns
// `current` unchanged, matching `addOdoReading`/`addServiceLog`'s
// established `indexWhere == -1 → return current` idiom elsewhere in this
// codebase.
import 'models/app_data.dart';

/// Returns a new [AppData] with [vehicleId] and everything that belongs to
/// it removed. See the file header for the exact cascade rules. If
/// [vehicleId] matches no vehicle in `current.vehicles`, returns [current]
/// unchanged.
AppData applyVehicleDeletion(AppData current, String vehicleId) {
  final stillExists = current.vehicles.any((v) => v.id == vehicleId);
  if (!stillExists) return current; // unknown id: honest no-op

  final vehicles = current.vehicles.where((v) => v.id != vehicleId).toList();
  final items = current.items.where((i) => i.vehicleId != vehicleId).toList();
  final logs = current.logs.where((l) => l.vehicleId != vehicleId).toList();
  final odoReadings = current.odoReadings
      .where((o) => o.vehicleId != vehicleId)
      .toList();
  // Only a note whose vehicleId EQUALS the deleted id is removed — a null
  // vehicleId can never satisfy `== vehicleId`, so vehicle-less notes always
  // survive.
  final notes = current.notes.where((n) => n.vehicleId != vehicleId).toList();

  final selectedVehicleId = current.settings.selectedVehicleId;
  final settings = selectedVehicleId == vehicleId
      ? current.settings.copyWith(
          selectedVehicleId: vehicles.isNotEmpty ? vehicles.first.id : null,
        )
      : current.settings;

  return current.copyWith(
    vehicles: vehicles,
    items: items,
    logs: logs,
    odoReadings: odoReadings,
    notes: notes,
    settings: settings,
  );
}
