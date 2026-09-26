// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceLogEntry {

 String get itemId; int? get costVnd; String? get partBrand; String? get partSpec; bool get resetsCycle;
/// Create a copy of ServiceLogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceLogEntryCopyWith<ServiceLogEntry> get copyWith => _$ServiceLogEntryCopyWithImpl<ServiceLogEntry>(this as ServiceLogEntry, _$identity);

  /// Serializes this ServiceLogEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceLogEntry&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.costVnd, costVnd) || other.costVnd == costVnd)&&(identical(other.partBrand, partBrand) || other.partBrand == partBrand)&&(identical(other.partSpec, partSpec) || other.partSpec == partSpec)&&(identical(other.resetsCycle, resetsCycle) || other.resetsCycle == resetsCycle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,costVnd,partBrand,partSpec,resetsCycle);

@override
String toString() {
  return 'ServiceLogEntry(itemId: $itemId, costVnd: $costVnd, partBrand: $partBrand, partSpec: $partSpec, resetsCycle: $resetsCycle)';
}


}

/// @nodoc
abstract mixin class $ServiceLogEntryCopyWith<$Res>  {
  factory $ServiceLogEntryCopyWith(ServiceLogEntry value, $Res Function(ServiceLogEntry) _then) = _$ServiceLogEntryCopyWithImpl;
@useResult
$Res call({
 String itemId, int? costVnd, String? partBrand, String? partSpec, bool resetsCycle
});




}
/// @nodoc
class _$ServiceLogEntryCopyWithImpl<$Res>
    implements $ServiceLogEntryCopyWith<$Res> {
  _$ServiceLogEntryCopyWithImpl(this._self, this._then);

  final ServiceLogEntry _self;
  final $Res Function(ServiceLogEntry) _then;

/// Create a copy of ServiceLogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? costVnd = freezed,Object? partBrand = freezed,Object? partSpec = freezed,Object? resetsCycle = null,}) {
  return _then(ServiceLogEntry(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,costVnd: freezed == costVnd ? _self.costVnd : costVnd // ignore: cast_nullable_to_non_nullable
as int?,partBrand: freezed == partBrand ? _self.partBrand : partBrand // ignore: cast_nullable_to_non_nullable
as String?,partSpec: freezed == partSpec ? _self.partSpec : partSpec // ignore: cast_nullable_to_non_nullable
as String?,resetsCycle: null == resetsCycle ? _self.resetsCycle : resetsCycle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceLogEntry].
extension ServiceLogEntryPatterns on ServiceLogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceLogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceLogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceLogEntry value)  $default,){
final _that = this;
switch (_that) {
case _ServiceLogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceLogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceLogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  int? costVnd,  String? partBrand,  String? partSpec,  bool resetsCycle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceLogEntry() when $default != null:
return $default(_that.itemId,_that.costVnd,_that.partBrand,_that.partSpec,_that.resetsCycle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  int? costVnd,  String? partBrand,  String? partSpec,  bool resetsCycle)  $default,) {final _that = this;
switch (_that) {
case _ServiceLogEntry():
return $default(_that.itemId,_that.costVnd,_that.partBrand,_that.partSpec,_that.resetsCycle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  int? costVnd,  String? partBrand,  String? partSpec,  bool resetsCycle)?  $default,) {final _that = this;
switch (_that) {
case _ServiceLogEntry() when $default != null:
return $default(_that.itemId,_that.costVnd,_that.partBrand,_that.partSpec,_that.resetsCycle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceLogEntry implements ServiceLogEntry {
  const _ServiceLogEntry({required this.itemId, this.costVnd, this.partBrand, this.partSpec, this.resetsCycle = true});
  factory _ServiceLogEntry.fromJson(Map<String, dynamic> json) => _$ServiceLogEntryFromJson(json);

@override final  String itemId;
@override final  int? costVnd;
@override final  String? partBrand;
@override final  String? partSpec;
@override@JsonKey() final  bool resetsCycle;

/// Create a copy of ServiceLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceLogEntryCopyWith<_ServiceLogEntry> get copyWith => __$ServiceLogEntryCopyWithImpl<_ServiceLogEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceLogEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceLogEntry&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.costVnd, costVnd) || other.costVnd == costVnd)&&(identical(other.partBrand, partBrand) || other.partBrand == partBrand)&&(identical(other.partSpec, partSpec) || other.partSpec == partSpec)&&(identical(other.resetsCycle, resetsCycle) || other.resetsCycle == resetsCycle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,costVnd,partBrand,partSpec,resetsCycle);

@override
String toString() {
  return 'ServiceLogEntry(itemId: $itemId, costVnd: $costVnd, partBrand: $partBrand, partSpec: $partSpec, resetsCycle: $resetsCycle)';
}


}

/// @nodoc
abstract mixin class _$ServiceLogEntryCopyWith<$Res> implements $ServiceLogEntryCopyWith<$Res> {
  factory _$ServiceLogEntryCopyWith(_ServiceLogEntry value, $Res Function(_ServiceLogEntry) _then) = __$ServiceLogEntryCopyWithImpl;
@override @useResult
$Res call({
 String itemId, int? costVnd, String? partBrand, String? partSpec, bool resetsCycle
});




}
/// @nodoc
class __$ServiceLogEntryCopyWithImpl<$Res>
    implements _$ServiceLogEntryCopyWith<$Res> {
  __$ServiceLogEntryCopyWithImpl(this._self, this._then);

  final _ServiceLogEntry _self;
  final $Res Function(_ServiceLogEntry) _then;

/// Create a copy of ServiceLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? costVnd = freezed,Object? partBrand = freezed,Object? partSpec = freezed,Object? resetsCycle = null,}) {
  return _then(_ServiceLogEntry(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,costVnd: freezed == costVnd ? _self.costVnd : costVnd // ignore: cast_nullable_to_non_nullable
as int?,partBrand: freezed == partBrand ? _self.partBrand : partBrand // ignore: cast_nullable_to_non_nullable
as String?,partSpec: freezed == partSpec ? _self.partSpec : partSpec // ignore: cast_nullable_to_non_nullable
as String?,resetsCycle: null == resetsCycle ? _self.resetsCycle : resetsCycle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ServiceLog {

 String get id; String get vehicleId; DateTime get date; int get odoKm; String? get shopName; int? get totalCostVnd; String? get note; List<String> get photoPaths; List<ServiceLogEntry> get entries;
/// Create a copy of ServiceLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceLogCopyWith<ServiceLog> get copyWith => _$ServiceLogCopyWithImpl<ServiceLog>(this as ServiceLog, _$identity);

  /// Serializes this ServiceLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceLog&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.date, date) || other.date == date)&&(identical(other.odoKm, odoKm) || other.odoKm == odoKm)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.totalCostVnd, totalCostVnd) || other.totalCostVnd == totalCostVnd)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.photoPaths, photoPaths)&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,date,odoKm,shopName,totalCostVnd,note,const DeepCollectionEquality().hash(photoPaths),const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'ServiceLog(id: $id, vehicleId: $vehicleId, date: $date, odoKm: $odoKm, shopName: $shopName, totalCostVnd: $totalCostVnd, note: $note, photoPaths: $photoPaths, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $ServiceLogCopyWith<$Res>  {
  factory $ServiceLogCopyWith(ServiceLog value, $Res Function(ServiceLog) _then) = _$ServiceLogCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, DateTime date, int odoKm, String? shopName, int? totalCostVnd, String? note, List<String> photoPaths, List<ServiceLogEntry> entries
});




}
/// @nodoc
class _$ServiceLogCopyWithImpl<$Res>
    implements $ServiceLogCopyWith<$Res> {
  _$ServiceLogCopyWithImpl(this._self, this._then);

  final ServiceLog _self;
  final $Res Function(ServiceLog) _then;

/// Create a copy of ServiceLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? date = null,Object? odoKm = null,Object? shopName = freezed,Object? totalCostVnd = freezed,Object? note = freezed,Object? photoPaths = null,Object? entries = null,}) {
  return _then(ServiceLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,odoKm: null == odoKm ? _self.odoKm : odoKm // ignore: cast_nullable_to_non_nullable
as int,shopName: freezed == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String?,totalCostVnd: freezed == totalCostVnd ? _self.totalCostVnd : totalCostVnd // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoPaths: null == photoPaths ? _self.photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<ServiceLogEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceLog].
extension ServiceLogPatterns on ServiceLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceLog value)  $default,){
final _that = this;
switch (_that) {
case _ServiceLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceLog value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  DateTime date,  int odoKm,  String? shopName,  int? totalCostVnd,  String? note,  List<String> photoPaths,  List<ServiceLogEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceLog() when $default != null:
return $default(_that.id,_that.vehicleId,_that.date,_that.odoKm,_that.shopName,_that.totalCostVnd,_that.note,_that.photoPaths,_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  DateTime date,  int odoKm,  String? shopName,  int? totalCostVnd,  String? note,  List<String> photoPaths,  List<ServiceLogEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _ServiceLog():
return $default(_that.id,_that.vehicleId,_that.date,_that.odoKm,_that.shopName,_that.totalCostVnd,_that.note,_that.photoPaths,_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  DateTime date,  int odoKm,  String? shopName,  int? totalCostVnd,  String? note,  List<String> photoPaths,  List<ServiceLogEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _ServiceLog() when $default != null:
return $default(_that.id,_that.vehicleId,_that.date,_that.odoKm,_that.shopName,_that.totalCostVnd,_that.note,_that.photoPaths,_that.entries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceLog implements ServiceLog {
  const _ServiceLog({required this.id, required this.vehicleId, required this.date, required this.odoKm, this.shopName, this.totalCostVnd, this.note,  List<String> photoPaths = const [],  List<ServiceLogEntry> entries = const []}): _photoPaths = photoPaths,_entries = entries;
  factory _ServiceLog.fromJson(Map<String, dynamic> json) => _$ServiceLogFromJson(json);

@override final  String id;
@override final  String vehicleId;
@override final  DateTime date;
@override final  int odoKm;
@override final  String? shopName;
@override final  int? totalCostVnd;
@override final  String? note;
 final  List<String> _photoPaths;
@override@JsonKey() List<String> get photoPaths {
  if (_photoPaths is EqualUnmodifiableListView) return _photoPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoPaths);
}

 final  List<ServiceLogEntry> _entries;
@override@JsonKey() List<ServiceLogEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of ServiceLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceLogCopyWith<_ServiceLog> get copyWith => __$ServiceLogCopyWithImpl<_ServiceLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceLog&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.date, date) || other.date == date)&&(identical(other.odoKm, odoKm) || other.odoKm == odoKm)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.totalCostVnd, totalCostVnd) || other.totalCostVnd == totalCostVnd)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other._photoPaths, _photoPaths)&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,date,odoKm,shopName,totalCostVnd,note,const DeepCollectionEquality().hash(_photoPaths),const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'ServiceLog(id: $id, vehicleId: $vehicleId, date: $date, odoKm: $odoKm, shopName: $shopName, totalCostVnd: $totalCostVnd, note: $note, photoPaths: $photoPaths, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$ServiceLogCopyWith<$Res> implements $ServiceLogCopyWith<$Res> {
  factory _$ServiceLogCopyWith(_ServiceLog value, $Res Function(_ServiceLog) _then) = __$ServiceLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, DateTime date, int odoKm, String? shopName, int? totalCostVnd, String? note, List<String> photoPaths, List<ServiceLogEntry> entries
});




}
/// @nodoc
class __$ServiceLogCopyWithImpl<$Res>
    implements _$ServiceLogCopyWith<$Res> {
  __$ServiceLogCopyWithImpl(this._self, this._then);

  final _ServiceLog _self;
  final $Res Function(_ServiceLog) _then;

/// Create a copy of ServiceLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? date = null,Object? odoKm = null,Object? shopName = freezed,Object? totalCostVnd = freezed,Object? note = freezed,Object? photoPaths = null,Object? entries = null,}) {
  return _then(_ServiceLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,odoKm: null == odoKm ? _self.odoKm : odoKm // ignore: cast_nullable_to_non_nullable
as int,shopName: freezed == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String?,totalCostVnd: freezed == totalCostVnd ? _self.totalCostVnd : totalCostVnd // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoPaths: null == photoPaths ? _self._photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<ServiceLogEntry>,
  ));
}


}

// dart format on
