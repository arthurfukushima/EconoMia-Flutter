import 'package:economia/domain/quests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a slot only counts events after it opened', () {
    const now = 1000000;
    final state = QuestState(
      counts: {'note': 5},
      daily: const QuestTrack(at: now, slots: [QuestSlot(id: 'd_nota', base: 5)]),
    );
    final result = refresh(state, now);
    final slot = result.state.daily.slots.firstWhere((s) => s.id == 'd_nota');
    expect(questProgress(result.state, slot), 0);
    expect(questDone(result.state, slot), isFalse);
  });

  test('daily and weekly slots rotate deterministically', () {
    final a = refresh(emptyState(), 86400000 * 4).state;
    final b = refresh(emptyState(), 86400000 * 4).state;
    expect([for (final s in a.daily.slots) s.id], [for (final s in b.daily.slots) s.id]);
    expect(a.daily.slots, hasLength(3));
    expect(a.weekly.slots, hasLength(3));
  });

  test('completed but unclaimed work is paid when its window rolls', () {
    const opened = 1000000;
    final state = QuestState(
      counts: const {'note': 1},
      daily: const QuestTrack(at: opened, slots: [QuestSlot(id: 'd_nota', base: 0)]),
    );
    final result = refresh(state, opened + questDay.inMilliseconds);
    expect(result.autoAwarded, 30);
    expect(result.state.daily.slots.any((s) => s.id == 'd_nota'), isFalse);
  });
}
