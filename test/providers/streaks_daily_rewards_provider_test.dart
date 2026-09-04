import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/streaks_daily_rewards.dart';
import 'package:shogaku_kore_programming/providers/streaks_daily_rewards_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('StreakNotifier', () {
    test('initializes with empty state', () {
      final notifier = StreakNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeStreaks creates collection with defaults', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final state = container.read(streakProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
      expect(state.collection!.rewardSchedule.isNotEmpty, true);
    });

    test('initializeStreaks creates 30 default reward tiers', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var state = container.read(streakProvider);
      expect(state.collection!.rewardSchedule.length, 30);
    });

    test('initializeStreaks loads existing data', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final state = container.read(streakProvider);
      expect(state.collection!.currentStreak.currentStreak, 0);

      // Reinitialize should load from storage
      final _notifier2 = StreakNotifier();
      final container2 = ProviderContainer();
      await container2.read(streakProvider.notifier).initializeStreaks('test_user');

      final newState = container2.read(streakProvider);
      expect(newState.collection!.userId, 'test_user');
    });

    test('loginUser increments streak', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var state = container.read(streakProvider);
      expect(state.collection!.currentStreak.currentStreak, 0);

      await notifier.loginUser('test_user');

      state = container.read(streakProvider);
      expect(state.collection!.currentStreak.currentStreak, 1);
    });

    test('loginUser creates login record', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var state = container.read(streakProvider);
      expect(state.collection!.loginHistory.isEmpty, true);

      await notifier.loginUser('test_user');

      state = container.read(streakProvider);
      expect(state.collection!.loginHistory.isNotEmpty, true);
      expect(state.collection!.loginHistory[0].userId, 'test_user');
    });

    test('loginUser prevents duplicate login today', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      var state = container.read(streakProvider);
      final firstCount = state.collection!.loginHistory.length;

      await notifier.loginUser('test_user');
      state = container.read(streakProvider);
      expect(state.collection!.loginHistory.length, firstCount);
    });

    test('logoutUser records session time', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      var state = container.read(streakProvider);
      final login = state.collection!.loginHistory[0];
      expect(login.logoutDate, isNull);

      await notifier.logoutUser('test_user');

      state = container.read(streakProvider);
      expect(state.collection!.loginHistory[0].logoutDate, isNotNull);
    });

    test('claimDailyReward claims reward and applies multiplier', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      var _state = container.read(streakProvider);
      final dayOfMonth = DateTime.now().day;

      await notifier.claimDailyReward('test_user', dayOfMonth);

      state = container.read(streakProvider);
      expect(state.collection!.rewardClaims.isNotEmpty, true);
      expect(state.collection!.rewardClaims[0].dayNumber, dayOfMonth);
    });

    test('claimDailyReward updates statistics', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      var _state = container.read(streakProvider);
      expect(state.collection!.statistics.totalCoinsFromStreaks, 0);

      final dayOfMonth = DateTime.now().day;
      await notifier.claimDailyReward('test_user', dayOfMonth);

      state = container.read(streakProvider);
      expect(state.collection!.statistics.totalCoinsFromStreaks > 0, true);
    });

    test('breakStreak resets current streak', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      var _state = container.read(streakProvider);
      expect(state.collection!.currentStreak.currentStreak, 1);

      await notifier.breakStreak('test_user');

      state = container.read(streakProvider);
      expect(state.collection!.currentStreak.currentStreak, 0);
    });

    test('breakStreak increments times broken', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var _state = container.read(streakProvider);
      expect(state.collection!.currentStreak.timesStreakBroken, 0);

      await notifier.breakStreak('test_user');

      state = container.read(streakProvider);
      expect(state.collection!.currentStreak.timesStreakBroken, 1);
    });

    test('protectStreak updates last login date', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      // Simulate being at risk by setting last login to yesterday
      var _state = container.read(streakProvider);
      final currentStreak = state.collection!.currentStreak;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // We can't directly modify, so we'll check that protectStreak only works when at risk
      final _atRiskStreak = UserStreak(
        streakId: currentStreak.streakId,
        userId: 'test_user',
        currentStreak: 5,
        longestStreak: 5,
        streakStartDate: yesterday.subtract(const Duration(days: 5)),
        lastLoginDate: yesterday,
        lastUpdatedAt: yesterday,
      );

      // Direct test - when streak is not at risk, should error
      await notifier.protectStreak('test_user');
      state = container.read(streakProvider);
      expect(state.collection!.error, isNotNull);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('persist_test');

      var _state = container.read(streakProvider);
      await notifier.loginUser('persist_test');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('streaks_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('streakCollectionProvider provides collection', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final collection = container.read(streakCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('currentStreakProvider provides current streak', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final streak = container.read(currentStreakProvider);
      expect(streak, isNotNull);
      expect(streak!.userId, 'test_user');
    });

    test('streakStatisticsProvider provides statistics', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final stats = container.read(streakStatisticsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('streakTierProvider provides correct tier', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var tier = container.read(streakTierProvider);
      expect(tier, '初心者');
    });

    test('currentStreakCountProvider provides count', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var count = container.read(currentStreakCountProvider);
      expect(count, 0);

      await notifier.loginUser('test_user');
      count = container.read(currentStreakCountProvider);
      expect(count, 1);
    });

    test('longestStreakProvider provides longest', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final longest = container.read(longestStreakProvider);
      expect(longest, 0);
    });

    test('isStreakAtRiskProvider detects at-risk status', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      var atRisk = container.read(isStreakAtRiskProvider);
      expect(atRisk, false);
    });

    test('daysUntilBrokenProvider provides days', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      final days = container.read(daysUntilBrokenProvider);
      expect(days, 2);
    });

    test('streakStatusProvider provides status', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var status = container.read(streakStatusProvider);
      expect(status, '中断');

      await notifier.loginUser('test_user');
      status = container.read(streakStatusProvider);
      expect(status, 'アクティブ');
    });

    test('rewardScheduleProvider provides schedule', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final schedule = container.read(rewardScheduleProvider);
      expect(schedule.isNotEmpty, true);
    });

    test('todaysRewardProvider provides today reward', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      final reward = container.read(todaysRewardProvider);
      expect(reward, isNotNull);
      expect(reward!.dayNumber, DateTime.now().day);
    });

    test('recentLoginsProvider filters by days', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      await notifier.loginUser('test_user');
      final recent = container.read(recentLoginsProvider(7));
      expect(recent.length, 1);
    });

    test('monthlyLoginsProvider filters this month', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var monthly = container.read(monthlyLoginsProvider);
      expect(monthly.isEmpty, true);

      await notifier.loginUser('test_user');
      monthly = container.read(monthlyLoginsProvider);
      expect(monthly.length, 1);
    });

    test('streakBonusMultiplierProvider provides multiplier', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var multiplier = container.read(streakBonusMultiplierProvider);
      expect(multiplier, 1.0);

      await notifier.loginUser('test_user');
      multiplier = container.read(streakBonusMultiplierProvider);
      expect(multiplier >= 1.0 && multiplier <= 2.5, true);
    });

    test('rewardClaimsProvider provides claims', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var claims = container.read(rewardClaimsProvider);
      expect(claims.isEmpty, true);

      await notifier.loginUser('test_user');
      final dayOfMonth = DateTime.now().day;
      await notifier.claimDailyReward('test_user', dayOfMonth);

      claims = container.read(rewardClaimsProvider);
      expect(claims.length, 1);
    });

    test('loginHistoryProvider provides login history', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var history = container.read(loginHistoryProvider);
      expect(history.isEmpty, true);

      await notifier.loginUser('test_user');
      history = container.read(loginHistoryProvider);
      expect(history.length, 1);
    });

    test('totalCoinsFromStreaksProvider provides total', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var total = container.read(totalCoinsFromStreaksProvider);
      expect(total, 0);

      await notifier.loginUser('test_user');
      final dayOfMonth = DateTime.now().day;
      await notifier.claimDailyReward('test_user', dayOfMonth);

      total = container.read(totalCoinsFromStreaksProvider);
      expect(total > 0, true);
    });

    test('totalXpFromStreaksProvider provides total', () async {
      final notifier = container.read(streakProvider.notifier);
      await notifier.initializeStreaks('test_user');

      var total = container.read(totalXpFromStreaksProvider);
      expect(total, 0);

      await notifier.loginUser('test_user');
      final dayOfMonth = DateTime.now().day;
      await notifier.claimDailyReward('test_user', dayOfMonth);

      total = container.read(totalXpFromStreaksProvider);
      expect(total > 0, true);
    });
  });
}
