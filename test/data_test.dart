import 'dart:convert';
import 'dart:io';

import 'package:economia/core/api_client.dart';
import 'package:economia/core/categoria.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';

/// The fixtures are recorded responses from the deployed functions (and, for
/// the receipt, a real enriched Muffato/Londrina nota carried over from the
/// reference implementation) — not hand-written shapes. Provenance is in each
/// file's `_note`.
dynamic fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync());

void main() {
  group('models round-trip the recorded API shapes', () {
    test('/api/cep', () {
      final loc = AppLocation.fromJson(fixture('cep') as Map<String, dynamic>);

      expect(loc.cep, '86010000');
      expect(loc.city, 'Londrina');
      expect(loc.state, 'Paraná', reason: 'the response is UTF-8, not latin-1');
      expect(loc.lat, closeTo(-23.31, 0.01));
      // Neither field is in the response; both are ours and must default.
      expect(loc.raio, 10);
      expect(loc.precise, isFalse);

      expect(AppLocation.fromJson(loc.toJson()), loc);
    });

    test('/api/precos, GTIN path', () {
      final p = Precos.fromJson(fixture('precos_gtin') as Map<String, dynamic>);

      expect(p.basis, 'gtin');
      expect(p.confidence, 'high');
      expect(p.gtin, '07891000100103', reason: 'padded to 14 by the backend');
      expect(p.cheapest!.priceCents, greaterThan(0));
      expect(p.range!.minCents, lessThanOrEqualTo(p.range!.maxCents));
      expect(p.stores, isNotEmpty);
      expect(p.nStores, greaterThan(0));

      expect(Precos.fromJson(p.toJson()), p);
    });

    test('/api/precos, description path', () {
      final p = Precos.fromJson(fixture('precos_desc') as Map<String, dynamic>);

      expect(p.basis, 'desc');
      expect(p.confidence, 'approx');
      expect(p.gtin, isNull, reason: 'no barcode was recovered');
      expect(p.options, isEmpty, reason: 'sent only when there is a real choice');
      expect(p.name, isNotNull);

      expect(Precos.fromJson(p.toJson()), p);
    });

    // The contract detail most likely to be smoothed over: the backend builds
    // `cheapest` without a `cod` while every `stores[]` entry has one. Any code
    // that identifies the cheapest store by `cheapest.cod` compares null.
    test('cheapest arrives without a cod; stores[] always has one', () {
      for (final name in ['precos_gtin', 'precos_desc']) {
        final p = Precos.fromJson(fixture(name) as Map<String, dynamic>);
        expect(p.cheapest!.cod, isNull, reason: name);
        expect(p.stores.every((s) => s.cod != null), isTrue, reason: name);
      }
    });

    test('cod is normalised to a String whatever upstream types it', () {
      expect(Offer.fromJson({'cod': 4821}).cod, '4821');
      expect(Offer.fromJson({'cod': '4821'}).cod, '4821');
      expect(Offer.fromJson(const {}).cod, isNull);
      // The store-search path returns establishments with no price at all.
      expect(Offer.fromJson(const {'store': 'Condor'}).priceCents, 0);
    });

    test('/api/precos?mode=stores yields locations, not offers', () {
      final json = fixture('precos_stores') as Map<String, dynamic>;
      final stores = [
        for (final s in json['stores'] as List)
          Offer.fromJson(s as Map<String, dynamic>),
      ];

      expect(stores, isNotEmpty);
      expect(stores.every((s) => s.cod != null && s.store != null), isTrue);
    });

    test('/api/nfce, enriched', () {
      final receipts = [
        for (final r in fixture('sample-receipts') as List)
          Receipt.fromJson(r as Map<String, dynamic>),
      ];
      final receipt = receipts.first;

      expect(receipt.accessKey.length, 44);
      expect(receipt.header.storeName, 'MUFFATO SUPERCENTER');
      expect(receipt.header.totalCents, 19468);
      expect(receipt.items, isNotEmpty);

      final leite = receipt.items.first;
      expect(leite.gtin, '7898080640017');
      expect(leite.qty, 6);
      expect(leite.unit, 'UN');
      expect(leite.unitPriceCents, 449);
      expect(leite.precos!.cheapest!.priceCents, 398);

      // A produce line the lookup could not match stays uncompared rather than
      // being quietly counted as "no savings here".
      expect(receipt.items.any((i) => i.precos == null), isTrue);

      expect(Receipt.fromJson(receipt.toJson()), receipt);
    });
  });

  group('api client', () {
    /// Answers every request with [body], and records the URI it was asked for.
    (EconomiaApi, List<Uri>) apiReturning(String body, {int status = 200}) {
      final seen = <Uri>[];
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          seen.add(req.url);
          // Bytes, not a String: `http.Response(String, …)` would re-encode.
          return http.Response.bytes(utf8.encode(body), status);
        }),
      ));
      return (api, seen);
    }

    test('decodes as UTF-8 regardless of the response headers', () async {
      final (api, _) = apiReturning(
        '{"cep":"86010000","lat":-23.3,"lng":-51.1,"city":"São Jerônimo","state":"Paraná"}',
      );
      expect((await api.resolveCep('86010-000')).city, 'São Jerônimo');
    });

    test('a bad CEP never leaves the device', () async {
      final (api, seen) = apiReturning('{}');
      await expectLater(
        api.resolveCep('123'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_cep')),
      );
      expect(seen, isEmpty);
    });

    test('an error body becomes its code, and a readable pt-BR message', () async {
      final (api, _) = apiReturning('{"error":"portal_unavailable"}', status: 502);
      await expectLater(
        api.fetchReceipt('x|y'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'portal_unavailable')
            .having((e) => e.mensagem, 'mensagem', contains('SEFAZ-PR'))),
      );
    });

    test('an unparseable body is an error, not a crash', () async {
      final (api, _) = apiReturning('<html>504 Gateway Timeout</html>', status: 504);
      await expectLater(
        api.fetchReceipt('x|y'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'bad_response')),
      );
    });

    test('sends the receipt-line query the backend needs to recover a GTIN', () async {
      final (api, seen) = apiReturning('{"basis":"desc","confidence":"approx"}');
      await api.precosForItem(
        description: 'BANANA NANICA KG',
        unit: 'KG',
        storeName: 'MUFFATO SUPERCENTER',
        city: 'Londrina',
        location: const AppLocation(lat: -23.31, lng: -51.16, raio: 15),
      );

      expect(seen.single.queryParameters, {
        'q': 'BANANA NANICA KG',
        'unit': 'KG',
        'store': 'MUFFATO SUPERCENTER',
        'city': 'Londrina',
        'local': '-23.31,-51.16',
        // Explicit: the backend would otherwise default to 25km silently.
        'raio': '15',
      });
    });

    test('a one-letter store search never hits the network', () async {
      final (api, seen) = apiReturning('{"stores":[]}');
      expect(await api.searchStores('m', const AppLocation(lat: 0, lng: 0)), isEmpty);
      expect(seen, isEmpty);
    });

    test('nearbyStores unions every staple term, deduped, nearest-first', () async {
      final bodies = {
        'arroz': '{"stores":[{"cod":"1","store":"CONDOR","km":2.4},{"cod":"2","store":"MUFFATO","km":1.1}]}',
        'farinha': '{"stores":[{"cod":"2","store":"MUFFATO","km":1.1},{"cod":"3","store":"SANTAREM","km":3.8}]}',
        'leite': '{"stores":[]}',
        'cafe': '{"error":"menorpreco_failed"}',
        'detergente': '{"stores":[]}',
      };
      final seen = <Uri>[];
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          seen.add(req.url);
          final body = bodies[req.url.queryParameters['q']]!;
          return http.Response.bytes(
            utf8.encode(body),
            body.contains('error') ? 502 : 200,
          );
        }),
      ));

      final stores = await api.nearbyStores(
        const AppLocation(lat: -23.31, lng: -51.16, raio: 15),
      );

      expect(seen, hasLength(5), reason: 'one call per staple term');
      expect(stores.map((s) => s.cod), ['2', '1', '3'], reason: 'deduped, nearest-first');
      expect(seen.every((u) => u.queryParameters['raio'] == '15'), isTrue);
    });

    test('a precise (GPS) fix narrows the seeding radius to 2km', () async {
      final seen = <Uri>[];
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          seen.add(req.url);
          return http.Response.bytes(utf8.encode('{"stores":[]}'), 200);
        }),
      ));

      await api.nearbyStores(const AppLocation(lat: 0, lng: 0, raio: 50, precise: true));

      expect(seen.every((u) => u.queryParameters['raio'] == '2'), isTrue);
    });
  });

  group('repository', () {
    late ReceiptRepository repo;

    setUp(() async {
      repo = ReceiptRepository(
        await newDatabaseFactoryMemory().openDatabase('test.db'),
      );
    });

    Receipt receipt(String key) => Receipt(
          accessKey: key,
          header: const ReceiptHeader(storeName: 'Muffato', totalCents: 1000),
          items: const [ReceiptItem(description: 'ARROZ 5KG', lineTotalCents: 1000)],
        );

    test('saves, stamps createdAt, and reads back whole', () async {
      final saved = await repo.saveReceipt(receipt('a' * 44));

      expect(saved.createdAt, isNotNull);
      expect(await repo.getReceipt('a' * 44), saved);
      expect(await repo.getReceipt('nope'), isNull);
    });

    test('re-saving the same nota overwrites it and keeps its createdAt', () async {
      final first = await repo.saveReceipt(receipt('b' * 44));
      final priced = await repo.saveReceipt(first.copyWith(enrichedAt: 123));

      expect(priced.createdAt, first.createdAt);
      expect((await repo.listReceipts()).length, 1);
      expect((await repo.getReceipt('b' * 44))!.enrichedAt, 123);
    });

    test('lists newest first', () async {
      await repo.saveReceipt(receipt('c' * 44).copyWith(createdAt: 100));
      await repo.saveReceipt(receipt('d' * 44).copyWith(createdAt: 300));
      await repo.saveReceipt(receipt('e' * 44).copyWith(createdAt: 200));

      expect(
        (await repo.listReceipts()).map((r) => r.createdAt),
        [300, 200, 100],
      );
    });

    const obs = PriceObservation(
      cod: '4821',
      store: 'Condor',
      category: Categoria.laticinios,
      gtin: '7898080640017',
      priceCents: 398,
      datahora: '2026-07-21T09:12:00',
    );

    test('offers dedup on re-scan but keep genuinely different sightings', () async {
      await repo.saveOffers([obs, obs, obs.copyWith(priceCents: 415)]);
      await repo.saveOffers([obs]); // the same receipt, scanned again

      final stored = await repo.listOffers();
      expect(stored.length, 2);
      expect(stored.map((o) => o.priceCents).toSet(), {398, 415});
      expect(stored.first.category, Categoria.laticinios);
    });

    test('a priceless or undated sighting never enters the medians', () async {
      await repo.saveOffers([
        obs.copyWith(priceCents: 0),
        obs.copyWith(datahora: ''),
      ]);
      expect(await repo.listOffers(), isEmpty);
    });

    test('clearing history takes the mined offers with it', () async {
      await repo.saveReceipt(receipt('f' * 44));
      await repo.saveOffers([obs]);

      await repo.clearAll();

      expect(await repo.listReceipts(), isEmpty);
      expect(await repo.listOffers(), isEmpty);
    });
  });
}
