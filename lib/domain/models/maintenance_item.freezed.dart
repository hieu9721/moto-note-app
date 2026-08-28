// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaintenanceItem {

 String get id; String get vehicleId; String get catalogCode; String get name; int? get intervalKm; int? get intervalMonths; bool get enabled; int? get lastServiceOdo; DateTime? get lastServiceDate; bool get baselineIsGuess; String? get partBrand; String? get partSpec; OilGrade? get oilGrade; int? get lastCostVnd; String? get notes;
/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceItemCopyWith<MaintenanceItem> get copyWith => _$MaintenanceItemCopyWithImpl<MaintenanceItem>(this as MaintenanceItem, _$identity);

  /// Serializes this MaintenanceItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceItem&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.catalogCode, catalogCode) || other.catalogCode == catalogCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.intervalKm, intervalKm) || other.intervalKm == intervalKm)&&(identical(other.intervalMonths, intervalMonths) || other.intervalMonths == intervalMonths)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.lastServiceOdo, lastServiceOdo) || other.lastServiceOdo == lastServiceOdo)&&(identical(other.lastServiceDate, lastServiceDate) || other.lastServiceDate == lastServiceDate)&&(identical(other.baselineIsGuess, baselineIsGuess) || other.baselineIsGuess == baselineIsGuess)&&(identical(other.partBrand, partBrand) || other.partBrand == partBrand)&&(identical(other.partSpec, partSpec) || other.partSpec == partSpec)&&(identical(other.oilGrade, oilGrade) || other.oilGrade == oilGrade)&&(identical(other.lastCostVnd, lastCostVnd) || other.lastCostVnd == lastCostVnd)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,catalogCode,name,intervalKm,intervalMonths,enabled,lastServiceOdo,lastServiceDate,baselineIsGuess,partBrand,partSpec,oilGrade,lastCostVnd,notes);

@override
String toString() {
  return 'MaintenanceItem(id: $id, vehicleId: $vehicleId, catalogCode: $catalogCode, name: $name, intervalKm: $intervalKm, intervalMonths: $intervalMonths, enabled: $enabled, lastServiceOdo: $lastServiceOdo, lastServiceDate: $lastServiceDate, baselineIsGuess: $baselineIsGuess, partBrand: $partBrand, partSpec: $partSpec, oilGrade: $oilGrade, lastCostVnd: $lastCostVnd, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $MaintenanceItemCopyWith<$Res>  {
  factory $MaintenanceItemCopyWith(MaintenanceItem value, $Res Function(MaintenanceItem) _then) = _$MaintenanceItemCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, String catalogCode, String name, int? intervalKm, int? intervalMonths, bool enabled, int? lastServiceOdo, DateTime? lastServiceDate, bool baselineIsGuess, String? partBrand, String? partSpec, OilGrade? oilGrade, int? lastCostVnd, String? notes
});




}
/// @nodoc
class _$MaintenanceItemCopyWithImpl<$Res>
    implements $MaintenanceItemCopyWith<$Res> {
  _$MaintenanceItemCopyWithImpl(this._self, this._then);

  final MaintenanceItem _self;
  final $Res Function(MaintenanceItem) _then;

/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? catalogCode = null,Object? name = null,Object? intervalKm = freezed,Object? intervalMonths = freezed,Object? enabled = null,Object? lastServiceOdo = freezed,Object? lastServiceDate = freezed,Object? baselineIsGuess = null,Object? partBrand = freezed,Object? partSpec = freezed,Object? oilGrade = freezed,Object? lastCostVnd = freezed,Object? notes = freezed,}) {
  return _then(MaintenanceItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,catalogCode: null == catalogCode ? _self.catalogCode : catalogCode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,intervalKm: freezed == intervalKm ? _self.intervalKm : intervalKm // ignore: cast_nullable_to_non_nullable
as int?,intervalMonths: freezed == intervalMonths ? _self.intervalMonths : intervalMonths // ignore: cast_nullable_to_non_nullable
as int?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lastServiceOdo: freezed == lastServiceOdo ? _self.lastServiceOdo : lastServiceOdo // ignore: cast_nullable_to_non_nullable
as int?,lastServiceDate: freezed == lastServiceDate ? _self.lastServiceDate : lastServiceDate // ignore: cast_nullable_to_non_nullable
as DateTime?,baselineIsGuess: null == baselineIsGuess ? _self.baselineIsGuess : baselineIsGuess // ignore: cast_nullable_to_non_nullable
as bool,partBrand: freezed == partBrand ? _self.partBrand : partBrand // ignore: cast_nullable_to_non_nullable
as String?,partSpec: freezed == partSpec ? _self.partSpec : partSpec // ignore: cast_nullable_to_non_nullable
as String?,oilGrade: freezed == oilGrade ? _self.oilGrade : oilGrade // ignore: cast_nullable_to_non_nullable
as OilGrade?,lastCostVnd: freezed == lastCostVnd ? _self.lastCostVnd : lastCostVnd // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceItem].
extension MaintenanceItemPatterns on MaintenanceItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceItem value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceItem value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String catalogCode,  String name,  int? intervalKm,  int? intervalMonths,  bool enabled,  int? lastServiceOdo,  DateTime? lastServiceDate,  bool baselineIsGuess,  String? partBrand,  String? partSpec,  OilGrade? oilGrade,  int? lastCostVnd,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
return $default(_that.id,_that.vehicleId,_that.catalogCode,_that.name,_that.intervalKm,_that.intervalMonths,_that.enabled,_that.lastServiceOdo,_that.lastServiceDate,_that.baselineIsGuess,_that.partBrand,_that.partSpec,_that.oilGrade,_that.lastCostVnd,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String catalogCode,  String name,  int? intervalKm,  int? intervalMonths,  bool enabled,  int? lastServiceOdo,  DateTime? lastServiceDate,  bool baselineIsGuess,  String? partBrand,  String? partSpec,  OilGrade? oilGrade,  int? lastCostVnd,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceItem():
return $default(_that.id,_that.vehicleId,_that.catalogCode,_that.name,_that.intervalKm,_that.intervalMonths,_that.enabled,_that.lastServiceOdo,_that.lastServiceDate,_that.baselineIsGuess,_that.partBrand,_that.partSpec,_that.oilGrade,_that.lastCostVnd,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  String catalogCode,  String name,  int? intervalKm,  int? intervalMonths,  bool enabled,  int? lastServiceOdo,  DateTime? lastServiceDate,  bool baselineIsGuess,  String? partBrand,  String? partSpec,  OilGrade? oilGrade,  int? lastCostVnd,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
return $default(_that.id,_that.vehicleId,_that.catalogCode,_that.name,_that.intervalKm,_that.intervalMonths,_that.enabled,_that.lastServiceOdo,_that.lastServiceDate,_that.baselineIsGuess,_that.partBrand,_that.partSpec,_that.oilGrade,_that.lastCostVnd,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceItem implements MaintenanceItem {
  const _MaintenanceItem({required this.id, required this.vehicleId, required this.catalogCode, required this.name, this.intervalKm, this.intervalMonths, this.enabled = true, this.lastServiceOdo, this.lastServiceDate, this.baselineIsGuess = true, this.partBrand, this.partSpec, this.oilGrade, this.lastCostVnd, this.notes});
  factory _MaintenanceItem.fromJson(Map<String, dynamic> json) => _$MaintenanceItemFromJson(json);

@override final  String id;
@override final  String vehicleId;
@override final  String catalogCode;
@override final  String name;
@override final  int? intervalKm;
@override final  int? intervalMonths;
@override@JsonKey() final  bool enabled;
@override final  int? lastServiceOdo;
@override final  DateTime? lastServiceDate;
@override@JsonKey() final  bool baselineIsGuess;
@override final  String? partBrand;
@override final  String? partSpec;
@override final  OilGrade? oilGrade;
@override final  int? lastCostVnd;
@override final  String? notes;

/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceItemCopyWith<_MaintenanceItem> get copyWith => __$MaintenanceItemCopyWithImpl<_MaintenanceItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaintenanceItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceItem&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.catalogCode, catalogCode) || other.catalogCode == catalogCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.intervalKm, intervalKm) || other.intervalKm == intervalKm)&&(identical(other.intervalMonths, intervalMonths) || other.intervalMonths == intervalMonths)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.lastServiceOdo, lastServiceOdo) || other.lastServiceOdo == lastServiceOdo)&&(identical(other.lastServiceDate, lastServiceDate) || other.lastServiceDate == lastServiceDate)&&(identical(other.baselineIsGuess, baselineIsGuess) || other.baselineIsGuess == baselineIsGuess)&&(identical(other.partBrand, partBrand) || other.partBrand == partBrand)&&(identical(other.partSpec, partSpec) || other.partSpec == partSpec)&&(identical(other.oilGrade, oilGrade) || other.oilGrade == oilGrade)&&(identical(other.lastCostVnd, lastCostVnd) || other.lastCostVnd == lastCostVnd)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,catalogCode,name,intervalKm,intervalMonths,enabled,lastServiceOdo,lastServiceDate,baselineIsGuess,partBrand,partSpec,oilGrade,lastCostVnd,notes);

@override
String toString() {
  return 'MaintenanceItem(id: $id, vehicleId: $vehicleId, catalogCode: $catalogCode, name: $name, intervalKm: $intervalKm, intervalMonths: $intervalMonths, enabled: $enabled, lastServiceOdo: $lastServiceOdo, lastServiceDate: $lastServiceDate, baselineIsGuess: $baselineIsGuess, partBrand: $partBrand, partSpec: $partSpec, oilGrade: $oilGrade, lastCostVnd: $lastCostVnd, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceItemCopyWith<$Res> implements $MaintenanceItemCopyWith<$Res> {
  factory _$MaintenanceItemCopyWith(_MaintenanceItem value, $Res Function(_MaintenanceItem) _then) = __$MaintenanceItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, String catalogCode, String name, int? intervalKm, int? intervalMonths, bool enabled, int? lastServiceOdo, DateTime? lastServiceDate, bool baselineIsGuess, String? partBrand, String? partSpec, OilGrade? oilGrade, int? lastCostVnd, String? notes
});




}
/// @nodoc
class __$MaintenanceItemCopyWithImpl<$Res>
    implements _$MaintenanceItemCopyWith<$Res> {
  __$MaintenanceItemCopyWithImpl(this._self, this._then);

  final _MaintenanceItem _self;
  final $Res Function(_MaintenanceItem) _then;

/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? catalogCode = null,Object? name = null,Object? intervalKm = freezed,Object? intervalMonths = freezed,Object? enabled = null,Object? lastServiceOdo = freezed,Object? lastServiceDate = freezed,Object? baselineIsGuess = null,Object? partBrand = freezed,Object? partSpec = freezed,Object? oilGrade = freezed,Object? lastCostVnd = freezed,Object? notes = freezed,}) {
  return _then(_MaintenanceItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,catalogCode: null == catalogCode ? _self.catalogCode : catalogCode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,intervalKm: freezed == intervalKm ? _self.intervalKm : intervalKm // ignore: cast_nullable_to_non_nullable
as int?,intervalMonths: freezed == intervalMonths ? _self.intervalMonths : intervalMonths // ignore: cast_nullable_to_non_nullable
as int?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lastServiceOdo: freezed == lastServiceOdo ? _self.lastServiceOdo : lastServiceOdo // ignore: cast_nullable_to_non_nullable
as int?,lastServiceDate: freezed == lastServiceDate ? _self.lastServiceDate : lastServiceDate // ignore: cast_nullable_to_non_nullable
as DateTime?,baselineIsGuess: null == baselineIsGuess ? _self.baselineIsGuess : baselineIsGuess // ignore: cast_nullable_to_non_nullable
as bool,partBrand: freezed == partBrand ? _self.partBrand : partBrand // ignore: cast_nullable_to_non_nullable
as String?,partSpec: freezed == partSpec ? _self.partSpec : partSpec // ignore: cast_nullable_to_non_nullable
as String?,oilGrade: freezed == oilGrade ? _self.oilGrade : oilGrade // ignore: cast_nullable_to_non_nullable
as OilGrade?,lastCostVnd: freezed == lastCostVnd ? _self.lastCostVnd : lastCostVnd // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
