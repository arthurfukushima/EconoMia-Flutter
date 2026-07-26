// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'precos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Offer _$OfferFromJson(Map<String, dynamic> json) => _Offer(
  priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
  store: json['store'] as String?,
  bairro: json['bairro'] as String?,
  addr: json['addr'] as String?,
  cod: _codFromJson(json['cod']),
  km: (json['km'] as num?)?.toDouble(),
  datahora: json['datahora'] as String?,
);

Map<String, dynamic> _$OfferToJson(_Offer instance) => <String, dynamic>{
  'priceCents': instance.priceCents,
  'store': instance.store,
  'bairro': instance.bairro,
  'addr': instance.addr,
  'cod': instance.cod,
  'km': instance.km,
  'datahora': instance.datahora,
};

_PriceRange _$PriceRangeFromJson(Map<String, dynamic> json) => _PriceRange(
  minCents: (json['minCents'] as num?)?.toInt() ?? 0,
  maxCents: (json['maxCents'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PriceRangeToJson(_PriceRange instance) =>
    <String, dynamic>{
      'minCents': instance.minCents,
      'maxCents': instance.maxCents,
    };

_ProductOption _$ProductOptionFromJson(Map<String, dynamic> json) =>
    _ProductOption(
      key: json['key'] as String,
      gtin: json['gtin'] as String?,
      name: json['name'] as String?,
      cheapest: json['cheapest'] == null
          ? null
          : Offer.fromJson(json['cheapest'] as Map<String, dynamic>),
      stores:
          (json['stores'] as List<dynamic>?)
              ?.map((e) => Offer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Offer>[],
      nStores: (json['nStores'] as num?)?.toInt() ?? 0,
      nOffers: (json['nOffers'] as num?)?.toInt() ?? 0,
      ncm: json['ncm'] as String?,
      tier: (json['tier'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$ProductOptionToJson(_ProductOption instance) =>
    <String, dynamic>{
      'key': instance.key,
      'gtin': instance.gtin,
      'name': instance.name,
      'cheapest': instance.cheapest?.toJson(),
      'stores': instance.stores.map((e) => e.toJson()).toList(),
      'nStores': instance.nStores,
      'nOffers': instance.nOffers,
      'ncm': instance.ncm,
      'tier': instance.tier,
    };

_Precos _$PrecosFromJson(Map<String, dynamic> json) => _Precos(
  gtin: json['gtin'] as String?,
  basis: json['basis'] as String? ?? 'desc',
  confidence: json['confidence'] as String? ?? 'approx',
  cheapest: json['cheapest'] == null
      ? null
      : Offer.fromJson(json['cheapest'] as Map<String, dynamic>),
  stores:
      (json['stores'] as List<dynamic>?)
          ?.map((e) => Offer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Offer>[],
  range: json['range'] == null
      ? null
      : PriceRange.fromJson(json['range'] as Map<String, dynamic>),
  nOffers: (json['nOffers'] as num?)?.toInt() ?? 0,
  nStores: (json['nStores'] as num?)?.toInt() ?? 0,
  name: json['name'] as String?,
  ncm: json['ncm'] as String?,
  options:
      (json['options'] as List<dynamic>?)
          ?.map((e) => ProductOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProductOption>[],
);

Map<String, dynamic> _$PrecosToJson(_Precos instance) => <String, dynamic>{
  'gtin': instance.gtin,
  'basis': instance.basis,
  'confidence': instance.confidence,
  'cheapest': instance.cheapest?.toJson(),
  'stores': instance.stores.map((e) => e.toJson()).toList(),
  'range': instance.range?.toJson(),
  'nOffers': instance.nOffers,
  'nStores': instance.nStores,
  'name': instance.name,
  'ncm': instance.ncm,
  'options': instance.options.map((e) => e.toJson()).toList(),
};

_PriceObservation _$PriceObservationFromJson(Map<String, dynamic> json) =>
    _PriceObservation(
      cod: json['cod'] as String,
      store: json['store'] as String?,
      category:
          $enumDecodeNullable(
            _$CategoriaEnumMap,
            json['category'],
            unknownValue: Categoria.outros,
          ) ??
          Categoria.outros,
      gtin: json['gtin'] as String?,
      priceCents: (json['priceCents'] as num).toInt(),
      datahora: json['datahora'] as String,
    );

Map<String, dynamic> _$PriceObservationToJson(_PriceObservation instance) =>
    <String, dynamic>{
      'cod': instance.cod,
      'store': instance.store,
      'category': _$CategoriaEnumMap[instance.category]!,
      'gtin': instance.gtin,
      'priceCents': instance.priceCents,
      'datahora': instance.datahora,
    };

const _$CategoriaEnumMap = {
  Categoria.frutas: 'frutas',
  Categoria.verduras: 'verduras',
  Categoria.carnes: 'carnes',
  Categoria.laticinios: 'laticinios',
  Categoria.padaria: 'padaria',
  Categoria.bebidas: 'bebidas',
  Categoria.doces: 'doces',
  Categoria.limpeza: 'limpeza',
  Categoria.outros: 'outros',
};
