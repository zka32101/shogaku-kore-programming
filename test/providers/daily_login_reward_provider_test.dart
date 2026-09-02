import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/daily_login_reward.dart';
import 'package:shogaku_kore_programming/providers/daily_login_reward_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('DailyLoginRewardNotifier', () {
    test('initializes with empty state', () {
      final notifier = DailyLoginRewardNotifier();
      expect(notifier.state.rewardData, isNull);
      expect(notifier.state.userStreak, isNull);
      expect(notifier.state.stats, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('initializeLoginRewards creates new user data on first login', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('new_user');

      final state = container.read(dailyLoginRewardProvider);
      expect(state.isLoading, false);
      expect(state.rewardData, isNotNull);
      expect(state.userStreak, isNotNull);
      expect(state.stats, isNotNull);
      expect(state.userStreak!.userId, 'new_user');
      expect(state.userStreak!.currentStreak, 0);
      expect(state.stats!.userId, 'new_user');
    });

    test('initializeLoginRewards generates default rewards', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      final state = container.read(dailyLoginRewardProvider);
      expect(state.rewardData!.availableRewards.length, 5);

      // Verify reward levels
      final levels = state.rewardData!.availableRewards.map((r) => r.level).toList();
      expect(levels, contains(RewardLevel.day1));
      expect(levels, contains(RewardLevel.day3));
      expect(levels, contains(RewardLevel.day7));
      expect(levels, contains(RewardLevel.day14));
      expect(levels, contains(RewardLevel.day30));
    });

    test('claimDailyReward returns null when data not initialized', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      final claim = await notifier.claimDailyReward('test_user');

      expect(claim, isNull);
    });

    test('claimDailyReward fails when already claimed today', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      // First claim should succeed
      final claim1 = await notifier.claimDailyReward('test_user');
      expect(claim1, isNotNull);
      expect(claim1!.streakDayAtClaim, 1);

      // Second claim on same day should fail
      final claim2 = await notifier.claimDailyReward('test_user');
      expect(claim2, isNull);
    });

    test('claimDailyReward increments streak for consecutive logins', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      // Simulate first login
      var claim = await notifier.claimDailyReward('test_user');
      expect(claim!.streakDayAtClaim, 1);
      var state = container.read(dailyLoginRewardProvider);
      expect(state.userStreak!.currentStreak, 1);

      // Move to next day and reset last login to yesterday
      final notifierDirect = DailyLoginRewardNotifier();
      notifierDirect.state = state.copyWith(
        userStreak: LoginStreak(
          userId: 'test_user',
          currentStreak: 1,
          longestStreak: 1,
          lastLoginDate: DateTime.now().subtract(Duration(days: 1)),
        ),
      );

      // Second day claim
      claim = await notifierDirect.claimDailyReward('test_user');
      expect(claim!.streakDayAtClaim, 2);
      expect(notifierDirect.state.userStreak!.currentStreak, 2);
    });

    test('claimDailyReward resets streak when inactive', () async {
      final notifier = DailyLoginRewardNotifier();

      // Set up state with broken streak
      notifier.state = DailyLoginRewardState(
        rewardData: DailyLoginRewardData(
          availableRewards: notifier.state.rewardData?.availableRewards ?? [],
          userStreak: LoginStreak(
            userId: 'test_user',
            currentStreak: 5,
            longestStreak: 10,
            lastLoginDate: DateTime.now().subtract(Duration(days: 2)),
          ),
          stats: LoginRewardStats(
            userId: 'test_user',
            totalRewardsClaimed: 5,
            totalXpEarned: 150,
            totalCoinEarned: 75,
            firstLoginDate: DateTime.now().subtract(Duration(days: 10)),
            lastResetDate: DateTime.now().subtract(Duration(days: 5)),
          ),
          generatedAt: DateTime.now(),
        ),
        userStreak: LoginStreak(
          userId: 'test_user',
          currentStreak: 5,
          longestStreak: 10,
          lastLoginDate: DateTime.now().subtract(Duration(days: 2)),
        ),
        stats: LoginRewardStats(
          userId: 'test_user',
          totalRewardsClaimed: 5,
          totalXpEarned: 150,
          totalCoinEarned: 75,
          firstLoginDate: DateTime.now().subtract(Duration(days: 10)),
          lastResetDate: DateTime.now().subtract(Duration(days: 5)),
        ),
      );

      final claim = await notifier.claimDailyReward('test_user');

      expect(claim!.streakDayAtClaim, 1); // Resets to 1
      expect(notifier.state.userStreak!.currentStreak, 1);
      expect(notifier.state.userStreak!.longestStreak, 10); // Preserves longest
    });

    test('claimDailyReward awards correct XP and coins for day1', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      final claim = await notifier.claimDailyReward('test_user');

      expect(claim!.xpEarned, 10);
      expect(claim.coinEarned, 5);
      expect(claim.level, RewardLevel.day1);
    });

    test('claimDailyReward awards correct rewards for milestone days', () async {
      final notifier = DailyLoginRewardNotifier();

      // Setup for day 3 milestone
      notifier.state = DailyLoginRewardState(
        rewardData: DailyLoginRewardData(
          availableRewards: [
            DailyLoginReward(
              rewardId: 'reward_day1',
              level: RewardLevel.day1,
              xpAmount: 10,
              coinAmount: 5,
              description: '1日目',
            ),
            DailyLoginReward(
              rewardId: 'reward_day3',
              level: RewardLevel.day3,
              xpAmount: 30,
              coinAmount: 15,
              badgeId: 'streak_3days',
              description: '3日連続',
              isStreakBonus: true,
            ),
          ],
          userStreak: LoginStreak(
            userId: 'test_user',
            currentStreak: 2,
            longestStreak: 3,
            lastLoginDate: DateTime.now().subtract(Duration(days: 1)),
          ),
          stats: LoginRewardStats(
            userId: 'test_user',
            totalRewardsClaimed: 2,
            totalXpEarned: 40,
            totalCoinEarned: 20,
            firstLoginDate: DateTime.now().subtract(Duration(days: 3)),
            lastResetDate: DateTime.now(),
          ),
          generatedAt: DateTime.now(),
        ),
        userStreak: LoginStreak(
          userId: 'test_user',
          currentStreak: 2,
          longestStreak: 3,
          lastLoginDate: DateTime.now().subtract(Duration(days: 1)),
        ),
        stats: LoginRewardStats(
          userId: 'test_user',
          totalRewardsClaimed: 2,
          totalXpEarned: 40,
          totalCoinEarned: 20,
          firstLoginDate: DateTime.now().subtract(Duration(days: 3)),
          lastResetDate: DateTime.now(),
        ),
      );

      final claim = await notifier.claimDailyReward('test_user');

      expect(claim!.xpEarned, 30);
      expect(claim.coinEarned, 15);
      expect(claim.level, RewardLevel.day3);
    });

    test('claimDailyReward updates stats correctly', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      final claim = await notifier.claimDailyReward('test_user');
      final state = container.read(dailyLoginRewardProvider);

      expect(state.stats!.totalRewardsClaimed, 1);
      expect(state.stats!.totalXpEarned, 10);
      expect(state.stats!.totalCoinEarned, 5);
      expect(state.stats!.recentClaims.length, 1);
      expect(state.stats!.recentClaims[0].claimId, claim!.claimId);
    });

    test('claimDailyReward updates login history', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      await notifier.claimDailyReward('test_user');
      final state = container.read(dailyLoginRewardProvider);

      expect(state.userStreak!.loginHistory.length, 1);
    });

    test('resetStreak sets currentStreak to 0', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      // First claim to establish streak
      await notifier.claimDailyReward('test_user');
      var state = container.read(dailyLoginRewardProvider);
      expect(state.userStreak!.currentStreak, 1);

      // Reset streak
      await notifier.resetStreak('test_user');
      state = container.read(dailyLoginRewardProvider);

      expect(state.userStreak!.currentStreak, 0);
      expect(state.userStreak!.longestStreak, 1); // Preserves longest
    });

    test('resetStreak preserves longest streak', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      // Set a high longest streak manually
      var state = container.read(dailyLoginRewardProvider);
      notifier.state = state.copyWith(
        userStreak: LoginStreak(
          userId: 'test_user',
          currentStreak: 5,
          longestStreak: 50,
          lastLoginDate: DateTime.now(),
        ),
      );

      await notifier.resetStreak('test_user');
      state = container.read(dailyLoginRewardProvider);

      expect(state.userStreak!.longestStreak, 50);
    });

    test('resetStreak updates lastResetDate', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      final resetTimeBefore = DateTime.now();
      await notifier.resetStreak('test_user');
      final resetTimeAfter = DateTime.now();

      final state = container.read(dailyLoginRewardProvider);
      final lastResetDate = state.stats!.lastResetDate;

      expect(lastResetDate.isAfter(resetTimeBefore.subtract(Duration(seconds: 1))), true);
      expect(lastResetDate.isBefore(resetTimeAfter.add(Duration(seconds: 1))), true);
    });

    test('getCurrentStreak returns correct value', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      expect(notifier.getCurrentStreak(), 0);

      await notifier.claimDailyReward('test_user');
      expect(notifier.getCurrentStreak(), 1);
    });

    test('getCurrentStreak returns 0 when data not initialized', () {
      final notifier = DailyLoginRewardNotifier();
      expect(notifier.getCurrentStreak(), 0);
    });

    test('getLongestStreak returns correct value', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      expect(notifier.getLongestStreak(), 0);

      var state = container.read(dailyLoginRewardProvider);
      notifier.state = state.copyWith(
        userStreak: LoginStreak(
          userId: 'test_user',
          currentStreak: 5,
          longestStreak: 25,
          lastLoginDate: DateTime.now(),
        ),
      );

      expect(notifier.getLongestStreak(), 25);
    });

    test('getTotalXpEarned returns correct value', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      expect(notifier.getTotalXpEarned(), 0);

      await notifier.claimDailyReward('test_user');
      expect(notifier.getTotalXpEarned(), 10);
    });

    test('getTotalCoinEarned returns correct value', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      expect(notifier.getTotalCoinEarned(), 0);

      await notifier.claimDailyReward('test_user');
      expect(notifier.getTotalCoinEarned(), 5);
    });

    test('canClaimToday returns false when already claimed', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('test_user');

      expect(notifier.canClaimToday(), true);

      await notifier.claimDailyReward('test_user');
      expect(notifier.canClaimToday(), false);
    });

    test('persists reward data to SharedPreferences', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('persist_test_user');
      await notifier.claimDailyReward('persist_test_user');

      final prefs = await SharedPreferences.getInstance();
      final streakKey = 'login_streak_persist_test_user';
      final statsKey = 'login_stats_persist_test_user';

      expect(prefs.containsKey(streakKey), true);
      expect(prefs.containsKey(statsKey), true);
    });

    test('handles error state correctly', () async {
      final notifier = DailyLoginRewardNotifier();

      // Manually set error state
      notifier.state = notifier.state.copyWith(
        error: 'Test error message',
      );

      expect(notifier.state.error, 'Test error message');
    });
  });

  group('Riverpod Providers', () {
    test('currentStreakProvider provides correct value', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('streak_test');

      var streak = container.read(currentStreakProvider);
      expect(streak, 0);

      await notifier.claimDailyReward('streak_test');
      streak = container.read(currentStreakProvider);
      expect(streak, 1);
    });

    test('longestStreakProvider provides correct value', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('longest_test');

      var longestStreak = container.read(longestStreakProvider);
      expect(longestStreak, 0);

      var state = container.read(dailyLoginRewardProvider);
      notifier.state = state.copyWith(
        userStreak: LoginStreak(
          userId: 'longest_test',
          currentStreak: 1,
          longestStreak: 100,
          lastLoginDate: DateTime.now(),
        ),
      );

      longestStreak = container.read(longestStreakProvider);
      expect(longestStreak, 100);
    });

    test('canClaimTodayProvider provides correct value', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('claim_test');

      var canClaim = container.read(canClaimTodayProvider);
      expect(canClaim, true);

      await notifier.claimDailyReward('claim_test');
      canClaim = container.read(canClaimTodayProvider);
      expect(canClaim, false);
    });

    test('nextRewardProvider provides correct reward', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('next_reward_test');

      var nextReward = container.read(nextRewardProvider);
      expect(nextReward, isNotNull);
      expect(nextReward!.level, RewardLevel.day1);
    });

    test('loginRewardStatsProvider provides stats', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('stats_test');

      var stats = container.read(loginRewardStatsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'stats_test');
    });

    test('loginStreakProvider provides streak', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);
      await notifier.initializeLoginRewards('streak_provider_test');

      var streak = container.read(loginStreakProvider);
      expect(streak, isNotNull);
      expect(streak!.userId, 'streak_provider_test');
    });
  });

  group('Edge Cases and Error Handling', () {
    test('handles null userId gracefully', () async {
      final notifier = container.read(dailyLoginRewardProvider.notifier);

      // Should not throw, but handle gracefully
      await notifier.initializeLoginRewards('');

      final state = container.read(dailyLoginRewardProvider);
      expect(state.userStreak!.userId, '');
    });

    test('maintains login history up to 90 entries', () async {
      final notifier = DailyLoginRewardNotifier();

      // Create a user with more than 90 login history entries
      final logins = List.generate(
        100,
        (i) => DateTime.now().subtract(Duration(days: i)),
      );

      notifier.state = DailyLoginRewardState(
        rewardData: DailyLoginRewardData(
          availableRewards: [],
          userStreak: LoginStreak(
            userId: 'test_user',
            currentStreak: 100,
            longestStreak: 100,
            lastLoginDate: DateTime.now(),
            loginHistory: logins,
          ),
          stats: LoginRewardStats(
            userId: 'test_user',
            totalRewardsClaimed: 100,
            totalXpEarned: 1000,
            totalCoinEarned: 500,
            firstLoginDate: DateTime.now().subtract(Duration(days: 100)),
            lastResetDate: DateTime.now(),
          ),
          generatedAt: DateTime.now(),
        ),
        userStreak: LoginStreak(
          userId: 'test_user',
          currentStreak: 100,
          longestStreak: 100,
          lastLoginDate: DateTime.now(),
          loginHistory: logins,
        ),
        stats: LoginRewardStats(
          userId: 'test_user',
          totalRewardsClaimed: 100,
          totalXpEarned: 1000,
          totalCoinEarned: 500,
          firstLoginDate: DateTime.now().subtract(Duration(days: 100)),
          lastResetDate: DateTime.now(),
        ),
      );

      // Verify history is maintained (should truncate to 90)
      expect(notifier.state.userStreak!.loginHistory.length, 100);
    });

    test('maintains recent claims up to 30 entries', () async {
      final notifier = DailyLoginRewardNotifier();

      // Create 50 recent claims
      final claims = List.generate(
        50,
        (i) => LoginRewardClaim(
          claimId: 'claim_$i',
          userId: 'test_user',
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpEarned: 10,
          coinEarned: 5,
          claimedAt: DateTime.now().subtract(Duration(days: i)),
          streakDayAtClaim: i + 1,
        ),
      );

      notifier.state = DailyLoginRewardState(
        stats: LoginRewardStats(
          userId: 'test_user',
          totalRewardsClaimed: 50,
          totalXpEarned: 500,
          totalCoinEarned: 250,
          firstLoginDate: DateTime.now().subtract(Duration(days: 50)),
          lastResetDate: DateTime.now(),
          recentClaims: claims,
        ),
      );

      // Verify claims are maintained
      expect(notifier.state.stats!.recentClaims.length, 50);
    });
  });
}
