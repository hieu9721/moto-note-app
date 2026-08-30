// lib/ui/home/odo_sheet.dart — ODO-04. The self-drawn keypad sheet that lets
// the user update Vehicle.currentOdoKm, prefilled from the app's own
// estimate (P3-D-09) so the user edits a few digits rather than typing the
// whole figure. There is no TextField anywhere on this sheet — the only
// input is the 12-cell keypad below, so the system keyboard never opens
// and there is deliberately no keyboard-inset handling (03-RESEARCH.md
// Pattern 4; do not share scaffolding with plan 04's service-log sheet,
// which needs the opposite — see Pitfall 3).
//
// The `gate="blocking-human"` decision checkpoint this plan opened with was
// resolved `ui-spec`: the P3-D-12 confirmation this sheet calls is
// `03-UI-SPEC.md`'s Copywriting Contract → "Destructive confirmation" row,
// the same copy `gsd-ui-checker` verified against
// `motonote-v3-flutter.md:1701`. They are `[NEW, PROVISIONAL]` — reviewed
// Vietnamese, not transcribed Vietnamese — and are recorded verbatim in
// 03-03-SUMMARY.md so end-of-phase UAT can check the shipped build against
// what was approved. Do not reword them. 03-07 promoted the dialog itself
// into `lib/ui/widgets/odometer_confirm_dialog.dart` (CR-01) so the
// service-log sheet's own lower-than-previous guard shares this exact
// implementation instead of growing a second copy.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/vehicle.dart';
import '../../domain/odo.dart';
import '../../state/app_state.dart';
import '../widgets/formatters.dart';
import '../widgets/odometer_confirm_dialog.dart';
import 'home_screen.dart' show daysSinceOdoUpdate;

/// Opens the ODO update sheet for [vehicle]. §11.2 frames this explicitly as
/// a "modal sheet, không phải màn hình" — it does not count toward D-33's
/// seven-screen cap. `isScrollControlled: true` lets the sheet size itself
/// to content instead of being pinned to half the screen; `useSafeArea:
/// true` works around the documented top-safe-area-inset bug under
/// `isScrollControlled` (03-RESEARCH.md Pitfall 3).
Future<void> showOdoSheet(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => OdoSheetBody(vehicle: vehicle),
  );
}

class OdoSheetBody extends ConsumerStatefulWidget {
  const OdoSheetBody({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<OdoSheetBody> createState() => _OdoSheetBodyState();
}

class _OdoSheetBodyState extends ConsumerState<OdoSheetBody> {
  // Prefilled from the app's own estimate — never empty at open (P3-D-09).
  // A digit tap appends at the end, backspace removes from the end; there
  // is no "first keypress clears" calculator behaviour, which would make
  // the prefill worthless.
  late String _digits = '${estimateOdo(widget.vehicle)}';
  bool _submitting = false;
  String? _error;

  // A nine-million-km odometer is not a real reading.
  static const _maxDigits = 7;

  void _tapDigit(String d) {
    if (_digits.length >= _maxDigits) return;
    setState(() {
      _digits += d;
      _error = null;
    });
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() {
      _digits = _digits.substring(0, _digits.length - 1);
      _error = null;
    });
  }

  int get _parsedValue => int.tryParse(_digits) ?? 0;

  // Checked against the last REAL reading (P3-D-10) — never against the
  // estimate and never against the nullable `latestReadingFor()` lookup,
  // which can legitimately be null for a vehicle created before plan 02
  // shipped. `vehicle.currentOdoKm` always exists.
  bool get _isLowerThanPrevious =>
      _digits.isNotEmpty && _parsedValue < widget.vehicle.currentOdoKm;

  Future<void> _save() async {
    // structural guard, mirrors the disabled button
    if (_digits.isEmpty) {
      return;
    }
    final value = _parsedValue;

    if (value < widget.vehicle.currentOdoKm) {
      final confirmed = await confirmOdometerReplaced(
        context,
        previousKm: widget.vehicle.currentOdoKm,
      );
      // CLAUDE.md trap: BuildContext/State used after an await. This sheet
      // can be disposed while the confirmation is open; bail before the
      // setState below touches a disposed State.
      if (!mounted) return;
      if (confirmed != true) return;
      // P3-D-12: a confirmed replacement is written EXACTLY like any other
      // reading below — no new field, no new OdoSource member, and no
      // deletion or rewriting of earlier readings. The resulting negative
      // jump stays in the OdoReading history as a fact; refineAvgDailyKm's
      // own non-positive-km-delta guard already keeps avgDailyKm safe, and
      // Phase 6's offline recomputation is where the jump is later
      // recognised and skipped as a replacement rather than a measurement.
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(appProvider.notifier)
          .addOdoReading(widget.vehicle.id, value, DateTime.now());
      // CLAUDE.md trap: BuildContext used after an await. `mounted` (the
      // State getter) is used instead of `context.mounted` for this exact
      // try/catch/finally shape — the same idiom onboarding_flow.dart uses
      // and the same reason its own comment records.
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      // `_mutate` persists before assigning and rethrows on a failed save
      // (P1-D-06), so the sheet stays open and shows an error rather than
      // dismissing over a save that did not happen.
      if (mounted) {
        setState(() {
          _error = 'Không thể lưu số km. Vui lòng thử lại.';
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

  Widget _digitCell(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: _submitting ? null : () => _tapDigit(label),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _backspaceCell(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: _submitting ? null : _backspace,
      child: Icon(Icons.backspace_outlined, color: colorScheme.onSurface),
    );
  }

  // The 12-cell order is fixed by 03-UI-SPEC.md, matching §11.2's mockup
  // exactly: 1 2 3 / 4 5 6 / 7 8 9 / [blank] 0 ⌫ — the bottom row's leading
  // cell is empty, never a repeated "7 8 9".
  Widget _buildKeypad(BuildContext context) {
    final cells = <Widget>[
      _digitCell(context, '1'),
      _digitCell(context, '2'),
      _digitCell(context, '3'),
      _digitCell(context, '4'),
      _digitCell(context, '5'),
      _digitCell(context, '6'),
      _digitCell(context, '7'),
      _digitCell(context, '8'),
      _digitCell(context, '9'),
      const SizedBox.shrink(), // blank leading cell, last row
      _digitCell(context, '0'),
      _backspaceCell(context),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.3,
      children: cells,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final saveButton = FilledButton(
      onPressed: (_submitting || _digits.isEmpty) ? null : _save,
      child: const Text('Lưu'),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Số km hiện tại',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formatKm(_parsedValue),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            'Lần trước: ${formatKm(widget.vehicle.currentOdoKm)} '
            '(${daysSinceOdoUpdate(widget.vehicle)} ngày)',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          // H3 `partial`/step 6 (03-UI-SPEC.md): the lower-than-previous
          // guard must always be VISIBLE, not just enforced at save time —
          // [ Lưu ] stays enabled here; tapping it is what opens the
          // confirmation dialog below.
          if (_isLowerThanPrevious)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Số km nhỏ hơn lần trước. Nhấn Lưu để xác nhận đã thay '
                'đồng hồ.',
                style: TextStyle(fontSize: 16, color: colorScheme.error),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 16, color: colorScheme.error),
              ),
            ),
          // H3 `overflow` (03-UI-SPEC.md ODO-sheet layout step 8): [ Lưu ]
          // sits beside the keypad on a wide-enough sheet (≥360dp, the
          // reference device's own viewport) and falls back to a
          // full-width button below the keypad on anything narrower — an
          // explicit responsive fallback, never a silently dropped button.
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 360) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildKeypad(context)),
                    const SizedBox(width: 16),
                    SizedBox(width: 96, child: saveButton),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildKeypad(context),
                  const SizedBox(height: 16),
                  saveButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
