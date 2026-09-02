// lib/ui/widgets/error_state.dart — P6-D-14, REL-01. The shared
// section/screen-level "nothing could be shown at all" widget — e.g. a
// future collection-load failure. This is NOT a replacement for this
// codebase's established inline-error-string-in-a-slot-plus-`SnackBar`
// pattern: onboarding, the ODO sheet, the service-log sheet, the restore
// sheet and this phase's own delete flows all keep that pattern, and an
// `ErrorState` column inside an `AlertDialog` would look absurd.
//
// `message` MUST always be a pre-mapped Vietnamese constant, never an
// interpolated exception object — the exact discipline CR-03 already fixed
// once in Settings (06-UI-SPEC.md § F, Copywriting Contract "Error state").
import 'package:flutter/material.dart';

/// A centered "could not load this" placeholder with an optional retry
/// action. Does no work of its own beyond rendering; a caller-supplied
/// `onRetry` callback owns its own in-flight state (P6-D-15, D-19 — no
/// screen waits on the network, so this widget never manufactures a
/// spinner).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
