import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/providers/learning_analytics_provider.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LearningAnalyticsState Tests', () {
    test('LearningAnalyticsState creation with default values', () {
      final state = LearningAnalyticsState(
        progress: OverallLearningProgress(
          totalQuizzesCompleted: 0,
          totalQuizzesCorrect: 0,
          totalTimeSpent: const Duration(),
          overallAccuracy: 0.0,
          longestStreak: 0,
          currentStreak: 0,
          totalDaysLearned: 0,
        ),
      );

      expect(state.dailyStats.length, 0);
      expect(state.progress.totalQuizzesCompleted, 0);
      expect(state.currentStreak, 0);
      expect(state.longestStreak, 0);
    });

    test('LearningAnalyticsState copyWith', () {
      final progress1 = OverallLearningProgress(
        totalQuizzesCompleted: 10,
        totalQuizzesCorrect: 8,
        totalTimeSpent: const Duration(hours: 1),
        overallAccuracy: 80.0,
        longestStreak: 3,
        currentStreak: 2,
        totalDaysLearned: 5,
      );

      final state1 = LearningAnalyticsState(progress: progress1);

      final progress2 = OverallLearningProgress(
        totalQuizzesCompleted: 20,
        totalQuizzesCorrect: 18,
        totalTimeSpent: const Duration(hours: 2),
        overallAccuracy: 90.0,
        longestStreak: 5,
        currentStreak: 4,
        totalDaysLearned: 10,
      );

      final state2 = state1.copyWith(progress: progress2, currentStreak: 4);

      expect(state2.progress.totalQuizzesCompleted, 20);
      expect(state2.currentStreak, 4);
    });
  });

  group('LearningAnalyticsNotifier Tests', () {
    test('LearningAnalyticsNotifier initializes with zero stats', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(learningAnalyticsProvider);
      expect(state.progress.totalQuizzesCompleted, 0);
      expect(state.currentStreak, 0);
    });

    test('LearningAnalyticsNotifier recordQuizCompletion updates stats', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);
      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      final state = container.read(learningAnalyticsProvider);
      expect(state.progress.totalQuizzesCompleted, 5);
      expect(state.progress.totalQuizzesCorrect, 4);
    });

    test('LearningAnalyticsNotifier calculates accuracy correctly', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      // First quiz: 8/10 = 80%
      await notifier.recordQuizCompletion(
        correctCount: 8,
        totalCount: 10,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      // Second quiz: 9/10 = 90%
      await notifier.recordQuizCompletion(
        correctCount: 9,
        totalCount: 10,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.mathematics,
        xpGained: 50,
        coinsGained: 25,
      );

      final state = container.read(learningAnalyticsProvider);
      expect(state.progress.totalQuizzesCompleted, 20);
      expect(state.progress.totalQuizzesCorrect, 17);
      expect(state.progress.overallAccuracy, 85.0);
    });

    test('LearningAnalyticsNotifier tracks category stats', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      await notifier.recordQuizCompletion(
        correctCount: 3,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.mathematics,
        xpGained: 50,
        coinsGained: 25,
      );

      final state = container.read(learningAnalyticsProvider);
      expect(state.progress.categoryStats[LearningCategory.programming], 5);
      expect(state.progress.categoryStats[LearningCategory.mathematics], 5);
    });

    test('LearningAnalyticsNotifier calculates streak correctly', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      // Record quiz today
      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      var state = container.read(learningAnalyticsProvider);
      expect(state.currentStreak, greaterThanOrEqualTo(1));

      // Verify longest streak is updated
      expect(state.longestStreak, greaterThanOrEqualTo(state.currentStreak));
    });

    test('LearningAnalyticsNotifier tracks time spent', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(hours: 1, minutes: 30),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      final state = container.read(learningAnalyticsProvider);
      expect(
        state.progress.totalTimeSpent,
        const Duration(hours: 1, minutes: 30),
      );
    });

    test('LearningAnalyticsNotifier generates daily report', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      final report = notifier.generateReport(AnalyticsTimeUnit.daily);

      expect(report.timeUnit, AnalyticsTimeUnit.daily);
      expect(report.progress.totalQuizzesCompleted, greaterThan(0));
      expect(report.dailyData, isNotEmpty);
    });

    test('LearningAnalyticsNotifier generates weekly report', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      final report = notifier.generateReport(AnalyticsTimeUnit.weekly);

      expect(report.timeUnit, AnalyticsTimeUnit.weekly);
      expect(report.weeklyData, isNotNull);
    });

    test('LearningAnalyticsNotifier generates monthly report', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      final report = notifier.generateReport(AnalyticsTimeUnit.monthly);

      expect(report.timeUnit, AnalyticsTimeUnit.monthly);
      expect(report.monthlyData, isNotNull);
    });

    test('LearningAnalyticsNotifier generates insights', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      // Record high accuracy quizzes
      for (int i = 0; i < 10; i++) {
        await notifier.recordQuizCompletion(
          correctCount: 9,
          totalCount: 10,
          timeSpent: const Duration(minutes: 10),
          category: LearningCategory.programming,
          xpGained: 50,
          coinsGained: 25,
        );
      }

      final report = notifier.generateReport(AnalyticsTimeUnit.daily);

      // High accuracy might trigger insights
      if (report.progress.overallAccuracy >= 90.0) {
        expect(report.insights, isNotNull);
      }
    });

    test('LearningAnalyticsNotifier persists data to SharedPreferences', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('learning_progress'), isNotNull);
      expect(prefs.getStringList('learning_daily_stats'), isNotNull);
    });

    test('LearningAnalyticsNotifier handles multiple quiz completions', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      // Simulate completing multiple quizzes throughout the day
      for (int i = 0; i < 5; i++) {
        await notifier.recordQuizCompletion(
          correctCount: 4,
          totalCount: 5,
          timeSpent: const Duration(minutes: 10),
          category: LearningCategory.programming,
          xpGained: 50,
          coinsGained: 25,
        );
      }

      final state = container.read(learningAnalyticsProvider);
      expect(state.progress.totalQuizzesCompleted, 25);
      expect(state.progress.totalQuizzesCorrect, 20);
    });

    test('LearningAnalyticsNotifier getStatsForDateRange', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(learningAnalyticsProvider.notifier);

      await notifier.recordQuizCompletion(
        correctCount: 4,
        totalCount: 5,
        timeSpent: const Duration(minutes: 10),
        category: LearningCategory.programming,
        xpGained: 50,
        coinsGained: 25,
      );

      final now = DateTime.now();
      final stats = notifier.getStatsForDateRange(
        now.subtract(const Duration(days: 7)),
        now.add(const Duration(days: 1)),
      );

      expect(stats, isNotEmpty);
    });
  });
}
