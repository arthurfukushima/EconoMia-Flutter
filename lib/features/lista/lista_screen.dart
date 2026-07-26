import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/economia_api.dart';
import '../../data/models/list_item.dart';
import '../../data/models/precos.dart';
import '../../data/models/shopping_list.dart';
import '../../data/prefs.dart';
import '../../domain/lista.dart';
import '../../domain/stores.dart';
import '../../theme/tokens.dart';
import '../../widgets/card_list.dart';
import '../../widgets/cat_chip.dart';
import '../../widgets/offer_span.dart';
import '../../widgets/store_picker.dart';
import '../location/location_controller.dart';
import 'lista_controller.dart';

/// `4` → "4", `1.5` → "1,5" — no trailing zeros, pt-BR decimal comma.
String _num(double v) =>
    v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');

String _qtyText(ListItem it) => '${_num(it.qty)} ${it.unit}';

String _plural(int n, String one, String many) => n == 1 ? one : many;

/// "Minha lista" — jot the list your own way (a category, a brand, or with a
/// quantity) and each line is best-effort priced across nearby markets.
///
/// Prices are cached 12h per item (see `domain/lista.dart`), so opening this
/// notepad-frequency tab does not re-hit a rate-limited source. Stale items are
/// re-priced on first open and whenever the CEP changes.
class ListaScreen extends ConsumerStatefulWidget {
  const ListaScreen({super.key});

  @override
  ConsumerState<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends ConsumerState<ListaScreen> {
  final _input = TextEditingController();

  /// The market the list is priced at, or null for "menor preço por perto".
  /// Seeded from the last choice, which is why it survives a restart.
  String? _selCod;

  bool _showMarkets = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _selCod = ref.read(prefsProvider).listStoreOf(ref.read(activeListIdProvider));
    // After the first frame: the list is worth reading before the network is
    // touched, exactly as on the receipt screen.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(listaControllerProvider.notifier).priceStale(),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _selectStore(String? cod) {
    setState(() => _selCod = cod);
    ref.read(prefsProvider).setListStoreOf(ref.read(activeListIdProvider), cod);
  }

  /// Switching lists brings its own items, its own store pick and its own
  /// name-searched markets — none of the current list's state carries over.
  void _switchList(String id) {
    ref.read(activeListIdProvider.notifier).set(id);
    setState(() {
      _selCod = ref.read(prefsProvider).listStoreOf(id);
      _extra = const [];
      _showMarkets = false;
    });
    ref.read(listaControllerProvider.notifier).priceStale();
  }

  Future<void> _openListMenu() async {
    final lists = ref.read(listsProvider);
    final activeId = ref.read(activeListIdProvider);
    final action = await showModalBottomSheet<_ListAction>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ListMenu(lists: lists, activeId: activeId),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _Switch(:final id):
        _switchList(id);
      case _Create():
        final name = await _promptName(title: 'Nova lista', initial: '');
        if (name == null || !mounted) return;
        final created = await ref.read(listsProvider.notifier).create(name);
        if (!mounted) return;
        _switchList(created.id);
      case _Rename(:final id, :final currentName):
        final name = await _promptName(title: 'Renomear lista', initial: currentName);
        if (name == null) return;
        await ref.read(listsProvider.notifier).rename(id, name);
      case _Delete(:final id, :final currentName):
        final ok = await _confirmDelete(currentName);
        if (ok != true) return;
        await ref.read(listsProvider.notifier).delete(id);
        if (!mounted) return;
        // delete() moves the active id itself (it may have been the active
        // list, or the last one) — resync this screen to wherever it landed.
        _switchList(ref.read(activeListIdProvider));
    }
  }

  Future<String?> _promptName({required String title, required String initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: Churrasco, Casa, Mês'),
          onSubmitted: (v) => Navigator.pop(context, v.trim().isEmpty ? null : v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              Navigator.pop(context, v.isEmpty ? null : v);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<bool?> _confirmDelete(String name) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Apagar "$name"?'),
          content: const Text('Os itens desta lista e os preços já buscados serão perdidos.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apagar'),
            ),
          ],
        ),
      );

  Future<void> _add() async {
    final text = _input.text;
    _input.clear();
    await ref.read(listaControllerProvider.notifier).add(text);
  }

  Future<void> _openStorePicker(List<Offer> stores, String? effectiveCod) async {
    final location = ref.read(locationControllerProvider);
    final picked = await showStorePicker(
      context,
      stores: stores,
      selectedCod: effectiveCod,
      title: 'Preços em',
      noneLabel: 'Menor preço por perto',
      onSearch: (term) => location == null
          ? Future.value(const <Offer>[])
          : ref.read(economiaApiProvider).searchStores(term, location),
    );
    // null = dismissed; a null `store` inside a result is the explicit
    // "menor preço por perto" pick.
    if (picked == null) return;
    if (picked.store != null) {
      setState(() => _extra = mergeStores(_extra, [picked.store!]));
    }
    _selectStore(picked.store?.cod);
  }

  /// Markets found by name search — they may carry nothing on the list, so they
  /// are not derivable from the items and have to be remembered here.
  List<Offer> _extra = const [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final items = ref.watch(listaControllerProvider);
    final pricing = ref.watch(listPricingProvider);
    final priceError = ref.watch(listPriceErrorProvider);
    final location = ref.watch(locationControllerProvider);

    // A CEP change makes every cached price about somewhere else, so the pass
    // re-runs. `isStale` decides what actually needs a fetch.
    ref.listen(locationControllerProvider, (_, _) {
      ref.read(listaControllerProvider.notifier).priceStale();
    });

    final stores = mergeStores(listStores(items), _extra);
    // A market that no longer carries anything listed (its only item was
    // removed, or its re-price failed) would strand every row on "sem preço
    // neste mercado" — so a selection that isn't in the picker any more simply
    // doesn't apply. The stored pick is left alone: it becomes valid again as
    // soon as that market carries something.
    final effectiveCod = stores.any((s) => s.cod == _selCod) ? _selCod : null;
    Offer? here;
    for (final s in stores) {
      if (s.cod == effectiveCod) here = s;
    }
    final basket = effectiveCod == null ? null : basketAt(items, effectiveCod);
    final ranking = marketRanking(items);

    final lists = ref.watch(listsProvider);
    final activeId = ref.watch(activeListIdProvider);
    var activeName = 'Minha Lista';
    for (final l in lists) {
      if (l.id == activeId) activeName = l.name;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _ListHeader(name: activeName, count: lists.length, onTap: _openListMenu),
        const SizedBox(height: 10),
        _AddForm(controller: _input, onSubmit: _input.text.trim().isEmpty ? null : _add),
        if (location == null) ...[
          const SizedBox(height: 12),
          _Banner(text: 'Informe seu CEP acima para comparar os preços dos itens.'),
        ],
        if (location != null && priceError) ...[
          const SizedBox(height: 12),
          _Banner(
            error: true,
            text: 'Não foi possível consultar os preços agora — a fonte (Menor Preço / Nota '
                'Paraná) está indisponível. Seus itens estão salvos; tente "atualizar preços" '
                'em instantes.',
          ),
        ],
        const SizedBox(height: 18),
        if (items.isEmpty)
          Text(
            'Sua lista está vazia. Escreva do seu jeito — categoria (Carne), marca (Toddy) ou '
            'com quantidade (4x Tomates) — e a Mia procura o melhor preço por perto.',
            style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
          )
        else ...[
          Row(
            children: [
              // Not "Minha lista" any more — the header above names the
              // active list, and repeating a wrong name here would be worse
              // than saying nothing.
              Expanded(
                child: Text('Itens (${items.length})', style: theme.textTheme.titleMedium),
              ),
              if (location != null)
                TextButton(
                  onPressed: pricing.isEmpty
                      ? () => ref.read(listaControllerProvider.notifier).refresh()
                      : null,
                  child: const Text('atualizar preços'),
                ),
            ],
          ),
          if (stores.isNotEmpty) ...[
            const SizedBox(height: 4),
            StorePickerRow(
              prefix: '🏪 Preços em: ',
              label: here != null ? storeLabel(here) : 'Menor preço por perto',
              onTap: () => _openStorePicker(stores, effectiveCod),
            ),
          ],
          if (here != null && basket != null) ...[
            const SizedBox(height: 10),
            _BasketSummary(here: here, basket: basket, itemCount: items.length),
          ],
          const SizedBox(height: 10),
          CardList(
            children: [
              for (final it in items)
                _ItemRow(
                  item: it,
                  loading: pricing.contains(it.id),
                  cod: effectiveCod,
                ),
            ],
          ),
          if (ranking.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => setState(() => _showMarkets = !_showMarkets),
                child: Text(_showMarkets ? 'Ocultar mercados' : 'Procurar Mercados'),
              ),
            ),
            if (_showMarkets) ...[
              const SizedBox(height: 10),
              CardList(
                children: [
                  for (final m in ranking)
                    _MarketRow(
                      market: m,
                      itemCount: items.length,
                      selected: m.cod == effectiveCod,
                      onTap: () => _selectStore(m.cod),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 12),
          Text(
            'Preços de notas fiscais recentes na sua região (Menor Preço / Nota Paraná).',
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          ),
        ],
      ],
    );
  }
}

class _AddForm extends StatelessWidget {
  const _AddForm({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            // A single-line field (maxLines: 1) discards every newline in
            // its value, typed or pasted — so pasting a multi-line list out
            // of Notes/WhatsApp would silently collapse into one run-on
            // item. Unbounded so those newlines survive into `_add()`,
            // which already splits on them (`parseInput`); submission stays
            // on the button, not Enter, since Enter now means "new line".
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Ex: 4x Tomates, 1.5kg Carne, Toddy… (ou cole uma lista)',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: onSubmit, child: const Text('Adicionar')),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? sa.dangerBg : sa.paper2,
        borderRadius: SaRadius.smAll,
        border: Border.all(color: error ? sa.danger : sa.stroke, width: 1.5),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium!.copyWith(color: error ? sa.danger : sa.ink),
      ),
    );
  }
}

/// What the whole list costs at the picked market — with the coverage count in
/// front of it, because a total over 6 of 10 items is not a shopping total.
class _BasketSummary extends StatelessWidget {
  const _BasketSummary({required this.here, required this.basket, required this.itemCount});

  final Offer here;
  final ListBasket basket;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final complete = basket.carried == itemCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sa.paper,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏪 ${storeLabel(here)}', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium!.copyWith(color: complete ? sa.ink : sa.muted),
              children: [
                TextSpan(
                  text: '${basket.carried} de $itemCount '
                      '${_plural(itemCount, "item", "itens")} · total ',
                ),
                TextSpan(
                  text: formatBRL(basket.totalCents),
                  style: theme.textTheme.titleSmall!.copyWith(color: sa.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the list: check it off, adjust how much of it you want, and see
/// what it costs — either cheapest nearby or at the picked market.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item, required this.loading, required this.cod});

  final ListItem item;
  final bool loading;
  final String? cod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final controller = ref.read(listaControllerProvider.notifier);
    final active = activeOption(item);
    final options = item.precos?.options ?? const <ProductOption>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: item.checked,
              onChanged: (_) => controller.toggle(item.id),
              semanticLabel: 'marcar ${item.name}',
              visualDensity: VisualDensity.compact,
            ),
            CatChip(description: item.name, ncm: active?.ncm),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.name,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: item.checked ? sa.muted : sa.ink,
                  decoration: item.checked ? TextDecoration.lineThrough : null,
                  decorationColor: sa.muted,
                ),
              ),
            ),
            IconButton(
              onPressed: () => controller.remove(item.id),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: sa.muted,
              tooltip: 'remover ${item.name}',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: _QtyRow(item: item, controller: controller),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: _PriceLine(item: item, active: active, loading: loading, cod: cod),
        ),
        if (options.length > 1)
          _Collapse(
            title: 'trocar produto (${options.length} opções)',
            children: [
              // Tier 1 (the literal product typed) and tier 2 (formulation/
              // packaging variants — Zero, Retornável, ...) as two groups, not
              // one flat list — a variant must stay reachable without ever
              // competing visually with the literal match. The backend
              // already sorts tier 1 before tier 2, so this only draws the
              // split; it doesn't re-order anything.
              for (final o in options)
                if (o.tier != 2)
                  _OptionTile(
                    option: o,
                    selected: o.key == active?.key,
                    onTap: () => controller.choose(item.id, o.key),
                  ),
              if (options.any((o) => o.tier == 2)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text('variações', style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Theme.of(context).sa.muted)),
                ),
                for (final o in options)
                  if (o.tier == 2)
                    _OptionTile(
                      option: o,
                      selected: o.key == active?.key,
                      onTap: () => controller.choose(item.id, o.key),
                    ),
              ],
            ],
          ),
        if ((active?.stores.length ?? 0) > 1)
          _Collapse(
            title: 'ver ${active!.stores.length} mercados',
            children: [
              for (final s in active.stores)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: StoreRow(offer: s),
                ),
            ],
          ),
      ],
    );
  }
}

/// `−  1,5 kg  +` plus the unit. Stepping beats a free-text field on a phone,
/// and exact quantities are already handled where they are natural: typing
/// "1.5kg Carne" into the add box.
class _QtyRow extends StatelessWidget {
  const _QtyRow({required this.item, required this.controller});

  final ListItem item;
  final ListaController controller;

  /// `un` counts whole; `kg`/`L` move in tenths, which is the granularity a
  /// scale or a bottle actually has.
  double get _step => item.unit == 'un' ? 1 : 0.1;

  void _bump(double by) {
    final next = ((item.qty + by) * 10).round() / 10;
    if (next < _step) return;
    controller.setQty(item.id, next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Row(
      children: [
        _StepButton(icon: Icons.remove_rounded, label: 'menos', onTap: () => _bump(-_step)),
        SizedBox(
          width: 48,
          child: Text(
            // The number only — the unit is the dropdown right beside it.
            _num(item.qty),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge,
            semanticsLabel: 'quantidade de ${item.name}: ${_qtyText(item)}',
          ),
        ),
        _StepButton(icon: Icons.add_rounded, label: 'mais', onTap: () => _bump(_step)),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: item.unit,
          isDense: true,
          underline: const SizedBox.shrink(),
          style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          onChanged: (u) => u == null ? null : controller.setUnit(item.id, u),
          items: const [
            DropdownMenuItem(value: 'un', child: Text('un')),
            DropdownMenuItem(value: 'kg', child: Text('kg')),
            DropdownMenuItem(value: 'L', child: Text('L')),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: sa.paper2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 16, color: sa.ink)),
        ),
      ),
    );
  }
}

/// The row's price, in whichever of its states is true — never a fabricated
/// zero.
class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.item,
    required this.active,
    required this.loading,
    required this.cod,
  });

  final ListItem item;
  final ProductOption? active;
  final bool loading;
  final String? cod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final body = theme.textTheme.labelMedium!;
    final muted = body.copyWith(color: sa.muted);

    if (loading) return Text('procurando preços…', style: muted);
    if (item.precos == null) {
      return Text('preço indisponível — toque em "atualizar preços"', style: muted);
    }

    if (cod != null) {
      final here = offerAt(item, cod!);
      if (here == null) {
        return Text(
          (active?.stores.isNotEmpty ?? false) ? 'sem preço neste mercado' : 'sem preço por perto',
          style: muted,
        );
      }
      return Text.rich(
        TextSpan(
          style: body,
          children: [
            if ((active?.name ?? '').isNotEmpty) TextSpan(text: '${active!.name} '),
            TextSpan(
              text: formatBRL(lineCents(here.priceCents, item.qty)),
              style: theme.textTheme.titleSmall!.copyWith(color: sa.green),
            ),
            if (item.qty != 1)
              TextSpan(
                text: ' (${_qtyText(item)} × ${formatBRL(here.priceCents)})',
                style: muted,
              ),
          ],
        ),
      );
    }

    final cheapest = active?.cheapest;
    if (cheapest == null) return Text('sem preço por perto', style: muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((active?.name ?? '').isNotEmpty) Text(active!.name!, style: body),
        OfferSpan(offer: cheapest),
      ],
    );
  }
}

/// One candidate product behind a vague term ("Carne", "Toddy"), with what it
/// costs and how widely it was found — the two things that tell you whether it
/// is the one you meant.
class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, required this.selected, required this.onTap});

  final ProductOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final price = option.cheapest?.priceCents;

    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? sa.tintGreen : sa.paper2,
        borderRadius: SaRadius.smAll,
        child: InkWell(
          borderRadius: SaRadius.smAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(option.name ?? 'produto', style: theme.textTheme.labelMedium),
                ),
                const SizedBox(width: 8),
                Text(
                  '${price == null ? '—' : formatBRL(price)} · ${option.nStores} '
                  '${_plural(option.nStores, "mercado", "mercados")}',
                  style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One market's standing against the whole list: coverage first, then the
/// partial total — and labelled as partial, because that is what it is.
class _MarketRow extends StatelessWidget {
  const _MarketRow({
    required this.market,
    required this.itemCount,
    required this.selected,
    required this.onTap,
  });

  final MarketOption market;
  final int itemCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final where = [
      market.store ?? 'Loja',
      if ((market.bairro ?? '').isNotEmpty) market.bairro!,
    ].join(' · ');
    final km = market.km == null ? '' : ' (${_num(market.km!)} km)';

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏪 $where$km',
                  style: selected
                      ? theme.textTheme.titleSmall!.copyWith(color: sa.amberPress)
                      : theme.textTheme.bodyMedium,
                ),
                Text(
                  '${market.count} de $itemCount ${_plural(itemCount, "item", "itens")} · total parcial',
                  style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatBRL(market.totalCents),
            style: theme.textTheme.titleSmall!.copyWith(color: sa.green),
          ),
        ],
      ),
    );
  }
}

/// The app's collapsible: no divider lines, tight padding, left-aligned
/// children — same shape Mercado uses for its nutrition panel.
class _Collapse extends StatelessWidget {
  const _Collapse({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(title, style: theme.textTheme.labelLarge!.copyWith(color: theme.sa.amberPress)),
        children: [
          for (final child in children)
            Align(alignment: Alignment.centerLeft, child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multiple lists
// ---------------------------------------------------------------------------

/// What the list menu resolved to. A sealed family rather than a callback per
/// row so the sheet stays a pure chooser — every action is performed by the
/// screen, which is the thing that can await a dialog and resync itself.
sealed class _ListAction {
  const _ListAction();
}

class _Switch extends _ListAction {
  const _Switch(this.id);
  final String id;
}

class _Create extends _ListAction {
  const _Create();
}

class _Rename extends _ListAction {
  const _Rename(this.id, this.currentName);
  final String id;
  final String currentName;
}

class _Delete extends _ListAction {
  const _Delete(this.id, this.currentName);
  final String id;
  final String currentName;
}

/// The active list's name, and the way into the list menu.
class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.name, required this.count, required this.onTap});

  final String name;

  /// How many lists exist. One is the ordinary case, so the "de N" suffix only
  /// appears once there is genuinely a choice to make.
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Material(
      color: sa.paper2,
      borderRadius: SaRadius.smAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: SaRadius.smAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Text('📋 ', style: TextStyle(fontSize: 15)),
              Expanded(
                child: Text(name, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
              ),
              if (count > 1)
                Text('1 de $count  ', style: theme.textTheme.labelMedium!.copyWith(color: sa.muted)),
              Icon(Icons.expand_more_rounded, color: sa.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch to another list, or create/rename/delete one.
class _ListMenu extends StatelessWidget {
  const _ListMenu({required this.lists, required this.activeId});

  final List<ShoppingList> lists;
  final String activeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Suas listas', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final l in lists)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        l.id == activeId ? '📋' : '📄',
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(l.name, style: theme.textTheme.bodyMedium),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (l.id == activeId)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_rounded, size: 18, color: sa.green),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            tooltip: 'renomear ${l.name}',
                            color: sa.muted,
                            onPressed: () => Navigator.pop(context, _Rename(l.id, l.name)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            tooltip: 'apagar ${l.name}',
                            color: sa.muted,
                            onPressed: () => Navigator.pop(context, _Delete(l.id, l.name)),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, _Switch(l.id)),
                    ),
                ],
              ),
            ),
            const Divider(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('✨', style: TextStyle(fontSize: 18)),
              title: Text('Nova lista', style: theme.textTheme.bodyMedium),
              onTap: () => Navigator.pop(context, const _Create()),
            ),
          ],
        ),
      ),
    );
  }
}
