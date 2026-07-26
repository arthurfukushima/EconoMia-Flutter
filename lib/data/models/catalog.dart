import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog.freezed.dart';
part 'catalog.g.dart';

/// How cheap this item's cached price is against the same product at every
/// other market nearby (already computed server-side, `api/lib/catalog.js` +
/// `src/lib/catalogScore.js`'s bucketing) — `otimo` / `ok` / `caro`, or
/// `unico` when there's nothing nearby to compare against (fewer than 2
/// markets stocking it).
const catalogBucketLabel = <String, String>{
  'otimo': 'Ótimo preço',
  'ok': 'Preço razoável',
  'caro': 'Tem mais barato perto',
  'unico': 'Preço único encontrado',
};

/// One product cached for a market, `/api/catalog`'s browse item.
@freezed
abstract class CatalogItem with _$CatalogItem {
  const factory CatalogItem({
    String? gtin,
    required String description,
    String? ncm,
    @JsonKey(name: 'priceCents') @Default(0) int priceCents,
    String? fetchedAt,
    @JsonKey(name: 'minCents') int? minCents,
    @JsonKey(name: 'maxCents') int? maxCents,
    @Default(0) int nStores,
    @Default(0) int rank,

    /// Server-computed via `classify()` (same categories as `Categoria`).
    @Default('outros') String category,

    /// `otimo` | `ok` | `caro` | `unico` — see [catalogBucketLabel].
    @Default('unico') String bucket,

    /// How far this price sits between the region's min and max, 0–100.
    /// Null exactly when [bucket] is `unico`.
    int? pct,
  }) = _CatalogItem;

  factory CatalogItem.fromJson(Map<String, dynamic> json) => _$CatalogItemFromJson(json);
}

/// `/api/catalog?market_codigo=X[&category=carnes]` — everything cached for
/// one market, each item scored against the same product at every other
/// nearby market. [categories] is the unfiltered item count per category, so
/// a category filter row can be drawn even while another category is active.
@freezed
abstract class CatalogResponse with _$CatalogResponse {
  const factory CatalogResponse({
    String? marketCodigo,
    @Default(<CatalogItem>[]) List<CatalogItem> items,
    @Default(<String, int>{}) Map<String, int> categories,
  }) = _CatalogResponse;

  factory CatalogResponse.fromJson(Map<String, dynamic> json) => _$CatalogResponseFromJson(json);
}
