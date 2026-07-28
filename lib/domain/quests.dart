const questDay = Duration(days: 1);
const questWeek = Duration(days: 7);

class QuestDefinition {
  const QuestDefinition(
    this.id,
    this.kind,
    this.event,
    this.goal,
    this.points,
    this.emoji,
    this.label,
  );
  final String id, kind, event, emoji, label;
  final int goal, points;
}

class QuestSlot {
  const QuestSlot({
    required this.id,
    required this.base,
    this.hit = false,
    this.claimed = false,
  });
  final String id;
  final int base;
  final bool hit, claimed;
  QuestSlot copyWith({int? base, bool? hit, bool? claimed}) => QuestSlot(
    id: id,
    base: base ?? this.base,
    hit: hit ?? this.hit,
    claimed: claimed ?? this.claimed,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'base': base,
    'hit': hit,
    'claimed': claimed,
  };
  factory QuestSlot.fromJson(Map<String, dynamic> json) => QuestSlot(
    id: json['id'] as String,
    base: (json['base'] as num?)?.toInt() ?? 0,
    hit: json['hit'] == true,
    claimed: json['claimed'] == true,
  );
}

class QuestTrack {
  const QuestTrack({this.at = 0, this.slots = const []});
  final int at;
  final List<QuestSlot> slots;
  QuestTrack copyWith({int? at, List<QuestSlot>? slots}) =>
      QuestTrack(at: at ?? this.at, slots: slots ?? this.slots);
  Map<String, dynamic> toJson() => {
    'at': at,
    'slots': [for (final s in slots) s.toJson()],
  };
}

class QuestState {
  const QuestState({
    this.counts = const {},
    this.daily = const QuestTrack(),
    this.weekly = const QuestTrack(),
    this.ftue = const [],
    this.ftueDone = const [],
  });
  final Map<String, int> counts;
  final QuestTrack daily, weekly;
  final List<QuestSlot> ftue;
  final List<String> ftueDone;
  QuestState copyWith({
    Map<String, int>? counts,
    QuestTrack? daily,
    QuestTrack? weekly,
    List<QuestSlot>? ftue,
    List<String>? ftueDone,
  }) => QuestState(
    counts: counts ?? this.counts,
    daily: daily ?? this.daily,
    weekly: weekly ?? this.weekly,
    ftue: ftue ?? this.ftue,
    ftueDone: ftueDone ?? this.ftueDone,
  );
  Map<String, dynamic> toJson() => {
    'counts': counts,
    'daily': daily.toJson(),
    'weekly': weekly.toJson(),
    'ftue': [for (final s in ftue) s.toJson()],
    'ftueDone': ftueDone,
  };
}

class QuestRow {
  const QuestRow({
    required this.definition,
    required this.progress,
    required this.done,
    required this.claimed,
  });
  final QuestDefinition definition;
  final int progress;
  final bool done, claimed;
}

class QuestView {
  const QuestView({
    required this.daily,
    required this.weekly,
    required this.ftue,
    required this.dailyIn,
    required this.weeklyIn,
  });
  final List<QuestRow> daily, weekly, ftue;
  final Duration dailyIn, weeklyIn;
}

class QuestRefresh {
  const QuestRefresh(this.state, this.autoAwarded);
  final QuestState state;
  final int autoAwarded;
}

const catalog = <QuestDefinition>[
  QuestDefinition(
    'd_nota',
    'daily',
    'note',
    1,
    30,
    '🧾',
    'Escaneie 1 nota fiscal',
  ),
  QuestDefinition(
    'd_prod',
    'daily',
    'product',
    3,
    20,
    '🏷️',
    'Escaneie 3 produtos',
  ),
  QuestDefinition(
    'd_lista',
    'daily',
    'list_add',
    3,
    15,
    '🛒',
    'Adicione 3 itens à lista',
  ),
  QuestDefinition(
    'd_check',
    'daily',
    'list_check',
    3,
    15,
    '✅',
    'Marque 3 itens como comprados',
  ),
  QuestDefinition(
    'd_mercado',
    'daily',
    'mercado',
    5,
    25,
    '🏪',
    'Confira 5 preços no mercado',
  ),
  QuestDefinition(
    'w_nota',
    'weekly',
    'note',
    3,
    100,
    '🧾',
    'Escaneie 3 notas fiscais',
  ),
  QuestDefinition(
    'w_prod',
    'weekly',
    'product',
    10,
    80,
    '🏷️',
    'Escaneie 10 produtos',
  ),
  QuestDefinition(
    'w_lista',
    'weekly',
    'list_add',
    10,
    60,
    '🛒',
    'Monte uma lista com 10 itens',
  ),
  QuestDefinition(
    'w_mercado',
    'weekly',
    'mercado',
    15,
    90,
    '🏪',
    'Confira 15 preços no mercado',
  ),
  QuestDefinition(
    'w_check',
    'weekly',
    'list_check',
    10,
    50,
    '✅',
    'Marque 10 itens como comprados',
  ),
  QuestDefinition(
    'f_local',
    'ftue',
    'location',
    1,
    20,
    '📍',
    'Compartilhe sua localização',
  ),
  QuestDefinition(
    'f_nota',
    'ftue',
    'note',
    1,
    50,
    '🧾',
    'Escaneie sua primeira nota',
  ),
  QuestDefinition(
    'f_prod',
    'ftue',
    'product',
    1,
    30,
    '🏷️',
    'Escaneie seu primeiro produto',
  ),
  QuestDefinition(
    'f_lista',
    'ftue',
    'list_add',
    1,
    20,
    '🛒',
    'Crie sua lista de compras',
  ),
  QuestDefinition(
    'f_check',
    'ftue',
    'list_check',
    1,
    20,
    '✅',
    'Marque um item como comprado',
  ),
  QuestDefinition(
    'f_mercado',
    'ftue',
    'mercado',
    1,
    30,
    '🏪',
    'Compare preços no modo "No mercado"',
  ),
  QuestDefinition(
    'f_nota5',
    'ftue',
    'note',
    5,
    100,
    '🧾',
    'Escaneie 5 notas fiscais',
  ),
  QuestDefinition(
    'f_prod10',
    'ftue',
    'product',
    10,
    60,
    '🏷️',
    'Escaneie 10 produtos',
  ),
];
const questCatalog = catalog;

QuestDefinition? questInfo(String id) {
  for (final q in catalog) {
    if (q.id == id) return q;
  }
  return null;
}

QuestState emptyQuestState() => const QuestState();

int questProgress(QuestState state, QuestSlot slot) {
  final q = questInfo(slot.id);
  if (q == null) return 0;
  final n = (state.counts[q.event] ?? 0) - slot.base;
  return n.clamp(0, q.goal);
}

bool questDone(QuestState state, QuestSlot slot) =>
    questProgress(state, slot) >= (questInfo(slot.id)?.goal ?? 1);

// Short aliases keep the reducer pleasant to use in tests and callers.
QuestState emptyState() => emptyQuestState();
int progress(QuestState state, QuestSlot slot) => questProgress(state, slot);
bool isDone(QuestState state, QuestSlot slot) => questDone(state, slot);

List<QuestSlot> _fill(
  QuestState state,
  String kind,
  List<QuestSlot> current,
  int now,
  int period,
  int count,
) {
  final pool = catalog
      .where(
        (q) =>
            q.kind == kind &&
            !state.ftueDone.contains(q.id) &&
            !current.any((s) => s.id == q.id),
      )
      .toList();
  final offset = period == 0
      ? 0
      : (now ~/ period) % (pool.isEmpty ? 1 : pool.length);
  final out = [...current];
  for (var i = 0; out.length < count && i < pool.length; i++) {
    final q = pool[(offset + i) % pool.length];
    out.add(QuestSlot(id: q.id, base: state.counts[q.event] ?? 0));
  }
  return out;
}

QuestRefresh refreshQuests(QuestState original, {required int now}) {
  var state = original.copyWith(counts: {...original.counts});
  var award = 0;
  QuestTrack roll(QuestTrack track, String kind, int period, int count) {
    var slots = track.slots;
    var at = track.at;
    if (now - at >= period) {
      for (final slot in slots) {
        if (questDone(state, slot) && !slot.claimed) {
          award += questInfo(slot.id)?.points ?? 0;
        }
      }
      slots = [
        for (final slot in slots)
          if (!slot.claimed && !questDone(state, slot)) slot,
      ];
      at = now;
    }
    return QuestTrack(
      at: at,
      slots: _fill(state, kind, slots, now, period, count),
    );
  }

  state = state.copyWith(
    daily: roll(state.daily, 'daily', questDay.inMilliseconds, 3),
    weekly: roll(state.weekly, 'weekly', questWeek.inMilliseconds, 3),
  );
  state = state.copyWith(ftue: _fill(state, 'ftue', state.ftue, now, 0, 5));
  return QuestRefresh(state, award);
}

QuestRefresh refresh(QuestState state, [int? now]) =>
    refreshQuests(state, now: now ?? DateTime.now().millisecondsSinceEpoch);

QuestView questView(QuestState state, {required int now}) {
  List<QuestRow> rows(List<QuestSlot> slots) => [
    for (final s in slots)
      if (questInfo(s.id) case final q?)
        QuestRow(
          definition: q,
          progress: questProgress(state, s),
          done: questDone(state, s),
          claimed: s.claimed,
        ),
  ];
  Duration left(int at, Duration period) => Duration(
    milliseconds: (at + period.inMilliseconds - now).clamp(0, 1 << 62),
  );
  return QuestView(
    daily: rows(state.daily.slots),
    weekly: rows(state.weekly.slots),
    ftue: rows(state.ftue),
    dailyIn: left(state.daily.at, questDay),
    weeklyIn: left(state.weekly.at, questWeek),
  );
}

QuestView view(QuestState state, [int? now]) =>
    questView(state, now: now ?? DateTime.now().millisecondsSinceEpoch);
