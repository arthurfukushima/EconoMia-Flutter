import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/enrichment.dart';
import '../../data/models/receipt.dart';
import '../../domain/savings.dart';
import '../../theme/tokens.dart';
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
            child: Text('Não foi possível abrir esta nota.', style: TextStyle(color: sa.danger)),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _Summary(receipt: receipt, total: total, savings: savings, pricing: _pricing, onRetry: _price),
        const SizedBox(height: 18),
        if (priced && !_pricing) ...[
          Text('Mais barato por perto (${savings.compared.length})', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (savings.compared.isEmpty)
            Text(
              'Nenhum item está mais barato em outra loja próxima.',
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
            )
          else
            _Card(children: [for (final c in savings.compared) _ComparedRow(compared: c)]),
          const SizedBox(height: 10),
          Text(
            'Preços de notas fiscais recentes na sua região. Itens “aprox.” são '
            'comparados por descrição, não por código de barras.',
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          ),
          if (savings.uncompared.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Não comparados (${savings.uncompared.length})', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _Card(
              children: [
                for (final item in savings.uncompared)
                  _PlainRow(item: item, trailing: 'sem preço próximo'),
              ],
            ),
          ],
        ] else ...[
          Text('Itens da nota (${items.length})', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _Card(
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
          Text(storeLabel, style: theme.textTheme.labelMedium!.copyWith(color: sa.muted)),
          const SizedBox(height: 4),
        ],
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Total da nota: '),
              TextSpan(text: formatBRL(total), style: theme.textTheme.titleMedium),
              TextSpan(text: ' · ${receipt.items.length} ${receipt.items.length == 1 ? 'item' : 'itens'}'),
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
        builder: (context, ref, _) => ref.watch(locationControllerProvider) == null
            ? Text('Informe seu CEP acima para comparar preços na sua região.', style: muted)
            : Row(
                children: [
                  Flexible(
                    child: Text(
                      'Não foi possível comparar os preços agora.',
                      style: theme.textTheme.labelMedium!.copyWith(color: sa.danger),
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('tentar de novo')),
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
              text: '${formatBRL(savings.totalSavedCents)} (${savedPct(savings.totalSavedCents, total)}%)',
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

/// The bordered list every section on this screen is drawn in.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;
    return Container(
      decoration: BoxDecoration(
        color: sa.paper,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: sa.stroke),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: children[i],
            ),
          ],
        ],
      ),
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
        Padding(padding: const EdgeInsets.only(top: 1), child: CatChip(item: item)),
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
                        style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
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
        CatChip(item: item),
        const SizedBox(width: 8),
        Expanded(child: Text(item.description, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Text(trailing, style: theme.textTheme.labelMedium!.copyWith(color: sa.muted)),
      ],
    );
  }
}
