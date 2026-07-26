/// Projections over the shopping list: which product each line is priced as,
/// which markets carry the list, and what the basket costs at one of them.
///
/// Pure arithmetic over items already carrying their cached `precos` — no I/O,
/// so a market ranking is tested by calling it.
library;

import '../data/models/list_item.dart';
import '../data/models/precos.dart';
import 'stores.dart';

/// How long a cached list price is trusted.
///
/// This view is opened at notepad frequency and Menor Preço rate-limits (real
/// 429s), so re-pricing on every open is not an option. Twelve hours is a whole
/// shopping day: prices are re-checked before the next trip, never during one.
///
/// ponytail: 12h guess, tune against Menor Preço freshness/429s.
const listPriceTtl = Duration(hours: 12);

/// Whether [item] needs a fresh price for a user now at [cep].
///
/// Three ways to be stale, and the first two matter more than the clock:
/// - never priced (or a lookup that failed, which never stamped `pricedAt`),
/// - priced for a CEP the user has since left — those prices are about another
///   city, which is worse than no prices at all,
/// - older than [listPriceTtl].
bool isStale(ListItem item, String? cep, {DateTime? now}) =>
    item.precos == null ||
    item.pricedCep != cep ||
    (now ?? DateTime.now()).millisecondsSinceEpoch - (item.pricedAt ?? 0) >
        listPriceTtl.inMilliseconds;

/// The product [item] is currently priced as: the user's pick, else the
/// most-common match (`options.first`).
///
/// Falls back to the collapsed top-level result for items cached before
/// `options` existed — a real state on disk, not a hypothetical one. Null when
/// there is no usable price at all.
ProductOption? activeOption(ListItem item) {
  final precos = item.precos;
  if (precos == null) return null;

  final options = precos.options;
  if (options.isNotEmpty) {
    for (final o in options) {
      if (o.key == item.chosenKey) return o;
    }
    return options.first;
  }

  if (precos.cheapest == null) return null;
  return ProductOption(
    key: '',
    name: precos.name,
    cheapest: precos.cheapest,
    stores: precos.stores,
    nStores: precos.nStores,
    ncm: precos.ncm,
  );
}

/// What [qty] of something costing [priceCents] each comes to.
///
/// Rounded once, at the end: a fractional weight (0,42 kg of pão) times a unit
/// price is not a whole number of cents, and rounding per-line keeps a basket
/// total from drifting by a centavo per item.
int lineCents(int priceCents, double qty) => (priceCents * qty).round();

/// Every market carrying at least one listed item, nearest-first — the store
/// picker's options without an extra fetch, since each item's active product
/// already lists its price per store.
List<Offer> listStores(List<ListItem> items) => mergeStores(const [], [
      for (final item in items) ...?activeOption(item)?.stores,
    ]);

/// One market's standing against the whole list.
typedef MarketOption = ({
  String cod,
  String? store,
  String? bairro,
  double? km,
  int count,
  int totalCents,
});

/// Markets ranked by how many listed items they carry, then by the cheapest
/// partial basket.
///
/// Coverage first, price second, deliberately: the trip you want is the one that
/// gets everything, and a market that stocks two of your ten items would
/// otherwise "win" on a total that isn't your shopping. [MarketOption.totalCents]
/// is that partial basket and the UI labels it as such.
List<MarketOption> marketRanking(List<ListItem> items) {
  final byCod = <String, MarketOption>{};
  for (final item in items) {
    for (final s in activeOption(item)?.stores ?? const <Offer>[]) {
      final cod = s.cod;
      if (cod == null) continue;
      final line = lineCents(s.priceCents, item.qty);
      final cur = byCod[cod];
      byCod[cod] = cur == null
          ? (cod: cod, store: s.store, bairro: s.bairro, km: s.km, count: 1, totalCents: line)
          : (
              cod: cod,
              store: cur.store,
              bairro: cur.bairro,
              km: cur.km,
              count: cur.count + 1,
              totalCents: cur.totalCents + line,
            );
    }
  }

  final ranked = byCod.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.totalCents.compareTo(b.totalCents);
    });
  return ranked;
}

/// This item's price at one market, or null when that market doesn't carry it.
Offer? offerAt(ListItem item, String cod) {
  for (final s in activeOption(item)?.stores ?? const <Offer>[]) {
    if (s.cod == cod) return s;
  }
  return null;
}

/// The whole list priced at one market. [carried] is out of `items.length` and
/// the UI shows both — a total over 6 of 10 items is not a shopping total.
typedef ListBasket = ({int carried, int totalCents});

ListBasket basketAt(List<ListItem> items, String cod) {
  var carried = 0;
  var totalCents = 0;
  for (final item in items) {
    final offer = offerAt(item, cod);
    if (offer == null) continue;
    carried++;
    totalCents += lineCents(offer.priceCents, item.qty);
  }
  return (carried: carried, totalCents: totalCents);
}
