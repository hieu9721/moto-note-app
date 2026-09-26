// lib/ui/settings/garage_screen.dart — 06-05 (SET-01, P6-D-06). The vehicle
// list every add/delete/switch action funnels through: one `ListTile` per
// vehicle, a trailing delete button that only ever opens a confirmation
// (never destroys on its own), and the FAB that reaches 06-02's
// `/onboarding/add-vehicle` route. This screen is D-33's second `7+3`
// exception (P6-D-26) — reachable only from Cài đặt, no new top-level
// navigation entry.
//
// This screen's vehicle list is structurally never empty: the router's own
// redirect (`lib/ui/router.dart`) guarantees at least one vehicle before any
// Settings sub-screen can build, so there is no empty-state branch here
// (`06-UI-SPEC.md` P1 empty).
//
// The row itself is `VehicleRow`, shared with the vehicle-switcher sheet
// (`lib/ui/home/vehicle_switcher_sheet.dart`) — one implementation, so the
// two surfaces can never render a vehicle differently. This screen passes
// its trailing delete `IconButton` in; the sheet passes none.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/vehicle.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../home/vehicle_switcher_sheet.dart' show VehicleRow;

// [NEW, PROVISIONAL] — 06-UI-SPEC.md Copywriting Contract, no verbatim
// source string exists for either. Recorded verbatim in 06-05-SUMMARY.md.
const _switchedSnackBarPrefix = 'Đã chuyển sang ';
const _deletedSnackBarPrefix = 'Đã xoá ';
// CR-03: a fixed mapped Vietnamese constant, never an interpolated
// exception — the same discipline every other mutation failure path in this
// codebase already follows.
const _deleteFailureMessage = 'Không thể xoá xe. Vui lòng thử lại.';

/// `home_screen.dart`'s existing empty-name fallback, reused verbatim rather
/// than inventing a second fallback string for this screen.
String _displayName(Vehicle vehicle) =>
    vehicle.name.isEmpty ? 'Xe của bạn' : vehicle.name;

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  // Re-entrancy guard (06-UI-SPEC.md P1 destructive): a vehicle id currently
  // mid-delete has its trailing delete button suppressed entirely, so a
  // double tap cannot fire the mutation twice — the same discipline
  // `_UndoRestoreRow`'s tap-guard already uses elsewhere in Settings.
  final Set<String> _deletingIds = {};

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final vehicles = data.vehicles;
    final selected = ref.watch(selectedVehicleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý xe')),
      body: SafeArea(
        child: ListView(
          // 96 = 2 × 2xl, sized to clear the FAB — the same bottom padding
          // `home_screen.dart`'s own ListView already uses (H1 overflow
          // precedent).
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
          children: [
            for (final vehicle in vehicles)
              _buildRow(
                context,
                vehicle,
                selected != null && vehicle.id == selected.id,
                colorScheme,
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Thêm xe'),
        onPressed: () => context.push('/onboarding/add-vehicle'),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    Vehicle vehicle,
    bool selected,
    ColorScheme colorScheme,
  ) {
    final deleting = _deletingIds.contains(vehicle.id);
    return VehicleRow(
      vehicle: vehicle,
      selected: selected,
      // Tapping the already-selected row's body is a no-op — never a way to
      // "unselect" a vehicle, since exactly one is always selected by
      // construction.
      onTap: selected ? null : () => _onRowTap(context, vehicle),
      trailing: deleting
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xoá xe',
              color: colorScheme.error,
              onPressed: () => _onDeleteTap(context, vehicle),
            ),
    );
  }

  Future<void> _onRowTap(BuildContext context, Vehicle vehicle) async {
    await ref
        .read(appProvider.notifier)
        .updateSettings((s) => s.copyWith(selectedVehicleId: vehicle.id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_switchedSnackBarPrefix${_displayName(vehicle)}'),
      ),
    );
  }

  Future<void> _onDeleteTap(BuildContext context, Vehicle vehicle) async {
    // Counts computed with the SAME predicates `applyVehicleDeletion` uses
    // (lib/domain/vehicle_cascade.dart) — a dialog that undercounts what it
    // is about to destroy is worse than no dialog at all.
    final data = ref.read(appProvider);
    final itemCount = data.items.where((i) => i.vehicleId == vehicle.id).length;
    final logCount = data.logs.where((l) => l.vehicleId == vehicle.id).length;
    final noteCount = data.notes.where((n) => n.vehicleId == vehicle.id).length;
    final odoCount = data.odoReadings
        .where((o) => o.vehicleId == vehicle.id)
        .length;
    final isLastVehicle = data.vehicles.length == 1;

    final confirmed = await _confirmDeleteVehicle(
      context,
      vehicleName: _displayName(vehicle),
      itemCount: itemCount,
      logCount: logCount,
      noteCount: noteCount,
      odoReadingCount: odoCount,
      isLastVehicle: isLastVehicle,
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    setState(() => _deletingIds.add(vehicle.id));
    try {
      // P6-D-13: no navigation call from here even on the last-vehicle case
      // — the router's own redirect carries the user to /onboarding the
      // instant vehicles.isEmpty becomes true.
      await ref.read(appProvider.notifier).deleteVehicle(vehicle.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_deletedSnackBarPrefix${_displayName(vehicle)}'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_deleteFailureMessage)));
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(vehicle.id));
      }
    }
  }
}

/// P6-D-06's confirmation, `[NEW, PROVISIONAL]` — `06-UI-SPEC.md`'s
/// Copywriting Contract → "Destructive confirmation" → delete one vehicle
/// row, quoted verbatim. Follows `confirmOdometerReplaced`'s exact
/// `showDialog<bool>` + `AlertDialog` + `FilledButton(colorScheme.error)`
/// shape (`lib/ui/widgets/odometer_confirm_dialog.dart`).
Future<bool?> _confirmDeleteVehicle(
  BuildContext context, {
  required String vehicleName,
  required int itemCount,
  required int logCount,
  required int noteCount,
  required int odoReadingCount,
  required bool isLastVehicle,
}) {
  final body = StringBuffer()
    ..write(
      '$itemCount hạng mục, $logCount lần bảo dưỡng, $noteCount ghi chú và '
      '$odoReadingCount lần cập nhật số km của xe này sẽ bị xoá. ',
    )
    ..write('Không thể hoàn tác.');
  if (isLastVehicle) {
    body.write(' Sau khi xoá, bạn sẽ quay lại màn hình thiết lập xe.');
  }
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Xoá $vehicleName?'),
      content: Text(body.toString()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Xoá'),
        ),
      ],
    ),
  );
}
