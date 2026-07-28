// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NutrientValue {

 String get label; String get unit; double get value;
/// Create a copy of NutrientValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NutrientValueCopyWith<NutrientValue> get copyWith => _$NutrientValueCopyWithImpl<NutrientValue>(this as NutrientValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NutrientValue&&(identical(other.label, label) || other.label == label)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,label,unit,value);

@override
String toString() {
  return 'NutrientValue(label: $label, unit: $unit, value: $value)';
}


}

/// @nodoc
abstract mixin class $NutrientValueCopyWith<$Res>  {
  factory $NutrientValueCopyWith(NutrientValue value, $Res Function(NutrientValue) _then) = _$NutrientValueCopyWithImpl;
@useResult
$Res call({
 String label, String unit, double value
});




}
/// @nodoc
class _$NutrientValueCopyWithImpl<$Res>
    implements $NutrientValueCopyWith<$Res> {
  _$NutrientValueCopyWithImpl(this._self, this._then);

  final NutrientValue _self;
  final $Res Function(NutrientValue) _then;

/// Create a copy of NutrientValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? unit = null,Object? value = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NutrientValue].
extension NutrientValuePatterns on NutrientValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NutrientValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NutrientValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NutrientValue value)  $default,){
final _that = this;
switch (_that) {
case _NutrientValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NutrientValue value)?  $default,){
final _that = this;
switch (_that) {
case _NutrientValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String unit,  double value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NutrientValue() when $default != null:
return $default(_that.label,_that.unit,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String unit,  double value)  $default,) {final _that = this;
switch (_that) {
case _NutrientValue():
return $default(_that.label,_that.unit,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String unit,  double value)?  $default,) {final _that = this;
switch (_that) {
case _NutrientValue() when $default != null:
return $default(_that.label,_that.unit,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _NutrientValue implements NutrientValue {
  const _NutrientValue({required this.label, required this.unit, required this.value});
  

@override final  String label;
@override final  String unit;
@override final  double value;

/// Create a copy of NutrientValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NutrientValueCopyWith<_NutrientValue> get copyWith => __$NutrientValueCopyWithImpl<_NutrientValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NutrientValue&&(identical(other.label, label) || other.label == label)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,label,unit,value);

@override
String toString() {
  return 'NutrientValue(label: $label, unit: $unit, value: $value)';
}


}

/// @nodoc
abstract mixin class _$NutrientValueCopyWith<$Res> implements $NutrientValueCopyWith<$Res> {
  factory _$NutrientValueCopyWith(_NutrientValue value, $Res Function(_NutrientValue) _then) = __$NutrientValueCopyWithImpl;
@override @useResult
$Res call({
 String label, String unit, double value
});




}
/// @nodoc
class __$NutrientValueCopyWithImpl<$Res>
    implements _$NutrientValueCopyWith<$Res> {
  __$NutrientValueCopyWithImpl(this._self, this._then);

  final _NutrientValue _self;
  final $Res Function(_NutrientValue) _then;

/// Create a copy of NutrientValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? unit = null,Object? value = null,}) {
  return _then(_NutrientValue(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$Nutrition {

 String get name; String get brands; String get quantity; String get ingredients;/// `a`–`e`, lowercase, or `''` when Open Food Facts has none on file.
 String get nutriscore;/// `1`–`4` (unprocessed → ultra-processed), or null when absent.
 int? get nova; List<NutrientValue> get nutrients;
/// Create a copy of Nutrition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NutritionCopyWith<Nutrition> get copyWith => _$NutritionCopyWithImpl<Nutrition>(this as Nutrition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nutrition&&(identical(other.name, name) || other.name == name)&&(identical(other.brands, brands) || other.brands == brands)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.nutriscore, nutriscore) || other.nutriscore == nutriscore)&&(identical(other.nova, nova) || other.nova == nova)&&const DeepCollectionEquality().equals(other.nutrients, nutrients));
}


@override
int get hashCode => Object.hash(runtimeType,name,brands,quantity,ingredients,nutriscore,nova,const DeepCollectionEquality().hash(nutrients));

@override
String toString() {
  return 'Nutrition(name: $name, brands: $brands, quantity: $quantity, ingredients: $ingredients, nutriscore: $nutriscore, nova: $nova, nutrients: $nutrients)';
}


}

/// @nodoc
abstract mixin class $NutritionCopyWith<$Res>  {
  factory $NutritionCopyWith(Nutrition value, $Res Function(Nutrition) _then) = _$NutritionCopyWithImpl;
@useResult
$Res call({
 String name, String brands, String quantity, String ingredients, String nutriscore, int? nova, List<NutrientValue> nutrients
});




}
/// @nodoc
class _$NutritionCopyWithImpl<$Res>
    implements $NutritionCopyWith<$Res> {
  _$NutritionCopyWithImpl(this._self, this._then);

  final Nutrition _self;
  final $Res Function(Nutrition) _then;

/// Create a copy of Nutrition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? brands = null,Object? quantity = null,Object? ingredients = null,Object? nutriscore = null,Object? nova = freezed,Object? nutrients = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brands: null == brands ? _self.brands : brands // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as String,nutriscore: null == nutriscore ? _self.nutriscore : nutriscore // ignore: cast_nullable_to_non_nullable
as String,nova: freezed == nova ? _self.nova : nova // ignore: cast_nullable_to_non_nullable
as int?,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as List<NutrientValue>,
  ));
}

}


/// Adds pattern-matching-related methods to [Nutrition].
extension NutritionPatterns on Nutrition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Nutrition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Nutrition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Nutrition value)  $default,){
final _that = this;
switch (_that) {
case _Nutrition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Nutrition value)?  $default,){
final _that = this;
switch (_that) {
case _Nutrition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String brands,  String quantity,  String ingredients,  String nutriscore,  int? nova,  List<NutrientValue> nutrients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Nutrition() when $default != null:
return $default(_that.name,_that.brands,_that.quantity,_that.ingredients,_that.nutriscore,_that.nova,_that.nutrients);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String brands,  String quantity,  String ingredients,  String nutriscore,  int? nova,  List<NutrientValue> nutrients)  $default,) {final _that = this;
switch (_that) {
case _Nutrition():
return $default(_that.name,_that.brands,_that.quantity,_that.ingredients,_that.nutriscore,_that.nova,_that.nutrients);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String brands,  String quantity,  String ingredients,  String nutriscore,  int? nova,  List<NutrientValue> nutrients)?  $default,) {final _that = this;
switch (_that) {
case _Nutrition() when $default != null:
return $default(_that.name,_that.brands,_that.quantity,_that.ingredients,_that.nutriscore,_that.nova,_that.nutrients);case _:
  return null;

}
}

}

/// @nodoc


class _Nutrition implements Nutrition {
  const _Nutrition({this.name = '', this.brands = '', this.quantity = '', this.ingredients = '', this.nutriscore = '', this.nova, final  List<NutrientValue> nutrients = const <NutrientValue>[]}): _nutrients = nutrients;
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String brands;
@override@JsonKey() final  String quantity;
@override@JsonKey() final  String ingredients;
/// `a`–`e`, lowercase, or `''` when Open Food Facts has none on file.
@override@JsonKey() final  String nutriscore;
/// `1`–`4` (unprocessed → ultra-processed), or null when absent.
@override final  int? nova;
 final  List<NutrientValue> _nutrients;
@override@JsonKey() List<NutrientValue> get nutrients {
  if (_nutrients is EqualUnmodifiableListView) return _nutrients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nutrients);
}


/// Create a copy of Nutrition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NutritionCopyWith<_Nutrition> get copyWith => __$NutritionCopyWithImpl<_Nutrition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Nutrition&&(identical(other.name, name) || other.name == name)&&(identical(other.brands, brands) || other.brands == brands)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.nutriscore, nutriscore) || other.nutriscore == nutriscore)&&(identical(other.nova, nova) || other.nova == nova)&&const DeepCollectionEquality().equals(other._nutrients, _nutrients));
}


@override
int get hashCode => Object.hash(runtimeType,name,brands,quantity,ingredients,nutriscore,nova,const DeepCollectionEquality().hash(_nutrients));

@override
String toString() {
  return 'Nutrition(name: $name, brands: $brands, quantity: $quantity, ingredients: $ingredients, nutriscore: $nutriscore, nova: $nova, nutrients: $nutrients)';
}


}

/// @nodoc
abstract mixin class _$NutritionCopyWith<$Res> implements $NutritionCopyWith<$Res> {
  factory _$NutritionCopyWith(_Nutrition value, $Res Function(_Nutrition) _then) = __$NutritionCopyWithImpl;
@override @useResult
$Res call({
 String name, String brands, String quantity, String ingredients, String nutriscore, int? nova, List<NutrientValue> nutrients
});




}
/// @nodoc
class __$NutritionCopyWithImpl<$Res>
    implements _$NutritionCopyWith<$Res> {
  __$NutritionCopyWithImpl(this._self, this._then);

  final _Nutrition _self;
  final $Res Function(_Nutrition) _then;

/// Create a copy of Nutrition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? brands = null,Object? quantity = null,Object? ingredients = null,Object? nutriscore = null,Object? nova = freezed,Object? nutrients = null,}) {
  return _then(_Nutrition(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brands: null == brands ? _self.brands : brands // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as String,nutriscore: null == nutriscore ? _self.nutriscore : nutriscore // ignore: cast_nullable_to_non_nullable
as String,nova: freezed == nova ? _self.nova : nova // ignore: cast_nullable_to_non_nullable
as int?,nutrients: null == nutrients ? _self._nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as List<NutrientValue>,
  ));
}


}

// dart format on
