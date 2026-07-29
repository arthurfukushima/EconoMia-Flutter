import 'dart:convert';

import 'package:economia/core/api_client.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/list_item.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/domain/lista.dart';
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
  // The parser's own corpus lives in `lista_parse_test.dart` — it is large,
  // it runs against the real shipped lexicon, and it is the spec for what a
  // jotted line is worth. What is left here is the *controller*: caching,
  // persistence, and reconciliation against what came back.

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
        pricedAt: now
            .subtract(const Duration(hours: 13))
            .millisecondsSinceEpoch,
      );
      expect(isStale(old, '86010000', now: now), isTrue);
    });

    test('the CEP moved → stale, however fresh the clock says it is', () {
      expect(isStale(priced, '80010000', now: now), isTrue);
    });

    test('never priced → stale', () {
      expect(
        isStale(
          const ListItem(id: 'b', raw: 'Cafe', name: 'Cafe'),
          '86010000',
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('activeOption', () {
    const optA = ProductOption(
      key: 'a',
      name: 'CARNE MOIDA',
      cheapest: Offer(priceCents: 2990),
      nStores: 4,
    );
    const optB = ProductOption(
      key: 'b',
      name: 'CARNE SECA',
      cheapest: Offer(priceCents: 4990),
      nStores: 2,
    );
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

    test(
      'a pick that no longer exists falls back rather than blanking the row',
      () {
        expect(
          activeOption(item.copyWith(chosenKey: 'gone'))?.name,
          'CARNE MOIDA',
        );
      },
    );

    test(
      'an item cached before options existed reads its collapsed result',
      () {
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
      },
    );

    test('no price at all → null', () {
      expect(
        activeOption(const ListItem(id: '3', raw: 'X', name: 'X')),
        isNull,
      );
      expect(
        activeOption(
          const ListItem(id: '3', raw: 'X', name: 'X', precos: Precos()),
        ),
        isNull,
      );
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

    test(
      'coverage beats price — the trip you want is the one that gets everything',
      () {
        final ranked = marketRanking(items);
        expect(ranked.map((m) => m.cod), ['1', '2']);
        expect(ranked.first.count, 2);
        // 2 × 449 + 1,235 × 499, each line rounded once.
        expect(ranked.first.totalCents, 898 + 616);
      },
    );

    test('equal coverage → the cheaper partial basket first', () {
      final one = items.first;
      final ranked = marketRanking([one]);
      expect(ranked.map((m) => m.cod), [
        '2',
        '1',
      ], reason: 'MUFFATO is cheaper on the only item');
    });

    test(
      'basketAt reports coverage alongside the total, never the total alone',
      () {
        expect(basketAt(items, '1'), (carried: 2, totalCents: 1514));
        expect(basketAt(items, '2'), (carried: 1, totalCents: 796));
        expect(basketAt(items, 'nowhere'), (carried: 0, totalCents: 0));
      },
    );

    test('listStores is the picker without an extra fetch, nearest-first', () {
      expect(listStores(items).map((s) => s.cod), ['2', '1']);
    });

    test('a fractional weight is rounded once, at the line', () {
      expect(lineCents(499, 1.235), 616);
    });

    test('the nearer market wins an otherwise exact tie', () {
      final one = ListItem(
        id: '1',
        raw: 'Leite',
        name: 'Leite',
        precos: const Precos(
          cheapest: Offer(priceCents: 1),
          stores: [
            Offer(cod: 'far', store: 'A', priceCents: 400, km: 22),
            Offer(cod: 'near', store: 'B', priceCents: 400, km: 0.8),
          ],
        ),
      );
      expect(marketRanking([one]).map((m) => m.cod), ['near', 'far']);
    });
  });

  group('bestSplit', () {
    /// Two items CONDOR carries; MUFFATO undercuts it on the first by R$ 6,00
    /// a unit and doesn't stock the second.
    final items = [
      ListItem(
        id: '1',
        raw: '2x Leite',
        name: 'Leite',
        qty: 2,
        precos: const Precos(
          cheapest: Offer(priceCents: 1),
          stores: [
            Offer(cod: '1', store: 'CONDOR', priceCents: 1000, km: 2.4),
            Offer(cod: '2', store: 'MUFFATO', priceCents: 400, km: 1.1),
          ],
        ),
      ),
      ListItem(
        id: '2',
        raw: 'Banana',
        name: 'Banana',
        precos: const Precos(
          cheapest: Offer(priceCents: 1),
          stores: [Offer(cod: '1', store: 'CONDOR', priceCents: 499, km: 2.4)],
        ),
      ),
    ];

    test('the saving is exactly the gap between the two totals shown', () {
      final split = bestSplit(items, '1')!;
      expect(split.cod, '2');
      expect(split.cheaperCount, 1);
      expect(split.extraCount, 0);
      // 2 × 400 + 499 — MUFFATO's leite, CONDOR's banana.
      expect(split.totalCents, 800 + 499);
      expect(
        split.savedCents,
        basketAt(items, '1').totalCents - split.totalCents,
        reason: 'the number shown must reconcile the two totals shown',
      );
    });

    test('a market that only adds items it alone stocks is still worth it', () {
      final list = [
        ListItem(
          id: '1',
          raw: 'Leite',
          name: 'Leite',
          precos: const Precos(
            cheapest: Offer(priceCents: 1),
            stores: [Offer(cod: '1', store: 'CONDOR', priceCents: 400)],
          ),
        ),
        ListItem(
          id: '2',
          raw: 'Queijo',
          name: 'Queijo',
          precos: const Precos(
            cheapest: Offer(priceCents: 1),
            stores: [Offer(cod: '2', store: 'MUFFATO', priceCents: 2999)],
          ),
        ),
      ];
      final split = bestSplit(list, '1')!;
      expect(split.cod, '2');
      expect(split.extraCount, 1);
      expect(
        split.savedCents,
        0,
        reason: 'an item the anchor never stocked was never a saving',
      );
      expect(split.totalCents, 400 + 2999);
    });

    test('a trip that saves less than splitWorthCents is not suggested', () {
      final list = [
        ListItem(
          id: '1',
          raw: 'Leite',
          name: 'Leite',
          precos: const Precos(
            cheapest: Offer(priceCents: 1),
            stores: [
              Offer(cod: '1', store: 'CONDOR', priceCents: 449),
              Offer(cod: '2', store: 'MUFFATO', priceCents: 448),
            ],
          ),
        ),
      ];
      expect(bestSplit(list, '1'), isNull);
    });

    test('no second market at all → null', () {
      expect(bestSplit([items.last], '1'), isNull);
      expect(bestSplit(const [], '1'), isNull);
    });

    test('a fractional weight saves the gap between two line totals', () {
      final list = [
        ListItem(
          id: '1',
          raw: '1.235kg Banana',
          name: 'Banana',
          qty: 1.235,
          unit: 'kg',
          precos: const Precos(
            cheapest: Offer(priceCents: 1),
            stores: [
              Offer(cod: '1', store: 'CONDOR', priceCents: 999),
              Offer(cod: '2', store: 'MUFFATO', priceCents: 499),
            ],
          ),
        ),
      ];
      final split = bestSplit(list, '1')!;
      expect(split.savedCents, lineCents(999, 1.235) - lineCents(499, 1.235));
      expect(split.savedCents, 1234 - 616);
    });

    test('the biggest saving wins, then the nearer market', () {
      final list = [
        ListItem(
          id: '1',
          raw: 'Leite',
          name: 'Leite',
          precos: const Precos(
            cheapest: Offer(priceCents: 1),
            stores: [
              Offer(cod: '1', store: 'CONDOR', priceCents: 2000),
              Offer(cod: 'meh', store: 'A', priceCents: 1400, km: 0.5),
              Offer(cod: 'best', store: 'B', priceCents: 1000, km: 9),
            ],
          ),
        ),
      ];
      expect(bestSplit(list, '1')!.cod, 'best');

      final tied = [
        ListItem(
          id: '1',
          raw: 'Leite',
          name: 'Leite',
          precos: const Precos(
            cheapest: Offer(priceCents: 1),
            stores: [
              Offer(cod: '1', store: 'CONDOR', priceCents: 2000),
              Offer(cod: 'far', store: 'A', priceCents: 1000, km: 9),
              Offer(cod: 'near', store: 'B', priceCents: 1000, km: 0.5),
            ],
          ),
        ),
      ];
      expect(bestSplit(tied, '1')!.cod, 'near');
    });
  });

  group('ListaController pricing', () {
    const cep = '86010000';

    /// A list holding one item priced 13h ago — stale by the clock, with prices
    /// that are still perfectly good to show.
    final cachedAt = DateTime.now()
        .subtract(const Duration(hours: 13))
        .millisecondsSinceEpoch;
    final cached = ListItem(
      id: 'toddy',
      raw: 'Toddy',
      name: 'Toddy',
      precos: const Precos(
        name: 'TODDY 400G',
        cheapest: Offer(priceCents: 1299),
      ),
      pricedAt: cachedAt,
      pricedCep: cep,
    );

    Future<ProviderContainer> boot(
      http.Client client, {
      List<ListItem> items = const [],
    }) async {
      SharedPreferences.setMockInitialValues({
        'economia.location': jsonEncode(
          const AppLocation(
            lat: -23.31,
            lng: -51.16,
            cep: cep,
            city: 'Londrina',
            raio: 50,
          ).toJson(),
        ),
        'economia.shoppingList': jsonEncode([
          for (final i in items) i.toJson(),
        ]),
      });
      final prefs = Prefs(await SharedPreferences.getInstance());
      await prefs.initLists();
      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          economiaApiProvider.overrideWithValue(
            EconomiaApi(ApiClient(client: client)),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    final down = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode({'error': 'menorpreco_failed'})),
        502,
      ),
    );

    test(
      'a failed refresh keeps the old prices AND the old timestamp',
      () async {
        final container = await boot(down, items: [cached]);
        await container.read(listaControllerProvider.notifier).refresh();

        final item = container.read(listaControllerProvider).single;
        expect(
          item.precos?.cheapest?.priceCents,
          1299,
          reason: 'a 502 must never blank a good price',
        );
        expect(
          item.pricedAt,
          cachedAt,
          reason: 'a fresh stamp on a failure stops it ever retrying',
        );
        expect(
          isStale(item, cep),
          isTrue,
          reason: 'still due, so the next pass tries again',
        );
        expect(container.read(listPriceErrorProvider), isTrue);
        // Nothing is left marked as loading, even on the failure path.
        expect(container.read(listPricingProvider), isEmpty);
      },
    );

    test('the failure is not written to disk either', () async {
      final container = await boot(down, items: [cached]);
      await container.read(listaControllerProvider.notifier).refresh();

      final onDisk = _onDisk(container).single;
      expect(onDisk.precos?.cheapest?.priceCents, 1299);
      expect(onDisk.pricedAt, cachedAt);
    });

    test('a successful pass stamps the price, the time and the CEP', () async {
      final ok = MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'basis': 'desc',
              'confidence': 'approx',
              'name': 'TODDY 400G',
              'nOffers': 3,
              'nStores': 2,
              'cheapest': {'priceCents': 1149, 'store': 'CONDOR'},
              'stores': [
                {'cod': '1', 'priceCents': 1149, 'store': 'CONDOR', 'km': 2.4},
              ],
            }),
          ),
          200,
        ),
      );
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
      final empty = MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'nOffers': 0, 'stores': <Object>[]})),
          200,
        ),
      );
      final container = await boot(empty, items: [cached]);
      await container.read(listaControllerProvider.notifier).refresh();

      final item = container.read(listaControllerProvider).single;
      expect(
        activeOption(item),
        isNull,
        reason: 'the row says "sem preço por perto"',
      );
      expect(
        isStale(item, cep),
        isFalse,
        reason: 'answered, so not re-asked for 12h',
      );
      expect(container.read(listPriceErrorProvider), isFalse);
    });

    test('priceStale leaves a fresh item alone', () async {
      var calls = 0;
      final counting = MockClient((_) async {
        calls++;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'nOffers': 0})),
          200,
        );
      });
      final fresh = cached.copyWith(
        pricedAt: DateTime.now().millisecondsSinceEpoch,
      );
      final container = await boot(counting, items: [fresh]);

      await container.read(listaControllerProvider.notifier).priceStale();
      expect(calls, 0);

      await container.read(listaControllerProvider.notifier).refresh();
      expect(calls, 1, reason: '"atualizar preços" ignores the cache');
    });

    test('add parses, persists and prices the new lines', () async {
      final ok = MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'nOffers': 1,
              'cheapest': {'priceCents': 599, 'store': 'CONDOR'},
              'stores': [
                {'cod': '1', 'priceCents': 599, 'store': 'CONDOR'},
              ],
            }),
          ),
          200,
        ),
      );
      final container = await boot(ok);
      await container
          .read(listaControllerProvider.notifier)
          .add('4x Tomates, 1.5kg Carne');

      final items = container.read(listaControllerProvider);
      // Singularised for the search; "tomate" is sold by the kilo, so four of
      // them is about a kilo rather than four × a per-kilo price.
      expect(items.map((i) => i.name), ['Tomate', 'Carne']);
      expect(items.map((i) => i.unit), ['kg', 'kg']);
      expect(items.every((i) => i.precos != null), isTrue);
      expect(
        _onDisk(container).length,
        2,
        reason: 'persisted, not memory-only',
      );
    });

    test('newest first, and an edit round-trips to disk', () async {
      final container = await boot(down);
      final controller = container.read(listaControllerProvider.notifier);
      await controller.add('Toddy');
      await controller.add('Cafe');
      expect(container.read(listaControllerProvider).map((i) => i.name), [
        'Cafe',
        'Toddy',
      ]);

      final id = container.read(listaControllerProvider).first.id;
      await controller.toggle(id);
      expect(_onDisk(container).first.checked, isTrue);

      await controller.remove(id);
      expect(container.read(listaControllerProvider).map((i) => i.name), [
        'Toddy',
      ]);
      expect(_onDisk(container).length, 1);
    });

    test('crossing the kg boundary re-prices; un ↔ L does not', () async {
      var calls = 0;
      final counting = MockClient((_) async {
        calls++;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'nOffers': 0})),
          200,
        );
      });
      final fresh = cached.copyWith(
        pricedAt: DateTime.now().millisecondsSinceEpoch,
      );
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
      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(await _initedPrefs()),
          economiaApiProvider.overrideWithValue(
            EconomiaApi(ApiClient(client: counting)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(listaControllerProvider.notifier).add('Toddy');
      expect(calls, 0);
      expect(container.read(listaControllerProvider).single.precos, isNull);
    });
  });

  // Catálogo's "+ Lista": a store-reported product name, not a jotted line.
  group('addNamed (from Catálogo)', () {
    Future<ProviderContainer> boot({List<ListItem> items = const []}) async {
      SharedPreferences.setMockInitialValues({
        'economia.shoppingList': jsonEncode([
          for (final i in items) i.toJson(),
        ]),
      });
      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(await _initedPrefs()),
          economiaApiProvider.overrideWithValue(
            EconomiaApi(
              ApiClient(
                client: MockClient((_) async => http.Response('{}', 200)),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    // The reason this doesn't go through add(): parseInput would read the
    // leading packaging token as a quantity prefix and eat it off the name.
    test('a leading packaging token stays part of the name', () async {
      final container = await boot();
      await container
          .read(listaControllerProvider.notifier)
          .addNamed('1KG ARROZ TIO JOAO');

      final item = container.read(listaControllerProvider).single;
      expect(item.name, '1KG ARROZ TIO JOAO');
      expect(item.qty, 1);
      // A one-kilo bag is priced per bag. Asking per-KG would compare the bag
      // to a kilo — the same UN-vs-KG trap, arriving from the catalog side.
      expect(item.unit, 'un');
      expect(item.size, (value: 1.0, unit: 'kg'));
    });

    test('a bare KG asks for a per-KG basis', () async {
      final container = await boot();
      await container
          .read(listaControllerProvider.notifier)
          .addNamed('PICANHA BOV KG');

      expect(container.read(listaControllerProvider).single.unit, 'kg');
    });

    test('anything else is a packaged unit', () async {
      final container = await boot();
      await container
          .read(listaControllerProvider.notifier)
          .addNamed('LEITE INTEGRAL ITALAC 1L');

      expect(container.read(listaControllerProvider).single.unit, 'un');
    });

    test('newest first, and it reaches disk', () async {
      final container = await boot();
      final controller = container.read(listaControllerProvider.notifier);
      await controller.addNamed('ARROZ');
      await controller.addNamed('FEIJAO');

      expect(container.read(listaControllerProvider).map((i) => i.name), [
        'FEIJAO',
        'ARROZ',
      ]);
      expect(_onDisk(container).map((i) => i.name), ['FEIJAO', 'ARROZ']);
    });

    test('reorder changes the list order and persists it too', () async {
      final container = await boot(
        items: const [
          ListItem(id: 'a', raw: 'Arroz', name: 'Arroz'),
          ListItem(id: 'b', raw: 'Feijao', name: 'Feijao'),
          ListItem(id: 'c', raw: 'Cafe', name: 'Cafe'),
        ],
      );

      await container.read(listaControllerProvider.notifier).reorder(0, 3);

      expect(container.read(listaControllerProvider).map((i) => i.id), [
        'b',
        'c',
        'a',
      ]);
      expect(_onDisk(container).map((i) => i.id), ['b', 'c', 'a']);
    });

    test('a blank description adds nothing', () async {
      final container = await boot();
      await container.read(listaControllerProvider.notifier).addNamed('   ');

      expect(container.read(listaControllerProvider), isEmpty);
    });
  });
}
