import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/api_client.dart';
import '../../core/pooled.dart';
import '../../data/economia_api.dart';
import '../../data/models/list_item.dart';
import '../../data/models/precos.dart';
import '../../data/prefs.dart';
import '../../domain/lista.dart';
import '../../domain/lista_parse.dart';
import '../location/location_controller.dart';

/// The shopping list itself. Loaded from prefs at startup and written back on
/// every edit, so it is never in memory only.
final listaControllerProvider = NotifierProvider<ListaController, List<ListItem>>(
  ListaController.new,
);

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
  @override
  List<ListItem> build() => ref.read(prefsProvider).shoppingList;

  Future<void> _write(List<ListItem> items) {
    state = items;
    return ref.read(prefsProvider).setShoppingList(items);
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
  Future<void> add(String text) async {
    final parsed = parseInput(text);
    if (parsed.isEmpty) return;
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
        ),
    ];
    await _write([...added, ...state]);
    await _price(added);
  }

  Future<void> toggle(String id) =>
      _update(id, (it) => it.copyWith(checked: !it.checked));

  Future<void> remove(String id) =>
      _write([for (final it in state) if (it.id != id) it]);

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
    final after = before.copyWith(unit: unit);
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
      final results = await pooled(stale, 3, (ListItem it) async {
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
      await _write([
        for (final it in state)
          if (priced.containsKey(it.id))
            it.copyWith(precos: priced[it.id], pricedAt: now, pricedCep: location.cep)
          else
            it,
      ]);
    } finally {
      pricing.state = {...pricing.state}..removeAll(ids);
    }
  }
}
