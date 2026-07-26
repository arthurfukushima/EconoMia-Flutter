// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListItem {

 String get id;/// Exactly what the user typed, before the quantity prefix was lifted off.
 String get raw;/// The search term — [raw] minus its quantity prefix.
 String get name; double get qty;/// `un` | `kg` | `L`. Crossing the `kg` boundary changes the price-search
/// basis, so the item is re-priced when it does.
 String get unit; bool get checked;/// Cached `/api/precos` result. Null means never successfully priced — the
/// row says so rather than showing a zero.
 Precos? get precos;/// Which [ProductOption] the user picked out of a vague term's candidates.
/// Null = whatever the backend ranked first.
 String? get chosenKey;/// Epoch ms of the last **successful** lookup.
 int? get pricedAt;/// The CEP those prices were fetched for.
 String? get pricedCep;
/// Create a copy of ListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListItemCopyWith<ListItem> get copyWith => _$ListItemCopyWithImpl<ListItem>(this as ListItem, _$identity);

  /// Serializes this ListItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.raw, raw) || other.raw == raw)&&(identical(other.name, name) || other.name == name)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.precos, precos) || other.precos == precos)&&(identical(other.chosenKey, chosenKey) || other.chosenKey == chosenKey)&&(identical(other.pricedAt, pricedAt) || other.pricedAt == pricedAt)&&(identical(other.pricedCep, pricedCep) || other.pricedCep == pricedCep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,raw,name,qty,unit,checked,precos,chosenKey,pricedAt,pricedCep);

@override
String toString() {
  return 'ListItem(id: $id, raw: $raw, name: $name, qty: $qty, unit: $unit, checked: $checked, precos: $precos, chosenKey: $chosenKey, pricedAt: $pricedAt, pricedCep: $pricedCep)';
}


}

/// @nodoc
abstract mixin class $ListItemCopyWith<$Res>  {
  factory $ListItemCopyWith(ListItem value, $Res Function(ListItem) _then) = _$ListItemCopyWithImpl;
@useResult
$Res call({
 String id, String raw, String name, double qty, String unit, bool checked, Precos? precos, String? chosenKey, int? pricedAt, String? pricedCep
});


$PrecosCopyWith<$Res>? get precos;

}
/// @nodoc
class _$ListItemCopyWithImpl<$Res>
    implements $ListItemCopyWith<$Res> {
  _$ListItemCopyWithImpl(this._self, this._then);

  final ListItem _self;
  final $Res Function(ListItem) _then;

/// Create a copy of ListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? raw = null,Object? name = null,Object? qty = null,Object? unit = null,Object? checked = null,Object? precos = freezed,Object? chosenKey = freezed,Object? pricedAt = freezed,Object? pricedCep = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,precos: freezed == precos ? _self.precos : precos // ignore: cast_nullable_to_non_nullable
as Precos?,chosenKey: freezed == chosenKey ? _self.chosenKey : chosenKey // ignore: cast_nullable_to_non_nullable
as String?,pricedAt: freezed == pricedAt ? _self.pricedAt : pricedAt // ignore: cast_nullable_to_non_nullable
as int?,pricedCep: freezed == pricedCep ? _self.pricedCep : pricedCep // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ListItem
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


/// Adds pattern-matching-related methods to [ListItem].
extension ListItemPatterns on ListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListItem value)  $default,){
final _that = this;
switch (_that) {
case _ListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListItem value)?  $default,){
final _that = this;
switch (_that) {
case _ListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String raw,  String name,  double qty,  String unit,  bool checked,  Precos? precos,  String? chosenKey,  int? pricedAt,  String? pricedCep)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListItem() when $default != null:
return $default(_that.id,_that.raw,_that.name,_that.qty,_that.unit,_that.checked,_that.precos,_that.chosenKey,_that.pricedAt,_that.pricedCep);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String raw,  String name,  double qty,  String unit,  bool checked,  Precos? precos,  String? chosenKey,  int? pricedAt,  String? pricedCep)  $default,) {final _that = this;
switch (_that) {
case _ListItem():
return $default(_that.id,_that.raw,_that.name,_that.qty,_that.unit,_that.checked,_that.precos,_that.chosenKey,_that.pricedAt,_that.pricedCep);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String raw,  String name,  double qty,  String unit,  bool checked,  Precos? precos,  String? chosenKey,  int? pricedAt,  String? pricedCep)?  $default,) {final _that = this;
switch (_that) {
case _ListItem() when $default != null:
return $default(_that.id,_that.raw,_that.name,_that.qty,_that.unit,_that.checked,_that.precos,_that.chosenKey,_that.pricedAt,_that.pricedCep);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListItem implements ListItem {
  const _ListItem({required this.id, required this.raw, required this.name, this.qty = 1.0, this.unit = 'un', this.checked = false, this.precos, this.chosenKey, this.pricedAt, this.pricedCep});
  factory _ListItem.fromJson(Map<String, dynamic> json) => _$ListItemFromJson(json);

@override final  String id;
/// Exactly what the user typed, before the quantity prefix was lifted off.
@override final  String raw;
/// The search term — [raw] minus its quantity prefix.
@override final  String name;
@override@JsonKey() final  double qty;
/// `un` | `kg` | `L`. Crossing the `kg` boundary changes the price-search
/// basis, so the item is re-priced when it does.
@override@JsonKey() final  String unit;
@override@JsonKey() final  bool checked;
/// Cached `/api/precos` result. Null means never successfully priced — the
/// row says so rather than showing a zero.
@override final  Precos? precos;
/// Which [ProductOption] the user picked out of a vague term's candidates.
/// Null = whatever the backend ranked first.
@override final  String? chosenKey;
/// Epoch ms of the last **successful** lookup.
@override final  int? pricedAt;
/// The CEP those prices were fetched for.
@override final  String? pricedCep;

/// Create a copy of ListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListItemCopyWith<_ListItem> get copyWith => __$ListItemCopyWithImpl<_ListItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.raw, raw) || other.raw == raw)&&(identical(other.name, name) || other.name == name)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.precos, precos) || other.precos == precos)&&(identical(other.chosenKey, chosenKey) || other.chosenKey == chosenKey)&&(identical(other.pricedAt, pricedAt) || other.pricedAt == pricedAt)&&(identical(other.pricedCep, pricedCep) || other.pricedCep == pricedCep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,raw,name,qty,unit,checked,precos,chosenKey,pricedAt,pricedCep);

@override
String toString() {
  return 'ListItem(id: $id, raw: $raw, name: $name, qty: $qty, unit: $unit, checked: $checked, precos: $precos, chosenKey: $chosenKey, pricedAt: $pricedAt, pricedCep: $pricedCep)';
}


}

/// @nodoc
abstract mixin class _$ListItemCopyWith<$Res> implements $ListItemCopyWith<$Res> {
  factory _$ListItemCopyWith(_ListItem value, $Res Function(_ListItem) _then) = __$ListItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String raw, String name, double qty, String unit, bool checked, Precos? precos, String? chosenKey, int? pricedAt, String? pricedCep
});


@override $PrecosCopyWith<$Res>? get precos;

}
/// @nodoc
class __$ListItemCopyWithImpl<$Res>
    implements _$ListItemCopyWith<$Res> {
  __$ListItemCopyWithImpl(this._self, this._then);

  final _ListItem _self;
  final $Res Function(_ListItem) _then;

/// Create a copy of ListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? raw = null,Object? name = null,Object? qty = null,Object? unit = null,Object? checked = null,Object? precos = freezed,Object? chosenKey = freezed,Object? pricedAt = freezed,Object? pricedCep = freezed,}) {
  return _then(_ListItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,precos: freezed == precos ? _self.precos : precos // ignore: cast_nullable_to_non_nullable
as Precos?,chosenKey: freezed == chosenKey ? _self.chosenKey : chosenKey // ignore: cast_nullable_to_non_nullable
as String?,pricedAt: freezed == pricedAt ? _self.pricedAt : pricedAt // ignore: cast_nullable_to_non_nullable
as int?,pricedCep: freezed == pricedCep ? _self.pricedCep : pricedCep // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ListItem
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

// dart format on
