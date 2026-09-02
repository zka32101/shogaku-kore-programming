import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/daily_login_reward.dart';

void main() {
  group('DailyLoginReward', () {
    test('creates instance with all required fields', () {
      final reward = DailyLoginReward(
        rewardId: 'reward_day1',
        level: RewardLevel.day1,
        xpAmount: 10,
        coinAmount: 5,
        description: '1日目ボーナス',
      );

      expect(reward.rewardId, 'reward_day1');
      expect(reward.level, RewardLevel.day1);
      expect(reward.xpAmount, 10);
      expect(reward.coinAmount, 5);
      expect(reward.description, '1日目ボーナス');
      expect(reward.badgeId, null);
      expect(reward.isStreakBonus, false);
    });

    test('creates instance with optional badge and streak bonus', () {
      final reward = DailyLoginReward(
        rewardId: 'reward_day7',
        level: RewardLevel.day7,
        xpAmount: 70,
        coinAmount: 35,
        badgeId: 'streak_7days',
        description: '7日連続ボーナス',
        isStreakBonus: true,
      );

      expect(reward.badgeId, 'streak_7days');
      expect(reward.isStreakBonus, true);
    });

    test('converts to JSON correctly', () {
      final reward = DailyLoginReward(
        rewardId: 'reward_day3',
        level: RewardLevel.day3,
        xpAmount: 30,
        coinAmount: 15,
        badgeId: 'streak_3days',
        description: '3日連続ボーナス',
        isStreakBonus: true,
      );

      final json = reward.toJson();

      expect(json['rewardId'], 'reward_day3');
      expect(json['level'], 'day3');
      expect(json['xpAmount'], 30);
      expect(json['coinAmount'], 15);
      expect(json['badgeId'], 'streak_3days');
      expect(json['description'], '3日連続ボーナス');
      expect(json['isStreakBonus'], true);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'rewardId': 'reward_day14',
        'level': 'day14',
        'xpAmount': 140,
        'coinAmount': 70,
        'badgeId': 'streak_14days',
        'description': '14日連続ボーナス',
        'isStreakBonus': true,
      };

      final reward = DailyLoginReward.fromJson(json);

      expect(reward.rewardId, 'reward_day14');
      expect(reward.level, RewardLevel.day14);
      expect(reward.xpAmount, 140);
      expect(reward.coinAmount, 70);
      expect(reward.badgeId, 'streak_14days');
      expect(reward.description, '14日連続ボーナス');
      expect(reward.isStreakBonus, true);
    });

    test('deserializes from JSON with missing optional fields', () {
      final json = {
        'rewardId': 'reward_day1',
        'level': 'day1',
        'xpAmount': 10,
        'coinAmount': 5,
        'description': '1日目ボーナス',
      };

      final reward = DailyLoginReward.fromJson(json);

      expect(reward.rewardId, 'reward_day1');
      expect(reward.level, RewardLevel.day1);
      expect(reward.badgeId, null);
      expect(reward.isStreakBonus, false);
    });

    test('JSON round-trip preserves all data', () {
      final original = DailyLoginReward(
        rewardId: 'reward_day30',
        level: RewardLevel.day30,
        xpAmount: 300,
        coinAmount: 150,
        badgeId: 'streak_30days',
        description: '30日連続ボーナス',
        isStreakBonus: true,
      );

      final json = original.toJson();
      final restored = DailyLoginReward.fromJson(json);

      expect(restored.rewardId, original.rewardId);
      expect(restored.level, original.level);
      expect(restored.xpAmount, original.xpAmount);
      expect(restored.coinAmount, original.coinAmount);
      expect(restored.badgeId, original.badgeId);
      expect(restored.description, original.description);
      expect(restored.isStreakBonus, original.isStreakBonus);
    });
  });

  group('LoginStreak', () {
    test('creates instance with basic fields', () {
      final now = DateTime.now();
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 5,
        longestStreak: 10,
        lastLoginDate: now,
      );

      expect(streak.userId, 'user123');
      expect(streak.currentStreak, 5);
      expect(streak.longestStreak, 10);
      expect(streak.lastLoginDate, now);
      expect(streak.streakStartDate, null);
      expect(streak.loginHistory, isEmpty);
    });

    test('isStreakActive returns true when logged in today', () {
      final now = DateTime.now();
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 3,
        longestStreak: 5,
        lastLoginDate: now,
      );

      expect(streak.isStreakActive, true);
    });

    test('isStreakActive returns true when logged in yesterday', () {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 3,
        longestStreak: 5,
        lastLoginDate: yesterday,
      );

      expect(streak.isStreakActive, true);
    });

    test('isStreakActive returns false when 2+ days since last login', () {
      final twoDaysAgo = DateTime.now().subtract(Duration(days: 2));
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 3,
        longestStreak: 5,
        lastLoginDate: twoDaysAgo,
      );

      expect(streak.isStreakActive, false);
    });

    test('isLoggedInToday returns true for same day login', () {
      final now = DateTime.now();
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 1,
        longestStreak: 1,
        lastLoginDate: now,
      );

      expect(streak.isLoggedInToday, true);
    });

    test('isLoggedInToday returns false for previous day login', () {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 1,
        longestStreak: 1,
        lastLoginDate: yesterday,
      );

      expect(streak.isLoggedInToday, false);
    });

    test('converts to JSON with ISO8601 dates', () {
      final now = DateTime(2024, 1, 15, 10, 30, 0);
      final startDate = DateTime(2024, 1, 10, 0, 0, 0);
      final loginDate1 = DateTime(2024, 1, 14, 8, 0, 0);
      final loginDate2 = DateTime(2024, 1, 15, 9, 0, 0);

      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 6,
        longestStreak: 10,
        lastLoginDate: now,
        streakStartDate: startDate,
        loginHistory: [loginDate1, loginDate2],
      );

      final json = streak.toJson();

      expect(json['userId'], 'user123');
      expect(json['currentStreak'], 6);
      expect(json['longestStreak'], 10);
      expect(json['lastLoginDate'], now.toIso8601String());
      expect(json['streakStartDate'], startDate.toIso8601String());
      expect(json['loginHistory'], isA<List>());
      expect(json['loginHistory'].length, 2);
    });

    test('deserializes from JSON with dates', () {
      final now = DateTime(2024, 1, 15, 10, 30, 0);
      final startDate = DateTime(2024, 1, 10, 0, 0, 0);
      final loginDate1 = DateTime(2024, 1, 14, 8, 0, 0);

      final json = {
        'userId': 'user456',
        'currentStreak': 5,
        'longestStreak': 12,
        'lastLoginDate': now.toIso8601String(),
        'streakStartDate': startDate.toIso8601String(),
        'loginHistory': [loginDate1.toIso8601String()],
      };

      final streak = LoginStreak.fromJson(json);

      expect(streak.userId, 'user456');
      expect(streak.currentStreak, 5);
      expect(streak.longestStreak, 12);
      expect(streak.lastLoginDate.toIso8601String(), now.toIso8601String());
      expect(streak.streakStartDate?.toIso8601String(), startDate.toIso8601String());
      expect(streak.loginHistory.length, 1);
    });

    test('handles empty login history', () {
      final json = {
        'userId': 'user789',
        'currentStreak': 0,
        'longestStreak': 5,
        'lastLoginDate': DateTime.now().toIso8601String(),
        'streakStartDate': null,
        'loginHistory': [],
      };

      final streak = LoginStreak.fromJson(json);

      expect(streak.loginHistory, isEmpty);
    });

    test('JSON round-trip preserves all data', () {
      final now = DateTime.now();
      final startDate = DateTime.now().subtract(Duration(days: 5));
      final original = LoginStreak(
        userId: 'user_test',
        currentStreak: 5,
        longestStreak: 15,
        lastLoginDate: now,
        streakStartDate: startDate,
        loginHistory: [now, now.subtract(Duration(days: 1))],
      );

      final json = original.toJson();
      final restored = LoginStreak.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.longestStreak, original.longestStreak);
      expect(restored.loginHistory.length, original.loginHistory.length);
    });
  });

  group('LoginRewardClaim', () {
    test('creates instance with all required fields', () {
      final now = DateTime.now();
      final claim = LoginRewardClaim(
        claimId: 'claim_001',
        userId: 'user123',
        rewardId: 'reward_day1',
        level: RewardLevel.day1,
        xpEarned: 10,
        coinEarned: 5,
        claimedAt: now,
        streakDayAtClaim: 1,
      );

      expect(claim.claimId, 'claim_001');
      expect(claim.userId, 'user123');
      expect(claim.rewardId, 'reward_day1');
      expect(claim.level, RewardLevel.day1);
      expect(claim.xpEarned, 10);
      expect(claim.coinEarned, 5);
      expect(claim.claimedAt, now);
      expect(claim.streakDayAtClaim, 1);
    });

    test('converts to JSON correctly', () {
      final now = DateTime(2024, 1, 15, 10, 30, 0);
      final claim = LoginRewardClaim(
        claimId: 'claim_003',
        userId: 'user456',
        rewardId: 'reward_day3',
        level: RewardLevel.day3,
        xpEarned: 30,
        coinEarned: 15,
        claimedAt: now,
        streakDayAtClaim: 3,
      );

      final json = claim.toJson();

      expect(json['claimId'], 'claim_003');
      expect(json['userId'], 'user456');
      expect(json['rewardId'], 'reward_day3');
      expect(json['level'], 'day3');
      expect(json['xpEarned'], 30);
      expect(json['coinEarned'], 15);
      expect(json['claimedAt'], now.toIso8601String());
      expect(json['streakDayAtClaim'], 3);
    });

    test('deserializes from JSON correctly', () {
      final now = DateTime(2024, 1, 15, 10, 30, 0);
      final json = {
        'claimId': 'claim_007',
        'userId': 'user789',
        'rewardId': 'reward_day7',
        'level': 'day7',
        'xpEarned': 70,
        'coinEarned': 35,
        'claimedAt': now.toIso8601String(),
        'streakDayAtClaim': 7,
      };

      final claim = LoginRewardClaim.fromJson(json);

      expect(claim.claimId, 'claim_007');
      expect(claim.userId, 'user789');
      expect(claim.rewardId, 'reward_day7');
      expect(claim.level, RewardLevel.day7);
      expect(claim.xpEarned, 70);
      expect(claim.coinEarned, 35);
      expect(claim.streakDayAtClaim, 7);
    });

    test('JSON round-trip preserves all data', () {
      final now = DateTime.now();
      final original = LoginRewardClaim(
        claimId: 'claim_test',
        userId: 'user_test',
        rewardId: 'reward_test',
        level: RewardLevel.day30,
        xpEarned: 300,
        coinEarned: 150,
        claimedAt: now,
        streakDayAtClaim: 30,
      );

      final json = original.toJson();
      final restored = LoginRewardClaim.fromJson(json);

      expect(restored.claimId, original.claimId);
      expect(restored.userId, original.userId);
      expect(restored.rewardId, original.rewardId);
      expect(restored.level, original.level);
      expect(restored.xpEarned, original.xpEarned);
      expect(restored.coinEarned, original.coinEarned);
      expect(restored.streakDayAtClaim, original.streakDayAtClaim);
    });
  });

  group('LoginRewardStats', () {
    test('creates instance with required fields', () {
      final now = DateTime.now();
      final stats = LoginRewardStats(
        userId: 'user123',
        totalRewardsClaimed: 5,
        totalXpEarned: 150,
        totalCoinEarned: 75,
        firstLoginDate: now,
        lastResetDate: now,
      );

      expect(stats.userId, 'user123');
      expect(stats.totalRewardsClaimed, 5);
      expect(stats.totalXpEarned, 150);
      expect(stats.totalCoinEarned, 75);
      expect(stats.firstLoginDate, now);
      expect(stats.lastResetDate, now);
      expect(stats.recentClaims, isEmpty);
    });

    test('creates instance with recent claims', () {
      final now = DateTime.now();
      final claim1 = LoginRewardClaim(
        claimId: 'claim1',
        userId: 'user123',
        rewardId: 'reward_day1',
        level: RewardLevel.day1,
        xpEarned: 10,
        coinEarned: 5,
        claimedAt: now,
        streakDayAtClaim: 1,
      );
      final claim2 = LoginRewardClaim(
        claimId: 'claim2',
        userId: 'user123',
        rewardId: 'reward_day3',
        level: RewardLevel.day3,
        xpEarned: 30,
        coinEarned: 15,
        claimedAt: now.add(Duration(days: 1)),
        streakDayAtClaim: 3,
      );

      final stats = LoginRewardStats(
        userId: 'user123',
        totalRewardsClaimed: 2,
        totalXpEarned: 40,
        totalCoinEarned: 20,
        firstLoginDate: now,
        lastResetDate: now,
        recentClaims: [claim1, claim2],
      );

      expect(stats.recentClaims.length, 2);
      expect(stats.recentClaims[0].claimId, 'claim1');
      expect(stats.recentClaims[1].claimId, 'claim2');
    });

    test('converts to JSON correctly', () {
      final now = DateTime(2024, 1, 15, 10, 30, 0);
      final stats = LoginRewardStats(
        userId: 'user456',
        totalRewardsClaimed: 10,
        totalXpEarned: 300,
        totalCoinEarned: 150,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final json = stats.toJson();

      expect(json['userId'], 'user456');
      expect(json['totalRewardsClaimed'], 10);
      expect(json['totalXpEarned'], 300);
      expect(json['totalCoinEarned'], 150);
      expect(json['firstLoginDate'], now.toIso8601String());
      expect(json['lastResetDate'], now.toIso8601String());
      expect(json['recentClaims'], isA<List>());
    });

    test('deserializes from JSON correctly', () {
      final now = DateTime(2024, 1, 15, 10, 30, 0);
      final json = {
        'userId': 'user789',
        'totalRewardsClaimed': 7,
        'totalXpEarned': 210,
        'totalCoinEarned': 105,
        'firstLoginDate': now.toIso8601String(),
        'lastResetDate': now.toIso8601String(),
        'recentClaims': [],
      };

      final stats = LoginRewardStats.fromJson(json);

      expect(stats.userId, 'user789');
      expect(stats.totalRewardsClaimed, 7);
      expect(stats.totalXpEarned, 210);
      expect(stats.totalCoinEarned, 105);
      expect(stats.recentClaims, isEmpty);
    });

    test('handles null firstLoginDate', () {
      final now = DateTime.now();
      final json = {
        'userId': 'user_new',
        'totalRewardsClaimed': 0,
        'totalXpEarned': 0,
        'totalCoinEarned': 0,
        'firstLoginDate': null,
        'lastResetDate': now.toIso8601String(),
        'recentClaims': [],
      };

      final stats = LoginRewardStats.fromJson(json);

      expect(stats.firstLoginDate, null);
    });

    test('JSON round-trip preserves all data', () {
      final now = DateTime.now();
      final original = LoginRewardStats(
        userId: 'user_test',
        totalRewardsClaimed: 15,
        totalXpEarned: 450,
        totalCoinEarned: 225,
        firstLoginDate: now.subtract(Duration(days: 15)),
        lastResetDate: now,
      );

      final json = original.toJson();
      final restored = LoginRewardStats.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.totalRewardsClaimed, original.totalRewardsClaimed);
      expect(restored.totalXpEarned, original.totalXpEarned);
      expect(restored.totalCoinEarned, original.totalCoinEarned);
    });
  });

  group('DailyLoginRewardData', () {
    test('creates instance with all required data', () {
      final now = DateTime.now();
      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 1,
        longestStreak: 5,
        lastLoginDate: now,
      );
      final stats = LoginRewardStats(
        userId: 'user123',
        totalRewardsClaimed: 1,
        totalXpEarned: 10,
        totalCoinEarned: 5,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final data = DailyLoginRewardData(
        availableRewards: rewards,
        userStreak: streak,
        stats: stats,
        generatedAt: now,
      );

      expect(data.availableRewards.length, 1);
      expect(data.userStreak.userId, 'user123');
      expect(data.stats.userId, 'user123');
      expect(data.generatedAt, now);
    });

    test('getNextReward returns day1 for new users', () {
      final now = DateTime.now();
      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
        DailyLoginReward(
          rewardId: 'reward_day3',
          level: RewardLevel.day3,
          xpAmount: 30,
          coinAmount: 15,
          description: '3日連続ボーナス',
        ),
      ];
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 0,
        longestStreak: 0,
        lastLoginDate: now.subtract(Duration(days: 2)),
      );
      final stats = LoginRewardStats(
        userId: 'user123',
        totalRewardsClaimed: 0,
        totalXpEarned: 0,
        totalCoinEarned: 0,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final data = DailyLoginRewardData(
        availableRewards: rewards,
        userStreak: streak,
        stats: stats,
        generatedAt: now,
      );

      final nextReward = data.getNextReward();
      expect(nextReward?.level, RewardLevel.day1);
      expect(nextReward?.xpAmount, 10);
    });

    test('getNextReward returns correct milestone', () {
      final now = DateTime.now();
      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
        DailyLoginReward(
          rewardId: 'reward_day3',
          level: RewardLevel.day3,
          xpAmount: 30,
          coinAmount: 15,
          description: '3日連続ボーナス',
        ),
        DailyLoginReward(
          rewardId: 'reward_day7',
          level: RewardLevel.day7,
          xpAmount: 70,
          coinAmount: 35,
          description: '7日連続ボーナス',
        ),
      ];
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 2,
        longestStreak: 5,
        lastLoginDate: now,
      );
      final stats = LoginRewardStats(
        userId: 'user123',
        totalRewardsClaimed: 2,
        totalXpEarned: 40,
        totalCoinEarned: 20,
        firstLoginDate: now.subtract(Duration(days: 2)),
        lastResetDate: now,
      );

      final data = DailyLoginRewardData(
        availableRewards: rewards,
        userStreak: streak,
        stats: stats,
        generatedAt: now,
      );

      final nextReward = data.getNextReward();
      expect(nextReward?.level, RewardLevel.day3);
    });

    test('canClaimToday returns true when not claimed', () {
      final now = DateTime.now();
      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 1,
        longestStreak: 5,
        lastLoginDate: now.subtract(Duration(days: 1)),
      );
      final stats = LoginRewardStats(
        userId: 'user123',
        totalRewardsClaimed: 5,
        totalXpEarned: 150,
        totalCoinEarned: 75,
        firstLoginDate: now.subtract(Duration(days: 5)),
        lastResetDate: now,
      );

      final data = DailyLoginRewardData(
        availableRewards: rewards,
        userStreak: streak,
        stats: stats,
        generatedAt: now,
      );

      expect(data.canClaimToday(), true);
    });

    test('canClaimToday returns false when already claimed', () {
      final now = DateTime.now();
      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];
      final streak = LoginStreak(
        userId: 'user123',
        currentStreak: 5,
        longestStreak: 10,
        lastLoginDate: now,
      );
      final stats = LoginRewardStats(
        userId: 'user123',
        totalRewardsClaimed: 5,
        totalXpEarned: 150,
        totalCoinEarned: 75,
        firstLoginDate: now.subtract(Duration(days: 5)),
        lastResetDate: now,
      );

      final data = DailyLoginRewardData(
        availableRewards: rewards,
        userStreak: streak,
        stats: stats,
        generatedAt: now,
      );

      expect(data.canClaimToday(), false);
    });

    test('JSON round-trip preserves structure', () {
      final now = DateTime.now();
      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];
      final streak = LoginStreak(
        userId: 'user_test',
        currentStreak: 3,
        longestStreak: 10,
        lastLoginDate: now,
      );
      final stats = LoginRewardStats(
        userId: 'user_test',
        totalRewardsClaimed: 3,
        totalXpEarned: 90,
        totalCoinEarned: 45,
        firstLoginDate: now.subtract(Duration(days: 3)),
        lastResetDate: now,
      );

      final original = DailyLoginRewardData(
        availableRewards: rewards,
        userStreak: streak,
        stats: stats,
        generatedAt: now,
      );

      final json = original.toJson();
      final restored = DailyLoginRewardData.fromJson(json);

      expect(restored.availableRewards.length, original.availableRewards.length);
      expect(restored.userStreak.userId, original.userStreak.userId);
      expect(restored.stats.userId, original.stats.userId);
    });
  });
}
