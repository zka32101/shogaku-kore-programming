import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/level.dart';

void main() {
  group('Level Model Tests', () {
    test('Level creation with required parameters', () {
      final level = Level(
        levelNumber: 1,
        title: 'Beginner 1',
        description: 'First level',
        requiredXp: 100,
        rewardCoins: 50,
        rewardXp: 25,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      expect(level.levelNumber, 1);
      expect(level.title, 'Beginner 1');
      expect(level.description, 'First level');
      expect(level.requiredXp, 100);
      expect(level.rewardCoins, 50);
      expect(level.rewardXp, 25);
      expect(level.tier, LevelTier.beginner);
      expect(level.emoji, '🌱');
      expect(level.rewardBadgeId, null);
    });

    test('Level creation with badge reward', () {
      final level = Level(
        levelNumber: 10,
        title: 'Beginner Master',
        description: 'Mastered beginner levels',
        requiredXp: 2000,
        rewardCoins: 200,
        rewardXp: 100,
        tier: LevelTier.beginner,
        emoji: '🌳',
        rewardBadgeId: 'beginner_master',
      );

      expect(level.rewardBadgeId, 'beginner_master');
    });

    test('Level JSON serialization', () {
      final level = Level(
        levelNumber: 1,
        title: 'Beginner 1',
        description: 'First level',
        requiredXp: 100,
        rewardCoins: 50,
        rewardXp: 25,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      final json = level.toJson();

      expect(json['levelNumber'], 1);
      expect(json['title'], 'Beginner 1');
      expect(json['description'], 'First level');
      expect(json['requiredXp'], 100);
      expect(json['rewardCoins'], 50);
      expect(json['rewardXp'], 25);
      expect(json['tier'], 'beginner');
      expect(json['emoji'], '🌱');
    });

    test('Level JSON deserialization', () {
      final json = {
        'levelNumber': 1,
        'title': 'Beginner 1',
        'description': 'First level',
        'requiredXp': 100,
        'rewardCoins': 50,
        'rewardXp': 25,
        'tier': 'beginner',
        'emoji': '🌱',
        'rewardBadgeId': null,
      };

      final level = Level.fromJson(json);

      expect(level.levelNumber, 1);
      expect(level.title, 'Beginner 1');
      expect(level.tier, LevelTier.beginner);
    });

    test('Level equality based on levelNumber', () {
      final level1 = Level(
        levelNumber: 1,
        title: 'Title 1',
        description: 'Desc 1',
        requiredXp: 100,
        rewardCoins: 50,
        rewardXp: 25,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      final level2 = Level(
        levelNumber: 1,
        title: 'Title 2',
        description: 'Desc 2',
        requiredXp: 150,
        rewardCoins: 60,
        rewardXp: 30,
        tier: LevelTier.intermediate,
        emoji: '🌿',
      );

      final level3 = Level(
        levelNumber: 2,
        title: 'Title 1',
        description: 'Desc 1',
        requiredXp: 100,
        rewardCoins: 50,
        rewardXp: 25,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      expect(level1, level2); // Same level number
      expect(level1, isNot(level3)); // Different level number
    });
  });

  group('LevelTier Enum Tests', () {
    test('LevelTier has 4 values', () {
      expect(LevelTier.values.length, 4);
      expect(LevelTier.values, contains(LevelTier.beginner));
      expect(LevelTier.values, contains(LevelTier.intermediate));
      expect(LevelTier.values, contains(LevelTier.advanced));
      expect(LevelTier.values, contains(LevelTier.expert));
    });

    test('LevelTier name property', () {
      expect(LevelTier.beginner.name, 'beginner');
      expect(LevelTier.intermediate.name, 'intermediate');
      expect(LevelTier.advanced.name, 'advanced');
      expect(LevelTier.expert.name, 'expert');
    });
  });

  group('UserLevelProgress Tests', () {
    test('UserLevelProgress creation', () {
      final level = Level(
        levelNumber: 5,
        title: 'Beginner 5',
        description: 'Test',
        requiredXp: 500,
        rewardCoins: 100,
        rewardXp: 50,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      final progress = UserLevelProgress(
        level: level,
        currentXp: 150,
        totalXpEarned: 650,
        progress: 50.0,
      );

      expect(progress.level, level);
      expect(progress.currentXp, 150);
      expect(progress.totalXpEarned, 650);
      expect(progress.progress, 50.0);
    });

    test('UserLevelProgress remainingXp calculation', () {
      final level = Level(
        levelNumber: 1,
        title: 'Beginner 1',
        description: 'Test',
        requiredXp: 100,
        rewardCoins: 50,
        rewardXp: 25,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      // Level 1 requires 100 XP, Level 2 requires ~115 XP
      final progress1 = UserLevelProgress(
        level: level,
        currentXp: 50,
        totalXpEarned: 150,
        progress: 50.0,
      );

      final progress2 = UserLevelProgress(
        level: level,
        currentXp: 115,
        totalXpEarned: 215,
        progress: 100.0,
      );

      expect(progress1.remainingXp, greaterThan(0));
      expect(progress2.remainingXp, equals(0));
    });

    test('UserLevelProgress canLevelUp property', () {
      final level = Level(
        levelNumber: 1,
        title: 'Beginner 1',
        description: 'Test',
        requiredXp: 100,
        rewardCoins: 50,
        rewardXp: 25,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      final notReady = UserLevelProgress(
        level: level,
        currentXp: 50,
        totalXpEarned: 150,
        progress: 50.0,
      );

      final ready = UserLevelProgress(
        level: level,
        currentXp: 115,
        totalXpEarned: 215,
        progress: 100.0,
      );

      expect(notReady.canLevelUp, false);
      expect(ready.canLevelUp, true);
    });
  });

  group('LevelUpEvent Tests', () {
    test('LevelUpEvent creation', () {
      final level = Level(
        levelNumber: 2,
        title: 'Beginner 2',
        description: 'Test',
        requiredXp: 115,
        rewardCoins: 60,
        rewardXp: 30,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      final timestamp = DateTime.now();
      final event = LevelUpEvent(
        oldLevel: 1,
        newLevel: 2,
        levelData: level,
        timestamp: timestamp,
        coinsReward: 60,
        xpBonus: 30,
      );

      expect(event.oldLevel, 1);
      expect(event.newLevel, 2);
      expect(event.levelData, level);
      expect(event.timestamp, timestamp);
      expect(event.coinsReward, 60);
      expect(event.xpBonus, 30);
    });

    test('LevelUpEvent toString', () {
      final level = Level(
        levelNumber: 2,
        title: 'Beginner 2',
        description: 'Test',
        requiredXp: 115,
        rewardCoins: 60,
        rewardXp: 30,
        tier: LevelTier.beginner,
        emoji: '🌱',
      );

      final event = LevelUpEvent(
        oldLevel: 1,
        newLevel: 2,
        levelData: level,
        timestamp: DateTime.now(),
        coinsReward: 60,
        xpBonus: 30,
      );

      final str = event.toString();
      expect(str, contains('LevelUpEvent'));
      expect(str, contains('1'));
      expect(str, contains('2'));
    });
  });

  group('DefaultLevels Tests', () {
    test('generateLevels creates 50 levels', () {
      final levels = DefaultLevels.generateLevels();
      expect(levels.length, 50);
    });

    test('Generated levels have correct structure', () {
      final levels = DefaultLevels.generateLevels();

      expect(levels[0].levelNumber, 1);
      expect(levels[9].levelNumber, 10);
      expect(levels[24].levelNumber, 25);
      expect(levels[39].levelNumber, 40);
      expect(levels[49].levelNumber, 50);
    });

    test('Generated levels increase in difficulty', () {
      final levels = DefaultLevels.generateLevels();

      for (int i = 0; i < levels.length - 1; i++) {
        expect(
          levels[i + 1].requiredXp,
          greaterThan(levels[i].requiredXp),
          reason:
              'Level ${i + 2} XP should be > Level ${i + 1} XP',
        );
      }
    });

    test('getLevelByNumber returns correct level', () {
      final level = DefaultLevels.getLevelByNumber(1);
      expect(level, isNotNull);
      expect(level!.levelNumber, 1);

      final level50 = DefaultLevels.getLevelByNumber(50);
      expect(level50, isNotNull);
      expect(level50!.levelNumber, 50);

      final invalid = DefaultLevels.getLevelByNumber(51);
      expect(invalid, isNull);
    });

    test('getLevelFromTotalXp returns correct level', () {
      final level1 = DefaultLevels.getLevelFromTotalXp(50);
      expect(level1, 1);

      final level2 = DefaultLevels.getLevelFromTotalXp(150);
      expect(level2, 2);

      final level50 = DefaultLevels.getLevelFromTotalXp(1000000);
      expect(level50, 50);
    });

    test('Milestone badges are defined at specific levels', () {
      final level10 = DefaultLevels.getLevelByNumber(10);
      expect(level10!.rewardBadgeId, 'beginner_master');

      final level25 = DefaultLevels.getLevelByNumber(25);
      expect(level25!.rewardBadgeId, 'intermediate_master');

      final level40 = DefaultLevels.getLevelByNumber(40);
      expect(level40!.rewardBadgeId, 'advanced_master');

      final level50 = DefaultLevels.getLevelByNumber(50);
      expect(level50!.rewardBadgeId, 'ultimate_master');
    });

    test('Levels are grouped by tier', () {
      final beginnerLevels = DefaultLevels.allLevels
          .where((l) => l.tier == LevelTier.beginner)
          .toList();
      expect(beginnerLevels.length, 10);
      expect(beginnerLevels.every((l) => l.emoji == '🌱'), true);

      final intermediateLevels = DefaultLevels.allLevels
          .where((l) => l.tier == LevelTier.intermediate)
          .toList();
      expect(intermediateLevels.length, 15);
      expect(intermediateLevels.every((l) => l.emoji == '🌿'), true);

      final advancedLevels = DefaultLevels.allLevels
          .where((l) => l.tier == LevelTier.advanced)
          .toList();
      expect(advancedLevels.length, 15);
      expect(advancedLevels.every((l) => l.emoji == '🌳'), true);

      final expertLevels = DefaultLevels.allLevels
          .where((l) => l.tier == LevelTier.expert)
          .toList();
      expect(expertLevels.length, 10);
      expect(expertLevels.every((l) => l.emoji == '🏆'), true);
    });

    test('Rewards increase with level tier', () {
      final level1 = DefaultLevels.getLevelByNumber(1)!;
      final level10 = DefaultLevels.getLevelByNumber(10)!;
      final level25 = DefaultLevels.getLevelByNumber(25)!;
      final level50 = DefaultLevels.getLevelByNumber(50)!;

      expect(level10.rewardCoins, greaterThan(level1.rewardCoins));
      expect(level25.rewardCoins, greaterThan(level10.rewardCoins));
      expect(level50.rewardCoins, greaterThan(level25.rewardCoins));
    });
  });
}
