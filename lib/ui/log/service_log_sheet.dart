// lib/ui/log/service_log_sheet.dart — the multi-item service-log modal
// sheet (LOG-01, LOG-04). One sheet records however many items were touched
// in a single workshop visit; ticking an item reveals its own brand, spec,
// cost and "Đã thay"/"Chỉ kiểm tra" toggle (P3-D-05/06/07). The sheet's own
// per-item ticked/text state stays private `StatefulWidget` state and is
// converted to the domain `ServiceLog`/`ServiceLogEntry` types only at "Lưu"
// time — never a draft type imported by `lib/state/` (03-RESEARCH.md
// Pattern 6). This is the one file in this phase most likely to recreate
// BL-01, the layering defect plan 02 just paid to remove.
//
// Scaffolding is deliberately NOT shared with `odo_sheet.dart` (Pitfall 3):
// this sheet takes real keyboard input and must track `MediaQuery.
// viewInsetsOf`, while the ODO sheet's self-drawn keypad never receives a
// keyboard at all.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/id.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/service_log.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/odo.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../widgets/formatters.dart';
import '../widgets/odometer_confirm_dialog.dart';

/// P3-D-05: opened from a due card's "[ Tôi vừa thay ]" action or the
/// item-detail screen's "[ Ghi lại ]" (plans 05/06) with [preTickedItemId]
/// set — or with no pre-ticked item at all. Never a `GoRoute`, matching
/// §11.2's own framing verbatim: "modal sheet, không phải màn hình".
Future<void> showServiceLogSheet(
  BuildContext context,
  WidgetRef ref, {
  required Vehicle vehicle,
  String? preTickedItemId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      // The load-bearing line entirely absent from the ODO sheet: this
      // sheet has real TextFields and a real keyboard, so its bottom must
      // track the keyboard (03-RESEARCH.md Pattern 5) rather than the fixed,
      // no-keyboard layout the ODO sheet uses.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ServiceLogForm(
          vehicle: vehicle,
          preTickedItemId: preTickedItemId,
        ),
      ),
    ),
  );
}

class ServiceLogForm extends ConsumerStatefulWidget {
  const ServiceLogForm({
    super.key,
    required this.vehicle,
    this.preTickedItemId,
  });

  final Vehicle vehicle;
  final String? preTickedItemId;

  @override
  ConsumerState<ServiceLogForm> createState() => _ServiceLogFormState();
}

class _ServiceLogFormState extends ConsumerState<ServiceLogForm> {
  // WR-03: matches step3_odo_avgkm.dart's own _maxOdo by name and value —
  // one bound, two enforcement points, not two unrelated magic numbers. An
  // extra typed digit turns 184200 into 1842000, and this sheet was the one
  // raw-odometer entry point with no digit-count cap of its own: the ODO
  // sheet caps at seven digits at the keypad, onboarding rejects at entry.
  static const int _maxOdo = 1000000;

  late final TextEditingController _dateController;
  late final TextEditingController _odoController;
  late final TextEditingController _shopController;
  late final TextEditingController _noteController;

  // Per-ticked-item state, keyed by item id (never twice) — private to this
  // widget, never exported, never imported by `lib/state/`. Converted to
  // `ServiceLogEntry` values only inside `_save` below.
  final Map<String, _ItemEntryDraft> _drafts = {};
  final Map<String, _ItemControllers> _controllers = {};

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: formatDate(DateTime.now()));
    _odoController = TextEditingController(
      text: formatKm(estimateOdo(widget.vehicle)),
    );
    _shopController = TextEditingController();
    _noteController = TextEditingController();

    final preTickedId = widget.preTickedItemId;
    if (preTickedId != null) {
      final dueItems = ref.read(dueItemsProvider(widget.vehicle.id));
      final source = _findItem(dueItems, preTickedId);
      if (source != null) _tickItem(source);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _odoController.dispose();
    _shopController.dispose();
    _noteController.dispose();
    // The sheet can be dismissed mid-entry (swipe, back gesture) and
    // Flutter does not warn about a leaked controller at compile time — only
    // a per-item controller set left un-disposed goes unnoticed until a
    // low-end device starts stuttering (03-RESEARCH.md Pattern 5).
    for (final controllers in _controllers.values) {
      controllers.dispose();
    }
    super.dispose();
  }

  MaintenanceItem? _findItem(List<DueItem> dueItems, String itemId) {
    for (final dueItem in dueItems) {
      if (dueItem.item.id == itemId) return dueItem.item;
    }
    return null;
  }

  // LOG-04: seeds the brand/spec controllers from the item's OWN fields —
  // never from the log history — so there is no ordering assumption to get
  // wrong.
  void _tickItem(MaintenanceItem item) {
    final controllers = _ItemControllers();
    controllers.brand.text = item.partBrand ?? '';
    controllers.spec.text = item.partSpec ?? '';
    _drafts[item.id] = _ItemEntryDraft();
    _controllers[item.id] = controllers;
  }

  void _untickItem(String itemId) {
    _drafts.remove(itemId);
    _controllers.remove(itemId)?.dispose();
  }

  void _toggleItem(MaintenanceItem item, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _tickItem(item);
      } else {
        _untickItem(item.id);
      }
    });
  }

  int? _parseIntField(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return int.tryParse(digitsOnly);
  }

  // "Ngày" stays a plain text field, not a calendar picker (§8.4's own
  // mockup draws it that way) — parsed by hand so this file never needs its
  // own `intl` import; `lib/ui/widgets/formatters.dart` is the one file in
  // `lib/ui/` that owns it.
  DateTime? _parseDateField(String raw) {
    final parts = raw.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    // DateTime's constructor rolls an out-of-range day/month forward rather
    // than rejecting it (e.g. 31/02 silently becomes 03/03) — reject that
    // "fixed" value rather than saving a date the user never typed.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  int _totalCostSoFar() {
    var total = 0;
    for (final itemId in _drafts.keys) {
      final controllers = _controllers[itemId];
      if (controllers == null) continue;
      total += _parseIntField(controllers.cost.text) ?? 0;
    }
    return total;
  }

  Future<void> _save() async {
    final parsedDate = _parseDateField(_dateController.text);
    final parsedOdo = _parseIntField(_odoController.text);
    if (parsedDate == null || parsedOdo == null || parsedOdo <= 0) {
      // Reject a non-positive or unparseable "Số km" here rather than
      // silently sending zero/garbage into refineAvgDailyKm.
      setState(() {
        _error = 'Không thể lưu lịch sử bảo dưỡng. Vui lòng thử lại.';
      });
      return;
    }

    // WR-03: its own branch, its own message. An out-of-range value must
    // never disappear into the generic save-failure text above — that tells
    // the user nothing about what to change. Reused byte-for-byte from
    // step3_odo_avgkm.dart:107 (en dash, not a hyphen) so both entry points
    // read identically. Strictly greater than, so 1.000.000 itself is
    // accepted, matching onboarding's own test. Never clamped — an
    // out-of-range figure is rejected visibly and re-typed, never silently
    // coerced into the accepted band.
    if (parsedOdo > _maxOdo) {
      setState(() {
        _error = 'Số km không hợp lệ (0 – 1.000.000).';
      });
      return;
    }

    // CR-01 / P3-D-10 / P3-D-12: this same parsedOdo reaches
    // Vehicle.currentOdoKm and, for any resetsCycle: true entry below,
    // MaintenanceItem.lastServiceOdo — from which the km-axis due date is
    // computed as lastServiceOdo + intervalKm (lib/domain/due.dart). A low
    // typo here does not produce a wrong display; it produces a due date
    // pushed into the future with nothing on screen to say so. Compared
    // against the real last reading (never estimateOdo, never the nullable
    // latestReadingFor), strictly, so a value exactly equal to the current
    // reading — a same-day visit with no riding since — is never
    // interrogated. Shares the exact confirmation odo_sheet.dart uses so the
    // two write paths cannot disagree on wording.
    if (parsedOdo < widget.vehicle.currentOdoKm) {
      final confirmed = await confirmOdometerReplaced(
        context,
        previousKm: widget.vehicle.currentOdoKm,
      );
      // CLAUDE.md trap: BuildContext/State used after an await. The sheet
      // can be disposed while the confirmation is open.
      if (!mounted) return;
      // Declining is a complete no-op: no error, no state change, every
      // ticked item and every typed field stays exactly as the user left
      // it. Cancelling is a correction opportunity, not a failure.
      if (confirmed != true) return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final dueItems = ref.read(dueItemsProvider(widget.vehicle.id));
      final entries = <ServiceLogEntry>[];
      for (final dueItem in dueItems) {
        final draft = _drafts[dueItem.item.id];
        if (draft == null) continue;
        final controllers = _controllers[dueItem.item.id]!;
        final brandText = controllers.brand.text.trim();
        final specText = controllers.spec.text.trim();
        entries.add(
          ServiceLogEntry(
            itemId: dueItem.item.id,
            costVnd: _parseIntField(controllers.cost.text),
            partBrand: brandText.isEmpty ? null : brandText,
            partSpec: specText.isEmpty ? null : specText,
            resetsCycle: draft.resetsCycle,
          ),
        );
      }

      // WR-04: the loop above walks dueItems (its shipped order, per
      // 03-04's must_haves — NOT switched to _drafts.keys, which would
      // reorder entries by tick sequence) and skips any item without a
      // matching draft. entries and _drafts are meant to describe the same
      // ticked set; a mismatch means the provider's output diverged from
      // that set between the sheet opening and the user tapping save.
      // Recording a partial visit that silently drops a ticked item — along
      // with the brand/spec/cost typed into it and any resetsCycle baseline
      // update it carried — is worse than recording none, because a missed
      // resetsCycle leaves a replaced part looking un-replaced and its
      // reminder never fires.
      if (entries.length != _drafts.length) {
        setState(() {
          _error = 'Không thể lưu lịch sử bảo dưỡng. Vui lòng thử lại.';
        });
        return;
      }

      final shopText = _shopController.text.trim();
      final noteText = _noteController.text.trim();
      final log = ServiceLog(
        id: newId(),
        vehicleId: widget.vehicle.id,
        date: parsedDate,
        odoKm: parsedOdo,
        shopName: shopText.isEmpty ? null : shopText,
        note: noteText.isEmpty ? null : noteText,
        entries: entries,
        // The total is left unset: AppNotifier.addServiceLog derives it as
        // the sum of the entries above, once, so the two figures can never
        // disagree.
      );

      await ref.read(appProvider.notifier).addServiceLog(log);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể lưu lịch sử bảo dưỡng. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _buildItemRow(BuildContext context, MaintenanceItem item) {
    final ticked = _drafts.containsKey(item.id);
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final children = <Widget>[
      CheckboxListTile(
        value: ticked,
        onChanged: (checked) => _toggleItem(item, checked),
        title: Text(item.name),
      ),
    ];
    if (ticked) {
      final controllers = _controllers[item.id]!;
      final draft = _drafts[item.id]!;
      // LOG-04: no sub-line at all when neither field was ever recorded.
      final showPrefillHint =
          (item.partBrand != null || item.partSpec != null) &&
          item.lastServiceDate != null;
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controllers.brand,
                decoration: const InputDecoration(labelText: 'Hãng'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controllers.spec,
                decoration: const InputDecoration(labelText: 'Quy cách'),
              ),
              if (showPrefillHint)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '↳ giống lần trước '
                    '(${formatShortDate(item.lastServiceDate!.toLocal())})',
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: controllers.cost,
                keyboardType: TextInputType.number,
                // Recomputes the read-only total line as entries change.
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Chi phí',
                  suffixText: '₫',
                ),
              ),
              const SizedBox(height: 8),
              // P3-D-07: a two-state toggle, defaulting to "Đã thay".
              // Material's own selected-segment tint (colorScheme.
              // secondaryContainer) is taken unmodified — this is a
              // per-item state toggle, not the sheet's one CTA, and must
              // never compete with [ Lưu ] for accent.
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Đã thay')),
                  ButtonSegment(value: false, label: Text('Chỉ kiểm tra')),
                ],
                selected: {draft.resetsCycle},
                onSelectionChanged: (selection) => setState(() {
                  draft.resetsCycle = selection.first;
                }),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    // dueItemsProvider's own urgency order — never re-sorted, re-filtered or
    // re-grouped by this sheet (P3-D-05).
    final dueItems = ref.watch(dueItemsProvider(widget.vehicle.id));
    final sourceItem = widget.preTickedItemId == null
        ? null
        : _findItem(dueItems, widget.preTickedItemId!);
    // §8.4 only draws the single pre-ticked-item case; the item-less title
    // below has no verbatim source string — flagged for UAT in the SUMMARY.
    final title = sourceItem == null
        ? 'Ghi lại lịch sử bảo dưỡng'
        : 'Ghi lại: ${sourceItem.name}';
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Shared visit-level fields (Ngày / Số km / Tiệm) — cost has no
        // shared field anywhere on this sheet; it lives only inside each
        // ticked item's own block below (P3-D-06).
        TextField(
          controller: _dateController,
          decoration: const InputDecoration(labelText: 'Ngày'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _odoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số km'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _shopController,
          decoration: const InputDecoration(labelText: 'Tiệm'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Ghi chú'),
        ),
        const SizedBox(height: 16),
        for (final dueItem in dueItems) _buildItemRow(context, dueItem.item),
        const SizedBox(height: 8),
        Text(
          'Tổng: ${formatVnd(_totalCostSoFar())}',
          style: TextStyle(fontSize: 12, color: onSurfaceVariant),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          // H4 empty: null whenever nothing is ticked, disabling the button
          // itself rather than guarding inside the handler — a ServiceLog
          // with zero entries would still move the vehicle's odometer
          // through addServiceLog's P3-D-08 path for a visit that recorded
          // nothing.
          onPressed: (_drafts.isEmpty || _submitting) ? null : _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

/// Per-ticked-item state private to this sheet (03-RESEARCH.md Pattern 6) —
/// never exported, never imported by `lib/state/`. Converted to a
/// [ServiceLogEntry] only at "Lưu" time.
class _ItemEntryDraft {
  bool resetsCycle = true;
}

/// One text-controller set per ticked item, created lazily in `_tickItem`
/// and disposed both when that single item is unticked and when the whole
/// sheet is disposed.
class _ItemControllers {
  final TextEditingController brand = TextEditingController();
  final TextEditingController spec = TextEditingController();
  final TextEditingController cost = TextEditingController();

  void dispose() {
    brand.dispose();
    spec.dispose();
    cost.dispose();
  }
}
