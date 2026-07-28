import 'dart:convert';
import 'dart:io';

import 'package:economia/core/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bundle holding only the assets a test names, so "the local override
/// isn't on this machine" is expressible — that's the default case for
/// everyone who hasn't written one.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('asset not bundled: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

const _base = 'assets/config/app_config.json';
const _local = 'assets/config/app_config.local.json';

void main() {
  group('defaults', () {
    test('no config at all is still a working config, not a crash', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {}));

      expect(config.api.baseUrl, AppConfig.fallback.api.baseUrl);
      expect(config.pricing.receiptConcurrency, 6);
      expect(config.pricing.listConcurrency, 3);
      expect(config.menorPreco.baseUrl, contains('notaparana'));
    });

    test('a key the JSON omits keeps its built-in default', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {
        _base: '{"api": {"baseUrl": "https://example.test"}}',
      }));

      expect(config.api.baseUrl, 'https://example.test');
      expect(config.api.timeoutSeconds, 45, reason: 'not named, so unchanged');
      expect(config.pricing.seedStaples, hasLength(5));
    });

    test('an empty or blank string is not a value — it falls back', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {
        _base: '{"api": {"baseUrl": "   "}}',
      }));

      expect(config.api.baseUrl, AppConfig.fallback.api.baseUrl);
    });
  });

  group('the local override', () {
    test('replaces only the keys it names, section by section', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {
        _base: '''
        {
          "api": {"baseUrl": "https://econo-mia-hugo.vercel.app", "timeoutSeconds": 45},
          "pricing": {"receiptConcurrency": 6, "listConcurrency": 3}
        }''',
        _local: '{"api": {"baseUrl": "https://econo-mia.vercel.app"}}',
      }));

      expect(config.api.baseUrl, 'https://econo-mia.vercel.app', reason: 'overridden');
      expect(config.api.timeoutSeconds, 45, reason: 'same section, not named → survives');
      expect(config.pricing.receiptConcurrency, 6, reason: 'untouched section');
    });

    test('can override a section the base file never mentions', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {
        _base: '{"api": {"baseUrl": "https://a.test"}}',
        _local: '{"menorPreco": {"timeoutSeconds": 90}}',
      }));

      expect(config.menorPreco.timeoutSeconds, 90);
      expect(config.api.baseUrl, 'https://a.test');
    });

    test('works with no base file at all — override straight onto the defaults', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {
        _local: '{"api": {"baseUrl": "https://solo.test"}}',
      }));

      expect(config.api.baseUrl, 'https://solo.test');
      expect(config.pricing.receiptConcurrency, 6);
    });
  });

  group('malformed input', () {
    // Deliberately loud: a typo in your own config must not read as a server
    // outage an hour later.
    test('invalid JSON throws, naming the file', () async {
      await expectLater(
        AppConfig.load(bundle: _FakeBundle(const {_base: '{"api": '})),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(_base))),
      );
    });

    test('an empty seedStaples list falls back rather than disabling discovery', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {
        _base: '{"pricing": {"seedStaples": []}}',
      }));

      expect(config.pricing.seedStaples, isNotEmpty);
    });
  });

  group('derived values', () {
    test('seconds become Durations', () async {
      final config = await AppConfig.load(bundle: _FakeBundle(const {
        _base: '{"api": {"timeoutSeconds": 12}, "openFoodFacts": {"timeoutSeconds": 7}}',
      }));

      expect(config.api.timeout, const Duration(seconds: 12));
      expect(config.openFoodFacts.timeout, const Duration(seconds: 7));
    });

    test('the maps template URL-encodes the address into {query}', () {
      const maps = MapsConfig();
      final uri = maps.uriFor('RUA TAPUIAS, 845, VILA CASONI, LONDRINA - PR');

      expect(uri.queryParameters['query'], 'RUA TAPUIAS, 845, VILA CASONI, LONDRINA - PR');
      expect(uri.host, 'www.google.com');
    });

    test('a custom maps template is honoured', () {
      const maps = MapsConfig(searchUrl: 'https://maps.apple.com/?q={query}');

      expect(maps.uriFor('Centro, Londrina').toString(), contains('maps.apple.com'));
      expect(maps.uriFor('Centro, Londrina').queryParameters['q'], 'Centro, Londrina');
    });
  });

  // The committed file is what a fresh clone runs on, so a typo in it breaks
  // everyone — parse the real thing, not a fixture of it.
  group('the committed assets/config/app_config.json', () {
    test('parses, and every section it names is well-formed', () {
      final raw = File(_base).readAsStringSync();
      final config = AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      expect(config.api.baseUrl, startsWith('https://'));
      expect(config.menorPreco.baseUrl, startsWith('https://'));
      expect(config.openFoodFacts.baseUrl, startsWith('https://'));
      expect(config.maps.searchUrl, contains('{query}'));
      expect(config.pricing.receiptConcurrency, greaterThan(0));
      expect(config.pricing.seedStaples, isNotEmpty);
    });

    test('the .local example parses too — it is what people copy', () {
      final raw = File('assets/config/app_config.local.example.json').readAsStringSync();
      final config = AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      expect(config.api.baseUrl, startsWith('https://'));
    });
  });
}
