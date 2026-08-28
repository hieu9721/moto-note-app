// lib/notifications/notification_service.dart — the notification seam
// `_mutate` calls on every mutation (P1-D-05). Real scheduling — channels,
// timezone setup, permission handling — is Phase 4 (NOTIF-01, NOTIF-02);
// this file only fixes the shape so `app_state.dart` never has to change
// when that implementation lands.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/app_data.dart';

/// Reschedules every local notification from the current [AppData]. Per
/// §10.4, implementations must cancel everything and re-plan individually
/// dated notifications rather than using a repeating schedule (D-29).
abstract class NotificationService {
  Future<void> rescheduleAll(AppData data);
}

/// Phase 1 placeholder, replaced by the real `flutter_local_notifications`
/// implementation in Phase 4. Deliberately inert — no channel creation, no
/// timezone setup, no permission handling belongs here yet.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> rescheduleAll(AppData data) async {}
}

/// Provider name is verbatim from §5.2 so Phase 4 swaps only the
/// implementation behind it; `app_state.dart` never has to change.
final notificationSchedulerProvider = Provider<NotificationService>(
  (_) => const NoopNotificationService(),
);
