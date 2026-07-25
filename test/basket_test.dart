import 'package:economia/data/models/precos.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/domain/basket.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 5's single-store basket mode: the same nota priced at one store
/// instead of cheapest-per-item, including the items that store doesn't sell.
void main() {
  final leite = ReceiptItem(
    description: 'LEITE',
    qty: 2,
    unitPriceCents: 449,
    precos: const Precos(stores: [
      Offer(priceCents: 398, store: 'Condor', cod: '1'),
      Offer(priceCents: 469, store: 'Muffato', cod: '2'),
    ]),
  );
  final pao = ReceiptItem(
    description: 'PAO',
    unitPriceCents: 899,
    precos: const Precos(stores: [Offer(priceCents: 799, store: 'Condor', cod: '1')]),
  );

  group('storeOptions', () {
    test('ranks by savings, then coverage, then proximity', () {
      final options = storeOptions([leite, pao]);

      expect(options.map((o) => o.cod), ['1', '2']);
      expect(options.first.itemsCovered, 2);
      expect(options.first.savedCents, (449 - 398) * 2 + (899 - 799));
      expect(options.last.savedCents, (449 - 469) * 2, reason: 'dearer here — negative saving');
    });

    test('a store with no cod cannot be grouped or selected', () {
      final item = ReceiptItem(
        description: 'X',
        unitPriceCents: 100,
        precos: const Precos(stores: [Offer(priceCents: 90, store: 'Sem código')]),
      );
      expect(storeOptions([item]), isEmpty);
    });

    test('no precos.stores anywhere yields no options, not a crash', () {
      expect(storeOptions([const ReceiptItem(description: 'X', unitPriceCents: 100)]), isEmpty);
    });
  });

  group('basketForStore', () {
    test('covered items price at that store; uncovered ones are listed, not dropped', () {
      final naoVendido = ReceiptItem(
        description: 'QUEIJO',
        unitPriceCents: 500,
        precos: const Precos(stores: [Offer(priceCents: 480, store: 'Muffato', cod: '2')]),
      );

      final basket = basketForStore([leite, pao, naoVendido], '1');

      expect(basket.coveredCount, 2);
      expect(basket.itemCount, 3);
      expect(basket.storeTotalCents, 398 * 2 + 799);
      expect(basket.totalSavedCents, (449 - 398) * 2 + (899 - 799));
      expect(basket.lines.firstWhere((l) => l.item.description == 'QUEIJO').offer, isNull);
    });

    test('a dearer store yields a negative total — the honest overpay case', () {
      final basket = basketForStore([leite], '2');
      expect(basket.totalSavedCents, lessThan(0));
      expect(basket.totalSavedCents, (449 - 469) * 2);
    });
  });
}
