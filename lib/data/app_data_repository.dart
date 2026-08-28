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

  static const _fileName = 'appdata.json';
  static const _tmpName = 'appdata.json.tmp';
  static const _backupName = 'appdata.backup.json';

  File get _target => File('${_dir.path}/$_fileName');
  File get _tmp => File('${_dir.path}/$_tmpName');
  File get _backup => File('${_dir.path}/$_backupName');

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
}
