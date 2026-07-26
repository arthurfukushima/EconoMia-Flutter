// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogItem _$CatalogItemFromJson(Map<String, dynamic> json) => _CatalogItem(
  gtin: json['gtin'] as String?,
  description: json['description'] as String,
  ncm: json['ncm'] as String?,
  priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
  fetchedAt: json['fetchedAt'] as String?,
  minCents: (json['minCents'] as num?)?.toInt(),
  maxCents: (json['maxCents'] as num?)?.toInt(),
  nStores: (json['nStores'] as num?)?.toInt() ?? 0,
  rank: (json['rank'] as num?)?.toInt() ?? 0,
  category: json['category'] as String? ?? 'outros',
  bucket: json['bucket'] as String? ?? 'unico',
  pct: (json['pct'] as num?)?.toInt(),
);

Map<String, dynamic> _$CatalogItemToJson(_CatalogItem instance) =>
    <String, dynamic>{
      'gtin': instance.gtin,
      'description': instance.description,
      'ncm': instance.ncm,
      'priceCents': instance.priceCents,
      'fetchedAt': instance.fetchedAt,
      'minCents': instance.minCents,
      'maxCents': instance.maxCents,
      'nStores': instance.nStores,
      'rank': instance.rank,
      'category': instance.category,
      'bucket': instance.bucket,
      'pct': instance.pct,
    };

_CatalogResponse _$CatalogResponseFromJson(Map<String, dynamic> json) =>
    _CatalogResponse(
      marketCodigo: json['marketCodigo'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CatalogItem>[],
      categories:
          (json['categories'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
    );

Map<String, dynamic> _$CatalogResponseToJson(_CatalogResponse instance) =>
    <String, dynamic>{
      'marketCodigo': instance.marketCodigo,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'categories': instance.categories,
    };
