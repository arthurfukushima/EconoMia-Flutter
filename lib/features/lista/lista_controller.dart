import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/api_client.dart';
import '../../core/measure.dart';
import '../../core/pooled.dart';
import '../../core/staples.dart';
import '../../data/economia_api.dart';
import '../../data/models/list_item.dart';
import '../../data/models/precos.dart';
import '../../data/models/shopping_list.dart';
import '../../data/prefs.dart';
import '../../domain/lista.dart';
import '../../domain/lista_parse.dart';
import '../../domain/lista_reconcile.dart';
import '../location/location_controller.dart';

/// A catalog product as a list line, or null when the description is empty.
///
/// Top-level because Catálogo builds one of these for the *non-active* list too,
/// where there is no [ListaController] to ask — and two copies of the
/// per-KG-vs-per-package rule is exactly one copy too many.
ListItem? catalogItem(String description) {
  final name = description.trim();
  if (name.isEmpty) return null;
  final read = readCatalogName(name);
  return ListItem(
    id: '${DateTime.now().microsecondsSinceEpoch}-0',
    raw: name,
    name: name,
    unit: read.unit,
    sizeValue: read.size?.value,
    sizeUnit: read.size?.unit,
  );
}

/// Every named list, creation order. Kept apart from the items so switching
/// lists doesn't rebuild the index and renaming doesn't rebuild the items.
final listsProvider = NotifierProvider<ListsController, List<ShoppingList>>(
  ListsController.new,
);

/// Which list is on screen. Everything below is scoped to it: the items, the
/// pricing pass, and the per-list store pick.
final activeListIdProvider = NotifierProvider<ActiveListController, String>(
  ActiveListController.new,
);

/// The active list's items. Loaded from prefs and written back on every edit,
/// so it is never in memory only.
final listaControllerProvider = NotifierProvider<ListaController, List<ListItem>>(
  ListaController.new,
);

/// The index of named lists — create, rename, delete. Deleting the active list
/// (or the last one) moves [activeListIdProvider] itself, since every screen
/// downstream assumes a list exists.
class ListsController extends Notifier<List<ShoppingList>> {
  @override
  List<ShoppingList> build() => ref.read(prefsProvider).lists;

  Future<ShoppingList> create(String name) async {
    final list = await ref.read(prefsProvider).createList(name);
    state = ref.read(prefsProvider).lists;
    // createList also makes it active; mirror that into the provider so the
    // screen switches to the list it just made.
    ref.read(activeListIdProvider.notifier).set(list.id);
    return list;
  }

  Future<void> rename(String id, String name) async {
    await ref.read(prefsProvider).renameList(id, name);
    state = ref.read(prefsProvider).lists;
  }

  Future<void> delete(String id) async {
    final nowActive = await ref.read(prefsProvider).deleteList(id);
    state = ref.read(prefsProvider).lists;
    ref.read(activeListIdProvider.notifier).set(nowActive);
  }
}

class ActiveListController extends Notifier<String> {
  @override
  String build() => ref.read(prefsProvider).activeListId;

  /// Switching lists re-reads that list's items from disk — they were never
  /// in memory for a list that wasn't on screen.
  void set(String id) {
    if (state == id) return;
    state = id;
    ref.read(listaControllerProvider.notifier).reload();
  }
}

/// Which items have a price lookup in flight. Kept out of the list's own state
/// so a request that's still running never blanks a row that already has a
/// price — same split as `locationBusyProvider`.
final listPricingProvider = StateProvider<Set<String>>((ref) => const {});

/// The last pass had at least one failed fetch — the source (Menor Preço / Nota
/// Paraná) is down or rate-limiting. Distinct from "this item has no offers
/// nearby", which is a successful answer.
final listPriceErrorProvider = StateProvider<bool>((ref) => false);

/// One item's lookup result. `precos == null` means the **fetch failed**, which
/// is the signal the never-wipe rule below turns on; a successful lookup that
/// simply found nothing nearby still comes back as a [Precos].
typedef _Result = ({String id, Precos? precos});

class ListaController extends Notifier<List<ListItem>> {
  /// Read through a getter, never cached: a list switch changes which key
  /// every read and write below lands on, and a stale copy would write one
  /// list's items over another's.
  String get _listId => ref.read(activeListIdProvider);

  @override
  List<ListItem> build() => ref.read(prefsProvider).itemsOf(ref.read(activeListIdProvider));

  /// Re-reads the active list from disk. Called when the active list changes —
  /// the items of a list that wasn't on screen were never in memory.
  void reload() {
    state = ref.read(prefsProvider).itemsOf(_listId);
  }

  Future<void> _write(List<ListItem> items) {
    state = items;
    return ref.read(prefsProvider).setItemsOf(_listId, items);
  }

  Future<void> _update(String id, ListItem Function(ListItem item) change) =>
      _write([for (final it in state) if (it.id == id) change(it) else it]);

  ListItem? _byId(String id) {
    for (final it in state) {
      if (it.id == id) return it;
    }
    return null;
  }

  /// Parses a jotted line (or a whole pasted list) and prices what it added.
  ///
  /// New items go on top: the thing you just typed is the thing you are looking
  /// at.
  /// Returns the ids it added, so the screen can offer to undo a whole paste in
  /// one tap — forty bad lines is forty deletions otherwise.
  Future<List<String>> add(String text) async {
    final parsed = parseInput(text, staples: ref.read(staplesProvider));
    if (parsed.isEmpty) return const [];
    // Ids only have to be unique within one list, so a microsecond stamp plus
    // the line's index does it — no uuid dependency for a local key.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final added = [
      for (var i = 0; i < parsed.length; i++)
        ListItem(
          id: '$stamp-$i',
          raw: parsed[i].raw,
          name: parsed[i].name,
          qty: parsed[i].qty,
          unit: parsed[i].unit,
          sizeValue: parsed[i].size?.value,
          sizeUnit: parsed[i].size?.unit,
          parseConf: parsed[i].conf,
          note: parsed[i].note,
        ),
    ];
    await _write([...added, ...state]);
    await _price(added);
    return [for (final it in added) it.id];
  }

  /// Adds a catalog product straight from Catálogo's "+ Lista".
  ///
  /// Not routed through [add]: the store-reported description is a whole
  /// product name, not a jotted line. `readCatalogName` owns the difference —
  /// see it for why "CARNE BOVINA KG" and "ARROZ 1KG" want opposite bases.
  Future<void> addNamed(String description) async {
    final item = catalogItem(description);
    if (item == null) return;
    await _write([item, ...state]);
    await _price([item]);
  }

  Future<void> toggle(String id) =>
      _update(id, (it) => it.copyWith(checked: !it.checked));

  Future<void> remove(String id) => removeMany({id});

  /// Undo for a whole paste — see [add].
  Future<void> removeMany(Set<String> ids) =>
      _write([for (final it in state) if (!ids.contains(it.id)) it]);

  /// Applies one of the readings the row's "?" offered. Re-prices only when the
  /// basis moved, same rule as [setUnit].
  Future<void> resolve(String id, {required double qty, required String unit, Measure? size}) async {
    final before = _byId(id);
    if (before == null) return;
    final after = before.copyWith(
      qty: qty,
      unit: unit,
      sizeValue: size?.value,
      sizeUnit: size?.unit,
      // The user has now said what they meant: the row stops asking, and the
      // reconciler stops being allowed to have an opinion.
      parseConf: ParseConf.high,
      reconciled: true,
    );
    await _write([for (final it in state) if (it.id == id) after else it]);
    if ((before.unit == 'kg') != (unit == 'kg')) await _price([after], force: true);
  }

  /// Switches which of a vague term's candidate products this line is priced
  /// as. No re-fetch: every option's prices came back in the same response.
  Future<void> choose(String id, String key) =>
      _update(id, (it) => it.copyWith(chosenKey: key));

  /// Quantity only scales the line total, so nothing is re-priced.
  Future<void> setQty(String id, double qty) =>
      _update(id, (it) => it.copyWith(qty: qty < 0 ? 0 : qty));

  /// Unit change. `kg` vs not-`kg` **is** the price-search basis upstream, so
  /// crossing that boundary re-matches the item; `un` ↔ `L` does not.
  Future<void> setUnit(String id, String unit) async {
    final before = _byId(id);
    if (before == null || before.unit == unit) return;
    // Hand-set, so the reconciler stays out of it. Someone who switched this to
    // `kg` and got no offers wants to see that, not to be quietly switched back.
    final after = before.copyWith(unit: unit, reconciled: true);
    await _write([for (final it in state) if (it.id == id) after else it]);
    if ((before.unit == 'kg') != (unit == 'kg')) {
      await _price([after], force: true);
    }
  }

  /// Prices whatever is stale — the mount and CEP-change pass. Cheap when
  /// nothing is due, so callers can fire it freely.
  Future<void> priceStale() => _price(state);

  /// "atualizar preços": re-price everything regardless of the cache.
  Future<void> refresh() => _price(state, force: true);

  /// Prices [targets] (only the stale ones unless [force]) and merges the
  /// results back **by id** into whatever the list is when they return — the
  /// user can add, remove or check items while a pass is in flight.
  ///
  /// Pool of 3, not 6: a whole list at once earns Menor Preço 429s, and a 429
  /// is a row that comes back priceless for no reason the user can see.
  ///
  /// **The never-wipe rule.** A failed fetch is skipped entirely, so the item
  /// keeps its old `precos` *and* its old `pricedAt`. Both halves matter: the
  /// prices stay on screen (a rate-limited refresh must not blank a list that
  /// was fine a second ago) and the item stays *stale*, so the next pass tries
  /// again instead of treating the failure as a fresh 12h answer.
  Future<void> _price(List<ListItem> targets, {bool force = false}) async {
    final location = ref.read(locationControllerProvider);
    if (location == null) return;

    final stale = force
        ? targets
        : [for (final it in targets) if (isStale(it, location.cep)) it];
    if (stale.isEmpty) return;

    final ids = {for (final it in stale) it.id};
    final pricing = ref.read(listPricingProvider.notifier);
    pricing.state = {...pricing.state, ...ids};

    try {
      final api = ref.read(economiaApiProvider);
      final results = await pooled(stale, api.config.pricing.listConcurrency, (ListItem it) async {
        try {
          return (
            id: it.id,
            // Only 'kg' asks for a per-KG basis; 'un' and 'L' are left lenient,
            // since packaged goods are priced per unit upstream.
            precos: await api.precosForItem(
              description: it.name,
              unit: it.unit == 'kg' ? 'KG' : '',
              location: location,
            ),
          ) as _Result;
        } on ApiException {
          return (id: it.id, precos: null) as _Result;
        }
      });

      ref.read(listPriceErrorProvider.notifier).state =
          results.any((r) => r.precos == null);

      final priced = {
        for (final r in results)
          if (r.precos != null) r.id: r.precos!,
      };
      final now = DateTime.now().millisecondsSinceEpoch;

      // Reconciliation, the moment the evidence exists: real product names are
      // what settle "12 Ovos", and this is the only point in the app where they
      // and the parse are both in hand. See `lista_reconcile.dart`.
      final staples = ref.read(staplesProvider);
      final next = <ListItem>[];
      final again = <ListItem>[];
      for (final it in state) {
        final precos = priced[it.id];
        if (precos == null) {
          next.add(it);
          continue;
        }
        final fresh =
            it.copyWith(precos: precos, pricedAt: now, pricedCep: location.cep);
        final read = reconcile(fresh, precos, staples);
        next.add(read.item);
        if (read.reprice) again.add(read.item);
      }
      await _write(next);

      // At most one extra round trip, and only for an item whose *search* the
      // reconciler changed. It marked those `reconciled`, so this cannot loop.
      if (again.isNotEmpty) await _price(again, force: true);
    } finally {
      pricing.state = {...pricing.state}..removeAll(ids);
    }
  }
}
