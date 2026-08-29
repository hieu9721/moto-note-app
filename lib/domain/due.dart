// lib/domain/due.dart — transcribed from §9.3. Pure Dart (D-31) — this
// directory must never import the Flutter SDK.
//
// Four deliberate adjustments to the source listing, each recorded here:
//
// 1. `now` defaults to `DateTime.now().toUtc()`, not bare `DateTime.now()`.
//    Phase 1 stores every persisted wall-clock timestamp in UTC
//    (app_data.dart:40, app_state.dart:158); comparing a local `now` against
//    a UTC `odoUpdatedAt` would reintroduce an off-by-a-day error near
//    midnight (02-RESEARCH.md Pitfall 2). Asia/Ho_Chi_Minh has no DST, so
//    anchoring to UTC is correctness-neutral provided it is applied on both
//    sides of every comparison — which is the point.
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
  final bool isEstimate; // ODO đã cũ hoặc mốc là giả định

  const DueResult({
    required this.status,
    required this.dueDate,
    required this.daysLeft,
    required this.progress,
    required this.drivenBy,
    required this.isEstimate,
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
    final d = item.lastServiceDate!;
    dueByTime = DateTime(d.year, d.month + item.intervalMonths!, d.day);
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
  } else {
    dueDate = dueByTime!;
    drivenBy = DrivenBy.time;
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
    isEstimate: daysSinceOdo > 45 || item.baselineIsGuess,
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
