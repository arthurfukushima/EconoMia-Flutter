import 'package:economia/features/action_indicators/action_indicators.dart';
import 'package:economia/domain/quests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending quest claim count only includes done and unclaimed rows', () {
    final view = QuestView(
      daily: [
        QuestRow(
          definition: questInfo('d_nota')!,
          progress: 1,
          done: true,
          claimed: false,
        ),
        QuestRow(
          definition: questInfo('d_prod')!,
          progress: 3,
          done: true,
          claimed: true,
        ),
      ],
      weekly: [
        QuestRow(
          definition: questInfo('w_nota')!,
          progress: 2,
          done: false,
          claimed: false,
        ),
        QuestRow(
          definition: questInfo('w_prod')!,
          progress: 10,
          done: true,
          claimed: false,
        ),
      ],
      ftue: [
        QuestRow(
          definition: questInfo('f_lista')!,
          progress: 1,
          done: true,
          claimed: false,
        ),
      ],
      dailyIn: questDay,
      weeklyIn: questWeek,
    );

    expect(pendingQuestClaimCount(view), 3);
  });

  test('action indicator display count caps at 99+', () {
    const indicator = ActionIndicator(
      count: 120,
      semanticLabel: '120 acoes pendentes',
    );

    expect(indicator.displayCount, '99+');
  });
}
