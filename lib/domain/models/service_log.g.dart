// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceLogEntry _$ServiceLogEntryFromJson(Map<String, dynamic> json) =>
    _ServiceLogEntry(
      itemId: json['itemId'] as String,
      costVnd: (json['costVnd'] as num?)?.toInt(),
      partBrand: json['partBrand'] as String?,
      partSpec: json['partSpec'] as String?,
      resetsCycle: json['resetsCycle'] as bool? ?? true,
    );

Map<String, dynamic> _$ServiceLogEntryToJson(_ServiceLogEntry instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'costVnd': instance.costVnd,
      'partBrand': instance.partBrand,
      'partSpec': instance.partSpec,
      'resetsCycle': instance.resetsCycle,
    };

_ServiceLog _$ServiceLogFromJson(Map<String, dynamic> json) => _ServiceLog(
  id: json['id'] as String,
  vehicleId: json['vehicleId'] as String,
  date: DateTime.parse(json['date'] as String),
  odoKm: (json['odoKm'] as num).toInt(),
  shopName: json['shopName'] as String?,
  totalCostVnd: (json['totalCostVnd'] as num?)?.toInt(),
  note: json['note'] as String?,
  photoPaths:
      (json['photoPaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => ServiceLogEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ServiceLogToJson(_ServiceLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicleId': instance.vehicleId,
      'date': instance.date.toIso8601String(),
      'odoKm': instance.odoKm,
      'shopName': instance.shopName,
      'totalCostVnd': instance.totalCostVnd,
      'note': instance.note,
      'photoPaths': instance.photoPaths,
      'entries': instance.entries,
    };
