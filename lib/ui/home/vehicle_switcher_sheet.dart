// lib/ui/home/vehicle_switcher_sheet.dart — 06-05 (SET-01, P6-D-02). Two
// things live here: the shared vehicle-row widget the Garage screen
// (lib/ui/settings/garage_screen.dart) and this sheet both render — one
// implementation, so the omit-the-plate rule, the accent-on-selected rule
// and the unclamped title exist once — and the sheet itself, the AppBar
// action's answer to "which bike am I looking at" without opening anything.
//
// Deliberately no add-vehicle row here — adding is the Garage screen's own
// FAB action, and two competing add affordances would leave neither reading
// as "the" way (06-UI-SPEC.md Per-Screen Contract item B). A discretionary
// simplification flagged for UAT, not a locked requirement.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/vehicle.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';

// [NEW, PROVISIONAL] — 06-UI-SPEC.md Copywriting Contract, no verbatim
// source string exists for either. Recorded verbatim in 06-05-SUMMARY.md.
const _sheetTitle = 'Chọn xe';
const _manageRowTitle = 'Quản lý xe';

/// `home_screen.dart`'s existing empty-name fallback, reused verbatim so
/// this sheet and the Garage screen can never disagree on how an unnamed
/// vehicle reads.
String _displayName(Vehicle vehicle) =>
    vehicle.name.isEmpty ? 'Xe của bạn' : vehicle.name;

/// The shared row both the Garage screen and this sheet render — same
/// leading icon, same accent-on-selected rule, same name/plate text, same
/// unclamped title (no `maxLines`). The Garage screen passes its delete
/// `IconButton` as [trailing]; this sheet passes none.
class VehicleRow extends StatelessWidget {
  const VehicleRow({
    super.key,
    required this.vehicle,
    required this.selected,
    this.onTap,
    this.trailing,
  });

  final Vehicle vehicle;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final plate = vehicle.plate;
    return ListTile(
      leading: Icon(
        Icons.two_wheeler,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        _displayName(vehicle),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: (plate != null && plate.isNotEmpty) ? Text(plate) : null,
      trailing: trailing,
      // Tapping the already-selected row is a no-op — never a way to
      // "unselect" a vehicle, since exactly one is always selected by
      // construction.
      onTap: onTap,
    );
  }
}

/// Opens the vehicle switcher — mirrors `showOdoSheet`'s exact signature
/// shape (`lib/ui/home/odo_sheet.dart:37-48`) and the house
/// `isScrollControlled: true, useSafeArea: true` pattern every modal sheet
/// in this codebase already uses.
Future<void> showVehicleSwitcherSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _VehicleSwitcherSheetBody(),
  );
}

class _VehicleSwitcherSheetBody extends ConsumerWidget {
  const _VehicleSwitcherSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final selected = ref.watch(selectedVehicleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      // Mirrors `_DriveBackupPromptSheet`'s exact padding shape
      // (home_screen.dart) — the house pattern for a plain-content sheet.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            _sheetTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (final vehicle in data.vehicles)
            VehicleRow(
              vehicle: vehicle,
              selected: selected != null && vehicle.id == selected.id,
              onTap: selected != null && vehicle.id == selected.id
                  ? null
                  : () => _onSwitch(context, ref, vehicle),
            ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
            title: const Text(_manageRowTitle),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/settings/vehicles');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onSwitch(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    await ref
        .read(appProvider.notifier)
        .updateSettings((s) => s.copyWith(selectedVehicleId: vehicle.id));
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
