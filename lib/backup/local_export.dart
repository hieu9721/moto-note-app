// lib/backup/local_export.dart — the fourth and last file under lib/backup/
// (05-06). "Xuất file" (BKP-11) is the stated mitigation for the one real
// cost of the drive.appdata scope (§7.2): appDataFolder is invisible in the
// Drive UI, so the user cannot see or copy their own backup — this button
// hands them a copy directly, through the OS share sheet. Only this file
// imports package:share_plus, mirroring the "only the service layer imports
// the plugin" rule the other three files under lib/backup/ already follow.
import 'dart:convert';
import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../domain/models/app_data.dart';

/// [NEW, PROVISIONAL] filename prefix. The full name is this prefix plus a
/// local-time stamp — deliberately local, not UTC, unlike every other
/// timestamp in this project: the string exists only so a person can
/// recognise the file later in whatever app they shared it into, and a UTC
/// stamp on a device several hours off UTC would name the file for a time
/// that never happened on the user's own clock. Nothing in this app ever
/// parses this string back.
const kExportFilePrefix = 'motonote-export-';

/// Re-encodes [data] — the in-memory document the user is already looking
/// at — into a fresh timestamped copy inside [dir], removes any previous
/// export first (P5-D-30, so at most one ever exists), and hands the new
/// file to the OS share sheet through `share_plus` 13.3.0's current
/// instance-based entry point. The deprecated static share class is never
/// used here — every one of its methods carries a deprecation annotation in
/// the resolved 13.3.0 source, and it is what every pre-2025 tutorial shows.
///
/// This function never reads a file from disk — it only re-encodes [data],
/// which the caller already holds in memory. `AppDataRepository`'s own
/// write path renames a temp file over the live document's exact path as
/// its atomic step, so a reader could catch that document mid-swap; the
/// in-memory [data] passed in here carries no such race, which is the
/// entire reason this function takes the document rather than a path
/// (P5-D-23).
///
/// [dir] is taken as a parameter rather than resolved internally, following
/// the constructor-injected-filesystem discipline `AppDataRepository` and
/// `receiptsDirIn` already use (P1-D-11) — it keeps this file testable in
/// principle and keeps path resolution in one place.
///
/// Failures propagate to the caller uncaught, so the Settings row that
/// calls this can report them.
Future<void> exportAppData(AppData data, Directory dir) async {
  // P5-D-30: delete any previous export before writing the new one, scoped
  // strictly to files whose name starts with kExportFilePrefix — that scope
  // cannot collide with any of the other named files this app writes to
  // this same directory, and nothing else here belongs to another owner. A
  // delete that throws must not abort the export; log it and carry on,
  // because failing to tidy up an old copy is not a reason to refuse the
  // user their data.
  await for (final entity in dir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.startsWith(kExportFilePrefix)) continue;
    try {
      await entity.delete();
    } catch (e) {
      _log('failed to remove previous export "$name": $e');
    }
  }

  final file = File('${dir.path}/$kExportFilePrefix${_timestamp()}.json');
  // Re-encode the document passed in — never read anything from disk.
  await file.writeAsString(jsonEncode(data.toJson()), flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      // [NEW, PROVISIONAL]
      subject: 'MotoNote — xuất dữ liệu',
    ),
  );
}

/// Local-time `yyyyMMdd-HHmmss`, zero-padded in the same style
/// `AppDataRepository`'s own quarantine stamp uses — deliberately
/// `DateTime.now()`, not `.toUtc()` (see the doc comment on
/// [kExportFilePrefix]).
String _timestamp() {
  final now = DateTime.now();
  String pad2(int n) => n.toString().padLeft(2, '0');
  return '${now.year}${pad2(now.month)}${pad2(now.day)}'
      '-${pad2(now.hour)}${pad2(now.minute)}${pad2(now.second)}';
}

void _log(String message) {
  // ignore: avoid_print
  print('local_export: $message');
}
