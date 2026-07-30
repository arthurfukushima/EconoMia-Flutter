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
      if (byCount != 0) return byCount;
      final byTotal = a.totalCents.compareTo(b.totalCents);
      if (byTotal != 0) return byTotal;
      // Same basket for the same money: take the nearer one. Without this a
      // market 25 km away ties with one down the street.
      return (a.km ?? double.infinity).compareTo(b.km ?? double.infinity);
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
  for (final line in basketLinesAt(items, cod)) {
    if (line.offer == null) continue;
    carried++;
    totalCents += line.totalCents;
  }
  return (carried: carried, totalCents: totalCents);
}

/// One list line as it prices at one market: the product actually matched, how
/// much of it to buy, and what that comes to there.
///
/// A line the market doesn't carry keeps its place with a null [offer] rather
/// than being dropped — "não vende aqui" is the honest half of a breakdown, and
/// silently omitting it would make a partial basket read as a complete one.
typedef BasketLine = ({
  ListItem item,
  Offer? offer,
  String? product,
  int totalCents,
});

/// The whole list, line by line, priced at one market. Same order as [items].
List<BasketLine> basketLinesAt(List<ListItem> items, String cod) => [
      for (final item in items)
        () {
          final offer = offerAt(item, cod);
          return (
            item: item,
            offer: offer,
            product: activeOption(item)?.name,
            totalCents: offer == null ? 0 : lineCents(offer.priceCents, item.qty),
          );
        }(),
    ];

/// What a second stop has to buy you before it is worth suggesting.
///
/// Below this, "divida sua compra em dois mercados" costs more in fuel, parking
/// and another queue than it saves — advice that makes the app wrong even when
/// its arithmetic is right.
///
/// ponytail: flat R$ 5,00, not scaled by the distance between the two markets.
const splitWorthCents = 500;

/// A second market weighed against the one you would otherwise shop at alone.
///
/// [savedCents] counts only the *shared* lines — a line the anchor market
/// doesn't carry is not a saving, since you were buying it somewhere else
/// regardless. That is [extra]: counted, shown, never turned into money.
///
/// [cheaper] and [extra] name the lines rather than only counting them: "vale
/// dividir" is advice you have to be able to act on, and "2 itens mais baratos
/// lá" without saying which two is not.
typedef SplitOption = ({
  String cod,
  String? store,
  String? bairro,
  double? km,
  List<ListItem> cheaper,
  List<ListItem> extra,
  int savedCents,
  int totalCents,
});

/// The best second stop to add to market [cod], or null when no other market is
/// worth the trip.
///
/// Deliberately anchored rather than a free search over every pair: the cheapest
/// pair of markets can cover fewer items than the best single one, and then its
/// total is over a different shopping than the number it would be compared to.
/// Anchoring keeps both sides of "vale dividir?" about the same list.
SplitOption? bestSplit(List<ListItem> items, String cod) {
  final cods = <String>{};
  for (final item in items) {
    for (final s in activeOption(item)?.stores ?? const <Offer>[]) {
      if (s.cod != null && s.cod != cod) cods.add(s.cod!);
    }
  }

  SplitOption? best;
  for (final other in cods) {
    final cheaper = <ListItem>[];
    final extra = <ListItem>[];
    var savedCents = 0;
    var totalCents = 0;
    Offer? seen;

    for (final item in items) {
      final here = offerAt(item, cod);
      final there = offerAt(item, other);
      if (there != null) seen = there;
      if (there == null) {
        // Only the anchor carries it (or nobody does, and the line is outside
        // both baskets).
        if (here != null) totalCents += lineCents(here.priceCents, item.qty);
        continue;
      }
      final thereCents = lineCents(there.priceCents, item.qty);
      if (here == null) {
        extra.add(item);
        totalCents += thereCents;
        continue;
      }
      final hereCents = lineCents(here.priceCents, item.qty);
      if (thereCents < hereCents) {
        cheaper.add(item);
        // The difference of the two line totals, not `lineCents` of the price
        // difference: the saving shown has to equal the difference of the two
        // totals shown, to the centavo.
        savedCents += hereCents - thereCents;
        totalCents += thereCents;
      } else {
        totalCents += hereCents;
      }
    }

    if (seen == null) continue;
    final option = (
      cod: other,
      store: seen.store,
      bairro: seen.bairro,
      km: seen.km,
      cheaper: cheaper,
      extra: extra,
      savedCents: savedCents,
      totalCents: totalCents,
    );
    if (best == null ||
        option.savedCents > best.savedCents ||
        (option.savedCents == best.savedCents &&
            (option.extra.length > best.extra.length ||
                (option.extra.length == best.extra.length &&
                    (option.km ?? double.infinity) <
                        (best.km ?? double.infinity))))) {
      best = option;
    }
  }

  if (best == null) return null;
  return best.savedCents < splitWorthCents && best.extra.isEmpty ? null : best;
}
