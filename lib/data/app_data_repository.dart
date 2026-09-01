// lib/data/app_data_repository.dart — §5.1 atomic write + backup fallback,
// widened per P1-D-07/P1-D-09 (plan 01-04).
//
// P1-D-11: the Directory is injected through the constructor rather than
// resolved internally via a platform directory API. This is what lets the
// class run under plain `dart test` against Directory.systemTemp.createTemp(), with
// no device and no mock standing between the test and the real filesystem —
// the single code path standing between the user and total data loss.
import 'dart:convert';
import 'dart:io';

import '../domain/models/app_data.dart';
import 'migrations.dart';

/// P1-D-07: `load()` reports one of four outcomes rather than a bare
/// nullable `AppData?`. Modeled as a sealed class so a `switch` over it is
/// exhaustive at compile time — a caller that forgets a case fails to
/// compile rather than falling through silently.
sealed class AppDataLoadResult {
  const AppDataLoadResult();
}

/// A document was found (primary or backup) and decoded successfully.
final class AppDataLoaded extends AppDataLoadResult {
  const AppDataLoaded(this.data);

  final AppData data;
}

/// No document exists yet — a fresh install / new device. Nothing was
/// written and nothing was renamed.
final class AppDataNotFound extends AppDataLoadResult {
  const AppDataNotFound();
}

/// The primary document exists but could not be decoded (and either there
/// is no backup, or the backup could not be decoded either). The unreadable
/// primary has already been quarantined to [quarantinePath] before this
/// outcome is returned.
final class AppDataUndecodable extends AppDataLoadResult {
  const AppDataUndecodable(this.quarantinePath);

  final String quarantinePath;
}

/// The primary document exists and decodes as JSON, but is stamped with a
/// `schemaVersion` newer than this build's [kSchemaVersion]. Kept distinct
/// from [AppDataUndecodable] because Phase 5's restore flow must tell the
/// user to update the app rather than report corruption (P1-D-09); the
/// local path treats both the same way. The document has already been
/// quarantined to [quarantinePath] before this outcome is returned.
final class AppDataSchemaTooNew extends AppDataLoadResult {
  const AppDataSchemaTooNew({
    required this.found,
    required this.supported,
    required this.quarantinePath,
  });

  final int found;
  final int supported;
  final String quarantinePath;
}

class AppDataRepository {
  AppDataRepository(this._dir);

  final Directory _dir;

  /// The injected documents directory (P1-D-11), exposed read-only so a
  /// caller that already holds the repository — e.g. the "Xuất file" row,
  /// per 05-06-PLAN.md's own read_first note — can reuse it instead of
  /// resolving it a second time through `path_provider`.
  Directory get documentsDirectory => _dir;

  static const _fileName = 'appdata.json';
  static const _tmpName = 'appdata.json.tmp';
  static const _backupName = 'appdata.backup.json';
  static const _preRestoreName = 'appdata.pre-restore.json';
  static const _preRestoreTmpName = 'appdata.pre-restore.json.tmp';

  File get _target => File('${_dir.path}/$_fileName');
  File get _tmp => File('${_dir.path}/$_tmpName');
  File get _backup => File('${_dir.path}/$_backupName');
  File get _preRestore => File('${_dir.path}/$_preRestoreName');
  File get _preRestoreTmp => File('${_dir.path}/$_preRestoreTmpName');

  /// P1-D-06/T-01-11: chains every [save] call onto the previous write, so
  /// only one write is ever in flight against [_tmp]. Closes an open Dart
  /// SDK race (dart-lang/tools#1255) in which two overlapping
  /// `writeAsString(..., flush: true)` calls to the same path interleave and
  /// corrupt the result — reachable here from a rapid double-tap, since
  /// every save() targets the same tmp path.
  Future<void> _lastWrite = Future.value();

  Future<AppDataLoadResult> load() async {
    if (!await _target.exists()) {
      return _loadBackupOnly();
    }

    final rawPrimary = await _target.readAsString();
    final Map<String, dynamic> decodedPrimary;
    try {
      decodedPrimary = jsonDecode(rawPrimary) as Map<String, dynamic>;
    } catch (_) {
      return _quarantinePrimaryAndFallBack();
    }

    try {
      final migrated = migrateRaw(decodedPrimary);
      return AppDataLoaded(AppData.fromJson(migrated));
    } on SchemaTooNewException catch (e) {
      final quarantinePath = await _quarantine(_target);
      _log(
        'primary schemaVersion ${e.found} is newer than supported '
        '${e.supported} — quarantined to $quarantinePath',
      );
      return AppDataSchemaTooNew(
        found: e.found,
        supported: e.supported,
        quarantinePath: quarantinePath,
      );
    } catch (_) {
      // A decodable-but-malformed primary (e.g. AppData.fromJson throws a
      // TypeError on an unexpected shape) is treated the same as an
      // undecodable one.
      return _quarantinePrimaryAndFallBack();
    }
  }

  /// Primary is undecodable (or malformed past decode). Falls back to the
  /// backup copy if it decodes, then quarantines the primary either way —
  /// losing one mutation is better than losing the session, and the primary
  /// is quarantined regardless so nothing is destroyed.
  Future<AppDataLoadResult> _quarantinePrimaryAndFallBack() async {
    final backupData = await _tryDecodeBackup();
    final quarantinePath = await _quarantine(_target);
    if (backupData != null) {
      _log(
        'primary undecodable, fell back to backup; quarantined primary to '
        '$quarantinePath',
      );
      return AppDataLoaded(backupData);
    }
    _log(
      'primary undecodable, no usable backup; quarantined to $quarantinePath',
    );
    return AppDataUndecodable(quarantinePath);
  }

  /// No primary file exists. Falls back to the backup if present and
  /// decodable; otherwise reports the no-data outcome. There is no primary
  /// to quarantine in this branch.
  Future<AppDataLoadResult> _loadBackupOnly() async {
    final backupData = await _tryDecodeBackup();
    if (backupData != null) return AppDataLoaded(backupData);
    return const AppDataNotFound();
  }

  Future<AppData?> _tryDecodeBackup() async {
    if (!await _backup.exists()) return null;
    try {
      final raw =
          jsonDecode(await _backup.readAsString()) as Map<String, dynamic>;
      return AppData.fromJson(migrateRaw(raw));
    } catch (_) {
      return null;
    }
  }

  /// P1-D-07: renames (never copy-then-delete) the unreadable/refused file
  /// to `appdata.corrupt.<timestamp>.json` in the same directory, so the
  /// original bytes are never at risk and a subsequent save() from
  /// onboarding creates a fresh `appdata.json` instead of overwriting the
  /// old one. The timestamp is an ISO-8601 basic form with milliseconds,
  /// which sorts chronologically; a numeric suffix is appended only on the
  /// rare collision within the same millisecond, so two successive
  /// quarantines never overwrite each other.
  Future<String> _quarantine(File file) async {
    final stamp = _quarantineTimestamp();
    var candidate = File('${_dir.path}/appdata.corrupt.$stamp.json');
    var attempt = 1;
    while (await candidate.exists()) {
      candidate = File('${_dir.path}/appdata.corrupt.$stamp-$attempt.json');
      attempt++;
    }
    await file.rename(candidate.path);
    return candidate.path;
  }

  String _quarantineTimestamp() {
    final now = DateTime.now().toUtc();
    String pad2(int n) => n.toString().padLeft(2, '0');
    String pad3(int n) => n.toString().padLeft(3, '0');
    return '${now.year}${pad2(now.month)}${pad2(now.day)}'
        'T${pad2(now.hour)}${pad2(now.minute)}${pad2(now.second)}'
        '${pad3(now.millisecond)}Z';
  }

  void _log(String message) {
    // ignore: avoid_print
    print('AppDataRepository: $message');
  }

  /// Chains onto the previous write so only one is ever in flight against
  /// [_tmp]. The future returned to the caller propagates a write failure
  /// normally; the future stored as the next chain link swallows the error,
  /// so a single failed save does not poison every save() call after it.
  Future<void> save(AppData data) {
    final resultFuture = _lastWrite.then((_) => _writeAtomic(data));
    _lastWrite = resultFuture.catchError((_) {});
    return resultFuture;
  }

  Future<void> _writeAtomic(AppData data) async {
    // 1. Write to a temp file first.
    await _tmp.writeAsString(jsonEncode(data.toJson()), flush: true);

    // 2. Preserve the previous good content as the backup — copied from the
    //    existing target, never from the tmp file being written, so the
    //    backup always holds the previous good document.
    if (await _target.exists()) {
      await _target.copy(_backup.path);
    }

    // 3. Atomic rename over the target — the atomic step, since the tmp
    //    file and target are always in the same directory (same filesystem).
    await _tmp.rename(_target.path);
  }

  /// A fourth file in the same atomic-write family (§7.6 Layer 3, BKP-10):
  /// the document about to be overwritten by a restore, written through the
  /// identical write-to-temp-then-rename discipline [_writeAtomic] uses —
  /// minus the backup-copy step, because there is no previous snapshot
  /// worth preserving. A second restore inside the undo window deliberately
  /// replaces the first snapshot rather than keeping it, so a second
  /// restore in a row destroys the device's original data — an accepted,
  /// recorded cost, not a defect. The rename is what moves the file's own
  /// modification time forward, which is what resets the seven-day undo
  /// clock — the single source of truth for the undo window; no field was
  /// added to the document for it, because that metadata is device-local
  /// and must never travel to Drive.
  Future<void> writePreRestoreSnapshot(AppData data) async {
    await _preRestoreTmp.writeAsString(
      jsonEncode(data.toJson()),
      flush: true,
    );
    await _preRestoreTmp.rename(_preRestore.path);
  }

  /// The only fact this repository knows about the undo window — the
  /// snapshot file's own modification time, or null when no snapshot
  /// exists. The seven-day judgment itself belongs to `canUndoRestore` in
  /// `lib/domain/backup_timing.dart`, kept there so the boundary stays
  /// reachable under plain `dart test`; this method does no interval math.
  Future<DateTime?> preRestoreSnapshotModifiedAt() async {
    if (!await _preRestore.exists()) return null;
    return _preRestore.lastModified();
  }

  /// Reads the snapshot through the exact same decode → migrate → validate
  /// boundary [load] uses for the primary document — a device-local file
  /// earns no weaker validation than a downloaded one.
  /// Returns null when the file does not exist. Deliberately does NOT catch
  /// [SchemaTooNewException]: the caller decides what to tell the user, the
  /// same division [load] already uses. Deliberately does NOT apply the
  /// undo-window check here either — reading the document and deciding
  /// whether the window is still open are separate concerns, composed by
  /// the caller.
  Future<AppData?> readPreRestoreSnapshot() async {
    if (!await _preRestore.exists()) return null;
    final raw =
        jsonDecode(await _preRestore.readAsString()) as Map<String, dynamic>;
    return AppData.fromJson(migrateRaw(raw));
  }

  /// Completes the snapshot family (P5-D-28): after a successful undo, the
  /// live document equals what the snapshot held, so the snapshot is
  /// redundant — deleting it is what makes the "Hoàn tác khôi phục" row
  /// disappear, since P5-D-05 makes the file's existence half the
  /// predicate. A missing file is already the correct end state, not an
  /// error — the same honest-no-op discipline this codebase uses for
  /// absent things (T-03-22) — so calling this with no snapshot present
  /// throws nothing. Also removes the temp file if one was somehow left
  /// behind.
  Future<void> deletePreRestoreSnapshot() async {
    if (await _preRestore.exists()) {
      await _preRestore.delete();
    }
    if (await _preRestoreTmp.exists()) {
      await _preRestoreTmp.delete();
    }
  }
}
