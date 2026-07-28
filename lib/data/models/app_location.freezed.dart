// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppLocation {

 double get lat; double get lng; String? get cep; String? get city; String? get state;/// Search radius in km, from the picker's `[1, 5, 10, 15, 25, 50]`.
/// The backend defaults to 25 but the client always sends this explicitly —
/// 10 is our default for a new location, while 50 remains the widest
/// Menor Preço accepts.
 int get raio;/// True when [lat]/[lng] came from GPS rather than a CEP centroid.
/// A precise fix is what lets "which market am I in?" narrow its radius
/// instead of dragging in a whole city.
 bool get precise;
/// Create a copy of AppLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppLocationCopyWith<AppLocation> get copyWith => _$AppLocationCopyWithImpl<AppLocation>(this as AppLocation, _$identity);

  /// Serializes this AppLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLocation&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.cep, cep) || other.cep == cep)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.raio, raio) || other.raio == raio)&&(identical(other.precise, precise) || other.precise == precise));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,cep,city,state,raio,precise);

@override
String toString() {
  return 'AppLocation(lat: $lat, lng: $lng, cep: $cep, city: $city, state: $state, raio: $raio, precise: $precise)';
}


}

/// @nodoc
abstract mixin class $AppLocationCopyWith<$Res>  {
  factory $AppLocationCopyWith(AppLocation value, $Res Function(AppLocation) _then) = _$AppLocationCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, String? cep, String? city, String? state, int raio, bool precise
});




}
/// @nodoc
class _$AppLocationCopyWithImpl<$Res>
    implements $AppLocationCopyWith<$Res> {
  _$AppLocationCopyWithImpl(this._self, this._then);

  final AppLocation _self;
  final $Res Function(AppLocation) _then;

/// Create a copy of AppLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? cep = freezed,Object? city = freezed,Object? state = freezed,Object? raio = null,Object? precise = null,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,cep: freezed == cep ? _self.cep : cep // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,raio: null == raio ? _self.raio : raio // ignore: cast_nullable_to_non_nullable
as int,precise: null == precise ? _self.precise : precise // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppLocation].
extension AppLocationPatterns on AppLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppLocation value)  $default,){
final _that = this;
switch (_that) {
case _AppLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppLocation value)?  $default,){
final _that = this;
switch (_that) {
case _AppLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  String? cep,  String? city,  String? state,  int raio,  bool precise)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppLocation() when $default != null:
return $default(_that.lat,_that.lng,_that.cep,_that.city,_that.state,_that.raio,_that.precise);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  String? cep,  String? city,  String? state,  int raio,  bool precise)  $default,) {final _that = this;
switch (_that) {
case _AppLocation():
return $default(_that.lat,_that.lng,_that.cep,_that.city,_that.state,_that.raio,_that.precise);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  String? cep,  String? city,  String? state,  int raio,  bool precise)?  $default,) {final _that = this;
switch (_that) {
case _AppLocation() when $default != null:
return $default(_that.lat,_that.lng,_that.cep,_that.city,_that.state,_that.raio,_that.precise);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppLocation implements AppLocation {
  const _AppLocation({required this.lat, required this.lng, this.cep, this.city, this.state, this.raio = 10, this.precise = false});
  factory _AppLocation.fromJson(Map<String, dynamic> json) => _$AppLocationFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  String? cep;
@override final  String? city;
@override final  String? state;
/// Search radius in km, from the picker's `[1, 5, 10, 15, 25, 50]`.
/// The backend defaults to 25 but the client always sends this explicitly —
/// 10 is our default for a new location, while 50 remains the widest
/// Menor Preço accepts.
@override@JsonKey() final  int raio;
/// True when [lat]/[lng] came from GPS rather than a CEP centroid.
/// A precise fix is what lets "which market am I in?" narrow its radius
/// instead of dragging in a whole city.
@override@JsonKey() final  bool precise;

/// Create a copy of AppLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppLocationCopyWith<_AppLocation> get copyWith => __$AppLocationCopyWithImpl<_AppLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppLocation&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.cep, cep) || other.cep == cep)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.raio, raio) || other.raio == raio)&&(identical(other.precise, precise) || other.precise == precise));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,cep,city,state,raio,precise);

@override
String toString() {
  return 'AppLocation(lat: $lat, lng: $lng, cep: $cep, city: $city, state: $state, raio: $raio, precise: $precise)';
}


}

/// @nodoc
abstract mixin class _$AppLocationCopyWith<$Res> implements $AppLocationCopyWith<$Res> {
  factory _$AppLocationCopyWith(_AppLocation value, $Res Function(_AppLocation) _then) = __$AppLocationCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, String? cep, String? city, String? state, int raio, bool precise
});




}
/// @nodoc
class __$AppLocationCopyWithImpl<$Res>
    implements _$AppLocationCopyWith<$Res> {
  __$AppLocationCopyWithImpl(this._self, this._then);

  final _AppLocation _self;
  final $Res Function(_AppLocation) _then;

/// Create a copy of AppLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? cep = freezed,Object? city = freezed,Object? state = freezed,Object? raio = null,Object? precise = null,}) {
  return _then(_AppLocation(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,cep: freezed == cep ? _self.cep : cep // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,raio: null == raio ? _self.raio : raio // ignore: cast_nullable_to_non_nullable
as int,precise: null == precise ? _self.precise : precise // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
