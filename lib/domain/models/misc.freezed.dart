// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'misc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OdoReading {

 String get id; String get vehicleId; int get odoKm; DateTime get date; OdoSource get source;
/// Create a copy of OdoReading
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OdoReadingCopyWith<OdoReading> get copyWith => _$OdoReadingCopyWithImpl<OdoReading>(this as OdoReading, _$identity);

  /// Serializes this OdoReading to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OdoReading&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.odoKm, odoKm) || other.odoKm == odoKm)&&(identical(other.date, date) || other.date == date)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,odoKm,date,source);

@override
String toString() {
  return 'OdoReading(id: $id, vehicleId: $vehicleId, odoKm: $odoKm, date: $date, source: $source)';
}


}

/// @nodoc
abstract mixin class $OdoReadingCopyWith<$Res>  {
  factory $OdoReadingCopyWith(OdoReading value, $Res Function(OdoReading) _then) = _$OdoReadingCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, int odoKm, DateTime date, OdoSource source
});




}
/// @nodoc
class _$OdoReadingCopyWithImpl<$Res>
    implements $OdoReadingCopyWith<$Res> {
  _$OdoReadingCopyWithImpl(this._self, this._then);

  final OdoReading _self;
  final $Res Function(OdoReading) _then;

/// Create a copy of OdoReading
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? odoKm = null,Object? date = null,Object? source = null,}) {
  return _then(OdoReading(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,odoKm: null == odoKm ? _self.odoKm : odoKm // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as OdoSource,
  ));
}

}


/// Adds pattern-matching-related methods to [OdoReading].
extension OdoReadingPatterns on OdoReading {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OdoReading value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OdoReading() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OdoReading value)  $default,){
final _that = this;
switch (_that) {
case _OdoReading():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OdoReading value)?  $default,){
final _that = this;
switch (_that) {
case _OdoReading() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  int odoKm,  DateTime date,  OdoSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OdoReading() when $default != null:
return $default(_that.id,_that.vehicleId,_that.odoKm,_that.date,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  int odoKm,  DateTime date,  OdoSource source)  $default,) {final _that = this;
switch (_that) {
case _OdoReading():
return $default(_that.id,_that.vehicleId,_that.odoKm,_that.date,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  int odoKm,  DateTime date,  OdoSource source)?  $default,) {final _that = this;
switch (_that) {
case _OdoReading() when $default != null:
return $default(_that.id,_that.vehicleId,_that.odoKm,_that.date,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OdoReading implements OdoReading {
  const _OdoReading({required this.id, required this.vehicleId, required this.odoKm, required this.date, this.source = OdoSource.manual});
  factory _OdoReading.fromJson(Map<String, dynamic> json) => _$OdoReadingFromJson(json);

@override final  String id;
@override final  String vehicleId;
@override final  int odoKm;
@override final  DateTime date;
@override@JsonKey() final  OdoSource source;

/// Create a copy of OdoReading
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OdoReadingCopyWith<_OdoReading> get copyWith => __$OdoReadingCopyWithImpl<_OdoReading>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OdoReadingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OdoReading&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.odoKm, odoKm) || other.odoKm == odoKm)&&(identical(other.date, date) || other.date == date)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,odoKm,date,source);

@override
String toString() {
  return 'OdoReading(id: $id, vehicleId: $vehicleId, odoKm: $odoKm, date: $date, source: $source)';
}


}

/// @nodoc
abstract mixin class _$OdoReadingCopyWith<$Res> implements $OdoReadingCopyWith<$Res> {
  factory _$OdoReadingCopyWith(_OdoReading value, $Res Function(_OdoReading) _then) = __$OdoReadingCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, int odoKm, DateTime date, OdoSource source
});




}
/// @nodoc
class __$OdoReadingCopyWithImpl<$Res>
    implements _$OdoReadingCopyWith<$Res> {
  __$OdoReadingCopyWithImpl(this._self, this._then);

  final _OdoReading _self;
  final $Res Function(_OdoReading) _then;

/// Create a copy of OdoReading
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? odoKm = null,Object? date = null,Object? source = null,}) {
  return _then(_OdoReading(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,odoKm: null == odoKm ? _self.odoKm : odoKm // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as OdoSource,
  ));
}


}


/// @nodoc
mixin _$Note {

 String get id; String? get vehicleId; String? get itemId; String? get title; String get body; bool get pinned; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteCopyWith<Note> get copyWith => _$NoteCopyWithImpl<Note>(this as Note, _$identity);

  /// Serializes this Note to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Note&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,itemId,title,body,pinned,createdAt,updatedAt);

@override
String toString() {
  return 'Note(id: $id, vehicleId: $vehicleId, itemId: $itemId, title: $title, body: $body, pinned: $pinned, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $NoteCopyWith<$Res>  {
  factory $NoteCopyWith(Note value, $Res Function(Note) _then) = _$NoteCopyWithImpl;
@useResult
$Res call({
 String id, String? vehicleId, String? itemId, String? title, String body, bool pinned, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$NoteCopyWithImpl<$Res>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._self, this._then);

  final Note _self;
  final $Res Function(Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = freezed,Object? itemId = freezed,Object? title = freezed,Object? body = null,Object? pinned = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Note(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: freezed == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Note].
extension NotePatterns on Note {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Note value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Note() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Note value)  $default,){
final _that = this;
switch (_that) {
case _Note():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Note value)?  $default,){
final _that = this;
switch (_that) {
case _Note() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? vehicleId,  String? itemId,  String? title,  String body,  bool pinned,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.vehicleId,_that.itemId,_that.title,_that.body,_that.pinned,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? vehicleId,  String? itemId,  String? title,  String body,  bool pinned,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Note():
return $default(_that.id,_that.vehicleId,_that.itemId,_that.title,_that.body,_that.pinned,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? vehicleId,  String? itemId,  String? title,  String body,  bool pinned,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.vehicleId,_that.itemId,_that.title,_that.body,_that.pinned,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Note implements Note {
  const _Note({required this.id, this.vehicleId, this.itemId, this.title, this.body = '', this.pinned = false, required this.createdAt, required this.updatedAt});
  factory _Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

@override final  String id;
@override final  String? vehicleId;
@override final  String? itemId;
@override final  String? title;
@override@JsonKey() final  String body;
@override@JsonKey() final  bool pinned;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteCopyWith<_Note> get copyWith => __$NoteCopyWithImpl<_Note>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Note&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,itemId,title,body,pinned,createdAt,updatedAt);

@override
String toString() {
  return 'Note(id: $id, vehicleId: $vehicleId, itemId: $itemId, title: $title, body: $body, pinned: $pinned, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NoteCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$NoteCopyWith(_Note value, $Res Function(_Note) _then) = __$NoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String? vehicleId, String? itemId, String? title, String body, bool pinned, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$NoteCopyWithImpl<$Res>
    implements _$NoteCopyWith<$Res> {
  __$NoteCopyWithImpl(this._self, this._then);

  final _Note _self;
  final $Res Function(_Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = freezed,Object? itemId = freezed,Object? title = freezed,Object? body = null,Object? pinned = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Note(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: freezed == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$Settings {

 bool get notificationsEnabled; bool get odoReminderEnabled; int get odoReminderDayOfMonth; int get notifyHour; int get leadDays; bool get driveBackupEnabled; DateTime? get lastBackupAt; String? get lastBackupError; String? get googleEmail; DateTime? get lastNotificationFiredAt; bool get notificationPermissionAsked; bool get exactAlarmsEnabled;
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsCopyWith<Settings> get copyWith => _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settings&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.odoReminderEnabled, odoReminderEnabled) || other.odoReminderEnabled == odoReminderEnabled)&&(identical(other.odoReminderDayOfMonth, odoReminderDayOfMonth) || other.odoReminderDayOfMonth == odoReminderDayOfMonth)&&(identical(other.notifyHour, notifyHour) || other.notifyHour == notifyHour)&&(identical(other.leadDays, leadDays) || other.leadDays == leadDays)&&(identical(other.driveBackupEnabled, driveBackupEnabled) || other.driveBackupEnabled == driveBackupEnabled)&&(identical(other.lastBackupAt, lastBackupAt) || other.lastBackupAt == lastBackupAt)&&(identical(other.lastBackupError, lastBackupError) || other.lastBackupError == lastBackupError)&&(identical(other.googleEmail, googleEmail) || other.googleEmail == googleEmail)&&(identical(other.lastNotificationFiredAt, lastNotificationFiredAt) || other.lastNotificationFiredAt == lastNotificationFiredAt)&&(identical(other.notificationPermissionAsked, notificationPermissionAsked) || other.notificationPermissionAsked == notificationPermissionAsked)&&(identical(other.exactAlarmsEnabled, exactAlarmsEnabled) || other.exactAlarmsEnabled == exactAlarmsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationsEnabled,odoReminderEnabled,odoReminderDayOfMonth,notifyHour,leadDays,driveBackupEnabled,lastBackupAt,lastBackupError,googleEmail,lastNotificationFiredAt,notificationPermissionAsked,exactAlarmsEnabled);

@override
String toString() {
  return 'Settings(notificationsEnabled: $notificationsEnabled, odoReminderEnabled: $odoReminderEnabled, odoReminderDayOfMonth: $odoReminderDayOfMonth, notifyHour: $notifyHour, leadDays: $leadDays, driveBackupEnabled: $driveBackupEnabled, lastBackupAt: $lastBackupAt, lastBackupError: $lastBackupError, googleEmail: $googleEmail, lastNotificationFiredAt: $lastNotificationFiredAt, notificationPermissionAsked: $notificationPermissionAsked, exactAlarmsEnabled: $exactAlarmsEnabled)';
}


}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res>  {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) = _$SettingsCopyWithImpl;
@useResult
$Res call({
 bool notificationsEnabled, bool odoReminderEnabled, int odoReminderDayOfMonth, int notifyHour, int leadDays, bool driveBackupEnabled, DateTime? lastBackupAt, String? lastBackupError, String? googleEmail, DateTime? lastNotificationFiredAt, bool notificationPermissionAsked, bool exactAlarmsEnabled
});




}
/// @nodoc
class _$SettingsCopyWithImpl<$Res>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notificationsEnabled = null,Object? odoReminderEnabled = null,Object? odoReminderDayOfMonth = null,Object? notifyHour = null,Object? leadDays = null,Object? driveBackupEnabled = null,Object? lastBackupAt = freezed,Object? lastBackupError = freezed,Object? googleEmail = freezed,Object? lastNotificationFiredAt = freezed,Object? notificationPermissionAsked = null,Object? exactAlarmsEnabled = null,}) {
  return _then(Settings(
notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,odoReminderEnabled: null == odoReminderEnabled ? _self.odoReminderEnabled : odoReminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,odoReminderDayOfMonth: null == odoReminderDayOfMonth ? _self.odoReminderDayOfMonth : odoReminderDayOfMonth // ignore: cast_nullable_to_non_nullable
as int,notifyHour: null == notifyHour ? _self.notifyHour : notifyHour // ignore: cast_nullable_to_non_nullable
as int,leadDays: null == leadDays ? _self.leadDays : leadDays // ignore: cast_nullable_to_non_nullable
as int,driveBackupEnabled: null == driveBackupEnabled ? _self.driveBackupEnabled : driveBackupEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastBackupAt: freezed == lastBackupAt ? _self.lastBackupAt : lastBackupAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastBackupError: freezed == lastBackupError ? _self.lastBackupError : lastBackupError // ignore: cast_nullable_to_non_nullable
as String?,googleEmail: freezed == googleEmail ? _self.googleEmail : googleEmail // ignore: cast_nullable_to_non_nullable
as String?,lastNotificationFiredAt: freezed == lastNotificationFiredAt ? _self.lastNotificationFiredAt : lastNotificationFiredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notificationPermissionAsked: null == notificationPermissionAsked ? _self.notificationPermissionAsked : notificationPermissionAsked // ignore: cast_nullable_to_non_nullable
as bool,exactAlarmsEnabled: null == exactAlarmsEnabled ? _self.exactAlarmsEnabled : exactAlarmsEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Settings].
extension SettingsPatterns on Settings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Settings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Settings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Settings value)  $default,){
final _that = this;
switch (_that) {
case _Settings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Settings value)?  $default,){
final _that = this;
switch (_that) {
case _Settings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool notificationsEnabled,  bool odoReminderEnabled,  int odoReminderDayOfMonth,  int notifyHour,  int leadDays,  bool driveBackupEnabled,  DateTime? lastBackupAt,  String? lastBackupError,  String? googleEmail,  DateTime? lastNotificationFiredAt,  bool notificationPermissionAsked,  bool exactAlarmsEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.notificationsEnabled,_that.odoReminderEnabled,_that.odoReminderDayOfMonth,_that.notifyHour,_that.leadDays,_that.driveBackupEnabled,_that.lastBackupAt,_that.lastBackupError,_that.googleEmail,_that.lastNotificationFiredAt,_that.notificationPermissionAsked,_that.exactAlarmsEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool notificationsEnabled,  bool odoReminderEnabled,  int odoReminderDayOfMonth,  int notifyHour,  int leadDays,  bool driveBackupEnabled,  DateTime? lastBackupAt,  String? lastBackupError,  String? googleEmail,  DateTime? lastNotificationFiredAt,  bool notificationPermissionAsked,  bool exactAlarmsEnabled)  $default,) {final _that = this;
switch (_that) {
case _Settings():
return $default(_that.notificationsEnabled,_that.odoReminderEnabled,_that.odoReminderDayOfMonth,_that.notifyHour,_that.leadDays,_that.driveBackupEnabled,_that.lastBackupAt,_that.lastBackupError,_that.googleEmail,_that.lastNotificationFiredAt,_that.notificationPermissionAsked,_that.exactAlarmsEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool notificationsEnabled,  bool odoReminderEnabled,  int odoReminderDayOfMonth,  int notifyHour,  int leadDays,  bool driveBackupEnabled,  DateTime? lastBackupAt,  String? lastBackupError,  String? googleEmail,  DateTime? lastNotificationFiredAt,  bool notificationPermissionAsked,  bool exactAlarmsEnabled)?  $default,) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.notificationsEnabled,_that.odoReminderEnabled,_that.odoReminderDayOfMonth,_that.notifyHour,_that.leadDays,_that.driveBackupEnabled,_that.lastBackupAt,_that.lastBackupError,_that.googleEmail,_that.lastNotificationFiredAt,_that.notificationPermissionAsked,_that.exactAlarmsEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Settings implements Settings {
  const _Settings({this.notificationsEnabled = true, this.odoReminderEnabled = true, this.odoReminderDayOfMonth = 1, this.notifyHour = 8, this.leadDays = 7, this.driveBackupEnabled = false, this.lastBackupAt, this.lastBackupError, this.googleEmail, this.lastNotificationFiredAt, this.notificationPermissionAsked = false, this.exactAlarmsEnabled = false});
  factory _Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

@override@JsonKey() final  bool notificationsEnabled;
@override@JsonKey() final  bool odoReminderEnabled;
@override@JsonKey() final  int odoReminderDayOfMonth;
@override@JsonKey() final  int notifyHour;
@override@JsonKey() final  int leadDays;
@override@JsonKey() final  bool driveBackupEnabled;
@override final  DateTime? lastBackupAt;
@override final  String? lastBackupError;
@override final  String? googleEmail;
@override final  DateTime? lastNotificationFiredAt;
@override@JsonKey() final  bool notificationPermissionAsked;
@override@JsonKey() final  bool exactAlarmsEnabled;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsCopyWith<_Settings> get copyWith => __$SettingsCopyWithImpl<_Settings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settings&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.odoReminderEnabled, odoReminderEnabled) || other.odoReminderEnabled == odoReminderEnabled)&&(identical(other.odoReminderDayOfMonth, odoReminderDayOfMonth) || other.odoReminderDayOfMonth == odoReminderDayOfMonth)&&(identical(other.notifyHour, notifyHour) || other.notifyHour == notifyHour)&&(identical(other.leadDays, leadDays) || other.leadDays == leadDays)&&(identical(other.driveBackupEnabled, driveBackupEnabled) || other.driveBackupEnabled == driveBackupEnabled)&&(identical(other.lastBackupAt, lastBackupAt) || other.lastBackupAt == lastBackupAt)&&(identical(other.lastBackupError, lastBackupError) || other.lastBackupError == lastBackupError)&&(identical(other.googleEmail, googleEmail) || other.googleEmail == googleEmail)&&(identical(other.lastNotificationFiredAt, lastNotificationFiredAt) || other.lastNotificationFiredAt == lastNotificationFiredAt)&&(identical(other.notificationPermissionAsked, notificationPermissionAsked) || other.notificationPermissionAsked == notificationPermissionAsked)&&(identical(other.exactAlarmsEnabled, exactAlarmsEnabled) || other.exactAlarmsEnabled == exactAlarmsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationsEnabled,odoReminderEnabled,odoReminderDayOfMonth,notifyHour,leadDays,driveBackupEnabled,lastBackupAt,lastBackupError,googleEmail,lastNotificationFiredAt,notificationPermissionAsked,exactAlarmsEnabled);

@override
String toString() {
  return 'Settings(notificationsEnabled: $notificationsEnabled, odoReminderEnabled: $odoReminderEnabled, odoReminderDayOfMonth: $odoReminderDayOfMonth, notifyHour: $notifyHour, leadDays: $leadDays, driveBackupEnabled: $driveBackupEnabled, lastBackupAt: $lastBackupAt, lastBackupError: $lastBackupError, googleEmail: $googleEmail, lastNotificationFiredAt: $lastNotificationFiredAt, notificationPermissionAsked: $notificationPermissionAsked, exactAlarmsEnabled: $exactAlarmsEnabled)';
}


}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res> implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) = __$SettingsCopyWithImpl;
@override @useResult
$Res call({
 bool notificationsEnabled, bool odoReminderEnabled, int odoReminderDayOfMonth, int notifyHour, int leadDays, bool driveBackupEnabled, DateTime? lastBackupAt, String? lastBackupError, String? googleEmail, DateTime? lastNotificationFiredAt, bool notificationPermissionAsked, bool exactAlarmsEnabled
});




}
/// @nodoc
class __$SettingsCopyWithImpl<$Res>
    implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notificationsEnabled = null,Object? odoReminderEnabled = null,Object? odoReminderDayOfMonth = null,Object? notifyHour = null,Object? leadDays = null,Object? driveBackupEnabled = null,Object? lastBackupAt = freezed,Object? lastBackupError = freezed,Object? googleEmail = freezed,Object? lastNotificationFiredAt = freezed,Object? notificationPermissionAsked = null,Object? exactAlarmsEnabled = null,}) {
  return _then(_Settings(
notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,odoReminderEnabled: null == odoReminderEnabled ? _self.odoReminderEnabled : odoReminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,odoReminderDayOfMonth: null == odoReminderDayOfMonth ? _self.odoReminderDayOfMonth : odoReminderDayOfMonth // ignore: cast_nullable_to_non_nullable
as int,notifyHour: null == notifyHour ? _self.notifyHour : notifyHour // ignore: cast_nullable_to_non_nullable
as int,leadDays: null == leadDays ? _self.leadDays : leadDays // ignore: cast_nullable_to_non_nullable
as int,driveBackupEnabled: null == driveBackupEnabled ? _self.driveBackupEnabled : driveBackupEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastBackupAt: freezed == lastBackupAt ? _self.lastBackupAt : lastBackupAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastBackupError: freezed == lastBackupError ? _self.lastBackupError : lastBackupError // ignore: cast_nullable_to_non_nullable
as String?,googleEmail: freezed == googleEmail ? _self.googleEmail : googleEmail // ignore: cast_nullable_to_non_nullable
as String?,lastNotificationFiredAt: freezed == lastNotificationFiredAt ? _self.lastNotificationFiredAt : lastNotificationFiredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notificationPermissionAsked: null == notificationPermissionAsked ? _self.notificationPermissionAsked : notificationPermissionAsked // ignore: cast_nullable_to_non_nullable
as bool,exactAlarmsEnabled: null == exactAlarmsEnabled ? _self.exactAlarmsEnabled : exactAlarmsEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
