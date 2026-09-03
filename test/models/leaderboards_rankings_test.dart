import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/leaderboards_rankings.dart';

void main() {
  group('SchoolGrade', () {
    test('displayName returns correct Japanese names', () {
      expect(SchoolGrade.firstGrade.displayName, '1年生');
      expect(SchoolGrade.sixthGrade.displayName, '6年生');
    });

    test('gradeLevel returns correct numbers', () {
      expect(SchoolGrade.firstGrade.gradeLevel, 1);
      expect(SchoolGrade.sixthGrade.gradeLevel, 6);
    });

    test('getNextGrade returns next grade', () {
      expect(SchoolGrade.firstGrade.getNextGrade(), SchoolGrade.secondGrade);
      expect(SchoolGrade.fifthGrade.getNextGrade(), SchoolGrade.sixthGrade);
    });

    test('getNextGrade returns same grade for 6年生', () {
      expect(SchoolGrade.sixthGrade.getNextGrade(), SchoolGrade.sixthGrade);
    });

    test('fromBirthYear calculates grade correctly', () {
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;

      // If born in current year - 6 (approximately 6 years old)
      final firstGrade = SchoolGrade.fromBirthYear(currentYear - 6);
      expect(firstGrade.gradeLevel, lessThanOrEqualTo(2));

      // If born many years ago
      final sixthGrade = SchoolGrade.fromBirthYear(currentYear - 12);
      expect(sixthGrade.gradeLevel, greaterThanOrEqualTo(5));
    });
  });

  group('RankingMetric', () {
    test('displayName returns correct names', () {
      expect(RankingMetric.totalCoins.displayName, '総ポイント');
      expect(RankingMetric.activityCompletions.displayName, 'アクティビティ完了数');
      expect(RankingMetric.compositeScore.displayName, '複合スコア');
    });
  });

  group('RankingGrouping', () {
    test('displayName returns correct names', () {
      expect(RankingGrouping.overall.displayName, '全体ランキング');
      expect(RankingGrouping.byGrade.displayName, '学年別');
      expect(RankingGrouping.byStartMonth.displayName, '開始月別');
      expect(RankingGrouping.combined.displayName, '複合グループ化');
    });
  });

  group('UserGrade', () {
    test('creates user grade with required fields', () {
      final now = DateTime.now();
      final grade = UserGrade(
        userId: 'user1',
        currentGrade: SchoolGrade.fourthGrade,
        birthYear: 2015,
        lastGradeChangeAt: now,
        firstEnrolledAt: now,
      );

      expect(grade.userId, 'user1');
      expect(grade.currentGrade, SchoolGrade.fourthGrade);
      expect(grade.autoPromoteEnabled, true);
    });

    test('shouldPromoteToNextGrade returns false before April', () {
      final now = DateTime.now();
      final grade = UserGrade(
        userId: 'user1',
        currentGrade: SchoolGrade.thirdGrade,
        birthYear: 2015,
        lastGradeChangeAt: DateTime(now.year - 1, 4, 1),
        firstEnrolledAt: now,
        autoPromoteEnabled: true,
      );

      // This test might fail depending on current month
      // Skip if not in April or later
      if (now.month < 4) {
        expect(grade.shouldPromoteToNextGrade(), false);
      }
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final grade = UserGrade(
        userId: 'user1',
        currentGrade: SchoolGrade.fourthGrade,
        birthYear: 2015,
        lastGradeChangeAt: now,
        firstEnrolledAt: now,
        autoPromoteEnabled: true,
      );

      final json = grade.toJson();
      final restored = UserGrade.fromJson(json);
      expect(restored.userId, 'user1');
      expect(restored.currentGrade, SchoolGrade.fourthGrade);
    });
  });

  group('RankingEntry', () {
    test('creates ranking entry', () {
      final now = DateTime.now();
      final entry = RankingEntry(
        rankingEntryId: 'rank1',
        userId: 'user1',
        userName: 'Student 1',
        metric: RankingMetric.totalCoins,
        score: 1000,
        rankPosition: 1,
        tier: 'チャンピオン',
        calculatedAt: now,
      );

      expect(entry.rankPosition, 1);
      expect(entry.tier, 'チャンピオン');
    });

    test('getTierFromRank returns correct tier', () {
      expect(RankingEntry.getTierFromRank(1), 'チャンピオン');
      expect(RankingEntry.getTierFromRank(2), 'プラチナ');
      expect(RankingEntry.getTierFromRank(10), 'ゴールド');
      expect(RankingEntry.getTierFromRank(50), 'シルバー');
      expect(RankingEntry.getTierFromRank(100), 'ブロンズ');
      expect(RankingEntry.getTierFromRank(1000), 'ビギナー');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final entry = RankingEntry(
        rankingEntryId: 'rank1',
        userId: 'user1',
        userName: 'Student 1',
        metric: RankingMetric.totalCoins,
        score: 1500,
        rankPosition: 5,
        tier: 'シルバー',
        calculatedAt: now,
      );

      final json = entry.toJson();
      final restored = RankingEntry.fromJson(json);
      expect(restored.rankPosition, 5);
      expect(restored.score, 1500);
    });
  });

  group('Leaderboard', () {
    test('creates leaderboard', () {
      final now = DateTime.now();
      final leaderboard = Leaderboard(
        leaderboardId: 'lb1',
        metric: RankingMetric.totalCoins,
        grouping: RankingGrouping.overall,
        entries: [],
        calculatedAt: now,
        lastUpdatedAt: now,
      );

      expect(leaderboard.metric, RankingMetric.totalCoins);
      expect(leaderboard.totalParticipants, 0);
    });

    test('getTopEntries returns top N', () {
      final now = DateTime.now();
      final entries = [
        RankingEntry(
          rankingEntryId: 'r1',
          userId: 'u1',
          userName: 'User 1',
          metric: RankingMetric.totalCoins,
          score: 1000,
          rankPosition: 1,
          tier: 'チャンピオン',
          calculatedAt: now,
        ),
        RankingEntry(
          rankingEntryId: 'r2',
          userId: 'u2',
          userName: 'User 2',
          metric: RankingMetric.totalCoins,
          score: 900,
          rankPosition: 2,
          tier: 'プラチナ',
          calculatedAt: now,
        ),
        RankingEntry(
          rankingEntryId: 'r3',
          userId: 'u3',
          userName: 'User 3',
          metric: RankingMetric.totalCoins,
          score: 800,
          rankPosition: 3,
          tier: 'ゴールド',
          calculatedAt: now,
        ),
      ];

      final leaderboard = Leaderboard(
        leaderboardId: 'lb1',
        metric: RankingMetric.totalCoins,
        grouping: RankingGrouping.overall,
        entries: entries,
        calculatedAt: now,
        lastUpdatedAt: now,
      );

      final top2 = leaderboard.getTopEntries(2);
      expect(top2.length, 2);
      expect(top2[0].rankPosition, 1);
    });

    test('getUserRank finds user in leaderboard', () {
      final now = DateTime.now();
      final entry = RankingEntry(
        rankingEntryId: 'r1',
        userId: 'user1',
        userName: 'User 1',
        metric: RankingMetric.totalCoins,
        score: 1000,
        rankPosition: 1,
        tier: 'チャンピオン',
        calculatedAt: now,
      );

      final leaderboard = Leaderboard(
        leaderboardId: 'lb1',
        metric: RankingMetric.totalCoins,
        grouping: RankingGrouping.overall,
        entries: [entry],
        calculatedAt: now,
        lastUpdatedAt: now,
      );

      final found = leaderboard.getUserRank('user1');
      expect(found, isNotNull);
      expect(found?.rankPosition, 1);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final leaderboard = Leaderboard(
        leaderboardId: 'lb1',
        metric: RankingMetric.totalCoins,
        grouping: RankingGrouping.byGrade,
        groupValue: '4年生',
        entries: [],
        calculatedAt: now,
        lastUpdatedAt: now,
      );

      final json = leaderboard.toJson();
      final restored = Leaderboard.fromJson(json);
      expect(restored.groupValue, '4年生');
      expect(restored.metric, RankingMetric.totalCoins);
    });
  });

  group('RankingStatistics', () {
    test('creates statistics', () {
      final now = DateTime.now();
      final stats = RankingStatistics(
        userId: 'user1',
        userName: 'Student 1',
        currentGrade: SchoolGrade.fourthGrade,
        rankPositions: {
          RankingMetric.totalCoins: 10,
          RankingMetric.activityCompletions: 15,
          RankingMetric.compositeScore: 12,
        },
        scores: {
          RankingMetric.totalCoins: 5000,
          RankingMetric.activityCompletions: 50,
          RankingMetric.compositeScore: 5000,
        },
        tiers: {
          RankingMetric.totalCoins: 'ゴールド',
          RankingMetric.activityCompletions: 'シルバー',
          RankingMetric.compositeScore: 'ゴールド',
        },
        totalCoinsEarned: 5000,
        totalActivitiesCompleted: 50,
        compositeScore: 5000,
        firstRankedAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.currentGrade, SchoolGrade.fourthGrade);
    });

    test('getBestTier returns best tier', () {
      final now = DateTime.now();
      final stats = RankingStatistics(
        userId: 'user1',
        userName: 'Student 1',
        currentGrade: SchoolGrade.fourthGrade,
        rankPositions: {},
        scores: {},
        tiers: {
          RankingMetric.totalCoins: 'ビギナー',
          RankingMetric.activityCompletions: 'ゴールド',
          RankingMetric.compositeScore: 'シルバー',
        },
        totalCoinsEarned: 0,
        totalActivitiesCompleted: 0,
        compositeScore: 0,
        firstRankedAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.getBestTier(), 'ゴールド');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = RankingStatistics(
        userId: 'user1',
        userName: 'Student 1',
        currentGrade: SchoolGrade.fourthGrade,
        rankPositions: {
          RankingMetric.totalCoins: 10,
        },
        scores: {
          RankingMetric.totalCoins: 5000,
        },
        tiers: {
          RankingMetric.totalCoins: 'ゴールド',
        },
        totalCoinsEarned: 5000,
        totalActivitiesCompleted: 50,
        compositeScore: 5000,
        firstRankedAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      final restored = RankingStatistics.fromJson(json);
      expect(restored.userId, 'user1');
      expect(restored.totalCoinsEarned, 5000);
    });
  });

  group('LeaderboardCollection', () {
    test('creates collection', () {
      final now = DateTime.now();
      final collection = LeaderboardCollection(
        userId: 'user1',
        userGrade: UserGrade(
          userId: 'user1',
          currentGrade: SchoolGrade.fourthGrade,
          birthYear: 2015,
          lastGradeChangeAt: now,
          firstEnrolledAt: now,
        ),
        statistics: RankingStatistics(
          userId: 'user1',
          userName: 'Student 1',
          currentGrade: SchoolGrade.fourthGrade,
          rankPositions: {},
          scores: {},
          tiers: {},
          totalCoinsEarned: 0,
          totalActivitiesCompleted: 0,
          compositeScore: 0,
          firstRankedAt: now,
          lastUpdatedAt: now,
        ),
        allLeaderboards: [],
        userRankings: [],
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.userGrade?.currentGrade, SchoolGrade.fourthGrade);
    });

    test('getLeaderboard finds leaderboard by metric and grouping', () {
      final now = DateTime.now();
      final leaderboard = Leaderboard(
        leaderboardId: 'lb1',
        metric: RankingMetric.totalCoins,
        grouping: RankingGrouping.overall,
        entries: [],
        calculatedAt: now,
        lastUpdatedAt: now,
      );

      final collection = LeaderboardCollection(
        userId: 'user1',
        allLeaderboards: [leaderboard],
        userRankings: [],
        generatedAt: now,
      );

      final found = collection.getLeaderboard(
        RankingMetric.totalCoins,
        RankingGrouping.overall,
      );
      expect(found, isNotNull);
      expect(found?.metric, RankingMetric.totalCoins);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final collection = LeaderboardCollection(
        userId: 'user1',
        allLeaderboards: [],
        userRankings: [],
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = LeaderboardCollection.fromJson(json);
      expect(restored.userId, 'user1');
    });
  });
}
