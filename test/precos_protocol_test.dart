import 'dart:convert';
import 'dart:io';

import 'package:economia/core/api_client.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// `/api/precos`'s two-step protocol, ported from the backend-integration
/// branch: a GET either serves a cache hit directly or answers
/// `{needsFetch: true}`; on a miss, the device fetches Menor Preço itself
/// (its CORS is wide open, and only the device's own IP dodges the decoy-data
/// problem a serverless egress IP runs into) and POSTs the raw `produtos`
/// back to the same path+query for matching. See EconomiaApi._priceQuery.
///
/// The old contract (a GET that fetched Menor Preço server-side and answered
/// in one round trip) still has to keep working unmodified — data_test.dart
/// pins that — since a cache hit on today's date is exactly that shape.
dynamic fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync());

http.Response _ok(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

const _loc = AppLocation(lat: -23.31, lng: -51.16, raio: 15);

void main() {
  group('the needsFetch → direct fetch → POST dance', () {
    test('happy path: GET says needsFetch, device fetches Menor Preço, POSTs it back', () async {
      final requests = <http.Request>[];
      final produtos = (fixture('menorpreco_produtos') as Map<String, dynamic>)['produtos'];
      final finalResult = {'basis': 'gtin', 'confidence': 'high', 'gtin': '07891000100103', 'cheapest': {'priceCents': 398, 'store': 'CONDOR'}};

      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          requests.add(req);
          if (req.url.host.contains('notaparana')) {
            expect(req.url.queryParameters['gtin'], '7891000100103');
            expect(req.url.queryParameters['local'], '-23.31,-51.16');
            return _ok({'produtos': produtos});
          }
          if (req.method == 'GET') return _ok({'needsFetch': true});
          // POST back to our own backend.
          expect(req.url.host, 'econo-mia-hugo.vercel.app');
          final sent = jsonDecode(req.body) as Map<String, dynamic>;
          expect(sent['produtos'], produtos, reason: 'relayed verbatim, not re-shaped');
          return _ok(finalResult);
        }),
      ));

      final result = await api.lookupProduct('7891000100103', _loc);

      expect(requests, hasLength(3), reason: 'GET (miss) + Menor Preço + POST');
      expect(requests[0].method, 'GET');
      expect(requests[1].url.host, 'menorpreco.notaparana.pr.gov.br');
      expect(requests[2].method, 'POST');
      expect(result.gtin, '07891000100103');
      expect(result.cheapest!.priceCents, 398);
    });

    test('a cache hit never touches Menor Preço or POSTs anything', () async {
      final requests = <http.Request>[];
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          requests.add(req);
          return _ok({'basis': 'desc', 'confidence': 'approx'});
        }),
      ));

      await api.precosForItem(description: 'ARROZ 5KG', location: _loc);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
    });

    test('a description-path miss sends termo, not gtin, to Menor Preço', () async {
      String? seenTermo;
      String? seenGtinKey;
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          if (req.url.host.contains('notaparana')) {
            seenTermo = req.url.queryParameters['termo'];
            seenGtinKey = req.url.queryParameters['gtin'];
            return _ok({'produtos': <dynamic>[]});
          }
          if (req.method == 'GET') return _ok({'needsFetch': true});
          return _ok({'basis': 'desc', 'confidence': 'approx'});
        }),
      ));

      await api.precosForItem(description: 'BANANA NANICA KG', location: _loc);

      expect(seenTermo, 'BANANA NANICA KG');
      expect(seenGtinKey, isNull);
    });

    test('the backend rejecting decoy offers (produtos_implausible) is an ordinary ApiException', () async {
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          if (req.url.host.contains('notaparana')) {
            return _ok({'produtos': (fixture('menorpreco_produtos') as Map<String, dynamic>)['produtos']});
          }
          if (req.method == 'GET') return _ok({'needsFetch': true});
          return http.Response.bytes(utf8.encode('{"error":"produtos_implausible"}'), 502);
        }),
      ));

      await expectLater(
        api.lookupProduct('7891000100103', _loc),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'produtos_implausible')
            .having((e) => e.mensagem, 'mensagem', isNotEmpty)),
      );
    });

    test('Menor Preço itself failing never reaches a POST, and surfaces as menorpreco_failed', () async {
      final requests = <http.Request>[];
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          requests.add(req);
          if (req.url.host.contains('notaparana')) {
            return http.Response('', 500); // upstream down / rate-limited
          }
          return _ok({'needsFetch': true});
        }),
      ));

      await expectLater(
        api.lookupProduct('7891000100103', _loc),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'menorpreco_failed')),
      );
      expect(requests, hasLength(2), reason: 'GET + failed Menor Preço fetch, no POST');
    });

    test('an unparseable Menor Preço body degrades to menorpreco_failed rather than crashing', () async {
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          if (req.url.host.contains('notaparana')) {
            return http.Response('<html>502</html>', 200);
          }
          return _ok({'needsFetch': true});
        }),
      ));

      await expectLater(
        api.lookupProduct('7891000100103', _loc),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'menorpreco_failed')),
      );
    });
  });

  group('searchStores without the retired mode=stores', () {
    test('reads stores off the ordinary description-path result', () async {
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          expect(req.url.queryParameters['mode'], isNull, reason: 'the backend no longer supports it');
          expect(req.url.queryParameters['q'], 'condor');
          return _ok({
            'basis': 'desc',
            'confidence': 'approx',
            'stores': [
              {'cod': '1', 'store': 'CONDOR CENTRO', 'km': 1.1},
            ],
          });
        }),
      ));

      final stores = await api.searchStores('condor', _loc);

      expect(stores.map((s) => s.cod), ['1']);
    });

    test('a failure is swallowed to an empty list, not thrown', () async {
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async => http.Response.bytes(utf8.encode('{"error":"menorpreco_failed"}'), 502)),
      ));

      expect(await api.searchStores('condor', _loc), isEmpty);
    });

    test('goes through the needsFetch dance too, same as any other term', () async {
      final requests = <http.Request>[];
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          requests.add(req);
          if (req.url.host.contains('notaparana')) return _ok({'produtos': <dynamic>[]});
          if (req.method == 'GET') return _ok({'needsFetch': true});
          return _ok({'stores': <dynamic>[]});
        }),
      ));

      await api.searchStores('santarem', _loc);

      expect(requests, hasLength(3));
    });
  });

  group('lookupProductByName ("buscar por nome")', () {
    test('sends a plain description-path query, no gtin', () async {
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          expect(req.url.queryParameters['q'], 'toddy');
          expect(req.url.queryParameters['gtin'], isNull);
          return _ok({
            'basis': 'desc',
            'confidence': 'approx',
            'options': [
              {'key': 'a', 'name': 'TODDY 400G', 'cheapest': {'priceCents': 899}},
              {'key': 'b', 'name': 'TODDY ZERO 380G', 'cheapest': {'priceCents': 950}},
            ],
          });
        }),
      ));

      final result = await api.lookupProductByName('toddy', _loc);

      expect(result.options, hasLength(2));
      expect(result.options.first.name, 'TODDY 400G');
    });
  });

  group('fetchSuggestions', () {
    test('a one-letter term never hits the network', () async {
      var called = false;
      final api = EconomiaApi(ApiClient(client: MockClient((req) async {
        called = true;
        return _ok({'items': <dynamic>[]});
      })));

      expect(await api.fetchSuggestions('a'), isEmpty);
      expect(called, isFalse);
    });

    test('parses the suggestion list', () async {
      final api = EconomiaApi(ApiClient(client: MockClient((req) async {
        expect(req.url.path, '/api/suggest');
        expect(req.url.queryParameters['q'], 'toddy');
        return _ok({'items': ['TODDY 400G', 'TODDY ACHOCOLATADO 200G']});
      })));

      expect(await api.fetchSuggestions('toddy'), ['TODDY 400G', 'TODDY ACHOCOLATADO 200G']);
    });

    test('a failure is swallowed to an empty list', () async {
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async => http.Response.bytes(utf8.encode('{"error":"suggest_failed"}'), 502)),
      ));

      expect(await api.fetchSuggestions('toddy'), isEmpty);
    });
  });

  group('fetchCatalog', () {
    test('parses the market catalog, category filter included when given', () async {
      final api = EconomiaApi(ApiClient(client: MockClient((req) async {
        expect(req.url.path, '/api/catalog');
        expect(req.url.queryParameters['market_codigo'], '1001');
        expect(req.url.queryParameters['category'], 'laticinios');
        return _ok(fixture('catalog_response'));
      })));

      final catalog = await api.fetchCatalog('1001', category: 'laticinios');

      expect(catalog, isNotNull);
      expect(catalog!.items, hasLength(2));
      expect(catalog.items.first.bucket, 'caro');
      expect(catalog.categories['laticinios'], 1);
      expect(CatalogResponse.fromJson(catalog.toJson()), catalog);
    });

    test('category omitted when not given', () async {
      final api = EconomiaApi(ApiClient(client: MockClient((req) async {
        expect(req.url.queryParameters.containsKey('category'), isFalse);
        return _ok({'marketCodigo': '1001', 'items': <dynamic>[], 'categories': <String, dynamic>{}});
      })));

      await api.fetchCatalog('1001');
    });

    test('a failure returns null, not a crash', () async {
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async => http.Response.bytes(utf8.encode('{"error":"catalog_failed"}'), 502)),
      ));

      expect(await api.fetchCatalog('1001'), isNull);
    });
  });
}
