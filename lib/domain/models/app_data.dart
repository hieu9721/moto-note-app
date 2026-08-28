// lib/domain/models/app_data.dart — the root document (§4.1). Pure Dart (D-31).
//
// Fields are declared in §4.1's order, but this plan only includes the ones
// whose types exist yet: schemaVersion, updatedAt, deviceLabel, odoReadings,
// notes, settings. Plan 01-03 inserts `vehicles`, `items` and `logs` into
// their §4.1 positions once those models exist — a purely additive change
// that needs no migration (D-21).
import 'package:freezed_annotation/freezed_annotation.dart';

import 'misc.dart';

part 'app_data.freezed.dart';
part 'app_data.g.dart';

// P1-D-08: kSchemaVersion is 1 and migrateRaw ships with no migration branch —
// the app has never released, so no v0 document exists anywhere.
const int kSchemaVersion = 1;

@freezed
abstract class AppData with _$AppData {
  const factory AppData({
    @Default(kSchemaVersion) int schemaVersion,
    required DateTime updatedAt,
    @Default('') String deviceLabel,
    @Default([]) List<OdoReading> odoReadings,
    @Default([]) List<Note> notes,
    required Settings settings,
  }) = _AppData;

  factory AppData.fromJson(Map<String, dynamic> json) =>
      _$AppDataFromJson(json);

  factory AppData.empty() =>
      AppData(updatedAt: DateTime.now(), settings: const Settings());
}
