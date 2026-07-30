import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/measure.dart';
import '../../core/money.dart';
import '../../data/economia_api.dart';
import '../../data/models/list_item.dart';
import '../../data/models/precos.dart';
import '../../data/models/shopping_list.dart';
import '../../data/prefs.dart';
import '../../domain/lista.dart';
import '../../domain/lista_parse.dart';
import '../../domain/stores.dart';
import '../../domain/lista_share.dart';
import '../../theme/tokens.dart';
import '../../widgets/cat_chip.dart';
import '../../widgets/store_picker.dart';
import '../location/location_controller.dart';
import 'lista_controller.dart';

/// `4` → "4", `1.5` → "1,5" — no trailing zeros, pt-BR decimal comma.
String _num(double v) => v
    .toStringAsFixed(3)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

String _qtyText(ListItem it) => '${_num(it.qty)} ${it.unit}';

String _plural(int n, String one, String many) => n == 1 ? one : many;

Future<String?> _showEditItemDialog(BuildContext context, String initial) =>
    showDialog<String>(
      context: context,
      builder: (context) => _TextPromptDialog(
        title: 'Editar item',
        initial: initial,
        hintText: 'Nome do item',
      ),
    );

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.hintText,
    this.initial = '',
  });

  final String title;
  final String hintText;
  final String initial;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    Navigator.pop(context, value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _selCod = ref
        .read(prefsProvider)
        .listStoreOf(ref.read(activeListIdProvider));
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
        final name = await _showNamePrompt(title: 'Nova lista', initial: '');
        if (name == null || !mounted) return;
        final created = await ref.read(listsProvider.notifier).create(name);
        if (!mounted) return;
        _switchList(created.id);
      case _Rename(:final id, :final currentName):
        final name = await _showNamePrompt(
          title: 'Renomear lista',
          initial: currentName,
        );
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

  Future<String?> _showNamePrompt({
    required String title,
    required String initial,
  }) => showDialog<String>(
    context: context,
    builder: (context) => _TextPromptDialog(
      title: title,
      initial: initial,
      hintText: 'Ex: Churrasco, Casa, MÃªs',
    ),
  );

  Future<bool?> _confirmDelete(String name) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Apagar "$name"?'),
      content: const Text(
        'Os itens desta lista e os preços já buscados serão perdidos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
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
    final ids = await ref.read(listaControllerProvider.notifier).add(text);
    if (!mounted || ids.length <= 1) return;
    // A single line earns no snackbar — mistyping one item is fixed with the
    // row's own remove button. A paste is different: forty bad lines would
    // otherwise be forty individual deletions.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ids.length} itens adicionados'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => ref
              .read(listaControllerProvider.notifier)
              .removeMany(ids.toSet()),
        ),
      ),
    );
  }

  Future<void> _shareList(String name, List<ListItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione itens antes de compartilhar.')),
      );
      return;
    }

    final text = formatShoppingListForShare(listName: name, items: items);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, title: name),
      );
      if (!mounted || result.status != ShareResultStatus.unavailable) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O compartilhamento não está disponível.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível compartilhar a lista.')),
      );
    }
  }

  Future<void> _openStorePicker(
    List<Offer> stores,
    String? effectiveCod,
  ) async {
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

  /// The whole market comparison: best market for the list, whether a second
  /// stop pays for itself, and every market ranked. Picking one prices the list
  /// there — that is what the market summary shows.
  ///
  /// Markets reached by name search (`_extra`) carry nothing listed, so they
  /// have no `MarketOption` and are rightly absent here.
  Future<void> _openCompare(String? effectiveCod) async {
    final planning = [
      for (final i in ref.read(listaControllerProvider))
        if (!i.checked) i,
    ];
    final markets = marketRanking(planning);
    if (markets.isEmpty) return;

    final anchor =
        effectiveCod != null && markets.any((m) => m.cod == effectiveCod)
        ? effectiveCod
        : markets.first.cod;

    final market = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MarketsSheet(
        markets: markets,
        items: planning,
        anchorCod: anchor,
        split: bestSplit(planning, anchor),
        onRefresh: () {
          Navigator.pop(context);
          ref.read(listaControllerProvider.notifier).refresh();
        },
      ),
    );
    if (market != null) {
      _selectStore(market);
    }
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

    // A ticked line is already in the cart: it must not steer which market wins
    // for what is still to buy. The rows below still render every item — only
    // the comparison narrows.
    final planning = [
      for (final i in items)
        if (!i.checked) i,
    ];

    final stores = mergeStores(listStores(planning), _extra);
    // A market that no longer carries anything listed (its only item was
    // removed, or its re-price failed) would strand every row on "sem preço
    // neste mercado" — so a selection that isn't in the picker any more simply
    // doesn't apply. The stored pick is left alone: it becomes valid again as
    // soon as that market carries something.
    final effectiveCod = stores.any((s) => s.cod == _selCod) ? _selCod : null;
    final ranking = marketRanking(planning);
    final pending = [
      for (final item in items)
        if (!item.checked) item,
    ];
    final completed = [
      for (final item in items)
        if (item.checked) item,
    ];
    final checkedCount = completed.length;

    MarketOption? summaryMarket;
    if (effectiveCod != null) {
      for (final market in ranking) {
        if (market.cod == effectiveCod) summaryMarket = market;
      }
    }
    summaryMarket ??= ranking.isEmpty ? null : ranking.first;

    final lists = ref.watch(listsProvider);
    final activeId = ref.watch(activeListIdProvider);
    var activeName = 'Minha Lista';
    for (final l in lists) {
      if (l.id == activeId) activeName = l.name;
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text('Lista de compras', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              _ListHeader(
                name: activeName,
                onTap: _openListMenu,
                onShare: () => _shareList(activeName, items),
                canShare: items.isNotEmpty,
              ),
              const SizedBox(height: 12),
              _ProgressSummary(checked: checkedCount, total: items.length),
              const SizedBox(height: 14),
              _AddForm(
                controller: _input,
                onSubmit: _input.text.trim().isEmpty ? null : _add,
              ),
              if (location == null) ...[
                const SizedBox(height: 12),
                _Banner(
                  text:
                      'Informe seu CEP acima para comparar os preços dos itens.',
                ),
              ],
              if (location != null && priceError) ...[
                const SizedBox(height: 12),
                _Banner(
                  error: true,
                  text:
                      'Não foi possível consultar os preços agora. Seus itens estão salvos.',
                  actionLabel: 'Atualizar preços',
                  onAction: () =>
                      ref.read(listaControllerProvider.notifier).refresh(),
                ),
              ],
              const SizedBox(height: 18),
              if (items.isEmpty)
                _EmptyListHint(color: sa.muted)
              else ...[
                if (summaryMarket != null) ...[
                  _MarketSummary(
                    market: summaryMarket,
                    itemCount: planning.length,
                    selected: effectiveCod != null,
                    onChange: stores.isEmpty
                        ? null
                        : () => _openStorePicker(stores, effectiveCod),
                    onCompare: ranking.length < 2
                        ? null
                        : () => _openCompare(effectiveCod),
                  ),
                  const SizedBox(height: 18),
                ],
                Text('Para comprar', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                if (pending.isEmpty)
                  _AllItemsDoneHint(color: sa.muted)
                else
                  _ReorderableItemsCard(
                    items: pending,
                    pricing: pricing,
                    cod: effectiveCod,
                    onReorder: (oldIndex, newIndex) => ref
                        .read(listaControllerProvider.notifier)
                        .reorderVisible(
                          [for (final item in pending) item.id],
                          oldIndex,
                          newIndex,
                        ),
                  ),
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _CompletedItemsSection(
                    items: completed,
                    pricing: pricing,
                    cod: effectiveCod,
                    onReorder: (oldIndex, newIndex) => ref
                        .read(listaControllerProvider.notifier)
                        .reorderVisible(
                          [for (final item in completed) item.id],
                          oldIndex,
                          newIndex,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Preços de notas fiscais recentes na sua região (Menor Preço / Nota Paraná).',
                  style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
                ),
              ],
            ],
          ),
        ),
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
    final sa = Theme.of(context).sa;

    return TextField(
      controller: controller,
      // A single-line field (maxLines: 1) discards every newline in its value,
      // typed or pasted — so pasting a multi-line list out of Notes/WhatsApp
      // would silently collapse into one run-on item. Unbounded so those
      // newlines survive into `_add()`, which already splits on them
      // (`parseInput`); submission stays on the button, not Enter, since Enter
      // now means "new line".
      minLines: 1,
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: 'Adicionar item…',
        // No helper line: the examples live in the empty-list hint, which is
        // exactly where someone with nothing on the list is looking.
        fillColor: sa.paper,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 60,
          minHeight: 60,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(6),
          child: FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              foregroundColor: sa.paper,
              // Dimmed amber rather than grey: with nothing typed the button
              // is not yet armed, but it is still the same button.
              disabledBackgroundColor: sa.amber.withValues(alpha: 0.35),
              disabledForegroundColor: sa.paper,
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: SaRadius.smAll,
              ),
            ),
            child: const Icon(Icons.add_rounded, size: 24),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    this.error = false,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final bool error;
  final String? actionLabel;
  final VoidCallback? onAction;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.labelMedium!.copyWith(
              color: error ? sa.danger : sa.ink,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.checked, required this.total});

  final int checked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final complete = total > 0 && checked == total;

    return Row(
      children: [
        Icon(
          complete
              ? Icons.check_circle_rounded
              : Icons.check_circle_outline_rounded,
          color: total == 0 ? sa.muted : sa.green,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          total == 0
              ? 'Adicione itens para começar'
              : '$checked de $total itens concluídos',
          style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
        ),
      ],
    );
  }
}

class _EmptyListHint extends StatelessWidget {
  const _EmptyListHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).sa.paper2,
      borderRadius: SaRadius.mdAll,
      border: Border.all(color: Theme.of(context).sa.stroke, width: 1.5),
    ),
    child: Text(
      'Sua lista está vazia. Escreva do seu jeito — categoria (Carne), marca (Toddy) ou com '
      'quantidade (4x Tomates) — e a Mia procura o melhor preço por perto.',
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
    ),
  );
}

class _AllItemsDoneHint extends StatelessWidget {
  const _AllItemsDoneHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      'Tudo pronto — você já pegou todos os itens.',
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
    ),
  );
}

class _MarketSummary extends StatelessWidget {
  const _MarketSummary({
    required this.market,
    required this.itemCount,
    required this.selected,
    required this.onChange,
    required this.onCompare,
  });

  final MarketOption market;
  final int itemCount;
  final bool selected;
  final VoidCallback? onChange;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final where = [
      market.store ?? 'Loja',
      if ((market.bairro ?? '').isNotEmpty) market.bairro!,
      if (market.km != null) '(${_num(market.km!)} km)',
    ].join(' · ');
    final complete = market.count == itemCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sa.tintGreen,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 20, color: sa.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected
                      ? 'Mercado escolhido'
                      : 'Melhor mercado para sua lista',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(where, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
              children: [
                TextSpan(
                  text:
                      '${market.count} de $itemCount '
                      '${_plural(itemCount, "item", "itens")} · '
                      '${complete ? "total" : "estimativa parcial"} ',
                ),
                TextSpan(
                  text: formatBRL(market.totalCents),
                  style: theme.textTheme.titleSmall!.copyWith(color: sa.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChange,
                  icon: const Icon(Icons.cached_rounded, size: 18),
                  label: const Text('Trocar mercado'),
                  style: OutlinedButton.styleFrom(
                    // Ink, not amber: only one of the two buttons is the
                    // action being suggested, and it is "Comparar".
                    foregroundColor: sa.ink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCompare,
                  icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: const Text('Comparar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedItemsSection extends StatelessWidget {
  const _CompletedItemsSection({
    required this.items,
    required this.pricing,
    required this.cod,
    required this.onReorder,
  });

  final List<ListItem> items;
  final Set<String> pricing;
  final String? cod;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: sa.paper2,
          borderRadius: SaRadius.mdAll,
          border: Border.all(color: sa.stroke, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            leading: Icon(Icons.check_circle_outline_rounded, color: sa.muted),
            title: Text('Já peguei (${items.length})'),
            children: [
              _ReorderableItemsCard(
                items: items,
                pricing: pricing,
                cod: cod,
                onReorder: onReorder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderableItemsCard extends ConsumerWidget {
  const _ReorderableItemsCard({
    required this.items,
    required this.pricing,
    required this.cod,
    required this.onReorder,
  });

  final List<ListItem> items;
  final Set<String> pricing;
  final String? cod;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sa = Theme.of(context).sa;
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      onReorderItem: onReorder,
      proxyDecorator: (child, index, animation) => Material(
        color: sa.paper,
        shape: RoundedRectangleBorder(
          borderRadius: SaRadius.mdAll,
          side: BorderSide(color: sa.amber, width: 2),
        ),
        elevation: 4,
        child: child,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          key: ValueKey(item.id),
          margin: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sa.paper,
            borderRadius: SaRadius.mdAll,
            border: Border.all(color: sa.stroke, width: 1.5),
          ),
          child: _ItemRow(
            item: item,
            loading: pricing.contains(item.id),
            cod: cod,
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: SizedBox(
                width: 26,
                height: 40,
                child: Center(
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 20,
                    color: sa.muted,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One line of the list: check it off, adjust how much of it you want, and see
/// what it costs — either cheapest nearby or at the picked market.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.item,
    required this.loading,
    required this.cod,
    required this.dragHandle,
  });

  final ListItem item;
  final bool loading;
  final String? cod;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final controller = ref.read(listaControllerProvider.notifier);
    final active = activeOption(item);
    final options = item.precos?.options ?? const <ProductOption>[];
    final confirmed = item.chosenKey != null || options.length <= 1;
    final price = _priceView(
      item: item,
      active: active,
      loading: loading,
      cod: cod,
      confirmed: confirmed,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Tooltip(message: 'arrastar para reordenar', child: dragHandle),
            Checkbox(
              value: item.checked,
              onChanged: (_) => controller.toggle(item.id),
              semanticLabel: 'marcar ${item.name}',
              visualDensity: VisualDensity.compact,
            ),
            CatChip(description: item.name, ncm: active?.ncm),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final newName = await _showEditItemDialog(
                          context,
                          item.name,
                        );
                        if (newName != null) {
                          controller.rename(item.id, newName);
                        }
                      },
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: item.checked ? sa.muted : sa.ink,
                          decoration: item.checked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: sa.muted,
                        ),
                      ),
                    ),
                  ),
                  // The shopper's own aside ("o do desconto", "R$ 20") — never
                  // part of the search, so it only ever shows, never edits
                  // anything below it.
                  if (item.note != null)
                    Text(
                      '(${item.note})',
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: sa.muted,
                      ),
                    ),
                  const SizedBox(height: 2),
                  _QtyRow(item: item, controller: controller),
                  // Which product that price is for, and its per-unit price —
                  // right under the amount it multiplies.
                  if (price.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        price.subtitle,
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: sa.muted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Remove on top, the line total under it — the two things that
            // belong to the row as a whole rather than to any one line of it.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => controller.remove(item.id),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: sa.muted,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'remover ${item.name}',
                ),
                if (price.total != null)
                  // Capped so a two-market *range* wraps instead of squeezing
                  // the stepper beside it off the card.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      price.total!,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleSmall!.copyWith(
                        color: sa.green,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (options.length > 1)
          _Collapse(
            key: ValueKey('${item.id}:${item.chosenKey ?? ""}'),
            title: '${options.length} opções',
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
                  child: Text(
                    'variações',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).sa.muted,
                    ),
                  ),
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

  /// Offers the concrete readings the parser could have meant instead, and
  /// applies whichever one is picked. Not `await`ed by the caller — same
  /// fire-and-forget shape as [ListaController.setUnit] above, since the
  /// controller's own state update is what the UI reacts to.
  Future<void> _openCorrection(BuildContext context) async {
    final reading = await showModalBottomSheet<_Reading>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CorrectionSheet(item: item),
    );
    if (reading == null) return;
    controller.resolve(
      item.id,
      qty: reading.qty,
      unit: reading.unit,
      size: reading.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final size = item.size;

    // A Wrap, not a Row: the stepper shares a narrow column with the price, and
    // a line carrying both a size and the "?" marker would otherwise overflow.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              label: 'menos',
              onTap: () => _bump(-_step),
            ),
            SizedBox(
              width: 28,
              child: Text(
                // The number only — the unit is the dropdown right beside it.
                _num(item.qty),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
                semanticsLabel: 'quantidade de ${item.name}: ${_qtyText(item)}',
              ),
            ),
            DropdownButton<String>(
              value: item.unit,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
              onChanged: (u) =>
                  u == null ? null : controller.setUnit(item.id, u),
              items: const [
                DropdownMenuItem(value: 'un', child: Text('un')),
                DropdownMenuItem(value: 'kg', child: Text('kg')),
                DropdownMenuItem(value: 'L', child: Text('L')),
              ],
            ),
            const SizedBox(width: 2),
            _StepButton(
              icon: Icons.add_rounded,
              label: 'mais',
              onTap: () => _bump(_step),
            ),
          ],
        ),
        // The package size the shopper actually asked for — display-only
        // here, and never part of the stepper: it is never multiplied into
        // the price, only shown. Correcting a *misread* split between size
        // and quantity is the "?" marker's job below, not this row's.
        if (size != null) ...[
          const SizedBox(width: 4),
          Text(
            '· ${formatMeasure(size)}',
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          ),
        ],
        // A quiet nudge, not an error: the parser committed to a reading but
        // isn't sure of it, and this is the one place that reading can be
        // overruled without retyping the whole line.
        if (item.parseConf != ParseConf.high) ...[
          const SizedBox(width: 2),
          Semantics(
            button: true,
            label: 'confirmar quantidade de ${item.name}',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _openCorrection(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: sa.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One concrete alternative the correction sheet can offer — the qty/unit/size
/// [ListaController.resolve] is called with if it's picked.
typedef _Reading = ({double qty, String unit, Measure? size});

typedef _ReadingOption = ({String label, _Reading reading});

/// A one-line pt-BR explanation of the ambiguity, plus the readings it can
/// resolve to.
typedef _CorrectionSpec = ({String explanation, List<_ReadingOption> options});

/// Builds the sheet's content from the *shape* of the ambiguity the parser
/// left behind, not from [item.parseConf] alone — `medium`/`low` cover several
/// different shapes, and each one has its own pair of honest alternatives.
///
/// Checked in order of specificity: the "weighed but might be a headcount"
/// shape (`item.unit == 'kg'`) is a special case of "carries a `un` size", so
/// it has to be tried first or it would never be reached.
_CorrectionSpec _correctionSpec(ListItem item) {
  final size = item.size;

  // "12 Pães": priced per kilo, but the number written down reads like a
  // headcount too — and multiplying a per-kilo price by 12 is the direction
  // that must never happen silently.
  if (item.unit == 'kg' && size != null && size.unit == 'un') {
    final n = _num(size.value);
    return (
      explanation:
          'Costuma ser vendido por peso — "$n" pode ser a quantidade de '
          'unidades ou só uma pista do tamanho do pacote.',
      options: [
        (label: '1 kg', reading: (qty: 1, unit: 'kg', size: size)),
        (
          label: '$n unidades',
          reading: (qty: size.value, unit: 'un', size: null),
        ),
      ],
    );
  }

  // "12 Ovos": a bare count that is, just as plausibly, one pack of that
  // count — the carton, not a dozen cartons.
  if (size != null && size.unit == 'un') {
    final n = _num(size.value);
    return (
      explanation: '"$n" pode ser $n unidades avulsas ou 1 pacote com $n.',
      options: [
        (
          label: '$n unidades',
          reading: (qty: size.value, unit: 'un', size: null),
        ),
        (label: '1 pacote de $n', reading: (qty: 1, unit: 'un', size: size)),
      ],
    );
  }

  // "Refrigerante 2l": a package size that might have been meant as the
  // amount to buy instead.
  if (size != null) {
    final label = formatMeasure(size);
    return (
      explanation:
          '"$label" pode ser o tamanho da embalagem ou quanto você quer '
          'comprar.',
      options: [
        (
          label: '${_num(item.qty)} × $label',
          reading: (qty: item.qty, unit: item.unit, size: size),
        ),
        (label: label, reading: (qty: size.value, unit: size.unit, size: null)),
      ],
    );
  }

  // Nothing sharper to offer — the parser had no size to weigh in either
  // direction (a `medium` from a lone weight, or from a money aside).
  return (
    explanation:
        'A quantidade foi uma estimativa — confira se está certa antes de '
        'comprar.',
    options: const [],
  );
}

/// Whether [item]'s current qty/unit/size is the reading [r] describes — the
/// sheet marks that one selected rather than leaving the choice unanchored.
bool _readingMatches(ListItem item, _Reading r) {
  if (item.unit != r.unit) return false;
  if ((item.qty - r.qty).abs() > 0.001) return false;
  final s = item.size;
  if ((s == null) != (r.size == null)) return false;
  if (s != null && r.size != null) {
    if (s.unit != r.size!.unit) return false;
    if ((s.value - r.size!.value).abs() > 0.001) return false;
  }
  return true;
}

/// The "?" marker's sheet: the item's name, why it's asking, and the concrete
/// readings it can resolve to — plus the always-present way out that changes
/// nothing.
class _CorrectionSheet extends StatelessWidget {
  const _CorrectionSheet({required this.item});

  final ListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final spec = _correctionSpec(item);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              spec.explanation,
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
            ),
            const SizedBox(height: 8),
            for (final o in spec.options)
              _ReadingTile(
                label: o.label,
                selected: _readingMatches(item, o.reading),
                onTap: () => Navigator.pop(context, o.reading),
              ),
            _ReadingTile(
              label: 'deixar como está',
              selected: false,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: selected ? Icon(Icons.check_rounded, color: sa.amber) : null,
      onTap: onTap,
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(child: Icon(icon, size: 16, color: sa.ink)),
          ),
        ),
      ),
    );
  }
}

/// The row's money, in whichever of its states is true — never a fabricated
/// zero. [subtitle] is the grey line under the stepper (which product, at what
/// unit price, or why there is no price); [total] is the green line total on the
/// right, null whenever there isn't one. A function rather than a widget because
/// the two halves land in different columns of the row.
({String subtitle, String? total}) _priceView({
  required ListItem item,
  required ProductOption? active,
  required bool loading,
  required String? cod,
  required bool confirmed,
}) {
  ({String subtitle, String? total}) state(String text) =>
      (subtitle: text, total: null);

  if (loading) return state('procurando preços…');
  if (item.precos == null) {
    return state('preço indisponível — toque em "atualizar preços"');
  }
  // An unconfirmed vague term has no price of its own yet: the options below
  // are the question, and a price beside it would answer a different one.
  if (!confirmed && item.precos!.options.isNotEmpty) return state('');

  final name = (active?.name ?? '').isEmpty ? null : active!.name!;
  String subtitleWith(String? detail) => [?name, ?detail].join(' · ');

  if (cod != null) {
    final here = offerAt(item, cod);
    if (here == null) {
      return state(
        (active?.stores.isNotEmpty ?? false)
            ? 'sem preço neste mercado'
            : 'sem preço por perto',
      );
    }
    return (
      subtitle: subtitleWith(
        item.qty == 1
            ? null
            : '${_qtyText(item)} × ${formatBRL(here.priceCents)}',
      ),
      total: formatBRL(lineCents(here.priceCents, item.qty)),
    );
  }

  final pricedStores = [
    for (final s in active?.stores ?? const <Offer>[])
      if (s.priceCents > 0) s,
  ];
  if (pricedStores.isEmpty) return state('sem preço por perto');
  var minLineCents = lineCents(pricedStores.first.priceCents, item.qty);
  var maxLineCents = minLineCents;
  for (final s in pricedStores.skip(1)) {
    final line = lineCents(s.priceCents, item.qty);
    if (line < minLineCents) minLineCents = line;
    if (line > maxLineCents) maxLineCents = line;
  }

  return (
    // One unit price is only quotable when every market agrees on it; a range
    // of totals over a range of unit prices is two numbers, not a breakdown.
    subtitle: subtitleWith(
      item.qty != 1 && minLineCents == maxLineCents
          ? '${_qtyText(item)} × ${formatBRL(pricedStores.first.priceCents)}'
          : null,
    ),
    total: formatRangeBRL(minLineCents, maxLineCents),
  );
}

/// One candidate product behind a vague term ("Carne", "Toddy"), with what it
/// costs and how widely it was found — the two things that tell you whether it
/// is the one you meant.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ProductOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final pricedStores = [
      for (final s in option.stores)
        if (s.priceCents > 0) s,
    ];
    int? minPrice;
    int? maxPrice;
    if (pricedStores.isNotEmpty) {
      minPrice = pricedStores.first.priceCents;
      maxPrice = minPrice;
      for (final s in pricedStores.skip(1)) {
        if (s.priceCents < minPrice!) minPrice = s.priceCents;
        if (s.priceCents > maxPrice!) maxPrice = s.priceCents;
      }
    }

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
                  child: Text(
                    option.name ?? 'produto',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${formatRangeBRL(minPrice, maxPrice)} · ${option.nStores} '
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
                  '$where$km',
                  style: selected
                      ? theme.textTheme.titleSmall!.copyWith(
                          color: sa.amberPress,
                        )
                      : theme.textTheme.bodyMedium,
                ),
                Text(
                  '${market.count} de $itemCount ${_plural(itemCount, "item", "itens")} · '
                  // A total over 6 of 10 items is not a shopping total, and is
                  // labelled as what it is.
                  '${market.count == itemCount ? "total" : "total parcial"}',
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
  const _Collapse({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            title,
            style: theme.textTheme.labelLarge!.copyWith(
              color: theme.sa.amberPress,
            ),
          ),
          children: [
            for (final child in children)
              Align(alignment: Alignment.centerLeft, child: child),
          ],
        ),
      ),
    );
  }
}

/// The market comparison: the best single market for the list, whether adding a
/// second stop pays for itself, and every market ranked. Pops the chosen cod.
class _MarketsSheet extends StatelessWidget {
  const _MarketsSheet({
    required this.markets,
    required this.items,
    required this.anchorCod,
    required this.split,
    required this.onRefresh,
  });

  final List<MarketOption> markets;
  final List<ListItem> items;
  final String anchorCod;
  final SplitOption? split;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final anchor = markets.firstWhere((m) => m.cod == anchorCod);
    final itemCount = items.length;
    final unpriced = items.where((i) => activeOption(i) == null).length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Comparar mercados', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: sa.muted),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Always name the best market, even when the shopper has
                  // another one picked — "qual mercado é o melhor?" is the
                  // question this sheet exists for, and a chosen market must
                  // not quietly stand in for the answer.
                  _SheetLabel('Melhor para a sua lista'),
                  const SizedBox(height: 6),
                  _PickRow(market: markets.first, items: items),
                  if (anchor.cod != markets.first.cod) ...[
                    const SizedBox(height: 12),
                    _SheetLabel('O mercado escolhido'),
                    const SizedBox(height: 6),
                    _PickRow(market: anchor, items: items),
                  ],
                  const SizedBox(height: 14),
                  _SheetLabel('Vale dividir em dois mercados?'),
                  const SizedBox(height: 6),
                  if (split != null)
                    _SplitCard(
                      anchor: anchor,
                      split: split!,
                      itemCount: itemCount,
                    )
                  else
                    Text(
                      'Um mercado só já resolve — nenhum segundo mercado por perto '
                      'compensa a viagem.',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: sa.muted,
                      ),
                    ),
                  const SizedBox(height: 14),
                  _SheetLabel('Todos os mercados'),
                  for (final m in markets)
                    _PickRow(
                      market: m,
                      items: items,
                      selected: m.cod == anchorCod,
                    ),
                  // Prices that never arrived are in no market's basket, so
                  // every total here is short by them. Say so rather than let
                  // the comparison look complete.
                  if (unpriced > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$unpriced ${_plural(unpriced, "item", "itens")} ainda sem preço — '
                            'fora de todas as contas acima.',
                            style: theme.textTheme.labelMedium!.copyWith(
                              color: sa.muted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onRefresh,
                          child: const Text('atualizar'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A market row that picks that market when tapped — the sheet's only action.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.market,
    required this.items,
    this.selected = true,
  });

  final MarketOption market;
  final List<ListItem> items;
  final bool selected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, market.cod),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _MarketRow(
              market: market,
              itemCount: items.length,
              selected: selected,
              onTap: () => Navigator.pop(context, market.cod),
            ),
          ),
        ),
      ),
      // Closed by default: the summary is the answer, the itemisation is the
      // evidence for it — and four open breakdowns would bury the comparison
      // this sheet exists to make.
      // Not "ver os N itens": the breakdown lists the whole list, including the
      // lines this market doesn't sell, so any count in the label would be a
      // promise it breaks.
      _Collapse(
        title: 'ver os itens',
        children: [_BasketBreakdown(lines: basketLinesAt(items, market.cod))],
      ),
    ],
  );
}

/// One market's basket, line by line: the product matched, how much of it, and
/// what that comes to there.
class _BasketBreakdown extends StatelessWidget {
  const _BasketBreakdown({required this.lines});

  final List<BasketLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${line.item.name} · ${_qtyText(line.item)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      // Which product that price is actually for — "Carne" is
                      // not a price, "CARNE MOIDA BOVINA KG" is.
                      if (line.product != null)
                        Text(
                          line.product!,
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: sa.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                line.offer == null
                    ? Text(
                        'não vende aqui',
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: sa.muted,
                        ),
                      )
                    : Text(
                        formatBRL(line.totalCents),
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: sa.green,
                        ),
                      ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge!.copyWith(color: theme.sa.amberPress),
    );
  }
}

/// The second stop, priced against shopping the anchor market alone.
class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.anchor,
    required this.split,
    required this.itemCount,
  });

  final MarketOption anchor;
  final SplitOption split;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final where = [
      split.store ?? 'Loja',
      if ((split.bairro ?? '').isNotEmpty) split.bairro!,
    ].join(' · ');
    final km = split.km == null ? '' : ' (${_num(split.km!)} km)';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sa.paper2,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Indo também ao $where$km', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (split.cheaper.isNotEmpty) ...[
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text:
                        '${split.cheaper.length} ${_plural(split.cheaper.length, "item", "itens")} '
                        'mais ${_plural(split.cheaper.length, "barato", "baratos")} lá · dá pra economizar ',
                  ),
                  TextSpan(
                    text: formatBRL(split.savedCents),
                    style: theme.textTheme.titleSmall!.copyWith(
                      color: sa.green,
                    ),
                  ),
                ],
              ),
            ),
            // Which ones. Advice you can act on beats a count you can't.
            Text(
              split.cheaper.map((i) => '${i.name} (${_qtyText(i)})').join(', '),
              style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
            ),
          ],
          if (split.extra.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '+ ${split.extra.length} ${_plural(split.extra.length, "item", "itens")} que '
              '${anchor.store ?? "o outro mercado"} não tem',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              split.extra.map((i) => '${i.name} (${_qtyText(i)})').join(', '),
              style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            // The one-market total is only quoted alongside when the split
            // covers exactly the same items. With extras it covers more, and
            // two totals over different shopping are not a comparison.
            'Os dois juntos: ${anchor.count + split.extra.length} de $itemCount '
            '${_plural(itemCount, "item", "itens")} · ${formatBRL(split.totalCents)}'
            '${split.extra.isEmpty ? ' (só em ${anchor.store ?? "um mercado"}: ${formatBRL(anchor.totalCents)})' : ''}',
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          ),
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
  const _ListHeader({
    required this.name,
    required this.onTap,
    required this.onShare,
    required this.canShare,
  });

  final String name;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final bool canShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Container(
      decoration: BoxDecoration(
        color: sa.paper,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: sa.paper2, shape: BoxShape.circle),
            child: Icon(Icons.list_alt_rounded, size: 18, color: sa.ink),
          ),
          const SizedBox(width: 8),
          // The name and the caret are one target, and the ⋮ beside it is the
          // other — both open the same menu, which is also where the other
          // lists are, so "trocar de lista" is reachable from either.
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: SaRadius.smAll,
              child: InkWell(
                onTap: onTap,
                borderRadius: SaRadius.smAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more_rounded, size: 20, color: sa.ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            color: sa.ink,
            visualDensity: VisualDensity.compact,
            tooltip: 'opções da lista',
          ),
          Container(width: 1.5, height: 24, color: sa.stroke),
          IconButton(
            onPressed: canShare ? onShare : null,
            icon: const Icon(Icons.share_rounded, size: 19),
            color: sa.ink,
            visualDensity: VisualDensity.compact,
            tooltip: 'compartilhar $name',
          ),
        ],
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
                      leading: Icon(
                        l.id == activeId
                            ? Icons.list_alt_rounded
                            : Icons.description_outlined,
                        color: sa.ink,
                      ),
                      title: Text(l.name, style: theme.textTheme.bodyMedium),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (l.id == activeId)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: sa.green,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            tooltip: 'renomear ${l.name}',
                            color: sa.muted,
                            onPressed: () =>
                                Navigator.pop(context, _Rename(l.id, l.name)),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            tooltip: 'apagar ${l.name}',
                            color: sa.muted,
                            onPressed: () =>
                                Navigator.pop(context, _Delete(l.id, l.name)),
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
              leading: Icon(Icons.add_rounded, size: 20, color: sa.ink),
              title: Text('Nova lista', style: theme.textTheme.bodyMedium),
              onTap: () => Navigator.pop(context, const _Create()),
            ),
          ],
        ),
      ),
    );
  }
}
