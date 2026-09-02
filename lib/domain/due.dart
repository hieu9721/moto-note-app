// lib/domain/due.dart — transcribed from §9.3. Pure Dart (D-31) — this
// directory must never import the Flutter SDK.
//
// Four deliberate adjustments to the source listing, each recorded here:
//
// 1. `now` defaults to `DateTime.now().toUtc()`, not bare `DateTime.now()`.
//    Phase 1 stores every persisted wall-clock timestamp in UTC
//    (app_data.dart:40, app_state.dart:158), so every ELAPSED-DURATION
//    measure here (`daysSinceOdo`, `estimateOdo`) compares UTC against UTC.
//
//    But a CALENDAR DAY is not a duration — it is a local-civil concept, and
//    "is it due today?" is a question about the user's calendar, not UTC's.
//    An earlier revision of this file anchored the calendar-day comparison to
//    UTC too, on the reasoning that Asia/Ho_Chi_Minh has no DST so a uniform
//    UTC anchor is "correctness-neutral provided it is applied on both sides".
//    That reasoning is wrong, and measurably so: at UTC+7 the local civil date
//    runs AHEAD of the UTC date between 00:00 and 07:00 local every single
//    day, so an item due on the 1st reported `daysLeft == 1` / `dueSoon` to a
//    Vietnamese user for the first seven hours OF the day it came due,
//    flipping to `dueToday` only at 07:00 local. For an app whose entire
//    promise is reminding someone on the RIGHT DAY, that is the bug the
//    promise is made of. `_dateOnly` therefore resolves to the LOCAL civil
//    date, and `dueByTime` is built from `lastServiceDate`'s local civil
//    components for the same reason. Found by plan 02-04's test suite.
// 2. The `estOdo` line calls `estimateOdo(vehicle, now: n)` (odo.dart)
//    instead of repeating the two-line calculation (02-RESEARCH.md
//    Pattern 3).
// 3. `_timeProgress` has NO body in the source document (02-RESEARCH.md
//    Assumptions Log A4). Locked here: normalise `last`, `due` and `now`
//    through `_dateOnly`; `total = due.difference(last).inDays`; return
//    `0.0` when `total <= 0` (guards the divide-by-zero an `intervalMonths`
//    of 0 would otherwise cause); otherwise
//    `now.difference(last).inDays / total`. Deliberately not clamped at the
//    top — `DueResult.progress` is documented `0..1+` and the km axis is
//    not clamped either.
// 4. `dueItemsProvider` and every caller pass `leadDays` from
//    `AppData.settings.leadDays` (default 7); `computeDue` itself keeps
//    `leadDays` as a required positional parameter exactly as §9.3 has it.
//    Never write the literal 7 at a call site — P2-D-09 anchors the phase's
//    ODO-error threshold to this same default and tracks it if the value
//    ever changes.
// 5. P3-D-01 (Phase 3): `isEstimate` was a single stored flag collapsing two
//    different causes — the ODO reading being stale (`daysSinceOdo > 45`)
//    and the item's baseline being a guess (`item.baselineIsGuess`) — into
//    one boolean. HOME-05 needs three distinct renderings with two
//    different action buttons, which a single flag cannot express. The two
//    causes are now stored independently as `odoIsStale`/`baselineIsGuess`,
//    and `isEstimate` becomes a derived getter (their OR) so every existing
//    caller keeps compiling and keeps reading the same truth table. The
//    45-day threshold and the guessed-baseline test stay in this file alone
//    (§5.3 — widgets never compute item status themselves), so a card
//    widget can never re-derive 45 days and drift away from this
//    definition. Precedence when both are true (which string a widget
//    shows) is plan 06's job, not this file's — `baselineIsGuess` wins the
//    wording there because a missing real baseline is the larger admission.
//
// `_dateOnly` normalisation stays on `daysLeft` — a 23-hour gap must not
// read as one day (§9.3's own Dart-trap callout; CLAUDE.md flags the same
// truncation twice).
import 'models/maintenance_item.dart';
import 'models/vehicle.dart';
import 'odo.dart';

enum DueStatus { ok, dueSoon, dueToday, overdue }

enum DrivenBy { km, time }

class DueResult {
  final DueStatus status;
  final DateTime dueDate;
  final int daysLeft;
  final int? kmLeft;
  final double progress; // 0..1+
  final DrivenBy drivenBy;
  final bool odoIsStale; // P3-D-01: daysSinceOdo > 45
  final bool baselineIsGuess; // P3-D-01: mirrors item.baselineIsGuess
  bool get isEstimate =>
      odoIsStale ||
      baselineIsGuess; // ODO đã cũ hoặc mốc là giả định — derived, not stored

  const DueResult({
    required this.status,
    required this.dueDate,
    required this.daysLeft,
    required this.progress,
    required this.drivenBy,
    required this.odoIsStale,
    required this.baselineIsGuess,
    this.kmLeft,
  });
}

DueResult? computeDue(
  MaintenanceItem item,
  Vehicle vehicle,
  int leadDays, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now().toUtc();

  if (!item.enabled) return null;
  if (item.lastServiceDate == null && item.lastServiceOdo == null) {
    return null;
  }

  final avg = vehicle.avgDailyKm <= 0 ? 0.5 : vehicle.avgDailyKm;
  final daysSinceOdo = n.difference(vehicle.odoUpdatedAt).inDays;
  final estOdo = estimateOdo(vehicle, now: n);

  DateTime? dueByKm;
  int? kmLeft;
  var progress = 0.0;

  if (item.intervalKm != null && item.lastServiceOdo != null) {
    final target = item.lastServiceOdo! + item.intervalKm!;
    kmLeft = target - estOdo;
    progress = 1 - kmLeft / item.intervalKm!;
    dueByKm = n.add(Duration(days: (kmLeft / avg).round()));
  }

  DateTime? dueByTime;
  if (item.intervalMonths != null && item.lastServiceDate != null) {
    // Local civil components: the anniversary a user means by "three months
    // after I changed the oil" is a date on their calendar, not on UTC's.
    final d = item.lastServiceDate!.toLocal();
    // Clamp to the target month's real length. `DateTime` NORMALISES an
    // out-of-range day instead of rejecting it, so a baseline on the 29th–31st
    // silently rolls forward: 31 Jan + 1 month became 3 Mar, and 30 Nov +
    // 3 months became 2 Mar — a 1–3 day drift on an app that promises the
    // right day. Onboarding writes `lastServiceDate` as commit-date minus N
    // days, so every user who sets up near a month end hits it.
    // `DateTime(y, m + 1, 0)` is the last day of month `m`; day 0 normalises
    // backwards, and an out-of-range month normalises into the next year.
    final targetMonth = d.month + item.intervalMonths!;
    final lastDayOfTarget = DateTime(d.year, targetMonth + 1, 0).day;
    dueByTime = DateTime(
      d.year,
      targetMonth,
      d.day < lastDayOfTarget ? d.day : lastDayOfTarget,
    );
    final p = _timeProgress(d, dueByTime, n);
    if (p > progress) progress = p;
  }

  final DateTime dueDate;
  final DrivenBy drivenBy;
  if (dueByKm != null && dueByTime != null) {
    if (dueByKm.isBefore(dueByTime)) {
      dueDate = dueByKm;
      drivenBy = DrivenBy.km;
    } else {
      dueDate = dueByTime;
      drivenBy = DrivenBy.time;
    }
  } else if (dueByKm != null) {
    dueDate = dueByKm;
    drivenBy = DrivenBy.km;
  } else if (dueByTime != null) {
    dueDate = dueByTime;
    drivenBy = DrivenBy.time;
  } else {
    // Neither axis is computable: the item carries a baseline, but not on an
    // axis it has an interval for (e.g. `lastServiceOdo` set while
    // `intervalKm` is null and `lastServiceDate` is null). The both-null guard
    // above is an AND, so such an item reaches here — and the previous
    // `dueByTime!` threw on it, taking down the whole `dueItemsProvider` for
    // that vehicle. Onboarding always writes both baselines together so it is
    // unreachable today, but `computeDue` is a public pure-Dart API that
    // Phase 3's service log, item editing and Phase 5's Drive restore all
    // call. Returning null is the same contract the disabled-item and
    // baseline-less guards already use: no due date is computable, so there
    // is none to report — never a crash.
    return null;
  }

  final daysLeft = _dateOnly(dueDate).difference(_dateOnly(n)).inDays;

  final status = daysLeft < 0
      ? DueStatus.overdue
      : daysLeft == 0
      ? DueStatus.dueToday
      : (daysLeft <= leadDays || progress >= 0.9)
      ? DueStatus.dueSoon
      : DueStatus.ok;

  return DueResult(
    status: status,
    dueDate: dueDate,
    daysLeft: daysLeft,
    kmLeft: kmLeft,
    progress: progress,
    drivenBy: drivenBy,
    odoIsStale: daysSinceOdo > 45,
    baselineIsGuess: item.baselineIsGuess,
  );
}

/// The LOCAL civil date `d` falls on, at midnight. `toLocal()` first is the
/// whole point: a UTC-anchored instant carries UTC's calendar date, which at
/// UTC+7 is the previous day for the first seven hours of every local day.
/// Both sides of every calendar-day comparison go through here, so the
/// normalisation stays symmetric — a 23-hour gap still must not read as one
/// day (§9.3's own Dart-trap callout; CLAUDE.md flags the same truncation
/// twice).
DateTime _dateOnly(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Locked implementation of the time-axis progress fraction (02-RESEARCH.md
/// Assumptions Log A4 — the source document names `_timeProgress` but never
/// gives its body). Guards the divide-by-zero an `intervalMonths` of 0
/// would otherwise cause.
double _timeProgress(DateTime last, DateTime due, DateTime now) {
  final l = _dateOnly(last);
  final d = _dateOnly(due);
  final n = _dateOnly(now);
  final total = d.difference(l).inDays;
  if (total <= 0) return 0.0;
  return n.difference(l).inDays / total;
}
