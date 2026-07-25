import 'package:economia/core/categoria.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/domain/tendencias.dart';
import 'package:flutter_test/flutter_test.dart';

/// The day-tip's weekday-trend detection: honestly empty on thin data, and
/// only ever names a store it can pin the discount to.
void main() {
  PriceObservation obs(String iso, {int cents = 300, String store = 'SUPERMERCADOS MUFFATO LTDA'}) =>
      PriceObservation(cod: '1', store: store, category: Categoria.frutas, priceCents: cents, datahora: iso);

  group('cheapDayByCategory', () {
    test('flags a weekday whose median clears the margin over every other weekday', () {
      // Wednesdays (2026-07-{01,08,15,22} are Wednesdays) cheap at 200; every
      // other day in the set is 300 — a 33% drop, well past the 8% default bar.
      final offers = [
        for (final d in ['2026-07-01', '2026-07-08', '2026-07-15', '2026-07-22'])
          obs('${d}T10:00:00Z', cents: 200),
        for (final d in ['2026-07-02', '2026-07-03', '2026-07-06', '2026-07-07'])
          obs('${d}T10:00:00Z', cents: 300),
      ];

      final trends = cheapDayByCategory(offers);

      expect(trends, hasLength(1));
      expect(trends.single.category, Categoria.frutas);
      expect(trends.single.weekday, DateTime.parse('2026-07-01T10:00:00Z').weekday % 7);
      expect(trends.single.store, 'Muffato');
    });

    test('thin data yields nothing — no fabricated day', () {
      final offers = [obs('2026-07-01T10:00:00Z'), obs('2026-07-02T10:00:00Z')];
      expect(cheapDayByCategory(offers), isEmpty);
    });

    test('a store with no distinctive name cannot be flagged', () {
      final offers = [
        for (var i = 0; i < 8; i++) obs('2026-07-0${i + 1}T10:00:00Z', cents: 200, store: 'LTDA ME EPP'),
      ];
      expect(cheapDayByCategory(offers), isEmpty);
    });

    test('outros is never a promo category', () {
      final offers = [
        for (var i = 0; i < 8; i++)
          PriceObservation(
            cod: '1',
            store: 'MUFFATO LTDA',
            category: Categoria.outros,
            priceCents: 200,
            datahora: '2026-07-0${i + 1}T10:00:00Z',
          ),
      ];
      expect(cheapDayByCategory(offers), isEmpty);
    });
  });

  group('cheapDayFor', () {
    const trendCondor = (
      category: Categoria.frutas,
      store: 'Condor',
      chain: 'CONDOR',
      weekday: 3,
      nObs: 4,
      deltaPct: 20,
    );
    const trendMuffato = (
      category: Categoria.frutas,
      store: 'Muffato',
      chain: 'MUFFATO',
      weekday: 5,
      nObs: 4,
      deltaPct: 15,
    );

    test('prefers the store the user actually bought at', () {
      final t = cheapDayFor([trendCondor, trendMuffato], Categoria.frutas, 'SUPERMERCADOS MUFFATO LTDA');
      expect(t!.chain, 'MUFFATO');
    });

    test('falls back to the strongest trend when the store is unrecognised', () {
      final t = cheapDayFor([trendCondor, trendMuffato], Categoria.frutas, 'ALGUMA OUTRA LOJA LTDA');
      expect(t!.chain, 'CONDOR');
    });

    test('no trend for the category is null, not a guess', () {
      expect(cheapDayFor([trendCondor], Categoria.laticinios, 'CONDOR'), isNull);
    });
  });

  group('purchaseWeekday', () {
    test('reads the consulta date first', () {
      const receipt = Receipt(
        accessKey: 'k',
        header: ReceiptHeader(purchasedAt: '20/07/2026 10:00:00'),
        createdAt: 1700000000000, // some unrelated other day
      );
      expect(purchaseWeekday(receipt), DateTime(2026, 7, 20).weekday % 7);
    });

    test('falls back to when the nota was scanned', () {
      // Local, not UTC — a wall-clock date round-trips through
      // fromMillisecondsSinceEpoch to the same weekday regardless of the
      // machine's timezone.
      final scannedAt = DateTime(2026, 7, 22);
      final receipt = Receipt(accessKey: 'k', createdAt: scannedAt.millisecondsSinceEpoch);
      expect(purchaseWeekday(receipt), scannedAt.weekday % 7);
    });

    test('neither resolving is null, not a wrong guess', () {
      expect(purchaseWeekday(const Receipt(accessKey: 'k')), isNull);
    });
  });
}
