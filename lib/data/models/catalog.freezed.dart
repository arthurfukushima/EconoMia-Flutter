// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogItem {

 String? get gtin; String get description; String? get ncm;@JsonKey(name: 'priceCents') int get priceCents; String? get fetchedAt;@JsonKey(name: 'minCents') int? get minCents;@JsonKey(name: 'maxCents') int? get maxCents; int get nStores; int get rank;/// Server-computed via `classify()` (same categories as `Categoria`).
 String get category;/// `otimo` | `ok` | `caro` | `unico` — see [catalogBucketLabel].
 String get bucket;/// How far this price sits between the region's min and max, 0–100.
/// Null exactly when [bucket] is `unico`.
 int? get pct;
/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogItemCopyWith<CatalogItem> get copyWith => _$CatalogItemCopyWithImpl<CatalogItem>(this as CatalogItem, _$identity);

  /// Serializes this CatalogItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogItem&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.description, description) || other.description == description)&&(identical(other.ncm, ncm) || other.ncm == ncm)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.minCents, minCents) || other.minCents == minCents)&&(identical(other.maxCents, maxCents) || other.maxCents == maxCents)&&(identical(other.nStores, nStores) || other.nStores == nStores)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.category, category) || other.category == category)&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.pct, pct) || other.pct == pct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gtin,description,ncm,priceCents,fetchedAt,minCents,maxCents,nStores,rank,category,bucket,pct);

@override
String toString() {
  return 'CatalogItem(gtin: $gtin, description: $description, ncm: $ncm, priceCents: $priceCents, fetchedAt: $fetchedAt, minCents: $minCents, maxCents: $maxCents, nStores: $nStores, rank: $rank, category: $category, bucket: $bucket, pct: $pct)';
}


}

/// @nodoc
abstract mixin class $CatalogItemCopyWith<$Res>  {
  factory $CatalogItemCopyWith(CatalogItem value, $Res Function(CatalogItem) _then) = _$CatalogItemCopyWithImpl;
@useResult
$Res call({
 String? gtin, String description, String? ncm,@JsonKey(name: 'priceCents') int priceCents, String? fetchedAt,@JsonKey(name: 'minCents') int? minCents,@JsonKey(name: 'maxCents') int? maxCents, int nStores, int rank, String category, String bucket, int? pct
});




}
/// @nodoc
class _$CatalogItemCopyWithImpl<$Res>
    implements $CatalogItemCopyWith<$Res> {
  _$CatalogItemCopyWithImpl(this._self, this._then);

  final CatalogItem _self;
  final $Res Function(CatalogItem) _then;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gtin = freezed,Object? description = null,Object? ncm = freezed,Object? priceCents = null,Object? fetchedAt = freezed,Object? minCents = freezed,Object? maxCents = freezed,Object? nStores = null,Object? rank = null,Object? category = null,Object? bucket = null,Object? pct = freezed,}) {
  return _then(_self.copyWith(
gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as String?,minCents: freezed == minCents ? _self.minCents : minCents // ignore: cast_nullable_to_non_nullable
as int?,maxCents: freezed == maxCents ? _self.maxCents : maxCents // ignore: cast_nullable_to_non_nullable
as int?,nStores: null == nStores ? _self.nStores : nStores // ignore: cast_nullable_to_non_nullable
as int,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,pct: freezed == pct ? _self.pct : pct // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogItem].
extension CatalogItemPatterns on CatalogItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogItem value)  $default,){
final _that = this;
switch (_that) {
case _CatalogItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? gtin,  String description,  String? ncm, @JsonKey(name: 'priceCents')  int priceCents,  String? fetchedAt, @JsonKey(name: 'minCents')  int? minCents, @JsonKey(name: 'maxCents')  int? maxCents,  int nStores,  int rank,  String category,  String bucket,  int? pct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
return $default(_that.gtin,_that.description,_that.ncm,_that.priceCents,_that.fetchedAt,_that.minCents,_that.maxCents,_that.nStores,_that.rank,_that.category,_that.bucket,_that.pct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? gtin,  String description,  String? ncm, @JsonKey(name: 'priceCents')  int priceCents,  String? fetchedAt, @JsonKey(name: 'minCents')  int? minCents, @JsonKey(name: 'maxCents')  int? maxCents,  int nStores,  int rank,  String category,  String bucket,  int? pct)  $default,) {final _that = this;
switch (_that) {
case _CatalogItem():
return $default(_that.gtin,_that.description,_that.ncm,_that.priceCents,_that.fetchedAt,_that.minCents,_that.maxCents,_that.nStores,_that.rank,_that.category,_that.bucket,_that.pct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? gtin,  String description,  String? ncm, @JsonKey(name: 'priceCents')  int priceCents,  String? fetchedAt, @JsonKey(name: 'minCents')  int? minCents, @JsonKey(name: 'maxCents')  int? maxCents,  int nStores,  int rank,  String category,  String bucket,  int? pct)?  $default,) {final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
return $default(_that.gtin,_that.description,_that.ncm,_that.priceCents,_that.fetchedAt,_that.minCents,_that.maxCents,_that.nStores,_that.rank,_that.category,_that.bucket,_that.pct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogItem implements CatalogItem {
  const _CatalogItem({this.gtin, required this.description, this.ncm, @JsonKey(name: 'priceCents') this.priceCents = 0, this.fetchedAt, @JsonKey(name: 'minCents') this.minCents, @JsonKey(name: 'maxCents') this.maxCents, this.nStores = 0, this.rank = 0, this.category = 'outros', this.bucket = 'unico', this.pct});
  factory _CatalogItem.fromJson(Map<String, dynamic> json) => _$CatalogItemFromJson(json);

@override final  String? gtin;
@override final  String description;
@override final  String? ncm;
@override@JsonKey(name: 'priceCents') final  int priceCents;
@override final  String? fetchedAt;
@override@JsonKey(name: 'minCents') final  int? minCents;
@override@JsonKey(name: 'maxCents') final  int? maxCents;
@override@JsonKey() final  int nStores;
@override@JsonKey() final  int rank;
/// Server-computed via `classify()` (same categories as `Categoria`).
@override@JsonKey() final  String category;
/// `otimo` | `ok` | `caro` | `unico` — see [catalogBucketLabel].
@override@JsonKey() final  String bucket;
/// How far this price sits between the region's min and max, 0–100.
/// Null exactly when [bucket] is `unico`.
@override final  int? pct;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogItemCopyWith<_CatalogItem> get copyWith => __$CatalogItemCopyWithImpl<_CatalogItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogItem&&(identical(other.gtin, gtin) || other.gtin == gtin)&&(identical(other.description, description) || other.description == description)&&(identical(other.ncm, ncm) || other.ncm == ncm)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.minCents, minCents) || other.minCents == minCents)&&(identical(other.maxCents, maxCents) || other.maxCents == maxCents)&&(identical(other.nStores, nStores) || other.nStores == nStores)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.category, category) || other.category == category)&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.pct, pct) || other.pct == pct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gtin,description,ncm,priceCents,fetchedAt,minCents,maxCents,nStores,rank,category,bucket,pct);

@override
String toString() {
  return 'CatalogItem(gtin: $gtin, description: $description, ncm: $ncm, priceCents: $priceCents, fetchedAt: $fetchedAt, minCents: $minCents, maxCents: $maxCents, nStores: $nStores, rank: $rank, category: $category, bucket: $bucket, pct: $pct)';
}


}

/// @nodoc
abstract mixin class _$CatalogItemCopyWith<$Res> implements $CatalogItemCopyWith<$Res> {
  factory _$CatalogItemCopyWith(_CatalogItem value, $Res Function(_CatalogItem) _then) = __$CatalogItemCopyWithImpl;
@override @useResult
$Res call({
 String? gtin, String description, String? ncm,@JsonKey(name: 'priceCents') int priceCents, String? fetchedAt,@JsonKey(name: 'minCents') int? minCents,@JsonKey(name: 'maxCents') int? maxCents, int nStores, int rank, String category, String bucket, int? pct
});




}
/// @nodoc
class __$CatalogItemCopyWithImpl<$Res>
    implements _$CatalogItemCopyWith<$Res> {
  __$CatalogItemCopyWithImpl(this._self, this._then);

  final _CatalogItem _self;
  final $Res Function(_CatalogItem) _then;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gtin = freezed,Object? description = null,Object? ncm = freezed,Object? priceCents = null,Object? fetchedAt = freezed,Object? minCents = freezed,Object? maxCents = freezed,Object? nStores = null,Object? rank = null,Object? category = null,Object? bucket = null,Object? pct = freezed,}) {
  return _then(_CatalogItem(
gtin: freezed == gtin ? _self.gtin : gtin // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as String?,minCents: freezed == minCents ? _self.minCents : minCents // ignore: cast_nullable_to_non_nullable
as int?,maxCents: freezed == maxCents ? _self.maxCents : maxCents // ignore: cast_nullable_to_non_nullable
as int?,nStores: null == nStores ? _self.nStores : nStores // ignore: cast_nullable_to_non_nullable
as int,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,pct: freezed == pct ? _self.pct : pct // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CatalogResponse {

 String? get marketCodigo; List<CatalogItem> get items; Map<String, int> get categories;
/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogResponseCopyWith<CatalogResponse> get copyWith => _$CatalogResponseCopyWithImpl<CatalogResponse>(this as CatalogResponse, _$identity);

  /// Serializes this CatalogResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogResponse&&(identical(other.marketCodigo, marketCodigo) || other.marketCodigo == marketCodigo)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.categories, categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,marketCodigo,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'CatalogResponse(marketCodigo: $marketCodigo, items: $items, categories: $categories)';
}


}

/// @nodoc
abstract mixin class $CatalogResponseCopyWith<$Res>  {
  factory $CatalogResponseCopyWith(CatalogResponse value, $Res Function(CatalogResponse) _then) = _$CatalogResponseCopyWithImpl;
@useResult
$Res call({
 String? marketCodigo, List<CatalogItem> items, Map<String, int> categories
});




}
/// @nodoc
class _$CatalogResponseCopyWithImpl<$Res>
    implements $CatalogResponseCopyWith<$Res> {
  _$CatalogResponseCopyWithImpl(this._self, this._then);

  final CatalogResponse _self;
  final $Res Function(CatalogResponse) _then;

/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? marketCodigo = freezed,Object? items = null,Object? categories = null,}) {
  return _then(_self.copyWith(
marketCodigo: freezed == marketCodigo ? _self.marketCodigo : marketCodigo // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogItem>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogResponse].
extension CatalogResponsePatterns on CatalogResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogResponse value)  $default,){
final _that = this;
switch (_that) {
case _CatalogResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? marketCodigo,  List<CatalogItem> items,  Map<String, int> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
return $default(_that.marketCodigo,_that.items,_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? marketCodigo,  List<CatalogItem> items,  Map<String, int> categories)  $default,) {final _that = this;
switch (_that) {
case _CatalogResponse():
return $default(_that.marketCodigo,_that.items,_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? marketCodigo,  List<CatalogItem> items,  Map<String, int> categories)?  $default,) {final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
return $default(_that.marketCodigo,_that.items,_that.categories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogResponse implements CatalogResponse {
  const _CatalogResponse({this.marketCodigo, final  List<CatalogItem> items = const <CatalogItem>[], final  Map<String, int> categories = const <String, int>{}}): _items = items,_categories = categories;
  factory _CatalogResponse.fromJson(Map<String, dynamic> json) => _$CatalogResponseFromJson(json);

@override final  String? marketCodigo;
 final  List<CatalogItem> _items;
@override@JsonKey() List<CatalogItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  Map<String, int> _categories;
@override@JsonKey() Map<String, int> get categories {
  if (_categories is EqualUnmodifiableMapView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categories);
}


/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogResponseCopyWith<_CatalogResponse> get copyWith => __$CatalogResponseCopyWithImpl<_CatalogResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogResponse&&(identical(other.marketCodigo, marketCodigo) || other.marketCodigo == marketCodigo)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._categories, _categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,marketCodigo,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'CatalogResponse(marketCodigo: $marketCodigo, items: $items, categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$CatalogResponseCopyWith<$Res> implements $CatalogResponseCopyWith<$Res> {
  factory _$CatalogResponseCopyWith(_CatalogResponse value, $Res Function(_CatalogResponse) _then) = __$CatalogResponseCopyWithImpl;
@override @useResult
$Res call({
 String? marketCodigo, List<CatalogItem> items, Map<String, int> categories
});




}
/// @nodoc
class __$CatalogResponseCopyWithImpl<$Res>
    implements _$CatalogResponseCopyWith<$Res> {
  __$CatalogResponseCopyWithImpl(this._self, this._then);

  final _CatalogResponse _self;
  final $Res Function(_CatalogResponse) _then;

/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? marketCodigo = freezed,Object? items = null,Object? categories = null,}) {
  return _then(_CatalogResponse(
marketCodigo: freezed == marketCodigo ? _self.marketCodigo : marketCodigo // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogItem>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
