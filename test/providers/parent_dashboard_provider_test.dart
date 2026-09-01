import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/providers/parent_dashboard_provider.dart';
import 'package:shogaku_kore_programming/models/parent_dashboard.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ParentDashboardState Tests', () {
    test('ParentDashboardState creation with defaults', () {
      final state = ParentDashboardState();

      expect(state.dashboardData, isNull);
      expect(state.alerts.length, 0);
      expect(state.notificationSettings, isNull);
      expect(state.learningGoals.length, 0);
      expect(state.isLoading, false);
    });

    test('ParentDashboardState copyWith', () {
      final state1 = ParentDashboardState();

      final state2 = state1.copyWith(
        isLoading: true,
        alerts: [],
      );

      expect(state2.isLoading, true);
      expect(state1.isLoading, false); // Original unchanged
    });
  });

  group('ParentDashboardNotifier Tests', () {
    test('ParentDashboardNotifier initializes with empty state', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(parentDashboardProvider);
      expect(state.dashboardData, isNull);
      expect(state.alerts.isEmpty, true);
    });

    test('ParentDashboardNotifier updateDashboardData', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 50,
        totalQuizzesCorrect: 40,
        totalTimeSpent: const Duration(hours: 5),
        overallAccuracy: 80.0,
        longestStreak: 5,
        currentStreak: 3,
        totalDaysLearned: 10,
      );

      await notifier.updateDashboardData(
        'child123',
        progress,
        ['badge1', 'badge2'],
        4,
        50.0,
        3,
        5,
      );

      final state = container.read(parentDashboardProvider);
      expect(state.dashboardData, isNotNull);
      expect(state.dashboardData!.currentLevel, 4);
      expect(state.dashboardData!.earnedBadgeIds.length, 2);
    });

    test('ParentDashboardNotifier identifies weak areas', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 100,
        totalQuizzesCorrect: 60,
        totalTimeSpent: const Duration(hours: 8),
        overallAccuracy: 60.0,
        longestStreak: 3,
        currentStreak: 1,
        totalDaysLearned: 5,
        categoryStats: {
          LearningCategory.programming: 30,
          LearningCategory.mathematics: 40,
          LearningCategory.algorithms: 30,
        },
      );

      await notifier.updateDashboardData(
        'child123',
        progress,
        [],
        2,
        25.0,
        1,
        3,
      );

      final state = container.read(parentDashboardProvider);
      expect(state.dashboardData!.weakAreas.length, greaterThan(0));
    });

    test('ParentDashboardNotifier generates general insight', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 50,
        totalQuizzesCorrect: 48,
        totalTimeSpent: const Duration(hours: 6),
        overallAccuracy: 96.0,
        longestStreak: 10,
        currentStreak: 8,
        totalDaysLearned: 15,
      );

      await notifier.updateDashboardData(
        'child123',
        progress,
        ['badge1', 'badge2', 'badge3'],
        6,
        75.0,
        5,
        5,
      );

      final state = container.read(parentDashboardProvider);
      expect(state.dashboardData!.generalInsight, isNotNull);
      expect(
        state.dashboardData!.generalInsight!.toLowerCase(),
        contains('素晴らしい'),
      );
    });

    test('ParentDashboardNotifier adds learning goal', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final deadline = DateTime.now().add(const Duration(days: 30));

      await notifier.addLearningGoal(
        'child123',
        'Math Mastery',
        'Achieve 90% accuracy in mathematics',
        LearningCategory.mathematics,
        90.0,
        100,
        deadline,
      );

      final state = container.read(parentDashboardProvider);
      expect(state.learningGoals.length, 1);
      expect(state.learningGoals.first.title, 'Math Mastery');
      expect(state.learningGoals.first.isCompleted, false);
    });

    test('ParentDashboardNotifier completes goal', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final deadline = DateTime.now().add(const Duration(days: 30));

      await notifier.addLearningGoal(
        'child123',
        'Math Goal',
        'Goal description',
        LearningCategory.mathematics,
        85.0,
        50,
        deadline,
      );

      final stateAfterAdd = container.read(parentDashboardProvider);
      final goalId = stateAfterAdd.learningGoals.first.goalId;

      await notifier.completeGoal(goalId);

      final stateAfterComplete = container.read(parentDashboardProvider);
      expect(stateAfterComplete.learningGoals.first.isCompleted, true);
      expect(stateAfterComplete.learningGoals.first.completedAt, isNotNull);
    });

    test('ParentDashboardNotifier adds alert', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      await notifier.addAlert(
        'child123',
        'Low Accuracy',
        'Accuracy dropped below 70%',
        ParentAlertType.lowAccuracy,
      );

      final state = container.read(parentDashboardProvider);
      expect(state.alerts.length, 1);
      expect(state.alerts.first.title, 'Low Accuracy');
      expect(state.alerts.first.isRead, false);
    });

    test('ParentDashboardNotifier marks alert as read', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      await notifier.addAlert(
        'child123',
        'Alert Title',
        'Alert message',
        ParentAlertType.badgeEarned,
      );

      final stateAfterAdd = container.read(parentDashboardProvider);
      final alertId = stateAfterAdd.alerts.first.alertId;

      await notifier.markAlertAsRead(alertId);

      final stateAfterRead = container.read(parentDashboardProvider);
      expect(stateAfterRead.alerts.first.isRead, true);
      expect(stateAfterRead.alerts.first.readAt, isNotNull);
    });

    test('ParentDashboardNotifier updates notification settings', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final now = DateTime.now();
      final settings = ParentNotificationSettings(
        parentId: 'parent123',
        childId: 'child123',
        dailyReportEnabled: false,
        lowAccuracyThreshold: 75.0,
        createdAt: now,
        updatedAt: now,
      );

      await notifier.updateNotificationSettings(settings);

      final state = container.read(parentDashboardProvider);
      expect(state.notificationSettings, isNotNull);
      expect(state.notificationSettings!.dailyReportEnabled, false);
      expect(state.notificationSettings!.lowAccuracyThreshold, 75.0);
    });

    test('ParentDashboardNotifier persists dashboard data to SharedPreferences',
        () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 30,
        totalQuizzesCorrect: 24,
        totalTimeSpent: const Duration(hours: 3),
        overallAccuracy: 80.0,
        longestStreak: 4,
        currentStreak: 2,
        totalDaysLearned: 6,
      );

      await notifier.updateDashboardData(
        'child123',
        progress,
        [],
        3,
        35.0,
        2,
        4,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('parent_dashboard_data'), isNotNull);
    });

    test('ParentDashboardNotifier handles multiple alerts', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      for (int i = 0; i < 5; i++) {
        await notifier.addAlert(
          'child123',
          'Alert $i',
          'Message $i',
          i % 2 == 0 ? ParentAlertType.badgeEarned : ParentAlertType.levelUp,
        );
      }

      final state = container.read(parentDashboardProvider);
      expect(state.alerts.length, 5);
    });

    test('ParentDashboardNotifier loads local data', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 40,
        totalQuizzesCorrect: 36,
        totalTimeSpent: const Duration(hours: 4),
        overallAccuracy: 90.0,
        longestStreak: 6,
        currentStreak: 4,
        totalDaysLearned: 8,
      );

      await notifier.updateDashboardData(
        'child123',
        progress,
        ['badge1'],
        4,
        60.0,
        4,
        5,
      );

      // Create new container to simulate app restart
      final newContainer = ProviderContainer();
      final newNotifier = newContainer.read(parentDashboardProvider.notifier);

      await newNotifier.loadLocalData('child123');

      final newState = newContainer.read(parentDashboardProvider);
      expect(newState.dashboardData, isNotNull);
    });

    test('ParentDashboardNotifier generates recent trends', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(parentDashboardProvider.notifier);

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 50,
        totalQuizzesCorrect: 42,
        totalTimeSpent: const Duration(hours: 5),
        overallAccuracy: 84.0,
        longestStreak: 5,
        currentStreak: 3,
        totalDaysLearned: 10,
      );

      await notifier.updateDashboardData(
        'child123',
        progress,
        [],
        3,
        40.0,
        2,
        4,
      );

      final state = container.read(parentDashboardProvider);
      expect(state.dashboardData!.recentTrends.length, 14);
    });
  });
}
