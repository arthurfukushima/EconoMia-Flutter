import 'dart:convert';
import 'dart:io';

import 'package:economia/core/api_client.dart';
import 'package:economia/core/categoria.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/enrichment.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/domain/savings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The savings figure is the project's #1 risk — `Docs/09`: *"a wrong 'you
/// overpaid R$17' destroys trust"*. These are the guardrails around it.
const _location = AppLocation(lat: -23.31, lng: -51.16, cep: '86010000', raio: 15);

ReceiptItem _item({
  String description = 'ITEM',
  double qty = 1,
  String unit = 'UN',
  int paid = 1000,
  int? cheapest,
  String confidence = 'high',
}) =>
    ReceiptItem(
      description: description,
      qty: qty,
      unit: unit,
      unitPriceCents: paid,
      lineTotalCents: (paid * qty).round(),
      precos: cheapest == null
          ? null
          : Precos(
              basis: confidence == 'high' ? 'gtin' : 'desc',
              confidence: confidence,
              cheapest: Offer(priceCents: cheapest, store: 'Condor'),
            ),
    );

void main() {
  group('computeSavings', () {
    test('sums positive per-unit deltas × qty, biggest line first', () {
      final s = computeSavings([
        _item(description: 'LEITE', qty: 6, paid: 449, cheapest: 398),
        _item(description: 'ARROZ', paid: 2890, cheapest: 2490),
      ]);

      expect(s.compared.map((c) => c.item.description), ['ARROZ', 'LEITE']);
      expect(s.compared.first.perUnitSavedCents, 400);
      expect(s.totalSavedCents, 400 + 51 * 6);
      expect(s.uncompared, isEmpty);
    });

    test('a fractional qty rounds once, at the line', () {
      // 150 × 1.235 = 185.25 — never 185.25 carried on into a total.
      final s = computeSavings([_item(qty: 1.235, paid: 499, cheapest: 349)]);
      expect(s.compared.single.lineSavedCents, 185);
      expect(s.totalSavedCents, 185);
    });

    test('matched but dearer nearby is neither compared nor uncompared', () {
      final s = computeSavings([_item(paid: 849, cheapest: 879)]);

      expect(s.compared, isEmpty);
      expect(s.uncompared, isEmpty, reason: 'it was priced fine — it just is not cheaper');
      expect(s.totalSavedCents, 0);
    });

    test('an item with no nearby price is uncompared, not a zero saving', () {
      final s = computeSavings([
        _item(description: 'PAO FRANCES'), // precos == null
        ReceiptItem(description: 'SEM CHEAPEST', unitPriceCents: 500, precos: const Precos()),
      ]);

      expect(s.uncompared.length, 2);
      expect(s.totalSavedCents, 0);
    });

    test('a priceless offer is unknown, not free', () {
      // The store-search shape carries priceCents 0. Booking it as a comparison
      // would claim the whole line as a saving.
      final s = computeSavings([_item(paid: 1290, cheapest: 0)]);

      expect(s.compared, isEmpty);
      expect(s.uncompared, hasLength(1));
    });

    test('an outlier under an approximate match is rejected', () {
      // R$ 12,90 "found" at R$ 2,90 on a description match: far likelier a
      // different product than a 77% discount.
      final outlier = computeSavings([
        _item(description: 'PAO FRANCES KG', unit: 'KG', paid: 1290, cheapest: 290, confidence: 'approx'),
      ]);

      expect(outlier.compared, isEmpty);
      expect(outlier.uncompared, hasLength(1), reason: 'no price we can stand behind');

      // The same discount on a barcode match is identity-certain, and the
      // backend has already trimmed that offer set against its own median.
      final byGtin = computeSavings([_item(paid: 1290, cheapest: 290)]);
      expect(byGtin.totalSavedCents, 1000);

      // A believable approximate discount still counts.
      final ok = computeSavings([_item(paid: 1290, cheapest: 990, confidence: 'approx')]);
      expect(ok.totalSavedCents, 300);
    });

    test('the real enriched Muffato nota adds up', () {
      final receipt = Receipt.fromJson(
        (jsonDecode(File('test/fixtures/sample-receipts.json').readAsStringSync()) as List)
            .first as Map<String, dynamic>,
      );
      final s = computeSavings(receipt.items);

      expect(s.compared, hasLength(8));
      expect(s.uncompared, hasLength(2), reason: 'PAO FRANCES and DETERGENTE');
      expect(
        s.compared.length + s.uncompared.length,
        receipt.items.length - 1,
        reason: 'FEIJAO is dearer nearby: in neither list',
      );
      expect(s.totalSavedCents, 2492);
      expect(savedPct(s.totalSavedCents, receipt.header.totalCents), 13);
      expect(s.totalSavedCents, lessThan(receipt.header.totalCents));
    });

    test('savedPct never divides by a missing total', () {
      expect(savedPct(500, 0), 0);
      expect(savedPct(0, 1000), 0);
    });
  });

  group('compareHere', () {
    const cheapest = Offer(priceCents: 398, store: 'CONDOR');

    test('no-offers: nothing priced nearby for this code at all', () {
      final r = compareHere(const Precos(nOffers: 0), '1');
      expect(r.status, CompareStatus.noOffers);
      expect(r.here, isNull);
      expect(r.savingsCents, 0);
    });

    test('not-carried: priced nearby, but not at the picked store', () {
      final r = compareHere(
        const Precos(nOffers: 3, cheapest: cheapest, stores: [Offer(cod: '2', priceCents: 410)]),
        '1',
      );
      expect(r.status, CompareStatus.notCarried);
      expect(r.here, isNull);
      expect(r.cheaper, cheapest, reason: 'the honest "buy it there instead" pointer');
      expect(r.savingsCents, 0);
    });

    test('here-cheapest: the picked store ties or beats every nearby offer', () {
      final r = compareHere(
        Precos(nOffers: 2, cheapest: cheapest, stores: [const Offer(cod: '1', priceCents: 398)]),
        '1',
      );
      expect(r.status, CompareStatus.hereCheapest);
      expect(r.cheaper, isNull);
      expect(r.savingsCents, 0);
    });

    test('cheaper-elsewhere: the gap is here minus cheapest, and positive', () {
      final r = compareHere(
        Precos(nOffers: 2, cheapest: cheapest, stores: [const Offer(cod: '1', priceCents: 450)]),
        '1',
      );
      expect(r.status, CompareStatus.cheaperElsewhere);
      expect(r.here!.priceCents, 450);
      expect(r.cheaper, cheapest);
      expect(r.savingsCents, 52);
    });

    test('a null cod (no store picked yet) never matches a real store', () {
      final r = compareHere(
        const Precos(nOffers: 1, stores: [Offer(cod: '1', priceCents: 450)]),
        null,
      );
      expect(r.status, CompareStatus.notCarried);
    });
  });

  group('enrichReceipt', () {
    /// An API whose `/api/precos` answers from [bodies], keyed by the `q` it was
    /// asked for, and that records every request.
    (EconomiaApi, List<Uri>, List<int>) apiFor(Map<String, String> bodies) {
      final seen = <Uri>[];
      final inFlight = <int>[];
      var live = 0;
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          seen.add(req.url);
          live++;
          inFlight.add(live);
          await Future<void>.delayed(const Duration(milliseconds: 5));
          live--;
          final body = bodies[req.url.queryParameters['q']];
          if (body == null) return http.Response('{"error":"menorpreco_failed"}', 502);
          return http.Response.bytes(utf8.encode(body), 200);
        }),
      ));
      return (api, seen, inFlight);
    }

    const banana = ReceiptItem(description: 'BANANA NANICA', unit: 'KG', qty: 1.2, unitPriceCents: 499);
    const leite = ReceiptItem(description: 'LEITE ITALAC 1L', unit: 'UN', unitPriceCents: 449);
    const receipt = Receipt(
      accessKey: '41250712345678000190650010000123451987654321',
      header: ReceiptHeader(storeName: 'MUFFATO', city: 'Londrina'),
      items: [banana, leite],
    );

    test('every item travels with its unit — the like-for-like guardrail', () async {
      // A per-KG banana compared against a per-UN banana is the false match
      // that inflated the raw figure; the backend filter is armed by `unit`.
      final (api, seen, _) = apiFor({
        'BANANA NANICA': '{"basis":"desc","confidence":"approx","cheapest":{"priceCents":349}}',
        'LEITE ITALAC 1L': '{"basis":"gtin","confidence":"high","cheapest":{"priceCents":398}}',
      });

      final priced = await enrichReceipt(api, receipt, _location);

      expect(seen.map((u) => u.queryParameters['unit']), ['KG', 'UN']);
      expect(seen.every((u) => u.queryParameters['store'] == 'MUFFATO'), isTrue);
      expect(seen.every((u) => u.queryParameters['raio'] == '15'), isTrue);
      expect(priced.items.map((i) => i.precos!.cheapest!.priceCents), [349, 398]);
      expect(priced.enrichedAt, isNotNull);
      expect(priced.locationCep, '86010000');
    });

    test('an item that fails to price leaves the rest of the nota priced', () async {
      final (api, _, _) = apiFor({
        'LEITE ITALAC 1L': '{"basis":"gtin","confidence":"high","cheapest":{"priceCents":398}}',
      });

      final priced = await enrichReceipt(api, receipt, _location);

      expect(priced.items.first.precos, isNull, reason: 'uncompared, not a crash');
      expect(priced.items.last.precos!.cheapest!.priceCents, 398);
      expect(priced.enrichedAt, isNotNull, reason: 'the pass ran; the item just missed');
    });

    test('the matched NCM is stamped onto the item so classify stops guessing', () async {
      final (api, _, _) = apiFor({
        'BANANA NANICA': '{"ncm":"08039000","cheapest":{"priceCents":349}}',
        'LEITE ITALAC 1L': '{"cheapest":{"priceCents":398}}',
      });

      final priced = await enrichReceipt(api, receipt, _location);

      expect(priced.items.first.ncm, '08039000');
      expect(classify(description: 'BANANA NANICA', ncm: priced.items.first.ncm), Categoria.frutas);
    });

    test('never more than six calls in flight — Menor Preço rate-limits', () async {
      final items = [for (var i = 0; i < 20; i++) leite.copyWith(description: 'ITEM $i')];
      final (api, seen, inFlight) = apiFor({
        for (var i = 0; i < 20; i++) 'ITEM $i': '{"cheapest":{"priceCents":100}}',
      });

      await enrichReceipt(api, receipt.copyWith(items: items), _location);

      expect(seen, hasLength(20));
      expect(inFlight.reduce((a, b) => a > b ? a : b), 6);
    });
  });

  group('mineOffers', () {
    test('keeps dated, identified offers and drops the rest', () {
      const item = ReceiptItem(
        description: 'BANANA NANICA',
        ncm: '08039000',
        unitPriceCents: 499,
        precos: Precos(
          gtin: '7891000100103',
          stores: [
            Offer(priceCents: 349, store: 'Condor', cod: '1', datahora: '2026-07-20T10:00:00Z'),
            Offer(priceCents: 359, store: 'Sem código', datahora: '2026-07-20T10:00:00Z'),
            Offer(priceCents: 369, store: 'Sem data', cod: '3'),
          ],
        ),
      );

      final mined = mineOffers([item, const ReceiptItem(description: 'NADA')]);

      expect(mined, hasLength(1));
      expect(mined.single.cod, '1');
      expect(mined.single.category, Categoria.frutas);
      expect(mined.single.gtin, '7891000100103');
      // Content-derived, so re-scanning the same nota overwrites the sighting
      // instead of doubling that day's weight in a trend.
      expect(mined.single.key, '1|7891000100103|2026-07-20T10:00:00Z|349');
    });
  });

  group('needsPricing', () {
    const receipt = Receipt(accessKey: 'k', enrichedAt: 1, locationCep: '86010000');

    test('an unpriced nota needs pricing', () {
      expect(needsPricing(const Receipt(accessKey: 'k'), _location), isTrue);
    });

    test('a nota priced for this CEP does not', () {
      expect(needsPricing(receipt, _location), isFalse);
    });

    test('a nota priced for somewhere else does', () {
      expect(needsPricing(receipt, _location.copyWith(cep: '80010000')), isTrue);
    });
  });
}
