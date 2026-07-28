import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categoria.dart';
import '../../core/money.dart';
import '../../core/text.dart';
import '../../data/enrichment.dart';
import '../../data/models/receipt.dart';
import '../../domain/basket.dart';
import '../../domain/savings.dart';
import '../../domain/tendencias.dart';
import '../../theme/tokens.dart';
import '../../widgets/card_list.dart';
import '../../widgets/cat_chip.dart';
import '../../widgets/offer_span.dart';
import '../location/location_controller.dart';
import 'receipt_controller.dart';

/// The nota, in whichever of its three honest states applies: unpriced (no
/// location yet), being priced, or the cheapest-nearby report.
///
/// Pricing runs on open and writes back to disk, so the screen never holds a
/// second copy of the receipt — it re-reads the one that was saved.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.accessKey});

  final String accessKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receiptProvider(accessKey));
    final sa = Theme.of(context).sa;
    // The value, not `.when`: re-reading after a pricing pass must not blank
    // the report back to a spinner.
    final receipt = async.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Nota')),
      body: switch ((receipt, async)) {
        (final Receipt r, _) => _ReceiptBody(receipt: r),
        (_, AsyncError()) => Center(
          child: Text(
            'Não foi possível abrir esta nota.',
            style: TextStyle(color: sa.danger),
          ),
        ),
        (_, AsyncLoading()) => const Center(child: CircularProgressIndicator()),
        _ => const Center(child: Text('Nota não encontrada.')),
      },
    );
  }
}

class _ReceiptBody extends ConsumerStatefulWidget {
  const _ReceiptBody({required this.receipt});

  final Receipt receipt;

  @override
  ConsumerState<_ReceiptBody> createState() => _ReceiptBodyState();
}

class _ReceiptBodyState extends ConsumerState<_ReceiptBody> {
  bool _pricing = false;

  /// Store to price the whole basket at, or null for "Mais barato por perto".
  /// Held in widget state only, same as the reference — it resets on leaving
  /// the screen rather than persisting to disk.
  String? _storeCod;

  /// Whether this session's user dismissed the day tip. Not persisted — a
  /// fresh open of the same nota shows it again.
  bool _tipOff = false;

  Future<void> _openStorePicker(List<StoreOption> options) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _StorePickerSheet(options: options, selectedCod: _storeCod),
    );
    // null means the sheet was dismissed without a choice; '' is the explicit
    // "Mais barato por perto" pick, distinct from "no change".
    if (result != null) {
      setState(() => _storeCod = result.isEmpty ? null : result);
    }
  }

  @override
  void initState() {
    super.initState();
    final location = ref.read(locationControllerProvider);
    if (location != null && needsPricing(widget.receipt, location)) {
      _pricing = true;
      // After the first frame, so the nota is on screen before the network is
      // touched — the item list is already worth reading unpriced.
      WidgetsBinding.instance.addPostFrameCallback((_) => _price());
    }
  }

  Future<void> _price() async {
    if (!_pricing) setState(() => _pricing = true);
    try {
      await ref.read(receiptControllerProvider.notifier).price(widget.receipt);
    } catch (_) {
      // Nothing to re-raise to: the receipt below stays in its unpriced state,
      // which the summary reports honestly, with a retry.
    } finally {
      if (mounted) setState(() => _pricing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final receipt = widget.receipt;
    final items = receipt.items;
    final savings = computeSavings(items);
    final priced = receipt.enrichedAt != null;
    // "Valor a pagar" if the consulta gave one, otherwise the honest fallback:
    // the sum of the lines actually parsed.
    final total = receipt.header.totalCents > 0
        ? receipt.header.totalCents
        : items.fold<int>(0, (s, it) => s + it.lineTotalCents);

    final options = priced && !_pricing
        ? storeOptions(items)
        : const <StoreOption>[];
    StoreOption? selectedStore;
    for (final o in options) {
      if (o.cod == _storeCod) {
        selectedStore = o;
        break;
      }
    }

    final offers = ref.watch(offersProvider).value ?? const [];
    final trends = offers.isEmpty
        ? const <Trend>[]
        : cheapDayByCategory(offers);
    final pwd = purchaseWeekday(receipt);
    final dayTips = <({Categoria cat, Trend t})>[];
    if (priced && !_pricing && !_tipOff && pwd != null && trends.isNotEmpty) {
      final cats = {
        for (final it in items)
          classify(description: it.description, ncm: it.ncm),
      };
      for (final cat in cats) {
        if (cat == Categoria.outros) continue;
        final t = cheapDayFor(trends, cat, receipt.header.storeName);
        if (t != null && t.weekday != pwd) dayTips.add((cat: cat, t: t));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _Summary(
          receipt: receipt,
          total: total,
          savings: savings,
          pricing: _pricing,
          onRetry: _price,
        ),
        const SizedBox(height: 18),
        if (dayTips.isNotEmpty)
          _DayTip(
            tips: dayTips,
            pwd: pwd!,
            onDismiss: () => setState(() => _tipOff = true),
          ),
        if (items.isNotEmpty) _CategoryBreakdown(items: items),
        if (priced && !_pricing && options.isNotEmpty) ...[
          _StorePickerRow(
            selected: selectedStore,
            onTap: () => _openStorePicker(options),
          ),
          const SizedBox(height: 18),
        ],
        if (priced && !_pricing) ...[
          if (selectedStore != null)
            _StoreBasket(items: items, store: selectedStore, total: total)
          else ...[
            Text(
              'Mais barato por perto (${savings.compared.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (savings.compared.isEmpty)
              Text(
                'Nenhum item está mais barato em outra loja próxima.',
                style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
              )
            else
              CardList(
                children: [
                  for (final c in savings.compared) _ComparedRow(compared: c),
                ],
              ),
            const SizedBox(height: 10),
            Text(
              'Preços de notas fiscais recentes na sua região. Itens “aprox.” são '
              'comparados por descrição, não por código de barras.',
              style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
            ),
            if (savings.uncompared.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Não comparados (${savings.uncompared.length})',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              CardList(
                children: [
                  for (final item in savings.uncompared)
                    _PlainRow(item: item, trailing: 'sem preço próximo'),
                ],
              ),
            ],
          ],
        ] else ...[
          Text(
            'Itens da nota (${items.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          CardList(
            children: [
              for (final item in items)
                _PlainRow(item: item, trailing: formatBRL(item.unitPriceCents)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Store, total, and the one line that says what this nota is worth knowing.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.receipt,
    required this.total,
    required this.savings,
    required this.pricing,
    required this.onRetry,
  });

  final Receipt receipt;
  final int total;
  final Savings savings;
  final bool pricing;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final header = receipt.header;
    final storeLabel = [
      header.storeName,
      header.city,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final muted = theme.textTheme.labelMedium!.copyWith(color: sa.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (storeLabel.isNotEmpty) ...[
          Text(
            storeLabel,
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          ),
          const SizedBox(height: 4),
        ],
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Total da nota: '),
              TextSpan(
                text: formatBRL(total),
                style: theme.textTheme.titleMedium,
              ),
              TextSpan(
                text:
                    ' · ${receipt.items.length} ${receipt.items.length == 1 ? 'item' : 'itens'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _verdict(context, theme, muted),
        if ((header.purchasedAt ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(header.purchasedAt!, style: muted),
        ],
      ],
    );
  }

  /// The five states this line can honestly be in. Savings are always framed as
  /// an opportunity — "dá pra economizar" — never as money already banked, and
  /// a pass that found nothing says so instead of showing a hollow "R$ 0,00".
  Widget _verdict(BuildContext context, ThemeData theme, TextStyle muted) {
    final sa = theme.sa;

    if (pricing) {
      return Row(
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: sa.amber),
          ),
          const SizedBox(width: 8),
          Text('Comparando preços por perto…', style: muted),
        ],
      );
    }

    if (receipt.enrichedAt == null) {
      // No location yet is the ordinary first-scan state; a location that is
      // set and still unpriced means the pass failed.
      final consumer = Consumer(
        builder: (context, ref, _) =>
            ref.watch(locationControllerProvider) == null
            ? Text(
                'Informe seu CEP acima para comparar preços na sua região.',
                style: muted,
              )
            : Row(
                children: [
                  Flexible(
                    child: Text(
                      'Não foi possível comparar os preços agora.',
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: sa.danger,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('tentar de novo'),
                  ),
                ],
              ),
      );
      return consumer;
    }

    if (savings.totalSavedCents > 0) {
      return Text.rich(
        TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'Dá pra economizar '),
            TextSpan(
              text:
                  '${formatBRL(savings.totalSavedCents)} (${savedPct(savings.totalSavedCents, total)}%)',
              style: theme.textTheme.titleMedium!.copyWith(color: sa.green),
            ),
            const TextSpan(text: ' comprando por perto'),
          ],
        ),
      );
    }

    return Text(
      savings.uncompared.length == receipt.items.length
          ? 'Não encontramos preços por perto para os itens desta nota.'
          : 'Você já comprou pelo melhor preço por perto.',
      style: muted,
    );
  }
}

/// One item that is cheaper somewhere else: what you paid, where it is cheaper,
/// and the difference.
class _ComparedRow extends StatelessWidget {
  const _ComparedRow({required this.compared});

  final ComparedItem compared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final item = compared.item;
    final approx = item.precos?.confidence != 'high';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: CatChip(description: item.description, ncm: item.ncm),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(text: item.description),
                    if (approx)
                      TextSpan(
                        text: ' aprox.',
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: sa.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'você pagou ${formatBRL(item.unitPriceCents)}',
                style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
              ),
              OfferSpan(offer: compared.cheapest),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '−${formatBRL(compared.lineSavedCents)}',
          style: theme.textTheme.titleMedium!.copyWith(color: sa.green),
        ),
      ],
    );
  }
}

/// An item with no comparison to make: the unpriced list and the uncompared
/// section are the same row with different trailing text.
class _PlainRow extends StatelessWidget {
  const _PlainRow({required this.item, required this.trailing});

  final ReceiptItem item;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Row(
      children: [
        CatChip(description: item.description, ncm: item.ncm),
        const SizedBox(width: 8),
        Expanded(
          child: Text(item.description, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Text(
          trailing,
          style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
        ),
      ],
    );
  }
}

/// "You bought produce on a day it's usually dearer" — one line per flagged
/// category, dismissible for the rest of this screen visit.
class _DayTip extends StatelessWidget {
  const _DayTip({
    required this.tips,
    required this.pwd,
    required this.onDismiss,
  });

  final List<({Categoria cat, Trend t})> tips;
  final int pwd;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 40, 12),
      decoration: BoxDecoration(
        color: sa.tintAmber,
        borderRadius: SaRadius.mdAll,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 19,
                    color: sa.ink,
                  ),
                  const SizedBox(width: 6),
                  Text('Dica de dia', style: theme.textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 6),
              for (final tip in tips)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Você comprou ${tip.cat.label.toLowerCase()} ${numDiaSemana(pwd)}. '
                    '${tip.t.store != null ? "No ${tip.t.store}" : "Por perto"} '
                    'costuma sair mais barato ${emDiaSemana(tip.t.weekday)}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
          Positioned(
            top: -8,
            right: -12,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onDismiss,
              tooltip: 'Dispensar dica',
              color: sa.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible transparency panel — shows exactly how each item was
/// categorised. `outros` is the honesty valve: misfits show up here instead
/// of being mis-filed into a real category.
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.items});

  final List<ReceiptItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    final groups = <Categoria, List<ReceiptItem>>{};
    for (final it in items) {
      groups
          .putIfAbsent(
            classify(description: it.description, ncm: it.ncm),
            () => [],
          )
          .add(it);
    }
    final present = [
      for (final c in Categoria.values)
        if (groups[c] != null) c,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      // A Material, not just a coloured Container: ExpansionTile's ListTile
      // paints its ink splash on the nearest Material ancestor, and a plain
      // background colour in between would swallow it silently.
      child: Material(
        color: sa.paper,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              'Categorias da nota (${present.length})',
              style: theme.textTheme.titleSmall,
            ),
            children: [
              for (final cat in present)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cat.label} (${groups[cat]!.length})',
                        style: theme.textTheme.labelLarge,
                      ),
                      for (final it in groups[cat]!)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 4),
                          child: Text(
                            it.description,
                            style: theme.textTheme.labelMedium!.copyWith(
                              color: sa.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tap target that opens the store picker sheet, showing the current
/// choice.
class _StorePickerRow extends StatelessWidget {
  const _StorePickerRow({required this.selected, required this.onTap});

  final StoreOption? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final label = selected == null
        ? 'Mais barato por perto'
        : (selected!.name ?? 'Loja');

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
              Text(
                'Comparar com: ',
                style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
              ),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.expand_more_rounded, color: sa.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing every nearby store this receipt's items were priced
/// at, each with a savings preview, plus "Mais barato por perto" to go back
/// to the cheapest-nearby report. A search field only appears once there are
/// enough stores to make one worth having.
class _StorePickerSheet extends StatefulWidget {
  const _StorePickerSheet({required this.options, required this.selectedCod});

  final List<StoreOption> options;
  final String? selectedCod;

  @override
  State<_StorePickerSheet> createState() => _StorePickerSheetState();
}

class _StorePickerSheetState extends State<_StorePickerSheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = norm(_query);
    // The selected store stays visible even if it no longer matches the
    // filter, so picking it back isn't a "clear filter first" chore.
    final visible = q.isEmpty
        ? widget.options
        : [
            for (final o in widget.options)
              if (norm('${o.name ?? ''} ${o.bairro ?? ''}').contains(q) ||
                  o.cod == widget.selectedCod)
                o,
          ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comparar com', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (widget.options.length > 6)
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Filtrar lojas por nome…',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _StorePickerOption(
                    title: 'Mais barato por perto',
                    subtitle: null,
                    selected: widget.selectedCod == null,
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  for (final o in visible)
                    _StorePickerOption(
                      title: [
                        o.name ?? 'Loja',
                        if ((o.bairro ?? '').isNotEmpty) o.bairro!,
                      ].join(' · '),
                      subtitle: _savingsLabel(o),
                      selected: o.cod == widget.selectedCod,
                      onTap: () => Navigator.pop(context, o.cod),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _savingsLabel(StoreOption o) {
    final count = '${o.itemsCovered} ${o.itemsCovered == 1 ? "item" : "itens"}';
    if (o.savedCents > 0) {
      return 'economiza ${formatBRL(o.savedCents)} ($count)';
    }
    if (o.savedCents < 0) return '${formatBRL(-o.savedCents)} a mais ($count)';
    return 'mesmo preço ($count)';
  }
}

class _StorePickerOption extends StatelessWidget {
  const _StorePickerOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return ListTile(
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
            ),
      trailing: selected ? Icon(Icons.check_rounded, color: sa.amber) : null,
      onTap: onTap,
    );
  }
}

/// The whole receipt priced at one store: total there, coverage, and
/// per-item deltas — green when cheaper here, red when dearer.
class _StoreBasket extends StatelessWidget {
  const _StoreBasket({
    required this.items,
    required this.store,
    required this.total,
  });

  final List<ReceiptItem> items;
  final StoreOption store;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final basket = basketForStore(items, store.cod);
    final covered = [
      for (final l in basket.lines)
        if (l.offer != null) l,
    ];
    final missing = [
      for (final l in basket.lines)
        if (l.offer == null) l,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Comprando tudo na '),
              TextSpan(
                text: store.name ?? 'loja',
                style: theme.textTheme.titleSmall,
              ),
              if ((store.bairro ?? '').isNotEmpty)
                TextSpan(text: ' · ${store.bairro}'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
            children: [
              TextSpan(
                text:
                    '${basket.coveredCount} de ${basket.itemCount} itens · total dos comparados ',
              ),
              TextSpan(
                text: formatBRL(basket.storeTotalCents),
                style: theme.textTheme.labelMedium!.copyWith(color: sa.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (basket.totalSavedCents >= 0)
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Você economizaria '),
                TextSpan(
                  text:
                      '${formatBRL(basket.totalSavedCents)} (${savedPct(basket.totalSavedCents, total)}%)',
                  style: theme.textTheme.titleMedium!.copyWith(color: sa.green),
                ),
                const TextSpan(text: ' nos itens comparados'),
              ],
            ),
          )
        else
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Você pagaria '),
                TextSpan(
                  text: formatBRL(-basket.totalSavedCents),
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: sa.danger,
                  ),
                ),
                const TextSpan(text: ' a mais nos itens comparados'),
              ],
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Nesta loja (${covered.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (covered.isEmpty)
          Text(
            'Nenhum item desta nota tem preço recente aqui.',
            style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
          )
        else
          CardList(children: [for (final l in covered) _BasketRow(line: l)]),
        const SizedBox(height: 10),
        Text(
          'Preços de notas fiscais recentes nesta loja. Itens sem preço recente aparecem abaixo.',
          style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Não vendidos nesta loja (${missing.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          CardList(
            children: [
              for (final l in missing)
                _PlainRow(item: l.item, trailing: 'sem preço recente aqui'),
            ],
          ),
        ],
      ],
    );
  }
}

/// One item at the chosen store: what you paid, what it costs there, and the
/// delta — green when cheaper here, red when dearer.
class _BasketRow extends StatelessWidget {
  const _BasketRow({required this.line});

  final BasketLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final item = line.item;
    final over = line.lineDeltaCents < 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: CatChip(description: item.description, ncm: item.ncm),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                'você pagou ${formatBRL(item.unitPriceCents)}',
                style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
              ),
              OfferSpan(offer: line.offer!),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          over
              ? '+${formatBRL(-line.lineDeltaCents)}'
              : '−${formatBRL(line.lineDeltaCents)}',
          style: theme.textTheme.titleMedium!.copyWith(
            color: over ? sa.danger : sa.green,
          ),
        ),
      ],
    );
  }
}
