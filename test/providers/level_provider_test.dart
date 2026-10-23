import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/models/level.dart';
import 'package:shogaku_kore_programming/providers/level_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LevelState Tests', () {
    test('LevelState creation with default values', () {
      const state = LevelState();

      expect(state.currentLevel, 1);
      expect(state.totalXpEarned, 0);
      expect(state.lastLevelUpDate, null);
      expect(state.milestoneReached, isEmpty);
      expect(state.lastLevelUpEvent, null);
    });

    test('LevelState copyWith', () {
      const state1 = LevelState(
        currentLevel: 1,
        totalXpEarned: 500,
      );

      final state2 = state1.copyWith(
        currentLevel: 2,
        totalXpEarned: 1000,
      );

      expect(state2.currentLevel, 2);
      expect(state2.totalXpEarned, 1000);
    });
  });

  group('LevelNotifier Tests', () {
    test('LevelNotifier initializes with level 1', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(levelProvider);
      expect(state.currentLevel, 1);
      expect(state.totalXpEarned, 0);
    });

    test('LevelNotifier addExperience increments total XP', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);
      final events = await notifier.addExperience(50);

      final state = container.read(levelProvider);
      expect(state.totalXpEarned, 50);
      expect(events, isEmpty); // No level-up yet
    });

    test('LevelNotifier detects level-up when XP crosses threshold', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // Add enough XP to level up multiple times
      // Level 1 requires 100, Level 2 ~115, Level 3 ~132
      final events = await notifier.addExperience(250);

      final state = container.read(levelProvider);
      expect(state.currentLevel, greaterThan(1));
      expect(events, isNotEmpty);
      expect(events.first.newLevel, greaterThan(events.first.oldLevel));
    });

    test('LevelNotifier multiple level-ups in one call', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // Add enough XP to reach level 5 or higher
      final events = await notifier.addExperience(2000);

      expect(events.length, greaterThan(1));
      for (int i = 1; i < events.length; i++) {
        expect(
          events[i].newLevel,
          equals(events[i - 1].newLevel + 1),
          reason: 'Levels should be sequential',
        );
      }
    });

    test('LevelNotifier getLevelProgress returns correct data', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);
      await notifier.addExperience(150);

      final progress = notifier.getLevelProgress();

      expect(progress.level, isNotNull);
      expect(progress.currentXp, greaterThanOrEqualTo(0));
      expect(progress.totalXpEarned, 150);
      expect(progress.progress, greaterThanOrEqualTo(0.0));
      expect(progress.progress, lessThanOrEqualTo(100.0));
    });

    test('LevelNotifier getXpToNextLevel', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);
      final xpNeeded = notifier.getXpToNextLevel();

      // レベル1(0XP) → レベル2 の累積XPまでが必要量
      expect(xpNeeded, greaterThan(0));
      expect(xpNeeded, lessThanOrEqualTo(DefaultLevels.getLevelByNumber(2)!.requiredXp));
    });

    test('LevelNotifier getMilestoneStatus tracks achievements', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // レベル10の累積XPは約2026(レベル11は約2430)
      await notifier.addExperience(2100);

      final milestones = notifier.getMilestoneStatus();

      expect(milestones[10], true);
      expect(milestones[25], false);
      expect(milestones[40], false);
      expect(milestones[50], false);
    });

    test('LevelNotifier canLevelUp property', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      var canLevel = notifier.canLevelUp();
      expect(canLevel, false);

      // 次のレベルに必要なXPを加えると、その場でレベルアップが確定する
      // （レベルが上がった後は、さらに次のレベルまで未到達なので canLevelUp は false）
      final progress = notifier.getLevelProgress();
      final events = await notifier.addExperience(progress.remainingXp);

      expect(events.length, 1);
      expect(container.read(levelProvider).currentLevel, 2);
      expect(notifier.canLevelUp(), false);
    });

    test('LevelNotifier getStats returns complete information', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);
      await notifier.addExperience(500);

      final stats = notifier.getStats();

      expect(stats['currentLevel'], isNotNull);
      expect(stats['totalXpEarned'], 500);
      expect(stats['currentLevelXp'], isNotNull);
      expect(stats['nextLevelXp'], isNotNull);
      expect(stats['progressPercentage'], isNotNull);
      expect(stats['maxLevel'], 50);
    });

    test('LevelNotifier persists data to SharedPreferences', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);
      await notifier.addExperience(500);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('user_level'), isNotNull);
      expect(prefs.getInt('user_total_xp'), 500);
    });

    test('LevelNotifier handles max level (level 50)', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // Add a huge amount of XP to reach level 50
      await notifier.addExperience(1000000);

      final state = container.read(levelProvider);
      expect(state.currentLevel, 50);
    });

    test('LevelUpEvent contains correct reward data', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);
      final events = await notifier.addExperience(200);

      if (events.isNotEmpty) {
        final event = events.first;
        expect(event.coinsReward, greaterThan(0));
        expect(event.xpBonus, greaterThan(0));
        expect(event.levelData, isNotNull);
      }
    });
  });

  group('Level Progression Tests', () {
    test('Progression from level 1 to 2', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // レベル2の累積XPは約214（レベル3は約346）
      final events = await notifier.addExperience(220);

      final state = container.read(levelProvider);
      expect(state.currentLevel, 2);
      expect(events.length, 1);
      expect(events[0].newLevel, 2);
    });

    test('Progressive XP accumulation', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // Add XP in multiple batches
      await notifier.addExperience(50);
      var state = container.read(levelProvider);
      expect(state.totalXpEarned, 50);

      await notifier.addExperience(60);
      state = container.read(levelProvider);
      expect(state.totalXpEarned, 110);
    });
  });

  group('Milestone Tracking Tests', () {
    test('Milestone at level 10', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // レベル10の累積XPは約2026
      await notifier.addExperience(2100);

      final state = container.read(levelProvider);
      expect(state.milestoneReached, contains(10));
    });

    test('Milestones persist across multiple calls', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // Reach level 10 (約2026 XP)
      await notifier.addExperience(2100);
      var state = container.read(levelProvider);
      expect(state.milestoneReached, contains(10));

      // Add more XP but don't level up
      await notifier.addExperience(100);
      state = container.read(levelProvider);
      expect(state.milestoneReached, contains(10)); // Milestone still there
    });

    test('Multiple milestones tracked correctly', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(levelProvider.notifier);

      // Add enough XP to reach level 50
      await notifier.addExperience(1000000);

      final state = container.read(levelProvider);
      expect(state.milestoneReached, contains(10));
      expect(state.milestoneReached, contains(25));
      expect(state.milestoneReached, contains(40));
      expect(state.milestoneReached, contains(50));
    });
  });
}
