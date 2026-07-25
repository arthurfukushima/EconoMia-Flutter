import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import 'models/app_location.dart';
import 'models/precos.dart';
import 'models/receipt.dart';

final economiaApiProvider = Provider<EconomiaApi>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return EconomiaApi(client);
});

/// The three deployed functions, typed.
///
/// Every method here is a thin shape over one GET. The parsing, scraping and
/// matching all happen server-side; this file's whole job is to send the right
/// query parameters and hand back a model.
class EconomiaApi {
  EconomiaApi(this._client);

  final ApiClient _client;

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
      Precos.fromJson(await _client.getJson('/api/precos', {
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
      Precos.fromJson(await _client.getJson('/api/precos', {
        'gtin': gtin,
        'local': '${location.lat},${location.lng}',
        'raio': '${location.raio}',
      }));

  /// `/api/precos?mode=stores` — the establishments a search term surfaced.
  ///
  /// Menor Preço has no store directory, so the only way to find a store by
  /// name is to search for a term and keep the distinct establishments that
  /// come back. These carry no price: they are locations, not offers.
  Future<List<Offer>> searchStores(String query, AppLocation location) async {
    final term = query.trim();
    if (term.length < 2) return const [];
    final json = await _client.getJson('/api/precos', {
      'q': term,
      'mode': 'stores',
      'local': '${location.lat},${location.lng}',
      'raio': '${location.raio}',
    });
    return [
      for (final s in (json['stores'] as List? ?? const []))
        Offer.fromJson(s as Map<String, dynamic>),
    ];
  }
}
