// lib/ui/widgets/empty_state.dart — P6-D-14, REL-01. The shared "nothing to
// show here" widget: one icon, one message, one optional action, nothing
// else. There is deliberately NO heading parameter — every verbatim
// empty-state string this project owns (Notes, item-detail history) is a
// single sentence, and adding a heading slot would invite inventing text
// with no source (06-UI-SPEC.md § F).
//
// The message `Text` leaves its line-clamp unset: that single unclamped
// `Text` is what makes this widget's long-text behaviour and its overflow
// behaviour the same property — a long message grows the column instead of
// clipping it, verified together in 06-03-PLAN.md's must_haves.
import 'package:flutter/material.dart';

/// A centered "nothing to show" placeholder for a section or screen with no
/// content at all — never a substitute for this codebase's inline
/// error-slot-plus-`SnackBar` pattern inside a sheet or dialog.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
