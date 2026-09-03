import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/activities_minigames.dart';

void main() {
  group('ActivityType Enum', () {
    test('has all expected types', () {
      expect(ActivityType.values.length, 8);
      expect(ActivityType.values, contains(ActivityType.quickGame));
      expect(ActivityType.values, contains(ActivityType.memoryGame));
    });
  });

  group('ActivityDifficulty Enum', () {
    test('has all expected difficulties', () {
      expect(ActivityDifficulty.values.length, 4);
      expect(ActivityDifficulty.values, contains(ActivityDifficulty.easy));
      expect(ActivityDifficulty.values, contains(ActivityDifficulty.expert));
    });
  });

  group('Activity', () {
    test('creates activity with required fields', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        name: 'テスト',
        description: 'Test activity',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
      );

      expect(activity.activityId, 'act1');
      expect(activity.name, 'テスト');
      expect(activity.isAvailable, true);
    });

    test('isAvailable returns true for non-limited activities', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        name: 'Test',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        availableUntil: null,
        addedAt: now,
      );

      expect(activity.isAvailable, true);
    });

    test('isAvailable returns true for future availability', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        name: 'Test',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        availableUntil: now.add(const Duration(days: 1)),
        addedAt: now,
      );

      expect(activity.isAvailable, true);
    });

    test('isAvailable returns false for expired activities', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        name: 'Test',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        availableUntil: now.subtract(const Duration(days: 1)),
        addedAt: now,
      );

      expect(activity.isAvailable, false);
    });

    test('getDifficultyColor returns correct colors', () {
      final now = DateTime.now();

      final easyAct = Activity(
        activityId: 'a1',
        name: 'Easy',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
      );
      expect(easyAct.getDifficultyColor(), 'green');

      final hardAct = Activity(
        activityId: 'a2',
        name: 'Hard',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.hard,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
      );
      expect(hardAct.getDifficultyColor(), 'orange');

      final expertAct = Activity(
        activityId: 'a3',
        name: 'Expert',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.expert,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
      );
      expect(expertAct.getDifficultyColor(), 'red');
    });

    test('toJson serializes activity', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        name: 'Test',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        playCount: 10,
        averageScore: 85.5,
        addedAt: now,
      );

      final json = activity.toJson();
      expect(json['activityId'], 'act1');
      expect(json['playCount'], 10);
      expect(json['averageScore'], 85.5);
    });

    test('fromJson deserializes activity', () {
      final now = DateTime.now();
      final json = {
        'activityId': 'act1',
        'name': 'Test',
        'description': 'Test',
        'type': 'quickGame',
        'difficulty': 'easy',
        'baseCoins': 50,
        'baseXp': 25,
        'addedAt': now.toIso8601String(),
      };

      final activity = Activity.fromJson(json);
      expect(activity.activityId, 'act1');
      expect(activity.type, ActivityType.quickGame);
    });
  });

  group('ActivityParticipation', () {
    test('creates participation with required fields', () {
      final now = DateTime.now();
      final part = ActivityParticipation(
        participationId: 'part1',
        userId: 'user1',
        activityId: 'act1',
        startedAt: now,
      );

      expect(part.participationId, 'part1');
      expect(part.isInProgress, true);
      expect(part.isCompleted, false);
    });

    test('isInProgress returns false when completed', () {
      final now = DateTime.now();
      final part = ActivityParticipation(
        participationId: 'part1',
        userId: 'user1',
        activityId: 'act1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 5)),
        isCompleted: true,
      );

      expect(part.isInProgress, false);
    });

    test('duration calculates correctly', () {
      final now = DateTime.now();
      final part = ActivityParticipation(
        participationId: 'part1',
        userId: 'user1',
        activityId: 'act1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 10)),
      );

      expect(part.duration.inMinutes, 10);
    });

    test('toJson serializes participation', () {
      final now = DateTime.now();
      final part = ActivityParticipation(
        participationId: 'part1',
        userId: 'user1',
        activityId: 'act1',
        startedAt: now,
        score: 95,
        coinsEarned: 100,
      );

      final json = part.toJson();
      expect(json['participationId'], 'part1');
      expect(json['score'], 95);
    });

    test('fromJson deserializes participation', () {
      final now = DateTime.now();
      final json = {
        'participationId': 'part1',
        'userId': 'user1',
        'activityId': 'act1',
        'startedAt': now.toIso8601String(),
        'score': 90,
      };

      final part = ActivityParticipation.fromJson(json);
      expect(part.participationId, 'part1');
      expect(part.score, 90);
    });
  });

  group('ActivityResult', () {
    test('creates result with required fields', () {
      final now = DateTime.now();
      final result = ActivityResult(
        resultId: 'result1',
        userId: 'user1',
        activityId: 'act1',
        score: 90,
        coinsReward: 100,
        xpReward: 50,
        completedAt: now,
        timeSpentSeconds: 120,
      );

      expect(result.resultId, 'result1');
      expect(result.score, 90);
    });

    test('creates result with perfect score', () {
      final now = DateTime.now();
      final result = ActivityResult(
        resultId: 'result1',
        userId: 'user1',
        activityId: 'act1',
        score: 100,
        coinsReward: 150,
        xpReward: 75,
        completedAt: now,
        timeSpentSeconds: 60,
        isPerfectScore: true,
        premiumCoinReward: 1,
      );

      expect(result.isPerfectScore, true);
      expect(result.premiumCoinReward, 1);
    });

    test('toJson serializes result', () {
      final now = DateTime.now();
      final result = ActivityResult(
        resultId: 'result1',
        userId: 'user1',
        activityId: 'act1',
        score: 95,
        coinsReward: 120,
        xpReward: 60,
        completedAt: now,
        timeSpentSeconds: 90,
        isPerfectScore: true,
        isNewHighScore: true,
      );

      final json = result.toJson();
      expect(json['resultId'], 'result1');
      expect(json['isPerfectScore'], true);
      expect(json['isNewHighScore'], true);
    });

    test('fromJson deserializes result', () {
      final now = DateTime.now();
      final json = {
        'resultId': 'result1',
        'userId': 'user1',
        'activityId': 'act1',
        'score': 85,
        'coinsReward': 100,
        'xpReward': 50,
        'completedAt': now.toIso8601String(),
        'timeSpentSeconds': 120,
      };

      final result = ActivityResult.fromJson(json);
      expect(result.resultId, 'result1');
      expect(result.score, 85);
    });
  });

  group('ActivityStatistics', () {
    test('creates statistics with required fields', () {
      final now = DateTime.now();
      final stats = ActivityStatistics(
        userId: 'user1',
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalActivitiesCompleted, 0);
    });

    test('getActivityTier returns correct tiers', () {
      final now = DateTime.now();

      final beginnerStats = ActivityStatistics(
        userId: 'user1',
        totalActivitiesCompleted: 5,
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );
      expect(beginnerStats.getActivityTier(), 'ビギナー');

      final amateurStats = ActivityStatistics(
        userId: 'user2',
        totalActivitiesCompleted: 30,
        firstActivityAt: DateTime(2024),
        lastActivityAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(amateurStats.getActivityTier(), 'アマチュア');

      final intermediateStats = ActivityStatistics(
        userId: 'user3',
        totalActivitiesCompleted: 75,
        firstActivityAt: DateTime(2024),
        lastActivityAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(intermediateStats.getActivityTier(), 'インターミディエイト');

      final advanceStats = ActivityStatistics(
        userId: 'user4',
        totalActivitiesCompleted: 150,
        firstActivityAt: DateTime(2024),
        lastActivityAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(advanceStats.getActivityTier(), 'アドバンス');

      final expertStats = ActivityStatistics(
        userId: 'user5',
        totalActivitiesCompleted: 300,
        firstActivityAt: DateTime(2024),
        lastActivityAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(expertStats.getActivityTier(), 'エキスパート');

      final masterStats = ActivityStatistics(
        userId: 'user6',
        totalActivitiesCompleted: 600,
        firstActivityAt: DateTime(2024),
        lastActivityAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(masterStats.getActivityTier(), 'マスター');
    });

    test('toJson serializes statistics', () {
      final now = DateTime.now();
      final stats = ActivityStatistics(
        userId: 'user1',
        totalActivitiesCompleted: 50,
        totalCoinsEarned: 5000,
        totalXpEarned: 2500,
        perfectScores: 5,
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      expect(json['userId'], 'user1');
      expect(json['totalActivitiesCompleted'], 50);
      expect(json['perfectScores'], 5);
    });

    test('fromJson deserializes statistics', () {
      final now = DateTime.now();
      final json = {
        'userId': 'user1',
        'totalActivitiesCompleted': 50,
        'totalCoinsEarned': 5000,
        'firstActivityAt': now.toIso8601String(),
        'lastActivityAt': now.toIso8601String(),
        'lastUpdatedAt': now.toIso8601String(),
      };

      final stats = ActivityStatistics.fromJson(json);
      expect(stats.userId, 'user1');
      expect(stats.totalActivitiesCompleted, 50);
    });
  });

  group('ActivityCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final stats = ActivityStatistics(
        userId: 'user1',
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityCollection(
        userId: 'user1',
        allActivities: [],
        participations: [],
        results: [],
        statistics: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.allActivities.isEmpty, true);
    });

    test('getAvailableActivities filters correctly', () {
      final now = DateTime.now();
      final available = Activity(
        activityId: 'act1',
        name: 'Available',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
        availableUntil: now.add(const Duration(days: 1)),
      );
      final unavailable = Activity(
        activityId: 'act2',
        name: 'Expired',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
        availableUntil: now.subtract(const Duration(days: 1)),
      );

      final stats = ActivityStatistics(
        userId: 'user1',
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityCollection(
        userId: 'user1',
        allActivities: [available, unavailable],
        participations: [],
        results: [],
        statistics: stats,
        generatedAt: now,
      );

      final availList = collection.getAvailableActivities();
      expect(availList.length, 1);
      expect(availList[0].activityId, 'act1');
    });

    test('getActivitiesByType filters correctly', () {
      final now = DateTime.now();
      final memory = Activity(
        activityId: 'act1',
        name: 'Memory',
        description: 'Test',
        type: ActivityType.memoryGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
      );
      final speed = Activity(
        activityId: 'act2',
        name: 'Speed',
        description: 'Test',
        type: ActivityType.speedGame,
        difficulty: ActivityDifficulty.normal,
        baseCoins: 75,
        baseXp: 40,
        addedAt: now,
      );

      final stats = ActivityStatistics(
        userId: 'user1',
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityCollection(
        userId: 'user1',
        allActivities: [memory, speed],
        participations: [],
        results: [],
        statistics: stats,
        generatedAt: now,
      );

      final memoryList = collection.getActivitiesByType(ActivityType.memoryGame);
      expect(memoryList.length, 1);
      expect(memoryList[0].type, ActivityType.memoryGame);
    });

    test('getFeaturedActivities returns featured only', () {
      final now = DateTime.now();
      final featured = Activity(
        activityId: 'act1',
        name: 'Featured',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
        isFeatured: true,
      );
      final notFeatured = Activity(
        activityId: 'act2',
        name: 'Regular',
        description: 'Test',
        type: ActivityType.quickGame,
        difficulty: ActivityDifficulty.easy,
        baseCoins: 50,
        baseXp: 25,
        addedAt: now,
        isFeatured: false,
      );

      final stats = ActivityStatistics(
        userId: 'user1',
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityCollection(
        userId: 'user1',
        allActivities: [featured, notFeatured],
        participations: [],
        results: [],
        statistics: stats,
        generatedAt: now,
      );

      final featuredList = collection.getFeaturedActivities();
      expect(featuredList.length, 1);
      expect(featuredList[0].isFeatured, true);
    });

    test('getPersonalBest returns highest score', () {
      final now = DateTime.now();
      final result1 = ActivityResult(
        resultId: 'r1',
        userId: 'user1',
        activityId: 'act1',
        score: 80,
        coinsReward: 80,
        xpReward: 40,
        completedAt: now,
        timeSpentSeconds: 120,
      );
      final result2 = ActivityResult(
        resultId: 'r2',
        userId: 'user1',
        activityId: 'act1',
        score: 95,
        coinsReward: 120,
        xpReward: 60,
        completedAt: now.add(const Duration(hours: 1)),
        timeSpentSeconds: 100,
      );

      final stats = ActivityStatistics(
        userId: 'user1',
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityCollection(
        userId: 'user1',
        allActivities: [],
        participations: [],
        results: [result1, result2],
        statistics: stats,
        generatedAt: now,
      );

      final best = collection.getPersonalBest('act1');
      expect(best, isNotNull);
      expect(best!.score, 95);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = ActivityStatistics(
        userId: 'user1',
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityCollection(
        userId: 'user1',
        allActivities: [],
        participations: [],
        results: [],
        statistics: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = ActivityCollection.fromJson(json);

      expect(restored.userId, collection.userId);
    });
  });
}
