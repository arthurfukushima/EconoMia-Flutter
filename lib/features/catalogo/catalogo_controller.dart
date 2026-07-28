import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/economia_api.dart';
import '../../data/models/catalog.dart';
import '../../data/models/precos.dart';
import '../../data/prefs.dart';
import '../location/location_controller.dart';

/// The market whose catalog is on screen.
///
/// Seeded from the same `economia.currentStore` key Mercado writes, and
/// written back on every pick: "which market am I in" is one physical fact,
/// not a per-screen one, so choosing here pre-selects it there and vice
/// versa.
final catalogoStoreProvider = StateProvider<String?>(
  (ref) => ref.read(prefsProvider).currentStore,
);

/// The markets to choose between — the same staple-seeded discovery Mercado's
/// picker uses, since Menor Preço has no store directory to ask.
final catalogoStoresProvider = FutureProvider.autoDispose<List<Offer>>((ref) async {
  final location = ref.watch(locationControllerProvider);
  if (location == null) return const [];
  return ref.watch(economiaApiProvider).nearbyStores(location);
});

/// Everything the backend has cached for one market — `/api/catalog`, keyed
/// by the market's `codigo`. Fetched once per market and filtered/sorted
/// client-side (see [CatalogoScreen]) rather than re-fetching per tap: the
/// whole point of the persisted offer log is that a market's assortment
/// doesn't change fast enough to need that.
final catalogoProvider = FutureProvider.autoDispose.family<CatalogResponse?, String>((ref, marketCodigo) async {
  return ref.watch(economiaApiProvider).fetchCatalog(marketCodigo);
});

/// How the catalog list is ordered. `barato` first: the screen's question is
/// "what's worth buying *here*", which is the cheapness ranking, not the
/// alphabet.
enum CatalogoSort {
  barato('Mais barato primeiro'),
  preco('Preço'),
  nome('Nome');

  const CatalogoSort(this.label);

  final String label;
}

final catalogoSortProvider = StateProvider.autoDispose<CatalogoSort>((ref) => CatalogoSort.barato);

/// Active category chip, `null` = todas. Not persisted — reopening the
/// catalog starts unfiltered.
final catalogoCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Filters by category, then orders. Pure, so the ordering rules are testable
/// without a widget or a live catalog.
///
/// An item with no [CatalogItem.pct] (only one market carries it, so there is
/// nothing to be cheaper *than*) sorts last under `barato` rather than
/// claiming the top spot a 0% item has earned.
List<CatalogItem> visibleCatalogItems(
  List<CatalogItem> items, {
  String? category,
  CatalogoSort sort = CatalogoSort.barato,
}) {
  final filtered = category == null
      ? [...items]
      : [for (final i in items) if (i.category == category) i];

  filtered.sort(switch (sort) {
    CatalogoSort.barato => (a, b) => (a.pct ?? 200).compareTo(b.pct ?? 200),
    CatalogoSort.preco => (a, b) => a.priceCents.compareTo(b.priceCents),
    CatalogoSort.nome => (a, b) => a.description.compareTo(b.description),
  });
  return filtered;
}
