import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/parent_dashboard.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';

void main() {
  group('ChildProfile Tests', () {
    test('ChildProfile creation with default values', () {
      final now = DateTime.now();
      final profile = ChildProfile(
        childId: 'child123',
        childName: 'Taro',
        gradeLevel: 3,
        createdAt: now,
      );

      expect(profile.childId, 'child123');
      expect(profile.childName, 'Taro');
      expect(profile.gradeLevel, 3);
      expect(profile.isActive, true);
    });

    test('ChildProfile JSON serialization round-trip', () {
      final now = DateTime.now();
      final profile = ChildProfile(
        childId: 'child123',
        childName: 'Taro',
        gradeLevel: 3,
        createdAt: now,
        profileImageUrl: 'https://example.com/image.jpg',
        lastActiveAt: now.subtract(const Duration(hours: 2)),
        isActive: true,
      );

      final json = profile.toJson();
      final restored = ChildProfile.fromJson(json);

      expect(restored.childId, profile.childId);
      expect(restored.childName, profile.childName);
      expect(restored.gradeLevel, profile.gradeLevel);
      expect(restored.profileImageUrl, profile.profileImageUrl);
      expect(restored.isActive, profile.isActive);
    });
  });

  group('WeakArea Tests', () {
    test('WeakArea creation', () {
      final weakArea = WeakArea(
        category: LearningCategory.mathematics,
        accuracy: 65.0,
        attemptCount: 10,
        recommendation: 'もっと練習が必要です',
      );

      expect(weakArea.category, LearningCategory.mathematics);
      expect(weakArea.accuracy, 65.0);
      expect(weakArea.attemptCount, 10);
      expect(weakArea.recommendation, 'もっと練習が必要です');
    });

    test('WeakArea JSON serialization', () {
      final weakArea = WeakArea(
        category: LearningCategory.algorithms,
        accuracy: 72.5,
        attemptCount: 15,
        recommendation: 'アルゴリズムをもう一度学ぶことをお勧めします',
      );

      final json = weakArea.toJson();
      final restored = WeakArea.fromJson(json);

      expect(restored.category, weakArea.category);
      expect(restored.accuracy, weakArea.accuracy);
      expect(restored.attemptCount, weakArea.attemptCount);
    });
  });

  group('LearningTimeTrend Tests', () {
    test('LearningTimeTrend creation', () {
      final date = DateTime(2026, 9, 1);
      final trend = LearningTimeTrend(
        date: date,
        timeSpent: const Duration(minutes: 30),
        quizzesCompleted: 5,
      );

      expect(trend.date, date);
      expect(trend.timeSpent, const Duration(minutes: 30));
      expect(trend.quizzesCompleted, 5);
    });

    test('LearningTimeTrend JSON serialization', () {
      final date = DateTime(2026, 9, 1);
      final trend = LearningTimeTrend(
        date: date,
        timeSpent: const Duration(hours: 1, minutes: 15),
        quizzesCompleted: 8,
      );

      final json = trend.toJson();
      final restored = LearningTimeTrend.fromJson(json);

      expect(restored.date, trend.date);
      expect(restored.timeSpent, trend.timeSpent);
      expect(restored.quizzesCompleted, trend.quizzesCompleted);
    });
  });

  group('ParentDashboardData Tests', () {
    test('ParentDashboardData creation', () {
      final now = DateTime.now();
      final childProfile = ChildProfile(
        childId: 'child123',
        childName: 'Taro',
        gradeLevel: 3,
        createdAt: now,
      );

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 50,
        totalQuizzesCorrect: 42,
        totalTimeSpent: const Duration(hours: 5),
        overallAccuracy: 84.0,
        longestStreak: 7,
        currentStreak: 3,
        totalDaysLearned: 10,
      );

      final dashboardData = ParentDashboardData(
        childProfile: childProfile,
        learningProgress: progress,
        earnedBadgeIds: ['badge1', 'badge2'],
        currentLevel: 5,
        levelProgress: 45.0,
        dailyMissionsCompleted: 3,
        dailyMissionsTotal: 5,
        weakAreas: [],
        recentTrends: [],
        generatedAt: now,
      );

      expect(dashboardData.childProfile.childName, 'Taro');
      expect(dashboardData.totalLearningHours, 5);
      expect(dashboardData.overallAccuracy, 84.0);
      expect(dashboardData.totalQuizzes, 50);
      expect(dashboardData.learningStreak, 3);
    });

    test('ParentDashboardData JSON serialization', () {
      final now = DateTime.now();
      final childProfile = ChildProfile(
        childId: 'child123',
        childName: 'Taro',
        gradeLevel: 3,
        createdAt: now,
      );

      final progress = OverallLearningProgress(
        totalQuizzesCompleted: 50,
        totalQuizzesCorrect: 42,
        totalTimeSpent: const Duration(hours: 5),
        overallAccuracy: 84.0,
        longestStreak: 7,
        currentStreak: 3,
        totalDaysLearned: 10,
      );

      final dashboardData = ParentDashboardData(
        childProfile: childProfile,
        learningProgress: progress,
        earnedBadgeIds: ['badge1', 'badge2'],
        currentLevel: 5,
        levelProgress: 45.0,
        dailyMissionsCompleted: 3,
        dailyMissionsTotal: 5,
        weakAreas: [],
        recentTrends: [],
        generalInsight: 'Great progress!',
        generatedAt: now,
      );

      final json = dashboardData.toJson();
      final restored = ParentDashboardData.fromJson(json);

      expect(restored.childProfile.childName, dashboardData.childProfile.childName);
      expect(restored.totalLearningHours, dashboardData.totalLearningHours);
      expect(restored.earnedBadgeIds.length, 2);
      expect(restored.generalInsight, 'Great progress!');
    });
  });

  group('ParentNotificationSettings Tests', () {
    test('ParentNotificationSettings creation with defaults', () {
      final now = DateTime.now();
      final settings = ParentNotificationSettings(
        parentId: 'parent123',
        childId: 'child123',
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.dailyReportEnabled, true);
      expect(settings.weeklyReportEnabled, true);
      expect(settings.lowAccuracyThreshold, 70.0);
      expect(settings.minimumDailyMinutes, 30);
    });

    test('ParentNotificationSettings copyWith', () {
      final now = DateTime.now();
      final settings1 = ParentNotificationSettings(
        parentId: 'parent123',
        childId: 'child123',
        createdAt: now,
        updatedAt: now,
      );

      final settings2 = settings1.copyWith(
        lowAccuracyThreshold: 75.0,
        minimumDailyMinutes: 45,
      );

      expect(settings2.lowAccuracyThreshold, 75.0);
      expect(settings2.minimumDailyMinutes, 45);
      expect(settings2.dailyReportEnabled, true);
    });

    test('ParentNotificationSettings JSON serialization', () {
      final now = DateTime.now();
      final settings = ParentNotificationSettings(
        parentId: 'parent123',
        childId: 'child123',
        dailyReportEnabled: false,
        lowAccuracyThreshold: 65.0,
        createdAt: now,
        updatedAt: now,
      );

      final json = settings.toJson();
      final restored = ParentNotificationSettings.fromJson(json);

      expect(restored.dailyReportEnabled, false);
      expect(restored.lowAccuracyThreshold, 65.0);
      expect(restored.parentId, 'parent123');
    });
  });

  group('LearningGoal Tests', () {
    test('LearningGoal creation', () {
      final deadline = DateTime.now().add(const Duration(days: 30));
      final goal = LearningGoal(
        goalId: 'goal123',
        childId: 'child123',
        title: 'マスター数学',
        description: '数学の問題を90%の精度で解く',
        category: LearningCategory.mathematics,
        targetAccuracy: 90.0,
        targetQuizzesCount: 100,
        deadline: deadline,
        createdAt: DateTime.now(),
      );

      expect(goal.title, 'マスター数学');
      expect(goal.targetAccuracy, 90.0);
      expect(goal.isCompleted, false);
      expect(goal.isOverdue, false);
      expect(goal.daysRemaining, greaterThan(0));
    });

    test('LearningGoal isOverdue property', () {
      final pastDeadline = DateTime.now().subtract(const Duration(days: 1));
      final goal = LearningGoal(
        goalId: 'goal123',
        childId: 'child123',
        title: 'Goal',
        description: 'Test goal',
        category: LearningCategory.programming,
        targetAccuracy: 85.0,
        targetQuizzesCount: 50,
        deadline: pastDeadline,
        createdAt: DateTime.now(),
      );

      expect(goal.isOverdue, true);
    });

    test('LearningGoal JSON serialization', () {
      final deadline = DateTime(2026, 10, 1);
      final goal = LearningGoal(
        goalId: 'goal123',
        childId: 'child123',
        title: 'Goal Title',
        description: 'Goal Description',
        category: LearningCategory.algorithms,
        targetAccuracy: 85.0,
        targetQuizzesCount: 75,
        deadline: deadline,
        isCompleted: false,
        createdAt: DateTime(2026, 9, 1),
      );

      final json = goal.toJson();
      final restored = LearningGoal.fromJson(json);

      expect(restored.goalId, goal.goalId);
      expect(restored.title, goal.title);
      expect(restored.targetAccuracy, goal.targetAccuracy);
      expect(restored.isCompleted, false);
    });
  });

  group('ParentAlert Tests', () {
    test('ParentAlert creation', () {
      final now = DateTime.now();
      final alert = ParentAlert(
        alertId: 'alert123',
        parentId: 'parent123',
        childId: 'child123',
        alertType: ParentAlertType.lowAccuracy,
        title: '正答率が低下しました',
        message: '正答率が70%を下回りました',
        createdAt: now,
      );

      expect(alert.title, '正答率が低下しました');
      expect(alert.isRead, false);
      expect(alert.alertType, ParentAlertType.lowAccuracy);
    });

    test('ParentAlert JSON serialization', () {
      final now = DateTime.now();
      final alert = ParentAlert(
        alertId: 'alert123',
        parentId: 'parent123',
        childId: 'child123',
        alertType: ParentAlertType.goalCompleted,
        title: 'Goal Completed',
        message: 'The goal has been completed',
        createdAt: now,
        isRead: true,
        readAt: now,
      );

      final json = alert.toJson();
      final restored = ParentAlert.fromJson(json);

      expect(restored.alertId, alert.alertId);
      expect(restored.isRead, true);
      expect(restored.alertType, ParentAlertType.goalCompleted);
    });
  });

  group('ParentAlertType Enum Tests', () {
    test('ParentAlertType has 7 values', () {
      expect(ParentAlertType.values.length, 7);
      expect(ParentAlertType.values, contains(ParentAlertType.lowAccuracy));
      expect(ParentAlertType.values, contains(ParentAlertType.streakBroken));
      expect(ParentAlertType.values, contains(ParentAlertType.goalCompleted));
      expect(ParentAlertType.values, contains(ParentAlertType.badgeEarned));
      expect(ParentAlertType.values, contains(ParentAlertType.noActivity));
      expect(ParentAlertType.values, contains(ParentAlertType.levelUp));
      expect(ParentAlertType.values, contains(ParentAlertType.weeklyReport));
    });

    test('ParentAlertType name property', () {
      expect(ParentAlertType.lowAccuracy.name, 'lowAccuracy');
      expect(ParentAlertType.streakBroken.name, 'streakBroken');
      expect(ParentAlertType.goalCompleted.name, 'goalCompleted');
    });
  });
}
