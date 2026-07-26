import 'package:economia/data/models/precos.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/domain/insights.dart';
import 'package:flutter_test/flutter_test.dart';

/// Home's hero shows this figure directly, so — same standard as
/// `savings_test.dart` — no plausible-looking wrong number ships silently.
Receipt _receipt({
  required String accessKey,
  required String purchasedAt,
  int? cheapest,
  int paid = 1000,
}) =>
    Receipt(
      accessKey: accessKey,
      header: ReceiptHeader(purchasedAt: purchasedAt, totalCents: paid),
      items: [
        ReceiptItem(
          description: 'ITEM',
          unitPriceCents: paid,
          lineTotalCents: paid,
          precos: cheapest == null
              ? null
              : Precos(confidence: 'high', cheapest: Offer(priceCents: cheapest)),
        ),
      ],
    );

void main() {
  group('aggregate', () {
    test('notesCount counts every receipt; pricedNotesCount only the priced ones', () {
      final agg = aggregate([
        _receipt(accessKey: 'a', purchasedAt: '10/07/2026', cheapest: 800, paid: 1000),
        _receipt(accessKey: 'b', purchasedAt: '11/07/2026'), // unpriced
      ]);

      expect(agg.notesCount, 2);
      expect(agg.pricedNotesCount, 1);
      expect(agg.totalSavedCents, 200);
    });

    test('an unpriced receipt contributes nothing to totalSavedCents', () {
      final agg = aggregate([_receipt(accessKey: 'a', purchasedAt: '10/07/2026')]);
      expect(agg.totalSavedCents, 0);
      expect(agg.pricedNotesCount, 0);
    });

    test('no receipts is the honest zero, not a crash', () {
      final agg = aggregate(const []);
      expect(agg.totalSavedCents, 0);
      expect(agg.notesCount, 0);
      expect(agg.projectedAnnualCents, 0);
    });

    test('projection needs at least two priced notes', () {
      final agg = aggregate([
        _receipt(accessKey: 'a', purchasedAt: '10/07/2026', cheapest: 800, paid: 1000),
      ]);
      expect(agg.projectedAnnualCents, 0, reason: 'one lucky receipt should not imply a wild yearly figure');
    });

    test('projection extrapolates saved-per-day over the note span', () {
      final agg = aggregate([
        _receipt(accessKey: 'a', purchasedAt: '01/01/2026', cheapest: 800, paid: 1000), // saved 200
        _receipt(accessKey: 'b', purchasedAt: '11/01/2026', cheapest: 800, paid: 1000), // saved 200, 10 days later
      ]);

      expect(agg.totalSavedCents, 400);
      expect(agg.projectedAnnualCents, (400 / 10 * 365).round());
    });

    test('totalSpentCents sums every line, priced or not', () {
      final agg = aggregate([
        _receipt(accessKey: 'a', purchasedAt: '10/07/2026', cheapest: 800, paid: 1000),
        _receipt(accessKey: 'b', purchasedAt: '11/07/2026', paid: 500),
      ]);
      expect(agg.totalSpentCents, 1500);
    });
  });
}
