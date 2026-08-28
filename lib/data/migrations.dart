// lib/data/migrations.dart — §4.4, adapted per P1-D-08. Runs on every raw
// JSON map before AppData.fromJson, for both locally loaded and (from
// plan 01-05 onward) Drive-restored data. D-21: additive only — only add
// fields, never rename, never delete.
import '../domain/models/app_data.dart';

/// P1-D-08: kSchemaVersion is 1 and no migration branch ships yet — the app
/// has never shipped, so no v0 or pre-1 document exists anywhere in the
/// world. The forward-version guard (P1-D-09 — throwing a typed error when
/// `from > kSchemaVersion`) is added in plan 01-04, not here.
Map<String, dynamic> migrateRaw(Map<String, dynamic> raw) {
  final data = Map<String, dynamic>.from(raw);
  // ignore: unused_local_variable
  final from = (data['schemaVersion'] as int?) ?? 0;

  // if (from < 2) {
  //   // v1 → v2 example additive migration, transcribed from §4.4. NOTE: as
  //   // printed in the source document this branch would re-run forever,
  //   // because it stamps schemaVersion back to 1 (kSchemaVersion) while
  //   // testing `from < 2` — any real branch added here must test against
  //   // the version it migrates *to*, not against kSchemaVersion.
  //   final vehicles = (data['vehicles'] as List? ?? []).map((v) {
  //     final m = Map<String, dynamic>.from(v as Map);
  //     m.putIfAbsent('avgDailyKmSource', () => 'user');
  //     return m;
  //   }).toList();
  //   data['vehicles'] = vehicles;
  // }

  data['schemaVersion'] = kSchemaVersion;
  return data;
}
