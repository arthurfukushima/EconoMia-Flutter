import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categoria.dart';
import '../../core/money.dart';
import '../../data/economia_api.dart';
import '../../data/models/catalog.dart';
import '../../data/models/list_item.dart';
import '../../data/models/precos.dart';
import '../../data/models/shopping_list.dart';
import '../../data/prefs.dart';
import '../../theme/tokens.dart';
import '../../widgets/card_list.dart';
import '../../widgets/location_bar.dart';
import '../../widgets/store_picker.dart';
import '../lista/lista_controller.dart';
import '../location/location_controller.dart';
import 'catalogo_controller.dart';

/// Everything cached for one market, browsable without scanning a single item
/// — "I'm about to walk in, what's worth buying here rather than elsewhere".
///
/// Backed by every offer `/api/precos` has already persisted nearby, so it
/// fills in as products get priced in the region; a market nobody has priced
/// anything at yet gets an honest "ainda vazio", never a fabricated
/// assortment. Each row is scored against the same product's price at every
/// other market in the município.
class CatalogoScreen extends ConsumerStatefulWidget {
  const CatalogoScreen({super.key, this.marketCodigo, this.marketLabel});

  /// When opened from Mercado, the market is already known. From Home it is
  /// null and the picker below chooses one (seeded from the last market the
  /// user said they were in).
  final String? marketCodigo;
  final String? marketLabel;

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  @override
  void initState() {
    super.initState();
    // An explicitly routed market wins over whatever the shared picker state
    // was last left on — arriving from Mercado's "ver catálogo deste mercado"
    // must show *that* market, not the one this provider happened to hold.
    final cod = widget.marketCodigo;
    if (cod != null) {
      ref.read(catalogoStoreProvider.notifier).state = cod;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);
    final storesAsync = ref.watch(catalogoStoresProvider);
    final stores = storesAsync.value ?? const <Offer>[];
    final selected = ref.watch(catalogoStoreProvider) ?? widget.marketCodigo;

    Offer? here;
    for (final s in stores) {
      if (s.cod == selected) {
        here = s;
        break;
      }
    }
    final label = here != null
        ? storeLabel(here)
        : widget.marketLabel ??
            (storesAsync.isLoading
                ? 'carregando mercados…'
                : stores.isEmpty
                    ? 'toque para buscar o mercado'
                    : 'selecione o mercado');

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          const LocationBar(),
          if (location == null)
            const Expanded(
              child: _Banner(text: 'Informe seu CEP acima para ver o catálogo dos mercados perto de você.'),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: StorePickerRow(
                prefix: '🏪 Mercado: ',
                label: label,
                onTap: () async {
                  final picked = await showStorePicker(
                    context,
                    stores: stores,
                    selectedCod: selected,
                    title: 'Ver o catálogo de',
                    loading: storesAsync.isLoading,
                    onSearch: (term) => ref.read(economiaApiProvider).searchStores(term, location),
                  );
                  final store = picked?.store;
                  if (store?.cod == null) return;
                  ref.read(catalogoStoreProvider.notifier).state = store!.cod;
                  // Same key Mercado reads: standing in a shop is one fact.
                  await ref.read(prefsProvider).setCurrentStore(store.cod);
                },
              ),
            ),
            Expanded(
              child: selected == null
                  ? const _Banner(text: 'Escolha um mercado acima para ver o que ele tem em catálogo.')
                  : _Catalog(marketCodigo: selected),
            ),
          ],
        ],
      ),
    );
  }
}

class _Catalog extends ConsumerWidget {
  const _Catalog({required this.marketCodigo});

  final String marketCodigo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(catalogoProvider(marketCodigo));

    return switch (async) {
      AsyncData(:final value) when value != null && value.items.isNotEmpty =>
        _CatalogList(catalog: value),
      AsyncData() => const _Banner(
          text: 'Ainda não temos produtos em cache para este mercado. Escaneie notas ou '
              'produtos por perto para começar a preencher o catálogo.',
        ),
      AsyncError() => _Banner(
          text: 'Não foi possível carregar o catálogo agora. Tente novamente.',
          danger: true,
          onRetry: () => ref.invalidate(catalogoProvider(marketCodigo)),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.danger = false, this.onRetry});

  final String text;
  final bool danger;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(color: danger ? sa.danger : sa.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('tentar de novo')),
            ],
          ],
        ),
      ),
    );
  }
}

class _CatalogList extends ConsumerWidget {
  const _CatalogList({required this.catalog});

  final CatalogResponse catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final category = ref.watch(catalogoCategoryProvider);
    final sort = ref.watch(catalogoSortProvider);
    final items = visibleCatalogItems(catalog.items, category: category, sort: sort);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: 'Todas (${catalog.items.length})',
                selected: category == null,
                onTap: () => ref.read(catalogoCategoryProvider.notifier).state = null,
              ),
              for (final entry in catalog.categories.entries)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _CategoryChip(
                    label: '${Categoria.fromKey(entry.key).emoji} '
                        '${Categoria.fromKey(entry.key).label} (${entry.value})',
                    selected: category == entry.key,
                    onTap: () => ref.read(catalogoCategoryProvider.notifier).state = entry.key,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('Ordenar por ', style: theme.textTheme.labelMedium!.copyWith(color: sa.muted)),
            DropdownButton<CatalogoSort>(
              value: sort,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: theme.textTheme.labelMedium,
              items: [
                for (final s in CatalogoSort.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (s) {
                if (s != null) ref.read(catalogoSortProvider.notifier).state = s;
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nada nesta categoria ainda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
            ),
          )
        else
          CardList(children: [for (final i in items) _CatalogRow(item: i)]),
        const SizedBox(height: 10),
        Text(
          'Preços de notas fiscais recentes na sua região (Menor Preço / Nota Paraná) '
          '— últimos ~45 dias.',
          style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: sa.tintGreen,
      backgroundColor: sa.paper2,
      labelStyle: theme.textTheme.labelMedium,
    );
  }
}

/// One product: what it costs here, how that ranks against the same product
/// elsewhere nearby, and a one-tap add to the shopping list.
class _CatalogRow extends ConsumerWidget {
  const _CatalogRow({required this.item});

  final CatalogItem item;

  /// Adds to [listId], which may not be the list on screen — so the
  /// confirmation names it. Adding to another list deliberately does **not**
  /// switch the active one: you're browsing a market, not moving house.
  Future<void> _addTo(BuildContext context, WidgetRef ref, String listId, String listName) async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = ref.read(prefsProvider);

    if (listId == ref.read(activeListIdProvider)) {
      await ref.read(listaControllerProvider.notifier).addNamed(item.description);
    } else {
      // A list that isn't loaded has no controller — write it straight to its
      // own key. It gets priced the next time that list is opened, which is
      // the same "stale on open" pass every list already runs.
      await prefs.setItemsOf(listId, [
        ListItem(
          id: '${DateTime.now().microsecondsSinceEpoch}-0',
          raw: item.description,
          name: item.description,
          unit: RegExp(r'\bKG\b', caseSensitive: false).hasMatch(item.description) ? 'kg' : 'un',
        ),
        ...prefs.itemsOf(listId),
      ]);
    }

    messenger.showSnackBar(
      SnackBar(content: Text('${item.description} → $listName'), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _chooseListAndAdd(BuildContext context, WidgetRef ref) async {
    final lists = ref.read(listsProvider);
    final picked = await showModalBottomSheet<ShoppingList>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Adicionar a qual lista?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final l in lists)
                      ListTile(
                        leading: const Text('📋', style: TextStyle(fontSize: 18)),
                        title: Text(l.name, style: Theme.of(context).textTheme.bodyMedium),
                        onTap: () => Navigator.pop(context, l),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await _addTo(context, ref, picked.id, picked.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final cat = Categoria.fromKey(item.category);
    // Already on the list? Match on the same text the add writes, so a
    // re-render (or a return to this screen) still shows it as added.
    final added = ref.watch(listaControllerProvider).any(
          (i) => i.name.toLowerCase() == item.description.toLowerCase(),
        );
    // The button names the list it will add to — with several lists, "+ Lista"
    // alone doesn't say where the item is going.
    final lists = ref.watch(listsProvider);
    final activeId = ref.watch(activeListIdProvider);
    var activeListName = 'Lista';
    for (final l in lists) {
      if (l.id == activeId) activeListName = l.name;
    }

    // How this price compares: null pct means only one market carries it, so
    // there is nothing to be cheaper than — the meta line below says so on its
    // own and a badge would only repeat it.
    final (badgeText, badgeColor) = switch (item) {
      CatalogItem(pct: null) => (null, sa.muted),
      CatalogItem(pct: 0) => ('melhor preço', sa.green),
      CatalogItem(:final pct, :final bucket) => (
          '+$pct%',
          switch (bucket) { 'otimo' => sa.green, 'ok' => sa.amber, _ => sa.danger },
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Semantics(
                label: cat.label,
                excludeSemantics: true,
                child: Text(cat.emoji, style: const TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.description, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 8),
            Text(formatBRL(item.priceCents), style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 23),
          child: Text.rich(
            TextSpan(
              style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
              children: [
                if (badgeText != null) ...[
                  TextSpan(
                    text: badgeText,
                    style: theme.textTheme.labelMedium!.copyWith(color: badgeColor),
                  ),
                  const TextSpan(text: ' · '),
                ],
                TextSpan(
                  text: item.nStores > 1
                      ? '${item.rank}º mais barato de ${item.nStores} mercados · '
                          'região ${formatRangeBRL(item.minCents, item.maxCents)}'
                      : 'preço único encontrado na região',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 19),
            child: added
                ? Text(
                    '✓ em $activeListName',
                    style: theme.textTheme.labelMedium!.copyWith(color: sa.green),
                  )
                : GestureDetector(
                    // Long-press to send it somewhere other than the active
                    // list. The reference asked "which list?" on the first add
                    // of every market visit; naming the target on the button
                    // itself answers that question without a modal in the way
                    // of the common case (adding to the list you're on).
                    onLongPress: () => _chooseListAndAdd(context, ref),
                    child: TextButton(
                      onPressed: () => _addTo(context, ref, activeId, activeListName),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('+ $activeListName'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
