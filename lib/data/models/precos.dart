import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/categoria.dart';

part 'precos.freezed.dart';
part 'precos.g.dart';

/// `cod` is passed through untouched from Menor Preço, which has typed it as
/// both a number and a string. It is only ever compared and used as a map key,
/// so it is normalised to `String` here at the parse boundary — the one place
/// that can guarantee two equal store codes compare equal.
String? _codFromJson(Object? value) => value?.toString();

/// One price at one store.
///
/// The same shape serves three jobs, which is why so much is optional:
/// - `precos.cheapest` — **no [cod]**, because the backend omits it there.
///   Nothing may key off `cheapest.cod`.
/// - `precos.stores[]` — the best price per nearby store, [cod] present.
/// - the store picker's name search, which returns establishments with no price
///   at all, so [priceCents] is `0` there and means "unknown", not "free".
@freezed
abstract class Offer with _$Offer {
  const factory Offer({
    @Default(0) int priceCents,
    String? store,
    String? bairro,

    /// "RUA TAPUIAS, 845, VILA CASONI, LONDRINA - PR" — enough for a maps search.
    String? addr,
    @JsonKey(fromJson: _codFromJson) String? cod,

    /// Distance in km. Null when upstream gave no usable distance.
    double? km,

    /// When the price was observed, ISO-8601. Kept as the raw string the API
    /// sends: weekday-trend detection is the only consumer and it parses this
    /// itself, so a malformed date stays one dropped observation rather than a
    /// failure to decode the whole response.
    String? datahora,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
}

/// The local price spread for one product, cheapest to dearest.
@freezed
abstract class PriceRange with _$PriceRange {
  const factory PriceRange({
    @Default(0) int minCents,
    @Default(0) int maxCents,
  }) = _PriceRange;

  factory PriceRange.fromJson(Map<String, dynamic> json) =>
      _$PriceRangeFromJson(json);
}

/// One candidate product behind a vague search term.
///
/// "Carne" or "Toddy" matches several real products; the backend groups the
/// candidates so the user picks the right one instead of getting the blind
/// cheapest. Only sent when there is a real choice to make.
@freezed
abstract class ProductOption with _$ProductOption {
  const factory ProductOption({
    required String key,
    String? gtin,
    String? name,
    Offer? cheapest,
    @Default(<Offer>[]) List<Offer> stores,
    @Default(0) int nStores,
    @Default(0) int nOffers,
    String? ncm,
  }) = _ProductOption;

  factory ProductOption.fromJson(Map<String, dynamic> json) =>
      _$ProductOptionFromJson(json);
}

/// `/api/precos` — what one item costs nearby.
///
/// Covers both response shapes: the GTIN path (a scanned barcode, identity is
/// certain) and the description path (a receipt line, matched on tokens).
@freezed
abstract class Precos with _$Precos {
  const factory Precos({
    /// The recovered barcode, or null when the match was by description.
    String? gtin,

    /// `gtin` | `desc` — how the match was made.
    ///
    /// Defaulted rather than required, and defaulted to the *cautious* pair
    /// with [confidence]: a response missing these must never read as an exact
    /// barcode match, because that is what suppresses the "aprox." flag.
    @Default('desc') String basis,

    /// `high` | `approx`.
    @Default('approx') String confidence,

    /// The cheapest nearby offer. **Has no `cod`** — see [Offer].
    Offer? cheapest,

    /// Best price per nearby store, nearest-first, so a whole basket can be
    /// priced at any one store without re-querying.
    @Default(<Offer>[]) List<Offer> stores,
    PriceRange? range,
    @Default(0) int nOffers,
    @Default(0) int nStores,

    /// The modal description across matched offers — the least surprising label
    /// for the product, since every store names it differently.
    String? name,

    /// The fiscal NCM most matched offers agree on. Stamped onto the receipt
    /// item so classification stops guessing from the description.
    String? ncm,
    @Default(<ProductOption>[]) List<ProductOption> options,
  }) = _Precos;

  factory Precos.fromJson(Map<String, dynamic> json) => _$PrecosFromJson(json);
}

/// A dated price sighting, mined from [Precos.stores] during enrichment and
/// accumulated in the `offers` store for weekday-trend detection.
@freezed
abstract class PriceObservation with _$PriceObservation {
  const PriceObservation._();

  const factory PriceObservation({
    required String cod,
    String? store,
    @JsonKey(unknownEnumValue: Categoria.outros)
    @Default(Categoria.outros) Categoria category,
    String? gtin,
    required int priceCents,
    required String datahora,
  }) = _PriceObservation;

  factory PriceObservation.fromJson(Map<String, dynamic> json) =>
      _$PriceObservationFromJson(json);

  /// The record key in the `offers` store. Synthetic and content-derived, so
  /// re-scanning the same receipt overwrites its observations instead of
  /// duplicating them and doubling that day's weight in a trend.
  String get key => '$cod|${gtin ?? category.name}|$datahora|$priceCents';
}
