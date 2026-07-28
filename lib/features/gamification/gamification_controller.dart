import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/prefs.dart';
import '../../domain/quests.dart';

final gamificationProvider =
    NotifierProvider<GamificationController, QuestState>(
      GamificationController.new,
    );
final miaPointsProvider = Provider<int>(
  (ref) => ref.watch(gamificationProvider.notifier).points,
);
final questToastProvider = StateProvider<QuestRow?>((ref) => null);

class GamificationController extends Notifier<QuestState> {
  late Prefs _prefs;
  bool _loaded = false;
  int points = 0;

  @override
  QuestState build() {
    _prefs = ref.read(prefsProvider);
    _loaded = true;
    points = _prefs.miaPoints;
    final loaded = _read();
    final refreshed = refreshQuests(
      loaded,
      now: DateTime.now().millisecondsSinceEpoch,
    );
    state = refreshed.state;
    if (refreshed.autoAwarded > 0) points += refreshed.autoAwarded;
    _save();
    return state;
  }

  QuestState _read() {
    final raw = _prefs.questsJson;
    if (raw == null) return emptyQuestState();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      QuestTrack track(dynamic value) {
        final map = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        final slots = map['slots'] is List
            ? (map['slots'] as List)
                  .whereType<Map>()
                  .map((e) => QuestSlot.fromJson(Map<String, dynamic>.from(e)))
                  .where((s) => questInfo(s.id) != null)
                  .toList()
            : <QuestSlot>[];
        return QuestTrack(at: (map['at'] as num?)?.toInt() ?? 0, slots: slots);
      }

      final counts = <String, int>{};
      if (json['counts'] is Map) {
        for (final e in (json['counts'] as Map).entries) {
          if (e.value is num) {
            counts[e.key.toString()] = (e.value as num).toInt();
          }
        }
      }
      final ftue = json['ftue'] is List
          ? (json['ftue'] as List)
                .whereType<Map>()
                .map((e) => QuestSlot.fromJson(Map<String, dynamic>.from(e)))
                .where((s) => questInfo(s.id) != null)
                .toList()
          : <QuestSlot>[];
      final done = json['ftueDone'] is List
          ? (json['ftueDone'] as List).whereType<String>().toList()
          : <String>[];
      return QuestState(
        counts: counts,
        daily: track(json['daily']),
        weekly: track(json['weekly']),
        ftue: ftue,
        ftueDone: done,
      );
    } catch (_) {
      return emptyQuestState();
    }
  }

  void _save() {
    _prefs.setQuestsJson(jsonEncode(state.toJson()));
    _prefs.setMiaPoints(points);
  }

  void _ensureLoaded() {
    if (_loaded) return;
    _prefs = ref.read(prefsProvider);
    points = _prefs.miaPoints;
    _loaded = true;
  }

  void addPoints(int amount) {
    if (amount <= 0) return;
    _ensureLoaded();
    points += amount;
    _prefs.setMiaPoints(points);
    state = state;
  }

  void track(String event, [int amount = 1]) {
    if (amount <= 0) return;
    _ensureLoaded();
    final before = state;
    final next = refreshQuests(
      state.copyWith(
        counts: {...state.counts, event: (state.counts[event] ?? 0) + amount},
      ),
      now: DateTime.now().millisecondsSinceEpoch,
    );
    state = next.state;
    if (next.autoAwarded > 0) points += next.autoAwarded;
    final slots = [...state.daily.slots, ...state.weekly.slots, ...state.ftue];
    for (final slot in slots) {
      final wasDone =
          before.daily.slots.any(
            (s) => s.id == slot.id && questDone(before, s),
          ) ||
          before.weekly.slots.any(
            (s) => s.id == slot.id && questDone(before, s),
          ) ||
          before.ftue.any((s) => s.id == slot.id && questDone(before, s));
      if (!slot.hit && questDone(state, slot) && !wasDone) {
        ref.read(questToastProvider.notifier).state = QuestRow(
          definition: questInfo(slot.id)!,
          progress: questProgress(state, slot),
          done: true,
          claimed: false,
        );
        state = state.copyWith(
          daily: QuestTrack(
            at: state.daily.at,
            slots: [
              for (final s in state.daily.slots)
                if (s.id == slot.id) s.copyWith(hit: true) else s,
            ],
          ),
          weekly: QuestTrack(
            at: state.weekly.at,
            slots: [
              for (final s in state.weekly.slots)
                if (s.id == slot.id) s.copyWith(hit: true) else s,
            ],
          ),
          ftue: [
            for (final s in state.ftue)
              if (s.id == slot.id) s.copyWith(hit: true) else s,
          ],
        );
      }
    }
    _save();
  }

  void claim(String id) {
    _ensureLoaded();
    QuestSlot? found;
    if (state.daily.slots.any((s) => s.id == id)) {
      found = state.daily.slots.firstWhere((s) => s.id == id);
    }
    if (found == null && state.weekly.slots.any((s) => s.id == id)) {
      found = state.weekly.slots.firstWhere((s) => s.id == id);
    }
    if (found == null && state.ftue.any((s) => s.id == id)) {
      found = state.ftue.firstWhere((s) => s.id == id);
    }
    if (found == null || found.claimed || !questDone(state, found)) return;
    final q = questInfo(id)!;
    points += q.points;
    state = state.copyWith(
      daily: QuestTrack(
        at: state.daily.at,
        slots: [
          for (final s in state.daily.slots)
            if (s.id == id) s.copyWith(claimed: true) else s,
        ],
      ),
      weekly: QuestTrack(
        at: state.weekly.at,
        slots: [
          for (final s in state.weekly.slots)
            if (s.id == id) s.copyWith(claimed: true) else s,
        ],
      ),
      ftue: q.kind == 'ftue'
          ? [
              for (final s in state.ftue)
                if (s.id != id) s,
            ]
          : [
              for (final s in state.ftue)
                if (s.id == id) s.copyWith(claimed: true) else s,
            ],
      ftueDone: q.kind == 'ftue' ? [...state.ftueDone, id] : state.ftueDone,
    );
    final refreshed = refreshQuests(
      state,
      now: DateTime.now().millisecondsSinceEpoch,
    );
    state = refreshed.state;
    if (refreshed.autoAwarded > 0) points += refreshed.autoAwarded;
    _save();
  }

  QuestView view() =>
      questView(state, now: DateTime.now().millisecondsSinceEpoch);

  void reset() {
    _ensureLoaded();
    points = 0;
    state = emptyQuestState();
    _save();
  }
}
