import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../data/models/receipt.dart';
import '../../domain/savings.dart';
import '../../theme/tokens.dart';
import 'history_controller.dart';

/// Every scanned nota, newest first: tap one to reopen it (which re-prices
/// itself if the CEP has moved on — that is [ReceiptScreen]'s own job, not
/// this screen's), or clear the lot.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final sa = Theme.of(context).sa;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar todo o histórico?'),
        content: const Text(
          'As notas salvas serão removidas. Escaneie os cupons novamente para recalcular os preços.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Apagar', style: TextStyle(color: sa.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(historyControllerProvider.notifier).clearAll();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historyProvider);
    final receipts = async.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Notas'),
        actions: [
          if (receipts != null && receipts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Limpar histórico',
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: switch ((receipts, async)) {
        (final List<Receipt> r, _) when r.isEmpty => const _EmptyHistory(),
        (final List<Receipt> r, _) => _HistoryList(receipts: r),
        (_, AsyncError()) => Center(
            child: Text(
              'Não foi possível abrir o histórico.',
              style: TextStyle(color: Theme.of(context).sa.danger),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// No notes yet — the honesty rule's empty state, never a hollow list.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧾', style: theme.textTheme.displaySmall),
            const SizedBox(height: 14),
            Text('Nenhuma nota ainda', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'Escaneie o QR do cupom fiscal para ver onde cada item sai mais barato.',
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.push('/scan?mode=nota'),
              child: const Text('Escanear nota'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.receipts});

  final List<Receipt> receipts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: receipts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _HistoryTile(receipt: receipts[i]),
    );
  }
}

/// One saved nota: store, date, total, and its pricing state — never a "R$
/// 0,00" placeholder, always one of the honest states below.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.receipt});

  final Receipt receipt;

  String get _date {
    final purchasedAt = receipt.header.purchasedAt;
    if (purchasedAt != null && purchasedAt.isNotEmpty) return purchasedAt.split(' ').first;
    final createdAt = receipt.createdAt;
    if (createdAt == null) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(createdAt);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final header = receipt.header;
    final storeLabel = [
      header.storeName,
      header.city,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final total = header.totalCents > 0
        ? header.totalCents
        : receipt.items.fold<int>(0, (s, it) => s + it.lineTotalCents);

    return Material(
      color: sa.paper,
      borderRadius: SaRadius.mdAll,
      child: InkWell(
        borderRadius: SaRadius.mdAll,
        onTap: () => context.push('/notas/${receipt.accessKey}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: SaRadius.mdAll,
            border: Border.all(color: sa.stroke, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      storeLabel.isEmpty ? 'Nota fiscal' : storeLabel,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatBRL(total), style: theme.textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (_date.isNotEmpty) _date,
                        '${receipt.items.length} ${receipt.items.length == 1 ? "item" : "itens"}',
                      ].join(' · '),
                      style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StateBadge(receipt: receipt),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three honest pricing states a saved nota can be in.
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    if (receipt.enrichedAt == null) {
      return Text('aguardando comparação', style: theme.textTheme.labelMedium!.copyWith(color: sa.muted));
    }

    final savings = computeSavings(receipt.items);
    if (savings.totalSavedCents > 0) {
      return Text(
        'dá pra economizar ${formatBRL(savings.totalSavedCents)}',
        style: theme.textTheme.labelMedium!.copyWith(color: sa.green),
      );
    }
    if (savings.uncompared.length == receipt.items.length) {
      return Text('sem preços por perto', style: theme.textTheme.labelMedium!.copyWith(color: sa.muted));
    }
    return Text('melhor preço por perto', style: theme.textTheme.labelMedium!.copyWith(color: sa.muted));
  }
}
