/// 学習分析の時間単位
enum AnalyticsTimeUnit {
  daily,    // 日単位
  weekly,   // 週単位
  monthly,  // 月単位
  yearly,   // 年単位
}

/// 学習カテゴリ
enum LearningCategory {
  programming,  // プログラミング
  mathematics,  // 数学
  algorithms,   // アルゴリズム
  dataStructure, // データ構造
  other,        // その他
}

/// 単日の学習統計
class DailyLearningStats {
  final DateTime date;
  final int quizzesCompleted;
  final int quizzesCorrect;
  final int lessonsCompleted;
  final Duration timeSpent;
  final double accuracyPercentage;
  final int xpGained;
  final int coinsGained;
  final Map<LearningCategory, int> categoryStats; // カテゴリ別の問題数

  DailyLearningStats({
    required this.date,
    this.quizzesCompleted = 0,
    this.quizzesCorrect = 0,
    this.lessonsCompleted = 0,
    this.timeSpent = const Duration(),
    this.accuracyPercentage = 0.0,
    this.xpGained = 0,
    this.coinsGained = 0,
    this.categoryStats = const {},
  });

  /// JSONに変換
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'quizzesCompleted': quizzesCompleted,
    'quizzesCorrect': quizzesCorrect,
    'lessonsCompleted': lessonsCompleted,
    'timeSpent': timeSpent.inSeconds,
    'accuracyPercentage': accuracyPercentage,
    'xpGained': xpGained,
    'coinsGained': coinsGained,
    'categoryStats': categoryStats.map(
      (k, v) => MapEntry(k.name, v),
    ),
  };

  /// JSONから復元
  factory DailyLearningStats.fromJson(Map<String, dynamic> json) =>
      DailyLearningStats(
        date: DateTime.parse(json['date'] as String),
        quizzesCompleted: json['quizzesCompleted'] as int? ?? 0,
        quizzesCorrect: json['quizzesCorrect'] as int? ?? 0,
        lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
        timeSpent:
            Duration(seconds: json['timeSpent'] as int? ?? 0),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble() ?? 0.0,
        xpGained: json['xpGained'] as int? ?? 0,
        coinsGained: json['coinsGained'] as int? ?? 0,
        categoryStats:
            ((json['categoryStats'] as Map<String, dynamic>?) ?? {})
                .map(
              (k, v) => MapEntry(
                LearningCategory.values.byName(k),
                v as int,
              ),
            ),
      );

  /// このデータが今日のものかチェック
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// 週単位の学習統計
class WeeklyLearningStats {
  final DateTime startDate; // その週の月曜日
  final List<DailyLearningStats> dailyStats;

  WeeklyLearningStats({
    required this.startDate,
    required this.dailyStats,
  });

  /// 週間の総問題数
  int get totalQuizzesCompleted =>
      dailyStats.fold(0, (sum, stats) => sum + stats.quizzesCompleted);

  /// 週間の総正解数
  int get totalQuizzesCorrect =>
      dailyStats.fold(0, (sum, stats) => sum + stats.quizzesCorrect);

  /// 週間の平均正答率
  double get averageAccuracy {
    if (totalQuizzesCompleted == 0) return 0.0;
    return (totalQuizzesCorrect / totalQuizzesCompleted * 100)
        .clamp(0.0, 100.0);
  }

  /// 週間の総学習時間
  Duration get totalTimeSpent => Duration(
    seconds: dailyStats.fold(
      0,
      (sum, stats) => sum + stats.timeSpent.inSeconds,
    ),
  );

  /// 学習した日数
  int get daysLearned => dailyStats.where((s) => s.quizzesCompleted > 0).length;

  /// 学習連続日数
  int get consecutiveDays {
    int count = 0;
    for (final stats in dailyStats.reversed) {
      if (stats.quizzesCompleted > 0) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// JSONに変換
  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'dailyStats': dailyStats.map((s) => s.toJson()).toList(),
  };

  /// JSONから復元
  factory WeeklyLearningStats.fromJson(Map<String, dynamic> json) =>
      WeeklyLearningStats(
        startDate: DateTime.parse(json['startDate'] as String),
        dailyStats: ((json['dailyStats'] as List?) ?? [])
            .map((d) => DailyLearningStats.fromJson(
              d as Map<String, dynamic>,
            ))
            .toList(),
      );
}

/// 月単位の学習統計
class MonthlyLearningStats {
  final int year;
  final int month;
  final List<WeeklyLearningStats> weeklyStats;

  MonthlyLearningStats({
    required this.year,
    required this.month,
    required this.weeklyStats,
  });

  /// 月間の総問題数
  int get totalQuizzesCompleted =>
      weeklyStats.fold(0, (sum, stats) => sum + stats.totalQuizzesCompleted);

  /// 月間の平均正答率
  double get averageAccuracy {
    if (totalQuizzesCompleted == 0) return 0.0;
    final totalCorrect =
        weeklyStats.fold(0, (sum, stats) => sum + stats.totalQuizzesCorrect);
    return (totalCorrect / totalQuizzesCompleted * 100).clamp(0.0, 100.0);
  }

  /// 月間の総学習時間（時間単位）
  double get totalHoursSpent =>
      weeklyStats.fold(0.0, (sum, stats) => sum + stats.totalTimeSpent.inHours);

  /// 学習した日数
  int get daysLearned =>
      weeklyStats.fold(0, (sum, stats) => sum + stats.daysLearned);

  /// JSONに変換
  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'weeklyStats': weeklyStats.map((s) => s.toJson()).toList(),
  };

  /// JSONから復元
  factory MonthlyLearningStats.fromJson(Map<String, dynamic> json) =>
      MonthlyLearningStats(
        year: json['year'] as int,
        month: json['month'] as int,
        weeklyStats: ((json['weeklyStats'] as List?) ?? [])
            .map((w) => WeeklyLearningStats.fromJson(
              w as Map<String, dynamic>,
            ))
            .toList(),
      );
}

/// 総合学習進捗情報
class OverallLearningProgress {
  final int totalQuizzesCompleted;
  final int totalQuizzesCorrect;
  final Duration totalTimeSpent;
  final double overallAccuracy;
  final int longestStreak; // 最長連続学習日数
  final int currentStreak; // 現在の連続学習日数
  final DateTime? lastStudyDate;
  final int totalDaysLearned;
  final Map<LearningCategory, int> categoryStats;

  OverallLearningProgress({
    required this.totalQuizzesCompleted,
    required this.totalQuizzesCorrect,
    required this.totalTimeSpent,
    required this.overallAccuracy,
    required this.longestStreak,
    required this.currentStreak,
    this.lastStudyDate,
    required this.totalDaysLearned,
    this.categoryStats = const {},
  });

  /// JSONに変換
  Map<String, dynamic> toJson() => {
    'totalQuizzesCompleted': totalQuizzesCompleted,
    'totalQuizzesCorrect': totalQuizzesCorrect,
    'totalTimeSpent': totalTimeSpent.inSeconds,
    'overallAccuracy': overallAccuracy,
    'longestStreak': longestStreak,
    'currentStreak': currentStreak,
    'lastStudyDate': lastStudyDate?.toIso8601String(),
    'totalDaysLearned': totalDaysLearned,
    'categoryStats': categoryStats.map(
      (k, v) => MapEntry(k.name, v),
    ),
  };

  /// JSONから復元
  factory OverallLearningProgress.fromJson(Map<String, dynamic> json) =>
      OverallLearningProgress(
        totalQuizzesCompleted: json['totalQuizzesCompleted'] as int? ?? 0,
        totalQuizzesCorrect: json['totalQuizzesCorrect'] as int? ?? 0,
        totalTimeSpent:
            Duration(seconds: json['totalTimeSpent'] as int? ?? 0),
        overallAccuracy: (json['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        lastStudyDate: json['lastStudyDate'] != null
            ? DateTime.parse(json['lastStudyDate'] as String)
            : null,
        totalDaysLearned: json['totalDaysLearned'] as int? ?? 0,
        categoryStats:
            ((json['categoryStats'] as Map<String, dynamic>?) ?? {})
                .map(
              (k, v) => MapEntry(
                LearningCategory.values.byName(k),
                v as int,
              ),
            ),
      );

  /// Copy with updated fields
  OverallLearningProgress copyWith({
    int? totalQuizzesCompleted,
    int? totalQuizzesCorrect,
    Duration? totalTimeSpent,
    double? overallAccuracy,
    int? longestStreak,
    int? currentStreak,
    DateTime? lastStudyDate,
    int? totalDaysLearned,
    Map<LearningCategory, int>? categoryStats,
  }) {
    return OverallLearningProgress(
      totalQuizzesCompleted: totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      totalQuizzesCorrect: totalQuizzesCorrect ?? this.totalQuizzesCorrect,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalDaysLearned: totalDaysLearned ?? this.totalDaysLearned,
      categoryStats: categoryStats ?? this.categoryStats,
    );
  }
}

/// 学習レポート
class LearningReport {
  final DateTime generatedAt;
  final AnalyticsTimeUnit timeUnit;
  final OverallLearningProgress progress;
  final List<DailyLearningStats>? dailyData;
  final WeeklyLearningStats? weeklyData;
  final MonthlyLearningStats? monthlyData;
  final String? insights; // AI生成のインサイト

  LearningReport({
    required this.generatedAt,
    required this.timeUnit,
    required this.progress,
    this.dailyData,
    this.weeklyData,
    this.monthlyData,
    this.insights,
  });

  /// JSONに変換
  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'timeUnit': timeUnit.name,
    'progress': progress.toJson(),
    'dailyData': dailyData?.map((d) => d.toJson()).toList(),
    'weeklyData': weeklyData?.toJson(),
    'monthlyData': monthlyData?.toJson(),
    'insights': insights,
  };

  /// JSONから復元
  factory LearningReport.fromJson(Map<String, dynamic> json) =>
      LearningReport(
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        timeUnit: AnalyticsTimeUnit.values.byName(json['timeUnit'] as String),
        progress: OverallLearningProgress.fromJson(
          json['progress'] as Map<String, dynamic>,
        ),
        dailyData: ((json['dailyData'] as List?) ?? [])
            .map((d) => DailyLearningStats.fromJson(
              d as Map<String, dynamic>,
            ))
            .toList(),
        weeklyData: json['weeklyData'] != null
            ? WeeklyLearningStats.fromJson(
              json['weeklyData'] as Map<String, dynamic>,
            )
            : null,
        monthlyData: json['monthlyData'] != null
            ? MonthlyLearningStats.fromJson(
              json['monthlyData'] as Map<String, dynamic>,
            )
            : null,
        insights: json['insights'] as String?,
      );
}
