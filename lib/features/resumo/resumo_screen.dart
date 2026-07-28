import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../domain/insights.dart';
import '../../theme/fonts.dart';
import '../../theme/tokens.dart';
import '../../widgets/card_list.dart';
import '../home/home_controller.dart' show homeInsightsProvider;

/// "Resumo" — cross-note spending insights, in Mia's voice. Every figure comes
/// straight from [aggregate] (the same one Home's hero reads), so nothing
/// shown here is a claim the domain layer can't back.
class ResumoScreen extends ConsumerWidget {
  const ResumoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeInsightsProvider);
    final sa = Theme.of(context).sa;

    return switch (async) {
      AsyncData(:final value) when value.notesCount < 3 =>
        const _NeedsMoreNotes(),
      AsyncData(:final value) => _ResumoBody(insights: value),
      AsyncError() => Center(
        child: Text(
          'Não foi possível montar o resumo.',
          style: TextStyle(color: sa.danger),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Cross-note patterns need a few notes before they mean anything — the
/// honesty rule's gate, never a hollow chart off one or two receipts.
class _NeedsMoreNotes extends StatelessWidget {
  const _NeedsMoreNotes();

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
            Icon(Icons.pets_rounded, size: 46, color: sa.ink),
            const SizedBox(height: 14),
            Text(
              'Escaneie mais algumas notas',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Com 3 ou mais compras eu começo a mostrar onde vai seu dinheiro e onde dá pra economizar.',
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

class _ResumoBody extends StatelessWidget {
  const _ResumoBody({required this.insights});

  final Insights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final byCategory = insights.byCategory;
    final topItems = insights.topItems;
    final byStore = insights.byStore;
    final fav = byStore.isEmpty ? null : byStore.first;
    final bestAlt = insights.bestAlt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SavingsHero(insights: insights),
          const SizedBox(height: 22),
          Text(
            'ONDE VAI SEU DINHEIRO',
            style: SaText.sectionLabel.copyWith(color: sa.muted),
          ),
          const SizedBox(height: 10),
          if (byCategory.isNotEmpty) ...[
            Text(
              '${byCategory.first.cat.label} levam ${byCategory.first.pct}% da sua compra.',
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
            ),
            const SizedBox(height: 10),
            CardList(
              children: [
                for (final c in byCategory)
                  _CategoryRow(spend: c, maxCents: byCategory.first.spentCents),
              ],
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'CAMPEÕES DA DESPENSA',
            style: SaText.sectionLabel.copyWith(color: sa.muted),
          ),
          const SizedBox(height: 10),
          CardList(
            children: [for (final it in topItems.take(5)) _ItemRow(item: it)],
          ),
          if (fav != null) ...[
            const SizedBox(height: 22),
            Text(
              'SEU MERCADO',
              style: SaText.sectionLabel.copyWith(color: sa.muted),
            ),
            const SizedBox(height: 10),
            Text(
              '${fav.visits}× no ${fav.name} · ${formatBRL(fav.spentCents)} no total.',
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
            ),
            if (bestAlt != null && bestAlt.name != fav.name) ...[
              const SizedBox(height: 10),
              _DicaCard(
                text:
                    'Somando suas notas, você teria economizado '
                    '${formatBRL(bestAlt.savedCents)} levando os mesmos itens no ${bestAlt.name}.',
              ),
            ],
          ],
          const SizedBox(height: 18),
          Text(
            'Baseado em ${insights.notesCount} nota(s), ${insights.pricedNotesCount} com preços comparados. '
            'Os números mudam a cada nota escaneada.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: sa.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Same forest hero surface as Home's, but Resumo's own headline figure —
/// [SaText.theme]'s `displaySmall` is reserved for exactly this number.
class _SavingsHero extends StatelessWidget {
  const _SavingsHero({required this.insights});

  final Insights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sa.forest,
        borderRadius: SaRadius.xlAll,
        boxShadow: sa.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DÁ PRA ECONOMIZAR',
            style: SaText.heroLabel.copyWith(color: sa.amber),
          ),
          const SizedBox(height: 4),
          Text(
            formatBRL(insights.totalSavedCents),
            style: theme.textTheme.displaySmall!.copyWith(color: sa.paper),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodySmall!.copyWith(
                color: sa.paper.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
              children: [
                const TextSpan(
                  text: 'Preços melhores que a Mia achou nas suas notas.',
                ),
                if (insights.projectedAnnualCents > 0) ...[
                  const TextSpan(text: ' No seu ritmo, dá '),
                  TextSpan(
                    text: formatBRL(insights.projectedAnnualCents),
                    style: TextStyle(
                      color: sa.mint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' por ano.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One category's spend bar: emoji + label, a fill proportional to the
/// biggest category so the longest bar reads as 100%, then the amount and its
/// share of the total.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.spend, required this.maxCents});

  final CategorySpend spend;

  /// The biggest category's spend — the longest bar reads as 100%, matching
  /// the reference dashboard's bars. [byCategory] is sorted by spend, so this
  /// is always its first element.
  final int maxCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            spend.cat.label,
            style: theme.textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 14,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: sa.paper2,
              borderRadius: SaRadius.pill,
              border: Border.all(color: sa.stroke, width: 1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: maxCents > 0
                  ? (spend.spentCents / maxCents).clamp(0.03, 1.0)
                  : 0.03,
              child: Container(color: sa.green),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            style: theme.textTheme.labelMedium,
            children: [
              TextSpan(text: formatBRL(spend.spentCents)),
              TextSpan(
                text: ' · ${spend.pct}%',
                style: TextStyle(color: sa.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One "campeão da despensa": how many times it was bought and what it cost
/// in total, plus the cheapest nearby offer ever seen for it.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ItemSummary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final cheapest = item.cheapest;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${formatBRL(item.spentCents)} no total'
                '${cheapest != null && cheapest.store != null ? " · mais barato no ${cheapest.store} (${formatBRL(cheapest.priceCents)})" : ""}',
                style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: sa.tintAmber,
            borderRadius: SaRadius.pill,
          ),
          child: Text(
            '${item.count}×',
            style: theme.textTheme.labelMedium!.copyWith(color: sa.amberPress),
          ),
        ),
      ],
    );
  }
}

/// The best-alternative-store nudge — same amber tint as the receipt's own
/// weekday day-tip, this app's one established "Dica da Mia" tip style.
class _DicaCard extends StatelessWidget {
  const _DicaCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sa.tintAmber,
        borderRadius: SaRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pets_rounded, size: 24, color: sa.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dica da Mia', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
