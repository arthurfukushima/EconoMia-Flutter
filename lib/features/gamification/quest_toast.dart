import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/tokens.dart';
import 'gamification_controller.dart';

/// A completion is announced wherever it happened; points are intentionally
/// not paid here. The Home board remains the single, explicit claim action.
class QuestToast extends ConsumerStatefulWidget {
  const QuestToast({super.key});
  @override
  ConsumerState<QuestToast> createState() => _QuestToastState();
}

class _QuestToastState extends ConsumerState<QuestToast>
    with TickerProviderStateMixin {
  late AnimationController _dismissController;
  late AnimationController _appearController;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _playDisappear();
        }
      });
    _appearController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  void _playDisappear() {
    _appearController.reverse().then((_) {
      ref.read(questToastProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _dismissController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = ref.watch(questToastProvider);
    ref.listen(questToastProvider, (previous, next) {
      if (next != null && previous == null) {
        _appearController.reset();
        _dismissController.reset();
        _appearController.forward().then((_) {
          _dismissController.forward();
        });
      } else if (next == null) {
        _appearController.reset();
        _dismissController.reset();
      }
    });
    if (row == null) return const SizedBox.shrink();
    final sa = Theme.of(context).sa;
    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, child) {
        final appearCurve = Curves.easeOut.transform(_appearController.value);
        final scale = 0.8 + (0.2 * appearCurve);
        final opacity = appearCurve;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Positioned(
              left: 14,
              right: 14,
              top: 14 + (20 * (1 - appearCurve)),
              child: child!,
            ),
          ),
        );
      },
      child: Material(
        color: sa.forest,
        borderRadius: SaRadius.lgAll,
        elevation: 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: SaRadius.lg,
                topRight: SaRadius.lg,
              ),
              onTap: () {
                _dismissController.stop();
                _playDisappear();
              },
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Icon(Icons.pets_rounded, size: 23, color: sa.paper),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Boa! Missão concluída\n',
                              style: TextStyle(
                                color: sa.amber,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${row.definition.label} — resgate +${row.definition.points} pts em Início.',
                              style: TextStyle(color: sa.paper),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _dismissController,
              builder: (context, _) {
                final remaining = 1 - _dismissController.value;
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: SaRadius.lg,
                    bottomRight: SaRadius.lg,
                  ),
                  child: LinearProgressIndicator(
                    value: remaining,
                    minHeight: 3,
                    backgroundColor: sa.forest.withValues(alpha: 0.3),
                    color: sa.amber,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
