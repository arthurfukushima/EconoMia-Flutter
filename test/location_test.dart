import 'dart:convert';

import 'package:economia/core/api_client.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/features/location/location_controller.dart';
import 'package:economia/theme/theme.dart';
import 'package:economia/widgets/location_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Prefs> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return Prefs(await SharedPreferences.getInstance());
}

/// Answers every `/api/cep` call with [body], regardless of query.
EconomiaApi _apiReturning(String body, {int status = 200}) => EconomiaApi(
      ApiClient(client: MockClient((_) async => http.Response.bytes(utf8.encode(body), status))),
    );

void main() {
  group('LocationController', () {
    test('setCep resolves and persists, defaulting a fresh raio to 50', () async {
      final prefs = await _prefs();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        economiaApiProvider.overrideWithValue(_apiReturning(
          '{"cep":"86010000","lat":-23.3,"lng":-51.1,"city":"Londrina","state":"Paraná"}',
        )),
      ]);
      addTearDown(container.dispose);

      await container.read(locationControllerProvider.notifier).setCep('86010-000');

      final loc = container.read(locationControllerProvider);
      expect(loc!.city, 'Londrina');
      expect(loc.raio, 50);
      expect(prefs.location!.city, 'Londrina', reason: 'survives a restart');
      expect(container.read(locationErrorProvider), isNull);
    });

    test('an invalid CEP never leaves the device, and the error is pt-BR', () async {
      final prefs = await _prefs();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        economiaApiProvider.overrideWithValue(_apiReturning('{}')),
      ]);
      addTearDown(container.dispose);

      await container.read(locationControllerProvider.notifier).setCep('123');

      expect(container.read(locationControllerProvider), isNull);
      expect(container.read(locationErrorProvider)!.code, 'invalid_cep');
      expect(container.read(locationErrorProvider)!.mensagem, contains('CEP inválido'));
      expect(container.read(locationBusyProvider), isFalse);
    });

    test('setRaio no-ops until a location exists, then persists it', () async {
      final prefs = await _prefs();
      final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);

      await container.read(locationControllerProvider.notifier).setRaio(10);
      expect(container.read(locationControllerProvider), isNull);

      await prefs.setLocation(const AppLocation(lat: -23.3, lng: -51.1, raio: 50));
      container.invalidate(locationControllerProvider);

      await container.read(locationControllerProvider.notifier).setRaio(10);
      expect(container.read(locationControllerProvider)!.raio, 10);
      expect(prefs.location!.raio, 10);
    });
  });

  group('LocationBar', () {
    testWidgets('shows the unset form, then the summary once a CEP is set', (tester) async {
      final prefs = await _prefs();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          economiaApiProvider.overrideWithValue(_apiReturning(
            '{"cep":"86010000","lat":-23.3,"lng":-51.1,"city":"Londrina","state":"Paraná"}',
          )),
        ],
        child: MaterialApp(theme: buildTheme(), home: const Scaffold(body: LocationBar())),
      ));

      expect(find.text('Seu CEP'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsNothing);

      await tester.enterText(find.byType(TextField), '86010000');
      await tester.pump();
      await tester.tap(find.text('Usar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Londrina'), findsOneWidget);
      expect(find.text('Seu CEP'), findsNothing);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });

    testWidgets('a failed lookup shows the pt-BR banner and stays on the form', (tester) async {
      final prefs = await _prefs();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          economiaApiProvider.overrideWithValue(_apiReturning('{"error":"cep_no_coords"}', status: 404)),
        ],
        child: MaterialApp(theme: buildTheme(), home: const Scaffold(body: LocationBar())),
      ));

      await tester.enterText(find.byType(TextField), '86010000');
      await tester.pump();
      await tester.tap(find.text('Usar'));
      await tester.pumpAndSettle();

      expect(find.text('Não encontramos as coordenadas desse CEP. Tente um CEP próximo.'), findsOneWidget);
      expect(find.text('Seu CEP'), findsOneWidget);
    });
  });
}
