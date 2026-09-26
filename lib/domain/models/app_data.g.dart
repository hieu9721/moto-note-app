// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppData _$AppDataFromJson(Map<String, dynamic> json) => _AppData(
  schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? kSchemaVersion,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deviceLabel: json['deviceLabel'] as String? ?? '',
  vehicles:
      (json['vehicles'] as List<dynamic>?)
          ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => MaintenanceItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  logs:
      (json['logs'] as List<dynamic>?)
          ?.map((e) => ServiceLog.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  odoReadings:
      (json['odoReadings'] as List<dynamic>?)
          ?.map((e) => OdoReading.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  notes:
      (json['notes'] as List<dynamic>?)
          ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  settings: Settings.fromJson(json['settings'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AppDataToJson(_AppData instance) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deviceLabel': instance.deviceLabel,
  'vehicles': instance.vehicles,
  'items': instance.items,
  'logs': instance.logs,
  'odoReadings': instance.odoReadings,
  'notes': instance.notes,
  'settings': instance.settings,
};
