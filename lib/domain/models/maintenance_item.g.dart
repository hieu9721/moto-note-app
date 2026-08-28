// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MaintenanceItem _$MaintenanceItemFromJson(Map<String, dynamic> json) =>
    _MaintenanceItem(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      catalogCode: json['catalogCode'] as String,
      name: json['name'] as String,
      intervalKm: (json['intervalKm'] as num?)?.toInt(),
      intervalMonths: (json['intervalMonths'] as num?)?.toInt(),
      enabled: json['enabled'] as bool? ?? true,
      lastServiceOdo: (json['lastServiceOdo'] as num?)?.toInt(),
      lastServiceDate: json['lastServiceDate'] == null
          ? null
          : DateTime.parse(json['lastServiceDate'] as String),
      baselineIsGuess: json['baselineIsGuess'] as bool? ?? true,
      partBrand: json['partBrand'] as String?,
      partSpec: json['partSpec'] as String?,
      oilGrade: $enumDecodeNullable(_$OilGradeEnumMap, json['oilGrade']),
      lastCostVnd: (json['lastCostVnd'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MaintenanceItemToJson(_MaintenanceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicleId': instance.vehicleId,
      'catalogCode': instance.catalogCode,
      'name': instance.name,
      'intervalKm': instance.intervalKm,
      'intervalMonths': instance.intervalMonths,
      'enabled': instance.enabled,
      'lastServiceOdo': instance.lastServiceOdo,
      'lastServiceDate': instance.lastServiceDate?.toIso8601String(),
      'baselineIsGuess': instance.baselineIsGuess,
      'partBrand': instance.partBrand,
      'partSpec': instance.partSpec,
      'oilGrade': _$OilGradeEnumMap[instance.oilGrade],
      'lastCostVnd': instance.lastCostVnd,
      'notes': instance.notes,
    };

const _$OilGradeEnumMap = {
  OilGrade.mineral: 'mineral',
  OilGrade.semiSynthetic: 'semiSynthetic',
  OilGrade.fullSynthetic: 'fullSynthetic',
};
