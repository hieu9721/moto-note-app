// lib/backup/drive_service.dart — the only file that imports
// `package:googleapis/drive/v3.dart` directly, mirroring
// `google_auth.dart`'s "only this file imports the plugin" rule. Takes an
// already-authenticated `http.Client` — this class knows nothing about
// sign-in, only about Drive's `appDataFolder` REST surface (BKP-05).
//
// Every call shape below is transcribed from the actual resolved
// `googleapis` 17.0.0 source read this session (05-RESEARCH.md Architecture
// Pattern 2), not guessed from the source document's older §7.4 sample.
import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
// `http` is a transitive dependency of `googleapis`/the sign-in extension,
// not a direct entry in pubspec.yaml — which the plan requires to stay
// byte-identical (task 2). Importing it directly for the constructor's
// parameter type is correct (this file IS the Drive REST client wrapper),
// so the resulting `depend_on_referenced_packages` info is suppressed
// rather than worked around with a weaker `dynamic` type.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import '../data/migrations.dart';
import '../domain/models/app_data.dart';

// Re-exported so `google_auth.dart` can build `kDriveScopes` from
// `DriveApi.driveAppdataScope`, and `backup_service.dart` can classify a
// `DetailedApiRequestError`'s status code, without either file importing
// `package:googleapis/` directly — this file stays the ONLY one under
// `lib/` whose source text names that package (acceptance criterion, task
// 2). `DetailedApiRequestError` is defined in `_discoveryapis_commons` but
// re-exported by `package:googleapis/drive/v3.dart` itself.
export 'package:googleapis/drive/v3.dart'
    show DriveApi, DetailedApiRequestError;

/// The single backup document's fixed name inside `appDataFolder`.
const kBackupFileName = 'motonote-backup.json';

/// The Drive "space" this whole file confines itself to — invisible in the
/// Drive UI by design (§7.2), and the mechanism D-22's scope restriction
/// actually enforces at the API level.
const kAppDataSpace = 'appDataFolder';

/// Kept minimal and explicit — over-fetching costs quota, and every field
/// below is what `peek()`/`upload()` actually need.
const _metaFields = 'files(id, modifiedTime, size, appProperties)';

/// A metadata-only summary of the remote backup file — never carries the
/// file body. Produced by `peek()` from a single `files.list` call, never
/// from a downloaded file (BKP-05, P5-D-21).
class BackupInfo {
  BackupInfo({
    required this.modifiedAt,
    required this.sizeBytes,
    required this.vehicleCount,
    required this.logCount,
  });

  final DateTime modifiedAt;
  final int sizeBytes;
  final int vehicleCount;
  final int logCount;
}

class DriveService {
  DriveService(http.Client authenticatedClient)
      : _api = drive.DriveApi(authenticatedClient);

  final drive.DriveApi _api;

  /// `spaces` is mandatory on every `files.list` call this class makes —
  /// omitting it queries the regular `'drive'` space and returns an empty
  /// list with no error (RESEARCH Pitfall 6), which would make `_find()`
  /// read "no backup exists" on every call, so `upload()` would always take
  /// the create branch and accumulate duplicate files invisible in the
  /// Drive UI.
  Future<drive.File?> _find() async {
    final list = await _api.files.list(
      spaces: kAppDataSpace,
      q: "name = '$kBackupFileName'",
      $fields: _metaFields,
    );
    final files = list.files;
    return (files == null || files.isEmpty) ? null : files.first;
  }

  /// BKP-05: metadata-only — `_find()` only, never `downloadOptions:
  /// DownloadOptions.fullMedia`. A missing file is the normal first-run
  /// state and returns null, not an error. `size` and the `appProperties`
  /// counts are wire-format strings in the generated client (RESEARCH
  /// Pitfall 5) and degrade to `0` on a missing or unparseable value rather
  /// than throwing (P5-D-21) — a less-informative summary is preferable to
  /// downloading a 200 KB body just to count two integers (D-19).
  Future<BackupInfo?> peek() async {
    final f = await _find();
    if (f == null) return null;
    final props = f.appProperties ?? const {};
    return BackupInfo(
      modifiedAt: f.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      sizeBytes: int.tryParse(f.size ?? '') ?? 0,
      vehicleCount: int.tryParse(props['vehicles'] ?? '') ?? 0,
      logCount: int.tryParse(props['logs'] ?? '') ?? 0,
    );
  }

  /// Create-or-update by `_find()`. `appProperties` values are written as
  /// strings (`File.appProperties` is `Map<String, String?>` — RESEARCH
  /// Pitfall 5). The literal `'appDataFolder'` in `parents` on the create
  /// branch IS the mechanism that places the file there — there is no
  /// separate `spaces:` create parameter. Uses the default (non-resumable)
  /// upload options: the document is always well under 200 KB (§2), so a
  /// resumable upload would add retry/chunk complexity D-17 already
  /// declines.
  Future<void> upload(AppData data) async {
    final bytes = utf8.encode(jsonEncode(data.toJson()));
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
    final props = <String, String>{
      'vehicles': data.vehicles.length.toString(),
      'logs': data.logs.length.toString(),
      'schema': data.schemaVersion.toString(),
    };
    final existing = await _find();
    if (existing != null) {
      await _api.files.update(
        drive.File(appProperties: props),
        existing.id!,
        uploadMedia: media,
      );
    } else {
      await _api.files.create(
        drive.File(
          name: kBackupFileName,
          parents: const [kAppDataSpace],
          appProperties: props,
        ),
        uploadMedia: media,
      );
    }
  }

  /// Reuses `migrateRaw` — the downloaded document goes through exactly the
  /// same validation boundary as the local load path
  /// (`lib/data/app_data_repository.dart`'s own `load()`), no shortcut for
  /// the network path. May throw `SchemaTooNewException` (via `migrateRaw`)
  /// or `FormatException` (malformed JSON) — the caller must catch both
  /// (P1-D-09); this plan's manual trigger never calls `download()`, 05-03
  /// owns that flow and its error rendering.
  Future<AppData> download() async {
    final f = await _find();
    if (f == null) {
      throw StateError('no backup file found in appDataFolder');
    }
    final media =
        await _api.files.get(
              f.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final bytes = await media.stream.expand((chunk) => chunk).toList();
    final raw = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return AppData.fromJson(migrateRaw(raw));
  }
}
