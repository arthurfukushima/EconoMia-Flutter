// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShoppingList _$ShoppingListFromJson(Map<String, dynamic> json) =>
    _ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ShoppingListToJson(_ShoppingList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt,
    };
