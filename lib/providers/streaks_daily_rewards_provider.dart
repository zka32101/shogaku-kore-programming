import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/streaks_daily_rewards.dart';

/// Streak state
class StreakState {
  final StreakAndRewardCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  StreakState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  StreakState copyWith({
    StreakAndRewardCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      StreakState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

/// Streak notifier
class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier() : super(StreakState());

  /// Initialize streaks
  Future<void> initializeStreaks(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'streaks_$userId';

      final stored = prefs.getString(key);
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        state = state.copyWith(
          collection: StreakAndRewardCollection.fromJson(json),
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
        return;
      }

      final now = DateTime.now();
      final defaultRewards = _createDefaultRewardTiers();

      final collection = StreakAndRewardCollection(
        userId: userId,
        currentStreak: UserStreak(
          streakId: 'streak_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
          streakStartDate: now,
          lastLoginDate: now,
          timesStreakBroken: 0,
          isActive: false,
          totalDaysParticipated: 0,
          lastUpdatedAt: now,
        ),
        loginHistory: [],
        rewardClaims: [],
        rewardSchedule: defaultRewards,
        statistics: StreakStatistics(
          userId: userId,
          totalLoginsEver: 0,
          consecutiveDaysActive: 0,
          longestStreak: 0,
          streaksAchieved: 0,
          totalCoinsFromStreaks: 0,
          totalXpFromStreaks: 0,
          firstLoginAt: now,
          lastLoginAt: now,
          lastUpdatedAt: now,
        ),
        generatedAt: now,
      );

      await prefs.setString(key, jsonEncode(collection.toJson()));
      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize streaks: $e',
      );
    }
  }

  /// User login
  Future<void> loginUser(String userId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      // Check if already logged in today
      final loginId = 'login_${now.year}_${now.month}_${now.day}_$userId';
      final todayLogin = collection.loginHistory.firstWhere(
        (l) => l.isToday && l.userId == userId,
        orElse: () => null as dynamic,
      ) as DailyLogin?;

      if (todayLogin != null) {
        state = state.copyWith(error: 'Already logged in today');
        return;
      }

      final newLogin = DailyLogin(
        loginId: loginId,
        userId: userId,
        loginDate: now,
        minutesActive: 0,
        claimedReward: false,
        coinsEarned: 0,
        xpEarned: 0,
      );

      // Update streak
      final currentStreak = collection.currentStreak;
      int newStreakCount = currentStreak.currentStreak;
      bool isNewStreak = false;

      if (currentStreak.currentStreak == 0) {
        newStreakCount = 1;
        isNewStreak = true;
      } else if (!currentStreak.isAtRisk) {
        // Continues existing streak
        newStreakCount = currentStreak.currentStreak + 1;
      } else {
        // Streak was broken, start new one
        newStreakCount = 1;
        isNewStreak = true;
      }

      final updatedStreak = UserStreak(
        streakId: currentStreak.streakId,
        userId: userId,
        currentStreak: newStreakCount,
        longestStreak: newStreakCount > currentStreak.longestStreak
            ? newStreakCount
            : currentStreak.longestStreak,
        streakStartDate: isNewStreak ? now : currentStreak.streakStartDate,
        lastLoginDate: now,
        streakBrokenDate: currentStreak.streakBrokenDate,
        timesStreakBroken: currentStreak.timesStreakBroken,
        isActive: true,
        totalDaysParticipated: currentStreak.totalDaysParticipated + 1,
        lastUpdatedAt: now,
      );

      final updatedHistory = [...collection.loginHistory, newLogin].take(400).toList();

      final stats = collection.statistics;
      int streaksAchieved = stats.streaksAchieved;
      if (newStreakCount >= 7 && currentStreak.currentStreak < 7) {
        streaksAchieved = stats.streaksAchieved + 1;
      }

      final updatedStats = StreakStatistics(
        userId: userId,
        totalLoginsEver: stats.totalLoginsEver + 1,
        consecutiveDaysActive: newStreakCount,
        longestStreak: updatedStreak.longestStreak,
        streaksAchieved: streaksAchieved,
        totalCoinsFromStreaks: stats.totalCoinsFromStreaks,
        totalXpFromStreaks: stats.totalXpFromStreaks,
        firstLoginAt: stats.firstLoginAt,
        lastLoginAt: now,
        lastUpdatedAt: now,
      );

      final updatedCollection = StreakAndRewardCollection(
        userId: userId,
        currentStreak: updatedStreak,
        loginHistory: updatedHistory,
        rewardClaims: collection.rewardClaims,
        rewardSchedule: collection.rewardSchedule,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to login: $e');
    }
  }

  /// User logout
  Future<void> logoutUser(String userId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedHistory = collection.loginHistory.map((login) {
        if (login.isToday && login.userId == userId && login.logoutDate == null) {
          return DailyLogin(
            loginId: login.loginId,
            userId: login.userId,
            loginDate: login.loginDate,
            logoutDate: now,
            minutesActive: now.difference(login.loginDate).inMinutes,
            claimedReward: login.claimedReward,
            coinsEarned: login.coinsEarned,
            xpEarned: login.xpEarned,
            deviceInfo: login.deviceInfo,
            metadata: login.metadata,
          );
        }
        return login;
      }).toList();

      final updatedCollection = StreakAndRewardCollection(
        userId: userId,
        currentStreak: collection.currentStreak,
        loginHistory: updatedHistory,
        rewardClaims: collection.rewardClaims,
        rewardSchedule: collection.rewardSchedule,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to logout: $e');
    }
  }

  /// Claim daily reward
  Future<void> claimDailyReward(String userId, int dayNumber) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      // Get reward tier for this day
      final rewardTier = collection.rewardSchedule.firstWhere(
        (r) => r.dayNumber == dayNumber,
        orElse: () => throw Exception('Invalid day number'),
      );

      // Check if already claimed today
      final todayLogin = collection.loginHistory.firstWhere(
        (l) => l.isToday && l.userId == userId,
        orElse: () => null as dynamic,
      ) as DailyLogin?;

      if (todayLogin == null || todayLogin.claimedReward) {
        throw Exception('Cannot claim reward');
      }

      // Calculate multiplier based on streak
      double multiplier = collection.getStreakBonusMultiplier();
      final streakMultiplier = multiplier > 1.0 ? multiplier : null;

      // Calculate rewards with multiplier
      final coinReward = (rewardTier.coinReward * multiplier).toInt();
      final xpReward = (rewardTier.xpReward * multiplier).toInt();
      final premiumCoinReward = rewardTier.premiumCoinReward;

      final claimId = 'claim_${now.millisecondsSinceEpoch}_${(now.microsecond % 10000)}';
      final claim = DailyRewardClaim(
        claimId: claimId,
        userId: userId,
        dayNumber: dayNumber,
        claimedAt: now,
        coinsReward: coinReward,
        xpReward: xpReward,
        premiumCoinReward: premiumCoinReward,
        specialItemId: rewardTier.specialItemId,
        streakMultiplier: streakMultiplier,
      );

      // Update login to mark reward as claimed
      final updatedHistory = collection.loginHistory.map((login) {
        if (login.loginId == todayLogin.loginId) {
          return DailyLogin(
            loginId: login.loginId,
            userId: login.userId,
            loginDate: login.loginDate,
            logoutDate: login.logoutDate,
            minutesActive: login.minutesActive,
            claimedReward: true,
            coinsEarned: coinReward,
            xpEarned: xpReward,
            deviceInfo: login.deviceInfo,
            metadata: login.metadata,
          );
        }
        return login;
      }).toList();

      final updatedClaims = [...collection.rewardClaims, claim].take(365).toList();

      final stats = collection.statistics;
      final updatedStats = StreakStatistics(
        userId: userId,
        totalLoginsEver: stats.totalLoginsEver,
        consecutiveDaysActive: stats.consecutiveDaysActive,
        longestStreak: stats.longestStreak,
        streaksAchieved: stats.streaksAchieved,
        totalCoinsFromStreaks: stats.totalCoinsFromStreaks + coinReward,
        totalXpFromStreaks: stats.totalXpFromStreaks + xpReward,
        firstLoginAt: stats.firstLoginAt,
        lastLoginAt: stats.lastLoginAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = StreakAndRewardCollection(
        userId: userId,
        currentStreak: collection.currentStreak,
        loginHistory: updatedHistory,
        rewardClaims: updatedClaims,
        rewardSchedule: collection.rewardSchedule,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to claim reward: $e');
    }
  }

  /// Break streak (miss a day)
  Future<void> breakStreak(String userId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final currentStreak = collection.currentStreak;

      final updatedStreak = UserStreak(
        streakId: currentStreak.streakId,
        userId: userId,
        currentStreak: 0,
        longestStreak: currentStreak.longestStreak,
        streakStartDate: currentStreak.streakStartDate,
        lastLoginDate: currentStreak.lastLoginDate,
        streakBrokenDate: now,
        timesStreakBroken: currentStreak.timesStreakBroken + 1,
        isActive: false,
        totalDaysParticipated: currentStreak.totalDaysParticipated,
        lastUpdatedAt: now,
      );

      final stats = collection.statistics;
      final updatedStats = StreakStatistics(
        userId: userId,
        totalLoginsEver: stats.totalLoginsEver,
        consecutiveDaysActive: 0,
        longestStreak: stats.longestStreak,
        streaksAchieved: stats.streaksAchieved,
        totalCoinsFromStreaks: stats.totalCoinsFromStreaks,
        totalXpFromStreaks: stats.totalXpFromStreaks,
        firstLoginAt: stats.firstLoginAt,
        lastLoginAt: stats.lastLoginAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = StreakAndRewardCollection(
        userId: userId,
        currentStreak: updatedStreak,
        loginHistory: collection.loginHistory,
        rewardClaims: collection.rewardClaims,
        rewardSchedule: collection.rewardSchedule,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to break streak: $e');
    }
  }

  /// Protect streak (prevent break with power-up)
  Future<void> protectStreak(String userId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      if (!collection.currentStreak.isAtRisk) {
        throw Exception('Streak is not at risk');
      }

      // Reset last login to today (simulating protection)
      final currentStreak = collection.currentStreak;
      final updatedStreak = UserStreak(
        streakId: currentStreak.streakId,
        userId: userId,
        currentStreak: currentStreak.currentStreak,
        longestStreak: currentStreak.longestStreak,
        streakStartDate: currentStreak.streakStartDate,
        lastLoginDate: now,
        streakBrokenDate: currentStreak.streakBrokenDate,
        timesStreakBroken: currentStreak.timesStreakBroken,
        isActive: true,
        totalDaysParticipated: currentStreak.totalDaysParticipated,
        lastUpdatedAt: now,
      );

      final updatedCollection = StreakAndRewardCollection(
        userId: userId,
        currentStreak: updatedStreak,
        loginHistory: collection.loginHistory,
        rewardClaims: collection.rewardClaims,
        rewardSchedule: collection.rewardSchedule,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to protect streak: $e');
    }
  }

  /// Persist to SharedPreferences
  Future<void> _persist(String userId, StreakAndRewardCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'streaks_$userId',
      jsonEncode(collection.toJson()),
    );
  }

  /// Create default reward tiers
  List<DailyRewardTier> _createDefaultRewardTiers() {
    final tiers = <DailyRewardTier>[];

    // Regular days (1-30)
    for (int i = 1; i <= 30; i++) {
      final baseCoins = 100 + (i * 5);
      final baseXp = 50 + (i * 2);
      final isMilestone = [7, 14, 21, 30].contains(i);

      tiers.add(DailyRewardTier(
        dayNumber: i,
        rewardName: '${i}日目報酬',
        coinReward: baseCoins,
        xpReward: baseXp,
        premiumCoinReward: isMilestone ? 1 : null,
        specialItemId: isMilestone ? 'special_day_$i' : null,
        isMilestone: isMilestone,
      ));
    }

    return tiers;
  }
}

// Riverpod providers
final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier();
});

final streakCollectionProvider = Provider<StreakAndRewardCollection?>((ref) {
  final state = ref.watch(streakProvider);
  return state.collection;
});

final currentStreakProvider = Provider<UserStreak?>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.currentStreak;
});

final streakStatisticsProvider = Provider<StreakStatistics?>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.statistics;
});

final streakTierProvider = Provider<String>((ref) {
  final stats = ref.watch(streakStatisticsProvider);
  return stats?.getStreakTier() ?? '初心者';
});

final currentStreakCountProvider = Provider<int>((ref) {
  final streak = ref.watch(currentStreakProvider);
  return streak?.currentStreak ?? 0;
});

final longestStreakProvider = Provider<int>((ref) {
  final streak = ref.watch(currentStreakProvider);
  return streak?.longestStreak ?? 0;
});

final isStreakAtRiskProvider = Provider<bool>((ref) {
  final streak = ref.watch(currentStreakProvider);
  return streak?.isAtRisk ?? false;
});

final daysUntilBrokenProvider = Provider<int>((ref) {
  final streak = ref.watch(currentStreakProvider);
  return streak?.daysUntilBroken ?? 2;
});

final streakStatusProvider = Provider<String>((ref) {
  final streak = ref.watch(currentStreakProvider);
  return streak?.getStreakStatus() ?? '中断';
});

final rewardScheduleProvider = Provider<List<DailyRewardTier>>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.rewardSchedule ?? [];
});

final todaysRewardProvider = Provider<DailyRewardTier?>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.getTodaysReward();
});

final recentLoginsProvider = Provider.family<List<DailyLogin>, int>((ref, days) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.getRecentLogins(days: days) ?? [];
});

final monthlyLoginsProvider = Provider<List<DailyLogin>>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.getLoginsThisMonth() ?? [];
});

final streakBonusMultiplierProvider = Provider<double>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.getStreakBonusMultiplier() ?? 1.0;
});

final rewardClaimsProvider = Provider<List<DailyRewardClaim>>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.rewardClaims ?? [];
});

final loginHistoryProvider = Provider<List<DailyLogin>>((ref) {
  final collection = ref.watch(streakCollectionProvider);
  return collection?.loginHistory ?? [];
});

final totalCoinsFromStreaksProvider = Provider<int>((ref) {
  final stats = ref.watch(streakStatisticsProvider);
  return stats?.totalCoinsFromStreaks ?? 0;
});

final totalXpFromStreaksProvider = Provider<int>((ref) {
  final stats = ref.watch(streakStatisticsProvider);
  return stats?.totalXpFromStreaks ?? 0;
});
