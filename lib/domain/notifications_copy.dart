import 'quests.dart';

/// Daily reminder copy. Returns null if there's nothing true to nudge about
/// (honesty rule — never send an empty/fabricated notification).
///
/// Priority order, each Mia-voiced pt-BR:
/// 1. Claim unclaimed quest(s) — "resgate sua recompensa"
/// 2. Open quest(s) still in progress — name one quest by label
/// 3. Stale scanning (3+ days) — "escaneie sua próxima nota"
/// 4. Otherwise → null (skip sending)
String? dailyReminderCopy({
  required QuestView quests,
  int? daysSinceLastScan,
}) {
  final hasUnclaimed = quests.daily.any((q) => q.done && !q.claimed) ||
      quests.weekly.any((q) => q.done && !q.claimed);
  if (hasUnclaimed) {
    return 'Resgate sua recompensa de Mia Points!';
  }

  final openDaily = quests.daily.firstWhereOrNull((q) => !q.done);
  if (openDaily != null) {
    return 'Missão do dia: ${openDaily.definition.label}';
  }

  if (daysSinceLastScan != null && daysSinceLastScan >= 3) {
    return 'Escaneie sua próxima nota e ganhe Mia Points!';
  }

  return null;
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
