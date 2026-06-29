import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── タイムアタックベストスコア永続化 ─────────────────────────────────────────

class TimeAttackState {
  final int bestScore;      // 正解数 + タイムボーナスの合計（全難易度）
  final int bestCorrect;    // 正解数（全難易度）
  final int playCount;      // プレイ回数（累計）
  final int weekPlayCount;  // 今週のプレイ回数
  final int bestMaxCombo;   // 最高連続正解数
  // 難易度別: index 0=やさしい, 1=ふつう, 2=むずかしい
  final List<int> bestScoreByDifficulty;
  final List<int> bestCorrectByDifficulty;
  /// 直近10回のスコア（古い→新しい順）
  final List<int> recentScores;
  /// 最後に選択した難易度（0=やさしい 1=ふつう 2=むずかしい）
  final int selectedDifficulty;

  const TimeAttackState({
    this.bestScore = 0,
    this.bestCorrect = 0,
    this.playCount = 0,
    this.weekPlayCount = 0,
    this.bestMaxCombo = 0,
    this.bestScoreByDifficulty = const [0, 0, 0],
    this.bestCorrectByDifficulty = const [0, 0, 0],
    this.recentScores = const [],
    this.selectedDifficulty = 1,
  });

  TimeAttackState copyWith({
    int? bestScore,
    int? bestCorrect,
    int? playCount,
    int? weekPlayCount,
    int? bestMaxCombo,
    List<int>? bestScoreByDifficulty,
    List<int>? bestCorrectByDifficulty,
    List<int>? recentScores,
    int? selectedDifficulty,
  }) =>
      TimeAttackState(
        bestScore: bestScore ?? this.bestScore,
        bestCorrect: bestCorrect ?? this.bestCorrect,
        playCount: playCount ?? this.playCount,
        weekPlayCount: weekPlayCount ?? this.weekPlayCount,
        bestMaxCombo: bestMaxCombo ?? this.bestMaxCombo,
        bestScoreByDifficulty: bestScoreByDifficulty ?? this.bestScoreByDifficulty,
        bestCorrectByDifficulty: bestCorrectByDifficulty ?? this.bestCorrectByDifficulty,
        recentScores: recentScores ?? this.recentScores,
        selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      );

  /// 直近スコアのトレンド: 正 = 改善, 負 = 低下, 0 = データ不足
  int get scoreTrend {
    if (recentScores.length < 2) return 0;
    final half = recentScores.length ~/ 2;
    final older = recentScores.sublist(0, half);
    final newer = recentScores.sublist(half);
    final avgOlder = older.fold(0, (s, v) => s + v) / older.length;
    final avgNewer = newer.fold(0, (s, v) => s + v) / newer.length;
    if (avgNewer > avgOlder + 1) return 1;
    if (avgNewer < avgOlder - 1) return -1;
    return 0;
  }
}

class TimeAttackNotifier extends StateNotifier<TimeAttackState> {
  static const _keyBestScore          = 'ta_best_score';
  static const _keyBestCorrect        = 'ta_best_correct';
  static const _keyPlayCount          = 'ta_play_count';
  static const _keyWeekPlayCount      = 'ta_week_play_count';
  static const _keyWeekStart          = 'ta_week_start';
  static const _keyBestMaxCombo       = 'ta_best_max_combo';
  static const _keyRecentScores       = 'ta_recent_scores';
  static const _keySelectedDifficulty = 'ta_selected_difficulty';
  // 難易度別キー
  static const _keyBestScoreD0   = 'ta_best_score_d0';
  static const _keyBestScoreD1   = 'ta_best_score_d1';
  static const _keyBestScoreD2   = 'ta_best_score_d2';
  static const _keyBestCorrectD0 = 'ta_best_correct_d0';
  static const _keyBestCorrectD1 = 'ta_best_correct_d1';
  static const _keyBestCorrectD2 = 'ta_best_correct_d2';

  TimeAttackNotifier() : super(const TimeAttackState()) {
    _load();
  }

  /// 月曜始まりの週の月曜日（UTC日付文字列）を返す
  static String _currentWeekStartIso() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getString(_keyRecentScores);
    List<int> recent = [];
    if (recentJson != null) {
      try {
        recent = (json.decode(recentJson) as List).cast<int>();
      } catch (_) {
        recent = [];
      }
    }

    // 週次カウントのリセット判定
    final currentWeekStart = _currentWeekStartIso();
    final savedWeekStart = prefs.getString(_keyWeekStart) ?? '';
    int weekPlayCount;
    if (savedWeekStart == currentWeekStart) {
      weekPlayCount = prefs.getInt(_keyWeekPlayCount) ?? 0;
    } else {
      // 新しい週 → リセット
      weekPlayCount = 0;
      await prefs.setString(_keyWeekStart, currentWeekStart);
      await prefs.setInt(_keyWeekPlayCount, 0);
    }

    state = TimeAttackState(
      bestScore:     prefs.getInt(_keyBestScore)    ?? 0,
      bestCorrect:   prefs.getInt(_keyBestCorrect)  ?? 0,
      playCount:     prefs.getInt(_keyPlayCount)    ?? 0,
      weekPlayCount: weekPlayCount,
      bestMaxCombo:  prefs.getInt(_keyBestMaxCombo) ?? 0,
      bestScoreByDifficulty: [
        prefs.getInt(_keyBestScoreD0) ?? 0,
        prefs.getInt(_keyBestScoreD1) ?? 0,
        prefs.getInt(_keyBestScoreD2) ?? 0,
      ],
      bestCorrectByDifficulty: [
        prefs.getInt(_keyBestCorrectD0) ?? 0,
        prefs.getInt(_keyBestCorrectD1) ?? 0,
        prefs.getInt(_keyBestCorrectD2) ?? 0,
      ],
      recentScores: recent,
      selectedDifficulty: prefs.getInt(_keySelectedDifficulty) ?? 1,
    );
  }

  /// 1回のプレイ結果を記録。(新スコア記録, 新コンボ記録) のタプルを返す。
  Future<(bool isNewScore, bool isNewCombo)> recordResult({
    required int score,        // 正解数
    required int bonus,        // タイムボーナス合計
    int difficulty = 1,        // 0=やさしい 1=ふつう 2=むずかしい
    int maxCombo = 0,          // 最高連続正解数
  }) async {
    final total = score + bonus;
    final isNew = total > state.bestScore;
    final isNewCombo = maxCombo > 0 && maxCombo > state.bestMaxCombo;

    final prefs = await SharedPreferences.getInstance();
    final newCount = state.playCount + 1;

    // 週次カウントのリセット判定
    final currentWeekStart = _currentWeekStartIso();
    final savedWeekStart = prefs.getString(_keyWeekStart) ?? '';
    final newWeekPlayCount = (savedWeekStart == currentWeekStart
        ? (prefs.getInt(_keyWeekPlayCount) ?? 0)
        : 0) + 1;
    await prefs.setString(_keyWeekStart, currentWeekStart);
    await prefs.setInt(_keyWeekPlayCount, newWeekPlayCount);

    if (isNew) {
      await prefs.setInt(_keyBestScore,   total);
      await prefs.setInt(_keyBestCorrect, score);
    }
    await prefs.setInt(_keyPlayCount, newCount);

    // 最高コンボ更新
    final newMaxCombo = maxCombo > state.bestMaxCombo ? maxCombo : state.bestMaxCombo;
    if (isNewCombo) {
      await prefs.setInt(_keyBestMaxCombo, maxCombo);
    }

    // 直近スコア更新（最大10件）
    final newRecent = [...state.recentScores, total];
    final trimmedRecent = newRecent.length > 10
        ? newRecent.sublist(newRecent.length - 10)
        : newRecent;
    await prefs.setString(_keyRecentScores, json.encode(trimmedRecent));

    // 難易度別ベスト更新
    final newByScore   = List<int>.from(state.bestScoreByDifficulty);
    final newByCorrect = List<int>.from(state.bestCorrectByDifficulty);
    if (total > newByScore[difficulty]) {
      newByScore[difficulty] = total;
      newByCorrect[difficulty] = score;
      final scoreKeys   = [_keyBestScoreD0,   _keyBestScoreD1,   _keyBestScoreD2];
      final correctKeys = [_keyBestCorrectD0, _keyBestCorrectD1, _keyBestCorrectD2];
      await prefs.setInt(scoreKeys[difficulty],   total);
      await prefs.setInt(correctKeys[difficulty], score);
    }

    state = state.copyWith(
      bestScore:    isNew ? total : state.bestScore,
      bestCorrect:  isNew ? score : state.bestCorrect,
      playCount:    newCount,
      weekPlayCount: newWeekPlayCount,
      bestMaxCombo: newMaxCombo,
      bestScoreByDifficulty:   newByScore,
      bestCorrectByDifficulty: newByCorrect,
      recentScores: trimmedRecent,
    );

    return (isNew, isNewCombo);
  }

  /// 難易度選択を保存（ピッカー選択時に呼ぶ）
  Future<void> setDifficulty(int d) async {
    if (d < 0 || d > 2) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelectedDifficulty, d);
    state = state.copyWith(selectedDifficulty: d);
  }

  /// 全タイムアタックスコアをリセット
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _keyBestScore, _keyBestCorrect, _keyPlayCount,
      _keyWeekPlayCount, _keyWeekStart,
      _keyBestMaxCombo, _keyRecentScores, _keySelectedDifficulty,
      _keyBestScoreD0, _keyBestScoreD1, _keyBestScoreD2,
      _keyBestCorrectD0, _keyBestCorrectD1, _keyBestCorrectD2,
    ]) {
      await prefs.remove(key);
    }
    state = const TimeAttackState();
  }
}

final timeAttackProvider =
    StateNotifierProvider<TimeAttackNotifier, TimeAttackState>(
  (ref) => TimeAttackNotifier(),
);
