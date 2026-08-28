// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'misc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OdoReading _$OdoReadingFromJson(Map<String, dynamic> json) => _OdoReading(
  id: json['id'] as String,
  vehicleId: json['vehicleId'] as String,
  odoKm: (json['odoKm'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  source:
      $enumDecodeNullable(_$OdoSourceEnumMap, json['source']) ??
      OdoSource.manual,
);

Map<String, dynamic> _$OdoReadingToJson(_OdoReading instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicleId': instance.vehicleId,
      'odoKm': instance.odoKm,
      'date': instance.date.toIso8601String(),
      'source': _$OdoSourceEnumMap[instance.source]!,
    };

const _$OdoSourceEnumMap = {
  OdoSource.manual: 'manual',
  OdoSource.service: 'service',
  OdoSource.setup: 'setup',
};

_Note _$NoteFromJson(Map<String, dynamic> json) => _Note(
  id: json['id'] as String,
  vehicleId: json['vehicleId'] as String?,
  itemId: json['itemId'] as String?,
  title: json['title'] as String?,
  body: json['body'] as String? ?? '',
  pinned: json['pinned'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$NoteToJson(_Note instance) => <String, dynamic>{
  'id': instance.id,
  'vehicleId': instance.vehicleId,
  'itemId': instance.itemId,
  'title': instance.title,
  'body': instance.body,
  'pinned': instance.pinned,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

_Settings _$SettingsFromJson(Map<String, dynamic> json) => _Settings(
  notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
  odoReminderEnabled: json['odoReminderEnabled'] as bool? ?? true,
  odoReminderDayOfMonth: (json['odoReminderDayOfMonth'] as num?)?.toInt() ?? 1,
  notifyHour: (json['notifyHour'] as num?)?.toInt() ?? 8,
  leadDays: (json['leadDays'] as num?)?.toInt() ?? 7,
  driveBackupEnabled: json['driveBackupEnabled'] as bool? ?? false,
  lastBackupAt: json['lastBackupAt'] == null
      ? null
      : DateTime.parse(json['lastBackupAt'] as String),
  lastBackupError: json['lastBackupError'] as String?,
  googleEmail: json['googleEmail'] as String?,
  lastNotificationFiredAt: json['lastNotificationFiredAt'] == null
      ? null
      : DateTime.parse(json['lastNotificationFiredAt'] as String),
);

Map<String, dynamic> _$SettingsToJson(_Settings instance) => <String, dynamic>{
  'notificationsEnabled': instance.notificationsEnabled,
  'odoReminderEnabled': instance.odoReminderEnabled,
  'odoReminderDayOfMonth': instance.odoReminderDayOfMonth,
  'notifyHour': instance.notifyHour,
  'leadDays': instance.leadDays,
  'driveBackupEnabled': instance.driveBackupEnabled,
  'lastBackupAt': instance.lastBackupAt?.toIso8601String(),
  'lastBackupError': instance.lastBackupError,
  'googleEmail': instance.googleEmail,
  'lastNotificationFiredAt': instance.lastNotificationFiredAt
      ?.toIso8601String(),
};
