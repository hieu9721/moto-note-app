// lib/data/app_data_repository.dart — §5.1 atomic write + backup fallback.
//
// P1-D-11: the Directory is injected through the constructor rather than
// resolved internally via a platform directory API. This is what lets the
// class run under plain `dart test` against Directory.systemTemp.createTemp(), with
// no device and no mock standing between the test and the real filesystem —
// the single code path standing between the user and total data loss.
//
// load() currently returns `null` for "no data yet" (missing file, or both
// primary and backup failed to decode). Plan 01-04 widens this to the
// three-outcome contract of P1-D-07 (loaded / no-file / corrupt-with-rename);
// this shape can be widened without changing call sites since the only call
// site until then is this plan's test.
import 'dart:convert';
import 'dart:io';

import '../domain/models/app_data.dart';
import 'migrations.dart';

class AppDataRepository {
  AppDataRepository(this._dir);

  final Directory _dir;

  static const _fileName = 'appdata.json';
  static const _tmpName = 'appdata.json.tmp';
  static const _backupName = 'appdata.backup.json';

  File get _target => File('${_dir.path}/$_fileName');
  File get _tmp => File('${_dir.path}/$_tmpName');
  File get _backup => File('${_dir.path}/$_backupName');

  Future<AppData?> load() async {
    if (await _target.exists()) {
      final decoded = await _tryDecode(_target);
      if (decoded != null) return decoded;
    }
    return _loadBackup();
  }

  Future<AppData?> _loadBackup() async {
    if (!await _backup.exists()) return null;
    return _tryDecode(_backup);
  }

  Future<AppData?> _tryDecode(File file) async {
    try {
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AppData.fromJson(migrateRaw(raw));
    } catch (_) {
      // Undecodable — the caller falls back to the backup copy. Plan 01-04
      // adds the corrupt-file rename (P1-D-07) at this point.
      return null;
    }
  }

  Future<void> save(AppData data) async {
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
