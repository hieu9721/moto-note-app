// lib/ui/settings/delete_all_data_dialog.dart — SET-03 (P6-D-10…13). The
// single most destructive interaction in this app, and the one flow this
// codebase confirms twice before running: two sequential AlertDialogs, both
// restating concrete counts, with the destructive tint withheld until the
// very last action (P6-D-12). This file owns the whole flow so
// settings_screen.dart (already ~1100 lines before this plan) does not grow
// by another hundred.
//
// Copy is [NEW, PROVISIONAL] except the checkbox label and caption, which
// this plan's own checkpoint settled verbatim — see 06-07-SUMMARY.md for the
// dated record and the checkpoint's chosen option (unchecked-as-specified).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_data.dart';
import '../../state/app_state.dart';

// CR-03: fixed mapped Vietnamese constants, never an interpolated exception
// — the same discipline every other mutation failure path in this codebase
// follows.
const _localFailureMessage = 'Không thể xoá dữ liệu. Vui lòng thử lại.';
// [NEW, PROVISIONAL] — surfaced only when local deletion succeeded but the
// opt-in Drive delete did not (T-06-07-05 — the split outcome must never be
// swallowed into a single "success").
const _driveFailureMessage =
    'Đã xoá dữ liệu trên máy, nhưng không xoá được bản sao lưu trên Google '
    'Drive.';

/// The single entry point `settings_screen.dart`'s danger-zone row calls.
/// Runs the two-step confirmation and, on the final confirm, the delete
/// itself. Makes no navigation call at all (P6-D-13) — the router's own
/// redirect carries the user to onboarding the instant `vehicles.isEmpty`
/// becomes true.
Future<void> showDeleteAllDataFlow(BuildContext context, WidgetRef ref) async {
  final data = ref.read(appProvider);
  final counts = _countAll(data);

  final deleteDrive = await _showStepOne(context, counts);
  if (deleteDrive == null) return; // cancelled at step one

  if (!context.mounted) return;
  final outcome = await showDialog<_StepTwoOutcome>(
    context: context,
    builder: (ctx) => _StepTwoDialog(
      body: _stepTwoBody(counts, deleteDrive),
      ref: ref,
      deleteDrive: deleteDrive,
    ),
  );
  if (outcome == null || outcome == _StepTwoOutcome.cancelled) return;

  if (!context.mounted) return;
  if (outcome == _StepTwoOutcome.localFailed) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(_localFailureMessage)));
  } else if (outcome == _StepTwoOutcome.driveFailed) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(_driveFailureMessage)));
  }
  // outcome == success: no SnackBar here — the router's own redirect to
  // onboarding is the feedback, and a SnackBar racing that screen change
  // would compete with it rather than add information.
}

class _Counts {
  const _Counts({
    required this.vehicleCount,
    required this.logCount,
    required this.noteCount,
    required this.photoCount,
  });

  final int vehicleCount;
  final int logCount;
  final int noteCount;
  final int photoCount;
}

/// Same collection `AppNotifier.deleteAllData` deletes (nulls excluded from
/// the photo paths), counted here so the number shown and the number
/// deleted cannot disagree.
_Counts _countAll(AppData data) {
  final photoPaths = <String>[
    ...data.logs.expand((l) => l.photoPaths),
    ...data.vehicles.map((v) => v.photoPath).whereType<String>(),
  ];
  return _Counts(
    vehicleCount: data.vehicles.length,
    logCount: data.logs.length,
    noteCount: data.notes.length,
    photoCount: photoPaths.length,
  );
}

/// The Copywriting Contract's exact count sentence, shared by both steps —
/// a zero count still renders as a literal `0` rather than dropping the
/// clause (UI-SPEC P4 zero-one-many).
String _countSentence(_Counts c) =>
    '${c.vehicleCount} xe, ${c.logCount} lần bảo dưỡng, ${c.noteCount} ghi '
    'chú và ${c.photoCount} ảnh hoá đơn trên máy này sẽ bị xoá.';

String _stepTwoBody(_Counts counts, bool deleteDrive) {
  final body = StringBuffer(_countSentence(counts));
  if (deleteDrive) {
    body.write(' Bản sao lưu trên Google Drive cũng sẽ bị xoá.');
  }
  return body.toString();
}

/// Step one — names the counts, offers the opt-in Drive checkbox
/// (P6-D-11, unchecked by default), returns null on cancel or the
/// checkbox's final value on `Tiếp tục`. `Tiếp tục` is deliberately NOT
/// error-tinted — the destructive colour belongs to step two alone
/// (P6-D-12).
Future<bool?> _showStepOne(BuildContext context, _Counts counts) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      var deleteDrive = false; // unchecked by default (P6-D-11)
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Xoá tất cả dữ liệu?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_countSentence(counts)),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: deleteDrive,
                    onChanged: (v) => setState(() => deleteDrive = v ?? false),
                    title: const Text(
                      'Đồng thời xoá bản sao lưu trên Google Drive',
                    ),
                    subtitle: const Text(
                      'Đây là nơi duy nhất bạn có thể khôi phục lại nếu xoá '
                      'nhầm. Chỉ chọn khi bạn chắc chắn không cần nữa.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(deleteDrive),
                child: const Text('Tiếp tục'),
              ),
            ],
          );
        },
      );
    },
  );
}

enum _StepTwoOutcome { cancelled, success, localFailed, driveFailed }

/// Step two — the actual point of no return (P6-D-12): restates the same
/// counts, appends the Drive sentence only when the checkbox was ticked,
/// and is the ONLY step whose confirming action is destructive-tinted. A
/// `StatefulWidget` rather than a plain `showDialog` builder because the
/// delete call itself happens from inside this dialog, guarded by
/// `_submitting`, so the destructive action disables for the whole
/// duration the mutation is in flight — the same discipline every other
/// commit action in this codebase uses.
class _StepTwoDialog extends StatefulWidget {
  const _StepTwoDialog({
    required this.body,
    required this.ref,
    required this.deleteDrive,
  });

  final String body;
  final WidgetRef ref;
  final bool deleteDrive;

  @override
  State<_StepTwoDialog> createState() => _StepTwoDialogState();
}

class _StepTwoDialogState extends State<_StepTwoDialog> {
  bool _submitting = false;

  Future<void> _onConfirm() async {
    setState(() => _submitting = true);
    try {
      final result = await widget.ref
          .read(appProvider.notifier)
          .deleteAllData(deleteDriveBackup: widget.deleteDrive);
      if (!mounted) return;
      if (result.driveDeleteRequested && !result.driveDeleteSucceeded) {
        Navigator.of(context).pop(_StepTwoOutcome.driveFailed);
      } else {
        Navigator.of(context).pop(_StepTwoOutcome.success);
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(_StepTwoOutcome.localFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Không thể hoàn tác'),
      content: SingleChildScrollView(child: Text(widget.body)),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(_StepTwoOutcome.cancelled),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _submitting ? null : _onConfirm,
          child: const Text('Xoá tất cả'),
        ),
      ],
    );
  }
}
