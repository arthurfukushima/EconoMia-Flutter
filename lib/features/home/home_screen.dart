import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../domain/insights.dart';
import '../../domain/tendencias.dart';
import '../../theme/fonts.dart';
import '../../theme/tokens.dart';
import '../lista/lista_controller.dart';
import 'home_controller.dart';

String _greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Bom dia' : h < 18 ? 'Boa tarde' : 'Boa noite';
}

const _zeroInsights = (
  totalSavedCents: 0,
  projectedAnnualCents: 0,
  totalSpentCents: 0,
  notesCount: 0,
  pricedNotesCount: 0,
  byCategory: <CategorySpend>[],
  topItems: <ItemSummary>[],
  byStore: <StoreVisit>[],
  bestAlt: null,
);

/// "A casa da Mia" — the hub: greeting, savings hero, Atalhos shortcut grid
/// and Dica da Mia's weekday trend tip.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Insights insights = ref.watch(homeInsightsProvider).value ?? _zeroInsights;
    final trends = ref.watch(homeTrendsProvider).value ?? const <Trend>[];
    final todayWd = DateTime.now().weekday % 7;
    final todayTrends = [for (final t in trends) if (t.weekday == todayWd) t];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_greeting()} 👋', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _SavingsHero(insights: insights),
          const SizedBox(height: 22),
          Text('ATALHOS', style: SaText.sectionLabel.copyWith(color: Theme.of(context).sa.muted)),
          const SizedBox(height: 10),
          _AtalhosGrid(
            insights: insights,
            todayCount: todayTrends.length,
            // Unchecked, not total: the tile answers "what's still to buy?".
            listCount: ref.watch(listaControllerProvider).where((it) => !it.checked).length,
          ),
          const SizedBox(height: 22),
          Text('DICA DA MIA', style: SaText.sectionLabel.copyWith(color: Theme.of(context).sa.muted)),
          const SizedBox(height: 10),
          _DicaDaMia(top: todayTrends.isEmpty ? null : todayTrends.first),
        ],
      ),
    );
  }
}

/// Forest-green card, Mia avatar, and — per the honesty rule — one of two
/// truthful states: a real opportunity figure, or an onboarding nudge. Never
/// a hollow "R$ 0,00".
class _SavingsHero extends StatelessWidget {
  const _SavingsHero({required this.insights});

  final Insights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final saved = insights.totalSavedCents;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: sa.forest, borderRadius: SaRadius.xlAll, boxShadow: sa.lift),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: sa.forestDeep,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: sa.paper.withValues(alpha: 0.14), width: 1.5),
            ),
            child: Image.asset('assets/img/mia_logo_android.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: saved > 0
                ? _SavingsCopy(saved: saved, projected: insights.projectedAnnualCents)
                : const _OnboardingCopy(),
          ),
        ],
      ),
    );
  }
}

/// "dá pra economizar" — framed as opportunity (paid − cheapest nearby), never
/// as money Mia has already banked.
class _SavingsCopy extends StatelessWidget {
  const _SavingsCopy({required this.saved, required this.projected});

  final int saved;
  final int projected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🐱 MIA · DÁ PRA ECONOMIZAR', style: SaText.heroLabel.copyWith(color: sa.amber)),
        const SizedBox(height: 3),
        Text(
          'Comprando no lugar mais barato, você guarda',
          style: theme.textTheme.bodyMedium!
              .copyWith(color: sa.paper.withValues(alpha: 0.80), fontWeight: FontWeight.w700),
        ),
        Text(formatBRL(saved), style: theme.textTheme.headlineMedium!.copyWith(color: sa.paper)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall!
                .copyWith(color: sa.paper.withValues(alpha: 0.66), fontWeight: FontWeight.w600),
            children: [
              const TextSpan(text: 'São os preços melhores que achei nas suas notas.'),
              if (projected > 0) ...[
                const TextSpan(text: ' No seu ritmo, dá '),
                TextSpan(
                  text: formatBRL(projected),
                  style: TextStyle(color: sa.mint, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' por ano.'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// No notes yet — the onboarding nudge, never a fabricated figure.
class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🐱 MIA', style: SaText.heroLabel.copyWith(color: sa.amber)),
        const SizedBox(height: 6),
        Text(
          'Escaneie sua primeira nota e eu começo a caçar economia pra você.',
          style: theme.textTheme.bodyLarge!.copyWith(color: sa.paper, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// 2×2 shortcut grid, each tile's meta line wired to real local data where one
/// exists yet — Mercado has no live count to show, so its meta line is fixed
/// rather than a fabricated zero. "Loja da Mia" is a disabled 5th row, ahead of
/// its own phase.
class _AtalhosGrid extends StatelessWidget {
  const _AtalhosGrid({
    required this.insights,
    required this.todayCount,
    required this.listCount,
  });

  final Insights insights;
  final int todayCount;
  final int listCount;

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Tile(
                emoji: '🛒',
                tint: sa.tintGreen,
                label: 'Lista de Compras',
                meta: listCount > 0
                    ? '${_plural(listCount, "item", "itens")} pra comprar'
                    : 'Monte sua lista',
                onTap: () => context.push('/lista'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                emoji: '🏪',
                tint: sa.paper2,
                label: 'No mercado',
                meta: 'Compare preços perto',
                onTap: () => context.push('/mercado'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Tile(
                emoji: '🔥',
                tint: sa.tintAmber,
                label: 'Ofertas do dia',
                meta: todayCount > 0 ? '${_plural(todayCount, "oferta", "ofertas")} hoje' : 'Melhores dias por categoria',
                onTap: () => context.push('/ofertas'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                emoji: '🧾',
                tint: sa.paper2,
                label: 'Minhas Notas',
                meta: insights.notesCount > 0
                    ? '${_plural(insights.notesCount, "nota", "notas")} · ${formatBRL(insights.totalSpentCents)}'
                    : 'Seu histórico aqui',
                onTap: () => context.push('/notas'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Tile(
                emoji: '🗂️',
                tint: sa.tintGreen,
                label: 'Catálogo',
                meta: 'Produtos por mercado',
                onTap: () => context.push('/catalogo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                emoji: '🛍️',
                tint: sa.paper2,
                label: 'Loja da Mia',
                meta: 'Em breve · pontos',
                onTap: null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.emoji,
    required this.tint,
    required this.label,
    required this.meta,
    required this.onTap,
  });

  final String emoji;
  final Color tint;
  final String label;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final disabled = onTap == null;

    return Material(
      color: sa.paper,
      borderRadius: SaRadius.mdAll,
      child: InkWell(
        borderRadius: SaRadius.mdAll,
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: SaRadius.mdAll,
              border: Border.all(color: sa.stroke, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: tint, borderRadius: SaRadius.smAll),
                  child: Text(emoji, style: const TextStyle(fontSize: 19)),
                ),
                const SizedBox(height: 10),
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(meta, style: theme.textTheme.labelMedium!.copyWith(color: sa.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One data-driven tip for today: the cheapest category-day trend that lands
/// on today's weekday, or — per the honesty rule — a learning nudge instead
/// of a fabricated promo.
class _DicaDaMia extends StatelessWidget {
  const _DicaDaMia({required this.top});

  final Trend? top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final top = this.top;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: sa.paper, borderRadius: SaRadius.mdAll, border: Border.all(color: sa.stroke, width: 1.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🐱', style: theme.textTheme.titleLarge),
          const SizedBox(width: 10),
          Expanded(
            child: top == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ainda aprendendo os preços daqui', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Escaneie algumas notas e eu descubro os melhores dias de cada categoria na sua região.',
                        style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hoje é dia de ${top.category.label.toLowerCase()}', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${top.category.emoji} ${top.category.label} costuma sair mais barato hoje'
                        '${top.store != null ? " no ${top.store}" : " por perto"}.',
                        style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
                      ),
                    ],
                  ),
          ),
          if (top != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: sa.tintGreen, borderRadius: SaRadius.pill),
              child: Text(
                '−${top.deltaPct}%',
                style: theme.textTheme.labelMedium!.copyWith(color: sa.green),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
