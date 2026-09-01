import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/providers/badge_provider.dart';
import 'package:shogaku_kore_programming/models/badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});
  });

  group('BadgeState Tests', () {
    test('BadgeState creation with default values', () {
      const state = BadgeState();

      expect(state.badges, isEmpty);
      expect(state.badgeProgress, isEmpty);
      expect(state.unlockedBadgeIds, isEmpty);
      expect(state.lastUpdatedAt, null);
    });

    test('BadgeState creation with values', () {
      final badges = [
        Badge(
          id: 'test1',
          name: 'Badge 1',
          description: 'Test Badge 1',
          emoji: '⭐',
          category: BadgeCategory.quiz,
          difficulty: BadgeDifficulty.bronze,
          requiredValue: 10,
        ),
      ];
      final progress = {'test1': 5};
      final unlocked = ['test1'];
      final now = DateTime.now();

      final state = BadgeState(
        badges: badges,
        badgeProgress: progress,
        unlockedBadgeIds: unlocked,
        lastUpdatedAt: now,
      );

      expect(state.badges, badges);
      expect(state.badgeProgress, progress);
      expect(state.unlockedBadgeIds, unlocked);
      expect(state.lastUpdatedAt, now);
    });

    test('BadgeState copyWith', () {
      final badge1 = Badge(
        id: 'test1',
        name: 'Badge 1',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final state1 = BadgeState(
        badges: [badge1],
        badgeProgress: {'test1': 5},
        unlockedBadgeIds: [],
      );

      final state2 = state1.copyWith(
        badgeProgress: {'test1': 10},
        unlockedBadgeIds: ['test1'],
      );

      expect(state2.badges, state1.badges);
      expect(state2.badgeProgress['test1'], 10);
      expect(state2.unlockedBadgeIds, contains('test1'));
    });

    test('BadgeState toString', () {
      final state = BadgeState(
        badges: [
          Badge(
            id: 'test',
            name: 'Test',
            description: 'Test',
            emoji: '⭐',
            category: BadgeCategory.quiz,
            difficulty: BadgeDifficulty.bronze,
            requiredValue: 10,
          ),
        ],
        unlockedBadgeIds: ['test'],
      );

      expect(state.toString(), contains('1'));
    });
  });

  group('BadgeNotifier Tests', () {
    test('BadgeNotifier initializes with default badges', () async {
      final container = ProviderContainer();
      final notifier = container.read(badgeProvider.notifier);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(badgeProvider);
      expect(state.badges.isNotEmpty, true);
      expect(state.badges.length, greaterThan(0));
    });

    test('BadgeNotifier updateBadgeProgress', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(badgeProvider.notifier).updateBadgeProgress(
            'quiz_starter',
            1,
          );

      final state = container.read(badgeProvider);
      expect(state.badgeProgress['quiz_starter'], 1);
    });

    test('BadgeNotifier unlocks badge when progress reaches requirement', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // quiz_starter requires 1
      await container.read(badgeProvider.notifier).updateBadgeProgress(
            'quiz_starter',
            1,
          );

      final state = container.read(badgeProvider);
      expect(state.unlockedBadgeIds, contains('quiz_starter'));
    });

    test('BadgeNotifier incrementQuizCorrectCount', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container
          .read(badgeProvider.notifier)
          .incrementQuizCorrectCount();

      final state = container.read(badgeProvider);
      expect(state.badgeProgress['quiz_starter'], greaterThan(0));
      expect(state.badgeProgress['quiz_master_10'], greaterThan(0));
    });

    test('BadgeNotifier completeLesson', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(badgeProvider.notifier).completeLesson();

      final state = container.read(badgeProvider);
      expect(state.badgeProgress['lesson_complete_1'], greaterThan(0));
      expect(state.badgeProgress['lesson_complete_10'], greaterThan(0));
    });

    test('BadgeNotifier updateConsecutiveDays', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(badgeProvider.notifier).updateConsecutiveDays(7);

      final state = container.read(badgeProvider);
      expect(state.badgeProgress['daily_1day'], 7);
      expect(state.badgeProgress['daily_7day'], 7);
    });

    test('BadgeNotifier updateStudyHours', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(badgeProvider.notifier).updateStudyHours(100);

      final state = container.read(badgeProvider);
      expect(state.badgeProgress['milestone_100hours'], 100);
    });

    test('BadgeNotifier getBadgeProgressInfo', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(badgeProvider.notifier).updateBadgeProgress(
            'quiz_master_10',
            5,
          );

      final notifier = container.read(badgeProvider.notifier);
      final progressInfo =
          notifier.getBadgeProgressInfo('quiz_master_10');

      expect(progressInfo.currentValue, 5);
      expect(progressInfo.badge.requiredValue, 10);
      expect(progressInfo.remainingValue, 5);
      expect(progressInfo.canUnlock, false);
    });

    test('BadgeNotifier getBadgesByCategory', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(badgeProvider.notifier);
      final quizBadges =
          notifier.getBadgesByCategory(BadgeCategory.quiz);

      expect(quizBadges.isNotEmpty, true);
      expect(
        quizBadges.every((b) => b.badge.category == BadgeCategory.quiz),
        true,
      );
    });

    test('BadgeNotifier getUnlockedBadges', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(badgeProvider.notifier);

      // Unlock a badge
      await notifier.unlockBadge('quiz_starter');

      final unlockedBadges = notifier.getUnlockedBadges();
      expect(
        unlockedBadges.any((b) => b.badge.id == 'quiz_starter'),
        true,
      );
    });

    test('BadgeNotifier getInProgressBadges', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(badgeProvider.notifier);

      // Add some progress
      await notifier.updateBadgeProgress('quiz_master_10', 5);

      final inProgressBadges = notifier.getInProgressBadges();
      expect(
        inProgressBadges.any((b) => b.badge.id == 'quiz_master_10'),
        true,
      );
    });

    test('BadgeNotifier unlockBadge directly', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(badgeProvider.notifier);
      await notifier.unlockBadge('quiz_master_100');

      final state = container.read(badgeProvider);
      expect(state.unlockedBadgeIds, contains('quiz_master_100'));

      final badge =
          state.badges.firstWhere((b) => b.id == 'quiz_master_100');
      expect(badge.isUnlocked, true);
    });

    test('BadgeNotifier prevents duplicate unlocks', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(badgeProvider.notifier);
      await notifier.unlockBadge('quiz_starter');
      await notifier.unlockBadge('quiz_starter'); // Try to unlock again

      final state = container.read(badgeProvider);
      final unlockedCount = state.unlockedBadgeIds
          .where((id) => id == 'quiz_starter')
          .length;
      expect(unlockedCount, 1);
    });
  });

  group('BadgeProgressInfo Tests', () {
    test('BadgeProgressInfo creation', () {
      final badge = Badge(
        id: 'test',
        name: 'Test Badge',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final info = BadgeProgressInfo(
        badge: badge,
        currentValue: 5,
        remainingValue: 5,
        progressPercentage: 50,
        isUnlocked: false,
        canUnlock: false,
      );

      expect(info.badge, badge);
      expect(info.currentValue, 5);
      expect(info.remainingValue, 5);
      expect(info.progressPercentage, 50);
      expect(info.isUnlocked, false);
      expect(info.canUnlock, false);
    });

    test('BadgeProgressInfo toString', () {
      final badge = Badge(
        id: 'test',
        name: 'Test Badge',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final info = BadgeProgressInfo(
        badge: badge,
        currentValue: 7,
        remainingValue: 3,
        progressPercentage: 70,
        isUnlocked: false,
        canUnlock: false,
      );

      expect(info.toString(), contains('Test Badge'));
      expect(info.toString(), contains('7/10'));
    });
  });
}
