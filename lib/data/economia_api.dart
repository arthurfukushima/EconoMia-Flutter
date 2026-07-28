import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/pooled.dart';
import 'models/app_location.dart';
import 'models/catalog.dart';
import 'models/precos.dart';
import 'models/receipt.dart';

final economiaApiProvider = Provider<EconomiaApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final client = ApiClient(config: config.api);
  ref.onDispose(client.close);
  return EconomiaApi(client, config: config);
});

/// The deployed functions, typed.
///
/// Every method here is a thin shape over one or two calls. The parsing,
/// scraping and matching all happen server-side (`/api/precos`'s matching) or
/// upstream (Menor Preço) — this file's job is to send the right query
/// parameters, do the one client-side fetch `/api/precos` can't safely do
/// itself, and hand back a model.
class EconomiaApi {
  EconomiaApi(this._client, {AppConfig? config}) : config = config ?? AppConfig.fallback;

  final ApiClient _client;

  /// Read by the pricing passes that fan out over this API — receipt
  /// enrichment and the shopping list each pool at their own configured
  /// concurrency rather than hardcoding one.
  final AppConfig config;

  /// `/api/nfce` — a signed QR payload becomes a receipt.
  ///
  /// [p] must be the **whole** payload from the QR
  /// (`chave|versão|tpAmb|hash`), not the bare 44-digit chave. A bare chave
  /// passes validation and
  /// then SEFAZ answers with a summary page that has no items at all.
  Future<Receipt> fetchReceipt(String p) async =>
      Receipt.fromJson(await _client.getJson('/api/nfce', {'p': p}));

  /// `/api/cep` — a CEP becomes a search centre.
  ///
  /// The 8-digit check is done here rather than left to the backend so a typo
  /// costs no round trip and reports the same `invalid_cep` code either way.
  Future<AppLocation> resolveCep(String cep) async {
    final clean = cep.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 8) throw const ApiException('invalid_cep');
    return AppLocation.fromJson(
      await _client.getJson('/api/cep', {'cep': clean}),
    );
  }

  /// `/api/cep` in reverse — GPS coordinates become a city/CEP label.
  ///
  /// The label is cosmetic; pricing uses the raw coordinates, which is why they
  /// are re-stamped onto the result rather than trusted back from the geocoder.
  /// A throw here means "no label" and callers should keep the fix anyway.
  Future<AppLocation> resolveCoords(double lat, double lng) async {
    final json = await _client.getJson('/api/cep', {
      'lat': '$lat',
      'lng': '$lng',
    });
    return AppLocation.fromJson(json)
        .copyWith(lat: lat, lng: lng, precise: true);
  }

  /// `/api/precos`, description path — what a receipt line costs nearby.
  ///
  /// [storeName] and [city] are what let the backend recover a GTIN: a store's
  /// description of a product only maps to a barcode *within that store*, so
  /// without them a produce line stays an approximate token match.
  Future<Precos> precosForItem({
    required String description,
    required AppLocation location,
    String? unit,
    String? storeName,
    String? city,
  }) async =>
      Precos.fromJson(await _priceQuery({
        'q': description,
        'unit': unit ?? '',
        'store': storeName ?? '',
        'city': city ?? '',
        'local': '${location.lat},${location.lng}',
        'raio': '${location.raio}',
      }));

  /// `/api/precos`, GTIN path — a scanned barcode is the product's identity, so
  /// no description recovery is needed and confidence is always `high`.
  Future<Precos> lookupProduct(String gtin, AppLocation location) async =>
      Precos.fromJson(await _priceQuery({
        'gtin': gtin,
        'local': '${location.lat},${location.lng}',
        'raio': '${location.raio}',
      }));

  /// `/api/precos`, description path — a typed product name instead of a
  /// scanned barcode ("buscar por nome"). A vague term ("Leite") can turn up
  /// several real products; [Precos.options] carries them when there is a
  /// real choice to make, same shape [precosForItem] returns for a receipt
  /// line.
  Future<Precos> lookupProductByName(String name, AppLocation location) async =>
      Precos.fromJson(await _priceQuery({
        'q': name,
        'local': '${location.lat},${location.lng}',
        'raio': '${location.raio}',
      }));

  /// `/api/suggest` — autocomplete for a typed product name.
  ///
  /// Suggestions come only from the backend's own persisted catalog (offers
  /// it has already seen), never a live Menor Preço hit — typing must not
  /// fire an upstream search per keystroke. A failure here is simply no
  /// suggestions, not an error the user needs to see.
  Future<List<String>> fetchSuggestions(String term) async {
    if (term.trim().length < 2) return const [];
    try {
      final json = await _client.getJson('/api/suggest', {'q': term.trim()});
      return [for (final s in (json['items'] as List? ?? const [])) s as String];
    } on ApiException {
      return const [];
    }
  }

  /// `/api/catalog` — everything the backend has cached for one market,
  /// browsable without scanning a single item first. Backed by the same
  /// offers `/api/precos` persists on every lookup (see api/lib/rawprices.js
  /// upstream), so it fills in only as products get priced nearby — a market
  /// nobody has scanned at yet answers with an empty catalog, not an error.
  Future<CatalogResponse?> fetchCatalog(String marketCodigo, {String? category}) async {
    final query = {'market_codigo': marketCodigo, 'category': ?category};
    try {
      final json = await _client.getJson('/api/catalog', query);
      return CatalogResponse.fromJson(json);
    } on ApiException {
      return null;
    }
  }

  /// `/api/precos?mode=stores` — the establishments a search term surfaced.
  ///
  /// Menor Preço has no store directory, so the only way to find a market by
  /// name is to search a term and keep the establishments that come back.
  /// These carry no price: they are locations, not offers.
  ///
  /// The backend's own `mode=stores` (a raw, match-independent establishment
  /// dump) was retired server-side in the backend-integration port — the
  /// reference client dropped the live name-search UI entirely in favour of
  /// [nearbyStores]'s seed+merge. Flutter keeps a live search box (Mercado and
  /// Lista's "preços em" picker), so this reads `stores` off the ordinary
  /// description-path result instead — the same field [nearbyStores] already
  /// reads per staple term. The one behaviour difference: a term whose
  /// matching guards (unit/species/size/category — see the backend's
  /// `candidatesFor`) reject every offer at a real nearby store now returns
  /// that store's name as "no results" rather than "found, no price" for this
  /// term; searching a second term (or a staple) still surfaces it.
  Future<List<Offer>> searchStores(String query, AppLocation location) async {
    final term = query.trim();
    if (term.length < 2) return const [];
    try {
      final json = await _priceQuery({
        'q': term,
        'local': '${location.lat},${location.lng}',
        'raio': '${location.raio}',
      });
      return [
        for (final s in (json['stores'] as List? ?? const []))
          Offer.fromJson(s as Map<String, dynamic>),
      ];
    } on ApiException {
      return const [];
    }
  }

  /// `/api/precos` seeded from `pricing.seedStaples` (description path) —
  /// the nearby markets to pick from before any product has been scanned,
  /// nearest-first. Reads each term's `stores[]` (best price per store for
  /// that product), the same field a receipt line's pricing call gets; it
  /// isn't `mode=stores` name-search, which would need a store name to
  /// search *for* rather than discover one.
  ///
  /// A precise (GPS) fix narrows the radius so the relevance page isn't
  /// saturated by a whole city — nearby markets surface instead of being
  /// buried under it.
  /// ponytail: `preciseSeedRadiusKm` assumes under ~50 offers/term inside it;
  /// widen it in config if a dense area still misses stores.
  Future<List<Offer>> nearbyStores(AppLocation location) async {
    final raio = location.precise ? config.pricing.preciseSeedRadiusKm : location.raio;
    final pages = await pooled(config.pricing.seedStaples, config.pricing.storeSeedConcurrency, (term) async {
      try {
        final json = await _priceQuery({
          'q': term,
          'local': '${location.lat},${location.lng}',
          'raio': '$raio',
        });
        return [
          for (final s in (json['stores'] as List? ?? const []))
            Offer.fromJson(s as Map<String, dynamic>),
        ];
      } on ApiException {
        return const <Offer>[];
      }
    });

    final byCod = <String, Offer>{};
    for (final page in pages) {
      for (final s in page) {
        if (s.cod != null) byCod.putIfAbsent(s.cod!, () => s);
      }
    }
    final list = byCod.values.toList()
      ..sort((a, b) => (a.km ?? double.infinity).compareTo(b.km ?? double.infinity));
    return list;
  }

  /// `/api/precos`'s two-step protocol: a GET serves a cache hit directly; a
  /// cache miss answers `{needsFetch: true}` rather than the backend fetching
  /// Menor Preço itself (see [_menorPrecoUrl]'s doc comment for why). On a
  /// miss, this fetches the upstream itself and POSTs the raw `produtos` back
  /// to the same path+query for matching — the backend rejects anything
  /// naming a non-PR store as decoy data (`produtos_implausible`) and that
  /// arrives here as an ordinary [ApiException], same as any other failure.
  ///
  /// [params] carries every query parameter both the GET and the POST need
  /// (`q`/`gtin`, `unit`, `store`, `city`, `local`, `raio`) — the backend
  /// reads `q`/`gtin`/`local`/`raio` off the query string on both verbs, and
  /// `unit`/`store`/`city` off the POST body (mirrored into the query too, so
  /// a GET cache hit already has what it needs).
  Future<Map<String, dynamic>> _priceQuery(Map<String, String> params) async {
    final data = await _client.getJson('/api/precos', params);
    if (data['needsFetch'] != true) return data;

    final produtos = await _fetchMenorPrecoDirect(params);
    if (produtos == null) {
      throw const ApiException('menorpreco_failed', detail: 'client_fetch_failed');
    }
    return _client.postJson('/api/precos', params, {
      'produtos': produtos,
      'unit': params['unit'] ?? '',
      'store': params['store'] ?? '',
      'city': params['city'] ?? '',
    });
  }

  /// The one live call to Menor Preço (`menorPreco.baseUrl`), made from the
  /// device rather than relayed through our backend.
  ///
  /// Nota Paraná covers PR stores only, and Vercel's serverless egress IP gets
  /// fed fabricated decoy data by menorpreco.notaparana.pr.gov.br (garbled
  /// store names, wrong states — looks like real JSON, not an outright block);
  /// a device's own residential/mobile IP doesn't hit this. So `/api/precos`
  /// never fetches Menor Preço itself: a cache miss answers
  /// `{needsFetch: true}` and the device fetches this URL directly, then POSTs
  /// the raw `produtos` back for the backend to match/persist/cache (see
  /// [_priceQuery]). Its CORS is wide open (`Access-Control-Allow-Origin: *`),
  /// so this works unmodified on Flutter Web too.
  ///
  /// Swallows every failure and returns null rather than throwing: the
  /// backend's own upstream fetch (src/lib/precos.js's
  /// `fetchMenorPrecoDirect`) has the same posture, and the caller here turns
  /// a null into the ordinary `menorpreco_failed` [ApiException] every other
  /// failure already reaches callers as.
  Future<List<dynamic>?> _fetchMenorPrecoDirect(Map<String, String> params) async {
    final gtin = params['gtin'];
    final query = <String, String>{
      'local': params['local'] ?? '',
      'raio': params['raio'] ?? '',
      'offset': '0',
    };
    if (gtin != null && gtin.isNotEmpty) {
      query['gtin'] = gtin;
    } else {
      query['termo'] = params['q'] ?? '';
    }
    final uri = Uri.parse(config.menorPreco.baseUrl).replace(queryParameters: query);
    try {
      final res = await _client.getExternal(uri, timeout: config.menorPreco.timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data is Map ? data['produtos'] as List? : null;
    } catch (_) {
      return null;
    }
  }
}
