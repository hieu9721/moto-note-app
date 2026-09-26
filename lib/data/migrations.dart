// lib/data/migrations.dart — §4.4, adapted per P1-D-08. Runs on every raw
// JSON map before AppData.fromJson, for both locally loaded and (from
// plan 01-05 onward) Drive-restored data. D-21: additive only — only add
// fields, never rename, never delete.
import '../domain/models/app_data.dart';

/// P1-D-09: thrown by [migrateRaw] when a document's `schemaVersion` is
/// greater than [kSchemaVersion] — a document written by a newer build than
/// this one understands. Thrown BEFORE any mutation of the input map, so a
/// forward-version document is never downgraded and never has fields
/// silently dropped by a `toJson` that doesn't know about them.
///
/// Locally this is handled on the P1-D-07 corrupt/quarantine path. For the
/// Phase 5 restore flow it must stop the restore and leave existing data
/// untouched, telling the user to update the app — which is why this carries
/// [found] and [supported] as distinct, typed fields rather than collapsing
/// into a generic decode failure.
class SchemaTooNewException implements Exception {
  const SchemaTooNewException({required this.found, required this.supported});

  /// The `schemaVersion` found in the document.
  final int found;

  /// The `kSchemaVersion` this build supports.
  final int supported;

  @override
  String toString() =>
      'SchemaTooNewException: document schemaVersion $found is newer than '
      'this build supports (kSchemaVersion=$supported)';
}

/// P1-D-08: kSchemaVersion is 1 and no migration branch ships yet — the app
/// has never shipped, so no v0 or pre-1 document exists anywhere in the
/// world. The forward-version guard below (P1-D-09) is the only branch this
/// gains in plan 01-04.
Map<String, dynamic> migrateRaw(Map<String, dynamic> raw) {
  final data = Map<String, dynamic>.from(raw);
  final from = (data['schemaVersion'] as int?) ?? 0;

  // P1-D-09: refuse a forward-version document before any other work and
  // before the version stamp below, so the input map is never mutated.
  if (from > kSchemaVersion) {
    throw SchemaTooNewException(found: from, supported: kSchemaVersion);
  }

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
