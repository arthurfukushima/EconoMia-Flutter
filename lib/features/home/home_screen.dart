import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../domain/insights.dart';
import '../../domain/tendencias.dart';
import '../../theme/fonts.dart';
import '../../theme/tokens.dart';
import '../../widgets/staggered_entrance.dart';
import '../gamification/gamification_controller.dart';
import '../gamification/mission_widgets.dart';
import '../lista/lista_controller.dart';
import '../profile/profile_controller.dart';
import 'home_controller.dart';

String _greeting() {
  final h = DateTime.now().hour;
  return h < 12
      ? 'Bom dia'
      : h < 18
      ? 'Boa tarde'
      : 'Boa noite';
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
    ref.watch(gamificationProvider);
    final profile = ref.watch(profileControllerProvider);
    final gamification = ref.read(gamificationProvider.notifier);
    final Insights insights =
        ref.watch(homeInsightsProvider).value ?? _zeroInsights;
    final trends = ref.watch(homeTrendsProvider).value ?? const <Trend>[];
    final todayWd = DateTime.now().weekday % 7;
    final todayTrends = [
      for (final t in trends)
        if (t.weekday == todayWd) t,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greeting(), style: Theme.of(context).textTheme.titleMedium),
          StaggeredEntrance(
            index: 1,
            child: Semantics(
              label: '${gamification.points} pontos Mia',
              child: Align(
                alignment: Alignment.centerRight,
                child: _PointsPill(points: gamification.points),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (profile == null) ...[
            StaggeredEntrance(
              index: 2,
              child: _LoginBanner(onTap: () => context.push('/perfil/login')),
            ),
            const SizedBox(height: 12),
          ],
          StaggeredEntrance(index: 3, child: _SavingsHero(insights: insights)),
          const SizedBox(height: 22),
          Text(
            'ATALHOS',
            style: SaText.sectionLabel.copyWith(
              color: Theme.of(context).sa.muted,
            ),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 4,
            child: _AtalhosGrid(
              insights: insights,
              todayCount: todayTrends.length,
              // Unchecked, not total: the tile answers "what's still to buy?".
              listCount: ref
                  .watch(listaControllerProvider)
                  .where((it) => !it.checked)
                  .length,
            ),
          ),
          const SizedBox(height: 22),
          StaggeredEntrance(
            index: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSOES EM DESTAQUE',
                  style: SaText.sectionLabel.copyWith(
                    color: Theme.of(context).sa.muted,
                  ),
                ),
                const SizedBox(height: 10),
                MissionCarousel(
                  view: gamification.view(),
                  onClaim: gamification.claim,
                ),
                const SizedBox(height: 10),
                MissionsEntryCard(
                  view: gamification.view(),
                  onTap: () => context.push('/missoes'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'DICA DA MIA',
            style: SaText.sectionLabel.copyWith(
              color: Theme.of(context).sa.muted,
            ),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 7,
            child: _DicaDaMia(
              top: todayTrends.isEmpty ? null : todayTrends.first,
            ),
          ),
          const SizedBox(height: 32),
          _DebugResetButton(onReset: gamification.reset),
        ],
      ),
    );
  }
}

class _LoginBanner extends StatelessWidget {
  const _LoginBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Material(
      color: sa.paper,
      borderRadius: SaRadius.mdAll,
      child: InkWell(
        borderRadius: SaRadius.mdAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: SaRadius.mdAll,
            border: Border.all(color: sa.stroke, width: 1.5),
            boxShadow: sa.liftSm,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sa.tintAmber,
                  borderRadius: SaRadius.smAll,
                ),
                child: Icon(Icons.person_rounded, color: sa.ink, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Criar perfil', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Opcional: diga seu nome e continue usando a Mia do seu jeito.',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: sa.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: sa.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Counts up (with a small overshoot bounce) whenever [points] increases —
/// the payoff half of the claim flourish in [_QuestRow].
class _PointsPill extends StatefulWidget {
  const _PointsPill({required this.points});
  final int points;
  @override
  State<_PointsPill> createState() => _PointsPillState();
}

class _PointsPillState extends State<_PointsPill>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    duration: SaMotion.slow,
    vsync: this,
  );
  late final _count = CurvedAnimation(
    parent: _controller,
    curve: SaMotion.easeOut,
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      weight: 40,
      tween: Tween(
        begin: 1.0,
        end: 1.3,
      ).chain(CurveTween(curve: SaMotion.easeBack)),
    ),
    TweenSequenceItem(
      weight: 60,
      tween: Tween(
        begin: 1.3,
        end: 1.0,
      ).chain(CurveTween(curve: SaMotion.easeOut)),
    ),
  ]).animate(_controller);
  late int _from = widget.points;
  late int _to = widget.points;

  @override
  void didUpdateWidget(_PointsPill old) {
    super.didUpdateWidget(old);
    if (widget.points == _to) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _from = _to = widget.points;
      return;
    }
    _from = _to;
    _to = widget.points;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shown = (_from + (_to - _from) * _count.value).round();
        final flash = ((_scale.value - 1.0) / 0.3).clamp(0.0, 1.0);
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Color.lerp(sa.paper2, sa.tintAmber, flash),
              borderRadius: SaRadius.pill,
              boxShadow: sa.liftSm,
            ),
            child: Text(
              '$shown pts',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: sa.forest,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DebugResetButton extends StatelessWidget {
  const _DebugResetButton({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Missions'),
            content: const Text('Clear all missions and Mia Points?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onReset();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        child: const Text('Debug: Reset Missions'),
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
      decoration: BoxDecoration(
        color: sa.forest,
        borderRadius: SaRadius.xlAll,
        boxShadow: sa.lift,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: sa.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: sa.paper.withValues(alpha: 0.14),
                width: 1.5,
              ),
            ),
            child: Image.asset('assets/img/mia-icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: saved > 0
                ? _SavingsCopy(
                    saved: saved,
                    projected: insights.projectedAnnualCents,
                  )
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
        Text(
          'MIA · DÁ PRA ECONOMIZAR',
          style: SaText.heroLabel.copyWith(color: sa.amber),
        ),
        const SizedBox(height: 3),
        Text(
          'Comprando no lugar mais barato, você guarda',
          style: theme.textTheme.bodyMedium!.copyWith(
            color: sa.paper.withValues(alpha: 0.80),
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          formatBRL(saved),
          style: theme.textTheme.headlineMedium!.copyWith(color: sa.paper),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall!.copyWith(
              color: sa.paper.withValues(alpha: 0.66),
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(
                text: 'São os preços melhores que achei nas suas notas.',
              ),
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

/// No notes yet â€” the onboarding nudge, never a fabricated figure.
class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MIA', style: SaText.heroLabel.copyWith(color: sa.amber)),
        const SizedBox(height: 6),
        Text(
          'Escaneie sua primeira nota e eu começo a caçar economia pra você.',
          style: theme.textTheme.bodyLarge!.copyWith(
            color: sa.paper,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// 2×2 shortcut grid, each tile's meta line wired to real local data where one
/// exists yet â€” Mercado has no live count to show, so its meta line is fixed
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
                icon: Icons.shopping_cart_rounded,
                tint: sa.tintGreen,
                semanticLabel: 'Lista de compras',
                label: 'Lista de Compras',
                meta: listCount > 0
                    ? '${_plural(listCount, "item", "itens")} pra comprar'
                    : 'Monte sua lista',
                onTap: () => context.go('/lista'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                icon: Icons.storefront_rounded,
                tint: sa.paper2,
                semanticLabel: 'Mercado',
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
                icon: Icons.local_fire_department_rounded,
                tint: sa.tintAmber,
                semanticLabel: 'Ofertas',
                label: 'Ofertas do dia',
                meta: todayCount > 0
                    ? '${_plural(todayCount, "oferta", "ofertas")} hoje'
                    : 'Melhores dias por categoria',
                onTap: () => context.go('/ofertas'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                icon: Icons.receipt_long_rounded,
                tint: sa.paper2,
                semanticLabel: 'Notas fiscais',
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
                icon: Icons.category_rounded,
                tint: sa.tintGreen,
                semanticLabel: 'Catálogo',
                label: 'Catálogo',
                meta: 'Produtos por mercado',
                onTap: () => context.push('/catalogo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                icon: Icons.shopping_bag_rounded,
                tint: sa.paper2,
                semanticLabel: 'Loja da Mia',
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
    required this.icon,
    required this.tint,
    required this.semanticLabel,
    required this.label,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String semanticLabel;
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
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: SaRadius.smAll,
                  ),
                  child: Semantics(
                    label: semanticLabel,
                    excludeSemantics: true,
                    child: Icon(icon, size: 21, color: sa.ink),
                  ),
                ),
                const SizedBox(height: 10),
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  meta,
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

/// One data-driven tip for today: the cheapest category-day trend that lands
/// on today's weekday, or â€” per the honesty rule â€” a learning nudge instead
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
      decoration: BoxDecoration(
        color: sa.paper,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pets_rounded, size: 24, color: sa.ink),
          const SizedBox(width: 10),
          Expanded(
            child: top == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ainda aprendendo os preços daqui',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Escaneie algumas notas e eu descubro os melhores dias de cada categoria na sua região.',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: sa.muted,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoje é dia de ${top.category.label.toLowerCase()}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${top.category.label} costuma sair mais barato hoje'
                        '${top.store != null ? " no ${top.store}" : " por perto"}.',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: sa.muted,
                        ),
                      ),
                    ],
                  ),
          ),
          if (top != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: sa.tintGreen,
                borderRadius: SaRadius.pill,
              ),
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
