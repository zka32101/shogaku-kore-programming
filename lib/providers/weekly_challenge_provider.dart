import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_challenge.dart';

class WeeklyChallengeState {
  final WeeklyChallengeCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;
  final List<String> recentlyCompleted;  // Challenge IDs completed in this session

  WeeklyChallengeState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
    this.recentlyCompleted = const [],
  });

  WeeklyChallengeState copyWith({
    WeeklyChallengeCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
    List<String>? recentlyCompleted,
  }) =>
      WeeklyChallengeState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        recentlyCompleted: recentlyCompleted ?? this.recentlyCompleted,
      );
}

class WeeklyChallengeNotifier extends StateNotifier<WeeklyChallengeState> {
  WeeklyChallengeNotifier() : super(WeeklyChallengeState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// 今週のデフォルトチャレンジを生成
  List<WeeklyChallenge> _generateWeeklyChallenges() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return [
      // 学習系
      WeeklyChallenge(
        challengeId: 'wch_learn_100',
        title: '100分学習チャレンジ',
        description: '今週100分以上学習する',
        category: ChallengeCategory.learning,
        difficulty: ChallengeDifficulty.normal,
        iconId: 'icon_learn_100',
        targetValue: 100,
        metricKey: 'learning_minutes',
        baseBonusXp: 150,
        baseBonusCoins: 75,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        isStreakBooster: true,
      ),
      // クイズ系
      WeeklyChallenge(
        challengeId: 'wch_quiz_10',
        title: 'クイズマスター',
        description: 'クイズに10回チャレンジ',
        category: ChallengeCategory.quiz,
        difficulty: ChallengeDifficulty.easy,
        iconId: 'icon_quiz_10',
        targetValue: 10,
        metricKey: 'quiz_attempts',
        baseBonusXp: 100,
        baseBonusCoins: 50,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
      ),
      // 読解系
      WeeklyChallenge(
        challengeId: 'wch_read_5',
        title: 'リーディング チャレンジ',
        description: '5つの読解問題を完了',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        iconId: 'icon_read_5',
        targetValue: 5,
        metricKey: 'reading_completed',
        baseBonusXp: 120,
        baseBonusCoins: 60,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        isStreakBooster: true,
      ),
      // 筆記系
      WeeklyChallenge(
        challengeId: 'wch_write_3',
        title: 'ライティング マスター',
        description: '3つのライティング課題を完了',
        category: ChallengeCategory.writing,
        difficulty: ChallengeDifficulty.hard,
        iconId: 'icon_write_3',
        targetValue: 3,
        metricKey: 'writing_completed',
        baseBonusXp: 200,
        baseBonusCoins: 100,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
      ),
      // リスニング系
      WeeklyChallenge(
        challengeId: 'wch_listen_30',
        title: 'リスニング チャンピオン',
        description: 'リスニング30分以上',
        category: ChallengeCategory.listening,
        difficulty: ChallengeDifficulty.normal,
        iconId: 'icon_listen_30',
        targetValue: 30,
        metricKey: 'listening_minutes',
        baseBonusXp: 130,
        baseBonusCoins: 65,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
      ),
      // ボーナスチャレンジ（秘密）
      WeeklyChallenge(
        challengeId: 'wch_bonus_perfect',
        title: 'パーフェクトウィーク',
        description: 'すべてのチャレンジを完了',
        category: ChallengeCategory.creative,
        difficulty: ChallengeDifficulty.expert,
        iconId: 'icon_perfect_week',
        targetValue: 5,
        metricKey: 'all_challenges_completed',
        baseBonusXp: 500,
        baseBonusCoins: 250,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        isBonusChallenge: true,
      ),
    ];
  }

  /// チャレンジシステムを初期化
  Future<void> initializeChallenges(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('challenge_progress_$userId');
      final statsJson = prefs.getString('challenge_stats_$userId');

      late WeeklyChallengeStats stats;
      late Map<String, ChallengeProgress> userProgress;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      if (statsJson != null) {
        stats = WeeklyChallengeStats.fromJson(
            Map<String, dynamic>.from(statsJson as Map));
      } else {
        stats = WeeklyChallengeStats(
          userId: userId,
          totalChallengesThisWeek: 6,
          completedChallenges: 0,
          totalXpEarned: 0,
          totalCoinsEarned: 0,
          rewardHistory: [],
          weeklyStreak: 0,
          weekStartDate: weekStart,
          weekEndDate: weekEnd,
          lastUpdatedAt: DateTime.now(),
        );
      }

      // ユーザープログレスを初期化
      if (progressJson != null) {
        final progressData = Map<String, dynamic>.from(progressJson as Map);
        userProgress = (progressData as Map)
            .cast<String, Map<String, dynamic>>()
            .map((key, value) => MapEntry(
              key,
              ChallengeProgress.fromJson(value),
            ));
      } else {
        userProgress = {};
      }

      // すべてのチャレンジの進捗を初期化
      final challenges = _generateWeeklyChallenges();
      for (final challenge in challenges) {
        if (!userProgress.containsKey(challenge.challengeId)) {
          userProgress[challenge.challengeId] = ChallengeProgress(
            challengeId: challenge.challengeId,
            userId: userId,
            currentValue: 0,
            targetValue: challenge.targetValue,
            startedAt: DateTime.now(),
            isCompleted: false,
          );
        }
      }

      final collection = WeeklyChallengeCollection(
        challenges: challenges,
        stats: stats,
        userProgress: userProgress,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistChallenges(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// チャレンジ進捗を更新
  Future<bool> updateChallengeProgress(
    String userId,
    String metricKey,
    int value,
  ) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      bool anyCompleted = false;
      final newRecentlyCompleted = <String>[...state.recentlyCompleted];
      final updatedProgress = Map<String, ChallengeProgress>.from(
        collection.userProgress,
      );

      for (final challenge in collection.challenges) {
        // 既に完了しているかチェック
        final progress = updatedProgress[challenge.challengeId];
        if (progress?.isCompleted == true) continue;

        if (challenge.metricKey == metricKey) {
          // 新しい進捗値で更新
          final newProgress = ChallengeProgress(
            challengeId: challenge.challengeId,
            userId: userId,
            currentValue: value,
            targetValue: challenge.targetValue,
            attemptCount: (progress?.attemptCount ?? 0) + 1,
            startedAt: progress?.startedAt ?? DateTime.now(),
            completedAt: value >= challenge.targetValue ? DateTime.now() : null,
            isCompleted: value >= challenge.targetValue,
            tier: value >= challenge.targetValue
                ? _calculateRewardTier(value, challenge.targetValue)
                : null,
          );

          updatedProgress[challenge.challengeId] = newProgress;

          if (newProgress.isCompleted && progress?.isCompleted != true) {
            anyCompleted = true;
            newRecentlyCompleted.add(challenge.challengeId);

            // 統計を更新
            final updatedStats = WeeklyChallengeStats(
              userId: collection.stats.userId,
              totalChallengesThisWeek:
                  collection.stats.totalChallengesThisWeek,
              completedChallenges: collection.stats.completedChallenges + 1,
              totalXpEarned: collection.stats.totalXpEarned +
                  _calculateReward(
                    challenge,
                    newProgress.tier!,
                  )['xp'] as int,
              totalCoinsEarned: collection.stats.totalCoinsEarned +
                  _calculateReward(
                    challenge,
                    newProgress.tier!,
                  )['coins'] as int,
              rewardHistory: [
                ChallengeReward(
                  rewardId: _generateId('creward'),
                  userId: userId,
                  challengeId: challenge.challengeId,
                  xpEarned: _calculateReward(
                    challenge,
                    newProgress.tier!,
                  )['xp'] as int,
                  coinsEarned: _calculateReward(
                    challenge,
                    newProgress.tier!,
                  )['coins'] as int,
                  claimedAt: DateTime.now(),
                  tier: newProgress.tier!,
                  difficultyMultiplier: challenge.difficultyMultiplier,
                ),
                ...collection.stats.rewardHistory,
              ].take(50).toList(),
              weeklyStreak: collection.stats.weeklyStreak,
              weekStartDate: collection.stats.weekStartDate,
              weekEndDate: collection.stats.weekEndDate,
              lastUpdatedAt: DateTime.now(),
            );

            final updatedCollection = WeeklyChallengeCollection(
              challenges: collection.challenges,
              stats: updatedStats,
              userProgress: updatedProgress,
              generatedAt: DateTime.now(),
            );

            state = state.copyWith(
              collection: updatedCollection,
              recentlyCompleted: newRecentlyCompleted,
            );
          }
        }
      }

      if (anyCompleted) {
        await _persistChallenges(userId);
      }

      return anyCompleted;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// リワード層を計算
  ChallengeRewardTier _calculateRewardTier(int current, int target) {
    final percentage = (current / target * 100);
    if (percentage >= 100) return ChallengeRewardTier.platinum;
    if (percentage >= 90) return ChallengeRewardTier.gold;
    if (percentage >= 70) return ChallengeRewardTier.silver;
    return ChallengeRewardTier.bronze;
  }

  /// リワード額を計算
  Map<String, int> _calculateReward(
    WeeklyChallenge challenge,
    ChallengeRewardTier tier,
  ) {
    final multiplier = challenge.difficultyMultiplier;
    var xp = (challenge.baseBonusXp * multiplier).toInt();
    var coins = (challenge.baseBonusCoins * multiplier).toInt();

    // ティアボーナス
    switch (tier) {
      case ChallengeRewardTier.silver:
        xp = (xp * 1.2).toInt();
        coins = (coins * 1.2).toInt();
      case ChallengeRewardTier.gold:
        xp = (xp * 1.5).toInt();
        coins = (coins * 1.5).toInt();
      case ChallengeRewardTier.platinum:
        xp = (xp * 2.0).toInt();
        coins = (coins * 2.0).toInt();
      default:
        break;
    }

    return {'xp': xp, 'coins': coins};
  }

  /// 完了したチャレンジを取得
  List<WeeklyChallenge> getCompletedChallenges() {
    return state.collection?.getCompletedChallenges() ?? [];
  }

  /// アクティブなチャレンジを取得
  List<WeeklyChallenge> getActiveChallenges() {
    return state.collection?.getActiveChallenges() ?? [];
  }

  /// ボーナスチャレンジを取得
  List<WeeklyChallenge> getBonusChallenges() {
    return state.collection?.getBonusChallenges() ?? [];
  }

  /// カテゴリ別にチャレンジを取得
  List<WeeklyChallenge> getByCategory(ChallengeCategory category) {
    return state.collection?.getByCategory(category) ?? [];
  }

  /// 難易度別にチャレンジを取得
  List<WeeklyChallenge> getByDifficulty(ChallengeDifficulty difficulty) {
    return state.collection?.getByDifficulty(difficulty) ?? [];
  }

  /// 最近完了したチャレンジをクリア
  void clearRecentlyCompleted() {
    state = state.copyWith(recentlyCompleted: []);
  }

  Future<void> _persistChallenges(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection = state.collection;
      if (collection != null) {
        final progressMap = collection.userProgress
            .map((key, value) => MapEntry(key, value.toJson()));
        await prefs.setString(
          'challenge_progress_$userId',
          progressMap.toString(),
        );
        await prefs.setString(
          'challenge_stats_$userId',
          collection.stats.toJson().toString(),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  int getCompletedCount() =>
      state.collection?.stats.completedChallenges ?? 0;
  int getTotalChallenges() =>
      state.collection?.stats.totalChallengesThisWeek ?? 0;
  double getCompletionPercentage() =>
      state.collection?.stats.completionPercentage ?? 0;
  int getWeeklyXpEarned() =>
      state.collection?.stats.totalXpEarned ?? 0;
  int getWeeklyCoinsEarned() =>
      state.collection?.stats.totalCoinsEarned ?? 0;
  int getWeeklyStreak() => state.collection?.stats.weeklyStreak ?? 0;
}

final weeklyChallengeProvider = StateNotifierProvider.autoDispose<
    WeeklyChallengeNotifier,
    WeeklyChallengeState>((ref) => WeeklyChallengeNotifier());

final completedChallengesProvider =
    Provider.autoDispose<List<WeeklyChallenge>>((ref) {
  return ref.watch(weeklyChallengeProvider).collection?.getCompletedChallenges() ?? [];
});

final activeChallengesProvider =
    Provider.autoDispose<List<WeeklyChallenge>>((ref) {
  return ref.watch(weeklyChallengeProvider).collection?.getActiveChallenges() ?? [];
});

final weeklyChallengeStatsProvider =
    Provider.autoDispose<WeeklyChallengeStats?>((ref) {
  return ref.watch(weeklyChallengeProvider).collection?.stats;
});

final completionPercentageProvider =
    Provider.autoDispose<double>((ref) {
  return ref.watch(weeklyChallengeProvider).collection?.stats.completionPercentage ?? 0;
});

final weeklyXpEarnedProvider =
    Provider.autoDispose<int>((ref) {
  return ref.watch(weeklyChallengeProvider).collection?.stats.totalXpEarned ?? 0;
});

final weeklyCoinsEarnedProvider =
    Provider.autoDispose<int>((ref) {
  return ref.watch(weeklyChallengeProvider).collection?.stats.totalCoinsEarned ?? 0;
});

final weeklyStreakProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(weeklyChallengeProvider).collection?.stats.weeklyStreak ?? 0;
});
