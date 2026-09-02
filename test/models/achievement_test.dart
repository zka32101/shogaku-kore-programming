import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/achievement.dart';

void main() {
  group('UnlockCondition', () {
    test('creates instance with required fields', () {
      final condition = UnlockCondition(
        conditionId: 'cond_1',
        description: 'Reach 100 XP',
        targetValue: 100,
        metricKey: 'total_xp',
      );

      expect(condition.conditionId, 'cond_1');
      expect(condition.description, 'Reach 100 XP');
      expect(condition.targetValue, 100);
      expect(condition.metricKey, 'total_xp');
      expect(condition.operator, 'greater_than');
    });

    test('converts to and from JSON', () {
      final original = UnlockCondition(
        conditionId: 'cond_streak',
        description: '7 day streak',
        targetValue: 7,
        metricKey: 'current_streak',
        operator: 'equal',
      );

      final json = original.toJson();
      final restored = UnlockCondition.fromJson(json);

      expect(restored.conditionId, original.conditionId);
      expect(restored.description, original.description);
      expect(restored.targetValue, original.targetValue);
      expect(restored.metricKey, original.metricKey);
    });
  });

  group('Achievement', () {
    test('creates instance with all fields', () {
      final conditions = [
        UnlockCondition(
          conditionId: 'cond_1',
          description: 'Reach 100 XP',
          targetValue: 100,
          metricKey: 'total_xp',
        ),
      ];

      final achievement = Achievement(
        achievementId: 'ach_xp_100',
        name: 'XP Hunter',
        description: 'Earn 100 XP',
        type: AchievementType.xp,
        rarity: AchievementRarity.common,
        iconId: 'icon_xp_100',
        xpReward: 50,
        coinReward: 25,
        conditions: conditions,
      );

      expect(achievement.achievementId, 'ach_xp_100');
      expect(achievement.name, 'XP Hunter');
      expect(achievement.type, AchievementType.xp);
      expect(achievement.rarity, AchievementRarity.common);
      expect(achievement.xpReward, 50);
      expect(achievement.coinReward, 25);
      expect(achievement.isSecret, false);
      expect(achievement.isSelfLocking, true);
    });

    test('creates secret achievement', () {
      final achievement = Achievement(
        achievementId: 'ach_secret',
        name: 'Secret Achievement',
        description: 'Hidden until unlocked',
        type: AchievementType.exploration,
        rarity: AchievementRarity.legendary,
        iconId: 'icon_secret',
        xpReward: 500,
        coinReward: 250,
        conditions: [],
        isSecret: true,
      );

      expect(achievement.isSecret, true);
    });

    test('JSON serialization preserves all data', () {
      final conditions = [
        UnlockCondition(
          conditionId: 'cond_streak',
          description: '30 day streak',
          targetValue: 30,
          metricKey: 'current_streak',
        ),
      ];

      final original = Achievement(
        achievementId: 'ach_month_master',
        name: 'Month Master',
        description: '30 day streak achieved',
        type: AchievementType.streak,
        rarity: AchievementRarity.rare,
        iconId: 'icon_month',
        xpReward: 300,
        coinReward: 150,
        conditions: conditions,
      );

      final json = original.toJson();
      final restored = Achievement.fromJson(json);

      expect(restored.achievementId, original.achievementId);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.rarity, original.rarity);
      expect(restored.conditions.length, original.conditions.length);
    });
  });

  group('UserAchievement', () {
    test('creates instance with all fields', () {
      final now = DateTime.now();
      final userAch = UserAchievement(
        achievementId: 'ach_1',
        userId: 'user123',
        unlockedAt: now,
        currentProgress: 100,
        isLocked: false,
      );

      expect(userAch.achievementId, 'ach_1');
      expect(userAch.userId, 'user123');
      expect(userAch.currentProgress, 100);
      expect(userAch.isLocked, false);
    });

    test('JSON round-trip preserves data', () {
      final now = DateTime.now();
      final original = UserAchievement(
        achievementId: 'ach_test',
        userId: 'user_test',
        unlockedAt: now,
        currentProgress: 75,
        isLocked: false,
      );

      final json = original.toJson();
      final restored = UserAchievement.fromJson(json);

      expect(restored.achievementId, original.achievementId);
      expect(restored.userId, original.userId);
      expect(restored.currentProgress, original.currentProgress);
    });
  });

  group('AchievementProgress', () {
    test('calculates progress percentage correctly', () {
      final progress = AchievementProgress(
        achievementId: 'ach_xp',
        currentProgress: 50,
        targetProgress: 100,
        isUnlocked: false,
      );

      expect(progress.progressPercentage, 50.0);
    });

    test('clamps percentage at 100', () {
      final progress = AchievementProgress(
        achievementId: 'ach_over',
        currentProgress: 150,
        targetProgress: 100,
        isUnlocked: true,
      );

      expect(progress.progressPercentage, 100.0);
    });

    test('handles zero target progress', () {
      final progress = AchievementProgress(
        achievementId: 'ach_zero',
        currentProgress: 0,
        targetProgress: 0,
        isUnlocked: true,
      );

      expect(progress.progressPercentage, 0);
    });

    test('JSON serialization works correctly', () {
      final now = DateTime.now();
      final original = AchievementProgress(
        achievementId: 'ach_test',
        currentProgress: 30,
        targetProgress: 100,
        isUnlocked: false,
      );

      final json = original.toJson();
      final restored = AchievementProgress.fromJson(json);

      expect(restored.progressPercentage, original.progressPercentage);
    });
  });

  group('AchievementStats', () {
    test('creates instance with user achievements', () {
      final now = DateTime.now();
      final userAch = UserAchievement(
        achievementId: 'ach_1',
        userId: 'user123',
        unlockedAt: now,
        isLocked: false,
      );

      final stats = AchievementStats(
        userId: 'user123',
        totalAchievements: 10,
        unlockedCount: 1,
        totalXpFromAchievements: 100,
        totalCoinsFromAchievements: 50,
        unlockedAchievements: [userAch],
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user123');
      expect(stats.unlockedCount, 1);
      expect(stats.totalXpFromAchievements, 100);
    });

    test('calculates unlocked percentage', () {
      final now = DateTime.now();
      final stats = AchievementStats(
        userId: 'user456',
        totalAchievements: 10,
        unlockedCount: 5,
        totalXpFromAchievements: 0,
        totalCoinsFromAchievements: 0,
        unlockedAchievements: [],
        lastUpdatedAt: now,
      );

      expect(stats.unlockedPercentage, 50.0);
    });

    test('JSON serialization preserves all data', () {
      final now = DateTime.now();
      final original = AchievementStats(
        userId: 'user_test',
        totalAchievements: 15,
        unlockedCount: 7,
        totalXpFromAchievements: 350,
        totalCoinsFromAchievements: 175,
        unlockedAchievements: [],
        lastUpdatedAt: now,
      );

      final json = original.toJson();
      final restored = AchievementStats.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.totalAchievements, original.totalAchievements);
      expect(restored.unlockedCount, original.unlockedCount);
      expect(restored.totalXpFromAchievements, original.totalXpFromAchievements);
    });
  });

  group('AchievementCollection', () {
    test('creates collection with achievements and stats', () {
      final now = DateTime.now();
      final achievements = [
        Achievement(
          achievementId: 'ach_1',
          name: 'Achievement 1',
          description: 'First achievement',
          type: AchievementType.milestone,
          rarity: AchievementRarity.common,
          iconId: 'icon_1',
          xpReward: 10,
          coinReward: 5,
          conditions: [],
        ),
      ];

      final stats = AchievementStats(
        userId: 'user123',
        totalAchievements: 1,
        unlockedCount: 1,
        totalXpFromAchievements: 10,
        totalCoinsFromAchievements: 5,
        unlockedAchievements: [],
        lastUpdatedAt: now,
      );

      final collection = AchievementCollection(
        allAchievements: achievements,
        stats: stats,
        generatedAt: now,
      );

      expect(collection.allAchievements.length, 1);
      expect(collection.stats.userId, 'user123');
    });

    test('getAchievement returns correct achievement', () {
      final achievements = [
        Achievement(
          achievementId: 'ach_1',
          name: 'First',
          description: 'desc',
          type: AchievementType.milestone,
          rarity: AchievementRarity.common,
          iconId: 'icon_1',
          xpReward: 10,
          coinReward: 5,
          conditions: [],
        ),
        Achievement(
          achievementId: 'ach_2',
          name: 'Second',
          description: 'desc',
          type: AchievementType.xp,
          rarity: AchievementRarity.uncommon,
          iconId: 'icon_2',
          xpReward: 20,
          coinReward: 10,
          conditions: [],
        ),
      ];

      final collection = AchievementCollection(
        allAchievements: achievements,
        stats: AchievementStats(
          userId: 'test',
          totalAchievements: 2,
          unlockedCount: 0,
          totalXpFromAchievements: 0,
          totalCoinsFromAchievements: 0,
          unlockedAchievements: [],
          lastUpdatedAt: DateTime.now(),
        ),
        generatedAt: DateTime.now(),
      );

      expect(collection.getAchievement('ach_1').name, 'First');
      expect(collection.getAchievement('ach_2').name, 'Second');
    });

    test('getByType filters achievements correctly', () {
      final achievements = [
        Achievement(
          achievementId: 'ach_xp_1',
          name: 'XP Achievement',
          description: 'desc',
          type: AchievementType.xp,
          rarity: AchievementRarity.common,
          iconId: 'icon_1',
          xpReward: 10,
          coinReward: 5,
          conditions: [],
        ),
        Achievement(
          achievementId: 'ach_streak_1',
          name: 'Streak Achievement',
          description: 'desc',
          type: AchievementType.streak,
          rarity: AchievementRarity.common,
          iconId: 'icon_2',
          xpReward: 20,
          coinReward: 10,
          conditions: [],
        ),
      ];

      final collection = AchievementCollection(
        allAchievements: achievements,
        stats: AchievementStats(
          userId: 'test',
          totalAchievements: 2,
          unlockedCount: 0,
          totalXpFromAchievements: 0,
          totalCoinsFromAchievements: 0,
          unlockedAchievements: [],
          lastUpdatedAt: DateTime.now(),
        ),
        generatedAt: DateTime.now(),
      );

      final xpAchievements = collection.getByType(AchievementType.xp);
      expect(xpAchievements.length, 1);
      expect(xpAchievements.first.achievementId, 'ach_xp_1');
    });

    test('getByRarity filters achievements correctly', () {
      final achievements = [
        Achievement(
          achievementId: 'ach_common',
          name: 'Common',
          description: 'desc',
          type: AchievementType.milestone,
          rarity: AchievementRarity.common,
          iconId: 'icon_1',
          xpReward: 10,
          coinReward: 5,
          conditions: [],
        ),
        Achievement(
          achievementId: 'ach_rare',
          name: 'Rare',
          description: 'desc',
          type: AchievementType.milestone,
          rarity: AchievementRarity.rare,
          iconId: 'icon_2',
          xpReward: 100,
          coinReward: 50,
          conditions: [],
        ),
      ];

      final collection = AchievementCollection(
        allAchievements: achievements,
        stats: AchievementStats(
          userId: 'test',
          totalAchievements: 2,
          unlockedCount: 0,
          totalXpFromAchievements: 0,
          totalCoinsFromAchievements: 0,
          unlockedAchievements: [],
          lastUpdatedAt: DateTime.now(),
        ),
        generatedAt: DateTime.now(),
      );

      final rareAchievements = collection.getByRarity(AchievementRarity.rare);
      expect(rareAchievements.length, 1);
      expect(rareAchievements.first.achievementId, 'ach_rare');
    });

    test('JSON round-trip preserves structure', () {
      final now = DateTime.now();
      final achievements = [
        Achievement(
          achievementId: 'ach_1',
          name: 'Test Achievement',
          description: 'Test description',
          type: AchievementType.milestone,
          rarity: AchievementRarity.uncommon,
          iconId: 'icon_test',
          xpReward: 50,
          coinReward: 25,
          conditions: [],
        ),
      ];

      final original = AchievementCollection(
        allAchievements: achievements,
        stats: AchievementStats(
          userId: 'test_user',
          totalAchievements: 1,
          unlockedCount: 0,
          totalXpFromAchievements: 0,
          totalCoinsFromAchievements: 0,
          unlockedAchievements: [],
          lastUpdatedAt: now,
        ),
        generatedAt: now,
      );

      final json = original.toJson();
      final restored = AchievementCollection.fromJson(json);

      expect(restored.allAchievements.length, original.allAchievements.length);
      expect(restored.stats.userId, original.stats.userId);
    });
  });
}
