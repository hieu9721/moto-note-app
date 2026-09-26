// lib/domain/backup_timing.dart — pure Dart (D-31). This directory must
// never import the Flutter SDK or anything under lib/ui/.
//
// This file exists because CLAUDE.md flags `DateTime.difference().inDays`
// truncation twice as this project's own recurring off-by-one source
// (`lib/domain/due.dart`'s header tells the same story once already). P5-D-18
// is the third amendment to D-32, on the identical rationale P1-D-11 and
// P4-D-13 already established: §9.6 objects to widget tests and mocks, not
// to pure functions under plain `dart test` — so the day-counting this whole
// phase leans on (the >24h automatic-backup rule here; 05-03's
// `driveCopyIsOlder`/`kClockSkewMargin` and 05-04's `canUndoRestore`/
// `kUndoWindow` land in this same file later, each with the plan that first
// needs it) is isolated where it can be pinned by exact-boundary tests
// instead of trusted by inspection.
library;

/// §7.5's "older than 24h" rule, named so the boundary lives in exactly one
/// place and a test can reference it by name instead of a bare literal.
const kBackupInterval = Duration(hours: 24);

/// True when a backup is due: never having backed up (`lastBackupAt == null`)
/// is due immediately; otherwise due only once the gap is STRICTLY greater
/// than [kBackupInterval] — at exactly 24 hours the last backup is not yet
/// *older than* 24 hours. Compares `Duration` values directly; converting to
/// whole days anywhere in this function would make the rule fire a day late
/// (RESEARCH Pitfall 7). A `lastBackupAt` in the future (a device clock moved
/// backwards) yields a negative `Duration`, which is correctly not greater
/// than the interval — not due, and this never throws for that case.
bool isBackupDue(DateTime? lastBackupAt, {DateTime? now}) {
  if (lastBackupAt == null) return true;
  final n = now ?? DateTime.now().toUtc();
  return n.difference(lastBackupAt) > kBackupInterval;
}

/// The human-facing "how long ago" string shared by the Settings status line
/// and 05-03's restore comparison, so the two can never disagree about what
/// a day means. Four bands, in order: under one minute (including any
/// future timestamp, which degrades to the nearest sensible band rather than
/// producing a negative count) → `vừa xong`; under one hour → the whole
/// minute count plus ` phút trước`; under one day → the whole hour count
/// plus ` giờ trước`; otherwise the whole day count plus ` ngày trước`.
///
/// This is the one place in this file where whole-unit (`.inMinutes`/
/// `.inHours`/`.inDays`) conversion is correct, unlike `isBackupDue` above —
/// both timestamps are already UTC instants and the user is being told "how
/// long ago", not "which calendar day" (RESEARCH Pitfall 7). That is a
/// different question from `due.dart`'s `_dateOnly` local-civil-date rule,
/// not an inconsistency with it.
///
/// `ngày trước` and `giờ trước` are sourced verbatim from §7.5/§7.6.
/// `vừa xong` and `phút trước` are invented — `[NEW, PROVISIONAL]`, recorded
/// in this plan's SUMMARY.
String relativeVi(DateTime then, {DateTime? now}) {
  final n = now ?? DateTime.now().toUtc();
  final diff = n.difference(then);
  if (diff < const Duration(minutes: 1)) {
    return 'vừa xong'; // [NEW, PROVISIONAL]
  }
  if (diff < const Duration(hours: 1)) {
    return '${diff.inMinutes} phút trước'; // [NEW, PROVISIONAL]
  }
  if (diff < const Duration(days: 1)) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}

/// P5-D-20: the two-minute clock-skew margin for the §7.6 "⚠ Bản trên
/// Drive CŨ HƠN" comparison. Drive's `modifiedTime` comes from Google's
/// server clock; the local document's `updatedAt` comes from the device
/// clock — two different clocks. A correctly-functioning backup writes
/// Drive about thirty seconds after the local write (the debounce), so a
/// document inside this margin is the same document seen twice, not a
/// stale one. Without the margin, a device clock running a minute fast
/// would make every Drive copy look stale — noise on the one screen where
/// a wrong tap destroys data.
const kClockSkewMargin = Duration(minutes: 2);

/// §7.6's seven-day "Hoàn tác khôi phục" window as a [Duration], so the
/// boundary lives in one place.
const kUndoWindow = Duration(days: 7);

/// True only when the local document is newer than the Drive copy by
/// strictly more than [margin]. Exact equality and anything inside the
/// margin are treated as the same document seen through two clocks, not a
/// stale Drive copy — see [kClockSkewMargin]. A Drive copy that is newer
/// than the local document is never "older", regardless of margin. Named
/// parameters only: two adjacent [DateTime] arguments in the wrong order
/// would invert the warning silently, on the one screen where that matters
/// most.
bool driveCopyIsOlder({
  required DateTime driveModifiedAt,
  required DateTime localUpdatedAt,
  Duration margin = kClockSkewMargin,
}) {
  return localUpdatedAt.difference(driveModifiedAt) > margin;
}

/// True while a pre-restore snapshot (aged by [snapshotModifiedAt]) is
/// still inside [kUndoWindow] — inclusive at exactly seven days, since the
/// requirement says the button "remains available for 7 days" and a
/// boundary that expires AT seven days makes that promise false on its
/// last day. The `now ?? DateTime.now().toUtc()` idiom, matching
/// [isBackupDue]/[relativeVi] above. A [snapshotModifiedAt] slightly in the
/// future (a clock adjustment) yields a negative elapsed duration, which is
/// correctly still within the window — treated as recent, never as
/// expired.
bool canUndoRestore(DateTime snapshotModifiedAt, {DateTime? now}) {
  final n = now ?? DateTime.now().toUtc();
  return n.difference(snapshotModifiedAt) <= kUndoWindow;
}
