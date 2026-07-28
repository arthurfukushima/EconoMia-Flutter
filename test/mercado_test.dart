import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/domain/stores.dart';
import 'package:economia/features/mercado/mercado_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 10's non-UI logic — the screen itself can't be widget-tested (see
/// screenshots.dart's note: the embedded camera throws under the test
/// binding's platform channel on every mount, same as Phase 3's ScanScreen).
void main() {
  group('mergeStores', () {
    test('dedupes by cod, nearest-first', () {
      final merged = mergeStores(
        [const Offer(cod: '1', store: 'CONDOR', km: 2.4)],
        [const Offer(cod: '1', store: 'CONDOR (novo)', km: 2.4), const Offer(cod: '2', store: 'MUFFATO', km: 1.1)],
      );

      expect(merged.map((s) => s.cod), ['2', '1']);
      expect(merged.last.store, 'CONDOR', reason: 'the first-seen store for a cod wins, not the incoming one');
    });

    test('a store with no cod is dropped — nothing to key it by', () {
      expect(mergeStores(const [], [const Offer(store: 'Sem código')]), isEmpty);
    });
  });

  group('defaultStoreCod', () {
    const stores = [Offer(cod: '1', store: 'CONDOR', km: 1.1), Offer(cod: '2', store: 'MUFFATO', km: 2.4)];

    test('no stores yet → nothing to default to', () {
      expect(defaultStoreCod(const AppLocation(lat: 0, lng: 0), const [], null), isNull);
    });

    test('a precise GPS fix wins even over a persisted pick — it is where you are standing', () {
      expect(defaultStoreCod(const AppLocation(lat: 0, lng: 0, precise: true), stores, '2'), '1');
    });

    test('a CEP fix keeps the persisted pick if it is still known', () {
      expect(defaultStoreCod(const AppLocation(lat: 0, lng: 0), stores, '2'), '2');
    });

    test('a CEP fix with no valid persisted pick falls back to nearest', () {
      expect(defaultStoreCod(const AppLocation(lat: 0, lng: 0), stores, null), '1');
      expect(defaultStoreCod(const AppLocation(lat: 0, lng: 0), stores, 'gone'), '1');
    });
  });

  group('shouldHandleCameraScan', () {
    test('accepts the first camera hit for a barcode', () {
      expect(shouldHandleCameraScan('7891234567890', null), isTrue);
    });

    test('ignores the same barcode on consecutive frames', () {
      expect(shouldHandleCameraScan('7891234567890', '7891234567890'), isFalse);
    });

    test('accepts a different barcode after the previous one', () {
      expect(shouldHandleCameraScan('7891234567891', '7891234567890'), isTrue);
    });
  });
}
