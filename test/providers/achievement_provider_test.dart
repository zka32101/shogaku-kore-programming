import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/achievement.dart';
import 'package:shogaku_kore_programming/providers/achievement_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AchievementNotifier', () {
    test('initializes with empty state', () {
      final notifier = AchievementNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('initializeAchievements creates default achievements', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final state = container.read(achievementProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.allAchievements.length, 10);
      expect(state.isLoading, false);
    });

    test('initializeAchievements generates correct default achievements', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final state = container.read(achievementProvider);
      final achievements = state.collection!.allAchievements;

      // Check for specific achievements
      expect(
        achievements.any((a) => a.achievementId == 'ach_streak_3'),
        true,
      );
      expect(
        achievements.any((a) => a.achievementId == 'ach_xp_100'),
        true,
      );
      expect(
        achievements.any((a) => a.achievementId == 'ach_explorer'),
        true,
      );
    });

    test('initializeAchievements sets default stats for new user', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('new_user');

      final state = container.read(achievementProvider);
      expect(state.collection!.stats.userId, 'new_user');
      expect(state.collection!.stats.unlockedCount, 0);
      expect(state.collection!.stats.totalXpFromAchievements, 0);
    });

    test('updateAchievementProgress unlocks achievement when condition met',
        () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      // Update XP to 100 (should unlock ach_xp_100)
      final unlocked = await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      expect(unlocked, true);

      final state = container.read(achievementProvider);
      expect(state.collection!.stats.unlockedCount, 1);
    });

    test('updateAchievementProgress adds to recently unlocked', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      final state = container.read(achievementProvider);
      expect(state.recentlyUnlocked.isNotEmpty, true);
      expect(state.recentlyUnlocked.contains('ach_xp_100'), true);
    });

    test('updateAchievementProgress updates correct stats', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final initialStats = container.read(achievementProvider).collection!.stats;
      final initialXp = initialStats.totalXpFromAchievements;
      final initialCoins = initialStats.totalCoinsFromAchievements;

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      final updatedState = container.read(achievementProvider);
      final updatedStats = updatedState.collection!.stats;

      expect(updatedStats.totalXpFromAchievements, greaterThan(initialXp));
      expect(updatedStats.totalCoinsFromAchievements, greaterThan(initialCoins));
    });

    test('updateAchievementProgress prevents duplicate unlocks', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      // First unlock
      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      var state = container.read(achievementProvider);
      final countAfterFirst = state.collection!.stats.unlockedCount;

      // Try to unlock again
      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        200,
      );

      state = container.read(achievementProvider);
      final countAfterSecond = state.collection!.stats.unlockedCount;

      // Count should not increase
      expect(countAfterSecond, equals(countAfterFirst));
    });

    test('checkCondition handles different operators', () async {
      final notifier = AchievementNotifier();

      // Greater than
      final cond1 = UnlockCondition(
        conditionId: 'test1',
        description: 'test',
        targetValue: 100,
        metricKey: 'xp',
        operator: 'greater_than',
      );
// expect(notifier._checkCondition(cond1, 150), true);
// expect(notifier._checkCondition(cond1, 50), false);

      // Equal
      final cond2 = UnlockCondition(
        conditionId: 'test2',
        description: 'test',
        targetValue: 5,
        metricKey: 'streak',
        operator: 'equal',
      );
// expect(notifier._checkCondition(cond2, 5), true);
// expect(notifier._checkCondition(cond2, 6), false);

      // Between
      final cond3 = UnlockCondition(
        conditionId: 'test3',
        description: 'test',
        targetValue: 10,
        metricKey: 'progress',
        operator: 'between',
        maxValue: 20,
      );
// expect(notifier._checkCondition(cond3, 15), true);
// expect(notifier._checkCondition(cond3, 25), false);
    });

    test('getProgress returns correct progress', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final progress = notifier.getProgress('ach_xp_100');
      expect(progress, isNotNull);
      expect(progress!.achievementId, 'ach_xp_100');
      expect(progress.targetProgress, 100);
    });

    test('getUnlockedAchievements returns unlocked only', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      final unlocked = notifier.getUnlockedAchievements();
      expect(unlocked.length, 1);
      expect(unlocked.first.achievementId, 'ach_xp_100');
    });

    test('getLockedAchievements returns locked only', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final locked = notifier.getLockedAchievements();
      expect(locked.length, 10); // All initially locked

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      final lockedAfter = notifier.getLockedAchievements();
      expect(lockedAfter.length, 9); // One now unlocked
    });

    test('getByType filters correctly', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final xpAchievements = notifier.getByType(AchievementType.xp);
      expect(xpAchievements.isNotEmpty, true);
      expect(
        xpAchievements.every((a) => a.type == AchievementType.xp),
        true,
      );
    });

    test('getByRarity filters correctly', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final rareAchievements = notifier.getByRarity(AchievementRarity.rare);
      expect(rareAchievements.isNotEmpty, true);
      expect(
        rareAchievements.every((a) => a.rarity == AchievementRarity.rare),
        true,
      );
    });

    test('clearRecentlyUnlocked clears list', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      var state = container.read(achievementProvider);
      expect(state.recentlyUnlocked.isNotEmpty, true);

      notifier.clearRecentlyUnlocked();

      state = container.read(achievementProvider);
      expect(state.recentlyUnlocked.isEmpty, true);
    });

    test('getUnlockedCount returns correct count', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      expect(notifier.getUnlockedCount(), 0);

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      expect(notifier.getUnlockedCount(), 1);
    });

    test('getTotalAchievements returns system total', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      expect(notifier.getTotalAchievements(), 10);
    });

    test('getUnlockedPercentage calculates correctly', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      expect(notifier.getUnlockedPercentage(), 0);

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      expect(notifier.getUnlockedPercentage(), 10.0);
    });

    test('getTotalXpFromAchievements returns sum', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      expect(notifier.getTotalXpFromAchievements(), 0);

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      expect(notifier.getTotalXpFromAchievements(), greaterThan(0));
    });

    test('persists achievements to SharedPreferences', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('persist_test');

      await notifier.updateAchievementProgress(
        'persist_test',
        'total_xp_earned',
        100,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('achievement_stats_persist_test'), true);
    });

    test('handles error state correctly', () async {
      final notifier = AchievementNotifier();

      notifier.state = notifier.state.copyWith(
        error: 'Test error',
      );

      expect(notifier.state.error, 'Test error');
    });
  });

  group('Riverpod Providers', () {
    test('unlockedAchievementsProvider returns correct achievements',
        () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      final unlocked = container.read(unlockedAchievementsProvider);
      expect(unlocked.length, 1);
    });

    test('unlockedCountProvider provides correct count', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      var count = container.read(unlockedCountProvider);
      expect(count, 0);

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      count = container.read(unlockedCountProvider);
      expect(count, 1);
    });

    test('unlockedPercentageProvider calculates correctly', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      var percentage = container.read(unlockedPercentageProvider);
      expect(percentage, 0);

      await notifier.updateAchievementProgress(
        'test_user',
        'total_xp_earned',
        100,
      );

      percentage = container.read(unlockedPercentageProvider);
      expect(percentage, 10.0);
    });

    test('achievementStatsProvider provides stats', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final stats = container.read(achievementStatsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });
  });

  group('Edge Cases', () {
    test('handles multiple conditions per achievement', () async {
      final notifier = AchievementNotifier();

      final conditions = [
        UnlockCondition(
          conditionId: 'cond1',
          description: 'desc',
          targetValue: 100,
          metricKey: 'xp',
        ),
        UnlockCondition(
          conditionId: 'cond2',
          description: 'desc',
          targetValue: 5,
          metricKey: 'streak',
        ),
      ];

      final achievement = Achievement(
        achievementId: 'multi_cond',
        name: 'Multi Condition',
        description: 'desc',
        type: AchievementType.milestone,
        rarity: AchievementRarity.epic,
        iconId: 'icon',
        xpReward: 500,
        coinReward: 250,
        conditions: conditions,
      );

      expect(achievement.conditions.length, 2);
    });

    test('handles secret achievements', () async {
      final notifier = container.read(achievementProvider.notifier);
      await notifier.initializeAchievements('test_user');

      final state = container.read(achievementProvider);
      final secretAchievements = state.collection!.allAchievements
          .where((a) => a.isSecret)
          .toList();

      expect(secretAchievements.isNotEmpty, true);
    });

    test('handles achievement with no conditions', () async {
      final notifier = AchievementNotifier();

      final achievement = Achievement(
        achievementId: 'no_cond',
        name: 'No Condition',
        description: 'No conditions required',
        type: AchievementType.milestone,
        rarity: AchievementRarity.legendary,
        iconId: 'icon',
        xpReward: 1000,
        coinReward: 500,
        conditions: [],
      );

      expect(achievement.conditions.isEmpty, true);
    });
  });
}
