import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/quests.dart';
import '../gamification/gamification_controller.dart';

enum ActionIndicatorTarget {
  homeTab,
  listaTab,
  ofertasTab,
  resumoTab,
  scanButton,
}

class ActionIndicator {
  const ActionIndicator({required this.count, required this.semanticLabel});

  final int count;
  final String semanticLabel;

  bool get visible => count > 0;

  String get displayCount => count > 99 ? '99+' : count.toString();
}

int pendingQuestClaimCount(QuestView view) => [
  ...view.daily,
  ...view.weekly,
  ...view.ftue,
].where((row) => row.done && !row.claimed).length;

final pendingQuestClaimCountProvider = Provider<int>((ref) {
  final state = ref.watch(gamificationProvider);
  final view = questView(state, now: DateTime.now().millisecondsSinceEpoch);
  return pendingQuestClaimCount(view);
});

final actionIndicatorsProvider =
    Provider<Map<ActionIndicatorTarget, ActionIndicator>>((ref) {
      final claimableQuests = ref.watch(pendingQuestClaimCountProvider);
      if (claimableQuests <= 0) return const {};

      final noun = claimableQuests == 1 ? 'missao' : 'missoes';
      return {
        ActionIndicatorTarget.homeTab: ActionIndicator(
          count: claimableQuests,
          semanticLabel: '$claimableQuests $noun para coletar',
        ),
      };
    });
