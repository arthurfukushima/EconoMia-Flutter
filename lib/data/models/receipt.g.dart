// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReceiptHeader _$ReceiptHeaderFromJson(Map<String, dynamic> json) =>
    _ReceiptHeader(
      cnpj: json['cnpj'] as String?,
      storeName: json['storeName'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      purchasedAt: json['purchasedAt'] as String?,
      totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReceiptHeaderToJson(_ReceiptHeader instance) =>
    <String, dynamic>{
      'cnpj': instance.cnpj,
      'storeName': instance.storeName,
      'city': instance.city,
      'address': instance.address,
      'purchasedAt': instance.purchasedAt,
      'totalCents': instance.totalCents,
    };

_ReceiptItem _$ReceiptItemFromJson(Map<String, dynamic> json) => _ReceiptItem(
  description: json['description'] as String,
  gtin: json['gtin'] as String?,
  qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
  unit: json['unit'] as String?,
  unitPriceCents: (json['unitPriceCents'] as num?)?.toInt() ?? 0,
  lineTotalCents: (json['lineTotalCents'] as num?)?.toInt() ?? 0,
  precos: json['precos'] == null
      ? null
      : Precos.fromJson(json['precos'] as Map<String, dynamic>),
  ncm: json['ncm'] as String?,
);

Map<String, dynamic> _$ReceiptItemToJson(_ReceiptItem instance) =>
    <String, dynamic>{
      'description': instance.description,
      'gtin': instance.gtin,
      'qty': instance.qty,
      'unit': instance.unit,
      'unitPriceCents': instance.unitPriceCents,
      'lineTotalCents': instance.lineTotalCents,
      'precos': instance.precos?.toJson(),
      'ncm': instance.ncm,
    };

_Receipt _$ReceiptFromJson(Map<String, dynamic> json) => _Receipt(
  accessKey: json['accessKey'] as String,
  header: json['header'] == null
      ? const ReceiptHeader()
      : ReceiptHeader.fromJson(json['header'] as Map<String, dynamic>),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ReceiptItem>[],
  createdAt: (json['createdAt'] as num?)?.toInt(),
  enrichedAt: (json['enrichedAt'] as num?)?.toInt(),
  locationCep: json['locationCep'] as String?,
);

Map<String, dynamic> _$ReceiptToJson(_Receipt instance) => <String, dynamic>{
  'accessKey': instance.accessKey,
  'header': instance.header.toJson(),
  'items': instance.items.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt,
  'enrichedAt': instance.enrichedAt,
  'locationCep': instance.locationCep,
};
