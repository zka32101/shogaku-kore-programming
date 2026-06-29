import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screens/quiz_result_screen.dart';

/// 間違えた問題を永続保存するプロバイダー
/// 最大 _kMaxItems 件まで保持し、古いものから上書きする。
/// timestamps は questionText → 追加日時のマップ。
/// wrongCounts は questionText → 累計間違い回数のマップ。
/// totalResolvedCount は累計克服数（markCorrect で 0 になった問題数）。

class WrongAnswersState {
  final List<QuizAnswer> answers;
  /// questionText → 間違えた日時（追加・更新時に記録）
  final Map<String, DateTime> timestamps;
  /// questionText → 累計間違い回数（正確な重要度順ソート用）
  final Map<String, int> wrongCounts;
  /// 累計克服数（markCorrect で完全除外された問題の累積数）
  final int totalResolvedCount;

  const WrongAnswersState({
    this.answers = const [],
    this.timestamps = const {},
    this.wrongCounts = const {},
    this.totalResolvedCount = 0,
  });

  WrongAnswersState copyWith({
    List<QuizAnswer>? answers,
    Map<String, DateTime>? timestamps,
    Map<String, int>? wrongCounts,
    int? totalResolvedCount,
  }) =>
      WrongAnswersState(
        answers: answers ?? this.answers,
        timestamps: timestamps ?? this.timestamps,
        wrongCounts: wrongCounts ?? this.wrongCounts,
        totalResolvedCount: totalResolvedCount ?? this.totalResolvedCount,
      );

  int get count => answers.length;
  bool get isEmpty => answers.isEmpty;

  /// 指定問題の追加日時を返す（存在しない場合は null）
  DateTime? timestampFor(String questionText) => timestamps[questionText];

  /// 指定問題の累計間違い回数を返す（記録がない場合は 0）
  int wrongCountFor(String questionText) => wrongCounts[questionText] ?? 0;

  /// 最も多く間違えた問題の回数
  int get maxWrongCount =>
      wrongCounts.isEmpty ? 0 : wrongCounts.values.reduce((a, b) => a > b ? a : b);
}

class WrongAnswersNotifier extends StateNotifier<WrongAnswersState> {
  WrongAnswersNotifier() : super(const WrongAnswersState()) {
    _load();
  }

  static const _key = 'wrong_answers_v1';
  static const _tsKey = 'wrong_answers_timestamps_v1';
  static const _countsKey = 'wrong_answers_counts_v1';
  static const _resolvedCountKey = 'wrong_answers_resolved_count_v1';
  static const _kMaxItems = 30;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final rawTs = prefs.getString(_tsKey);
    final rawCounts = prefs.getString(_countsKey);
    final resolvedCount = prefs.getInt(_resolvedCountKey) ?? 0;
    if (raw == null) {
      state = state.copyWith(totalResolvedCount: resolvedCount);
      return;
    }
    try {
      final list = (json.decode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(_fromMap)
          .toList();
      Map<String, DateTime> timestamps = {};
      if (rawTs != null) {
        final tsMap = json.decode(rawTs) as Map<String, dynamic>;
        timestamps = tsMap.map(
          (k, v) => MapEntry(k, DateTime.tryParse(v as String) ?? DateTime.now()),
        );
      }
      Map<String, int> counts = {};
      if (rawCounts != null) {
        final cMap = json.decode(rawCounts) as Map<String, dynamic>;
        counts = cMap.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
      state = state.copyWith(
        answers: list,
        timestamps: timestamps,
        wrongCounts: counts,
        totalResolvedCount: resolvedCount,
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.answers.map(_toMap).toList();
    await prefs.setString(_key, json.encode(data));
    final tsData = state.timestamps.map((k, v) => MapEntry(k, v.toIso8601String()));
    await prefs.setString(_tsKey, json.encode(tsData));
    await prefs.setString(_countsKey, json.encode(state.wrongCounts));
    await prefs.setInt(_resolvedCountKey, state.totalResolvedCount);
  }

  /// セッション終了時に間違い問題を追加（重複は questionText で判定）
  Future<void> addWrongAnswers(List<QuizAnswer> newWrong) async {
    if (newWrong.isEmpty) return;
    final existing = List<QuizAnswer>.from(state.answers);
    final timestamps = Map<String, DateTime>.from(state.timestamps);
    final counts = Map<String, int>.from(state.wrongCounts);
    final now = DateTime.now();
    for (final a in newWrong) {
      // 同じ問題文がある場合は更新
      existing.removeWhere((e) => e.questionText == a.questionText);
      existing.insert(0, a); // 新しいものを先頭に追加
      timestamps[a.questionText] = now; // 追加/更新日時を記録
      counts[a.questionText] = (counts[a.questionText] ?? 0) + 1; // 間違い回数をインクリメント
    }
    // 上限超え分を削除（古いもの=末尾を削除）
    final trimmed = existing.take(_kMaxItems).toList();
    // タイムスタンプ・カウントも同期（trimmed に含まれないものを除外）
    final activeKeys = trimmed.map((a) => a.questionText).toSet();
    timestamps.removeWhere((k, _) => !activeKeys.contains(k));
    counts.removeWhere((k, _) => !activeKeys.contains(k));
    state = state.copyWith(answers: trimmed, timestamps: timestamps, wrongCounts: counts);
    await _save();
  }

  /// 正解時に呼び出す: 累計間違い回数を 1 減らし、0 になれば苦手リストから除外する。
  /// 完全除外された場合は totalResolvedCount を 1 増やし、true を返す。
  /// 苦手リストにない問題やカウント減少のみの場合は false を返す。
  Future<bool> markCorrect(String questionText) async {
    final counts = Map<String, int>.from(state.wrongCounts);
    final current = counts[questionText] ?? 0;
    if (current <= 0) return false; // 苦手リストにない問題は何もしない
    if (current <= 1) {
      // カウントが 0 になる → リストから完全除外 + 克服カウントを増やす
      final updated = state.answers
          .where((a) => a.questionText != questionText)
          .toList();
      final timestamps = Map<String, DateTime>.from(state.timestamps)
        ..remove(questionText);
      counts.remove(questionText);
      state = state.copyWith(
        answers: updated,
        timestamps: timestamps,
        wrongCounts: counts,
        totalResolvedCount: state.totalResolvedCount + 1,
      );
      await _save();
      return true; // 完全克服
    } else {
      counts[questionText] = current - 1;
      state = state.copyWith(wrongCounts: counts);
      await _save();
      return false; // カウント減少のみ
    }
  }

  Future<void> removeAnswer(String questionText) async {
    final updated = state.answers
        .where((a) => a.questionText != questionText)
        .toList();
    final timestamps = Map<String, DateTime>.from(state.timestamps)
      ..remove(questionText);
    final counts = Map<String, int>.from(state.wrongCounts)
      ..remove(questionText);
    state = state.copyWith(answers: updated, timestamps: timestamps, wrongCounts: counts);
    await _save();
  }

  /// 復習画面の「解決した」ボタン用: 苦手リストから削除し totalResolvedCount を増やす。
  /// removeAnswer と異なり、克服カウントも更新する。
  Future<void> resolveAnswer(String questionText) async {
    if (!state.wrongCounts.containsKey(questionText) &&
        !state.answers.any((a) => a.questionText == questionText)) {
      return;
    }
    final updated = state.answers
        .where((a) => a.questionText != questionText)
        .toList();
    final timestamps = Map<String, DateTime>.from(state.timestamps)
      ..remove(questionText);
    final counts = Map<String, int>.from(state.wrongCounts)
      ..remove(questionText);
    state = state.copyWith(
      answers: updated,
      timestamps: timestamps,
      wrongCounts: counts,
      totalResolvedCount: state.totalResolvedCount + 1,
    );
    await _save();
  }

  Future<void> clearAll() async {
    state = WrongAnswersState(totalResolvedCount: state.totalResolvedCount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_tsKey);
    await prefs.remove(_countsKey);
    // _resolvedCountKey は clearAll でも保持する（累計克服数はリセットしない）
  }

  // ─── シリアライズ ────────────────────────────────────────────────────────

  static Map<String, dynamic> _toMap(QuizAnswer a) => {
        'questionText': a.questionText,
        'isCorrect': a.isCorrect,
        'selectedAnswer': a.selectedAnswer,
        'correctAnswer': a.correctAnswer,
        'explanation': a.explanation,
        'codeSnippet': a.codeSnippet,
        'hintUsed': a.hintUsed,
      };

  static QuizAnswer _fromMap(Map<String, dynamic> m) => QuizAnswer(
        questionText: m['questionText'] as String,
        isCorrect: m['isCorrect'] as bool? ?? false,
        selectedAnswer: m['selectedAnswer'] as String? ?? '',
        correctAnswer: m['correctAnswer'] as String? ?? '',
        explanation: m['explanation'] as String? ?? '',
        codeSnippet: m['codeSnippet'] as String?,
        hintUsed: m['hintUsed'] as bool? ?? false,
      );
}

final wrongAnswersProvider =
    StateNotifierProvider<WrongAnswersNotifier, WrongAnswersState>(
        (ref) => WrongAnswersNotifier());
