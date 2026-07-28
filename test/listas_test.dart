import 'dart:convert';

import 'package:economia/data/models/list_item.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/data/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Several named lists, and the one-way migration into them.
///
/// The migration is the part that can be quietly catastrophic: it runs once,
/// on someone who already has a list, and getting it wrong looks exactly like
/// "the update ate my shopping list".
Future<Prefs> prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return Prefs(await SharedPreferences.getInstance());
}

const _item = ListItem(
  id: 'i1',
  raw: '2x Leite',
  name: 'Leite',
  qty: 2,
  precos: Precos(cheapest: Offer(priceCents: 398)),
  pricedAt: 1700000000000,
  pricedCep: '86010000',
);

String _encode(List<ListItem> items) => jsonEncode([for (final i in items) i.toJson()]);

void main() {
  group('migration from the single-list layout', () {
    test('an existing list survives, prices and all, under "Minha Lista"', () async {
      final prefs = await prefsWith({'economia.shoppingList': _encode([_item])});

      await prefs.initLists();

      expect(prefs.lists, hasLength(1));
      expect(prefs.lists.single.name, 'Minha Lista');

      final migrated = prefs.itemsOf(prefs.activeListId);
      expect(migrated, hasLength(1));
      expect(migrated.single.name, 'Leite');
      // The cached price and its timestamp have to survive too — losing them
      // silently re-prices everything against a rate-limited source.
      expect(migrated.single.precos?.cheapest?.priceCents, 398);
      expect(migrated.single.pricedAt, 1700000000000);
    });

    test('the old per-app store pick becomes that list\'s own', () async {
      final prefs = await prefsWith({
        'economia.shoppingList': _encode([_item]),
        'economia.listStore': '4821',
      });

      await prefs.initLists();

      expect(prefs.listStoreOf(prefs.activeListId), '4821');
    });

    test('a fresh install gets one empty default list', () async {
      final prefs = await prefsWith({});

      await prefs.initLists();

      expect(prefs.lists, hasLength(1));
      expect(prefs.itemsOf(prefs.activeListId), isEmpty);
      expect(prefs.activeListId, isNotEmpty);
    });

    test('is idempotent — a second run never re-migrates over live data', () async {
      final prefs = await prefsWith({'economia.shoppingList': _encode([_item])});
      await prefs.initLists();
      final id = prefs.activeListId;

      // Someone empties the list, then the app restarts.
      await prefs.setItemsOf(id, const []);
      await prefs.initLists();

      expect(prefs.lists, hasLength(1));
      expect(prefs.activeListId, id);
      expect(prefs.itemsOf(id), isEmpty, reason: 'the legacy blob must not come back');
    });

    test('the legacy keys are left in place for a downgrade', () async {
      final prefs = await prefsWith({'economia.shoppingList': _encode([_item])});
      await prefs.initLists();

      final legacy = await SharedPreferences.getInstance();
      expect(legacy.getString('economia.shoppingList'), isNotNull);
    });
  });

  group('list CRUD', () {
    test('create makes the new list active and starts it empty', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final first = prefs.activeListId;

      final created = await prefs.createList('Churrasco');

      expect(prefs.lists, hasLength(2));
      expect(prefs.activeListId, created.id);
      expect(prefs.activeListId, isNot(first));
      expect(prefs.itemsOf(created.id), isEmpty);
    });

    test('a blank name still creates a usable list', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();

      final created = await prefs.createList('   ');

      expect(created.name, 'Nova lista');
    });

    test('items are per list — writing one never touches another', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final a = prefs.activeListId;
      final b = (await prefs.createList('B')).id;

      await prefs.setItemsOf(a, [_item]);
      await prefs.setItemsOf(b, const []);

      expect(prefs.itemsOf(a), hasLength(1));
      expect(prefs.itemsOf(b), isEmpty);
    });

    test('the store pick is per list too', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final a = prefs.activeListId;
      final b = (await prefs.createList('B')).id;

      await prefs.setListStoreOf(a, '1');
      await prefs.setListStoreOf(b, '2');

      expect(prefs.listStoreOf(a), '1');
      expect(prefs.listStoreOf(b), '2');
    });

    test('rename changes only that list, and ignores a blank name', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final id = prefs.activeListId;

      await prefs.renameList(id, 'Casa');
      expect(prefs.lists.single.name, 'Casa');

      await prefs.renameList(id, '   ');
      expect(prefs.lists.single.name, 'Casa', reason: 'a blank rename is a no-op');
    });
  });

  group('delete', () {
    test('deleting a non-active list leaves the active one alone', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final keep = prefs.activeListId;
      final other = (await prefs.createList('Outra')).id;
      await prefs.setActiveListId(keep);

      final nowActive = await prefs.deleteList(other);

      expect(nowActive, keep);
      expect(prefs.activeListId, keep);
      expect(prefs.lists, hasLength(1));
    });

    test('deleting the active list moves to another one', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final first = prefs.activeListId;
      final second = (await prefs.createList('Segunda')).id; // also becomes active

      final nowActive = await prefs.deleteList(second);

      expect(nowActive, first);
      expect(prefs.activeListId, first);
    });

    // Every screen downstream assumes a list exists — leaving the app with
    // none would strand them all.
    test('deleting the last list creates a fresh default rather than none', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final only = prefs.activeListId;

      final nowActive = await prefs.deleteList(only);

      expect(prefs.lists, hasLength(1));
      expect(nowActive, isNotEmpty);
      expect(nowActive, isNot(only));
      expect(prefs.activeListId, nowActive);
      expect(prefs.itemsOf(nowActive), isEmpty);
    });

    test('a deleted list takes its items and store pick with it', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final keep = prefs.activeListId;
      final doomed = (await prefs.createList('Some')).id;
      await prefs.setItemsOf(doomed, [_item]);
      await prefs.setListStoreOf(doomed, '4821');

      await prefs.deleteList(doomed);

      expect(prefs.itemsOf(doomed), isEmpty);
      expect(prefs.listStoreOf(doomed), isNull);
      expect(prefs.activeListId, keep);
    });
  });

  group('activeListId self-heal', () {
    test('a stored id that no longer exists falls back to the first list', () async {
      final prefs = await prefsWith({});
      await prefs.initLists();
      final real = prefs.activeListId;

      await prefs.setActiveListId('a-list-that-was-restored-from-a-backup');

      expect(prefs.activeListId, real);
    });
  });
}
