// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListItem _$ListItemFromJson(Map<String, dynamic> json) => _ListItem(
  id: json['id'] as String,
  raw: json['raw'] as String,
  name: json['name'] as String,
  qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
  unit: json['unit'] as String? ?? 'un',
  checked: json['checked'] as bool? ?? false,
  sizeValue: (json['sizeValue'] as num?)?.toDouble(),
  sizeUnit: json['sizeUnit'] as String?,
  parseConf: json['parseConf'] as String? ?? 'high',
  note: json['note'] as String?,
  reconciled: json['reconciled'] as bool? ?? false,
  precos: json['precos'] == null
      ? null
      : Precos.fromJson(json['precos'] as Map<String, dynamic>),
  chosenKey: json['chosenKey'] as String?,
  pricedAt: (json['pricedAt'] as num?)?.toInt(),
  pricedCep: json['pricedCep'] as String?,
);

Map<String, dynamic> _$ListItemToJson(_ListItem instance) => <String, dynamic>{
  'id': instance.id,
  'raw': instance.raw,
  'name': instance.name,
  'qty': instance.qty,
  'unit': instance.unit,
  'checked': instance.checked,
  'sizeValue': instance.sizeValue,
  'sizeUnit': instance.sizeUnit,
  'parseConf': instance.parseConf,
  'note': instance.note,
  'reconciled': instance.reconciled,
  'precos': instance.precos?.toJson(),
  'chosenKey': instance.chosenKey,
  'pricedAt': instance.pricedAt,
  'pricedCep': instance.pricedCep,
};
