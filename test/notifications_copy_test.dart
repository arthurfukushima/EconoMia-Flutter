import 'package:economia/domain/notifications_copy.dart';
import 'package:economia/domain/quests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dailyReminderCopy', () {
    test('nudge to claim unclaimed quest', () {
      final view = QuestView(
        daily: [
          QuestRow(
            definition: const QuestDefinition('d_nota', 'daily', 'note', 1, 30, '🧾', 'Escaneie 1 nota fiscal'),
            progress: 1,
            done: true,
            claimed: false,
          ),
        ],
        weekly: const [],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: null),
        'Resgate sua recompensa de Mia Points!',
      );
    });

    test('nudge on weekly unclaimed quest', () {
      final view = QuestView(
        daily: const [],
        weekly: [
          QuestRow(
            definition: const QuestDefinition('w_nota', 'weekly', 'note', 3, 100, '🧾', 'Escaneie 3 notas fiscais'),
            progress: 3,
            done: true,
            claimed: false,
          ),
        ],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: null),
        'Resgate sua recompensa de Mia Points!',
      );
    });

    test('nudge open daily quest by name', () {
      final view = QuestView(
        daily: [
          QuestRow(
            definition: const QuestDefinition('d_mercado', 'daily', 'mercado', 5, 25, '🏪', 'Confira 5 preços no mercado'),
            progress: 2,
            done: false,
            claimed: false,
          ),
        ],
        weekly: const [],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: null),
        'Missão do dia: Confira 5 preços no mercado',
      );
    });

    test('nudge for stale scan (3+ days)', () {
      final view = QuestView(
        daily: const [],
        weekly: const [],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: 3),
        'Escaneie sua próxima nota e ganhe Mia Points!',
      );
    });

    test('no nudge when everything done and claimed', () {
      final view = QuestView(
        daily: [
          QuestRow(
            definition: const QuestDefinition('d_nota', 'daily', 'note', 1, 30, '🧾', 'Escaneie 1 nota fiscal'),
            progress: 1,
            done: true,
            claimed: true,
          ),
        ],
        weekly: const [],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: 1),
        null,
      );
    });

    test('no nudge for recent scan with no open quests', () {
      final view = QuestView(
        daily: const [],
        weekly: const [],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: 2),
        null,
      );
    });

    test('skip stale scan nudge (< 3 days)', () {
      final view = QuestView(
        daily: const [],
        weekly: const [],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: 2),
        null,
      );
    });

    test('prioritize claim nudge over open quest', () {
      final view = QuestView(
        daily: [
          QuestRow(
            definition: const QuestDefinition('d_nota', 'daily', 'note', 1, 30, '🧾', 'Escaneie 1 nota fiscal'),
            progress: 2,
            done: false,
            claimed: false,
          ),
          QuestRow(
            definition: const QuestDefinition('d_prod', 'daily', 'product', 3, 20, '🏷️', 'Escaneie 3 produtos'),
            progress: 3,
            done: true,
            claimed: false,
          ),
        ],
        weekly: const [],
        ftue: const [],
        dailyIn: Duration.zero,
        weeklyIn: Duration.zero,
      );
      expect(
        dailyReminderCopy(quests: view, daysSinceLastScan: null),
        'Resgate sua recompensa de Mia Points!',
      );
    });
  });
}
