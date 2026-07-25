// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReceiptHeader {

 String? get cnpj; String? get storeName; String? get city; String? get address;/// `"DD/MM/YYYY HH:mm:ss"`, exactly as the consulta prints it.
 String? get purchasedAt;/// "Valor a pagar", never the first total on the page (that one is the item
/// count) and never the pre-discount subtotal.
 int get totalCents;
/// Create a copy of ReceiptHeader
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptHeaderCopyWith<ReceiptHeader> get copyWith => _$ReceiptHeaderCopyWithImpl<ReceiptHeader>(this as ReceiptHeader, _$identity);

  /// Serializes this ReceiptHeader to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptHeader&&(identical(other.cnpj, cnpj) || other.cnpj == cnpj)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.totalCents, totalCents) || other.totalCents == totalCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cnpj,storeName,city,address,purchasedAt,totalCents);

@override
String toString() {
  return 'ReceiptHeader(cnpj: $cnpj, storeName: $storeName, city: $city, address: $address, purchasedAt: $purchasedAt, totalCents: $totalCents)';
}


}

/// @nodoc
abstract mixin class $ReceiptHeaderCopyWith<$Res>  {
  factory $ReceiptHeaderCopyWith(ReceiptHeader value, $Res Function(ReceiptHeader) _then) = _$ReceiptHeaderCopyWithImpl;
@useResult
$Res call({
 String? cnpj, String? storeName, String? city, String? address, String? purchasedAt, int totalCents
});




}
/// @nodoc
class _$ReceiptHeaderCopyWithImpl<$Res>
    implements $ReceiptHeaderCopyWith<$Res> {
  _$ReceiptHeaderCopyWithImpl(this._self, this._then);

  final ReceiptHeader _self;
  final $Res Function(ReceiptHeader) _then;

/// Create a copy of ReceiptHeader
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cnpj = freezed,Object? storeName = freezed,Object? city = freezed,Object? address = freezed,Object? purchasedAt = freezed,Object? totalCents = null,}) {
  return _then(_self.copyWith(
cnpj: freezed == cnpj ? _self.cnpj : cnpj // ignore: cast_nullable_to_non_nullable
as String?,storeName: freezed == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String?,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptHeader].
extension ReceiptHeaderPatterns on ReceiptHeader {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptHeader value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptHeader() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptHeader value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptHeader():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptHeader value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptHeader() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? cnpj,  String? storeName,  String? city,  String? address,  String? purchasedAt,  int totalCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptHeader() when $default != null:
return $default(_that.cnpj,_that.storeName,_that.city,_that.address,_that.purchasedAt,_that.totalCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? cnpj,  String? storeName,  String? city,  String? address,  String? purchasedAt,  int totalCents)  $default,) {final _that = this;
switch (_that) {
case _ReceiptHeader():
return $default(_that.cnpj,_that.storeName,_that.city,_that.address,_that.purchasedAt,_that.totalCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? cnpj,  String? storeName,  String? city,  String? address,  String? purchasedAt,  int totalCents)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptHeader() when $default != null:
return $default(_that.cnpj,_that.storeName,_that.city,_that.address,_that.purchasedAt,_that.totalCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptHeader implements ReceiptHeader {
  const _ReceiptHeader({this.cnpj, this.storeName, this.city, this.address, this.purchasedAt, this.totalCents = 0});
  factory _ReceiptHeader.fromJson(Map<String, dynamic> json) => _$ReceiptHeaderFromJson(json);

@override final  String? cnpj;
@override final  String? storeName;
@override final  String? city;
@override final  String? address;
/// `"DD/MM/YYYY HH:mm:ss"`, exactly as the consulta prints it.
@override final  String? purchasedAt;
/// "Valor a pagar", never the first total on the page (that one is the item
/// count) and never the pre-discount subtotal.
@override@JsonKey() final  int totalCents;

/// Create a copy of ReceiptHeader
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptHeaderCopyWith<_ReceiptHeader> get copyWith => __$ReceiptHeaderCopyWithImpl<_ReceiptHeader>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptHeaderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptHeader&&(identical(other.cnpj, cnpj) || other.cnpj == cnpj)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.totalCents, totalCents) || other.totalCents == totalCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cnpj,storeName,city,address,purchasedAt,totalCents);

@override
String toString() {
  return 'ReceiptHeader(cnpj: $cnpj, storeName: $storeName, city: $city, address: $address, purchasedAt: $purchasedAt, totalCents: $totalCents)';
}


}

/// @nodoc
abstract mixin class _$ReceiptHeaderCopyWith<$Res> implements $ReceiptHeaderCopyWith<$Res> {
  factory _$ReceiptHeaderCopyWith(_ReceiptHeader value, $Res Function(_ReceiptHeader) _then) = __$ReceiptHeaderCopyWithImpl;
@override @useResult
$Res call({
 String? cnpj, String? storeName, String? city, String? address, String? purchasedAt, int totalCents
});




}
/// @nodoc
class __$ReceiptHeaderCopyWithImpl<$Res>
    implements _$ReceiptHeaderCopyWith<$Res> {
  __$ReceiptHeaderCopyWithImpl(this._self, this._then);

  final _ReceiptHeader _self;
  final $Res Function(_ReceiptHeader) _then;

/// Create a copy of ReceiptHeader
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cnpj = freezed,Object? storeName = freezed,Object? city = freezed,Object? address = freezed,Object? purchasedAt = freezed,Object? totalCents = null,}) {
  return _then(_ReceiptHeader(
cnpj: freezed == cnpj ? _self.cnpj : cnpj // ignore: cast_nullable_to_non_nullable
as String?,storeName: freezed == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String?,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ReceiptItem {

 String get description;/// Null for weighed/PLU lines and anything the consulta marks "SEM GTIN".
 String? get gtin; double get qty;/// `UN`, `KG`, … The per-UN vs per-KG distinction is the produce
/// false-match trap, so this travels with the item everywhere.
 String? get unit; int get unitPriceCents; int get lineTotalCents;/// Cheapest-nearby result. Null means **uncompared** — the price lookup
/// failed or found nothing — which is a state the report shows honestly
/// rather than treating as "no savings available".
 Precos? get precos;/// Fiscal NCM, stamped from the matched product during enrichment so
/// classification is deterministic on re-open.
 String? get ncm;
/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptItemCopyWith<ReceiptItem> get copyWith => _$ReceiptItemCopyWithImpl<ReceiptItem>(this as ReceiptItem, _$identity);

  /// Serializes this ReceiptItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptItem&&(identical(other.description, description) || other.description == description)&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.lineTotalCents, lineTotalCents) || other.lineTotalCents == lineTotalCents)&&(identical(other.precos, precos) || other.precos == precos)&&(identical(other.ncm, ncm) || other.ncm == ncm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,gtin,qty,unit,unitPriceCents,lineTotalCents,precos,ncm);

@override
String toString() {
  return 'ReceiptItem(description: $description, gtin: $gtin, qty: $qty, unit: $unit, unitPriceCents: $unitPriceCents, lineTotalCents: $lineTotalCents, precos: $precos, ncm: $ncm)';
}


}

/// @nodoc
abstract mixin class $ReceiptItemCopyWith<$Res>  {
  factory $ReceiptItemCopyWith(ReceiptItem value, $Res Function(ReceiptItem) _then) = _$ReceiptItemCopyWithImpl;
@useResult
$Res call({
 String description, String? gtin, double qty, String? unit, int unitPriceCents, int lineTotalCents, Precos? precos, String? ncm
});


$PrecosCopyWith<$Res>? get precos;

}
/// @nodoc
class _$ReceiptItemCopyWithImpl<$Res>
    implements $ReceiptItemCopyWith<$Res> {
  _$ReceiptItemCopyWithImpl(this._self, this._then);

  final ReceiptItem _self;
  final $Res Function(ReceiptItem) _then;

/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? gtin = freezed,Object? qty = null,Object? unit = freezed,Object? unitPriceCents = null,Object? lineTotalCents = null,Object? precos = freezed,Object? ncm = freezed,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,lineTotalCents: null == lineTotalCents ? _self.lineTotalCents : lineTotalCents // ignore: cast_nullable_to_non_nullable
as int,precos: freezed == precos ? _self.precos : precos // ignore: cast_nullable_to_non_nullable
as Precos?,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrecosCopyWith<$Res>? get precos {
    if (_self.precos == null) {
    return null;
  }

  return $PrecosCopyWith<$Res>(_self.precos!, (value) {
    return _then(_self.copyWith(precos: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReceiptItem].
extension ReceiptItemPatterns on ReceiptItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptItem value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  String? gtin,  double qty,  String? unit,  int unitPriceCents,  int lineTotalCents,  Precos? precos,  String? ncm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
return $default(_that.description,_that.gtin,_that.qty,_that.unit,_that.unitPriceCents,_that.lineTotalCents,_that.precos,_that.ncm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  String? gtin,  double qty,  String? unit,  int unitPriceCents,  int lineTotalCents,  Precos? precos,  String? ncm)  $default,) {final _that = this;
switch (_that) {
case _ReceiptItem():
return $default(_that.description,_that.gtin,_that.qty,_that.unit,_that.unitPriceCents,_that.lineTotalCents,_that.precos,_that.ncm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  String? gtin,  double qty,  String? unit,  int unitPriceCents,  int lineTotalCents,  Precos? precos,  String? ncm)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
return $default(_that.description,_that.gtin,_that.qty,_that.unit,_that.unitPriceCents,_that.lineTotalCents,_that.precos,_that.ncm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptItem implements ReceiptItem {
  const _ReceiptItem({required this.description, this.gtin, this.qty = 1.0, this.unit, this.unitPriceCents = 0, this.lineTotalCents = 0, this.precos, this.ncm});
  factory _ReceiptItem.fromJson(Map<String, dynamic> json) => _$ReceiptItemFromJson(json);

@override final  String description;
/// Null for weighed/PLU lines and anything the consulta marks "SEM GTIN".
@override final  String? gtin;
@override@JsonKey() final  double qty;
/// `UN`, `KG`, … The per-UN vs per-KG distinction is the produce
/// false-match trap, so this travels with the item everywhere.
@override final  String? unit;
@override@JsonKey() final  int unitPriceCents;
@override@JsonKey() final  int lineTotalCents;
/// Cheapest-nearby result. Null means **uncompared** — the price lookup
/// failed or found nothing — which is a state the report shows honestly
/// rather than treating as "no savings available".
@override final  Precos? precos;
/// Fiscal NCM, stamped from the matched product during enrichment so
/// classification is deterministic on re-open.
@override final  String? ncm;

/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptItemCopyWith<_ReceiptItem> get copyWith => __$ReceiptItemCopyWithImpl<_ReceiptItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptItem&&(identical(other.description, description) || other.description == description)&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.lineTotalCents, lineTotalCents) || other.lineTotalCents == lineTotalCents)&&(identical(other.precos, precos) || other.precos == precos)&&(identical(other.ncm, ncm) || other.ncm == ncm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,gtin,qty,unit,unitPriceCents,lineTotalCents,precos,ncm);

@override
String toString() {
  return 'ReceiptItem(description: $description, gtin: $gtin, qty: $qty, unit: $unit, unitPriceCents: $unitPriceCents, lineTotalCents: $lineTotalCents, precos: $precos, ncm: $ncm)';
}


}

/// @nodoc
abstract mixin class _$ReceiptItemCopyWith<$Res> implements $ReceiptItemCopyWith<$Res> {
  factory _$ReceiptItemCopyWith(_ReceiptItem value, $Res Function(_ReceiptItem) _then) = __$ReceiptItemCopyWithImpl;
@override @useResult
$Res call({
 String description, String? gtin, double qty, String? unit, int unitPriceCents, int lineTotalCents, Precos? precos, String? ncm
});


@override $PrecosCopyWith<$Res>? get precos;

}
/// @nodoc
class __$ReceiptItemCopyWithImpl<$Res>
    implements _$ReceiptItemCopyWith<$Res> {
  __$ReceiptItemCopyWithImpl(this._self, this._then);

  final _ReceiptItem _self;
  final $Res Function(_ReceiptItem) _then;

/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? gtin = freezed,Object? qty = null,Object? unit = freezed,Object? unitPriceCents = null,Object? lineTotalCents = null,Object? precos = freezed,Object? ncm = freezed,}) {
  return _then(_ReceiptItem(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,lineTotalCents: null == lineTotalCents ? _self.lineTotalCents : lineTotalCents // ignore: cast_nullable_to_non_nullable
as int,precos: freezed == precos ? _self.precos : precos // ignore: cast_nullable_to_non_nullable
as Precos?,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrecosCopyWith<$Res>? get precos {
    if (_self.precos == null) {
    return null;
  }

  return $PrecosCopyWith<$Res>(_self.precos!, (value) {
    return _then(_self.copyWith(precos: value));
  });
}
}


/// @nodoc
mixin _$Receipt {

/// The 44-digit chave de acesso. Also the record key in the `receipts`
/// store, which is what makes re-scanning the same nota idempotent.
 String get accessKey; ReceiptHeader get header; List<ReceiptItem> get items;/// Epoch ms, stamped on first save. History sorts on it, newest first.
 int? get createdAt;/// Epoch ms of the last successful pricing pass; null while unpriced.
 int? get enrichedAt;/// The CEP the prices were fetched for. A different CEP now means the
/// savings figure is about somewhere the user no longer is.
 String? get locationCep;
/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCopyWith<Receipt> get copyWith => _$ReceiptCopyWithImpl<Receipt>(this as Receipt, _$identity);

  /// Serializes this Receipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Receipt&&(identical(other.accessKey, accessKey) || other.accessKey == accessKey)&&(identical(other.header, header) || other.header == header)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.enrichedAt, enrichedAt) || other.enrichedAt == enrichedAt)&&(identical(other.locationCep, locationCep) || other.locationCep == locationCep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessKey,header,const DeepCollectionEquality().hash(items),createdAt,enrichedAt,locationCep);

@override
String toString() {
  return 'Receipt(accessKey: $accessKey, header: $header, items: $items, createdAt: $createdAt, enrichedAt: $enrichedAt, locationCep: $locationCep)';
}


}

/// @nodoc
abstract mixin class $ReceiptCopyWith<$Res>  {
  factory $ReceiptCopyWith(Receipt value, $Res Function(Receipt) _then) = _$ReceiptCopyWithImpl;
@useResult
$Res call({
 String accessKey, ReceiptHeader header, List<ReceiptItem> items, int? createdAt, int? enrichedAt, String? locationCep
});


$ReceiptHeaderCopyWith<$Res> get header;

}
/// @nodoc
class _$ReceiptCopyWithImpl<$Res>
    implements $ReceiptCopyWith<$Res> {
  _$ReceiptCopyWithImpl(this._self, this._then);

  final Receipt _self;
  final $Res Function(Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessKey = null,Object? header = null,Object? items = null,Object? createdAt = freezed,Object? enrichedAt = freezed,Object? locationCep = freezed,}) {
  return _then(_self.copyWith(
accessKey: null == accessKey ? _self.accessKey : accessKey // ignore: cast_nullable_to_non_nullable
as String,header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as ReceiptHeader,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,enrichedAt: freezed == enrichedAt ? _self.enrichedAt : enrichedAt // ignore: cast_nullable_to_non_nullable
as int?,locationCep: freezed == locationCep ? _self.locationCep : locationCep // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReceiptHeaderCopyWith<$Res> get header {
  
  return $ReceiptHeaderCopyWith<$Res>(_self.header, (value) {
    return _then(_self.copyWith(header: value));
  });
}
}


/// Adds pattern-matching-related methods to [Receipt].
extension ReceiptPatterns on Receipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Receipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Receipt value)  $default,){
final _that = this;
switch (_that) {
case _Receipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Receipt value)?  $default,){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessKey,  ReceiptHeader header,  List<ReceiptItem> items,  int? createdAt,  int? enrichedAt,  String? locationCep)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.accessKey,_that.header,_that.items,_that.createdAt,_that.enrichedAt,_that.locationCep);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessKey,  ReceiptHeader header,  List<ReceiptItem> items,  int? createdAt,  int? enrichedAt,  String? locationCep)  $default,) {final _that = this;
switch (_that) {
case _Receipt():
return $default(_that.accessKey,_that.header,_that.items,_that.createdAt,_that.enrichedAt,_that.locationCep);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessKey,  ReceiptHeader header,  List<ReceiptItem> items,  int? createdAt,  int? enrichedAt,  String? locationCep)?  $default,) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.accessKey,_that.header,_that.items,_that.createdAt,_that.enrichedAt,_that.locationCep);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Receipt implements Receipt {
  const _Receipt({required this.accessKey, this.header = const ReceiptHeader(), final  List<ReceiptItem> items = const <ReceiptItem>[], this.createdAt, this.enrichedAt, this.locationCep}): _items = items;
  factory _Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);

/// The 44-digit chave de acesso. Also the record key in the `receipts`
/// store, which is what makes re-scanning the same nota idempotent.
@override final  String accessKey;
@override@JsonKey() final  ReceiptHeader header;
 final  List<ReceiptItem> _items;
@override@JsonKey() List<ReceiptItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Epoch ms, stamped on first save. History sorts on it, newest first.
@override final  int? createdAt;
/// Epoch ms of the last successful pricing pass; null while unpriced.
@override final  int? enrichedAt;
/// The CEP the prices were fetched for. A different CEP now means the
/// savings figure is about somewhere the user no longer is.
@override final  String? locationCep;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptCopyWith<_Receipt> get copyWith => __$ReceiptCopyWithImpl<_Receipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Receipt&&(identical(other.accessKey, accessKey) || other.accessKey == accessKey)&&(identical(other.header, header) || other.header == header)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.enrichedAt, enrichedAt) || other.enrichedAt == enrichedAt)&&(identical(other.locationCep, locationCep) || other.locationCep == locationCep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessKey,header,const DeepCollectionEquality().hash(_items),createdAt,enrichedAt,locationCep);

@override
String toString() {
  return 'Receipt(accessKey: $accessKey, header: $header, items: $items, createdAt: $createdAt, enrichedAt: $enrichedAt, locationCep: $locationCep)';
}


}

/// @nodoc
abstract mixin class _$ReceiptCopyWith<$Res> implements $ReceiptCopyWith<$Res> {
  factory _$ReceiptCopyWith(_Receipt value, $Res Function(_Receipt) _then) = __$ReceiptCopyWithImpl;
@override @useResult
$Res call({
 String accessKey, ReceiptHeader header, List<ReceiptItem> items, int? createdAt, int? enrichedAt, String? locationCep
});


@override $ReceiptHeaderCopyWith<$Res> get header;

}
/// @nodoc
class __$ReceiptCopyWithImpl<$Res>
    implements _$ReceiptCopyWith<$Res> {
  __$ReceiptCopyWithImpl(this._self, this._then);

  final _Receipt _self;
  final $Res Function(_Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessKey = null,Object? header = null,Object? items = null,Object? createdAt = freezed,Object? enrichedAt = freezed,Object? locationCep = freezed,}) {
  return _then(_Receipt(
accessKey: null == accessKey ? _self.accessKey : accessKey // ignore: cast_nullable_to_non_nullable
as String,header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as ReceiptHeader,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,enrichedAt: freezed == enrichedAt ? _self.enrichedAt : enrichedAt // ignore: cast_nullable_to_non_nullable
as int?,locationCep: freezed == locationCep ? _self.locationCep : locationCep // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReceiptHeaderCopyWith<$Res> get header {
  
  return $ReceiptHeaderCopyWith<$Res>(_self.header, (value) {
    return _then(_self.copyWith(header: value));
  });
}
}

// dart format on
