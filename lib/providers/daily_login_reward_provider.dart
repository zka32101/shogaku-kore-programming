import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_login_reward.dart';

class DailyLoginRewardState {
  final DailyLoginRewardData? rewardData;
  final LoginStreak? userStreak;
  final LoginRewardStats? stats;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  DailyLoginRewardState({
    this.rewardData,
    this.userStreak,
    this.stats,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  DailyLoginRewardState copyWith({
    DailyLoginRewardData? rewardData,
    LoginStreak? userStreak,
    LoginRewardStats? stats,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      DailyLoginRewardState(
        rewardData: rewardData ?? this.rewardData,
        userStreak: userStreak ?? this.userStreak,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

class DailyLoginRewardNotifier extends StateNotifier<DailyLoginRewardState> {
  DailyLoginRewardNotifier() : super(DailyLoginRewardState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// デフォルトのログインリワードを生成
  List<DailyLoginReward> _generateDefaultRewards() => [
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
          badgeId: 'streak_3days',
          description: '3日連続ボーナス',
          isStreakBonus: true,
        ),
        DailyLoginReward(
          rewardId: 'reward_day7',
          level: RewardLevel.day7,
          xpAmount: 70,
          coinAmount: 35,
          badgeId: 'streak_7days',
          description: '7日連続ボーナス',
          isStreakBonus: true,
        ),
        DailyLoginReward(
          rewardId: 'reward_day14',
          level: RewardLevel.day14,
          xpAmount: 140,
          coinAmount: 70,
          badgeId: 'streak_14days',
          description: '14日連続ボーナス',
          isStreakBonus: true,
        ),
        DailyLoginReward(
          rewardId: 'reward_day30',
          level: RewardLevel.day30,
          xpAmount: 300,
          coinAmount: 150,
          badgeId: 'streak_30days',
          description: '30日連続ボーナス',
          isStreakBonus: true,
        ),
      ];

  Future<void> initializeLoginRewards(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // ローカルストレージからデータを読み込み
      final prefs = await SharedPreferences.getInstance();
      final streakJson = prefs.getString('login_streak_$userId');
      final statsJson = prefs.getString('login_stats_$userId');

      late LoginStreak streak;
      late LoginRewardStats stats;

      if (streakJson != null) {
        streak = LoginStreak.fromJson(
            Map<String, dynamic>.from(streakJson as Map));
      } else {
        // 初回ログイン
        streak = LoginStreak(
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
          lastLoginDate: DateTime.now().subtract(Duration(days: 2)), // 初回ログイン判定
        );
      }

      if (statsJson != null) {
        stats = LoginRewardStats.fromJson(
            Map<String, dynamic>.from(statsJson as Map));
      } else {
        stats = LoginRewardStats(
          userId: userId,
          totalRewardsClaimed: 0,
          totalXpEarned: 0,
          totalCoinEarned: 0,
          firstLoginDate: DateTime.now(),
          lastResetDate: DateTime.now(),
        );
      }

      final rewardData = DailyLoginRewardData(
        availableRewards: _generateDefaultRewards(),
        userStreak: streak,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        rewardData: rewardData,
        userStreak: streak,
        stats: stats,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistRewardData(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 今日のログインリワードを獲得
  Future<LoginRewardClaim?> claimDailyReward(String userId) async {
    try {
      final streak = state.userStreak;
      final stats = state.stats;

      if (streak == null || stats == null) {
        throw Exception('ユーザーデータが初期化されていません');
      }

      // 既に本日ログインしているか確認
      if (streak.isLoggedInToday) {
        throw Exception('本日のリワードは既に獲得済みです');
      }

      // ストリークを計算
      int newStreak = streak.currentStreak;
      if (!streak.isStreakActive) {
        // ストリークが途切れている
        newStreak = 1;
      } else {
        // ストリーク継続
        newStreak = streak.currentStreak + 1;
      }

      // リワードを取得
      late DailyLoginReward reward;
      if (newStreak == 1) {
        reward = state.rewardData!.availableRewards
            .firstWhere((r) => r.level == RewardLevel.day1);
      } else if (newStreak == 3) {
        reward = state.rewardData!.availableRewards
            .firstWhere((r) => r.level == RewardLevel.day3);
      } else if (newStreak == 7) {
        reward = state.rewardData!.availableRewards
            .firstWhere((r) => r.level == RewardLevel.day7);
      } else if (newStreak == 14) {
        reward = state.rewardData!.availableRewards
            .firstWhere((r) => r.level == RewardLevel.day14);
      } else if (newStreak == 30) {
        reward = state.rewardData!.availableRewards
            .firstWhere((r) => r.level == RewardLevel.day30);
      } else {
        // その他の日数は基本報酬
        reward = state.rewardData!.availableRewards
            .firstWhere((r) => r.level == RewardLevel.day1);
      }

      // クレーム記録を作成
      final claim = LoginRewardClaim(
        claimId: _generateId('claim'),
        userId: userId,
        rewardId: reward.rewardId,
        level: reward.level,
        xpEarned: reward.xpAmount,
        coinEarned: reward.coinAmount,
        claimedAt: DateTime.now(),
        streakDayAtClaim: newStreak,
      );

      // ストリークを更新
      final updatedStreak = LoginStreak(
        userId: streak.userId,
        currentStreak: newStreak,
        longestStreak:
            max(streak.longestStreak, newStreak),
        lastLoginDate: DateTime.now(),
        streakStartDate:
            streak.streakStartDate ?? DateTime.now(),
        loginHistory: [...streak.loginHistory, DateTime.now()]
            .take(90)
            .toList(),
      );

      // 統計を更新
      final updatedStats = LoginRewardStats(
        userId: stats.userId,
        totalRewardsClaimed:
            stats.totalRewardsClaimed + 1,
        totalXpEarned: stats.totalXpEarned +
            reward.xpAmount,
        totalCoinEarned: stats.totalCoinEarned +
            reward.coinAmount,
        firstLoginDate: stats.firstLoginDate,
        lastResetDate: stats.lastResetDate,
        recentClaims: [claim, ...stats.recentClaims]
            .take(30)
            .toList(),
      );

      // 状態を更新
      final updatedRewardData = DailyLoginRewardData(
        availableRewards:
            state.rewardData!.availableRewards,
        userStreak: updatedStreak,
        stats: updatedStats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        rewardData: updatedRewardData,
        userStreak: updatedStreak,
        stats: updatedStats,
      );

      await _persistRewardData(userId);
      return claim;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// ストリークをリセット
  Future<void> resetStreak(String userId) async {
    try {
      final streak = state.userStreak;
      if (streak == null) return;

      final resetStreak = LoginStreak(
        userId: streak.userId,
        currentStreak: 0,
        longestStreak: streak.longestStreak,
        lastLoginDate:
            DateTime.now().subtract(Duration(days: 2)),
        streakStartDate: null,
        loginHistory: streak.loginHistory,
      );

      final stats = state.stats;
      final updatedStats = stats != null
          ? LoginRewardStats(
              userId: stats.userId,
              totalRewardsClaimed:
                  stats.totalRewardsClaimed,
              totalXpEarned: stats.totalXpEarned,
              totalCoinEarned:
                  stats.totalCoinEarned,
              firstLoginDate: stats.firstLoginDate,
              lastResetDate: DateTime.now(),
              recentClaims: stats.recentClaims,
            )
          : null;

      state = state.copyWith(
        userStreak: resetStreak,
        stats: updatedStats,
      );

      await _persistRewardData(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _persistRewardData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.userStreak != null) {
        // 簡略化：実運用ではJSON文字列化
        await prefs.setString(
          'login_streak_$userId',
          state.userStreak!.toJson().toString(),
        );
      }
      if (state.stats != null) {
        await prefs.setString(
          'login_stats_$userId',
          state.stats!.toJson().toString(),
        );
      }
      await prefs.setString(
        'login_reward_last_updated_$userId',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Silently fail
    }
  }

  int getCurrentStreak() => state.userStreak?.currentStreak ?? 0;
  int getLongestStreak() => state.userStreak?.longestStreak ?? 0;
  int getTotalXpEarned() => state.stats?.totalXpEarned ?? 0;
  int getTotalCoinEarned() => state.stats?.totalCoinEarned ?? 0;
  bool canClaimToday() => state.rewardData?.canClaimToday() ?? false;
}

final dailyLoginRewardProvider = StateNotifierProvider.autoDispose<
    DailyLoginRewardNotifier,
    DailyLoginRewardState>((ref) => DailyLoginRewardNotifier());

final currentStreakProvider =
    Provider.autoDispose<int>((ref) {
  return ref.watch(dailyLoginRewardProvider).userStreak?.currentStreak ?? 0;
});

final longestStreakProvider =
    Provider.autoDispose<int>((ref) {
  return ref.watch(dailyLoginRewardProvider).userStreak?.longestStreak ?? 0;
});

final canClaimTodayProvider =
    Provider.autoDispose<bool>((ref) {
  return ref.watch(dailyLoginRewardProvider).rewardData?.canClaimToday() ?? false;
});

final nextRewardProvider =
    Provider.autoDispose<DailyLoginReward?>((ref) {
  return ref.watch(dailyLoginRewardProvider).rewardData?.getNextReward();
});

final loginRewardStatsProvider =
    Provider.autoDispose<LoginRewardStats?>((ref) {
  return ref.watch(dailyLoginRewardProvider).stats;
});

final loginStreakProvider =
    Provider.autoDispose<LoginStreak?>((ref) {
  return ref.watch(dailyLoginRewardProvider).userStreak;
});
