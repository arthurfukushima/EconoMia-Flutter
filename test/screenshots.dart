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
import 'package:economia/core/api_client.dart';
import 'package:economia/core/categoria.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/data/off_api.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:economia/features/produto/produto_screen.dart';
import 'package:economia/features/receipt/receipt_screen.dart';
import 'package:economia/router.dart';
import 'package:economia/theme/theme.dart';
import 'package:economia/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
    final repo = await tester.runAsync(
      () async => ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('shots_home.db')),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        receiptRepositoryProvider.overrideWithValue(repo!),
      ],
      child: const EconoMiaApp(),
    ));

    // Image decoding is real async work, which pump() alone won't wait for.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/splash.png'));

    await tester.pumpAndSettle();
    // No receipts in this repo — Home's hero is in its onboarding state.
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
    final repo = await tester.runAsync(
      () async => ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('shots_home_location.db')),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        receiptRepositoryProvider.overrideWithValue(repo!),
      ],
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
  // and the uncompared section. Also carries `precos.stores[]` on most lines,
  // which is what makes the store picker (Phase 5) appear — CONDOR (cod '1')
  // is priced on four of the six items, including one it's dearer on, so the
  // single-store basket shot below has both a green and a red delta to show.
  Receipt pricedSample() {
    final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    Precos precos(
      int cents,
      String store,
      String bairro,
      double km, {
      String confidence = 'high',
      List<Offer> stores = const [],
    }) =>
        Precos(
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
          stores: stores,
        );
    Offer at(String cod, int cents, String store, String bairro, double km) => Offer(
          cod: cod,
          priceCents: cents,
          store: store,
          bairro: bairro,
          km: km,
          datahora: ontem,
        );

    return Receipt(
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
          precos: precos(
            398,
            'CONDOR',
            'Gleba Palhano',
            2.4,
            stores: [
              at('1', 398, 'CONDOR', 'Gleba Palhano', 2.4),
              at('2', 410, 'SUPER MUFFATO', 'Centro', 1.1),
            ],
          ),
        ),
        ReceiptItem(
          description: 'CAFE PILAO TRADICIONAL 500G',
          unit: 'UN',
          qty: 2,
          unitPriceCents: 1590,
          lineTotalCents: 3180,
          precos: precos(
            1349,
            'SUPER MUFFATO',
            'Centro',
            1.1,
            stores: [
              at('2', 1349, 'SUPER MUFFATO', 'Centro', 1.1),
              at('1', 1650, 'CONDOR', 'Gleba Palhano', 2.4),
            ],
          ),
        ),
        ReceiptItem(
          description: 'BANANA NANICA',
          unit: 'KG',
          qty: 1.235,
          unitPriceCents: 499,
          lineTotalCents: 616,
          precos: precos(
            349,
            'HORTIFRUTI SANTARÉM',
            'Vila Casoni',
            3.8,
            confidence: 'approx',
            stores: [at('3', 349, 'HORTIFRUTI SANTARÉM', 'Vila Casoni', 3.8)],
          ),
        ),
        ReceiptItem(
          description: 'FEIJAO CARIOCA KICALDO 1KG',
          unit: 'UN',
          qty: 2,
          unitPriceCents: 849,
          lineTotalCents: 1698,
          precos: precos(
            879,
            'CONDOR',
            'Gleba Palhano',
            2.4,
            stores: [at('1', 879, 'CONDOR', 'Gleba Palhano', 2.4)],
          ),
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
    );
  }

  testWidgets('shots — receipt, priced', (tester) async {
    await receiptShot(tester, pricedSample(), 'receipt_priced');
  });

  // Phase 7: Home's hero in its "has savings" state, with the annual
  // projection line — needs >= 2 priced notes spanning real days, so a
  // second nota (bought five days earlier) joins the sample.
  testWidgets('shots — home, with savings', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final first = pricedSample();
    final second = first.copyWith(
      accessKey: '41250712345678000190650010000123451987654399',
      header: first.header.copyWith(purchasedAt: '14/07/2026 09:00:00'),
    );

    SharedPreferences.setMockInitialValues({});
    final setUp = await tester.runAsync(() async {
      final repo = ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('home_with_savings.db'));
      await repo.saveReceipt(first);
      await repo.saveReceipt(second);
      return (repo, Prefs(await SharedPreferences.getInstance()));
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        receiptRepositoryProvider.overrideWithValue(setUp!.$1),
        prefsProvider.overrideWithValue(setUp.$2),
      ],
      child: const EconoMiaApp(),
    ));

    router.go('/');
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/home_with_savings.png'));
  });

  // Phase 8: Atalhos' live counts (Ofertas do dia, Minhas Notas) and the
  // "Loja da Mia" disabled row, plus Dica da Mia's trend state — CONDOR
  // cheaper on FRUTAS today than every other weekday, clearing both
  // `minPerDay` and `marginPct`. Scrolled so the tiles below the hero show.
  testWidgets('shots — home, atalhos & dica', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    PriceObservation obs(int daysAgo, int cents) => PriceObservation(
          cod: '1',
          store: 'CONDOR',
          category: Categoria.frutas,
          priceCents: cents,
          datahora: now.subtract(Duration(days: daysAgo)).toIso8601String(),
        );
    // Today's weekday, 4 sightings, cheap. Every other weekday (offsets not a
    // multiple of 7), 4 sightings, dearer.
    final offers = [
      for (var w = 0; w < 4; w++) obs(w * 7, 300),
      for (var d = 1; d <= 4; d++) obs(d, 400),
    ];

    SharedPreferences.setMockInitialValues({});
    final setUp = await tester.runAsync(() async {
      final repo = ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('home_atalhos_dica.db'));
      await repo.saveReceipt(pricedSample());
      await repo.saveOffers(offers);
      return (repo, Prefs(await SharedPreferences.getInstance()));
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        receiptRepositoryProvider.overrideWithValue(setUp!.$1),
        prefsProvider.overrideWithValue(setUp.$2),
      ],
      child: const EconoMiaApp(),
    ));

    router.go('/');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/home_atalhos_dica.png'));
  });

  // Phase 5: the store picker opened, the category breakdown expanded, and —
  // after picking CONDOR — the single-store basket with both a green delta
  // (LEITE) and a red one (CAFE, FEIJAO), plus the "não vendidos nesta loja"
  // section for what CONDOR doesn't carry.
  testWidgets('shots — receipt, second pass', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final receipt = pricedSample();
    SharedPreferences.setMockInitialValues({});
    final setUp = await tester.runAsync(() async {
      final repo = ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('receipt_second_pass.db'));
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

    await tester.tap(find.text('Categorias da nota (5)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mais barato por perto'));
    await tester.pumpAndSettle();
    // The sheet's ListTile title, an exact match unlike the OfferSpan text
    // behind it (which carries the same store name plus price and distance).
    await tester.tap(find.text('CONDOR · Gleba Palhano'));
    await tester.pumpAndSettle();

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/receipt_second_pass.png'));
  });

  // Phase 6: Minhas Notas, both states. The full app (not a bare screen) since
  // rows navigate with `context.push`, which needs the real router in the tree.
  Future<ReceiptRepository> historyRepo(WidgetTester tester, String name, List<Receipt> receipts) =>
      tester.runAsync(() async {
        final repo = ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('$name.db'));
        for (final r in receipts) {
          await repo.saveReceipt(r);
        }
        return repo;
      }).then((r) => r!);

  testWidgets('shots — history, empty', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final repo = await historyRepo(tester, 'history_empty', const []);
    final prefs = Prefs(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        receiptRepositoryProvider.overrideWithValue(repo),
      ],
      child: const EconoMiaApp(),
    ));

    router.go('/notas');
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/history_empty.png'));
  });

  // One unpriced (just scanned) and one priced-with-savings nota, so both of
  // _StateBadge's non-empty states show up in the same shot.
  testWidgets('shots — history', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const unpriced = Receipt(
      accessKey: '41250712345678000190650010000123451987654323',
      createdAt: 1721000000000,
      header: ReceiptHeader(
        storeName: 'CONDOR SUPERMERCADOS',
        city: 'Londrina',
        purchasedAt: '24/07/2026 09:12:00',
        totalCents: 3210,
      ),
      items: [
        ReceiptItem(description: 'ARROZ TIO JOAO 5KG', unit: 'UN', unitPriceCents: 3210, lineTotalCents: 3210),
      ],
    );

    SharedPreferences.setMockInitialValues({});
    final repo = await historyRepo(tester, 'history', [unpriced, pricedSample()]);
    final prefs = Prefs(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        receiptRepositoryProvider.overrideWithValue(repo),
      ],
      child: const EconoMiaApp(),
    ));

    router.go('/notas');
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/history.png'));
  });

  // Phase 9: a scanned barcode's price range, cheapest offer and nearby-store
  // list. Bare screen, same reasoning as receiptShot above — the screen
  // depends on neither the shell nor the router for anything shown here.
  testWidgets('shots — produto', (tester) async {
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
        raio: 15,
      ).toJson()),
    });
    final prefs = Prefs(await SharedPreferences.getInstance());

    final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    final anteontem = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
    final body = jsonEncode({
      'gtin': '7894900011517',
      'basis': 'gtin',
      'confidence': 'high',
      'name': 'COCA-COLA LATA 350ML',
      'ncm': '2202',
      'range': {'minCents': 449, 'maxCents': 699},
      'nOffers': 9,
      'nStores': 3,
      'cheapest': {
        'priceCents': 449,
        'store': 'CONDOR',
        'bairro': 'Gleba Palhano',
        'km': 2.4,
        'addr': 'RUA TAPUIAS, 845, GLEBA PALHANO, LONDRINA - PR',
        'datahora': ontem,
      },
      'stores': [
        {'cod': '1', 'priceCents': 449, 'store': 'CONDOR', 'bairro': 'Gleba Palhano', 'km': 2.4, 'datahora': ontem},
        {'cod': '2', 'priceCents': 529, 'store': 'SUPER MUFFATO', 'bairro': 'Centro', 'km': 3.1, 'datahora': anteontem},
        {
          'cod': '3',
          'priceCents': 699,
          'store': 'HORTIFRUTI SANTARÉM',
          'bairro': 'Vila Casoni',
          'km': 4.0,
          'datahora': anteontem,
        },
      ],
    });
    final api = EconomiaApi(ApiClient(
      client: MockClient((req) async => http.Response.bytes(utf8.encode(body), 200)),
    ));

    // Phase 11: the "found" state — Nutri-Score, NOVA and the nutrient table.
    final offBody = jsonEncode({
      'status': 1,
      'product': {
        'product_name_pt': 'Coca-Cola Lata 350ml',
        'brands': 'Coca-Cola',
        'quantity': '350 ml',
        'ingredients_text_pt':
            'Água gaseificada, açúcar, extrato de noz de cola, corante caramelo IV, acidulante INS 338, aromatizante.',
        'nutriments': {
          'energy-kcal_100g': 42,
          'carbohydrates_100g': 10.6,
          'sugars_100g': 10.6,
          'proteins_100g': 0,
          'fat_100g': 0,
          'saturated-fat_100g': 0,
          'fiber_100g': 0,
          'sodium_100g': 0.01,
        },
        'nutriscore_grade': 'e',
        'nova_group': 4,
      },
    });
    final offApi = OffApi(client: MockClient((req) async => http.Response.bytes(utf8.encode(offBody), 200)));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        economiaApiProvider.overrideWithValue(api),
        offApiProvider.overrideWithValue(offApi),
      ],
      child: MaterialApp(theme: buildTheme(), home: const ProdutoScreen(gtin: '7894900011517')),
    ));

    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/produto.png'));
  });

  // Phase 10 (Mercado) has no shot here, same as Phase 3's ScanScreen: the
  // embedded camera calls MobileScannerController.start() unconditionally on
  // mount (there's no state of this screen without it — the scanner isn't a
  // separate route here, it's embedded), and that throws under the test
  // binding's unregistered platform channel regardless of what's on screen.
  // Verified instead by domain tests (compareHere, mergeStores/defaultStoreCod)
  // and by reading the widget tree logic against the reference MercadoView.
}
