// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'precos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Offer {

 int get priceCents; String? get store; String? get bairro;/// "RUA TAPUIAS, 845, VILA CASONI, LONDRINA - PR" — enough for a maps search.
 String? get addr;@JsonKey(fromJson: _codFromJson) String? get cod;/// Distance in km. Null when upstream gave no usable distance.
 double? get km;/// When the price was observed, ISO-8601. Kept as the raw string the API
/// sends: weekday-trend detection is the only consumer and it parses this
/// itself, so a malformed date stays one dropped observation rather than a
/// failure to decode the whole response.
 String? get datahora;
/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfferCopyWith<Offer> get copyWith => _$OfferCopyWithImpl<Offer>(this as Offer, _$identity);

  /// Serializes this Offer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Offer&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.store, store) || other.store == store)&&(identical(other.bairro, bairro) || other.bairro == bairro)&&(identical(other.addr, addr) || other.addr == addr)&&(identical(other.cod, cod) || other.cod == cod)&&(identical(other.km, km) || other.km == km)&&(identical(other.datahora, datahora) || other.datahora == datahora));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,priceCents,store,bairro,addr,cod,km,datahora);

@override
String toString() {
  return 'Offer(priceCents: $priceCents, store: $store, bairro: $bairro, addr: $addr, cod: $cod, km: $km, datahora: $datahora)';
}


}

/// @nodoc
abstract mixin class $OfferCopyWith<$Res>  {
  factory $OfferCopyWith(Offer value, $Res Function(Offer) _then) = _$OfferCopyWithImpl;
@useResult
$Res call({
 int priceCents, String? store, String? bairro, String? addr,@JsonKey(fromJson: _codFromJson) String? cod, double? km, String? datahora
});




}
/// @nodoc
class _$OfferCopyWithImpl<$Res>
    implements $OfferCopyWith<$Res> {
  _$OfferCopyWithImpl(this._self, this._then);

  final Offer _self;
  final $Res Function(Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? priceCents = null,Object? store = freezed,Object? bairro = freezed,Object? addr = freezed,Object? cod = freezed,Object? km = freezed,Object? datahora = freezed,}) {
  return _then(_self.copyWith(
priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,bairro: freezed == bairro ? _self.bairro : bairro // ignore: cast_nullable_to_non_nullable
as String?,addr: freezed == addr ? _self.addr : addr // ignore: cast_nullable_to_non_nullable
as String?,cod: freezed == cod ? _self.cod : cod // ignore: cast_nullable_to_non_nullable
as String?,km: freezed == km ? _self.km : km // ignore: cast_nullable_to_non_nullable
as double?,datahora: freezed == datahora ? _self.datahora : datahora // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Offer].
extension OfferPatterns on Offer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Offer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Offer value)  $default,){
final _that = this;
switch (_that) {
case _Offer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Offer value)?  $default,){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int priceCents,  String? store,  String? bairro,  String? addr, @JsonKey(fromJson: _codFromJson)  String? cod,  double? km,  String? datahora)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.priceCents,_that.store,_that.bairro,_that.addr,_that.cod,_that.km,_that.datahora);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int priceCents,  String? store,  String? bairro,  String? addr, @JsonKey(fromJson: _codFromJson)  String? cod,  double? km,  String? datahora)  $default,) {final _that = this;
switch (_that) {
case _Offer():
return $default(_that.priceCents,_that.store,_that.bairro,_that.addr,_that.cod,_that.km,_that.datahora);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int priceCents,  String? store,  String? bairro,  String? addr, @JsonKey(fromJson: _codFromJson)  String? cod,  double? km,  String? datahora)?  $default,) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.priceCents,_that.store,_that.bairro,_that.addr,_that.cod,_that.km,_that.datahora);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Offer implements Offer {
  const _Offer({this.priceCents = 0, this.store, this.bairro, this.addr, @JsonKey(fromJson: _codFromJson) this.cod, this.km, this.datahora});
  factory _Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

@override@JsonKey() final  int priceCents;
@override final  String? store;
@override final  String? bairro;
/// "RUA TAPUIAS, 845, VILA CASONI, LONDRINA - PR" — enough for a maps search.
@override final  String? addr;
@override@JsonKey(fromJson: _codFromJson) final  String? cod;
/// Distance in km. Null when upstream gave no usable distance.
@override final  double? km;
/// When the price was observed, ISO-8601. Kept as the raw string the API
/// sends: weekday-trend detection is the only consumer and it parses this
/// itself, so a malformed date stays one dropped observation rather than a
/// failure to decode the whole response.
@override final  String? datahora;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfferCopyWith<_Offer> get copyWith => __$OfferCopyWithImpl<_Offer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfferToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Offer&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.store, store) || other.store == store)&&(identical(other.bairro, bairro) || other.bairro == bairro)&&(identical(other.addr, addr) || other.addr == addr)&&(identical(other.cod, cod) || other.cod == cod)&&(identical(other.km, km) || other.km == km)&&(identical(other.datahora, datahora) || other.datahora == datahora));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,priceCents,store,bairro,addr,cod,km,datahora);

@override
String toString() {
  return 'Offer(priceCents: $priceCents, store: $store, bairro: $bairro, addr: $addr, cod: $cod, km: $km, datahora: $datahora)';
}


}

/// @nodoc
abstract mixin class _$OfferCopyWith<$Res> implements $OfferCopyWith<$Res> {
  factory _$OfferCopyWith(_Offer value, $Res Function(_Offer) _then) = __$OfferCopyWithImpl;
@override @useResult
$Res call({
 int priceCents, String? store, String? bairro, String? addr,@JsonKey(fromJson: _codFromJson) String? cod, double? km, String? datahora
});




}
/// @nodoc
class __$OfferCopyWithImpl<$Res>
    implements _$OfferCopyWith<$Res> {
  __$OfferCopyWithImpl(this._self, this._then);

  final _Offer _self;
  final $Res Function(_Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? priceCents = null,Object? store = freezed,Object? bairro = freezed,Object? addr = freezed,Object? cod = freezed,Object? km = freezed,Object? datahora = freezed,}) {
  return _then(_Offer(
priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,bairro: freezed == bairro ? _self.bairro : bairro // ignore: cast_nullable_to_non_nullable
as String?,addr: freezed == addr ? _self.addr : addr // ignore: cast_nullable_to_non_nullable
as String?,cod: freezed == cod ? _self.cod : cod // ignore: cast_nullable_to_non_nullable
as String?,km: freezed == km ? _self.km : km // ignore: cast_nullable_to_non_nullable
as double?,datahora: freezed == datahora ? _self.datahora : datahora // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PriceRange {

 int get minCents; int get maxCents;
/// Create a copy of PriceRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceRangeCopyWith<PriceRange> get copyWith => _$PriceRangeCopyWithImpl<PriceRange>(this as PriceRange, _$identity);

  /// Serializes this PriceRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceRange&&(identical(other.minCents, minCents) || other.minCents == minCents)&&(identical(other.maxCents, maxCents) || other.maxCents == maxCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minCents,maxCents);

@override
String toString() {
  return 'PriceRange(minCents: $minCents, maxCents: $maxCents)';
}


}

/// @nodoc
abstract mixin class $PriceRangeCopyWith<$Res>  {
  factory $PriceRangeCopyWith(PriceRange value, $Res Function(PriceRange) _then) = _$PriceRangeCopyWithImpl;
@useResult
$Res call({
 int minCents, int maxCents
});




}
/// @nodoc
class _$PriceRangeCopyWithImpl<$Res>
    implements $PriceRangeCopyWith<$Res> {
  _$PriceRangeCopyWithImpl(this._self, this._then);

  final PriceRange _self;
  final $Res Function(PriceRange) _then;

/// Create a copy of PriceRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minCents = null,Object? maxCents = null,}) {
  return _then(_self.copyWith(
minCents: null == minCents ? _self.minCents : minCents // ignore: cast_nullable_to_non_nullable
as int,maxCents: null == maxCents ? _self.maxCents : maxCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceRange].
extension PriceRangePatterns on PriceRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceRange value)  $default,){
final _that = this;
switch (_that) {
case _PriceRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceRange value)?  $default,){
final _that = this;
switch (_that) {
case _PriceRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minCents,  int maxCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceRange() when $default != null:
return $default(_that.minCents,_that.maxCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minCents,  int maxCents)  $default,) {final _that = this;
switch (_that) {
case _PriceRange():
return $default(_that.minCents,_that.maxCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minCents,  int maxCents)?  $default,) {final _that = this;
switch (_that) {
case _PriceRange() when $default != null:
return $default(_that.minCents,_that.maxCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceRange implements PriceRange {
  const _PriceRange({this.minCents = 0, this.maxCents = 0});
  factory _PriceRange.fromJson(Map<String, dynamic> json) => _$PriceRangeFromJson(json);

@override@JsonKey() final  int minCents;
@override@JsonKey() final  int maxCents;

/// Create a copy of PriceRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceRangeCopyWith<_PriceRange> get copyWith => __$PriceRangeCopyWithImpl<_PriceRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceRangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceRange&&(identical(other.minCents, minCents) || other.minCents == minCents)&&(identical(other.maxCents, maxCents) || other.maxCents == maxCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minCents,maxCents);

@override
String toString() {
  return 'PriceRange(minCents: $minCents, maxCents: $maxCents)';
}


}

/// @nodoc
abstract mixin class _$PriceRangeCopyWith<$Res> implements $PriceRangeCopyWith<$Res> {
  factory _$PriceRangeCopyWith(_PriceRange value, $Res Function(_PriceRange) _then) = __$PriceRangeCopyWithImpl;
@override @useResult
$Res call({
 int minCents, int maxCents
});




}
/// @nodoc
class __$PriceRangeCopyWithImpl<$Res>
    implements _$PriceRangeCopyWith<$Res> {
  __$PriceRangeCopyWithImpl(this._self, this._then);

  final _PriceRange _self;
  final $Res Function(_PriceRange) _then;

/// Create a copy of PriceRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minCents = null,Object? maxCents = null,}) {
  return _then(_PriceRange(
minCents: null == minCents ? _self.minCents : minCents // ignore: cast_nullable_to_non_nullable
as int,maxCents: null == maxCents ? _self.maxCents : maxCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProductOption {

 String get key; String? get gtin; String? get name; Offer? get cheapest; List<Offer> get stores; int get nStores; int get nOffers; String? get ncm;
/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductOptionCopyWith<ProductOption> get copyWith => _$ProductOptionCopyWithImpl<ProductOption>(this as ProductOption, _$identity);

  /// Serializes this ProductOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductOption&&(identical(other.key, key) || other.key == key)&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.name, name) || other.name == name)&&(identical(other.cheapest, cheapest) || other.cheapest == cheapest)&&const DeepCollectionEquality().equals(other.stores, stores)&&(identical(other.nStores, nStores) || other.nStores == nStores)&&(identical(other.nOffers, nOffers) || other.nOffers == nOffers)&&(identical(other.ncm, ncm) || other.ncm == ncm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,gtin,name,cheapest,const DeepCollectionEquality().hash(stores),nStores,nOffers,ncm);

@override
String toString() {
  return 'ProductOption(key: $key, gtin: $gtin, name: $name, cheapest: $cheapest, stores: $stores, nStores: $nStores, nOffers: $nOffers, ncm: $ncm)';
}


}

/// @nodoc
abstract mixin class $ProductOptionCopyWith<$Res>  {
  factory $ProductOptionCopyWith(ProductOption value, $Res Function(ProductOption) _then) = _$ProductOptionCopyWithImpl;
@useResult
$Res call({
 String key, String? gtin, String? name, Offer? cheapest, List<Offer> stores, int nStores, int nOffers, String? ncm
});


$OfferCopyWith<$Res>? get cheapest;

}
/// @nodoc
class _$ProductOptionCopyWithImpl<$Res>
    implements $ProductOptionCopyWith<$Res> {
  _$ProductOptionCopyWithImpl(this._self, this._then);

  final ProductOption _self;
  final $Res Function(ProductOption) _then;

/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? gtin = freezed,Object? name = freezed,Object? cheapest = freezed,Object? stores = null,Object? nStores = null,Object? nOffers = null,Object? ncm = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,cheapest: freezed == cheapest ? _self.cheapest : cheapest // ignore: cast_nullable_to_non_nullable
as Offer?,stores: null == stores ? _self.stores : stores // ignore: cast_nullable_to_non_nullable
as List<Offer>,nStores: null == nStores ? _self.nStores : nStores // ignore: cast_nullable_to_non_nullable
as int,nOffers: null == nOffers ? _self.nOffers : nOffers // ignore: cast_nullable_to_non_nullable
as int,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfferCopyWith<$Res>? get cheapest {
    if (_self.cheapest == null) {
    return null;
  }

  return $OfferCopyWith<$Res>(_self.cheapest!, (value) {
    return _then(_self.copyWith(cheapest: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductOption].
extension ProductOptionPatterns on ProductOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductOption value)  $default,){
final _that = this;
switch (_that) {
case _ProductOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductOption value)?  $default,){
final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String? gtin,  String? name,  Offer? cheapest,  List<Offer> stores,  int nStores,  int nOffers,  String? ncm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
return $default(_that.key,_that.gtin,_that.name,_that.cheapest,_that.stores,_that.nStores,_that.nOffers,_that.ncm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String? gtin,  String? name,  Offer? cheapest,  List<Offer> stores,  int nStores,  int nOffers,  String? ncm)  $default,) {final _that = this;
switch (_that) {
case _ProductOption():
return $default(_that.key,_that.gtin,_that.name,_that.cheapest,_that.stores,_that.nStores,_that.nOffers,_that.ncm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String? gtin,  String? name,  Offer? cheapest,  List<Offer> stores,  int nStores,  int nOffers,  String? ncm)?  $default,) {final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
return $default(_that.key,_that.gtin,_that.name,_that.cheapest,_that.stores,_that.nStores,_that.nOffers,_that.ncm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductOption implements ProductOption {
  const _ProductOption({required this.key, this.gtin, this.name, this.cheapest, final  List<Offer> stores = const <Offer>[], this.nStores = 0, this.nOffers = 0, this.ncm}): _stores = stores;
  factory _ProductOption.fromJson(Map<String, dynamic> json) => _$ProductOptionFromJson(json);

@override final  String key;
@override final  String? gtin;
@override final  String? name;
@override final  Offer? cheapest;
 final  List<Offer> _stores;
@override@JsonKey() List<Offer> get stores {
  if (_stores is EqualUnmodifiableListView) return _stores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stores);
}

@override@JsonKey() final  int nStores;
@override@JsonKey() final  int nOffers;
@override final  String? ncm;

/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductOptionCopyWith<_ProductOption> get copyWith => __$ProductOptionCopyWithImpl<_ProductOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductOption&&(identical(other.key, key) || other.key == key)&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.name, name) || other.name == name)&&(identical(other.cheapest, cheapest) || other.cheapest == cheapest)&&const DeepCollectionEquality().equals(other._stores, _stores)&&(identical(other.nStores, nStores) || other.nStores == nStores)&&(identical(other.nOffers, nOffers) || other.nOffers == nOffers)&&(identical(other.ncm, ncm) || other.ncm == ncm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,gtin,name,cheapest,const DeepCollectionEquality().hash(_stores),nStores,nOffers,ncm);

@override
String toString() {
  return 'ProductOption(key: $key, gtin: $gtin, name: $name, cheapest: $cheapest, stores: $stores, nStores: $nStores, nOffers: $nOffers, ncm: $ncm)';
}


}

/// @nodoc
abstract mixin class _$ProductOptionCopyWith<$Res> implements $ProductOptionCopyWith<$Res> {
  factory _$ProductOptionCopyWith(_ProductOption value, $Res Function(_ProductOption) _then) = __$ProductOptionCopyWithImpl;
@override @useResult
$Res call({
 String key, String? gtin, String? name, Offer? cheapest, List<Offer> stores, int nStores, int nOffers, String? ncm
});


@override $OfferCopyWith<$Res>? get cheapest;

}
/// @nodoc
class __$ProductOptionCopyWithImpl<$Res>
    implements _$ProductOptionCopyWith<$Res> {
  __$ProductOptionCopyWithImpl(this._self, this._then);

  final _ProductOption _self;
  final $Res Function(_ProductOption) _then;

/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? gtin = freezed,Object? name = freezed,Object? cheapest = freezed,Object? stores = null,Object? nStores = null,Object? nOffers = null,Object? ncm = freezed,}) {
  return _then(_ProductOption(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,cheapest: freezed == cheapest ? _self.cheapest : cheapest // ignore: cast_nullable_to_non_nullable
as Offer?,stores: null == stores ? _self._stores : stores // ignore: cast_nullable_to_non_nullable
as List<Offer>,nStores: null == nStores ? _self.nStores : nStores // ignore: cast_nullable_to_non_nullable
as int,nOffers: null == nOffers ? _self.nOffers : nOffers // ignore: cast_nullable_to_non_nullable
as int,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfferCopyWith<$Res>? get cheapest {
    if (_self.cheapest == null) {
    return null;
  }

  return $OfferCopyWith<$Res>(_self.cheapest!, (value) {
    return _then(_self.copyWith(cheapest: value));
  });
}
}


/// @nodoc
mixin _$Precos {

/// The recovered barcode, or null when the match was by description.
 String? get gtin;/// `gtin` | `desc` — how the match was made.
///
/// Defaulted rather than required, and defaulted to the *cautious* pair
/// with [confidence]: a response missing these must never read as an exact
/// barcode match, because that is what suppresses the "aprox." flag.
 String get basis;/// `high` | `approx`.
 String get confidence;/// The cheapest nearby offer. **Has no `cod`** — see [Offer].
 Offer? get cheapest;/// Best price per nearby store, nearest-first, so a whole basket can be
/// priced at any one store without re-querying.
 List<Offer> get stores; PriceRange? get range; int get nOffers; int get nStores;/// The modal description across matched offers — the least surprising label
/// for the product, since every store names it differently.
 String? get name;/// The fiscal NCM most matched offers agree on. Stamped onto the receipt
/// item so classification stops guessing from the description.
 String? get ncm; List<ProductOption> get options;
/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrecosCopyWith<Precos> get copyWith => _$PrecosCopyWithImpl<Precos>(this as Precos, _$identity);

  /// Serializes this Precos to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Precos&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.cheapest, cheapest) || other.cheapest == cheapest)&&const DeepCollectionEquality().equals(other.stores, stores)&&(identical(other.range, range) || other.range == range)&&(identical(other.nOffers, nOffers) || other.nOffers == nOffers)&&(identical(other.nStores, nStores) || other.nStores == nStores)&&(identical(other.name, name) || other.name == name)&&(identical(other.ncm, ncm) || other.ncm == ncm)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gtin,basis,confidence,cheapest,const DeepCollectionEquality().hash(stores),range,nOffers,nStores,name,ncm,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'Precos(gtin: $gtin, basis: $basis, confidence: $confidence, cheapest: $cheapest, stores: $stores, range: $range, nOffers: $nOffers, nStores: $nStores, name: $name, ncm: $ncm, options: $options)';
}


}

/// @nodoc
abstract mixin class $PrecosCopyWith<$Res>  {
  factory $PrecosCopyWith(Precos value, $Res Function(Precos) _then) = _$PrecosCopyWithImpl;
@useResult
$Res call({
 String? gtin, String basis, String confidence, Offer? cheapest, List<Offer> stores, PriceRange? range, int nOffers, int nStores, String? name, String? ncm, List<ProductOption> options
});


$OfferCopyWith<$Res>? get cheapest;$PriceRangeCopyWith<$Res>? get range;

}
/// @nodoc
class _$PrecosCopyWithImpl<$Res>
    implements $PrecosCopyWith<$Res> {
  _$PrecosCopyWithImpl(this._self, this._then);

  final Precos _self;
  final $Res Function(Precos) _then;

/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gtin = freezed,Object? basis = null,Object? confidence = null,Object? cheapest = freezed,Object? stores = null,Object? range = freezed,Object? nOffers = null,Object? nStores = null,Object? name = freezed,Object? ncm = freezed,Object? options = null,}) {
  return _then(_self.copyWith(
gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as String,cheapest: freezed == cheapest ? _self.cheapest : cheapest // ignore: cast_nullable_to_non_nullable
as Offer?,stores: null == stores ? _self.stores : stores // ignore: cast_nullable_to_non_nullable
as List<Offer>,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as PriceRange?,nOffers: null == nOffers ? _self.nOffers : nOffers // ignore: cast_nullable_to_non_nullable
as int,nStores: null == nStores ? _self.nStores : nStores // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<ProductOption>,
  ));
}
/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfferCopyWith<$Res>? get cheapest {
    if (_self.cheapest == null) {
    return null;
  }

  return $OfferCopyWith<$Res>(_self.cheapest!, (value) {
    return _then(_self.copyWith(cheapest: value));
  });
}/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceRangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $PriceRangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [Precos].
extension PrecosPatterns on Precos {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Precos value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Precos() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Precos value)  $default,){
final _that = this;
switch (_that) {
case _Precos():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Precos value)?  $default,){
final _that = this;
switch (_that) {
case _Precos() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? gtin,  String basis,  String confidence,  Offer? cheapest,  List<Offer> stores,  PriceRange? range,  int nOffers,  int nStores,  String? name,  String? ncm,  List<ProductOption> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Precos() when $default != null:
return $default(_that.gtin,_that.basis,_that.confidence,_that.cheapest,_that.stores,_that.range,_that.nOffers,_that.nStores,_that.name,_that.ncm,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? gtin,  String basis,  String confidence,  Offer? cheapest,  List<Offer> stores,  PriceRange? range,  int nOffers,  int nStores,  String? name,  String? ncm,  List<ProductOption> options)  $default,) {final _that = this;
switch (_that) {
case _Precos():
return $default(_that.gtin,_that.basis,_that.confidence,_that.cheapest,_that.stores,_that.range,_that.nOffers,_that.nStores,_that.name,_that.ncm,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? gtin,  String basis,  String confidence,  Offer? cheapest,  List<Offer> stores,  PriceRange? range,  int nOffers,  int nStores,  String? name,  String? ncm,  List<ProductOption> options)?  $default,) {final _that = this;
switch (_that) {
case _Precos() when $default != null:
return $default(_that.gtin,_that.basis,_that.confidence,_that.cheapest,_that.stores,_that.range,_that.nOffers,_that.nStores,_that.name,_that.ncm,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Precos implements Precos {
  const _Precos({this.gtin, this.basis = 'desc', this.confidence = 'approx', this.cheapest, final  List<Offer> stores = const <Offer>[], this.range, this.nOffers = 0, this.nStores = 0, this.name, this.ncm, final  List<ProductOption> options = const <ProductOption>[]}): _stores = stores,_options = options;
  factory _Precos.fromJson(Map<String, dynamic> json) => _$PrecosFromJson(json);

/// The recovered barcode, or null when the match was by description.
@override final  String? gtin;
/// `gtin` | `desc` — how the match was made.
///
/// Defaulted rather than required, and defaulted to the *cautious* pair
/// with [confidence]: a response missing these must never read as an exact
/// barcode match, because that is what suppresses the "aprox." flag.
@override@JsonKey() final  String basis;
/// `high` | `approx`.
@override@JsonKey() final  String confidence;
/// The cheapest nearby offer. **Has no `cod`** — see [Offer].
@override final  Offer? cheapest;
/// Best price per nearby store, nearest-first, so a whole basket can be
/// priced at any one store without re-querying.
 final  List<Offer> _stores;
/// Best price per nearby store, nearest-first, so a whole basket can be
/// priced at any one store without re-querying.
@override@JsonKey() List<Offer> get stores {
  if (_stores is EqualUnmodifiableListView) return _stores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stores);
}

@override final  PriceRange? range;
@override@JsonKey() final  int nOffers;
@override@JsonKey() final  int nStores;
/// The modal description across matched offers — the least surprising label
/// for the product, since every store names it differently.
@override final  String? name;
/// The fiscal NCM most matched offers agree on. Stamped onto the receipt
/// item so classification stops guessing from the description.
@override final  String? ncm;
 final  List<ProductOption> _options;
@override@JsonKey() List<ProductOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrecosCopyWith<_Precos> get copyWith => __$PrecosCopyWithImpl<_Precos>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrecosToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Precos&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.cheapest, cheapest) || other.cheapest == cheapest)&&const DeepCollectionEquality().equals(other._stores, _stores)&&(identical(other.range, range) || other.range == range)&&(identical(other.nOffers, nOffers) || other.nOffers == nOffers)&&(identical(other.nStores, nStores) || other.nStores == nStores)&&(identical(other.name, name) || other.name == name)&&(identical(other.ncm, ncm) || other.ncm == ncm)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gtin,basis,confidence,cheapest,const DeepCollectionEquality().hash(_stores),range,nOffers,nStores,name,ncm,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'Precos(gtin: $gtin, basis: $basis, confidence: $confidence, cheapest: $cheapest, stores: $stores, range: $range, nOffers: $nOffers, nStores: $nStores, name: $name, ncm: $ncm, options: $options)';
}


}

/// @nodoc
abstract mixin class _$PrecosCopyWith<$Res> implements $PrecosCopyWith<$Res> {
  factory _$PrecosCopyWith(_Precos value, $Res Function(_Precos) _then) = __$PrecosCopyWithImpl;
@override @useResult
$Res call({
 String? gtin, String basis, String confidence, Offer? cheapest, List<Offer> stores, PriceRange? range, int nOffers, int nStores, String? name, String? ncm, List<ProductOption> options
});


@override $OfferCopyWith<$Res>? get cheapest;@override $PriceRangeCopyWith<$Res>? get range;

}
/// @nodoc
class __$PrecosCopyWithImpl<$Res>
    implements _$PrecosCopyWith<$Res> {
  __$PrecosCopyWithImpl(this._self, this._then);

  final _Precos _self;
  final $Res Function(_Precos) _then;

/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gtin = freezed,Object? basis = null,Object? confidence = null,Object? cheapest = freezed,Object? stores = null,Object? range = freezed,Object? nOffers = null,Object? nStores = null,Object? name = freezed,Object? ncm = freezed,Object? options = null,}) {
  return _then(_Precos(
gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as String,cheapest: freezed == cheapest ? _self.cheapest : cheapest // ignore: cast_nullable_to_non_nullable
as Offer?,stores: null == stores ? _self._stores : stores // ignore: cast_nullable_to_non_nullable
as List<Offer>,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as PriceRange?,nOffers: null == nOffers ? _self.nOffers : nOffers // ignore: cast_nullable_to_non_nullable
as int,nStores: null == nStores ? _self.nStores : nStores // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<ProductOption>,
  ));
}

/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfferCopyWith<$Res>? get cheapest {
    if (_self.cheapest == null) {
    return null;
  }

  return $OfferCopyWith<$Res>(_self.cheapest!, (value) {
    return _then(_self.copyWith(cheapest: value));
  });
}/// Create a copy of Precos
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceRangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $PriceRangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// @nodoc
mixin _$PriceObservation {

 String get cod; String? get store;@JsonKey(unknownEnumValue: Categoria.outros) Categoria get category; String? get gtin; int get priceCents; String get datahora;
/// Create a copy of PriceObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceObservationCopyWith<PriceObservation> get copyWith => _$PriceObservationCopyWithImpl<PriceObservation>(this as PriceObservation, _$identity);

  /// Serializes this PriceObservation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceObservation&&(identical(other.cod, cod) || other.cod == cod)&&(identical(other.store, store) || other.store == store)&&(identical(other.category, category) || other.category == category)&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.datahora, datahora) || other.datahora == datahora));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cod,store,category,gtin,priceCents,datahora);

@override
String toString() {
  return 'PriceObservation(cod: $cod, store: $store, category: $category, gtin: $gtin, priceCents: $priceCents, datahora: $datahora)';
}


}

/// @nodoc
abstract mixin class $PriceObservationCopyWith<$Res>  {
  factory $PriceObservationCopyWith(PriceObservation value, $Res Function(PriceObservation) _then) = _$PriceObservationCopyWithImpl;
@useResult
$Res call({
 String cod, String? store,@JsonKey(unknownEnumValue: Categoria.outros) Categoria category, String? gtin, int priceCents, String datahora
});




}
/// @nodoc
class _$PriceObservationCopyWithImpl<$Res>
    implements $PriceObservationCopyWith<$Res> {
  _$PriceObservationCopyWithImpl(this._self, this._then);

  final PriceObservation _self;
  final $Res Function(PriceObservation) _then;

/// Create a copy of PriceObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cod = null,Object? store = freezed,Object? category = null,Object? gtin = freezed,Object? priceCents = null,Object? datahora = null,}) {
  return _then(_self.copyWith(
cod: null == cod ? _self.cod : cod // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Categoria,gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,datahora: null == datahora ? _self.datahora : datahora // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceObservation].
extension PriceObservationPatterns on PriceObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceObservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceObservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceObservation value)  $default,){
final _that = this;
switch (_that) {
case _PriceObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceObservation value)?  $default,){
final _that = this;
switch (_that) {
case _PriceObservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cod,  String? store, @JsonKey(unknownEnumValue: Categoria.outros)  Categoria category,  String? gtin,  int priceCents,  String datahora)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceObservation() when $default != null:
return $default(_that.cod,_that.store,_that.category,_that.gtin,_that.priceCents,_that.datahora);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cod,  String? store, @JsonKey(unknownEnumValue: Categoria.outros)  Categoria category,  String? gtin,  int priceCents,  String datahora)  $default,) {final _that = this;
switch (_that) {
case _PriceObservation():
return $default(_that.cod,_that.store,_that.category,_that.gtin,_that.priceCents,_that.datahora);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cod,  String? store, @JsonKey(unknownEnumValue: Categoria.outros)  Categoria category,  String? gtin,  int priceCents,  String datahora)?  $default,) {final _that = this;
switch (_that) {
case _PriceObservation() when $default != null:
return $default(_that.cod,_that.store,_that.category,_that.gtin,_that.priceCents,_that.datahora);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceObservation extends PriceObservation {
  const _PriceObservation({required this.cod, this.store, @JsonKey(unknownEnumValue: Categoria.outros) this.category = Categoria.outros, this.gtin, required this.priceCents, required this.datahora}): super._();
  factory _PriceObservation.fromJson(Map<String, dynamic> json) => _$PriceObservationFromJson(json);

@override final  String cod;
@override final  String? store;
@override@JsonKey(unknownEnumValue: Categoria.outros) final  Categoria category;
@override final  String? gtin;
@override final  int priceCents;
@override final  String datahora;

/// Create a copy of PriceObservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceObservationCopyWith<_PriceObservation> get copyWith => __$PriceObservationCopyWithImpl<_PriceObservation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceObservationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceObservation&&(identical(other.cod, cod) || other.cod == cod)&&(identical(other.store, store) || other.store == store)&&(identical(other.category, category) || other.category == category)&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.datahora, datahora) || other.datahora == datahora));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cod,store,category,gtin,priceCents,datahora);

@override
String toString() {
  return 'PriceObservation(cod: $cod, store: $store, category: $category, gtin: $gtin, priceCents: $priceCents, datahora: $datahora)';
}


}

/// @nodoc
abstract mixin class _$PriceObservationCopyWith<$Res> implements $PriceObservationCopyWith<$Res> {
  factory _$PriceObservationCopyWith(_PriceObservation value, $Res Function(_PriceObservation) _then) = __$PriceObservationCopyWithImpl;
@override @useResult
$Res call({
 String cod, String? store,@JsonKey(unknownEnumValue: Categoria.outros) Categoria category, String? gtin, int priceCents, String datahora
});




}
/// @nodoc
class __$PriceObservationCopyWithImpl<$Res>
    implements _$PriceObservationCopyWith<$Res> {
  __$PriceObservationCopyWithImpl(this._self, this._then);

  final _PriceObservation _self;
  final $Res Function(_PriceObservation) _then;

/// Create a copy of PriceObservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cod = null,Object? store = freezed,Object? category = null,Object? gtin = freezed,Object? priceCents = null,Object? datahora = null,}) {
  return _then(_PriceObservation(
cod: null == cod ? _self.cod : cod // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Categoria,gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,datahora: null == datahora ? _self.datahora : datahora // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
