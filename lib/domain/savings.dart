/// Savings = what you paid − what the same thing costs nearby, per item.
///
/// Pure arithmetic over items already carrying their `precos`. The matching
/// itself — GTIN recovery, per-UN vs per-KG like-for-like, dropping offers far
/// below the median — happens server-side in `/api/precos`; the client's part
/// of that contract is sending `unit` on every enrichment call (see
/// `data/enrichment.dart`), never re-deriving the match here.
///
/// What this file *does* guard is the one thing the backend cannot see: **what
/// the user actually paid**. An approximate (description-matched) offer at a
/// fraction of the paid price is far more likely to be a different product than
/// a real bargain, and `Docs/09` is explicit that a wrong "you overpaid R$17"
/// destroys trust. Those are dropped rather than shown.
library;

import '../data/models/precos.dart';
import '../data/models/receipt.dart';

/// One line that is genuinely cheaper somewhere nearby.
typedef ComparedItem = ({
  ReceiptItem item,
  Offer cheapest,
  int perUnitSavedCents,
  int lineSavedCents,
});

typedef Savings = ({
  List<ComparedItem> compared,
  List<ReceiptItem> uncompared,
  int totalSavedCents,
});

/// The floor an *approximate* match has to clear, as a fraction of the price
/// paid. Mirrors the backend's own 0.4-of-the-median outlier trim, applied to
/// the signal it doesn't have.
///
/// ponytail: one flat ratio, no per-category tuning — revisit only if real
/// receipts show genuine 60%-off promotions being dropped.
const _approxFloor = 0.4;

/// Splits the receipt into what is cheaper nearby and what could not be
/// compared at all.
///
/// Three states, deliberately, because collapsing any two of them is how the
/// figure starts lying:
/// - **compared** — matched and cheaper nearby; the only lines that add savings.
/// - **uncompared** — no usable nearby price. Shown as "sem preço próximo",
///   never as "no savings here".
/// - matched but **not cheaper** — neither. It is not a saving, and calling it
///   uncompared would claim we failed to price something we priced fine.
Savings computeSavings(List<ReceiptItem> items) {
  final compared = <ComparedItem>[];
  final uncompared = <ReceiptItem>[];
  var totalSavedCents = 0;

  for (final item in items) {
    final precos = item.precos;
    final cheapest = precos?.cheapest;
    // priceCents 0 means "price unknown" (the store-search shape), not "free" —
    // comparing against it would book the whole line as a saving.
    if (cheapest == null || cheapest.priceCents <= 0) {
      uncompared.add(item);
      continue;
    }
    if (precos!.confidence != 'high' &&
        cheapest.priceCents < item.unitPriceCents * _approxFloor) {
      uncompared.add(item);
      continue;
    }

    final perUnitSavedCents = item.unitPriceCents - cheapest.priceCents;
    if (perUnitSavedCents <= 0) continue;

    final qty = item.qty > 0 ? item.qty : 1.0;
    final lineSavedCents = (perUnitSavedCents * qty).round();
    totalSavedCents += lineSavedCents;
    compared.add((
      item: item,
      cheapest: cheapest,
      perUnitSavedCents: perUnitSavedCents,
      lineSavedCents: lineSavedCents,
    ));
  }

  compared.sort((a, b) => b.lineSavedCents.compareTo(a.lineSavedCents));
  return (compared: compared, uncompared: uncompared, totalSavedCents: totalSavedCents);
}

/// Potential savings as a whole percent of the receipt total.
int savedPct(int savedCents, int totalCents) =>
    totalCents > 0 ? (savedCents / totalCents * 100).round() : 0;

/// The four honest verdicts [compareHere] can reach for one scanned product.
enum CompareStatus {
  /// Nothing priced nearby for this code at all.
  noOffers,

  /// Priced nearby, but not at the store the user says they're standing in.
  notCarried,

  /// The store here ties or beats every nearby offer.
  hereCheapest,

  /// Cheaper somewhere else nearby — [CompareResult.savingsCents] is the gap.
  cheaperElsewhere,
}

typedef CompareResult = ({
  CompareStatus status,
  Offer? here,
  Offer? cheapest,
  Offer? cheaper,
  int savingsCents,
});

/// One scanned product, judged against the store the user says they're
/// standing in (by [cod]).
///
/// [data] is a [Precos] from the GTIN lookup path. Identifying "here" always
/// goes through [Precos.stores], never [Precos.cheapest] — the backend omits
/// `cod` on `cheapest` (see [Offer]), so a `here.cod == cheapest.cod` check
/// would be comparing against null. It would also be redundant: if here is
/// genuinely the cheapest, its price already equals `cheapest.priceCents`,
/// so the `savingsCents <= 0` branch below catches it regardless.
CompareResult compareHere(Precos data, String? cod) {
  final cheapest = data.cheapest;
  if (data.nOffers <= 0) {
    return (status: CompareStatus.noOffers, here: null, cheapest: cheapest, cheaper: null, savingsCents: 0);
  }

  Offer? here;
  for (final s in data.stores) {
    if (s.cod == cod) {
      here = s;
      break;
    }
  }
  if (here == null) {
    return (status: CompareStatus.notCarried, here: null, cheapest: cheapest, cheaper: cheapest, savingsCents: 0);
  }

  final savingsCents = cheapest != null ? here.priceCents - cheapest.priceCents : 0;
  if (savingsCents <= 0) {
    return (status: CompareStatus.hereCheapest, here: here, cheapest: cheapest, cheaper: null, savingsCents: 0);
  }
  return (status: CompareStatus.cheaperElsewhere, here: here, cheapest: cheapest, cheaper: cheapest, savingsCents: savingsCents);
}
