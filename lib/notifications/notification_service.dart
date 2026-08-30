// lib/notifications/notification_service.dart — the notification seam
// `_mutate` calls on every mutation (P1-D-05). Phase 4 replaces the Phase 1
// Noop stub with a real `flutter_local_notifications`-backed implementation.
//
// The abstract class's existing `rescheduleAll(AppData data)` member and the
// `notificationSchedulerProvider` name are unchanged — that is what the
// "must not change" constraint in 04-PATTERNS.md actually protects (the
// signature and the provider name, not the member count), so
// `app_state.dart:169`'s call site needed no edit. Three new members are
// added to the abstract class for this task: `init()`,
// `consumeLaunchPayload()` and the settable `onNotificationOpened` callback.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models/app_data.dart';
import '../domain/notification_plan.dart';

/// Reschedules every local notification from the current [AppData]. Per
/// §10.4, implementations must cancel everything and re-plan individually
/// dated notifications rather than using a repeating schedule (D-29).
abstract class NotificationService {
  Future<void> rescheduleAll(AppData data);

  /// Initialises the plugin: timezone data, local location, plugin init and
  /// the `maintenance` channel (NOTIF-01). Must complete before the first
  /// `rescheduleAll` call.
  Future<void> init();

  /// Reads the payload that cold-started the app, if any. Consumes the
  /// underlying plugin call once — a second call returns null.
  Future<String?> consumeLaunchPayload();

  /// Invoked with the tapped notification's payload when the app is warm.
  /// `main.dart` sets this; the service itself never imports the router or
  /// `app_state.dart` (keeps a global router shape out of this codebase).
  set onNotificationOpened(void Function(String payload)? callback);
}

/// Phase 1 placeholder, replaced by [FlutterLocalNotificationService] as the
/// provider's default in Phase 4. Deliberately inert — every member is a
/// no-op so it stays a valid default for `notificationSchedulerProvider`.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> rescheduleAll(AppData data) async {}

  @override
  Future<void> init() async {}

  @override
  Future<String?> consumeLaunchPayload() async => null;

  @override
  set onNotificationOpened(void Function(String payload)? callback) {}
}

/// The real implementation, wired in by `main.dart` after `hydrate()`. Owns
/// every call into `flutter_local_notifications`/`timezone`/
/// `flutter_timezone` — the domain planner (`notification_plan.dart`) stays
/// free of all three (D-31).
class FlutterLocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String payload)? _onNotificationOpened;

  @override
  set onNotificationOpened(void Function(String payload)? callback) {
    _onNotificationOpened = callback;
  }

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    // flutter_timezone 5.x returns a TimezoneInfo, not a bare String — a
    // v5.0.0 breaking change (04-RESEARCH.md § Code Examples). `.identifier`
    // is the IANA name (e.g. "Asia/Ho_Chi_Minh"). An unknown identifier
    // falls back to a known location instead of throwing, so a failed
    // timezone lookup never prevents the plugin initialising or the channel
    // being created (NOTIF-01 edge: empty).
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      // Asia/Ho_Chi_Minh: this app's whole userbase is Vietnamese riders
      // (PROJECT.md), so it is the least-wrong fallback location when the
      // OS reports an identifier the bundled IANA database has no entry
      // for. Logged, not swallowed silently.
      _log('unknown timezone identifier, falling back to Asia/Ho_Chi_Minh: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    await _plugin.initialize(
      // NAMED, not positional — v20.0.0 breaking change.
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // iOS is deferred past 1.0 (PROJECT.md Out of Scope) — no
        // DarwinInitializationSettings block, which would be dead
        // configuration.
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'maintenance',
            'Nhắc bảo dưỡng',
            description:
                'Nhắc khi tới hạn thay linh kiện và nhắc cập nhật số km',
            importance: Importance.high,
          ),
        );
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) _onNotificationOpened?.call(payload);
  }

  @override
  Future<String?> consumeLaunchPayload() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails == null || !launchDetails.didNotificationLaunchApp) {
      return null;
    }
    return launchDetails.notificationResponse?.payload;
  }

  @override
  Future<void> rescheduleAll(AppData data) async {
    // Cancel first, unconditionally — D-29's cancel-then-reschedule
    // discipline, before the disabled check, so a user who just turned
    // notifications off actually gets everything cancelled.
    await _plugin.cancelAll();

    if (!data.settings.notificationsEnabled) return;

    final planned = planNotifications(data);
    final now = DateTime.now();
    var id = 0;
    // A fresh 0..29 range each call is sufficient — cancelAll() already ran
    // for this invocation, so id stability across calls is irrelevant
    // (§10.4's own `var id = 0;` pattern).
    for (final p in planned) {
      // Pitfall 2 guard (04-RESEARCH.md): zonedSchedule throws ArgumentError
      // if the resolved time has already passed by execution time. Skip
      // deliberately rather than clamp — see this plan's flagged assumption
      // #2: a clamped entry would re-arm ~1 minute out on every subsequent
      // rescheduleAll call (every mutation, every resume), firing a
      // "reminder" about the screen the user was just looking at.
      if (!p.scheduledAt.isAfter(now.add(const Duration(seconds: 5)))) {
        continue;
      }
      final thisId = id++;
      // Wrapped per-item so one stale/invalid entry cannot abort the loop
      // for the rest (T-04-03).
      try {
        await _plugin.zonedSchedule(
          id: thisId,
          scheduledDate: tz.TZDateTime.from(p.scheduledAt, tz.local),
          title: p.title,
          body: p.body,
          payload: p.payload,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'maintenance',
              'Nhắc bảo dưỡng',
              channelDescription:
                  'Nhắc khi tới hạn thay linh kiện và nhắc cập nhật số km',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: _scheduleMode(),
        );
      } catch (e) {
        _log('zonedSchedule failed for id $thisId (${p.payload}): $e');
      }
    }
  }

  /// The single resolver every `zonedSchedule` call reads (this plan's
  /// `<assumption_delta_decision>`). Today this always returns
  /// `inexactAllowWhileIdle` — never bare `inexact`, which the package's own
  /// enum doc says may not execute in low-power idle, exactly the Doze
  /// problem §10.6 exists to work around (P4-D-07, D-30, Pitfall 4). 04-03
  /// gives this its second branch (the user's exact-alarm opt-in) without
  /// any call site needing to change.
  AndroidScheduleMode _scheduleMode() =>
      AndroidScheduleMode.inexactAllowWhileIdle;

  void _log(String message) {
    // ignore: avoid_print
    print('FlutterLocalNotificationService: $message');
  }
}

/// Provider name is verbatim from §5.2 so `app_state.dart` never has to
/// change; `main.dart` overrides this with the real service after `init()`.
final notificationSchedulerProvider = Provider<NotificationService>(
  (_) => const NoopNotificationService(),
);
