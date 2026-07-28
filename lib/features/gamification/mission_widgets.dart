import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/quests.dart';
import '../../theme/fonts.dart';
import '../../theme/tokens.dart';

List<QuestRow> topMissionRows(QuestView view, {int limit = 3}) {
  final rows = [
    ...view.daily,
    ...view.weekly,
    ...view.ftue,
  ].where((row) => !row.claimed).toList();
  rows.sort(_compareMissionRows);
  return rows.take(limit).toList();
}

int _compareMissionRows(QuestRow a, QuestRow b) {
  final aRemaining = a.definition.goal - a.progress;
  final bRemaining = b.definition.goal - b.progress;
  if (aRemaining != bRemaining) return aRemaining.compareTo(bRemaining);

  final aRatio = a.progress / a.definition.goal;
  final bRatio = b.progress / b.definition.goal;
  final ratioOrder = bRatio.compareTo(aRatio);
  if (ratioOrder != 0) return ratioOrder;

  return a.definition.points.compareTo(b.definition.points);
}

String renewLabel(Duration d) =>
    d.inHours > 36 ? '${(d.inHours / 24).ceil()}d' : '${d.inHours.ceil()}h';

IconData missionIcon(String event) => switch (event) {
  'note' => Icons.receipt_long_rounded,
  'product' => Icons.sell_rounded,
  'list_add' => Icons.add_shopping_cart_rounded,
  'list_check' => Icons.check_circle_rounded,
  'mercado' => Icons.storefront_rounded,
  'location' => Icons.my_location_rounded,
  _ => Icons.stars_rounded,
};

class MissionCarousel extends StatefulWidget {
  const MissionCarousel({super.key, required this.view, required this.onClaim});

  final QuestView view;
  final ValueChanged<String> onClaim;

  @override
  State<MissionCarousel> createState() => _MissionCarouselState();
}

class _MissionCarouselState extends State<MissionCarousel> {
  late final PageController _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = topMissionRows(widget.view);
    final sa = Theme.of(context).sa;
    if (rows.isEmpty) {
      return const _MissionsEmptyCard(
        message:
            'Suas proximas missoes vao aparecer aqui conforme voce usa o app.',
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 152,
          child: PageView.builder(
            controller: _controller,
            itemCount: rows.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final row = rows[index];
              final hint = switch (row.definition.kind) {
                'daily' =>
                  'Diaria · renova em ${renewLabel(widget.view.dailyIn)}',
                'weekly' =>
                  'Semanal · renova em ${renewLabel(widget.view.weeklyIn)}',
                _ => 'Primeiros passos',
              };
              return Padding(
                padding: EdgeInsets.only(
                  right: index == rows.length - 1 ? 0 : 10,
                ),
                child: MissionHeroCard(
                  row: row,
                  hint: hint,
                  onClaim: widget.onClaim,
                ),
              );
            },
          ),
        ),
        if (rows.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < rows.length; i++)
                AnimatedContainer(
                  duration: SaMotion.normal,
                  width: i == _page ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _page ? sa.amber : sa.stroke2,
                    borderRadius: SaRadius.pill,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class MissionHeroCard extends StatefulWidget {
  const MissionHeroCard({
    super.key,
    required this.row,
    required this.hint,
    required this.onClaim,
  });

  final QuestRow row;
  final String hint;
  final ValueChanged<String> onClaim;

  @override
  State<MissionHeroCard> createState() => _MissionHeroCardState();
}

class _MissionHeroCardState extends State<MissionHeroCard>
    with SingleTickerProviderStateMixin {
  late final _flash = claimFlashController(this);

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  void _claim() {
    final sa = Theme.of(context).sa;
    triggerClaimFlourish(context, _flash, widget.row.definition.points, sa);
    widget.onClaim(widget.row.definition.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final row = widget.row;
    final ratio = row.definition.goal == 0
        ? 0.0
        : row.progress / row.definition.goal;

    return AnimatedBuilder(
      animation: _flash,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          color: Color.lerp(sa.paper, sa.tintGreen, claimFlashValue(_flash)),
          borderRadius: SaRadius.xlAll,
          border: Border.all(
            color: row.done ? sa.stroke2 : sa.stroke,
            width: 1.5,
          ),
          boxShadow: sa.liftSm,
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sa.paper2,
                  borderRadius: SaRadius.mdAll,
                ),
                child: Icon(missionIcon(row.definition.event), color: sa.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.definition.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.hint,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: sa.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: SaRadius.pill,
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: sa.paper2,
              color: row.done ? sa.green : sa.amber,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                row.claimed
                    ? 'Resgatada'
                    : row.done
                    ? 'Pronta para resgatar'
                    : '${row.progress}/${row.definition.goal} concluido',
                style: theme.textTheme.labelMedium!.copyWith(
                  color: row.done && !row.claimed ? sa.green : sa.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (row.claimed)
                Text(
                  '+${row.definition.points} pts',
                  style: theme.textTheme.labelLarge!.copyWith(color: sa.green),
                )
              else if (row.done)
                TextButton(
                  onPressed: _claim,
                  child: Text('Resgatar +${row.definition.points}'),
                )
              else
                Text(
                  '+${row.definition.points} pts',
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: sa.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MissionsBoard extends StatelessWidget {
  const MissionsBoard({super.key, required this.view, required this.onClaim});

  final QuestView view;
  final ValueChanged<String> onClaim;

  @override
  Widget build(BuildContext context) {
    final ready = [
      ...view.daily,
      ...view.weekly,
      ...view.ftue,
    ].where((q) => q.done && !q.claimed).length;
    final groups = <({String title, List<QuestRow> rows, String? hint})>[
      (
        title: 'Diarias',
        rows: view.daily,
        hint: 'renova em ${renewLabel(view.dailyIn)}',
      ),
      (
        title: 'Semanais',
        rows: view.weekly,
        hint: 'renova em ${renewLabel(view.weeklyIn)}',
      ),
      (title: 'Primeiros passos', rows: view.ftue, hint: null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MISSOES DA MIA${ready > 0 ? ' · $ready para resgatar' : ''}',
          style: SaText.sectionLabel.copyWith(
            color: Theme.of(context).sa.muted,
          ),
        ),
        const SizedBox(height: 10),
        for (final group in groups)
          if (group.rows.isNotEmpty) ...[
            Text(
              '${group.title}${group.hint == null ? '' : ' · ${group.hint}'}',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).sa.muted,
              ),
            ),
            const SizedBox(height: 5),
            for (final row in group.rows)
              MissionRow(row: row, onClaim: onClaim),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class MissionRow extends StatefulWidget {
  const MissionRow({super.key, required this.row, required this.onClaim});

  final QuestRow row;
  final ValueChanged<String> onClaim;

  @override
  State<MissionRow> createState() => _MissionRowState();
}

class _MissionRowState extends State<MissionRow>
    with SingleTickerProviderStateMixin {
  late final _flash = claimFlashController(this);

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  void _claim() {
    final sa = Theme.of(context).sa;
    triggerClaimFlourish(context, _flash, widget.row.definition.points, sa);
    widget.onClaim(widget.row.definition.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final row = widget.row;
    return AnimatedBuilder(
      animation: _flash,
      builder: (context, child) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Color.lerp(sa.paper, sa.tintGreen, claimFlashValue(_flash)),
          borderRadius: SaRadius.mdAll,
          border: Border.all(color: row.done ? sa.stroke2 : sa.stroke),
        ),
        child: child,
      ),
      child: Row(
        children: [
          Semantics(
            label: row.definition.label,
            excludeSemantics: true,
            child: Icon(
              missionIcon(row.definition.event),
              size: 19,
              color: sa.ink,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.definition.label,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: SaRadius.pill,
                  child: LinearProgressIndicator(
                    value: row.progress / row.definition.goal,
                    minHeight: 5,
                    backgroundColor: sa.paper2,
                    color: row.done ? sa.green : sa.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          AnimatedSwitcher(
            duration: SaMotion.normal,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: SaMotion.easeBack,
              ),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: row.claimed
                ? Text(
                    'resgatado',
                    key: const ValueKey('claimed'),
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: sa.green,
                    ),
                  )
                : row.done
                ? TextButton(
                    key: const ValueKey('claim'),
                    onPressed: _claim,
                    child: Text('Resgatar +${row.definition.points}'),
                  )
                : Text(
                    '${row.progress}/${row.definition.goal}\n+${row.definition.points}',
                    key: const ValueKey('progress'),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: sa.muted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class MissionsEntryCard extends StatelessWidget {
  const MissionsEntryCard({super.key, required this.view, required this.onTap});

  final QuestView view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final total = view.daily.length + view.weekly.length + view.ftue.length;
    final ready = [
      ...view.daily,
      ...view.weekly,
      ...view.ftue,
    ].where((row) => row.done && !row.claimed).length;

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
                child: Icon(Icons.flag_rounded, color: sa.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ver todas as missoes',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ready > 0
                          ? '$ready prontas para resgatar · $total ativas'
                          : '$total missoes ativas',
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: sa.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: sa.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionsEmptyCard extends StatelessWidget {
  const _MissionsEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sa.paper,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
      ),
    );
  }
}

/// Shared claim-moment flourish for [MissionHeroCard] and [MissionRow]: a
/// stronger haptic, the card's own background flash (driven by [flash], a
/// controller each card owns so its card — not its neighbours — lights up),
/// and the overlay burst. Kept as free functions rather than a mixin since
/// each card's `build` still needs its own `AnimatedBuilder`/`Container`.
AnimationController claimFlashController(TickerProvider vsync) =>
    AnimationController(duration: SaMotion.slow, vsync: vsync);

/// A 0→1→0 pulse across the controller's span, quick up / slow settle.
double claimFlashValue(AnimationController flash) {
  final t = flash.value;
  return t < 0.3 ? (t / 0.3) : (1 - (t - 0.3) / 0.7);
}

void triggerClaimFlourish(
  BuildContext context,
  AnimationController flash,
  int points,
  SaColors sa,
) {
  HapticFeedback.heavyImpact();
  flash.forward(from: 0);
  showClaimBurst(context, points, sa);
}

void showClaimBurst(BuildContext context, int points, SaColors sa) {
  if (MediaQuery.disableAnimationsOf(context)) return;
  final overlay = Overlay.of(context);
  final box = context.findRenderObject() as RenderBox;
  final overlayBox = overlay.context.findRenderObject() as RenderBox;
  final origin = overlayBox.globalToLocal(
    box.localToGlobal(box.size.topRight(Offset.zero)),
  );
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ClaimBurst(
      origin: origin,
      points: points,
      colors: [sa.amber, sa.green, sa.mint],
      textColor: sa.ink,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _Spark {
  _Spark(this.angle, this.distance, this.size, this.color);
  final double angle, distance, size;
  final Color color;
}

/// A dozen dots bursting outward and falling (a plain [CustomPainter], no
/// particle package) plus a bigger "+N" pill that pops in and rises — the
/// full flourish for a claimed mission, over the tapped button's own spot.
class _ClaimBurst extends StatefulWidget {
  const _ClaimBurst({
    required this.origin,
    required this.points,
    required this.colors,
    required this.textColor,
    required this.onDone,
  });

  final Offset origin;
  final int points;
  final List<Color> colors;
  final Color textColor;
  final VoidCallback onDone;

  @override
  State<_ClaimBurst> createState() => _ClaimBurstState();
}

class _ClaimBurstState extends State<_ClaimBurst>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(
          duration: const Duration(milliseconds: 900),
          vsync: this,
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  late final _sparks = List.generate(12, (i) {
    final rnd = math.Random(i * 7919 + widget.points * 31);
    final angle = (i / 12) * 2 * math.pi + rnd.nextDouble() * 0.4;
    return _Spark(
      angle,
      34.0 + rnd.nextDouble() * 32,
      2.5 + rnd.nextDouble() * 2.5,
      widget.colors[i % widget.colors.length],
    );
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final burstT = Curves.easeOut.transform(t);
        final popT = SaMotion.easeBack.transform((t / 0.3).clamp(0.0, 1.0));
        final riseT = SaMotion.easeOut.transform(t);
        final fadeT = Curves.easeIn.transform(t);
        return Stack(
          children: [
            Positioned(
              left: widget.origin.dx - 70,
              top: widget.origin.dy - 70,
              width: 140,
              height: 140,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SparkPainter(
                    sparks: _sparks,
                    t: burstT,
                    center: const Offset(70, 70),
                  ),
                ),
              ),
            ),
            Positioned(
              left: widget.origin.dx - 44,
              top: widget.origin.dy - 10 - 46 * riseT,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1 - fadeT).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * popT,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.colors.first,
                        borderRadius: SaRadius.pill,
                      ),
                      child: Text(
                        '+${widget.points}',
                        style: TextStyle(
                          color: widget.textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.sparks, required this.t, required this.center});

  final List<_Spark> sparks;
  final double t;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    for (final spark in sparks) {
      final dist = spark.distance * t;
      final fall = 20 * t * t;
      final pos =
          center +
          Offset(math.cos(spark.angle), math.sin(spark.angle)) * dist +
          Offset(0, fall);
      final paint = Paint()
        ..color = spark.color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.drawCircle(pos, spark.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.t != t;
}
