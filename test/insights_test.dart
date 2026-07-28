import 'package:economia/core/categoria.dart';
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

  /// Resumo reads these off the same `aggregate()` Home's hero does — same
  /// standard: a plausible-looking wrong breakdown is still a wrong number.
  group('aggregate — Resumo fields', () {
    test('byCategory groups spend by category, sorted by spend, with pct of total', () {
      final agg = aggregate([
        Receipt(
          accessKey: 'a',
          header: const ReceiptHeader(purchasedAt: '10/07/2026'),
          items: const [
            ReceiptItem(description: 'BANANA NANICA', unitPriceCents: 300, lineTotalCents: 300),
            ReceiptItem(description: 'LEITE INTEGRAL', unitPriceCents: 700, lineTotalCents: 700),
          ],
        ),
      ]);

      expect(agg.byCategory.first.cat, Categoria.laticinios);
      expect(agg.byCategory.first.spentCents, 700);
      expect(agg.byCategory.first.pct, 70);
      expect(agg.byCategory.last.cat, Categoria.frutas);
      expect(agg.byCategory.last.pct, 30);
    });

    test('topItems merges the same product across notes by gtin, ranked by count then spend', () {
      final agg = aggregate([
        Receipt(
          accessKey: 'a',
          header: const ReceiptHeader(purchasedAt: '01/07/2026'),
          items: const [ReceiptItem(description: 'ARROZ', gtin: '111', unitPriceCents: 500, lineTotalCents: 500)],
        ),
        Receipt(
          accessKey: 'b',
          header: const ReceiptHeader(purchasedAt: '02/07/2026'),
          items: const [
            ReceiptItem(description: 'ARROZ', gtin: '111', unitPriceCents: 500, lineTotalCents: 500),
            ReceiptItem(description: 'FEIJAO', unitPriceCents: 900, lineTotalCents: 900),
          ],
        ),
      ]);

      expect(agg.topItems.first.key, '111');
      expect(agg.topItems.first.count, 2);
      expect(agg.topItems.first.spentCents, 1000);
    });

    test('byStore groups visits by CNPJ and sums what was spent and saved there', () {
      final agg = aggregate([
        Receipt(
          accessKey: 'a',
          header: const ReceiptHeader(cnpj: '123', storeName: 'CONDOR', purchasedAt: '01/07/2026', totalCents: 500),
          items: [
            ReceiptItem(
              description: 'ITEM',
              unitPriceCents: 500,
              lineTotalCents: 500,
              precos: const Precos(confidence: 'high', cheapest: Offer(priceCents: 400)),
            ),
          ],
        ),
        Receipt(
          accessKey: 'b',
          header: const ReceiptHeader(cnpj: '123', storeName: 'CONDOR', purchasedAt: '02/07/2026', totalCents: 500),
          items: [
            ReceiptItem(
              description: 'ITEM',
              unitPriceCents: 500,
              lineTotalCents: 500,
              precos: const Precos(confidence: 'high', cheapest: Offer(priceCents: 400)),
            ),
          ],
        ),
      ]);

      expect(agg.byStore, hasLength(1));
      expect(agg.byStore.first.visits, 2);
      expect(agg.byStore.first.spentCents, 1000);
      expect(agg.byStore.first.savedCents, 200);
    });

    test('bestAlt is the nearby store that would have saved the most, a dearer one never surfaces', () {
      final agg = aggregate([
        Receipt(
          accessKey: 'a',
          header: const ReceiptHeader(purchasedAt: '01/07/2026'),
          items: [
            ReceiptItem(
              description: 'ITEM',
              unitPriceCents: 1000,
              lineTotalCents: 1000,
              precos: const Precos(
                confidence: 'high',
                cheapest: Offer(priceCents: 800),
                stores: [
                  Offer(cod: '1', priceCents: 800, store: 'CONDOR'),
                  Offer(cod: '2', priceCents: 1200, store: 'MUFFATO'),
                ],
              ),
            ),
          ],
        ),
      ]);

      expect(agg.bestAlt?.cod, '1');
      expect(agg.bestAlt?.name, 'CONDOR');
      expect(agg.bestAlt?.savedCents, 200);
    });

    test('bestAlt is null when no nearby store beats what was actually paid', () {
      final agg = aggregate([
        Receipt(
          accessKey: 'a',
          header: const ReceiptHeader(purchasedAt: '01/07/2026'),
          items: [
            ReceiptItem(
              description: 'ITEM',
              unitPriceCents: 1000,
              lineTotalCents: 1000,
              precos: const Precos(
                confidence: 'high',
                cheapest: Offer(priceCents: 1000),
                stores: [Offer(cod: '1', priceCents: 1200, store: 'CONDOR')],
              ),
            ),
          ],
        ),
      ]);

      expect(agg.bestAlt, isNull);
    });
  });
}
