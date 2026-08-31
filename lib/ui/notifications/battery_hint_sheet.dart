// lib/ui/notifications/battery_hint_sheet.dart — the per-manufacturer
// battery guidance from §10.6, reachable from both Cài đặt and the
// dead-notification banner on Trang chủ (P4-D-09: one implementation, two
// entry points). This is a **modal sheet, not a screen** — D-33 is not
// amended again. D-33 already treats the ODO sheet and the service-log
// sheet as modals rather than screens, and Phase 3's amendment for the
// data-issue screen states in PROJECT.md that it is explicitly not a
// precedent, so following the existing modal precedent costs nothing and
// keeps the seven-screen cap intact.
import 'package:flutter/material.dart';

import '../../notifications/battery_hints.dart';

/// Opens the battery-guidance sheet. Copies `showOdoSheet`'s exact call
/// shape (`lib/ui/home/odo_sheet.dart`) — `isScrollControlled: true` and
/// `useSafeArea: true` are both present even though this sheet's content
/// is short, because the top-safe-area-inset bug the ODO sheet's own
/// comment documents is not about content length.
Future<void> showBatteryHintSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const BatteryHintSheetBody(),
  );
}

class BatteryHintSheetBody extends StatefulWidget {
  const BatteryHintSheetBody({super.key});

  @override
  State<BatteryHintSheetBody> createState() => _BatteryHintSheetBodyState();
}

class _BatteryHintSheetBodyState extends State<BatteryHintSheetBody> {
  // Null until the platform-channel read below resolves. The sheet's first
  // frame is never blocked on it — title, lead-in and button render
  // immediately; only the instruction text below waits.
  BatteryHint? _hint;

  @override
  void initState() {
    super.initState();
    _loadHint();
  }

  Future<void> _loadHint() async {
    final hint = await batteryOptimizationHint();
    // CLAUDE.md trap: BuildContext used after an await. This sheet can be
    // dismissed while the platform-channel read is in flight.
    if (!context.mounted) return;
    setState(() => _hint = hint);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hint = _hint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // [NEW, PROVISIONAL] — sheet title, not sourced in §10.6.
          Text(
            'Thông báo không tới?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // [NEW, PROVISIONAL] — lead-in above the instructions.
          Text(
            'Máy Android có thể tự chặn thông báo của app để tiết kiệm pin. Làm theo hướng dẫn dưới đây cho máy của bạn:',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          // A sheet the user deliberately opened must never render blank:
          // while the platform-channel read is still in flight — a
          // fraction of a second, no network involved (D-19) — or if it
          // somehow resolves null (a non-Android platform, which cannot
          // happen in this build), the [_fallbackHintText] below fills the
          // instruction area rather than leaving it empty.
          Text(
            hint?.text ?? _fallbackHintText,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          // The sheet's single primary action — a FilledButton, matching
          // this codebase's convention that the one action resolving the
          // situation is the filled one (due_card.dart's "Tôi vừa thay").
          FilledButton(
            onPressed: () => openBatterySettings(),
            // [NEW, PROVISIONAL] — button label.
            child: const Text('Mở cài đặt pin'),
          ),
        ],
      ),
    );
  }
}

// [NEW, PROVISIONAL] — defensive fallback for the loading window and the
// non-Android null case, neither of which is one of this file's three
// enumerated invented strings (sheet title, lead-in, button label); this
// path cannot be reached on a shipped Android build.
const _fallbackHintText =
    'Mở phần tối ưu hoá pin trong Cài đặt và cho MotoNote chạy không giới hạn.';
