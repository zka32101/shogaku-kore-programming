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
          icon: '⭐',
          name: 'Badge 1',
          description: 'Test Badge 1',
          category: 'quiz',
          isUnlocked: false,
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
        icon: '⭐',
        name: 'Badge 1',
        description: 'Test',
        category: 'quiz',
        isUnlocked: false,
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
            icon: '⭐',
            name: 'Test',
            description: 'Test',
            category: 'quiz',
            isUnlocked: false,
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

    test('BadgeNotifier unlockBadge directly', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(badgeProvider.notifier);
      await notifier.unlockBadge('quiz_master_100');

      final state = container.read(badgeProvider);
      expect(state.unlockedBadgeIds, contains('quiz_master_100'));

      final badge =
          state.badges.firstWhere((b) => b.icon.isNotEmpty);
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
}
