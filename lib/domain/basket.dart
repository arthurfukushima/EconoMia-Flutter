/// The whole receipt priced at one nearby store: totals, per-line deltas, and
/// what that store doesn't carry.
///
/// Pure arithmetic over items already carrying their `precos.stores[]` — the
/// second-pass counterpart to `savings.dart`'s cheapest-nearby report.
library;

import '../data/models/precos.dart';
import '../data/models/receipt.dart';

/// One nearby store, ranked by what buying the whole receipt there would save.
typedef StoreOption = ({
  String cod,
  String? name,
  String? bairro,
  double? km,
  int itemsCovered,
  int savedCents,
});

/// Every distinct store carried by any item's `precos.stores[]`, ranked by
/// savings (most first), then coverage, then proximity. `[]` for receipts
/// priced before this feature shipped (no `precos.stores`) — the caller hides
/// the picker in that case.
List<StoreOption> storeOptions(List<ReceiptItem> items) {
  final byCod = <String, StoreOption>{};
  for (final item in items) {
    final qty = item.qty > 0 ? item.qty : 1.0;
    for (final s in item.precos?.stores ?? const <Offer>[]) {
      final cod = s.cod;
      if (cod == null) continue;
      final saved = ((item.unitPriceCents - s.priceCents) * qty).round();
      final cur = byCod[cod];
      byCod[cod] = cur == null
          ? (cod: cod, name: s.store, bairro: s.bairro, km: s.km, itemsCovered: 1, savedCents: saved)
          : (
              cod: cod,
              name: cur.name,
              bairro: cur.bairro,
              km: cur.km,
              itemsCovered: cur.itemsCovered + 1,
              savedCents: cur.savedCents + saved,
            );
    }
  }

  final options = byCod.values.toList()
    ..sort((a, b) {
      final bySaved = b.savedCents.compareTo(a.savedCents);
      if (bySaved != 0) return bySaved;
      final byCoverage = b.itemsCovered.compareTo(a.itemsCovered);
      if (byCoverage != 0) return byCoverage;
      return (a.km ?? double.infinity).compareTo(b.km ?? double.infinity);
    });
  return options;
}

/// One line of the basket at that store: the offer there, or null if this
/// store doesn't carry it — never dropped, since the "não vendidos nesta
/// loja" section needs it.
typedef BasketLine = ({ReceiptItem item, Offer? offer, int lineDeltaCents});

typedef Basket = ({
  List<BasketLine> lines,
  int coveredCount,
  int itemCount,
  int storeTotalCents,
  int totalSavedCents,
});

Offer? _storeOffer(ReceiptItem item, String cod) {
  for (final s in item.precos?.stores ?? const <Offer>[]) {
    if (s.cod == cod) return s;
  }
  return null;
}

/// Prices the whole receipt at one store. [Basket.totalSavedCents] can go
/// negative — that store may be dearer overall than what was actually paid.
Basket basketForStore(List<ReceiptItem> items, String cod) {
  final lines = <BasketLine>[];
  var storeTotalCents = 0;
  var totalSavedCents = 0;
  var coveredCount = 0;

  for (final item in items) {
    final offer = _storeOffer(item, cod);
    if (offer == null) {
      lines.add((item: item, offer: null, lineDeltaCents: 0));
      continue;
    }
    final qty = item.qty > 0 ? item.qty : 1.0;
    final lineDeltaCents = ((item.unitPriceCents - offer.priceCents) * qty).round();
    storeTotalCents += (offer.priceCents * qty).round();
    totalSavedCents += lineDeltaCents;
    coveredCount++;
    lines.add((item: item, offer: offer, lineDeltaCents: lineDeltaCents));
  }

  return (
    lines: lines,
    coveredCount: coveredCount,
    itemCount: items.length,
    storeTotalCents: storeTotalCents,
    totalSavedCents: totalSavedCents,
  );
}
