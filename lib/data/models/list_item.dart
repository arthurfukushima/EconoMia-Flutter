import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/measure.dart';
import 'precos.dart';

part 'list_item.freezed.dart';
part 'list_item.g.dart';

/// One line of the shopping list, plus its cached pricing.
///
/// Stored as JSON in `economia.shoppingList` — a handful of lines the user
/// typed, not a document collection, so it stays a preference scalar rather
/// than joining receipts in sembast.
///
/// [pricedAt] and [pricedCep] together are the cache key: a price is reused
/// until it is 12h old or the user's CEP moved (see `domain/lista.dart`'s
/// `isStale`). They are stamped **only** on a successful lookup, which is what
/// makes a failed refresh keep the old prices *and* stay due for a retry.
@freezed
abstract class ListItem with _$ListItem {
  const ListItem._();

  const factory ListItem({
    required String id,

    /// Exactly what the user typed, before the quantity prefix was lifted off.
    required String raw,

    /// The search term — [raw] minus its quantity, expanded and singularised.
    required String name,

    /// **How much to buy.** The only number that multiplies a price.
    @Default(1.0) double qty,

    /// `un` | `kg` | `L`. Crossing the `kg` boundary changes the price-search
    /// basis, so the item is re-priced when it does.
    @Default('un') String unit,
    @Default(false) bool checked,

    /// **How big one package is** — `2` of [sizeUnit] `L`, `12` of `un`.
    ///
    /// Never multiplies anything. It steers *which* of a search's candidate
    /// products the line is priced as: someone who wrote "Refrigerante 2l"
    /// wants the 2L bottle's price, not the can's. Null when the line said
    /// nothing about packaging.
    ///
    /// Split into two scalars rather than stored as a `Measure` record because
    /// this is a persisted JSON model and a nullable record would need a
    /// converter for no gain.
    double? sizeValue,
    String? sizeUnit,

    /// `high` | `medium` | `low` — see `ParseConf`. Anything but `high` puts a
    /// correction affordance on the row, and `low` is what
    /// `lista_reconcile.dart` is allowed to overrule.
    @Default('high') String parseConf,

    /// The shopper's own aside — "(o do desconto)", "R$ 20". Shown on the row,
    /// never sent to the price search.
    String? note,

    /// Whether the reconciler has already had its one look at this item's
    /// prices. Bounds the re-price it can trigger to exactly one.
    @Default(false) bool reconciled,

    /// Cached `/api/precos` result. Null means never successfully priced — the
    /// row says so rather than showing a zero.
    Precos? precos,

    /// Which [ProductOption] the user picked out of a vague term's candidates.
    /// Null = whatever the backend ranked first.
    String? chosenKey,

    /// Epoch ms of the last **successful** lookup.
    int? pricedAt,

    /// The CEP those prices were fetched for.
    String? pricedCep,
  }) = _ListItem;

  factory ListItem.fromJson(Map<String, dynamic> json) =>
      _$ListItemFromJson(json);

  /// [sizeValue]/[sizeUnit] back as the [Measure] the rest of the app works in.
  Measure? get size =>
      sizeValue == null || sizeUnit == null ? null : (value: sizeValue!, unit: sizeUnit!);
}
