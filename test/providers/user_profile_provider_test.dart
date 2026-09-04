import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/user_profile.dart';
import 'package:shogaku_kore_programming/providers/user_profile_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('UserProfileNotifier', () {
    test('initializes with empty state', () {
      final notifier = UserProfileNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeProfile creates profile', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final state = container.read(userProfileProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
      expect(state.collection!.profile.username, 'testuser');
    });

    test('initializeProfile creates default statistics', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final state = container.read(userProfileProvider);
      expect(state.collection!.statistics.userId, 'test_user');
      expect(state.collection!.statistics.totalLessonsTaken, 0);
    });

    test('initializeProfile creates milestones', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final state = container.read(userProfileProvider);
      expect(state.collection!.milestones.isNotEmpty, true);
    });

    test('updateProfile changes profile information', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      expect(state.collection!.profile.bioDescription, isNull);

      await notifier.updateProfile(
        userId: 'test_user',
        displayName: 'Test Display',
        bioDescription: 'My bio',
      );

      state = container.read(userProfileProvider);
      expect(state.collection!.profile.displayName, 'Test Display');
      expect(state.collection!.profile.bioDescription, 'My bio');
    });

    test('updateProfile changes visibility', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.updateProfile(
        userId: 'test_user',
        visibility: ProfileVisibility.private,
      );

      final state = container.read(userProfileProvider);
      expect(state.collection!.profile.visibility, ProfileVisibility.private);
    });

    test('addXp increments total XP', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      expect(state.collection!.profile.totalXp, 0);

      await notifier.addXp('test_user', 100);

      state = container.read(userProfileProvider);
      expect(state.collection!.profile.totalXp, 100);
    });

    test('addXp levels up when threshold reached', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      expect(state.collection!.profile.currentLevel, 1);

      await notifier.addXp('test_user', 200);

      state = container.read(userProfileProvider);
      expect(state.collection!.profile.currentLevel, greaterThan(1));
    });

    test('addXp unlocks milestones', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      final milestonesUnlockedBefore = state.collection!.milestones.where((m) => m.isUnlocked).length;

      await notifier.addXp('test_user', 600);

      state = container.read(userProfileProvider);
      final milestonesUnlockedAfter = state.collection!.milestones.where((m) => m.isUnlocked).length;

      expect(milestonesUnlockedAfter, greaterThan(milestonesUnlockedBefore));
    });

    test('addCoins increments coin count', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      expect(state.collection!.profile.coins, 0);

      await notifier.addCoins('test_user', 50);

      state = container.read(userProfileProvider);
      expect(state.collection!.profile.coins, 50);
    });

    test('addPremiumCurrency increments premium currency', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      expect(state.collection!.profile.premiumCurrency, 0);

      await notifier.addPremiumCurrency('test_user', 10);

      state = container.read(userProfileProvider);
      expect(state.collection!.profile.premiumCurrency, 10);
    });

    test('unlockAchievement creates new achievement', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final success = await notifier.unlockAchievement(
        'test_user',
        'ach1',
        'アチーブメント',
        '説明',
        rarity: 5,
      );

      expect(success, true);

      final state = container.read(userProfileProvider);
      expect(state.collection!.achievements.length, 1);
      expect(state.collection!.achievements[0].achievementId, 'ach1');
    });

    test('unlockAchievement increments achievement count', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      expect(state.collection!.statistics.totalAchievementsUnlocked, 0);

      await notifier.unlockAchievement(
        'test_user',
        'ach1',
        'Achievement 1',
        'Description',
      );

      state = container.read(userProfileProvider);
      expect(state.collection!.statistics.totalAchievementsUnlocked, 1);
    });

    test('unlockAchievement does not duplicate', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');
      var state = container.read(userProfileProvider);
      expect(state.collection!.achievements.length, 1);

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');
      state = container.read(userProfileProvider);
      expect(state.collection!.achievements.length, 1);
    });

    test('featureAchievement adds to featured list', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');

      var state = container.read(userProfileProvider);
      expect(state.collection!.featuredAchievements.isEmpty, true);

      await notifier.featureAchievement('test_user', 'ach1');

      state = container.read(userProfileProvider);
      expect(state.collection!.featuredAchievements.length, 1);
      expect(state.collection!.featuredAchievements[0].achievementId, 'ach1');
    });

    test('featureAchievement respects max 5 limit', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      for (int i = 1; i <= 7; i++) {
        await notifier.unlockAchievement('test_user', 'ach$i', 'Achievement $i', 'Description');
        await notifier.featureAchievement('test_user', 'ach$i');
      }

      final state = container.read(userProfileProvider);
      expect(state.collection!.featuredAchievements.length, 5);
    });

    test('updateStatistics modifies statistics', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var state = container.read(userProfileProvider);
      expect(state.collection!.statistics.totalLessonsTaken, 0);

      await notifier.updateStatistics(
        'test_user',
        lessonsTaken: 50,
        lessonsCompleted: 40,
        minutesLearned: 300,
      );

      state = container.read(userProfileProvider);
      expect(state.collection!.statistics.totalLessonsTaken, 50);
      expect(state.collection!.statistics.totalLessonsCompleted, 40);
    });

    test('updateStatistics tracks longest streak', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.updateStatistics(
        'test_user',
        currentStreak: 5,
      );

      var state = container.read(userProfileProvider);
      expect(state.collection!.statistics.longestStreak, 5);

      await notifier.updateStatistics(
        'test_user',
        currentStreak: 3,
      );

      state = container.read(userProfileProvider);
      expect(state.collection!.statistics.longestStreak, 5);
    });

    test('getTotalAchievements returns correct count', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      expect(notifier.getTotalAchievements(), 0);

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');

      expect(notifier.getTotalAchievements(), 1);
    });

    test('getUnlockedAchievements returns only unlocked', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');

      expect(notifier.getUnlockedAchievements(), 1);
    });

    test('getUserRank returns correct rank', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      expect(notifier.getUserRank(), UserRank.beginner);
    });

    test('getEngagementScore calculates correctly', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.updateStatistics(
        'test_user',
        lessonsTaken: 100,
      );

      expect(notifier.getEngagementScore(), greaterThan(0));
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('persist_test', 'testuser');

      await notifier.updateProfile(
        userId: 'persist_test',
        bioDescription: 'Test bio',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('user_profile_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('userProfileCollectionProvider provides collection', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final collection = container.read(userProfileCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('userProfileProvider_profile provides profile', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final profile = container.read(userProfileProvider_profile);
      expect(profile, isNotNull);
      expect(profile!.username, 'testuser');
    });

    test('userStatisticsProvider provides statistics', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final stats = container.read(userStatisticsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('userAchievementsProvider provides achievements', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var achievements = container.read(userAchievementsProvider);
      expect(achievements.isEmpty, true);

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');

      achievements = container.read(userAchievementsProvider);
      expect(achievements.length, 1);
    });

    test('userFeaturedAchievementsProvider provides featured', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var featured = container.read(userFeaturedAchievementsProvider);
      expect(featured.isEmpty, true);

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');
      await notifier.featureAchievement('test_user', 'ach1');

      featured = container.read(userFeaturedAchievementsProvider);
      expect(featured.length, 1);
    });

    test('userLevelMilestonesProvider provides milestones', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final milestones = container.read(userLevelMilestonesProvider);
      expect(milestones.isNotEmpty, true);
    });

    test('unlockedAchievementsProvider filters unlocked', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.unlockAchievement('test_user', 'ach1', 'Achievement', 'Description');

      final unlocked = container.read(unlockedAchievementsProvider);
      expect(unlocked.length, 1);
    });

    test('userRankProvider provides rank', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final rank = container.read(userRankProvider);
      expect(rank, UserRank.beginner);
    });

    test('userRankTitleProvider provides rank title', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      final title = container.read(userRankTitleProvider);
      expect(title, '初心者');
    });

    test('learningLevelProvider provides learning level', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      var level = container.read(learningLevelProvider);
      expect(level, '初級');

      await notifier.updateStatistics(
        'test_user',
        lessonsCompleted: 200,
      );

      level = container.read(learningLevelProvider);
      expect(level, '中級');
    });

    test('engagementScoreProvider provides score', () async {
      final notifier = container.read(userProfileProvider.notifier);
      await notifier.initializeProfile('test_user', 'testuser');

      await notifier.updateStatistics(
        'test_user',
        lessonsTaken: 50,
      );

      final score = container.read(engagementScoreProvider);
      expect(score, greaterThanOrEqualTo(0));
    });
  });
}
