import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/challenge.dart';
import '../services/notification_service.dart';

class ProgressNotifier extends StateNotifier<Map<String, UserProgress>> {
  ProgressNotifier() : super({}) {
    _loadProgress();
  }

  static const String _storageKey = 'user_progress';
  static const String _streakKey = 'streak_count';
  static const String _lastActiveDateKey = 'last_active_date';
  static const String _bonusKey = 'bonus_points';
  static const String _totalQuestionsKey = 'total_questions_answered';
  static const String _longestStreakKey = 'longest_streak';
  static const String _totalLearningSecondsKey = 'total_learning_seconds';
  static const String _weeklyChallengeBonusKey = 'weekly_challenge_bonus_week';
  static const String _homeWeeklyBonusKey = 'home_weekly_bonus_week';
  static const String _codeKingShownKey = 'code_king_badge_shown';
  static const String _comebackBonusDateKey = 'comeback_bonus_date';
  static const String _dailyGoalShownKey = 'daily_goal_shown_date';
  static const String _lastShownStreakMilestoneKey = 'last_shown_streak_milestone';
  static const String _perfectRunsKey = 'perfect_runs_count';
  static const String _activityLogKey = 'activity_log_v2'; // 日付別アクティビティ（全モード合算）

  int _streakDays = 0;
  int _longestStreak = 0;
  DateTime? _lastActiveDate;
  int _bonusPoints = 0;
  int _totalQuestionsAnswered = 0;
  int _totalLearningSeconds = 0;
  int _perfectRuns = 0; // 全問正解でクリアした累計回数
  Map<String, int> _activityLog = {}; // ISO日付文字列 → その日のアクティビティ合算数
  int _comebackDays = 0; // 前回プレイからの日数（2以上 = カムバック）
  String? _weeklyChallengeBonusWeek; // 週次チャレンジボーナスを付与した週（月曜ISO日付）
  String? _homeWeeklyBonusWeek; // ホーム週次チャレンジボーナスを付与した週
  DateTime? _comebackBonusDate; // カムバックボーナスを付与した日
  bool _comebackBonusAwardedToday = false; // 今日カムバックボーナスを付与したか
  bool _codeKingBadgeShown = false; // コード王バッジを一度でも表示したか
  String? _dailyGoalShownDate; // 今日の目標達成バッジを表示した日（重複防止）
  int _lastShownStreakMilestone = 0; // 最後に表示したストリークマイルストーン（重複防止）
  bool _isLoaded = false; // _loadProgress 完了フラグ（初回ロード完了を検出するため）

  int get streakDays => _streakDays;
  int get longestStreak => _longestStreak;
  int get bonusPoints => _bonusPoints;
  int get totalQuestionsAnswered => _totalQuestionsAnswered;
  int get totalLearningSeconds => _totalLearningSeconds;
  int get comebackDays => _comebackDays;
  bool get comebackBonusAwardedToday => _comebackBonusAwardedToday;
  bool get codeKingBadgeShown => _codeKingBadgeShown;
  int get lastShownStreakMilestone => _lastShownStreakMilestone;
  bool get isLoaded => _isLoaded;
  int get totalPerfectRuns => _perfectRuns;

  /// 今日の目標達成バッジをすでに表示済みか（重複防止）
  bool get isDailyGoalShownToday {
    final today = _dateOnly(DateTime.now()).toIso8601String().substring(0, 10);
    return _dailyGoalShownDate == today;
  }

  /// 今日の目標達成バッジを表示済みとしてマーク
  void markDailyGoalShownToday() {
    final today = _dateOnly(DateTime.now()).toIso8601String().substring(0, 10);
    if (_dailyGoalShownDate == today) return;
    _dailyGoalShownDate = today;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_dailyGoalShownKey, today);
    });
  }

  /// 指定ストリークマイルストーンのバッジを表示済みとしてマーク（再表示防止）
  void markStreakMilestoneShown(int milestone) {
    if (_lastShownStreakMilestone >= milestone) return;
    _lastShownStreakMilestone = milestone;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_lastShownStreakMilestoneKey, milestone);
    });
  }

  /// 今週の週次チャレンジボーナスが付与済みかどうか
  bool get isWeeklyChallengeBonusAwardedThisWeek {
    return _weeklyChallengeBonusWeek == _currentWeekIso();
  }

  /// 月曜始まりの現在週の月曜日 ISO 文字列
  static String _currentWeekIso() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  /// ホーム週次チャレンジボーナスが今週付与済みかどうか
  bool get isHomeWeeklyBonusAwardedThisWeek {
    return _homeWeeklyBonusWeek == _currentWeekIso();
  }

  /// ホーム週次チャレンジボーナス（20pt）を今週1回だけ付与する（同期的にフラグ設定）
  bool awardHomeWeeklyBonus() {
    final currentWeek = _currentWeekIso();
    if (_homeWeeklyBonusWeek == currentWeek) return false;
    _homeWeeklyBonusWeek = currentWeek;
    // 非同期で永続化＋ポイント付与
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_homeWeeklyBonusKey, currentWeek);
    });
    addBonusPoints(20);
    return true;
  }

  /// 週次チャレンジ全達成ボーナス（100pt）を今週1回だけ付与する
  Future<bool> awardWeeklyChallengeBonus() async {
    final currentWeek = _currentWeekIso();
    if (_weeklyChallengeBonusWeek == currentWeek) return false; // 今週付与済み
    _weeklyChallengeBonusWeek = currentWeek;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyChallengeBonusKey, currentWeek);
    await addBonusPoints(100);
    return true;
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // 進捗データ
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final decoded = json.decode(data) as Map<String, dynamic>;
      final progress = decoded.map((key, value) {
        final v = value as Map<String, dynamic>;
        return MapEntry(
          key,
          UserProgress(
            challengeId: key,
            isCompleted: v['isCompleted'] as bool? ?? false,
            starsEarned: v['starsEarned'] as int? ?? 0,
            completedAt: v['completedAt'] != null
                ? DateTime.parse(v['completedAt'] as String)
                : null,
          ),
        );
      });
      state = progress;
    }

    // ボーナスポイント
    _bonusPoints = prefs.getInt(_bonusKey) ?? 0;

    // 累計回答数
    _totalQuestionsAnswered = prefs.getInt(_totalQuestionsKey) ?? 0;

    // 累計学習時間
    _totalLearningSeconds = prefs.getInt(_totalLearningSecondsKey) ?? 0;

    // 全問正解クリア累計回数
    _perfectRuns = prefs.getInt(_perfectRunsKey) ?? 0;

    // 日別アクティビティログ（全モード合算）
    final activityJson = prefs.getString(_activityLogKey);
    if (activityJson != null) {
      try {
        final decoded = json.decode(activityJson) as Map<String, dynamic>;
        _activityLog = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }

    // 週次チャレンジボーナス付与済み週
    _weeklyChallengeBonusWeek = prefs.getString(_weeklyChallengeBonusKey);
    _homeWeeklyBonusWeek = prefs.getString(_homeWeeklyBonusKey);

    // コード王バッジ表示済みフラグ
    _codeKingBadgeShown = prefs.getBool(_codeKingShownKey) ?? false;

    // 今日の目標達成バッジ表示済み日
    _dailyGoalShownDate = prefs.getString(_dailyGoalShownKey);

    // カムバックボーナス付与済み日
    final comebackBonusStr = prefs.getString(_comebackBonusDateKey);
    _comebackBonusDate = comebackBonusStr != null ? DateTime.tryParse(comebackBonusStr) : null;

    // ストリーク
    _streakDays = prefs.getInt(_streakKey) ?? 0;
    _longestStreak = prefs.getInt(_longestStreakKey) ?? _streakDays;
    final lastDateStr = prefs.getString(_lastActiveDateKey);
    _lastActiveDate =
        lastDateStr != null ? DateTime.tryParse(lastDateStr) : null;
    _lastShownStreakMilestone = prefs.getInt(_lastShownStreakMilestoneKey) ?? 0;

    // 起動時にストリーク更新
    await _updateStreakOnOpen(prefs);

    // ロード完了後に1回だけ state を更新し、UI に最新ストリーク等を反映させる
    _isLoaded = true;
    state = {...state};
  }

  Future<void> _updateStreakOnOpen(SharedPreferences prefs) async {
    final today = _dateOnly(DateTime.now());

    if (_lastActiveDate == null) {
      // 初回起動 → ストリーク1日目
      _streakDays = 1;
    } else {
      final last = _dateOnly(_lastActiveDate!);
      final diff = today.difference(last).inDays;

      if (diff == 0) {
        // 今日すでに開いている → カムバックバナーは今日1回だけ表示すればよい
        // （前回起動が別の日だったなら comebackDays は既に設定済み。同日再起動ではクリアしない）
        return;
      } else if (diff == 1) {
        // 連続プレイ中はカムバック日数をリセット
        _comebackDays = 0;
        // 昨日も開いていた → ストリーク継続
        _streakDays++;
      } else {
        // 2日以上空いた → ストリークリセット
        _streakDays = 1;
        _comebackDays = diff; // カムバック日数を記録

        // カムバックボーナス付与（今日まだ付与していない場合）
        if (_comebackBonusDate == null || _dateOnly(_comebackBonusDate!) != today) {
          _comebackBonusDate = today;
          _comebackBonusAwardedToday = true;
          await prefs.setString(_comebackBonusDateKey, today.toIso8601String());
          // ボーナスポイント付与（最大30pt: 不在日数×5、上限30）
          final bonusPts = (diff * 5).clamp(5, 30);
          _bonusPoints += bonusPts;
          await prefs.setInt(_bonusKey, _bonusPoints);
          state = {...state};
        }
      }
    }

    _lastActiveDate = today;
    // 最長ストリーク更新
    if (_streakDays > _longestStreak) {
      _longestStreak = _streakDays;
      await prefs.setInt(_longestStreakKey, _longestStreak);
    }
    await prefs.setInt(_streakKey, _streakDays);
    await prefs.setString(_lastActiveDateKey, today.toIso8601String());

    // ストリーク節目通知（7・14・30・60・100日）
    const milestones = [7, 14, 30, 60, 100];
    if (milestones.contains(_streakDays)) {
      await NotificationService().sendStreakMilestone(_streakDays);
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((key, value) => MapEntry(key, {
          'isCompleted': value.isCompleted,
          'starsEarned': value.starsEarned,
          'completedAt': value.completedAt?.toIso8601String(),
        }));
    await prefs.setString(_storageKey, json.encode(data));
  }

  Future<void> completeChallenge(String challengeId, int stars) async {
    // 再挑戦でスターが下がっても以前のベストを保持する
    final bestStars = (state[challengeId]?.starsEarned ?? 0);
    state = {
      ...state,
      challengeId: UserProgress(
        challengeId: challengeId,
        isCompleted: true,
        starsEarned: stars > bestStars ? stars : bestStars,
        completedAt: DateTime.now(),
      ),
    };
    await _saveProgress();
  }

  UserProgress getProgress(String challengeId) {
    return state[challengeId] ?? UserProgress(challengeId: challengeId);
  }

  Future<void> resetAll() async {
    state = {};
    _streakDays = 0;
    _longestStreak = 0;
    _lastActiveDate = null;
    _bonusPoints = 0;
    _totalQuestionsAnswered = 0;
    _totalLearningSeconds = 0;
    _comebackDays = 0;
    _weeklyChallengeBonusWeek = null;
    _homeWeeklyBonusWeek = null;
    _comebackBonusDate = null;
    _comebackBonusAwardedToday = false;
    _codeKingBadgeShown = false;
    _dailyGoalShownDate = null;
    _lastShownStreakMilestone = 0;
    _activityLog = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_streakKey);
    await prefs.remove(_lastActiveDateKey);
    await prefs.remove(_bonusKey);
    await prefs.remove(_totalQuestionsKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_totalLearningSecondsKey);
    await prefs.remove(_weeklyChallengeBonusKey);
    await prefs.remove(_homeWeeklyBonusKey);
    await prefs.remove(_comebackBonusDateKey);
    await prefs.remove(_codeKingShownKey);
    await prefs.remove(_dailyGoalShownKey);
    await prefs.remove(_lastShownStreakMilestoneKey);
    await prefs.remove(_activityLogKey);
  }

  /// コード王バッジを表示済みとしてマーク
  Future<void> markCodeKingShown() async {
    if (_codeKingBadgeShown) return;
    _codeKingBadgeShown = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_codeKingShownKey, true);
    state = {...state};
  }

  int get totalStarsEarned {
    final base = state.values.fold(0, (sum, p) => sum + p.starsEarned);
    return base + _bonusPoints;
  }

  Future<void> recordQuestionsAnswered(int count) async {
    if (count <= 0) return;
    _totalQuestionsAnswered += count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalQuestionsKey, _totalQuestionsAnswered);
    state = {...state};
  }

  /// 全問正解クリア（パーフェクトラン）を記録する
  Future<void> recordPerfectRun() async {
    _perfectRuns++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_perfectRunsKey, _perfectRuns);
    state = {...state};
  }

  /// 今日のアクティビティを記録する（クイズ以外のモード：復習・タイムアタック等）
  /// カレンダーヒートマップに反映させるために呼び出す。
  Future<void> recordActivity({int count = 1}) async {
    final today = _dateOnly(DateTime.now()).toIso8601String().substring(0, 10);
    _activityLog[today] = (_activityLog[today] ?? 0) + count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activityLogKey, json.encode(_activityLog));
    state = {...state};
  }

  /// 学習時間を記録する。マイルストーン達成時は (icon, name, message, nextGoal) を返す。
  Future<(String, String, String, String)?> recordLearningSeconds(int seconds) async {
    if (seconds <= 0) return null;
    final beforeMinutes = _totalLearningSeconds ~/ 60;
    _totalLearningSeconds += seconds;
    final afterMinutes = _totalLearningSeconds ~/ 60;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalLearningSecondsKey, _totalLearningSeconds);
    state = {...state};

    // 学習時間マイルストーン判定
    const milestones = [
      (10,  '⏱',  '10分学習！',   '累計10分学習達成！これからが楽しい！',   '30分学習を目指そう！'),
      (30,  '⏰',  '30分学習！',   '累計30分学習達成！継続は力なり！',       '1時間学習を目指そう！'),
      (60,  '🕐',  '1時間学習！',  '累計1時間学習達成！本気の学習者！',      '2時間学習を目指そう！'),
      (120, '🕑',  '2時間学習！',  '累計2時間学習達成！集中力がすごい！',    '3時間学習を目指そう！'),
      (180, '🕒',  '3時間学習！',  '累計3時間学習達成！素晴らしい集中力！',  '10時間学習を目指そう！'),
      (600, '🏆',  '10時間学習！', '累計10時間学習達成！あなたは本気のコーダー！', 'このまま続けよう！'),
    ];
    for (final (mins, icon, name, msg, nextGoal) in milestones) {
      if (beforeMinutes < mins && afterMinutes >= mins) {
        return (icon, name, msg, nextGoal);
      }
    }
    return null;
  }

  Future<void> addBonusPoints(int points) async {
    _bonusPoints += points;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bonusKey, _bonusPoints);
    // 状態変化を通知（stateを触ってリビルドを促す）
    state = {...state};
  }

  int get completedCount {
    return state.values.where((p) => p.isCompleted).length;
  }

  // レベル閾値: 40ステージ×3★=120★満点、Lv.20 が最大
  // (閾値, レベル) のリスト — 降順で最初にマッチしたものを採用
  static const List<(int, int)> _levelThresholds = [
    (115, 20),
    (105, 18),
    (90,  15),
    (75,  12),
    (60,  10),
    (45,   8),
    (30,   6),
    (20,   5),
    (12,   4),
    (6,    3),
    (2,    2),
  ];

  int get currentLevel {
    final stars = totalStarsEarned;
    for (final (threshold, level) in _levelThresholds) {
      if (stars >= threshold) return level;
    }
    return 1;
  }

  /// 次のレベルに必要な残りスター数（最大レベル時は 0）
  int get starsToNextLevel {
    final stars = totalStarsEarned;
    if (stars >= 115) return 0; // Lv.20 = max
    for (int i = 0; i < _levelThresholds.length - 1; i++) {
      final (current, _) = _levelThresholds[i];
      final (prev, _) = _levelThresholds[i + 1];
      if (stars >= prev && stars < current) return current - stars;
    }
    return 2 - stars; // Lv.1 → Lv.2 requires 2 stars
  }

  /// 現在レベルの開始スター〜次レベルまでの進捗率 (0.0–1.0)
  double get levelProgress {
    final stars = totalStarsEarned;
    if (stars >= 115) return 1.0;
    for (int i = 0; i < _levelThresholds.length - 1; i++) {
      final (current, _) = _levelThresholds[i];
      final (prev, _) = _levelThresholds[i + 1];
      if (stars >= prev && stars < current) {
        return (stars - prev) / (current - prev);
      }
    }
    return (stars / 2).clamp(0.0, 1.0);
  }

  /// 3つ星クリアしたステージ数
  int get perfectStagesCount {
    return state.values.where((p) => p.isCompleted && p.starsEarned >= 3).length;
  }

  /// 今日クリアしたステージ数
  int get todayClearedCount {
    final today = _dateOnly(DateTime.now());
    return state.values
        .where((p) =>
            p.isCompleted &&
            p.completedAt != null &&
            _dateOnly(p.completedAt!) == today)
        .length;
  }

  /// 過去 N 週間の週ごとクリア数リスト（グラフ表示用）
  /// index 0 = 最古の週, index N-1 = 今週
  List<int> weeklyActivity({int weeks = 4}) {
    final today = _dateOnly(DateTime.now());
    final startOfThisWeek = today.subtract(Duration(days: (today.weekday - 1) % 7));
    return List.generate(weeks, (i) {
      final weekStart = startOfThisWeek.subtract(Duration(days: (weeks - 1 - i) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return state.values.where((p) {
        if (!p.isCompleted || p.completedAt == null) return false;
        final d = _dateOnly(p.completedAt!);
        return !d.isBefore(weekStart) && d.isBefore(weekEnd);
      }).length;
    });
  }

  /// 日付 → その日のアクティビティ合算マップ（カレンダー表示用）
  /// クイズステージ完了数 + 全モードの追加アクティビティを合算する。
  Map<DateTime, int> get activityByDate {
    final map = <DateTime, int>{};
    // ステージ完了をカウント
    for (final p in state.values) {
      if (p.isCompleted && p.completedAt != null) {
        final d = _dateOnly(p.completedAt!);
        map[d] = (map[d] ?? 0) + 1;
      }
    }
    // 復習・タイムアタック等のアクティビティを追加
    for (final entry in _activityLog.entries) {
      final d = DateTime.tryParse(entry.key);
      if (d == null) continue;
      map[d] = (map[d] ?? 0) + entry.value;
    }
    return map;
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Map<String, UserProgress>>(
        (ref) => ProgressNotifier());
