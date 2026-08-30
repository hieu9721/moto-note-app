// lib/domain/notification_plan.dart — transcribed from §10.1/§10.4. Pure
// Dart (D-31) — this directory must never import the Flutter SDK.
//
// The planning half of `rescheduleAll` (P4-D-13): a function over [AppData]
// with an injectable [now] that returns the sorted, capped list of planned
// notifications as plain `DateTime`s (never `TZDateTime`, never a
// notification-plugin type). `NotificationService` is reduced to executing
// this list against the OS at the one boundary that needs the plugin.
//
// Two deliberate, narrow exceptions to this file's purity, both explained at
// their point of use below:
// 1. The `intl` package import below IS allowed — `intl` has zero Flutter
//    dependency, so D-31 permits it. Importing `../ui/widgets/formatters.dart`
//    is NOT allowed — that file lives under `lib/ui/`, and importing it would
//    invert the codebase's dependency direction even though it would not
//    literally violate D-31's "no package:flutter" text (04-RESEARCH.md
//    Pitfall 5). The single duplicated `NumberFormat` line below is a
//    deliberate exception to "single implementation for shared copy",
//    justified by layering.
// 2. The ODO reminder body's `~` is unconditional, unlike the home header's
//    `~` (P3-D-04), which is conditional on measured drift because it is
//    recomputed every frame. This string is composed once, at schedule time,
//    up to six months before it is read — a figure that stale is always a
//    guess (P4-D-15).
import 'package:intl/intl.dart';

import 'models/app_data.dart';
import 'odo.dart';

/// §10.4's `_horizonDays` — how far ahead `rescheduleAll` plans.
const int kNotificationHorizonDays = 120;

/// §10.4's `_maxScheduled` — the hard cap on how many notifications a single
/// `rescheduleAll` call will ever hand to the OS.
const int kMaxScheduledNotifications = 30;

/// One notification `rescheduleAll` should schedule. [scheduledAt] is a
/// local wall-clock `DateTime` — NEVER a UTC one and NEVER a `TZDateTime`;
/// `NotificationService` converts to `tz.TZDateTime` at the one execution
/// boundary that needs the plugin. Modelled on `odo.dart`'s `RefinedAvg`: a
/// plain `const` class, never Freezed, never serialized on its own.
class PlannedNotification {
  final DateTime scheduledAt;
  final String title;
  final String body;
  final String payload; // '{kind}:{id}' — locked P4-D-01, checkpoint Task 1
  const PlannedNotification({
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
  });
}

final NumberFormat _kmFmt = NumberFormat.decimalPattern('vi_VN');
String _fmtKm(int km) => _kmFmt.format(km);

/// Returns the planned notifications for [data], sorted by [scheduledAt]
/// with a deterministic secondary key on [PlannedNotification.payload] (not
/// a priority rule — P4-D-17 declines one — purely to keep the 30-item cut
/// stable run to run, matching `derived.dart`'s own tie-break hardening),
/// then capped at [kMaxScheduledNotifications].
///
/// This task builds only the monthly ODO reminder (§10.4's own scoping to
/// `data.vehicles.first`, P4-D-16). The due-item loop is 04-02's addition —
/// left out entirely here rather than stubbed, so this file's own git
/// history shows the tracer slice's true shape.
List<PlannedNotification> planNotifications(AppData data, {DateTime? now}) {
  final n = now ?? DateTime.now().toUtc();
  if (!data.settings.notificationsEnabled) return const [];

  final planned = <PlannedNotification>[];

  if (data.settings.odoReminderEnabled && data.vehicles.isNotEmpty) {
    final v = data.vehicles.first; // P4-D-16: first only, flagged for Phase 6
    for (var m = 0; m < 6; m++) {
      planned.add(
        PlannedNotification(
          scheduledAt: _nthMonthDay(
            n,
            m,
            data.settings.odoReminderDayOfMonth,
            data.settings.notifyHour,
          ),
          title: 'Cập nhật số km',
          // The `~` is inside the composed body literal, not appended at a
          // call site — deliberate and unconditional (P4-D-15). `{name}` is
          // interpolated verbatim, no truncation, no normalisation.
          body:
              'Xe ${v.name} đang ở khoảng ~${_fmtKm(estimateOdo(v, now: n))} '
              'km. Số thật là bao nhiêu?',
          payload: 'odo:${v.id}',
        ),
      );
    }
  }

  planned.sort((a, b) {
    final byDate = a.scheduledAt.compareTo(b.scheduledAt);
    if (byDate != 0) return byDate;
    return a.payload.compareTo(b.payload);
  });
  return planned.take(kMaxScheduledNotifications).toList();
}

/// Resolves a tap payload to a route. Pure and testable — the mitigation for
/// T-04-01/T-04-02. Never throws: a null/empty payload, a malformed payload
/// (wrong colon count) or an unrecognised kind/vehicle id all fall back to
/// `'/'` silently (P4-D-04's honest no-op, same idiom as
/// `app_state.dart`'s `indexWhere`-then-check-`-1` lookups — T-03-22).
String notificationRouteFor(String? payload, AppData data) {
  if (payload == null || payload.isEmpty) return '/';

  final parts = payload.split(':');
  if (parts.length != 2) return '/'; // length-checked, never a destructive
  // two-element pattern-match, which throws on any other length.

  final kind = parts[0];
  final id = parts[1];

  var vehicleFound = false;
  for (final v in data.vehicles) {
    if (v.id == id) {
      vehicleFound = true;
      break;
    }
  }
  if (!vehicleFound) return '/'; // P4-D-04: stale, not an error.

  return switch (kind) {
    'odo' => '/?sheet=odo',
    'due' => '/',
    _ => '/',
  };
}

/// §10.4's own `_nthMonthDay`-equivalent: the local `DateTime` for the
/// [monthsAhead]-th month after [from]'s local month, at [hour], clamped to
/// that month's last day when [dayOfMonth] exceeds it — 31 in a 30-day month
/// schedules on the 30th, 31 in February on the 28th/29th, never rolling
/// forward into the next month (NOTIF-06 boundary edge). Mirrors
/// `due.dart`'s own out-of-range-day clamp for `dueByTime` (`due.dart:126
/// -140`) rather than letting `DateTime`'s constructor silently normalise
/// forward.
DateTime _nthMonthDay(
  DateTime from,
  int monthsAhead,
  int dayOfMonth,
  int hour,
) {
  final l = from.toLocal();
  final targetMonth = l.month + monthsAhead;
  final lastDayOfTarget = DateTime(l.year, targetMonth + 1, 0).day;
  final day = dayOfMonth < lastDayOfTarget ? dayOfMonth : lastDayOfTarget;
  return DateTime(l.year, targetMonth, day, hour);
}
