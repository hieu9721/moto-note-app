// lib/ui/settings/item_management_screen.dart — 06-06 (SET-01, P6-D-08/
// P6-D-09). The screen `06-05`'s `Quản lý hạng mục` Settings row targets —
// one `ExpansionTile` per applicable catalog entry, a per-item enable
// switch, and both due-axis intervals always editable, behind the §15 R9
// caveat that these are general recommendations, not the manufacturer's own
// numbers.
//
// This screen is D-33's 7+3 exception (P6-D-26), reachable only from Cài
// đặt — see `06-05-SUMMARY.md`'s "Checkpoint Decision" section for the full
// amendment text.
//
// This screen's row list is structurally never empty for a healthy
// document: the router's own redirect guarantees at least one vehicle
// before any Settings sub-screen can build (06-UI-SPEC.md P3 zero-one-many),
// so there is no empty-state branch here — same reasoning garage_screen.dart
// already documents for its own list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/vehicle.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../catalog_icons.dart';

// [NEW, PROVISIONAL] strings — no verbatim source string exists for any of
// these except the caveat (sourced below); recorded verbatim in
// 06-06-SUMMARY.md for harvest into 06-UAT.md.
//
// The §15 R9 caveat, rendered per 06-UI-SPEC.md's own resolution of
// motonote-v3-flutter.md:2097 — two deliberate differences from the source
// line are recorded in 06-06-SUMMARY.md (dropped developer instruction,
// sentence-cased opening word). Do not reword, retranslate, reflow or
// shorten this string, and it must never repeat inside a per-item
// expansion below (P6-D-08: once, at the top, only).
const _caveatText =
    'Đây là khoảng khuyến nghị chung cho điều kiện sử dụng đô thị. Chạy nội đô kẹt xe, ngập nước, chở nặng thì rút ngắn. Sổ tay theo xe của hãng vẫn là căn cứ chính xác nhất.';
const _noBaselineCaption =
    'Chưa có mốc — sẽ bắt đầu nhắc sau khi bạn ghi lần thay đầu tiên.';
const _kmLabel = 'Chu kỳ (km)';
const _monthsLabel = 'Chu kỳ (tháng)';
// CR-03: a fixed mapped Vietnamese constant, never an interpolated
// exception — the same discipline every other mutation failure path in
// this codebase already follows.
const _updateFailureMessage = 'Không thể lưu thay đổi. Vui lòng thử lại.';

class ItemManagementScreen extends ConsumerWidget {
  const ItemManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(selectedVehicleProvider);
    if (vehicle == null) {
      // The router's redirect never lets a Settings sub-screen build
      // without a vehicle — this is a defensive no-op for the one frame
      // that could theoretically race it, mirroring home_screen.dart's
      // identical guard.
      return const Scaffold(body: SizedBox.shrink());
    }

    final items = ref.watch(appProvider).items;
    final colorScheme = Theme.of(context).colorScheme;
    // Kept exactly in kCatalog's declaration order, never reordered and
    // never re-grouped — the vehicle's own applicable subset
    // (06-UI-SPEC.md Per-Screen Contract item D).
    final entries = catalogFor(vehicle.type);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý hạng mục')),
      body: SafeArea(
        child: Column(
          children: [
            _CaveatBanner(colorScheme: colorScheme),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in entries)
                    _ItemRow(
                      entry: entry,
                      vehicle: vehicle,
                      item: _findItem(items, vehicle.id, entry.code),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nullable lookup, honest-no-op idiom this codebase uses throughout — see
/// `item_detail_screen.dart`'s `_findVehicle`.
MaintenanceItem? _findItem(
  List<MaintenanceItem> items,
  String vehicleId,
  String catalogCode,
) {
  for (final i in items) {
    if (i.vehicleId == vehicleId && i.catalogCode == catalogCode) return i;
  }
  return null;
}

class _CaveatBanner extends StatelessWidget {
  const _CaveatBanner({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHigh,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              _caveatText,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// One `ExpansionTile` per catalog entry. Stateful so it can own commit-on-
/// blur `TextEditingController`/`FocusNode` pairs for the two interval
/// fields — the fields must never write on every keystroke, only when
/// focus leaves them or the keyboard's Done action fires.
class _ItemRow extends ConsumerStatefulWidget {
  const _ItemRow({
    required this.entry,
    required this.vehicle,
    required this.item,
  });

  final CatalogEntry entry;
  final Vehicle vehicle;
  final MaintenanceItem? item;

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  late final TextEditingController _kmController;
  late final TextEditingController _monthsController;
  late final FocusNode _kmFocus;
  late final FocusNode _monthsFocus;

  static String _text(int? value) => value?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(text: _text(widget.item?.intervalKm));
    _monthsController = TextEditingController(
      text: _text(widget.item?.intervalMonths),
    );
    _kmFocus = FocusNode()..addListener(_handleKmFocusChange);
    _monthsFocus = FocusNode()..addListener(_handleMonthsFocusChange);
  }

  @override
  void didUpdateWidget(covariant _ItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync each controller from the persisted item whenever it changes
    // out from under this row (another commit landed elsewhere) — but
    // never while the user is mid-edit in that field, or a keystroke would
    // be clobbered by the rebuild.
    if (!_kmFocus.hasFocus) {
      final text = _text(widget.item?.intervalKm);
      if (_kmController.text != text) _kmController.text = text;
    }
    if (!_monthsFocus.hasFocus) {
      final text = _text(widget.item?.intervalMonths);
      if (_monthsController.text != text) _monthsController.text = text;
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    _monthsController.dispose();
    _kmFocus.dispose();
    _monthsFocus.dispose();
    super.dispose();
  }

  void _handleKmFocusChange() {
    if (!_kmFocus.hasFocus) _commit(isKm: true);
  }

  void _handleMonthsFocusChange() {
    if (!_monthsFocus.hasFocus) _commit(isKm: false);
  }

  /// Parses the just-blurred field via `int.tryParse` over its trimmed
  /// text (T-06-06-01): a blank field commits null — that axis is now
  /// unused for this item's due computation. An unparsable value (letters,
  /// a bare space) is IGNORED — the field snaps back to the last committed
  /// value and nothing is written; this is a validation omission, not a
  /// submit failure, so it raises no error. A value equal to what is
  /// already persisted skips the mutation rather than issuing a redundant
  /// write.
  Future<void> _commit({required bool isKm}) async {
    final item = widget.item;
    if (item == null) return; // guard: unreachable while collapsed/disabled

    final controller = isKm ? _kmController : _monthsController;
    final text = controller.text.trim();
    final current = isKm ? item.intervalKm : item.intervalMonths;

    int? next;
    if (text.isEmpty) {
      next = null;
    } else {
      final parsed = int.tryParse(text);
      if (parsed == null) {
        controller.text = _text(current); // unparsable: revert, no commit
        return;
      }
      next = parsed;
    }
    if (next == current) return; // no real change: skip a redundant write

    final km = isKm ? next : item.intervalKm;
    final months = isKm ? item.intervalMonths : next;
    try {
      await ref
          .read(appProvider.notifier)
          .updateItemIntervals(item.id, km, months);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_updateFailureMessage)));
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    try {
      await ref
          .read(appProvider.notifier)
          .setCatalogItemEnabled(widget.vehicle.id, widget.entry.code, value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_updateFailureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final enabled = item?.enabled ?? false;
    final title = item?.name ?? widget.entry.nameVi;
    final noBaseline =
        enabled &&
        item != null &&
        item.lastServiceOdo == null &&
        item.lastServiceDate == null;

    return ExpansionTile(
      leading: Icon(
        catalogIconFor(widget.entry.iconKey),
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      // [NEW, PROVISIONAL] — shown only when enabled with no baseline on
      // either axis (06-UI-SPEC.md Per-Screen Contract item D).
      subtitle: noBaseline
          ? Text(
              _noBaselineCaption,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      // Trailing carries the switch on its own tap target — tapping it
      // never also expands/collapses the row, the same "action control
      // outside the tappable area" discipline due_card.dart already uses.
      trailing: Switch(value: enabled, onChanged: _toggleEnabled),
      // Reachable only while the item exists and is enabled — a disabled
      // item cannot have its interval edited without first turning it on.
      children: enabled && item != null
          ? [_buildIntervalRow(context)]
          : const [],
    );
  }

  Widget _buildIntervalRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _kmController,
              focusNode: _kmFocus,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: _kmLabel),
              onEditingComplete: () => _kmFocus.unfocus(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _monthsController,
              focusNode: _monthsFocus,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: _monthsLabel),
              onEditingComplete: () => _monthsFocus.unfocus(),
            ),
          ),
        ],
      ),
    );
  }
}
