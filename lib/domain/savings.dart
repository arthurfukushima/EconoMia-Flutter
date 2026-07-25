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
