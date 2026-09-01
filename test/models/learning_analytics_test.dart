import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';

void main() {
  group('DailyLearningStats Tests', () {
    test('DailyLearningStats creation with default values', () {
      final now = DateTime.now();
      final stats = DailyLearningStats(
        date: now,
        quizzesCompleted: 5,
        quizzesCorrect: 4,
        lessonsCompleted: 1,
        timeSpent: const Duration(hours: 1),
        accuracyPercentage: 80.0,
        xpGained: 100,
        coinsGained: 50,
      );

      expect(stats.date, now);
      expect(stats.quizzesCompleted, 5);
      expect(stats.quizzesCorrect, 4);
      expect(stats.lessonsCompleted, 1);
      expect(stats.timeSpent, const Duration(hours: 1));
      expect(stats.accuracyPercentage, 80.0);
      expect(stats.xpGained, 100);
      expect(stats.coinsGained, 50);
    });

    test('DailyLearningStats isToday property works correctly', () {
      final today = DateTime.now();
      final yesterdayStats = DailyLearningStats(
        date: today.subtract(const Duration(days: 1)),
      );
      final todayStats = DailyLearningStats(date: today);

      expect(yesterdayStats.isToday, false);
      expect(todayStats.isToday, true);
    });

    test('DailyLearningStats JSON serialization round-trip', () {
      final now = DateTime.now();
      final stats = DailyLearningStats(
        date: now,
        quizzesCompleted: 5,
        quizzesCorrect: 4,
        lessonsCompleted: 1,
        timeSpent: const Duration(hours: 1, minutes: 30),
        accuracyPercentage: 80.0,
        xpGained: 100,
        coinsGained: 50,
        categoryStats: {
          LearningCategory.programming: 3,
          LearningCategory.mathematics: 2,
        },
      );

      final json = stats.toJson();
      final restored = DailyLearningStats.fromJson(json);

      expect(restored.quizzesCompleted, stats.quizzesCompleted);
      expect(restored.quizzesCorrect, stats.quizzesCorrect);
      expect(restored.accuracyPercentage, stats.accuracyPercentage);
      expect(restored.categoryStats.length, 2);
    });
  });

  group('WeeklyLearningStats Tests', () {
    test('WeeklyLearningStats calculation', () {
      final monday = DateTime(2026, 9, 1); // Tuesday actually
      final dailyStats = [
        DailyLearningStats(
          date: monday,
          quizzesCompleted: 5,
          quizzesCorrect: 4,
        ),
        DailyLearningStats(
          date: monday.add(const Duration(days: 1)),
          quizzesCompleted: 3,
          quizzesCorrect: 3,
        ),
      ];

      final weekly = WeeklyLearningStats(
        startDate: monday,
        dailyStats: dailyStats,
      );

      expect(weekly.totalQuizzesCompleted, 8);
      expect(weekly.totalQuizzesCorrect, 7);
      expect(weekly.averageAccuracy, greaterThan(80.0));
      expect(weekly.daysLearned, 2);
    });

    test('WeeklyLearningStats consecutiveDays calculation', () {
      final monday = DateTime(2026, 9, 1);
      final dailyStats = [
        DailyLearningStats(
          date: monday,
          quizzesCompleted: 5,
        ),
        DailyLearningStats(
          date: monday.add(const Duration(days: 1)),
          quizzesCompleted: 3,
        ),
        DailyLearningStats(
          date: monday.add(const Duration(days: 2)),
          quizzesCompleted: 0, // No learning
        ),
        DailyLearningStats(
          date: monday.add(const Duration(days: 3)),
          quizzesCompleted: 4,
        ),
      ];

      final weekly = WeeklyLearningStats(
        startDate: monday,
        dailyStats: dailyStats,
      );

      expect(weekly.consecutiveDays, 1); // Only the last day counts
    });

    test('WeeklyLearningStats JSON serialization', () {
      final monday = DateTime(2026, 9, 1);
      final dailyStats = [
        DailyLearningStats(
          date: monday,
          quizzesCompleted: 5,
          quizzesCorrect: 4,
        ),
      ];

      final weekly = WeeklyLearningStats(
        startDate: monday,
        dailyStats: dailyStats,
      );

      final json = weekly.toJson();
      final restored = WeeklyLearningStats.fromJson(json);

      expect(restored.totalQuizzesCompleted, weekly.totalQuizzesCompleted);
      expect(restored.daysLearned, weekly.daysLearned);
    });
  });

  group('MonthlyLearningStats Tests', () {
    test('MonthlyLearningStats calculation', () {
      final week1 = WeeklyLearningStats(
        startDate: DateTime(2026, 9, 1),
        dailyStats: [
          DailyLearningStats(
            date: DateTime(2026, 9, 1),
            quizzesCompleted: 10,
            quizzesCorrect: 8,
          ),
        ],
      );

      final week2 = WeeklyLearningStats(
        startDate: DateTime(2026, 9, 8),
        dailyStats: [
          DailyLearningStats(
            date: DateTime(2026, 9, 8),
            quizzesCompleted: 5,
            quizzesCorrect: 5,
          ),
        ],
      );

      final monthly = MonthlyLearningStats(
        year: 2026,
        month: 9,
        weeklyStats: [week1, week2],
      );

      expect(monthly.totalQuizzesCompleted, 15);
      expect(monthly.daysLearned, 2);
    });

    test('MonthlyLearningStats average accuracy calculation', () {
      final dailyStats1 = [
        DailyLearningStats(
          date: DateTime(2026, 9, 1),
          quizzesCompleted: 10,
          quizzesCorrect: 10,
        ),
      ];

      final dailyStats2 = [
        DailyLearningStats(
          date: DateTime(2026, 9, 8),
          quizzesCompleted: 10,
          quizzesCorrect: 8,
        ),
      ];

      final monthly = MonthlyLearningStats(
        year: 2026,
        month: 9,
        weeklyStats: [
          WeeklyLearningStats(
            startDate: DateTime(2026, 9, 1),
            dailyStats: dailyStats1,
          ),
          WeeklyLearningStats(
            startDate: DateTime(2026, 9, 8),
            dailyStats: dailyStats2,
          ),
        ],
      );

      expect(monthly.averageAccuracy, 90.0);
    });

    test('MonthlyLearningStats JSON serialization', () {
      final month = MonthlyLearningStats(
        year: 2026,
        month: 9,
        weeklyStats: [
          WeeklyLearningStats(
            startDate: DateTime(2026, 9, 1),
            dailyStats: [
              DailyLearningStats(
                date: DateTime(2026, 9, 1),
                quizzesCompleted: 10,
              ),
            ],
          ),
        ],
      );

      final json = month.toJson();
      final restored = MonthlyLearningStats.fromJson(json);

      expect(restored.year, 2026);
      expect(restored.month, 9);
      expect(restored.totalQuizzesCompleted, 10);
    });
  });

  group('OverallLearningProgress Tests', () {
    test('OverallLearningProgress creation', () {
      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 100,
        totalQuizzesCorrect: 85,
        totalTimeSpent: const Duration(hours: 10),
        overallAccuracy: 85.0,
        longestStreak: 10,
        currentStreak: 5,
        totalDaysLearned: 20,
      );

      expect(progress.totalQuizzesCompleted, 100);
      expect(progress.totalQuizzesCorrect, 85);
      expect(progress.overallAccuracy, 85.0);
      expect(progress.longestStreak, 10);
      expect(progress.currentStreak, 5);
    });

    test('OverallLearningProgress JSON serialization', () {
      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 100,
        totalQuizzesCorrect: 85,
        totalTimeSpent: const Duration(hours: 10),
        overallAccuracy: 85.0,
        longestStreak: 10,
        currentStreak: 5,
        totalDaysLearned: 20,
        categoryStats: {
          LearningCategory.programming: 50,
          LearningCategory.mathematics: 50,
        },
      );

      final json = progress.toJson();
      final restored = OverallLearningProgress.fromJson(json);

      expect(restored.totalQuizzesCompleted, progress.totalQuizzesCompleted);
      expect(restored.overallAccuracy, progress.overallAccuracy);
      expect(restored.categoryStats.length, 2);
    });
  });

  group('LearningReport Tests', () {
    test('LearningReport creation', () {
      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 100,
        totalQuizzesCorrect: 85,
        totalTimeSpent: const Duration(hours: 10),
        overallAccuracy: 85.0,
        longestStreak: 10,
        currentStreak: 5,
        totalDaysLearned: 20,
      );

      final report = LearningReport(
        generatedAt: DateTime.now(),
        timeUnit: AnalyticsTimeUnit.weekly,
        progress: progress,
        insights: 'Great progress!',
      );

      expect(report.timeUnit, AnalyticsTimeUnit.weekly);
      expect(report.progress.totalQuizzesCompleted, 100);
      expect(report.insights, 'Great progress!');
    });

    test('LearningReport JSON serialization', () {
      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 100,
        totalQuizzesCorrect: 85,
        totalTimeSpent: const Duration(hours: 10),
        overallAccuracy: 85.0,
        longestStreak: 10,
        currentStreak: 5,
        totalDaysLearned: 20,
      );

      final report = LearningReport(
        generatedAt: DateTime.now(),
        timeUnit: AnalyticsTimeUnit.monthly,
        progress: progress,
      );

      final json = report.toJson();
      final restored = LearningReport.fromJson(json);

      expect(restored.timeUnit, AnalyticsTimeUnit.monthly);
      expect(restored.progress.totalQuizzesCompleted, 100);
    });
  });

  group('AnalyticsTimeUnit Enum Tests', () {
    test('AnalyticsTimeUnit has 4 values', () {
      expect(AnalyticsTimeUnit.values.length, 4);
      expect(AnalyticsTimeUnit.values, contains(AnalyticsTimeUnit.daily));
      expect(AnalyticsTimeUnit.values, contains(AnalyticsTimeUnit.weekly));
      expect(AnalyticsTimeUnit.values, contains(AnalyticsTimeUnit.monthly));
      expect(AnalyticsTimeUnit.values, contains(AnalyticsTimeUnit.yearly));
    });

    test('AnalyticsTimeUnit name property', () {
      expect(AnalyticsTimeUnit.daily.name, 'daily');
      expect(AnalyticsTimeUnit.weekly.name, 'weekly');
      expect(AnalyticsTimeUnit.monthly.name, 'monthly');
      expect(AnalyticsTimeUnit.yearly.name, 'yearly');
    });
  });

  group('LearningCategory Enum Tests', () {
    test('LearningCategory has 5 values', () {
      expect(LearningCategory.values.length, 5);
      expect(LearningCategory.values, contains(LearningCategory.programming));
      expect(LearningCategory.values, contains(LearningCategory.mathematics));
      expect(LearningCategory.values, contains(LearningCategory.algorithms));
      expect(LearningCategory.values, contains(LearningCategory.dataStructure));
      expect(LearningCategory.values, contains(LearningCategory.other));
    });

    test('LearningCategory name property', () {
      expect(LearningCategory.programming.name, 'programming');
      expect(LearningCategory.mathematics.name, 'mathematics');
      expect(LearningCategory.algorithms.name, 'algorithms');
    });
  });
}
