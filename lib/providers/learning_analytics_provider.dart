import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/learning_analytics.dart';

/// 学習分析の状態
class LearningAnalyticsState {
  final List<DailyLearningStats> dailyStats; // 日単位の統計履歴
  final OverallLearningProgress progress; // 総合進捗
  final DateTime? lastUpdatedAt; // 最終更新日時
  final int currentStreak; // 現在の連続学習日数
  final int longestStreak; // 最長連続学習日数

  const LearningAnalyticsState({
    this.dailyStats = const [],
    required this.progress,
    this.lastUpdatedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  /// コピーメソッド
  LearningAnalyticsState copyWith({
    List<DailyLearningStats>? dailyStats,
    OverallLearningProgress? progress,
    DateTime? lastUpdatedAt,
    int? currentStreak,
    int? longestStreak,
  }) =>
      LearningAnalyticsState(
        dailyStats: dailyStats ?? this.dailyStats,
        progress: progress ?? this.progress,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
      );

  @override
  String toString() =>
      'LearningAnalyticsState(Days tracked: ${dailyStats.length}, Accuracy: ${progress.overallAccuracy.toStringAsFixed(1)}%)';
}

/// 学習分析管理プロバイダ
class LearningAnalyticsNotifier extends StateNotifier<LearningAnalyticsState> {
  LearningAnalyticsNotifier()
      : super(
          LearningAnalyticsState(
            progress: OverallLearningProgress(
              totalQuizzesCompleted: 0,
              totalQuizzesCorrect: 0,
              totalTimeSpent: const Duration(),
              overallAccuracy: 0.0,
              longestStreak: 0,
              currentStreak: 0,
              totalDaysLearned: 0,
            ),
          ),
        ) {
    _initializeAnalyticsData();
  }

  static const String _dailyStatsKey = 'learning_daily_stats';
  static const String _progressKey = 'learning_progress';
  static const String _streakKey = 'learning_streak';
  static const String _longestStreakKey = 'learning_longest_streak';
  static const String _lastUpdatedKey = 'learning_last_updated';

  /// 学習分析データの初期化
  Future<void> _initializeAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();

    // 保存されたデータを読み込む
    final savedDailyStats = prefs.getStringList(_dailyStatsKey) ?? [];
    final savedProgress = prefs.getString(_progressKey);
    final currentStreak = prefs.getInt(_streakKey) ?? 0;
    final longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    final lastUpdatedStr = prefs.getString(_lastUpdatedKey);

    // データを復元
    List<DailyLearningStats> dailyStats = [];
    OverallLearningProgress progress = OverallLearningProgress(
      totalQuizzesCompleted: 0,
      totalQuizzesCorrect: 0,
      totalTimeSpent: const Duration(),
      overallAccuracy: 0.0,
      longestStreak: longestStreak,
      currentStreak: currentStreak,
      totalDaysLearned: 0,
    );

    if (savedDailyStats.isNotEmpty) {
      dailyStats = savedDailyStats
          .map((json) => DailyLearningStats.fromJson(
            Map<String, dynamic>.from(
              Map.from(Uri.parse('?$json').queryParameters)
                  .map((k, v) => MapEntry(k, v)),
            ),
          ))
          .toList();
    }

    if (savedProgress != null) {
      progress = OverallLearningProgress.fromJson(
        Map<String, dynamic>.from(
          Map.from(Uri.parse('?$savedProgress').queryParameters)
              .map((k, v) => MapEntry(k, v)),
        ),
      );
    }

    state = LearningAnalyticsState(
      dailyStats: dailyStats,
      progress: progress,
      lastUpdatedAt:
          lastUpdatedStr != null ? DateTime.parse(lastUpdatedStr) : null,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  /// クイズ完了時に統計を更新
  Future<void> recordQuizCompletion({
    required int correctCount,
    required int totalCount,
    required Duration timeSpent,
    required LearningCategory category,
    required int xpGained,
    required int coinsGained,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 今日のデータを取得または作成
    var todayStats = _getTodayStats();
    final accuracy = totalCount > 0 ? (correctCount / totalCount * 100) : 0.0;

    todayStats = DailyLearningStats(
      date: now,
      quizzesCompleted: todayStats.quizzesCompleted + totalCount,
      quizzesCorrect: todayStats.quizzesCorrect + correctCount,
      lessonsCompleted: todayStats.lessonsCompleted,
      timeSpent: todayStats.timeSpent + timeSpent,
      accuracyPercentage: (todayStats.quizzesCompleted + totalCount) > 0
          ? ((todayStats.quizzesCorrect + correctCount) /
                  (todayStats.quizzesCompleted + totalCount) *
                  100)
              .clamp(0.0, 100.0)
          : 0.0,
      xpGained: todayStats.xpGained + xpGained,
      coinsGained: todayStats.coinsGained + coinsGained,
      categoryStats: _updateCategoryStats(todayStats.categoryStats, category, totalCount),
    );

    // 日単位の統計を更新
    final updatedDailyStats = List<DailyLearningStats>.from(state.dailyStats);
    final todayIndex = updatedDailyStats
        .indexWhere((s) => s.isToday);
    if (todayIndex >= 0) {
      updatedDailyStats[todayIndex] = todayStats;
    } else {
      updatedDailyStats.add(todayStats);
    }

    // 総合進捗を更新
    final newProgress = _calculateOverallProgress(updatedDailyStats);

    // ストリークを更新
    final newCurrentStreak = _calculateCurrentStreak(updatedDailyStats);
    final newLongestStreak = _calculateLongestStreak(newCurrentStreak, state.longestStreak);

    state = state.copyWith(
      dailyStats: updatedDailyStats,
      progress: newProgress.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
      ),
      lastUpdatedAt: DateTime.now(),
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
    );

    // SharedPreferencesに保存
    await _saveLearningAnalytics(prefs, updatedDailyStats, newProgress, newCurrentStreak, newLongestStreak);
  }

  /// 今日の統計を取得
  DailyLearningStats _getTodayStats() {
    final today = DateTime.now();
    try {
      return state.dailyStats.firstWhere(
        (s) => s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day,
      );
    } catch (e) {
      return DailyLearningStats(
        date: today,
        quizzesCompleted: 0,
        quizzesCorrect: 0,
        lessonsCompleted: 0,
        timeSpent: const Duration(),
        accuracyPercentage: 0.0,
        xpGained: 0,
        coinsGained: 0,
        categoryStats: {},
      );
    }
  }

  /// カテゴリ統計を更新
  Map<LearningCategory, int> _updateCategoryStats(
    Map<LearningCategory, int> current,
    LearningCategory category,
    int count,
  ) {
    final updated = Map<LearningCategory, int>.from(current);
    updated[category] = (updated[category] ?? 0) + count;
    return updated;
  }

  /// 総合進捗を計算
  OverallLearningProgress _calculateOverallProgress(
    List<DailyLearningStats> dailyStats,
  ) {
    int totalCompleted = 0;
    int totalCorrect = 0;
    Duration totalTime = const Duration();
    final categoryMap = <LearningCategory, int>{};
    int daysLearned = 0;

    for (final stats in dailyStats) {
      totalCompleted += stats.quizzesCompleted;
      totalCorrect += stats.quizzesCorrect;
      totalTime += stats.timeSpent;
      daysLearned++;

      stats.categoryStats.forEach((category, count) {
        categoryMap[category] = (categoryMap[category] ?? 0) + count;
      });
    }

    final accuracy = totalCompleted > 0
        ? (totalCorrect / totalCompleted * 100).clamp(0.0, 100.0)
        : 0.0;

    return OverallLearningProgress(
      totalQuizzesCompleted: totalCompleted,
      totalQuizzesCorrect: totalCorrect,
      totalTimeSpent: totalTime,
      overallAccuracy: accuracy,
      longestStreak: state.progress.longestStreak,
      currentStreak: state.currentStreak,
      lastStudyDate: dailyStats.isEmpty ? null : dailyStats.last.date,
      totalDaysLearned: daysLearned,
      categoryStats: categoryMap,
    );
  }

  /// 現在のストリークを計算
  int _calculateCurrentStreak(List<DailyLearningStats> dailyStats) {
    if (dailyStats.isEmpty) return 0;

    int streak = 0;
    final sorted = dailyStats..sort((a, b) => b.date.compareTo(a.date));

    final today = DateTime.now();
    var checkDate = DateTime(today.year, today.month, today.day);

    for (final stats in sorted) {
      final statsDate = DateTime(stats.date.year, stats.date.month, stats.date.day);

      if (statsDate.difference(checkDate).inDays == 0 && stats.quizzesCompleted > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// 最長ストリークを計算
  int _calculateLongestStreak(int currentStreak, int previousLongest) {
    return currentStreak > previousLongest ? currentStreak : previousLongest;
  }

  /// SharedPreferencesにデータを保存
  Future<void> _saveLearningAnalytics(
    SharedPreferences prefs,
    List<DailyLearningStats> dailyStats,
    OverallLearningProgress progress,
    int currentStreak,
    int longestStreak,
  ) async {
    // 日単位の統計を保存（最新100日のみ保持）
    final recentStats = dailyStats.length > 100
        ? dailyStats.sublist(dailyStats.length - 100)
        : dailyStats;

    await prefs.setStringList(
      _dailyStatsKey,
      recentStats.map((s) => s.toJson().toString()).toList(),
    );

    // 総合進捗を保存
    await prefs.setString(_progressKey, progress.toJson().toString());

    // ストリーク情報を保存
    await prefs.setInt(_streakKey, currentStreak);
    await prefs.setInt(_longestStreakKey, longestStreak);
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  /// 指定期間の統計を取得
  List<DailyLearningStats> getStatsForDateRange(DateTime start, DateTime end) {
    return state.dailyStats
        .where((stats) =>
            stats.date.isAfter(start.subtract(const Duration(days: 1))) &&
            stats.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  /// 週単位の統計を取得
  WeeklyLearningStats getWeeklyStats(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final weeklyData = getStatsForDateRange(monday, sunday);

    // 7日分のデータを確保（欠けている日は0のデータで埋める）
    final fullWeek = <DailyLearningStats>[];
    for (int i = 0; i < 7; i++) {
      final checkDate = monday.add(Duration(days: i));
      final existingData = weeklyData.firstWhere(
        (s) => s.date.year == checkDate.year &&
            s.date.month == checkDate.month &&
            s.date.day == checkDate.day,
        orElse: () => DailyLearningStats(date: checkDate),
      );
      fullWeek.add(existingData);
    }

    return WeeklyLearningStats(startDate: monday, dailyStats: fullWeek);
  }

  /// 月単位の統計を取得
  MonthlyLearningStats getMonthlyStats(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final monthlyData = getStatsForDateRange(firstDay, lastDay);

    // 週単位で分割
    final weeks = <WeeklyLearningStats>[];
    var currentWeekStart = firstDay;

    while (currentWeekStart.month == month) {
      final weekEnd = currentWeekStart.add(const Duration(days: 6));
      final weekLastDay = weekEnd.month == month ? weekEnd : lastDay;

      final weekData = monthlyData
          .where((s) =>
              s.date.isAfter(
                currentWeekStart.subtract(const Duration(days: 1)),
              ) &&
              s.date.isBefore(weekLastDay.add(const Duration(days: 1))))
          .toList();

      weeks.add(WeeklyLearningStats(
        startDate: currentWeekStart,
        dailyStats: weekData,
      ));

      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    }

    return MonthlyLearningStats(
      year: year,
      month: month,
      weeklyStats: weeks,
    );
  }

  /// 学習レポートを生成
  LearningReport generateReport(AnalyticsTimeUnit timeUnit) {
    final now = DateTime.now();

    DailyLearningStats? dailyData;
    WeeklyLearningStats? weeklyData;
    MonthlyLearningStats? monthlyData;

    switch (timeUnit) {
      case AnalyticsTimeUnit.daily:
        dailyData = _getTodayStats();
        break;
      case AnalyticsTimeUnit.weekly:
        weeklyData = getWeeklyStats(now);
        break;
      case AnalyticsTimeUnit.monthly:
        monthlyData = getMonthlyStats(now.year, now.month);
        break;
      case AnalyticsTimeUnit.yearly:
        // 年単位は複数月のデータを集計
        break;
    }

    return LearningReport(
      generatedAt: now,
      timeUnit: timeUnit,
      progress: state.progress,
      dailyData: dailyData != null ? [dailyData] : null,
      weeklyData: weeklyData,
      monthlyData: monthlyData,
      insights: _generateInsights(),
    );
  }

  /// AIベースのインサイトを生成
  String? _generateInsights() {
    // 簡単なインサイト生成ロジック
    final accuracy = state.progress.overallAccuracy;
    final streak = state.currentStreak;
    final hoursSpent = state.progress.totalTimeSpent.inHours;

    if (accuracy >= 90 && streak >= 7) {
      return '素晴らしい成績です！高い正答率と継続的な学習習慣が身についています。🌟';
    } else if (accuracy >= 75) {
      return '順調に進んでいます。継続することでさらに成績が向上するでしょう。📈';
    } else if (streak >= 7) {
      return '学習習慣が定着しています。正答率を上げることに集中してみましょう。💪';
    } else if (hoursSpent >= 10) {
      return '多くの学習時間を投資されていますね。質の高い学習を心がけましょう。⏱️';
    }

    return null;
  }
}

/// プロバイダー定義

/// 学習分析状態プロバイダ
final learningAnalyticsProvider =
    StateNotifierProvider<LearningAnalyticsNotifier, LearningAnalyticsState>(
  (ref) => LearningAnalyticsNotifier(),
);

/// 総合進捗プロバイダ
final learningProgressProvider =
    FutureProvider<OverallLearningProgress>((ref) async {
  ref.watch(learningAnalyticsProvider);
  final notifier = ref.read(learningAnalyticsProvider.notifier);
  return notifier.state.progress;
});

/// 週間レポートプロバイダ
final weeklyReportProvider =
    FutureProvider.family<LearningReport, DateTime>((ref, date) async {
  ref.watch(learningAnalyticsProvider);
  final notifier = ref.read(learningAnalyticsProvider.notifier);
  return notifier.generateReport(AnalyticsTimeUnit.weekly);
});

/// 月間レポートプロバイダ
final monthlyReportProvider =
    FutureProvider.family<LearningReport, (int, int)>((ref, date) async {
  ref.watch(learningAnalyticsProvider);
  final notifier = ref.read(learningAnalyticsProvider.notifier);
  return notifier.generateReport(AnalyticsTimeUnit.monthly);
});

/// 日単位レポートプロバイダ
final dailyReportProvider = FutureProvider<LearningReport>((ref) async {
  ref.watch(learningAnalyticsProvider);
  final notifier = ref.read(learningAnalyticsProvider.notifier);
  return notifier.generateReport(AnalyticsTimeUnit.daily);
});
