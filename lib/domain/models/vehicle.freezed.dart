// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Vehicle {

 String get id; String get name; VehicleType get type; String? get plate; String? get brand; String? get model; int? get year; String? get photoPath; int get currentOdoKm; DateTime get odoUpdatedAt; double get avgDailyKm; AvgKmSource get avgDailyKmSource; DateTime get createdAt;
/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleCopyWith<Vehicle> get copyWith => _$VehicleCopyWithImpl<Vehicle>(this as Vehicle, _$identity);

  /// Serializes this Vehicle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vehicle&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.currentOdoKm, currentOdoKm) || other.currentOdoKm == currentOdoKm)&&(identical(other.odoUpdatedAt, odoUpdatedAt) || other.odoUpdatedAt == odoUpdatedAt)&&(identical(other.avgDailyKm, avgDailyKm) || other.avgDailyKm == avgDailyKm)&&(identical(other.avgDailyKmSource, avgDailyKmSource) || other.avgDailyKmSource == avgDailyKmSource)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,plate,brand,model,year,photoPath,currentOdoKm,odoUpdatedAt,avgDailyKm,avgDailyKmSource,createdAt);

@override
String toString() {
  return 'Vehicle(id: $id, name: $name, type: $type, plate: $plate, brand: $brand, model: $model, year: $year, photoPath: $photoPath, currentOdoKm: $currentOdoKm, odoUpdatedAt: $odoUpdatedAt, avgDailyKm: $avgDailyKm, avgDailyKmSource: $avgDailyKmSource, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VehicleCopyWith<$Res>  {
  factory $VehicleCopyWith(Vehicle value, $Res Function(Vehicle) _then) = _$VehicleCopyWithImpl;
@useResult
$Res call({
 String id, String name, VehicleType type, String? plate, String? brand, String? model, int? year, String? photoPath, int currentOdoKm, DateTime odoUpdatedAt, double avgDailyKm, AvgKmSource avgDailyKmSource, DateTime createdAt
});




}
/// @nodoc
class _$VehicleCopyWithImpl<$Res>
    implements $VehicleCopyWith<$Res> {
  _$VehicleCopyWithImpl(this._self, this._then);

  final Vehicle _self;
  final $Res Function(Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? plate = freezed,Object? brand = freezed,Object? model = freezed,Object? year = freezed,Object? photoPath = freezed,Object? currentOdoKm = null,Object? odoUpdatedAt = null,Object? avgDailyKm = null,Object? avgDailyKmSource = null,Object? createdAt = null,}) {
  return _then(Vehicle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,currentOdoKm: null == currentOdoKm ? _self.currentOdoKm : currentOdoKm // ignore: cast_nullable_to_non_nullable
as int,odoUpdatedAt: null == odoUpdatedAt ? _self.odoUpdatedAt : odoUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,avgDailyKm: null == avgDailyKm ? _self.avgDailyKm : avgDailyKm // ignore: cast_nullable_to_non_nullable
as double,avgDailyKmSource: null == avgDailyKmSource ? _self.avgDailyKmSource : avgDailyKmSource // ignore: cast_nullable_to_non_nullable
as AvgKmSource,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Vehicle].
extension VehiclePatterns on Vehicle {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vehicle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vehicle value)  $default,){
final _that = this;
switch (_that) {
case _Vehicle():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vehicle value)?  $default,){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  VehicleType type,  String? plate,  String? brand,  String? model,  int? year,  String? photoPath,  int currentOdoKm,  DateTime odoUpdatedAt,  double avgDailyKm,  AvgKmSource avgDailyKmSource,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.plate,_that.brand,_that.model,_that.year,_that.photoPath,_that.currentOdoKm,_that.odoUpdatedAt,_that.avgDailyKm,_that.avgDailyKmSource,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  VehicleType type,  String? plate,  String? brand,  String? model,  int? year,  String? photoPath,  int currentOdoKm,  DateTime odoUpdatedAt,  double avgDailyKm,  AvgKmSource avgDailyKmSource,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Vehicle():
return $default(_that.id,_that.name,_that.type,_that.plate,_that.brand,_that.model,_that.year,_that.photoPath,_that.currentOdoKm,_that.odoUpdatedAt,_that.avgDailyKm,_that.avgDailyKmSource,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  VehicleType type,  String? plate,  String? brand,  String? model,  int? year,  String? photoPath,  int currentOdoKm,  DateTime odoUpdatedAt,  double avgDailyKm,  AvgKmSource avgDailyKmSource,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.plate,_that.brand,_that.model,_that.year,_that.photoPath,_that.currentOdoKm,_that.odoUpdatedAt,_that.avgDailyKm,_that.avgDailyKmSource,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vehicle implements Vehicle {
  const _Vehicle({required this.id, required this.name, required this.type, this.plate, this.brand, this.model, this.year, this.photoPath, required this.currentOdoKm, required this.odoUpdatedAt, required this.avgDailyKm, this.avgDailyKmSource = AvgKmSource.user, required this.createdAt});
  factory _Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

@override final  String id;
@override final  String name;
@override final  VehicleType type;
@override final  String? plate;
@override final  String? brand;
@override final  String? model;
@override final  int? year;
@override final  String? photoPath;
@override final  int currentOdoKm;
@override final  DateTime odoUpdatedAt;
@override final  double avgDailyKm;
@override@JsonKey() final  AvgKmSource avgDailyKmSource;
@override final  DateTime createdAt;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleCopyWith<_Vehicle> get copyWith => __$VehicleCopyWithImpl<_Vehicle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vehicle&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.currentOdoKm, currentOdoKm) || other.currentOdoKm == currentOdoKm)&&(identical(other.odoUpdatedAt, odoUpdatedAt) || other.odoUpdatedAt == odoUpdatedAt)&&(identical(other.avgDailyKm, avgDailyKm) || other.avgDailyKm == avgDailyKm)&&(identical(other.avgDailyKmSource, avgDailyKmSource) || other.avgDailyKmSource == avgDailyKmSource)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,plate,brand,model,year,photoPath,currentOdoKm,odoUpdatedAt,avgDailyKm,avgDailyKmSource,createdAt);

@override
String toString() {
  return 'Vehicle(id: $id, name: $name, type: $type, plate: $plate, brand: $brand, model: $model, year: $year, photoPath: $photoPath, currentOdoKm: $currentOdoKm, odoUpdatedAt: $odoUpdatedAt, avgDailyKm: $avgDailyKm, avgDailyKmSource: $avgDailyKmSource, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VehicleCopyWith<$Res> implements $VehicleCopyWith<$Res> {
  factory _$VehicleCopyWith(_Vehicle value, $Res Function(_Vehicle) _then) = __$VehicleCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, VehicleType type, String? plate, String? brand, String? model, int? year, String? photoPath, int currentOdoKm, DateTime odoUpdatedAt, double avgDailyKm, AvgKmSource avgDailyKmSource, DateTime createdAt
});




}
/// @nodoc
class __$VehicleCopyWithImpl<$Res>
    implements _$VehicleCopyWith<$Res> {
  __$VehicleCopyWithImpl(this._self, this._then);

  final _Vehicle _self;
  final $Res Function(_Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? plate = freezed,Object? brand = freezed,Object? model = freezed,Object? year = freezed,Object? photoPath = freezed,Object? currentOdoKm = null,Object? odoUpdatedAt = null,Object? avgDailyKm = null,Object? avgDailyKmSource = null,Object? createdAt = null,}) {
  return _then(_Vehicle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,currentOdoKm: null == currentOdoKm ? _self.currentOdoKm : currentOdoKm // ignore: cast_nullable_to_non_nullable
as int,odoUpdatedAt: null == odoUpdatedAt ? _self.odoUpdatedAt : odoUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,avgDailyKm: null == avgDailyKm ? _self.avgDailyKm : avgDailyKm // ignore: cast_nullable_to_non_nullable
as double,avgDailyKmSource: null == avgDailyKmSource ? _self.avgDailyKmSource : avgDailyKmSource // ignore: cast_nullable_to_non_nullable
as AvgKmSource,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
