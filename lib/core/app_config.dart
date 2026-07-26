import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every host, endpoint and tuning knob that differs between machines, people
/// or deployments — loaded from JSON at startup instead of being hardcoded in
/// the file that happens to use it.
///
/// **Two files, base + override:**
///
/// | File | Committed? | Role |
/// |---|---|---|
/// | `assets/config/app_config.json` | yes | the defaults everyone gets |
/// | `assets/config/app_config.local.json` | **no** (gitignored) | your machine's overrides |
///
/// The local file is optional and merged *over* the base one section by
/// section, so it only has to name what actually differs — the usual case
/// being a single `{"api": {"baseUrl": "…"}}`. Copy
/// `app_config.local.example.json` to get started.
///
/// Every field also has a compile-time default in [AppConfig.fallback], so a
/// missing key, a missing file, or a test that never loads anything at all
/// still gets a working config rather than a crash.
class AppConfig {
  const AppConfig({
    this.api = const ApiConfig(),
    this.menorPreco = const MenorPrecoConfig(),
    this.openFoodFacts = const OpenFoodFactsConfig(),
    this.maps = const MapsConfig(),
    this.pricing = const PricingConfig(),
  });

  /// Our own serverless backend (`/api/cep`, `/api/nfce`, `/api/precos`,
  /// `/api/suggest`, `/api/catalog`).
  final ApiConfig api;

  /// The Menor Preço / Nota Paraná upstream, which the **device** calls
  /// directly rather than through our backend.
  final MenorPrecoConfig menorPreco;

  /// Open Food Facts, for nutrition — wholly independent of the pricing spine.
  final OpenFoodFactsConfig openFoodFacts;
  final MapsConfig maps;
  final PricingConfig pricing;

  /// What you get with no JSON at all: the committed defaults, in code. Tests
  /// and any provider that was never overridden read this.
  static const fallback = AppConfig();

  static const _baseAsset = 'assets/config/app_config.json';
  static const _localAsset = 'assets/config/app_config.local.json';

  /// Reads the base config, then merges the optional per-machine override over
  /// it. Neither file existing is fine — that is [fallback].
  ///
  /// A malformed JSON file is deliberately **not** swallowed: a typo in your
  /// own config should say so at launch, not silently point the app at the
  /// wrong backend and look like a server outage an hour later.
  static Future<AppConfig> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final base = await _readAsset(assets, _baseAsset);
    final local = await _readAsset(assets, _localAsset);
    if (base == null && local == null) return fallback;
    return AppConfig.fromJson(_merge(base ?? const {}, local ?? const {}));
  }

  /// Null when the asset simply isn't bundled (no local override, say);
  /// throws when it is there but unreadable as JSON.
  static Future<Map<String, dynamic>?> _readAsset(AssetBundle bundle, String key) async {
    final String raw;
    try {
      raw = await bundle.loadString(key);
    } catch (_) {
      return null; // not bundled
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('$key is not valid JSON: $e');
    }
  }

  /// One level deep: a section named by the override replaces only the keys it
  /// names, not the whole section. Config is two levels by design, so this
  /// needs no general-purpose deep merge.
  static Map<String, dynamic> _merge(Map<String, dynamic> base, Map<String, dynamic> over) {
    final out = <String, dynamic>{...base};
    for (final entry in over.entries) {
      final existing = out[entry.key];
      final incoming = entry.value;
      out[entry.key] = existing is Map<String, dynamic> && incoming is Map<String, dynamic>
          ? {...existing, ...incoming}
          : incoming;
    }
    return out;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> section(String name) =>
        (json[name] as Map<String, dynamic>?) ?? const {};
    return AppConfig(
      api: ApiConfig.fromJson(section('api')),
      menorPreco: MenorPrecoConfig.fromJson(section('menorPreco')),
      openFoodFacts: OpenFoodFactsConfig.fromJson(section('openFoodFacts')),
      maps: MapsConfig.fromJson(section('maps')),
      pricing: PricingConfig.fromJson(section('pricing')),
    );
  }
}

/// Our own backend. [baseUrl] is the one field that genuinely differs per
/// person: each dev deploys their own Vercel project, and the bare
/// `econo-mia.vercel.app` belongs to a different account than
/// `econo-mia-hugo.vercel.app`.
class ApiConfig {
  const ApiConfig({
    this.baseUrl = 'https://econo-mia-hugo.vercel.app',
    this.timeoutSeconds = 45,
  });

  final String baseUrl;

  /// Long, but bounded: a cache-miss price lookup does real upstream work, and
  /// an unbounded request is a spinner that never stops.
  final int timeoutSeconds;

  Duration get timeout => Duration(seconds: timeoutSeconds);

  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
        baseUrl: _str(json, 'baseUrl', const ApiConfig().baseUrl),
        timeoutSeconds: _int(json, 'timeoutSeconds', const ApiConfig().timeoutSeconds),
      );
}

/// The upstream price source. Called from the device, never proxied: its own
/// CORS is wide open, and only a residential/mobile IP dodges the fabricated
/// decoy data a serverless egress IP is fed.
class MenorPrecoConfig {
  const MenorPrecoConfig({
    this.baseUrl = 'https://menorpreco.notaparana.pr.gov.br/api/v1/produtos',
    this.timeoutSeconds = 30,
  });

  final String baseUrl;
  final int timeoutSeconds;

  Duration get timeout => Duration(seconds: timeoutSeconds);

  factory MenorPrecoConfig.fromJson(Map<String, dynamic> json) => MenorPrecoConfig(
        baseUrl: _str(json, 'baseUrl', const MenorPrecoConfig().baseUrl),
        timeoutSeconds: _int(json, 'timeoutSeconds', const MenorPrecoConfig().timeoutSeconds),
      );
}

class OpenFoodFactsConfig {
  const OpenFoodFactsConfig({
    this.baseUrl = 'https://world.openfoodfacts.org/api/v2/product',
    this.timeoutSeconds = 15,
  });

  final String baseUrl;
  final int timeoutSeconds;

  Duration get timeout => Duration(seconds: timeoutSeconds);

  factory OpenFoodFactsConfig.fromJson(Map<String, dynamic> json) => OpenFoodFactsConfig(
        baseUrl: _str(json, 'baseUrl', const OpenFoodFactsConfig().baseUrl),
        timeoutSeconds: _int(json, 'timeoutSeconds', const OpenFoodFactsConfig().timeoutSeconds),
      );
}

/// Where a store address opens. Swappable because "the maps app" is a
/// per-person preference, not a fact about the data.
class MapsConfig {
  const MapsConfig({this.searchUrl = 'https://www.google.com/maps/search/?api=1&query={query}'});

  /// `{query}` is replaced with the URL-encoded address.
  final String searchUrl;

  Uri uriFor(String address) =>
      Uri.parse(searchUrl.replaceAll('{query}', Uri.encodeQueryComponent(address)));

  factory MapsConfig.fromJson(Map<String, dynamic> json) =>
      MapsConfig(searchUrl: _str(json, 'searchUrl', const MapsConfig().searchUrl));
}

/// Request pacing and the store-discovery seed. Menor Preço rate-limits, and a
/// 429 is an item that comes back silently unpriced — so these are the knobs
/// worth turning when a region misbehaves, without a rebuild of anyone's
/// mental model of the pricing code.
class PricingConfig {
  const PricingConfig({
    this.receiptConcurrency = 6,
    this.listConcurrency = 3,
    this.storeSeedConcurrency = 3,
    this.seedStaples = const ['arroz', 'farinha', 'leite', 'cafe', 'detergente'],
    this.preciseSeedRadiusKm = 2,
  });

  /// Six in flight for a whole nota…
  final int receiptConcurrency;

  /// …but three for a shopping list: a long list at once earns 429s.
  final int listConcurrency;
  final int storeSeedConcurrency;

  /// Everyday terms whose `stores[]` union stands in for the store directory
  /// Menor Preço doesn't have. One term alone misses real nearby markets.
  final List<String> seedStaples;

  /// A precise (GPS) fix narrows seeding to this radius so the upstream's
  /// ~50-offer relevance page isn't saturated by a whole city.
  final int preciseSeedRadiusKm;

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    const d = PricingConfig();
    final staples = json['seedStaples'];
    return PricingConfig(
      receiptConcurrency: _int(json, 'receiptConcurrency', d.receiptConcurrency),
      listConcurrency: _int(json, 'listConcurrency', d.listConcurrency),
      storeSeedConcurrency: _int(json, 'storeSeedConcurrency', d.storeSeedConcurrency),
      seedStaples: staples is List && staples.isNotEmpty
          ? [for (final s in staples) '$s']
          : d.seedStaples,
      preciseSeedRadiusKm: _int(json, 'preciseSeedRadiusKm', d.preciseSeedRadiusKm),
    );
  }
}

String _str(Map<String, dynamic> json, String key, String fallback) {
  final v = json[key];
  return v is String && v.trim().isNotEmpty ? v.trim() : fallback;
}

int _int(Map<String, dynamic> json, String key, int fallback) {
  final v = json[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return fallback;
}

/// Overridden in `main()` with the loaded JSON. Defaults to [AppConfig.fallback]
/// rather than throwing, so a widget test that never loads config still runs —
/// the compile-time defaults *are* a valid config, not a placeholder.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fallback);
