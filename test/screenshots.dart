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
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:economia/features/receipt/receipt_screen.dart';
import 'package:economia/router.dart';
import 'package:economia/theme/theme.dart';
import 'package:economia/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
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

  // ReceiptScreen's two states, pumped directly (no router, no shell): the
  // screen depends on neither, and going through the full app for one screen's
  // shot is exactly the setup LocationBar's own widget test also skips.
  //
  // No location is saved in either, so nothing kicks off a real pricing pass —
  // the priced shot carries prices that are already on the receipt.
  Future<void> receiptShot(WidgetTester tester, Receipt receipt, String name) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    // Sembast's real I/O doesn't resolve under the test binding's fake clock
    // without this escape hatch — same reason font loading above needs it.
    final setUp = await tester.runAsync(() async {
      final repo = ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('$name.db'));
      await repo.saveReceipt(receipt);
      return (repo, Prefs(await SharedPreferences.getInstance()));
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        receiptRepositoryProvider.overrideWithValue(setUp!.$1),
        prefsProvider.overrideWithValue(setUp.$2),
      ],
      child: MaterialApp(theme: buildTheme(), home: ReceiptScreen(accessKey: receipt.accessKey)),
    ));

    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
  }

  // Straight off a scan, before any pricing pass has run.
  testWidgets('shots — receipt, unpriced', (tester) async {
    await receiptShot(
      tester,
      const Receipt(
        accessKey: '41250712345678000190650010000123451987654321',
        header: ReceiptHeader(
          storeName: 'MUFFATO SUPERCENTER',
          city: 'Londrina',
          purchasedAt: '19/07/2026 18:32:10',
          totalCents: 4823,
        ),
        items: [
          ReceiptItem(description: 'LEITE INTEGRAL ITALAC 1L', unit: 'UN', unitPriceCents: 449, lineTotalCents: 2694),
          ReceiptItem(description: 'CAFE PILAO TRADICIONAL 500G', unit: 'UN', unitPriceCents: 1590, lineTotalCents: 1590),
          ReceiptItem(description: 'BANANA NANICA', unit: 'KG', unitPriceCents: 539, lineTotalCents: 539),
        ],
      ),
      'receipt_unpriced',
    );
  });

  // The cheapest-nearby report: savings hero, per-line offers, the "aprox."
  // flag on a description match, a dearer item that appears in neither list,
  // and the uncompared section.
  testWidgets('shots — receipt, priced', (tester) async {
    final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    Precos precos(int cents, String store, String bairro, double km, {String confidence = 'high'}) => Precos(
          basis: confidence == 'high' ? 'gtin' : 'desc',
          confidence: confidence,
          cheapest: Offer(
            priceCents: cents,
            store: store,
            bairro: bairro,
            km: km,
            addr: 'RUA TAPUIAS, 845, $bairro, LONDRINA - PR',
            datahora: ontem,
          ),
        );

    await receiptShot(
      tester,
      Receipt(
        accessKey: '41250712345678000190650010000123451987654322',
        enrichedAt: DateTime.now().millisecondsSinceEpoch,
        locationCep: '86010000',
        header: const ReceiptHeader(
          storeName: 'MUFFATO SUPERCENTER',
          city: 'Londrina',
          purchasedAt: '19/07/2026 18:32:10',
          totalCents: 9468,
        ),
        items: [
          ReceiptItem(
            description: 'LEITE INTEGRAL ITALAC 1L',
            unit: 'UN',
            qty: 6,
            unitPriceCents: 449,
            lineTotalCents: 2694,
            precos: precos(398, 'CONDOR', 'Gleba Palhano', 2.4),
          ),
          ReceiptItem(
            description: 'CAFE PILAO TRADICIONAL 500G',
            unit: 'UN',
            qty: 2,
            unitPriceCents: 1590,
            lineTotalCents: 3180,
            precos: precos(1349, 'SUPER MUFFATO', 'Centro', 1.1),
          ),
          ReceiptItem(
            description: 'BANANA NANICA',
            unit: 'KG',
            qty: 1.235,
            unitPriceCents: 499,
            lineTotalCents: 616,
            precos: precos(349, 'HORTIFRUTI SANTARÉM', 'Vila Casoni', 3.8, confidence: 'approx'),
          ),
          ReceiptItem(
            description: 'FEIJAO CARIOCA KICALDO 1KG',
            unit: 'UN',
            qty: 2,
            unitPriceCents: 849,
            lineTotalCents: 1698,
            precos: precos(879, 'CONDOR', 'Gleba Palhano', 2.4),
          ),
          const ReceiptItem(
            description: 'DETERGENTE YPE NEUTRO 500ML',
            unit: 'UN',
            qty: 4,
            unitPriceCents: 249,
            lineTotalCents: 996,
          ),
          const ReceiptItem(
            description: 'PAO FRANCES',
            unit: 'KG',
            qty: 0.42,
            unitPriceCents: 1290,
            lineTotalCents: 542,
          ),
        ],
      ),
      'receipt_priced',
    );
  });
}
