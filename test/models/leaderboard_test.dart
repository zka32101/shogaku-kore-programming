import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/leaderboard.dart';

void main() {
  group('LeaderboardTimeUnit', () {
    test('should have all required values', () {
      expect(LeaderboardTimeUnit.allTime, isNotNull);
      expect(LeaderboardTimeUnit.monthly, isNotNull);
      expect(LeaderboardTimeUnit.weekly, isNotNull);
      expect(LeaderboardTimeUnit.daily, isNotNull);
    });

    test('should have correct enum names', () {
      expect(LeaderboardTimeUnit.allTime.name, 'allTime');
      expect(LeaderboardTimeUnit.monthly.name, 'monthly');
      expect(LeaderboardTimeUnit.weekly.name, 'weekly');
      expect(LeaderboardTimeUnit.daily.name, 'daily');
    });
  });

  group('RankingTier', () {
    test('should have all required values', () {
      expect(RankingTier.bronze, isNotNull);
      expect(RankingTier.silver, isNotNull);
      expect(RankingTier.gold, isNotNull);
      expect(RankingTier.platinum, isNotNull);
    });

    test('should have correct index ordering', () {
      expect(RankingTier.bronze.index, 0);
      expect(RankingTier.silver.index, 1);
      expect(RankingTier.gold.index, 2);
      expect(RankingTier.platinum.index, 3);
    });
  });

  group('LeaderboardRegion', () {
    test('should have all required values', () {
      expect(LeaderboardRegion.global, isNotNull);
      expect(LeaderboardRegion.japan, isNotNull);
      expect(LeaderboardRegion.asia, isNotNull);
      expect(LeaderboardRegion.other, isNotNull);
    });

    test('should have correct enum names', () {
      expect(LeaderboardRegion.global.name, 'global');
      expect(LeaderboardRegion.japan.name, 'japan');
      expect(LeaderboardRegion.asia.name, 'asia');
      expect(LeaderboardRegion.other.name, 'other');
    });
  });

  group('GlobalLeaderboardEntry', () {
    late GlobalLeaderboardEntry entry;

    setUp(() {
      entry = GlobalLeaderboardEntry(
        rank: 1,
        userId: 'user-1',
        username: 'user1',
        displayName: 'User One',
        profileImageUrl: 'https://example.com/avatar.jpg',
        level: 10,
        totalXp: 10000,
        averageAccuracy: 0.95,
        matchesWon: 45,
        matchesPlayed: 50,
        winRate: 0.9,
        currentStreak: 5,
        longestStreak: 15,
        tier: RankingTier.platinum,
        lastUpdatedAt: DateTime(2026, 9, 1),
      );
    });

    test('should create entry with correct values', () {
      expect(entry.rank, 1);
      expect(entry.userId, 'user-1');
      expect(entry.username, 'user1');
      expect(entry.displayName, 'User One');
      expect(entry.level, 10);
      expect(entry.totalXp, 10000);
      expect(entry.averageAccuracy, 0.95);
      expect(entry.matchesWon, 45);
      expect(entry.matchesPlayed, 50);
      expect(entry.winRate, 0.9);
      expect(entry.currentStreak, 5);
      expect(entry.longestStreak, 15);
      expect(entry.tier, RankingTier.platinum);
    });

    test('calculateTier should return correct tier for rank', () {
      expect(GlobalLeaderboardEntry.calculateTier(1), RankingTier.platinum);
      expect(GlobalLeaderboardEntry.calculateTier(10), RankingTier.platinum);
      expect(GlobalLeaderboardEntry.calculateTier(11), RankingTier.gold);
      expect(GlobalLeaderboardEntry.calculateTier(100), RankingTier.gold);
      expect(GlobalLeaderboardEntry.calculateTier(101), RankingTier.silver);
      expect(GlobalLeaderboardEntry.calculateTier(1000), RankingTier.silver);
      expect(GlobalLeaderboardEntry.calculateTier(1001), RankingTier.bronze);
    });

    test('should serialize to JSON correctly', () {
      final json = entry.toJson();

      expect(json['rank'], 1);
      expect(json['userId'], 'user-1');
      expect(json['username'], 'user1');
      expect(json['displayName'], 'User One');
      expect(json['level'], 10);
      expect(json['totalXp'], 10000);
      expect(json['averageAccuracy'], 0.95);
      expect(json['matchesWon'], 45);
      expect(json['matchesPlayed'], 50);
      expect(json['winRate'], 0.9);
      expect(json['tier'], 'platinum');
    });

    test('should deserialize from JSON correctly', () {
      final json = entry.toJson();
      final deserialized = GlobalLeaderboardEntry.fromJson(json);

      expect(deserialized.rank, entry.rank);
      expect(deserialized.userId, entry.userId);
      expect(deserialized.username, entry.username);
      expect(deserialized.displayName, entry.displayName);
      expect(deserialized.level, entry.level);
      expect(deserialized.totalXp, entry.totalXp);
      expect(deserialized.averageAccuracy, entry.averageAccuracy);
      expect(deserialized.tier, entry.tier);
    });

    test('should handle null profileImageUrl', () {
      final entry2 = GlobalLeaderboardEntry(
        rank: 2,
        userId: 'user-2',
        username: 'user2',
        displayName: 'User Two',
        level: 5,
        totalXp: 5000,
        averageAccuracy: 0.85,
        matchesWon: 20,
        matchesPlayed: 30,
        winRate: 0.67,
        currentStreak: 2,
        longestStreak: 10,
        tier: RankingTier.gold,
        lastUpdatedAt: DateTime(2026, 9, 1),
      );

      expect(entry2.profileImageUrl, isNull);

      final json = entry2.toJson();
      final deserialized = GlobalLeaderboardEntry.fromJson(json);
      expect(deserialized.profileImageUrl, isNull);
    });
  });

  group('CategoryLeaderboardEntry', () {
    late CategoryLeaderboardEntry entry;

    setUp(() {
      entry = CategoryLeaderboardEntry(
        rank: 5,
        userId: 'user-5',
        username: 'user5',
        displayName: 'User Five',
        category: LearningCategory.variables,
        accuracy: 0.88,
        quizzesCompleted: 30,
        correctAnswers: 26,
        lastUpdatedAt: DateTime(2026, 9, 1),
      );
    });

    test('should create entry with correct values', () {
      expect(entry.rank, 5);
      expect(entry.userId, 'user-5');
      expect(entry.category, LearningCategory.variables);
      expect(entry.accuracy, 0.88);
      expect(entry.quizzesCompleted, 30);
      expect(entry.correctAnswers, 26);
    });

    test('should serialize to JSON correctly', () {
      final json = entry.toJson();

      expect(json['rank'], 5);
      expect(json['userId'], 'user-5');
      expect(json['category'], 'variables');
      expect(json['accuracy'], 0.88);
      expect(json['quizzesCompleted'], 30);
      expect(json['correctAnswers'], 26);
    });

    test('should deserialize from JSON correctly', () {
      final json = entry.toJson();
      final deserialized = CategoryLeaderboardEntry.fromJson(json);

      expect(deserialized.rank, entry.rank);
      expect(deserialized.userId, entry.userId);
      expect(deserialized.category, entry.category);
      expect(deserialized.accuracy, entry.accuracy);
      expect(deserialized.quizzesCompleted, entry.quizzesCompleted);
    });
  });

  group('RankingChangeNotification', () {
    late RankingChangeNotification notification;

    setUp(() {
      notification = RankingChangeNotification(
        notificationId: 'notif-1',
        userId: 'user-1',
        timeUnit: LeaderboardTimeUnit.weekly,
        previousRank: 15,
        currentRank: 10,
        previousTier: RankingTier.gold,
        currentTier: RankingTier.gold,
        isPromotion: true,
        createdAt: DateTime(2026, 9, 1),
        isRead: false,
      );
    });

    test('should create notification with correct values', () {
      expect(notification.notificationId, 'notif-1');
      expect(notification.userId, 'user-1');
      expect(notification.timeUnit, LeaderboardTimeUnit.weekly);
      expect(notification.previousRank, 15);
      expect(notification.currentRank, 10);
      expect(notification.isPromotion, true);
      expect(notification.isRead, false);
    });

    test('rankChange should return negative value for rank improvement', () {
      expect(notification.rankChange, 5); // 15 - 10 = 5 (negative rankChange means improvement)
    });

    test('rankChange should return positive value for rank decline', () {
      final decline = RankingChangeNotification(
        notificationId: 'notif-2',
        userId: 'user-2',
        timeUnit: LeaderboardTimeUnit.weekly,
        previousRank: 10,
        currentRank: 15,
        previousTier: RankingTier.gold,
        currentTier: RankingTier.silver,
        isPromotion: false,
        createdAt: DateTime(2026, 9, 1),
      );

      expect(decline.rankChange, -5); // 10 - 15 = -5
    });

    test('isTierPromotion should return true only on tier improvement', () {
      expect(notification.isTierPromotion, false); // gold -> gold is not promotion

      final promotion = RankingChangeNotification(
        notificationId: 'notif-3',
        userId: 'user-3',
        timeUnit: LeaderboardTimeUnit.weekly,
        previousRank: 100,
        currentRank: 50,
        previousTier: RankingTier.gold,
        currentTier: RankingTier.platinum,
        isPromotion: true,
        createdAt: DateTime(2026, 9, 1),
      );

      expect(promotion.isTierPromotion, true);
    });

    test('isTierDemotion should return true only on tier decline', () {
      expect(notification.isTierDemotion, false);

      final demotion = RankingChangeNotification(
        notificationId: 'notif-4',
        userId: 'user-4',
        timeUnit: LeaderboardTimeUnit.weekly,
        previousRank: 50,
        currentRank: 100,
        previousTier: RankingTier.platinum,
        currentTier: RankingTier.gold,
        isPromotion: false,
        createdAt: DateTime(2026, 9, 1),
      );

      expect(demotion.isTierDemotion, true);
    });

    test('should serialize to JSON correctly', () {
      final json = notification.toJson();

      expect(json['notificationId'], 'notif-1');
      expect(json['userId'], 'user-1');
      expect(json['timeUnit'], 'weekly');
      expect(json['previousRank'], 15);
      expect(json['currentRank'], 10);
      expect(json['isPromotion'], true);
      expect(json['isRead'], false);
    });

    test('should deserialize from JSON correctly', () {
      final json = notification.toJson();
      final deserialized = RankingChangeNotification.fromJson(json);

      expect(deserialized.notificationId, notification.notificationId);
      expect(deserialized.userId, notification.userId);
      expect(deserialized.timeUnit, notification.timeUnit);
      expect(deserialized.isPromotion, notification.isPromotion);
      expect(deserialized.isRead, notification.isRead);
    });
  });

  group('LeaderboardData', () {
    late LeaderboardData data;

    setUp(() {
      final entries = [
        GlobalLeaderboardEntry(
          rank: 1,
          userId: 'user-1',
          username: 'user1',
          displayName: 'User One',
          level: 10,
          totalXp: 10000,
          averageAccuracy: 0.95,
          matchesWon: 45,
          matchesPlayed: 50,
          winRate: 0.9,
          currentStreak: 5,
          longestStreak: 15,
          tier: RankingTier.platinum,
          lastUpdatedAt: DateTime(2026, 9, 1),
        ),
      ];

      data = LeaderboardData(
        timeUnit: LeaderboardTimeUnit.allTime,
        generatedAt: DateTime(2026, 9, 1),
        globalRankings: entries,
        categoryRankings: {},
        recentChanges: [],
      );
    });

    test('should create leaderboard data with correct values', () {
      expect(data.timeUnit, LeaderboardTimeUnit.allTime);
      expect(data.globalRankings.length, 1);
      expect(data.globalRankings[0].rank, 1);
    });

    test('should serialize to JSON correctly', () {
      final json = data.toJson();

      expect(json['timeUnit'], 'allTime');
      expect(json['globalRankings'], isA<List>());
      expect(json['globalRankings'].length, 1);
    });

    test('should deserialize from JSON correctly', () {
      final json = data.toJson();
      final deserialized = LeaderboardData.fromJson(json);

      expect(deserialized.timeUnit, data.timeUnit);
      expect(deserialized.globalRankings.length, data.globalRankings.length);
    });

    test('should handle empty rankings', () {
      final emptyData = LeaderboardData(
        timeUnit: LeaderboardTimeUnit.daily,
        generatedAt: DateTime(2026, 9, 1),
        globalRankings: [],
        categoryRankings: {},
        recentChanges: [],
      );

      final json = emptyData.toJson();
      final deserialized = LeaderboardData.fromJson(json);

      expect(deserialized.globalRankings.isEmpty, true);
    });
  });

  group('UserRankingPosition', () {
    late UserRankingPosition position;

    setUp(() {
      position = UserRankingPosition(
        userId: 'user-1',
        globalRank: 5,
        tier: RankingTier.platinum,
        categoryRanks: {
          LearningCategory.variables: 3,
          LearningCategory.loops: 7,
        },
        previousGlobalRank: 8,
        lastUpdatedAt: DateTime(2026, 9, 1),
      );
    });

    test('should create position with correct values', () {
      expect(position.userId, 'user-1');
      expect(position.globalRank, 5);
      expect(position.tier, RankingTier.platinum);
      expect(position.previousGlobalRank, 8);
    });

    test('isRankImproved should return true when rank decreased', () {
      expect(position.isRankImproved, true); // 5 < 8
    });

    test('isRankDeclined should return false when rank decreased', () {
      expect(position.isRankDeclined, false);
    });

    test('isRankUnchanged should return false when rank changed', () {
      expect(position.isRankUnchanged, false);
    });

    test('isRankUnchanged should return true when rank unchanged', () {
      final unchangedPosition = UserRankingPosition(
        userId: 'user-2',
        globalRank: 10,
        tier: RankingTier.gold,
        categoryRanks: {},
        previousGlobalRank: 10,
        lastUpdatedAt: DateTime(2026, 9, 1),
      );

      expect(unchangedPosition.isRankUnchanged, true);
    });

    test('isRankDeclined should return true when rank increased', () {
      final declinedPosition = UserRankingPosition(
        userId: 'user-3',
        globalRank: 15,
        tier: RankingTier.gold,
        categoryRanks: {},
        previousGlobalRank: 10,
        lastUpdatedAt: DateTime(2026, 9, 1),
      );

      expect(declinedPosition.isRankDeclined, true);
    });

    test('should serialize to JSON correctly', () {
      final json = position.toJson();

      expect(json['userId'], 'user-1');
      expect(json['globalRank'], 5);
      expect(json['tier'], 'platinum');
      expect(json['previousGlobalRank'], 8);
    });

    test('should deserialize from JSON correctly', () {
      final json = position.toJson();
      final deserialized = UserRankingPosition.fromJson(json);

      expect(deserialized.userId, position.userId);
      expect(deserialized.globalRank, position.globalRank);
      expect(deserialized.tier, position.tier);
      expect(deserialized.previousGlobalRank, position.previousGlobalRank);
    });

    test('should include category ranks in serialization', () {
      final json = position.toJson();

      expect(json['categoryRanks'], isA<Map>());
      expect(json['categoryRanks']['variables'], 3);
      expect(json['categoryRanks']['loops'], 7);
    });
  });
}
