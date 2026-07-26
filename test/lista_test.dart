import 'dart:convert';

import 'package:economia/core/api_client.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/list_item.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/domain/lista.dart';
import 'package:economia/domain/lista_parse.dart';
import 'package:economia/features/lista/lista_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 12. The parser is the user-facing half; the cache rules are the half
/// that can be quietly wrong — a failed refresh that wipes good prices, or that
/// stamps a fresh timestamp on a failure and so stops retrying.

/// Prefs with the shopping-list index already created — `main()` awaits
/// `initLists()` before anything reads a list, so a test that skips it would
/// be exercising a state the app never reaches.
Future<Prefs> _initedPrefs() async {
  final prefs = Prefs(await SharedPreferences.getInstance());
  await prefs.initLists();
  return prefs;
}

/// What actually reached disk for the list on screen.
List<ListItem> _onDisk(ProviderContainer container) {
  final prefs = container.read(prefsProvider);
  return prefs.itemsOf(prefs.activeListId);
}

void main() {
  group('parseItem', () {
    test('"4x Tomates" — a count prefix', () {
      final p = parseItem('4x Tomates');
      expect((p.qty, p.unit, p.name), (4.0, 'un', 'Tomates'));
    });

    test('a bare leading count works too', () {
      expect(parseItem('2 Laranjas').qty, 2);
      expect(parseItem('2 Laranjas').name, 'Laranjas');
    });

    test('"1.5kg Carne" and "1,5kg Carne" are the same item', () {
      for (final raw in ['1.5kg Carne', '1,5kg Carne']) {
        final p = parseItem(raw);
        expect((p.qty, p.unit, p.name), (1.5, 'kg', 'Carne'), reason: raw);
      }
    });

    test('grams and millilitres are packaged goods → un, never kg', () {
      // The UN-vs-KG trap from the other direction: a 500g pack is priced per
      // unit upstream, so asking for a per-KG basis would compare it to a price
      // per kilo.
      expect(parseItem('500g Cafe').unit, 'un');
      expect(parseItem('300ml Molho').unit, 'un');
      expect(parseItem('500g Cafe').qty, 500);
    });

    test('litres in every spelling → L', () {
      for (final raw in ['2l Leite', '2L Leite', '2lt Leite', '2 litros Leite']) {
        expect(parseItem(raw).unit, 'L', reason: raw);
      }
    });

    test('no prefix at all → 1 un, name untouched', () {
      final p = parseItem('  Toddy  ');
      expect((p.qty, p.unit, p.name, p.raw), (1.0, 'un', 'Toddy', 'Toddy'));
    });

    test('a line that is only a quantity keeps the raw text as its name', () {
      // Unpriceable, but still checkable — silently dropping what someone typed
      // is worse than a row that says "2kg".
      expect(parseItem('2kg').name, '2kg');
      expect(parseItem('2kg').unit, 'kg');
    });

    test('"kg" inside a word is not a unit', () {
      expect(parseItem('4x Kgel').unit, 'un');
    });
  });

  group('parseInput', () {
    test('splits on commas and newlines, dropping blanks', () {
      final lines = parseInput('4x Tomates, 2x Laranjas\nToddy,,\n  ');
      expect(lines.map((l) => l.name), ['Tomates', 'Laranjas', 'Toddy']);
      expect(lines.map((l) => l.qty), [4, 2, 1]);
    });

    test('nothing typed → nothing added', () {
      expect(parseInput('   ,\n '), isEmpty);
    });

    // People paste out of Notes/Word/PDF, and that arrives decorated.
    test('bullets and dashes are stripped, not treated as part of the name', () {
      final lines = parseInput('• 12 Pães\n- Toddy\n— 2x Leite\n* Cafe');
      expect(lines.map((l) => l.name), ['Pães', 'Toddy', 'Leite', 'Cafe']);
      expect(lines.map((l) => l.qty), [12, 1, 2, 1]);
    });

    test('numbering is stripped, but a bare count is still a quantity', () {
      expect(parseInput('1. Arroz').single.name, 'Arroz');
      expect(parseInput('1. Arroz').single.qty, 1);
      expect(parseInput('2) Feijao').single.name, 'Feijao');
      // "4 Tomates" is four tomatoes, not item #4 — no trailing '.' or ')'.
      expect(parseInput('4 Tomates').single.qty, 4);
      expect(parseInput('4 Tomates').single.name, 'Tomates');
    });

    test('non-breaking spaces and doubled whitespace collapse', () {
      final line = parseInput('•  2x  Leite   Integral').single;
      expect(line.qty, 2);
      expect(line.name, 'Leite Integral');
    });

    test('the name gets a capital, the rest of the casing is left alone', () {
      expect(parseItem('tomates').name, 'Tomates');
      expect(parseItem('TODDY').name, 'TODDY');
      expect(parseItem('pão DE queijo').name, 'Pão DE queijo');
    });
  });

  group('isStale', () {
    final now = DateTime(2026, 7, 26, 12);
    final priced = ListItem(
      id: 'a',
      raw: 'Toddy',
      name: 'Toddy',
      precos: const Precos(cheapest: Offer(priceCents: 999)),
      pricedAt: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      pricedCep: '86010000',
    );

    test('priced 2h ago for this CEP → fresh', () {
      expect(isStale(priced, '86010000', now: now), isFalse);
    });

    test('older than 12h → stale', () {
      final old = priced.copyWith(
        pricedAt: now.subtract(const Duration(hours: 13)).millisecondsSinceEpoch,
      );
      expect(isStale(old, '86010000', now: now), isTrue);
    });

    test('the CEP moved → stale, however fresh the clock says it is', () {
      expect(isStale(priced, '80010000', now: now), isTrue);
    });

    test('never priced → stale', () {
      expect(isStale(const ListItem(id: 'b', raw: 'Cafe', name: 'Cafe'), '86010000', now: now), isTrue);
    });
  });

  group('activeOption', () {
    const optA = ProductOption(key: 'a', name: 'CARNE MOIDA', cheapest: Offer(priceCents: 2990), nStores: 4);
    const optB = ProductOption(key: 'b', name: 'CARNE SECA', cheapest: Offer(priceCents: 4990), nStores: 2);
    const item = ListItem(
      id: '1',
      raw: 'Carne',
      name: 'Carne',
      precos: Precos(options: [optA, optB]),
    );

    test('the user\'s pick wins', () {
      expect(activeOption(item.copyWith(chosenKey: 'b'))?.name, 'CARNE SECA');
    });

    test('no pick → the most-common match, options.first', () {
      expect(activeOption(item)?.name, 'CARNE MOIDA');
    });

    test('a pick that no longer exists falls back rather than blanking the row', () {
      expect(activeOption(item.copyWith(chosenKey: 'gone'))?.name, 'CARNE MOIDA');
    });

    test('an item cached before options existed reads its collapsed result', () {
      const legacy = ListItem(
        id: '2',
        raw: 'Toddy',
        name: 'Toddy',
        precos: Precos(
          name: 'TODDY 400G',
          cheapest: Offer(priceCents: 1299),
          stores: [Offer(cod: '1', priceCents: 1299)],
          nStores: 1,
        ),
      );
      final active = activeOption(legacy);
      expect(active?.name, 'TODDY 400G');
      expect(active?.stores.single.cod, '1');
    });

    test('no price at all → null', () {
      expect(activeOption(const ListItem(id: '3', raw: 'X', name: 'X')), isNull);
      expect(activeOption(const ListItem(id: '3', raw: 'X', name: 'X', precos: Precos())), isNull);
    });
  });

  group('marketRanking / basketAt', () {
    // CONDOR carries both items and is dearer; MUFFATO carries one and is cheap.
    final items = [
      ListItem(
        id: '1',
        raw: '2x Leite',
        name: 'Leite',
        qty: 2,
        precos: const Precos(
          cheapest: Offer(priceCents: 398),
          stores: [
            Offer(cod: '1', store: 'CONDOR', priceCents: 449, km: 2.4),
            Offer(cod: '2', store: 'MUFFATO', priceCents: 398, km: 1.1),
          ],
        ),
      ),
      ListItem(
        id: '2',
        raw: '1.235kg Banana',
        name: 'Banana',
        qty: 1.235,
        unit: 'kg',
        precos: const Precos(
          cheapest: Offer(priceCents: 499),
          stores: [Offer(cod: '1', store: 'CONDOR', priceCents: 499, km: 2.4)],
        ),
      ),
    ];

    test('coverage beats price — the trip you want is the one that gets everything', () {
      final ranked = marketRanking(items);
      expect(ranked.map((m) => m.cod), ['1', '2']);
      expect(ranked.first.count, 2);
      // 2 × 449 + 1,235 × 499, each line rounded once.
      expect(ranked.first.totalCents, 898 + 616);
    });

    test('equal coverage → the cheaper partial basket first', () {
      final one = items.first;
      final ranked = marketRanking([one]);
      expect(ranked.map((m) => m.cod), ['2', '1'], reason: 'MUFFATO is cheaper on the only item');
    });

    test('basketAt reports coverage alongside the total, never the total alone', () {
      expect(basketAt(items, '1'), (carried: 2, totalCents: 1514));
      expect(basketAt(items, '2'), (carried: 1, totalCents: 796));
      expect(basketAt(items, 'nowhere'), (carried: 0, totalCents: 0));
    });

    test('listStores is the picker without an extra fetch, nearest-first', () {
      expect(listStores(items).map((s) => s.cod), ['2', '1']);
    });

    test('a fractional weight is rounded once, at the line', () {
      expect(lineCents(499, 1.235), 616);
    });
  });

  group('ListaController pricing', () {
    const cep = '86010000';

    /// A list holding one item priced 13h ago — stale by the clock, with prices
    /// that are still perfectly good to show.
    final cachedAt = DateTime.now().subtract(const Duration(hours: 13)).millisecondsSinceEpoch;
    final cached = ListItem(
      id: 'toddy',
      raw: 'Toddy',
      name: 'Toddy',
      precos: const Precos(name: 'TODDY 400G', cheapest: Offer(priceCents: 1299)),
      pricedAt: cachedAt,
      pricedCep: cep,
    );

    Future<ProviderContainer> boot(http.Client client, {List<ListItem> items = const []}) async {
      SharedPreferences.setMockInitialValues({
        'economia.location': jsonEncode(const AppLocation(
          lat: -23.31,
          lng: -51.16,
          cep: cep,
          city: 'Londrina',
          raio: 50,
        ).toJson()),
        'economia.shoppingList': jsonEncode([for (final i in items) i.toJson()]),
      });
      final prefs = Prefs(await SharedPreferences.getInstance());
      await prefs.initLists();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        economiaApiProvider.overrideWithValue(EconomiaApi(ApiClient(client: client))),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    final down = MockClient((_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'error': 'menorpreco_failed'})),
          502,
        ));

    test('a failed refresh keeps the old prices AND the old timestamp', () async {
      final container = await boot(down, items: [cached]);
      await container.read(listaControllerProvider.notifier).refresh();

      final item = container.read(listaControllerProvider).single;
      expect(item.precos?.cheapest?.priceCents, 1299, reason: 'a 502 must never blank a good price');
      expect(item.pricedAt, cachedAt, reason: 'a fresh stamp on a failure stops it ever retrying');
      expect(isStale(item, cep), isTrue, reason: 'still due, so the next pass tries again');
      expect(container.read(listPriceErrorProvider), isTrue);
      // Nothing is left marked as loading, even on the failure path.
      expect(container.read(listPricingProvider), isEmpty);
    });

    test('the failure is not written to disk either', () async {
      final container = await boot(down, items: [cached]);
      await container.read(listaControllerProvider.notifier).refresh();

      final onDisk = _onDisk(container).single;
      expect(onDisk.precos?.cheapest?.priceCents, 1299);
      expect(onDisk.pricedAt, cachedAt);
    });

    test('a successful pass stamps the price, the time and the CEP', () async {
      final ok = MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({
              'basis': 'desc',
              'confidence': 'approx',
              'name': 'TODDY 400G',
              'nOffers': 3,
              'nStores': 2,
              'cheapest': {'priceCents': 1149, 'store': 'CONDOR'},
              'stores': [
                {'cod': '1', 'priceCents': 1149, 'store': 'CONDOR', 'km': 2.4},
              ],
            })),
            200,
          ));
      final container = await boot(ok, items: [cached]);
      await container.read(listaControllerProvider.notifier).priceStale();

      final item = container.read(listaControllerProvider).single;
      expect(item.precos?.cheapest?.priceCents, 1149);
      expect(item.pricedCep, cep);
      expect(item.pricedAt, greaterThan(cachedAt));
      expect(isStale(item, cep), isFalse);
      expect(container.read(listPriceErrorProvider), isFalse);
    });

    test('"no offers nearby" is a real answer and gets cached', () async {
      // Otherwise every open re-asks a rate-limited source the same question it
      // already answered.
      final empty = MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({'nOffers': 0, 'stores': <Object>[]})),
            200,
          ));
      final container = await boot(empty, items: [cached]);
      await container.read(listaControllerProvider.notifier).refresh();

      final item = container.read(listaControllerProvider).single;
      expect(activeOption(item), isNull, reason: 'the row says "sem preço por perto"');
      expect(isStale(item, cep), isFalse, reason: 'answered, so not re-asked for 12h');
      expect(container.read(listPriceErrorProvider), isFalse);
    });

    test('priceStale leaves a fresh item alone', () async {
      var calls = 0;
      final counting = MockClient((_) async {
        calls++;
        return http.Response.bytes(utf8.encode(jsonEncode({'nOffers': 0})), 200);
      });
      final fresh = cached.copyWith(pricedAt: DateTime.now().millisecondsSinceEpoch);
      final container = await boot(counting, items: [fresh]);

      await container.read(listaControllerProvider.notifier).priceStale();
      expect(calls, 0);

      await container.read(listaControllerProvider.notifier).refresh();
      expect(calls, 1, reason: '"atualizar preços" ignores the cache');
    });

    test('add parses, persists and prices the new lines', () async {
      final ok = MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({
              'nOffers': 1,
              'cheapest': {'priceCents': 599, 'store': 'CONDOR'},
              'stores': [
                {'cod': '1', 'priceCents': 599, 'store': 'CONDOR'},
              ],
            })),
            200,
          ));
      final container = await boot(ok);
      await container.read(listaControllerProvider.notifier).add('4x Tomates, 1.5kg Carne');

      final items = container.read(listaControllerProvider);
      expect(items.map((i) => i.name), ['Tomates', 'Carne']);
      expect(items.every((i) => i.precos != null), isTrue);
      expect(_onDisk(container).length, 2, reason: 'persisted, not memory-only');
    });

    test('newest first, and an edit round-trips to disk', () async {
      final container = await boot(down);
      final controller = container.read(listaControllerProvider.notifier);
      await controller.add('Toddy');
      await controller.add('Cafe');
      expect(container.read(listaControllerProvider).map((i) => i.name), ['Cafe', 'Toddy']);

      final id = container.read(listaControllerProvider).first.id;
      await controller.toggle(id);
      expect(_onDisk(container).first.checked, isTrue);

      await controller.remove(id);
      expect(container.read(listaControllerProvider).map((i) => i.name), ['Toddy']);
      expect(_onDisk(container).length, 1);
    });

    test('crossing the kg boundary re-prices; un ↔ L does not', () async {
      var calls = 0;
      final counting = MockClient((_) async {
        calls++;
        return http.Response.bytes(utf8.encode(jsonEncode({'nOffers': 0})), 200);
      });
      final fresh = cached.copyWith(pricedAt: DateTime.now().millisecondsSinceEpoch);
      final container = await boot(counting, items: [fresh]);
      final controller = container.read(listaControllerProvider.notifier);

      await controller.setUnit('toddy', 'L');
      expect(calls, 0, reason: 'un and L match either basis upstream');

      await controller.setUnit('toddy', 'kg');
      expect(calls, 1, reason: 'kg is a different price-search basis');
    });

    test('nothing is priced without a location', () async {
      SharedPreferences.setMockInitialValues({});
      var calls = 0;
      final counting = MockClient((_) async {
        calls++;
        return http.Response.bytes(utf8.encode('{}'), 200);
      });
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(await _initedPrefs()),
        economiaApiProvider.overrideWithValue(EconomiaApi(ApiClient(client: counting))),
      ]);
      addTearDown(container.dispose);

      await container.read(listaControllerProvider.notifier).add('Toddy');
      expect(calls, 0);
      expect(container.read(listaControllerProvider).single.precos, isNull);
    });
  });

  // Catálogo's "+ Lista": a store-reported product name, not a jotted line.
  group('addNamed (from Catálogo)', () {
    Future<ProviderContainer> boot() async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(await _initedPrefs()),
        economiaApiProvider.overrideWithValue(
          EconomiaApi(ApiClient(client: MockClient((_) async => http.Response('{}', 200)))),
        ),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    // The reason this doesn't go through add(): parseInput would read the
    // leading packaging token as a quantity prefix and eat it off the name.
    test('a leading packaging token stays part of the name', () async {
      final container = await boot();
      await container.read(listaControllerProvider.notifier).addNamed('1KG ARROZ TIO JOAO');

      final item = container.read(listaControllerProvider).single;
      expect(item.name, '1KG ARROZ TIO JOAO');
      expect(item.qty, 1);
    });

    test('a KG anywhere in the description asks for a per-KG basis', () async {
      final container = await boot();
      await container.read(listaControllerProvider.notifier).addNamed('PICANHA BOV KG');

      expect(container.read(listaControllerProvider).single.unit, 'kg');
    });

    test('anything else is a packaged unit', () async {
      final container = await boot();
      await container.read(listaControllerProvider.notifier).addNamed('LEITE INTEGRAL ITALAC 1L');

      expect(container.read(listaControllerProvider).single.unit, 'un');
    });

    test('newest first, and it reaches disk', () async {
      final container = await boot();
      final controller = container.read(listaControllerProvider.notifier);
      await controller.addNamed('ARROZ');
      await controller.addNamed('FEIJAO');

      expect(container.read(listaControllerProvider).map((i) => i.name), ['FEIJAO', 'ARROZ']);
      expect(_onDisk(container).map((i) => i.name), ['FEIJAO', 'ARROZ']);
    });

    test('a blank description adds nothing', () async {
      final container = await boot();
      await container.read(listaControllerProvider.notifier).addNamed('   ');

      expect(container.read(listaControllerProvider), isEmpty);
    });
  });
}
