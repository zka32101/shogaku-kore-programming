import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/streaks_daily_rewards.dart';

void main() {
  group('DailyRewardTier', () {
    test('creates tier with required fields', () {
      final tier = DailyRewardTier(
        dayNumber: 1,
        rewardName: '1日目報酬',
        coinReward: 100,
        xpReward: 50,
      );

      expect(tier.dayNumber, 1);
      expect(tier.rewardName, '1日目報酬');
      expect(tier.coinReward, 100);
      expect(tier.xpReward, 50);
      expect(tier.isMilestone, false);
    });

    test('creates milestone tier', () {
      final tier = DailyRewardTier(
        dayNumber: 7,
        rewardName: '7日目報酬',
        coinReward: 500,
        xpReward: 250,
        premiumCoinReward: 1,
        isMilestone: true,
      );

      expect(tier.isMilestone, true);
      expect(tier.premiumCoinReward, 1);
    });

    test('toJson serializes tier', () {
      final tier = DailyRewardTier(
        dayNumber: 1,
        rewardName: '1日目報酬',
        coinReward: 100,
        xpReward: 50,
        premiumCoinReward: null,
      );

      final json = tier.toJson();
      expect(json['dayNumber'], 1);
      expect(json['rewardName'], '1日目報酬');
      expect(json['coinReward'], 100);
      expect(json['isMilestone'], false);
    });

    test('fromJson deserializes tier', () {
      final json = {
        'dayNumber': 7,
        'rewardName': '7日目報酬',
        'coinReward': 500,
        'xpReward': 250,
        'premiumCoinReward': 1,
        'isMilestone': true,
      };

      final tier = DailyRewardTier.fromJson(json);
      expect(tier.dayNumber, 7);
      expect(tier.isMilestone, true);
      expect(tier.premiumCoinReward, 1);
    });
  });

  group('DailyLogin', () {
    test('creates login with required fields', () {
      final now = DateTime.now();
      final login = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: now,
      );

      expect(login.loginId, 'login1');
      expect(login.userId, 'user1');
      expect(login.claimedReward, false);
      expect(login.coinsEarned, 0);
    });

    test('isToday returns true for today login', () {
      final now = DateTime.now();
      final login = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: now,
      );

      expect(login.isToday, true);
    });

    test('isToday returns false for past login', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final login = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: yesterday,
      );

      expect(login.isToday, false);
    });

    test('getSessionMinutes calculates correctly with logout', () {
      final now = DateTime.now();
      final login = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: now,
        logoutDate: now.add(const Duration(minutes: 30)),
      );

      expect(login.getSessionMinutes(), 30);
    });

    test('getSessionMinutes calculates with current time if no logout', () {
      final now = DateTime.now();
      final login = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: now,
      );

      final minutes = login.getSessionMinutes();
      expect(minutes, lessThanOrEqualTo(1));
    });

    test('toJson serializes login', () {
      final now = DateTime.now();
      final login = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: now,
        claimedReward: true,
        coinsEarned: 100,
        xpEarned: 50,
      );

      final json = login.toJson();
      expect(json['loginId'], 'login1');
      expect(json['claimedReward'], true);
      expect(json['coinsEarned'], 100);
    });

    test('fromJson deserializes login', () {
      final now = DateTime.now();
      final json = {
        'loginId': 'login1',
        'userId': 'user1',
        'loginDate': now.toIso8601String(),
        'claimedReward': true,
        'coinsEarned': 100,
      };

      final login = DailyLogin.fromJson(json);
      expect(login.loginId, 'login1');
      expect(login.claimedReward, true);
    });
  });

  group('UserStreak', () {
    test('creates streak with required fields', () {
      final now = DateTime.now();
      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );

      expect(streak.streakId, 'streak1');
      expect(streak.currentStreak, 5);
      expect(streak.isActive, true);
    });

    test('isAtRisk returns true when no login today', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: yesterday,
        lastLoginDate: yesterday,
        lastUpdatedAt: yesterday,
      );

      expect(streak.isAtRisk, true);
    });

    test('isAtRisk returns false when logged in today', () {
      final now = DateTime.now();
      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );

      expect(streak.isAtRisk, false);
    });

    test('daysUntilBroken returns 0 or 1 when at risk', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: yesterday,
        lastLoginDate: yesterday,
        lastUpdatedAt: yesterday,
      );

      final days = streak.daysUntilBroken;
      expect(days >= 0 && days <= 2, true);
    });

    test('getStreakStatus returns correct status', () {
      final now = DateTime.now();

      final brokenStreak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 0,
        longestStreak: 5,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );
      expect(brokenStreak.getStreakStatus(), '中断');

      final atRiskStreak = UserStreak(
        streakId: 'streak2',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: now.subtract(const Duration(days: 5)),
        lastLoginDate: now.subtract(const Duration(days: 1)),
        lastUpdatedAt: now.subtract(const Duration(days: 1)),
      );
      expect(atRiskStreak.getStreakStatus(), '危機');

      final activeStreak = UserStreak(
        streakId: 'streak3',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: now.subtract(const Duration(days: 5)),
        lastLoginDate: now,
        lastUpdatedAt: now,
      );
      expect(activeStreak.getStreakStatus(), 'アクティブ');
    });

    test('toJson serializes streak', () {
      final now = DateTime.now();
      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );

      final json = streak.toJson();
      expect(json['streakId'], 'streak1');
      expect(json['currentStreak'], 5);
      expect(json['longestStreak'], 10);
    });

    test('fromJson deserializes streak', () {
      final now = DateTime.now();
      final json = {
        'streakId': 'streak1',
        'userId': 'user1',
        'currentStreak': 5,
        'longestStreak': 10,
        'streakStartDate': now.toIso8601String(),
        'lastLoginDate': now.toIso8601String(),
        'lastUpdatedAt': now.toIso8601String(),
      };

      final streak = UserStreak.fromJson(json);
      expect(streak.streakId, 'streak1');
      expect(streak.currentStreak, 5);
    });
  });

  group('DailyRewardClaim', () {
    test('creates claim with required fields', () {
      final now = DateTime.now();
      final claim = DailyRewardClaim(
        claimId: 'claim1',
        userId: 'user1',
        dayNumber: 1,
        claimedAt: now,
        coinsReward: 100,
        xpReward: 50,
      );

      expect(claim.claimId, 'claim1');
      expect(claim.dayNumber, 1);
      expect(claim.coinsReward, 100);
    });

    test('creates claim with streak multiplier', () {
      final now = DateTime.now();
      final claim = DailyRewardClaim(
        claimId: 'claim1',
        userId: 'user1',
        dayNumber: 1,
        claimedAt: now,
        coinsReward: 100,
        xpReward: 50,
        streakMultiplier: 1.5,
      );

      expect(claim.streakMultiplier, 1.5);
    });

    test('toJson serializes claim', () {
      final now = DateTime.now();
      final claim = DailyRewardClaim(
        claimId: 'claim1',
        userId: 'user1',
        dayNumber: 1,
        claimedAt: now,
        coinsReward: 100,
        xpReward: 50,
        streakMultiplier: 1.2,
      );

      final json = claim.toJson();
      expect(json['claimId'], 'claim1');
      expect(json['coinsReward'], 100);
      expect(json['streakMultiplier'], 1.2);
    });

    test('fromJson deserializes claim', () {
      final now = DateTime.now();
      final json = {
        'claimId': 'claim1',
        'userId': 'user1',
        'dayNumber': 1,
        'claimedAt': now.toIso8601String(),
        'coinsReward': 100,
        'xpReward': 50,
        'streakMultiplier': 1.5,
      };

      final claim = DailyRewardClaim.fromJson(json);
      expect(claim.claimId, 'claim1');
      expect(claim.streakMultiplier, 1.5);
    });
  });

  group('StreakStatistics', () {
    test('creates statistics with required fields', () {
      final now = DateTime.now();
      final stats = StreakStatistics(
        userId: 'user1',
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalLoginsEver, 0);
      expect(stats.consecutiveDaysActive, 0);
    });

    test('getStreakTier returns correct tiers', () {
      final now = DateTime.now();

      final beginnerStats = StreakStatistics(
        userId: 'user1',
        consecutiveDaysActive: 1,
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );
      expect(beginnerStats.getStreakTier(), '初心者');

      final steadyStats = StreakStatistics(
        userId: 'user2',
        consecutiveDaysActive: 5,
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );
      expect(steadyStats.getStreakTier(), '着実');

      const reliableStats = StreakStatistics(
        userId: 'user3',
        consecutiveDaysActive: 10,
        firstLoginAt: DateTime(2024),
        lastLoginAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(reliableStats.getStreakTier(), '堅実');

      const habitFormingStats = StreakStatistics(
        userId: 'user4',
        consecutiveDaysActive: 20,
        firstLoginAt: DateTime(2024),
        lastLoginAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(habitFormingStats.getStreakTier(), '習慣形成');

      const commitmentStats = StreakStatistics(
        userId: 'user5',
        consecutiveDaysActive: 50,
        firstLoginAt: DateTime(2024),
        lastLoginAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(commitmentStats.getStreakTier(), 'コミットメント');

      const legendStats = StreakStatistics(
        userId: 'user6',
        consecutiveDaysActive: 100,
        firstLoginAt: DateTime(2024),
        lastLoginAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(legendStats.getStreakTier(), 'レジェンド');
    });

    test('toJson serializes statistics', () {
      final now = DateTime.now();
      final stats = StreakStatistics(
        userId: 'user1',
        totalLoginsEver: 50,
        consecutiveDaysActive: 10,
        longestStreak: 30,
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      expect(json['userId'], 'user1');
      expect(json['totalLoginsEver'], 50);
      expect(json['longestStreak'], 30);
    });

    test('fromJson deserializes statistics', () {
      final now = DateTime.now();
      final json = {
        'userId': 'user1',
        'totalLoginsEver': 50,
        'consecutiveDaysActive': 10,
        'longestStreak': 30,
        'firstLoginAt': now.toIso8601String(),
        'lastLoginAt': now.toIso8601String(),
        'lastUpdatedAt': now.toIso8601String(),
      };

      final stats = StreakStatistics.fromJson(json);
      expect(stats.userId, 'user1');
      expect(stats.totalLoginsEver, 50);
    });
  });

  group('StreakAndRewardCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 0,
        longestStreak: 0,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );
      final stats = StreakStatistics(
        userId: 'user1',
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      final collection = StreakAndRewardCollection(
        userId: 'user1',
        currentStreak: streak,
        loginHistory: [],
        rewardClaims: [],
        rewardSchedule: [],
        statistics: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.loginHistory.isEmpty, true);
    });

    test('getTodaysReward returns correct reward', () {
      final now = DateTime.now();
      final dayOfMonth = now.day;

      final tier = DailyRewardTier(
        dayNumber: dayOfMonth,
        rewardName: '$dayOfMonth日目報酬',
        coinReward: 100,
        xpReward: 50,
      );

      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 0,
        longestStreak: 0,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );
      final stats = StreakStatistics(
        userId: 'user1',
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      final collection = StreakAndRewardCollection(
        userId: 'user1',
        currentStreak: streak,
        loginHistory: [],
        rewardClaims: [],
        rewardSchedule: [tier],
        statistics: stats,
        generatedAt: now,
      );

      final reward = collection.getTodaysReward();
      expect(reward, isNotNull);
      expect(reward!.dayNumber, dayOfMonth);
    });

    test('getLoginsThisMonth filters correctly', () {
      final now = DateTime.now();
      final thisMonth = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: now,
      );
      final lastMonth = DailyLogin(
        loginId: 'login2',
        userId: 'user1',
        loginDate: now.subtract(const Duration(days: 40)),
      );

      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 0,
        longestStreak: 0,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );
      final stats = StreakStatistics(
        userId: 'user1',
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      final collection = StreakAndRewardCollection(
        userId: 'user1',
        currentStreak: streak,
        loginHistory: [thisMonth, lastMonth],
        rewardClaims: [],
        rewardSchedule: [],
        statistics: stats,
        generatedAt: now,
      );

      final monthlyLogins = collection.getLoginsThisMonth();
      expect(monthlyLogins.length, 1);
      expect(monthlyLogins[0].loginId, 'login1');
    });

    test('getRecentLogins filters by days', () {
      final now = DateTime.now();
      final recent = DailyLogin(
        loginId: 'login1',
        userId: 'user1',
        loginDate: now.subtract(const Duration(days: 3)),
      );
      final old = DailyLogin(
        loginId: 'login2',
        userId: 'user1',
        loginDate: now.subtract(const Duration(days: 30)),
      );

      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 0,
        longestStreak: 0,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );
      final stats = StreakStatistics(
        userId: 'user1',
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      final collection = StreakAndRewardCollection(
        userId: 'user1',
        currentStreak: streak,
        loginHistory: [recent, old],
        rewardClaims: [],
        rewardSchedule: [],
        statistics: stats,
        generatedAt: now,
      );

      final recentLogins = collection.getRecentLogins(days: 7);
      expect(recentLogins.length, 1);
      expect(recentLogins[0].loginId, 'login1');
    });

    test('getStreakBonusMultiplier returns correct values', () {
      final now = DateTime.now();

      for (int streak = 0; streak <= 100; streak++) {
        final currentStreak = UserStreak(
          streakId: 'streak1',
          userId: 'user1',
          currentStreak: streak,
          longestStreak: streak,
          streakStartDate: now,
          lastLoginDate: now,
          lastUpdatedAt: now,
        );
        final stats = StreakStatistics(
          userId: 'user1',
          firstLoginAt: now,
          lastLoginAt: now,
          lastUpdatedAt: now,
        );

        final collection = StreakAndRewardCollection(
          userId: 'user1',
          currentStreak: currentStreak,
          loginHistory: [],
          rewardClaims: [],
          rewardSchedule: [],
          statistics: stats,
          generatedAt: now,
        );

        final multiplier = collection.getStreakBonusMultiplier();
        expect(multiplier >= 1.0 && multiplier <= 2.5, true);
      }
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final streak = UserStreak(
        streakId: 'streak1',
        userId: 'user1',
        currentStreak: 5,
        longestStreak: 10,
        streakStartDate: now,
        lastLoginDate: now,
        lastUpdatedAt: now,
      );
      final stats = StreakStatistics(
        userId: 'user1',
        firstLoginAt: now,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      final collection = StreakAndRewardCollection(
        userId: 'user1',
        currentStreak: streak,
        loginHistory: [],
        rewardClaims: [],
        rewardSchedule: [],
        statistics: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = StreakAndRewardCollection.fromJson(json);

      expect(restored.userId, collection.userId);
      expect(restored.currentStreak.currentStreak, 5);
    });
  });
}
