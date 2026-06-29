import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// フラッシュカード習得状態プロバイダー
/// 習得済みカード ID の Set と個人メモを SharedPreferences に永続化する

class FlashcardState {
  final Set<String> masteredIds;           // 「わかった」マーク済みカード ID
  final Map<String, String> notes;          // カード ID → メモ文字列
  final Map<String, DateTime> masteredDates; // カード ID → 習得日

  const FlashcardState({
    this.masteredIds = const {},
    this.notes = const {},
    this.masteredDates = const {},
  });

  FlashcardState copyWith({
    Set<String>? masteredIds,
    Map<String, String>? notes,
    Map<String, DateTime>? masteredDates,
  }) =>
      FlashcardState(
        masteredIds: masteredIds ?? this.masteredIds,
        notes: notes ?? this.notes,
        masteredDates: masteredDates ?? this.masteredDates,
      );

  int get masteredCount => masteredIds.length;
  String? noteFor(String cardId) => notes[cardId];
  bool hasNote(String cardId) => notes.containsKey(cardId) && notes[cardId]!.isNotEmpty;
  DateTime? masteredDateFor(String cardId) => masteredDates[cardId];

  /// 習得してから何日経過しているか（未習得は null）
  int? daysSinceMastered(String cardId) {
    final d = masteredDates[cardId];
    if (d == null) return null;
    return DateTime.now().difference(d).inDays;
  }
}

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  FlashcardNotifier() : super(const FlashcardState()) {
    _load();
  }

  static const _key       = 'flashcard_mastered_ids';
  static const _notesKey  = 'flashcard_notes_v1';
  static const _datesKey  = 'flashcard_mastered_dates_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // 習得済み ID
    final raw = prefs.getString(_key);
    Set<String> ids = const {};
    if (raw != null) {
      final list = (json.decode(raw) as List).cast<String>();
      ids = Set<String>.from(list);
    }

    // メモ
    final notesRaw = prefs.getString(_notesKey);
    Map<String, String> notes = const {};
    if (notesRaw != null) {
      notes = Map<String, String>.from(json.decode(notesRaw) as Map);
    }

    // 習得日
    final datesRaw = prefs.getString(_datesKey);
    Map<String, DateTime> dates = {};
    if (datesRaw != null) {
      try {
        final decoded = Map<String, dynamic>.from(json.decode(datesRaw) as Map);
        dates = decoded.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
      } catch (_) {
        dates = {};
      }
    }

    state = state.copyWith(masteredIds: ids, notes: notes, masteredDates: dates);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state.masteredIds.toList()));
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesKey, json.encode(state.notes));
  }

  Future<void> _saveDates() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.masteredDates.map((k, v) => MapEntry(k, v.toIso8601String()));
    await prefs.setString(_datesKey, json.encode(encoded));
  }

  /// カードを「習得済み」にする
  Future<void> markMastered(String cardId) async {
    if (state.masteredIds.contains(cardId)) return;
    final newDates = Map<String, DateTime>.from(state.masteredDates)
      ..[cardId] = DateTime.now();
    state = state.copyWith(
      masteredIds: {...state.masteredIds, cardId},
      masteredDates: newDates,
    );
    await _save();
    await _saveDates();
  }

  /// 「習得済み」を取り消す
  Future<void> unmarkMastered(String cardId) async {
    if (!state.masteredIds.contains(cardId)) return;
    final updatedIds = Set<String>.from(state.masteredIds)..remove(cardId);
    final updatedDates = Map<String, DateTime>.from(state.masteredDates)..remove(cardId);
    state = state.copyWith(masteredIds: updatedIds, masteredDates: updatedDates);
    await _save();
    await _saveDates();
  }

  bool isMastered(String cardId) => state.masteredIds.contains(cardId);

  /// 複数カードをまとめて「習得済み」にする（一括習得用）
  Future<void> markAllMastered(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    final now = DateTime.now();
    final newDates = Map<String, DateTime>.from(state.masteredDates);
    final newIds = Set<String>.from(state.masteredIds);
    for (final id in cardIds) {
      if (!newIds.contains(id)) {
        newIds.add(id);
        newDates[id] = now;
      }
    }
    state = state.copyWith(masteredIds: newIds, masteredDates: newDates);
    await _save();
    await _saveDates();
  }

  /// カードにメモを保存（空文字で削除）
  Future<void> setNote(String cardId, String note) async {
    final updated = Map<String, String>.from(state.notes);
    if (note.trim().isEmpty) {
      updated.remove(cardId);
    } else {
      updated[cardId] = note.trim();
    }
    state = state.copyWith(notes: updated);
    await _saveNotes();
  }

  /// 全リセット
  Future<void> resetAll() async {
    state = const FlashcardState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_notesKey);
    await prefs.remove(_datesKey);
  }
}

final flashcardProvider =
    StateNotifierProvider<FlashcardNotifier, FlashcardState>(
        (ref) => FlashcardNotifier());
