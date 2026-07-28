/// Cross-note aggregation for the Home hero and Resumo.
///
/// Pure over the receipts list — no I/O, no classes — so the figure Mia's
/// hero shows is directly testable.
library;

import '../core/categoria.dart';
import '../core/text.dart';
import '../data/models/precos.dart';
import '../data/models/receipt.dart';
import 'basket.dart';
import 'savings.dart';

/// Purchase date of a note: prefer the nota's own "DD/MM/YYYY", fall back to
/// when it was scanned. Null when neither parses.
DateTime? purchaseDate(Receipt receipt) {
  final purchasedAt = receipt.header.purchasedAt;
  final m = purchasedAt == null ? null : RegExp(r'(\d{2})/(\d{2})/(\d{4})').firstMatch(purchasedAt);
  if (m != null) {
    return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
  }
  final createdAt = receipt.createdAt;
  return createdAt == null ? null : DateTime.fromMillisecondsSinceEpoch(createdAt);
}

/// Spending in one category across every note, and its share of the total.
typedef CategorySpend = ({Categoria cat, int spentCents, int pct});

/// One distinct product (by `gtin`, falling back to [norm]'d description)
/// bought across notes — Resumo's "campeões da despensa".
typedef ItemSummary = ({
  String key,
  String name,
  int count,
  double qtyTotal,
  int spentCents,
  Offer? cheapest,
});

/// One store shopped at, across every note it appears on.
typedef StoreVisit = ({
  String? cnpj,
  String name,
  int visits,
  int spentCents,
  int savedCents,
});

/// The nearby store that would have saved the most, buying every item it
/// carries across all notes, versus what was actually paid.
typedef BestAlt = ({String cod, String name, int savedCents});

typedef Insights = ({
  int totalSavedCents,
  int projectedAnnualCents,
  int totalSpentCents,
  int notesCount,
  int pricedNotesCount,
  List<CategorySpend> byCategory,
  List<ItemSummary> topItems,
  List<StoreVisit> byStore,
  BestAlt? bestAlt,
});

/// Rolls every scanned note into the numbers Home's hero and Resumo show.
Insights aggregate(List<Receipt> receipts) {
  var totalSavedCents = 0;
  var totalSpentCents = 0;
  var pricedNotesCount = 0;
  DateTime? minDate, maxDate;

  final catSpent = <Categoria, int>{};
  final items = <String, ItemSummary>{};
  final stores = <String, StoreVisit>{};
  // Best-alternative-store accumulator: savedCents summed across every note's
  // storeOptions(), keyed by cod so the same nearby store's saving compounds.
  final alts = <String, ({String name, int savedCents})>{};

  for (final r in receipts) {
    final savedHere = computeSavings(r.items).totalSavedCents;
    final priced = r.items.any((it) => it.precos?.cheapest != null);
    if (priced) {
      pricedNotesCount++;
      totalSavedCents += savedHere;
    }

    final d = purchaseDate(r);
    if (d != null) {
      if (minDate == null || d.isBefore(minDate)) minDate = d;
      if (maxDate == null || d.isAfter(maxDate)) maxDate = d;
    }

    for (final it in r.items) {
      totalSpentCents += it.lineTotalCents;

      final cat = classify(description: it.description, ncm: it.ncm);
      catSpent[cat] = (catSpent[cat] ?? 0) + it.lineTotalCents;

      final key = it.gtin ?? norm(it.description);
      final cur = items[key];
      items[key] = (
        key: key,
        name: cur?.name ?? it.description,
        count: (cur?.count ?? 0) + 1,
        qtyTotal: (cur?.qtyTotal ?? 0) + it.qty,
        spentCents: (cur?.spentCents ?? 0) + it.lineTotalCents,
        cheapest: cur?.cheapest ?? it.precos?.cheapest,
      );
    }

    // Favourite market: one visit per note, grouped by CNPJ (store name, then
    // the accessKey, as fallbacks for a scrape that came back thin).
    final skey = r.header.cnpj ?? r.header.storeName ?? r.accessKey;
    final curStore = stores[skey];
    stores[skey] = (
      cnpj: r.header.cnpj,
      name: r.header.storeName ?? 'Mercado',
      visits: (curStore?.visits ?? 0) + 1,
      spentCents: (curStore?.spentCents ?? 0) + r.header.totalCents,
      savedCents: (curStore?.savedCents ?? 0) + savedHere,
    );

    for (final s in storeOptions(r.items)) {
      final curAlt = alts[s.cod];
      alts[s.cod] = (
        name: s.name ?? curAlt?.name ?? 'Mercado',
        savedCents: (curAlt?.savedCents ?? 0) + s.savedCents,
      );
    }
  }

  final byCategory = catSpent.entries
      .map((e) => (
            cat: e.key,
            spentCents: e.value,
            pct: totalSpentCents > 0 ? (e.value / totalSpentCents * 100).round() : 0,
          ))
      .toList()
    ..sort((a, b) => b.spentCents.compareTo(a.spentCents));

  final topItems = items.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : b.spentCents.compareTo(a.spentCents);
    });

  final byStore = stores.values.toList()
    ..sort((a, b) {
      final byVisits = b.visits.compareTo(a.visits);
      return byVisits != 0 ? byVisits : b.spentCents.compareTo(a.spentCents);
    });

  BestAlt? bestAlt;
  for (final e in alts.entries) {
    if (e.value.savedCents <= 0) continue;
    if (bestAlt == null || e.value.savedCents > bestAlt.savedCents) {
      bestAlt = (cod: e.key, name: e.value.name, savedCents: e.value.savedCents);
    }
  }

  // Annual projection: extrapolate saved-per-day over the note span. Needs a
  // real span and >= 2 priced notes so one lucky receipt can't imply a wild
  // yearly figure.
  var projectedAnnualCents = 0;
  if (minDate != null && maxDate != null && pricedNotesCount >= 2) {
    final spanDays = maxDate.difference(minDate).inDays.clamp(1, 1 << 30);
    projectedAnnualCents = (totalSavedCents / spanDays * 365).round();
  }

  return (
    totalSavedCents: totalSavedCents,
    projectedAnnualCents: projectedAnnualCents,
    totalSpentCents: totalSpentCents,
    notesCount: receipts.length,
    pricedNotesCount: pricedNotesCount,
    byCategory: byCategory,
    topItems: topItems,
    byStore: byStore,
    bestAlt: bestAlt,
  );
}
