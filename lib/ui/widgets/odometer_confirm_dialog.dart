// lib/ui/widgets/odometer_confirm_dialog.dart — the single implementation of
// the P3-D-12 "odometer replaced" confirmation, promoted out of
// `lib/ui/home/odo_sheet.dart` (03-07, closing CR-01). Before this file
// existed, `odo_sheet.dart` carried the only copy of this dialog and
// `lib/ui/log/service_log_sheet.dart` had no lower-than-previous guard at
// all — the two odometer write paths could not have agreed on wording even
// if the service-log sheet had grown its own copy, because there was
// nothing to compare against. Sharing one function is what makes it
// structurally impossible for the two paths to drift apart again.
//
// This is the `ui-spec` resolution of `03-03-PLAN.md`'s `gate="blocking-human"`
// checkpoint: the title, body and button strings below are
// `03-UI-SPEC.md`'s Copywriting Contract → "Destructive confirmation" row,
// the same copy `gsd-ui-checker` verified against `motonote-v3-flutter.md:1701`.
// They are `[NEW, PROVISIONAL]` — reviewed Vietnamese, not transcribed
// Vietnamese — and are recorded verbatim in 03-03-SUMMARY.md's "Settled
// Confirmation Copy" table so end-of-phase UAT can check the shipped build
// against what was approved. Do not reword them.
import 'package:flutter/material.dart';

import 'formatters.dart';

/// P3-D-12's replacement confirmation, shared by `odo_sheet.dart` (ODO-04)
/// and `service_log_sheet.dart` (LOG-02/LOG-03). Returns `true` only when the
/// user explicitly confirms; a cancel or a dismissed dialog returns `false`
/// or `null` and the caller must treat both as "do not persist anything".
Future<bool?> confirmOdometerReplaced(
  BuildContext context, {
  required int previousKm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Xác nhận đã thay đồng hồ'),
      content: Text(
        'Số bạn nhập nhỏ hơn lần trước (Lần trước: ${formatKm(previousKm)} '
        'km). Nếu bạn vừa thay đồng hồ ODO, hãy xác nhận để tiếp tục — nếu '
        'không, hãy kiểm tra lại số vừa nhập.',
      ),
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
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );
}
