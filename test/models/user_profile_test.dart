import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/user_profile.dart';

void main() {
  group('UserRank Enum', () {
    test('has all expected ranks', () {
      expect(UserRank.values.length, 6);
      expect(UserRank.values, contains(UserRank.beginner));
      expect(UserRank.values, contains(UserRank.master));
    });
  });

  group('AchievementStatus Enum', () {
    test('has all expected statuses', () {
      expect(AchievementStatus.values.length, 3);
    });
  });

  group('ProfileVisibility Enum', () {
    test('has all expected visibility options', () {
      expect(ProfileVisibility.values.length, 3);
    });
  });

  group('UserAchievement', () {
    test('creates achievement with required fields', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final achievement = UserAchievement(
        achievementId: 'ach1',
        title: 'アチーブメント',
        description: '説明',
        unlockedAt: now,
      );

      expect(achievement.achievementId, 'ach1');
      expect(achievement.title, 'アチーブメント');
      expect(achievement.status, AchievementStatus.locked);
    });

    test('isRecentlyUnlocked returns true for recent achievements', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final achievement = UserAchievement(
        achievementId: 'ach1',
        title: 'Test',
        description: 'Test',
        unlockedAt: now - (3 * 24 * 60 * 60), // 3 days ago
      );

      expect(achievement.isRecentlyUnlocked, true);
    });

    test('isRecentlyUnlocked returns false for old achievements', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final achievement = UserAchievement(
        achievementId: 'ach1',
        title: 'Test',
        description: 'Test',
        unlockedAt: now - (10 * 24 * 60 * 60), // 10 days ago
      );

      expect(achievement.isRecentlyUnlocked, false);
    });

    test('toJson serializes achievement', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final achievement = UserAchievement(
        achievementId: 'ach1',
        title: 'Test',
        description: 'Test',
        iconId: 'icon1',
        unlockedAt: now,
        status: AchievementStatus.featured,
        rarity: 5,
        category: 'special',
      );

      final json = achievement.toJson();
      expect(json['achievementId'], 'ach1');
      expect(json['rarity'], 5);
      expect(json['status'], 'featured');
    });

    test('fromJson deserializes achievement', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final json = {
        'achievementId': 'ach1',
        'title': 'Test',
        'description': 'Test',
        'unlockedAt': now,
        'status': 'unlocked',
      };

      final achievement = UserAchievement.fromJson(json);
      expect(achievement.achievementId, 'ach1');
      expect(achievement.status, AchievementStatus.unlocked);
    });
  });

  group('LevelMilestone', () {
    test('creates milestone with required fields', () {
      final milestone = LevelMilestone(
        level: 5,
        totalXpRequired: 500,
      );

      expect(milestone.level, 5);
      expect(milestone.totalXpRequired, 500);
      expect(milestone.isUnlocked, false);
    });

    test('xpForThisLevel calculates correctly', () {
      final milestone = LevelMilestone(
        level: 5,
        totalXpRequired: 500,
      );

      expect(milestone.xpForThisLevel, greaterThan(0));
    });

    test('toJson serializes milestone', () {
      final milestone = LevelMilestone(
        level: 5,
        totalXpRequired: 500,
        rewardId: 'reward1',
        milestoneTitle: 'マイルストーン',
        isUnlocked: true,
      );

      final json = milestone.toJson();
      expect(json['level'], 5);
      expect(json['isUnlocked'], true);
    });
  });

  group('UserProfile', () {
    test('creates profile with required fields', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        createdAt: now,
      );

      expect(profile.userId, 'user1');
      expect(profile.username, 'testuser');
      expect(profile.currentLevel, 1);
      expect(profile.totalXp, 0);
    });

    test('getRank returns correct rank for level', () {
      final now = DateTime.now();

      final beginnerProfile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        currentLevel: 5,
        createdAt: now,
      );
      expect(beginnerProfile.getRank(), UserRank.beginner);

      final learnerProfile = UserProfile(
        userId: 'user2',
        username: 'testuser2',
        currentLevel: 15,
        createdAt: now,
      );
      expect(learnerProfile.getRank(), UserRank.learner);

      final masterProfile = UserProfile(
        userId: 'user3',
        username: 'testuser3',
        currentLevel: 101,
        createdAt: now,
      );
      expect(masterProfile.getRank(), UserRank.master);
    });

    test('getRankTitle returns correct Japanese text', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        currentLevel: 5,
        createdAt: now,
      );

      expect(profile.getRankTitle(), '初心者');
    });

    test('getXpToNextLevel calculates correctly', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        totalXp: 50,
        currentLevel: 1,
        createdAt: now,
      );

      expect(profile.getXpToNextLevel(), lessThan(100));
    });

    test('getAccountAgeDays calculates correctly', () {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        createdAt: sevenDaysAgo,
      );

      expect(profile.getAccountAgeDays(), 7);
    });

    test('toJson serializes profile', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        displayName: 'Test User',
        totalXp: 500,
        currentLevel: 6,
        coins: 100,
        premiumCurrency: 50,
        createdAt: now,
        visibility: ProfileVisibility.public,
      );

      final json = profile.toJson();
      expect(json['userId'], 'user1');
      expect(json['totalXp'], 500);
      expect(json['currentLevel'], 6);
    });

    test('fromJson deserializes profile', () {
      final now = DateTime.now();
      final json = {
        'userId': 'user1',
        'username': 'testuser',
        'displayName': 'Test User',
        'totalXp': 500,
        'currentLevel': 6,
        'createdAt': now.toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.userId, 'user1');
      expect(profile.currentLevel, 6);
    });
  });

  group('UserStatistics', () {
    test('creates stats with required fields', () {
      final now = DateTime.now();
      final stats = UserStatistics(
        userId: 'user1',
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalLessonsTaken, 0);
    });

    test('completionRate calculates correctly', () {
      final now = DateTime.now();
      final stats = UserStatistics(
        userId: 'user1',
        totalLessonsTaken: 10,
        totalLessonsCompleted: 5,
        lastUpdatedAt: now,
      );

      expect(stats.completionRate, 50);
    });

    test('completionRate returns 0 when no lessons taken', () {
      final now = DateTime.now();
      final stats = UserStatistics(
        userId: 'user1',
        lastUpdatedAt: now,
      );

      expect(stats.completionRate, 0);
    });

    test('getEngagementScore calculates correctly', () {
      final now = DateTime.now();
      final stats = UserStatistics(
        userId: 'user1',
        totalLessonsTaken: 100,
        totalAchievementsUnlocked: 10,
        totalChallengesCompleted: 5,
        lastUpdatedAt: now,
      );

      expect(stats.getEngagementScore(), greaterThan(0));
    });

    test('getLearningLevel returns correct level', () {
      final now = DateTime.now();

      final beginnerStats = UserStatistics(
        userId: 'user1',
        totalLessonsCompleted: 30,
        lastUpdatedAt: now,
      );
      expect(beginnerStats.getLearningLevel(), '初級');

      final advancedStats = UserStatistics(
        userId: 'user2',
        totalLessonsCompleted: 200,
        lastUpdatedAt: now,
      );
      expect(advancedStats.getLearningLevel(), '中級');

      const masterStats = UserStatistics(
        userId: 'user3',
        totalLessonsCompleted: 550,
        lastUpdatedAt: DateTime(2024),
      );
      expect(masterStats.getLearningLevel(), 'マスター');
    });

    test('toJson serializes stats', () {
      final now = DateTime.now();
      final stats = UserStatistics(
        userId: 'user1',
        totalLessonsTaken: 100,
        totalLessonsCompleted: 80,
        totalMinutesLearned: 500,
        currentStreak: 7,
        longestStreak: 15,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      expect(json['userId'], 'user1');
      expect(json['totalLessonsTaken'], 100);
      expect(json['currentStreak'], 7);
    });
  });

  group('UserProfileCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        createdAt: now,
      );
      final stats = UserStatistics(
        userId: 'user1',
        lastUpdatedAt: now,
      );

      final collection = UserProfileCollection(
        userId: 'user1',
        profile: profile,
        statistics: stats,
        achievements: [],
        featuredAchievements: [],
        milestones: [],
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.achievements, isEmpty);
    });

    test('getRecentAchievements filters recent only', () {
      final now = DateTime.now();
      final recentTime = (now.millisecondsSinceEpoch ~/ 1000) - (3 * 24 * 60 * 60);
      final oldTime = (now.millisecondsSinceEpoch ~/ 1000) - (15 * 24 * 60 * 60);

      final recentAch = UserAchievement(
        achievementId: 'ach1',
        title: 'Recent',
        description: 'Recent',
        unlockedAt: recentTime,
      );

      final oldAch = UserAchievement(
        achievementId: 'ach2',
        title: 'Old',
        description: 'Old',
        unlockedAt: oldTime,
      );

      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        createdAt: now,
      );
      final stats = UserStatistics(
        userId: 'user1',
        lastUpdatedAt: now,
      );

      final collection = UserProfileCollection(
        userId: 'user1',
        profile: profile,
        statistics: stats,
        achievements: [recentAch, oldAch],
        featuredAchievements: [],
        milestones: [],
        generatedAt: now,
      );

      final recent = collection.getRecentAchievements(7);
      expect(recent.length, 1);
      expect(recent[0].achievementId, 'ach1');
    });

    test('getUnlockedAchievements filters unlocked only', () {
      final now = DateTime.now();
      final time = (now.millisecondsSinceEpoch ~/ 1000);

      final unlockedAch = UserAchievement(
        achievementId: 'ach1',
        title: 'Unlocked',
        description: 'Unlocked',
        unlockedAt: time,
        status: AchievementStatus.unlocked,
      );

      final lockedAch = UserAchievement(
        achievementId: 'ach2',
        title: 'Locked',
        description: 'Locked',
        unlockedAt: time,
        status: AchievementStatus.locked,
      );

      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        createdAt: now,
      );
      final stats = UserStatistics(
        userId: 'user1',
        lastUpdatedAt: now,
      );

      final collection = UserProfileCollection(
        userId: 'user1',
        profile: profile,
        statistics: stats,
        achievements: [unlockedAch, lockedAch],
        featuredAchievements: [],
        milestones: [],
        generatedAt: now,
      );

      final unlocked = collection.getUnlockedAchievements();
      expect(unlocked.length, 1);
      expect(unlocked[0].status, AchievementStatus.unlocked);
    });

    test('getRarityBreakdown calculates correctly', () {
      final now = DateTime.now();
      final time = (now.millisecondsSinceEpoch ~/ 1000);

      final ach1 = UserAchievement(
        achievementId: 'ach1',
        title: 'Test',
        description: 'Test',
        unlockedAt: time,
        rarity: 5,
      );

      final ach2 = UserAchievement(
        achievementId: 'ach2',
        title: 'Test',
        description: 'Test',
        unlockedAt: time,
        rarity: 3,
      );

      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        createdAt: now,
      );
      final stats = UserStatistics(
        userId: 'user1',
        lastUpdatedAt: now,
      );

      final collection = UserProfileCollection(
        userId: 'user1',
        profile: profile,
        statistics: stats,
        achievements: [ach1, ach2],
        featuredAchievements: [],
        milestones: [],
        generatedAt: now,
      );

      final breakdown = collection.getRarityBreakdown();
      expect(breakdown[5], 1);
      expect(breakdown[3], 1);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user1',
        username: 'testuser',
        createdAt: now,
      );
      final stats = UserStatistics(
        userId: 'user1',
        lastUpdatedAt: now,
      );

      final collection = UserProfileCollection(
        userId: 'user1',
        profile: profile,
        statistics: stats,
        achievements: [],
        featuredAchievements: [],
        milestones: [],
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = UserProfileCollection.fromJson(json);

      expect(restored.userId, collection.userId);
      expect(restored.profile.username, collection.profile.username);
    });
  });
}
