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

class _QuestToastState extends ConsumerState<QuestToast> {
  @override
  Widget build(BuildContext context) {
    final row = ref.watch(questToastProvider);
    if (row == null) return const SizedBox.shrink();
    final sa = Theme.of(context).sa;
    return Positioned(
      left: 14,
      right: 14,
      bottom: 78,
      child: Material(
        color: sa.forest,
        borderRadius: SaRadius.lgAll,
        elevation: 8,
        child: InkWell(
          borderRadius: SaRadius.lgAll,
          onTap: () => ref.read(questToastProvider.notifier).state = null,
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
      ),
    );
  }
}
