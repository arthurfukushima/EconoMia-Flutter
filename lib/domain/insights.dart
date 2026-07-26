/// Cross-note aggregation for the Home hero (and, later, Resumo).
///
/// Pure over the receipts list — no I/O, no classes — so the figure Mia's
/// hero shows is directly testable.
library;

import '../data/models/receipt.dart';
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

typedef Insights = ({
  int totalSavedCents,
  int projectedAnnualCents,
  int totalSpentCents,
  int notesCount,
  int pricedNotesCount,
});

/// Rolls every scanned note into the numbers Home's hero shows.
Insights aggregate(List<Receipt> receipts) {
  var totalSavedCents = 0;
  var totalSpentCents = 0;
  var pricedNotesCount = 0;
  DateTime? minDate, maxDate;

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
  );
}
