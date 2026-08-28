// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppData {

 int get schemaVersion; DateTime get updatedAt; String get deviceLabel; List<OdoReading> get odoReadings; List<Note> get notes; Settings get settings;
/// Create a copy of AppData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDataCopyWith<AppData> get copyWith => _$AppDataCopyWithImpl<AppData>(this as AppData, _$identity);

  /// Serializes this AppData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppData&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deviceLabel, deviceLabel) || other.deviceLabel == deviceLabel)&&const DeepCollectionEquality().equals(other.odoReadings, odoReadings)&&const DeepCollectionEquality().equals(other.notes, notes)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,updatedAt,deviceLabel,const DeepCollectionEquality().hash(odoReadings),const DeepCollectionEquality().hash(notes),settings);

@override
String toString() {
  return 'AppData(schemaVersion: $schemaVersion, updatedAt: $updatedAt, deviceLabel: $deviceLabel, odoReadings: $odoReadings, notes: $notes, settings: $settings)';
}


}

/// @nodoc
abstract mixin class $AppDataCopyWith<$Res>  {
  factory $AppDataCopyWith(AppData value, $Res Function(AppData) _then) = _$AppDataCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, DateTime updatedAt, String deviceLabel, List<OdoReading> odoReadings, List<Note> notes, Settings settings
});


$SettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$AppDataCopyWithImpl<$Res>
    implements $AppDataCopyWith<$Res> {
  _$AppDataCopyWithImpl(this._self, this._then);

  final AppData _self;
  final $Res Function(AppData) _then;

/// Create a copy of AppData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? updatedAt = null,Object? deviceLabel = null,Object? odoReadings = null,Object? notes = null,Object? settings = null,}) {
  return _then(AppData(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceLabel: null == deviceLabel ? _self.deviceLabel : deviceLabel // ignore: cast_nullable_to_non_nullable
as String,odoReadings: null == odoReadings ? _self.odoReadings : odoReadings // ignore: cast_nullable_to_non_nullable
as List<OdoReading>,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<Note>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Settings,
  ));
}
/// Create a copy of AppData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsCopyWith<$Res> get settings {
  
  return $SettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppData].
extension AppDataPatterns on AppData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppData value)  $default,){
final _that = this;
switch (_that) {
case _AppData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppData value)?  $default,){
final _that = this;
switch (_that) {
case _AppData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  DateTime updatedAt,  String deviceLabel,  List<OdoReading> odoReadings,  List<Note> notes,  Settings settings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppData() when $default != null:
return $default(_that.schemaVersion,_that.updatedAt,_that.deviceLabel,_that.odoReadings,_that.notes,_that.settings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  DateTime updatedAt,  String deviceLabel,  List<OdoReading> odoReadings,  List<Note> notes,  Settings settings)  $default,) {final _that = this;
switch (_that) {
case _AppData():
return $default(_that.schemaVersion,_that.updatedAt,_that.deviceLabel,_that.odoReadings,_that.notes,_that.settings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  DateTime updatedAt,  String deviceLabel,  List<OdoReading> odoReadings,  List<Note> notes,  Settings settings)?  $default,) {final _that = this;
switch (_that) {
case _AppData() when $default != null:
return $default(_that.schemaVersion,_that.updatedAt,_that.deviceLabel,_that.odoReadings,_that.notes,_that.settings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppData implements AppData {
  const _AppData({this.schemaVersion = kSchemaVersion, required this.updatedAt, this.deviceLabel = '',  List<OdoReading> odoReadings = const [],  List<Note> notes = const [], required this.settings}): _odoReadings = odoReadings,_notes = notes;
  factory _AppData.fromJson(Map<String, dynamic> json) => _$AppDataFromJson(json);

@override@JsonKey() final  int schemaVersion;
@override final  DateTime updatedAt;
@override@JsonKey() final  String deviceLabel;
 final  List<OdoReading> _odoReadings;
@override@JsonKey() List<OdoReading> get odoReadings {
  if (_odoReadings is EqualUnmodifiableListView) return _odoReadings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_odoReadings);
}

 final  List<Note> _notes;
@override@JsonKey() List<Note> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

@override final  Settings settings;

/// Create a copy of AppData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDataCopyWith<_AppData> get copyWith => __$AppDataCopyWithImpl<_AppData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppData&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deviceLabel, deviceLabel) || other.deviceLabel == deviceLabel)&&const DeepCollectionEquality().equals(other._odoReadings, _odoReadings)&&const DeepCollectionEquality().equals(other._notes, _notes)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,updatedAt,deviceLabel,const DeepCollectionEquality().hash(_odoReadings),const DeepCollectionEquality().hash(_notes),settings);

@override
String toString() {
  return 'AppData(schemaVersion: $schemaVersion, updatedAt: $updatedAt, deviceLabel: $deviceLabel, odoReadings: $odoReadings, notes: $notes, settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$AppDataCopyWith<$Res> implements $AppDataCopyWith<$Res> {
  factory _$AppDataCopyWith(_AppData value, $Res Function(_AppData) _then) = __$AppDataCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, DateTime updatedAt, String deviceLabel, List<OdoReading> odoReadings, List<Note> notes, Settings settings
});


@override $SettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$AppDataCopyWithImpl<$Res>
    implements _$AppDataCopyWith<$Res> {
  __$AppDataCopyWithImpl(this._self, this._then);

  final _AppData _self;
  final $Res Function(_AppData) _then;

/// Create a copy of AppData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? updatedAt = null,Object? deviceLabel = null,Object? odoReadings = null,Object? notes = null,Object? settings = null,}) {
  return _then(_AppData(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceLabel: null == deviceLabel ? _self.deviceLabel : deviceLabel // ignore: cast_nullable_to_non_nullable
as String,odoReadings: null == odoReadings ? _self._odoReadings : odoReadings // ignore: cast_nullable_to_non_nullable
as List<OdoReading>,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<Note>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Settings,
  ));
}

/// Create a copy of AppData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsCopyWith<$Res> get settings {
  
  return $SettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on
