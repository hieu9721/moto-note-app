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

import 'due.dart';
import 'models/app_data.dart';
import 'models/misc.dart';
import 'models/vehicle.dart';
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
/// Two halves, both from `AppData`: the monthly ODO reminder (§10.4's own
/// scoping to `data.vehicles.first`, P4-D-16 — 04-01's tracer slice), and
/// the due-item cadence below — "sắp tới hạn"/"quá hạn", bucketed by
/// (vehicle, day) and composed per §10.5 (04-02's addition, P4-D-13/14).
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

  // The due-item cadence (NOTIF-04/-05/-07). `byDay` IS the grouping
  // mechanism for SC2/NOTIF-07 (RESEARCH.md Pattern 2) — at most one entry
  // per (vehicle, day) reaches `planned`, so the plugin's native
  // `groupKey`/`setAsGroupSummary` is never needed; the planner never
  // produces more than one entry per bucket in the first place.
  final byDay = <String, _Group>{};
  for (final v in data.vehicles) {
    for (final item in data.items.where((i) => i.vehicleId == v.id)) {
      // A null result means the item is disabled or has no baseline on
      // either axis — not an error, `computeDue`'s own honest contract
      // (§5.3: the planner reads due-ness, it never re-derives it).
      final due = computeDue(item, v, data.settings.leadDays, now: n);
      if (due == null) continue;

      // Dedupe a single item's OWN candidate dates before bucketing: with
      // leadDays: 0 the "sắp tới hạn" and "đúng hạn" candidates from
      // `_notifyDatesFor` are the identical local civil date, and without
      // this the same item's name would be appended twice into one
      // bucket. Two DIFFERENT items landing on the same day is the real
      // grouping case below and is unaffected — this `toSet()` only
      // collapses duplicates within one item's own four candidates.
      for (final date in _notifyDatesFor(due, data.settings).toSet()) {
        final scheduledAt = _atHour(date, data.settings.notifyHour);
        // Strictly-after, never §10.4's `isBefore` — `d == now` must not
        // reach `zonedSchedule`, which is already stale by the time the
        // service's own clock read happens (RESEARCH.md Pitfall 2).
        if (!scheduledAt.isAfter(n)) continue;
        // Horizon is inclusive at the boundary: exactly
        // kNotificationHorizonDays days out is scheduled, one day past is
        // not. Comparing two already-`_dateOnly`-normalised local civil
        // dates — the one `.inDays` use this function needs.
        final daysOut = _dateOnly(date).difference(_dateOnly(n)).inDays;
        if (daysOut > kNotificationHorizonDays) continue;

        final key = '${v.id}|${_dateKey(date)}';
        final group = byDay.putIfAbsent(
          key,
          () => _Group(vehicle: v, date: date),
        );
        group.items.add(item.name);
      }
    }
  }
  for (final group in byDay.values) {
    final msg = _compose(group.vehicle, group.items);
    planned.add(
      PlannedNotification(
        scheduledAt: _atHour(group.date, data.settings.notifyHour),
        title: msg.title,
        body: msg.body,
        payload: 'due:${group.vehicle.id}',
      ),
    );
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

/// The LOCAL civil date [d] falls on, at midnight — the same normalisation
/// `due.dart`'s own private `_dateOnly` performs, duplicated here (rather
/// than exported cross-file) because it is one three-line function and
/// `due.dart` does not expose it. `toLocal()` first is the whole point: a
/// UTC-anchored instant carries UTC's calendar date, which at UTC+7 is the
/// previous day for the first seven hours of every local day — the same
/// off-by-one CLAUDE.md and `due.dart`'s own header both flag twice.
DateTime _dateOnly(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// [day] (any local civil date; time components ignored via [_dateOnly])
/// at [hour]:00:00, as a plain local `DateTime` — never a `TZDateTime`. The
/// conversion to `TZDateTime` belongs at the one execution boundary that
/// already needs the plugin (RESEARCH.md Anti-Patterns).
DateTime _atHour(DateTime day, int hour) {
  final l = _dateOnly(day);
  return DateTime(l.year, l.month, l.day, hour);
}

/// The local civil year-month-day [d] falls on, rendered as a stable string
/// key for the (vehicle, day) bucket map below — `'{vehicleId}|{_dateKey}'`
/// is the entire grouping mechanism for NOTIF-07/SC2 (RESEARCH.md Pattern
/// 2); no native `groupKey`/`setAsGroupSummary` is used because the planner
/// never produces more than one entry per bucket to begin with.
String _dateKey(DateTime d) {
  final l = _dateOnly(d);
  final mm = l.month.toString().padLeft(2, '0');
  final dd = l.day.toString().padLeft(2, '0');
  return '${l.year}-$mm-$dd';
}

/// §10.4's `_notifyDatesFor` — the function the source calls and never
/// defines (RESEARCH.md Pattern 1). Four candidate local civil dates, in a
/// fixed order: [settings.leadDays] before [due.dueDate] ("sắp tới hạn"),
/// [due.dueDate] itself (also the first "quá hạn" occurrence and the
/// dueToday case), then +14 and +28 days — §10.1's "mỗi 14 ngày, tối đa 3
/// lần", three quá-hạn occurrences and no fourth. Day arithmetic goes
/// through [_dateOnly] and `DateTime`'s own normalising constructor —
/// NEVER a `Duration` added to a raw stored timestamp, and NEVER through
/// `difference().inDays`, which truncates (CLAUDE.md, `due.dart`'s own
/// header).
///
/// Deliberately independent of the item's CURRENT status: `rescheduleAll`
/// re-derives the whole schedule from scratch on every run (`_mutate`
/// calls it on every state change, P1-D-05), so an item that is `ok` today
/// may be `dueSoon` or `overdue` tomorrow, and the candidate list here must
/// already carry the dates that will matter once that happens — this
/// function only ever reads `due.dueDate`, never `due.status`.
List<DateTime> _notifyDatesFor(DueResult due, Settings settings) {
  final base = _dateOnly(due.dueDate);
  return [
    DateTime(base.year, base.month, base.day - settings.leadDays),
    base,
    DateTime(base.year, base.month, base.day + 14),
    DateTime(base.year, base.month, base.day + 28),
  ];
}

/// One bucket in `planNotifications`'s (vehicle, day) grouping map — a
/// plain mutable accumulator, never Freezed, never serialized (mirrors
/// `PlannedNotification`'s own "not every domain class needs to be
/// Freezed" precedent).
class _Group {
  final Vehicle vehicle;
  final DateTime date;
  final List<String> items = [];
  _Group({required this.vehicle, required this.date});
}

/// A composed notification title/body pair, before it becomes a
/// [PlannedNotification]. Plain, private, never Freezed.
class _Msg {
  final String title;
  final String body;
  const _Msg(this.title, this.body);
}

/// §10.5's three composition shapes, transcribed verbatim — nothing
/// paraphrased, every count interpolated at runtime, never a literal digit
/// from the source's illustrative example. [items] is read in
/// `data.items` iteration order (the order the bucket accumulated them),
/// so the same data composes the same sentence on every run — the
/// `{n} mục khác` form always names the first two of that order.
_Msg _compose(Vehicle v, List<String> items) {
  if (items.length == 1) {
    return _Msg('${v.name} sắp tới hạn', items[0]);
  }
  if (items.length == 2) {
    return _Msg('${v.name} sắp tới hạn', '${items[0]} và ${items[1]}');
  }
  final n = items.length;
  return _Msg(
    '${v.name} có $n hạng mục sắp tới hạn',
    '${items[0]}, ${items[1]} và ${n - 2} mục khác',
  );
}
