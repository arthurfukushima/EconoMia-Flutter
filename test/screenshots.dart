// Renders screens to PNGs under test/shots/ so the UI can be eyeballed without
// an emulator or a device attached.
//
//   flutter test test/screenshots.dart --update-goldens
//
// Deliberately *not* named `*_test.dart`: `flutter test` skips it, so these
// never become brittle pixel assertions that fail on every intended redesign.
// The output is gitignored. Add a shot per screen as each phase lands.
import 'dart:convert';

import 'package:economia/app.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/router.dart';
import 'package:economia/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  const files = {
    'Fredoka': 'assets/fonts/Fredoka.ttf',
    'Baloo2': 'assets/fonts/Baloo2.ttf',
    'Nunito': 'assets/fonts/Nunito.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final e in files.entries) {
    final loader = FontLoader(e.key)..addFont(rootBundle.load(e.value));
    await loader.load();
  }
}

void main() {
  testWidgets('shots', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = Prefs(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const EconoMiaApp(),
    ));

    // Image decoding is real async work, which pump() alone won't wait for.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/splash.png'));

    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/home.png'));

    await tester.tap(find.descendant(of: find.byType(BottomNav), matching: find.text('Escanear')));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/scan_chooser.png'));

    router.go('/resumo');
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/resumo.png'));
  });

  // A second boot with a location already on disk — the LocationBar's other
  // real state (§ honesty rule: every block has a real state *and* an empty
  // one; home.png above is the empty one).
  testWidgets('shots — location set', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'economia.location': jsonEncode(const AppLocation(
        lat: -23.31,
        lng: -51.16,
        cep: '86010000',
        city: 'Londrina',
        state: 'Paraná',
        raio: 15,
      ).toJson()),
    });
    final prefs = Prefs(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const EconoMiaApp(),
    ));

    router.go('/');
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/home_location_set.png'));
  });
}
