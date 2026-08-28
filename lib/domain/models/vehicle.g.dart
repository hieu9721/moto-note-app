// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Vehicle _$VehicleFromJson(Map<String, dynamic> json) => _Vehicle(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$VehicleTypeEnumMap, json['type']),
  plate: json['plate'] as String?,
  brand: json['brand'] as String?,
  model: json['model'] as String?,
  year: (json['year'] as num?)?.toInt(),
  photoPath: json['photoPath'] as String?,
  currentOdoKm: (json['currentOdoKm'] as num).toInt(),
  odoUpdatedAt: DateTime.parse(json['odoUpdatedAt'] as String),
  avgDailyKm: (json['avgDailyKm'] as num).toDouble(),
  avgDailyKmSource:
      $enumDecodeNullable(_$AvgKmSourceEnumMap, json['avgDailyKmSource']) ??
      AvgKmSource.user,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$VehicleToJson(_Vehicle instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$VehicleTypeEnumMap[instance.type]!,
  'plate': instance.plate,
  'brand': instance.brand,
  'model': instance.model,
  'year': instance.year,
  'photoPath': instance.photoPath,
  'currentOdoKm': instance.currentOdoKm,
  'odoUpdatedAt': instance.odoUpdatedAt.toIso8601String(),
  'avgDailyKm': instance.avgDailyKm,
  'avgDailyKmSource': _$AvgKmSourceEnumMap[instance.avgDailyKmSource]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$VehicleTypeEnumMap = {
  VehicleType.scooter: 'scooter',
  VehicleType.underbone: 'underbone',
  VehicleType.manual: 'manual',
};

const _$AvgKmSourceEnumMap = {
  AvgKmSource.user: 'user',
  AvgKmSource.computed: 'computed',
};
