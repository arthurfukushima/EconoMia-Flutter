import 'package:freezed_annotation/freezed_annotation.dart';

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
  const factory ListItem({
    required String id,

    /// Exactly what the user typed, before the quantity prefix was lifted off.
    required String raw,

    /// The search term — [raw] minus its quantity prefix.
    required String name,
    @Default(1.0) double qty,

    /// `un` | `kg` | `L`. Crossing the `kg` boundary changes the price-search
    /// basis, so the item is re-priced when it does.
    @Default('un') String unit,
    @Default(false) bool checked,

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
}
