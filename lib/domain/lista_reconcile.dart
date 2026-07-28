/// Settling what the parser could not, using the products the shops actually
/// stock.
///
/// `lista_parse.dart` reads a line offline and, where the answer genuinely
/// isn't in the text, says so instead of guessing. `12 Ovos` is the case that
/// proves it: twelve eggs and one carton of twelve are both correct readings of
/// the same three characters, and no amount of grammar decides between them.
///
/// What decides it is the price search coming back with `OVO BRANCO GRANDE
/// 12UN`. That is evidence — a real product, in a real shop, near this user —
/// and it is the only thing here that is allowed to change a parse.
///
/// **Every rule requires evidence in the response.** None fire on a hunch, none
/// fire twice, and the one that costs a second network round trip is bounded by
/// [ListItem.reconciled] so it cannot loop. A response with nothing in it
/// changes nothing: an item that could not be priced keeps exactly what the
/// user typed.
///
/// Pure, like the rest of `domain/` — it takes a [Precos] that someone else
/// fetched and returns a new [ListItem].
library;

import '../core/measure.dart';
import '../core/staples.dart';
import '../data/models/list_item.dart';
import '../data/models/precos.dart';
import 'lista_parse.dart';

/// The reconciled item, and whether it now needs a fresh price.
///
/// [reprice] is only ever set by the wrong-basis rule, which changes the search
/// itself. Everything else re-reads the response already in hand.
typedef Reconciled = ({ListItem item, bool reprice});

/// Re-reads [item] in the light of what [precos] came back with.
Reconciled reconcile(ListItem item, Precos precos, Staples staples) {
  final names = [
    precos.name,
    for (final o in precos.options) o.name,
  ];
  final found = precos.options.isNotEmpty || precos.cheapest != null;

  // Rule 1 — the wrong price basis.
  //
  // A per-KG search that came back with nothing, for a term that is obviously
  // sold *somehow*, means the basis was wrong: this is a sealed package priced
  // per unit, not a cut weighed at a counter. Flip it, and keep the weight the
  // user asked for as a size hint so the 500g pack can still be preferred over
  // the 200g one.
  //
  // This is the safety net under the parser's default that an unknown weight
  // term is an amount. Bounded to one attempt — a flip that also finds nothing
  // must not flip back.
  //
  // Only for terms the lexicon *didn't* vouch for. When it says "carne" is sold
  // by the kilo, an empty per-KG result is a gap in local coverage, not a wrong
  // basis, and pricing beef per package would be meaningless.
  final vouched = staples.lookup(item.name)?.soldByWeight ?? false;
  if (!item.reconciled && !found && item.unit == 'kg' && !vouched) {
    return (
      item: item.copyWith(
        unit: 'un',
        qty: 1,
        sizeValue: item.sizeValue ?? item.qty,
        sizeUnit: item.sizeUnit ?? 'kg',
        parseConf: ParseConf.medium,
        reconciled: true,
      ),
      reprice: true,
    );
  }

  // Nothing came back: nothing is known, so nothing is changed. An unpriced row
  // shows what the user typed, which is honest; rewriting it on no evidence
  // would not be.
  if (!found) return (item: item.copyWith(reconciled: true), reprice: false);

  var out = item.copyWith(reconciled: true);
  final size = out.size;

  // Rule 2 — was that number a count, or the pack it comes in?
  //
  // The parser took the non-multiplying reading (one carton) and marked it
  // `low`, which is its licence to be overruled here. Confirm it if a matching
  // pack is really on the shelves; revert to a plain count of loose units if
  // not, because somewhere that sells eggs by the unit exists too.
  if (out.parseConf == ParseConf.low && size != null && size.unit == 'un') {
    final stocked = names.any((n) => textHasMeasure(n, size));
    out = stocked
        ? out.copyWith(parseConf: ParseConf.medium)
        : out.copyWith(
            qty: size.value,
            sizeValue: null,
            sizeUnit: null,
            parseConf: ParseConf.medium,
          );
  }

  // Rule 3 — price the size that was asked for.
  //
  // "Refrigerante 2l" searched broadly on purpose, so the answer holds cans and
  // bottles alike. Options arrive tier-1-first, so the first one advertising 2L
  // is the least surprising 2L. An explicit pick by the user always wins.
  final want = out.size;
  if (want != null && out.chosenKey == null && precos.options.isNotEmpty) {
    final match = precos.options
        .where((o) => textHasMeasure(o.name, want))
        .firstOrNull;
    if (match != null) {
      out = out.copyWith(chosenKey: match.key);
    } else if (out.parseConf == ParseConf.high) {
      // Asked for a size nobody nearby stocks. The price on the row is for
      // *some* other size, so the row has to admit it isn't sure.
      out = out.copyWith(parseConf: ParseConf.medium);
    }
  }

  return (item: out, reprice: false);
}
