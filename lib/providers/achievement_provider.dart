import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

class AchievementState {
  final AchievementCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;
  final List<String> recentlyUnlocked;  // Achievement IDs unlocked in this session

  AchievementState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
    this.recentlyUnlocked = const [],
  });

  AchievementState copyWith({
    AchievementCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
    List<String>? recentlyUnlocked,
  }) =>
      AchievementState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        recentlyUnlocked: recentlyUnlocked ?? this.recentlyUnlocked,
      );
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier() : super(AchievementState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// デフォルトの達成リストを生成
  List<Achievement> _generateDefaultAchievements() => [
        // ストリーク系
        Achievement(
          achievementId: 'ach_streak_3',
          name: '3日連続ログイン',
          description: '3日連続でログインした',
          type: AchievementType.streak,
          rarity: AchievementRarity.common,
          iconId: 'icon_streak_3',
          xpReward: 25,
          coinReward: 10,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_streak_3',
              description: 'ストリーク3日達成',
              targetValue: 3,
              metricKey: 'current_streak',
            ),
          ],
          isSelfLocking: true,
        ),
        Achievement(
          achievementId: 'ach_streak_7',
          name: 'ウィークストリーク',
          description: '7日連続ログイン達成',
          type: AchievementType.streak,
          rarity: AchievementRarity.uncommon,
          iconId: 'icon_streak_7',
          xpReward: 75,
          coinReward: 30,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_streak_7',
              description: 'ストリーク7日達成',
              targetValue: 7,
              metricKey: 'current_streak',
            ),
          ],
        ),
        Achievement(
          achievementId: 'ach_streak_30',
          name: 'マンスマスター',
          description: '30日連続ログイン達成',
          type: AchievementType.streak,
          rarity: AchievementRarity.rare,
          iconId: 'icon_streak_30',
          xpReward: 300,
          coinReward: 150,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_streak_30',
              description: 'ストリーク30日達成',
              targetValue: 30,
              metricKey: 'current_streak',
            ),
          ],
        ),
        // XP系
        Achievement(
          achievementId: 'ach_xp_100',
          name: '経験値ハンター',
          description: '100 XP獲得した',
          type: AchievementType.xp,
          rarity: AchievementRarity.common,
          iconId: 'icon_xp_100',
          xpReward: 50,
          coinReward: 20,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_xp_100',
              description: '100 XP獲得',
              targetValue: 100,
              metricKey: 'total_xp_earned',
            ),
          ],
        ),
        Achievement(
          achievementId: 'ach_xp_500',
          name: 'XPマイスター',
          description: '500 XP獲得した',
          type: AchievementType.xp,
          rarity: AchievementRarity.uncommon,
          iconId: 'icon_xp_500',
          xpReward: 150,
          coinReward: 60,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_xp_500',
              description: '500 XP獲得',
              targetValue: 500,
              metricKey: 'total_xp_earned',
            ),
          ],
        ),
        Achievement(
          achievementId: 'ach_xp_1000',
          name: 'XPレジェンド',
          description: '1000 XP獲得した',
          type: AchievementType.xp,
          rarity: AchievementRarity.epic,
          iconId: 'icon_xp_1000',
          xpReward: 400,
          coinReward: 200,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_xp_1000',
              description: '1000 XP獲得',
              targetValue: 1000,
              metricKey: 'total_xp_earned',
            ),
          ],
        ),
        // マイルストーン系
        Achievement(
          achievementId: 'ach_first_login',
          name: 'はじまりの一歩',
          description: 'はじめてログインした',
          type: AchievementType.milestone,
          rarity: AchievementRarity.common,
          iconId: 'icon_first_login',
          xpReward: 10,
          coinReward: 5,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_first_login',
              description: '初回ログイン',
              targetValue: 1,
              metricKey: 'login_count',
            ),
          ],
        ),
        Achievement(
          achievementId: 'ach_collector',
          name: 'コレクター',
          description: '5個のバッジを獲得した',
          type: AchievementType.milestone,
          rarity: AchievementRarity.uncommon,
          iconId: 'icon_collector',
          xpReward: 80,
          coinReward: 40,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_5_badges',
              description: '5個バッジ獲得',
              targetValue: 5,
              metricKey: 'badges_earned',
            ),
          ],
        ),
        // スキル系
        Achievement(
          achievementId: 'ach_learner',
          name: '学習者',
          description: '3つの異なるスキルを修得した',
          type: AchievementType.skill,
          rarity: AchievementRarity.uncommon,
          iconId: 'icon_learner',
          xpReward: 100,
          coinReward: 50,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_3_skills',
              description: '3スキル修得',
              targetValue: 3,
              metricKey: 'skills_mastered',
            ),
          ],
        ),
        // 参加系
        Achievement(
          achievementId: 'ach_challenger',
          name: 'チャレンジャー',
          description: '10個のチャレンジに参加した',
          type: AchievementType.participation,
          rarity: AchievementRarity.uncommon,
          iconId: 'icon_challenger',
          xpReward: 120,
          coinReward: 60,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_10_challenges',
              description: '10チャレンジ参加',
              targetValue: 10,
              metricKey: 'challenges_attempted',
            ),
          ],
        ),
        // 探索系（Secret）
        Achievement(
          achievementId: 'ach_explorer',
          name: 'エクスプローラー',
          description: 'すべての機能を試した',
          type: AchievementType.exploration,
          rarity: AchievementRarity.rare,
          iconId: 'icon_explorer',
          xpReward: 200,
          coinReward: 100,
          conditions: [
            UnlockCondition(
              conditionId: 'cond_explore_all',
              description: 'すべての機能を試す',
              targetValue: 1,
              metricKey: 'all_features_used',
            ),
          ],
          isSecret: true,
        ),
      ];

  /// アチーブメントシステムを初期化
  Future<void> initializeAchievements(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('achievements_$userId');
      final statsJson = prefs.getString('achievement_stats_$userId');

      late AchievementStats stats;

      if (statsJson != null) {
        stats = AchievementStats.fromJson(
            Map<String, dynamic>.from(statsJson as Map));
      } else {
        stats = AchievementStats(
          userId: userId,
          totalAchievements: 10,
          unlockedCount: 0,
          totalXpFromAchievements: 0,
          totalCoinsFromAchievements: 0,
          unlockedAchievements: [],
          lastUpdatedAt: DateTime.now(),
        );
      }

      final collection = AchievementCollection(
        allAchievements: _generateDefaultAchievements(),
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistAchievements(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// アチーブメント進捗を更新
  Future<bool> updateAchievementProgress(
    String userId,
    String metricKey,
    int value,
  ) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      bool anyUnlocked = false;
      final newRecentlyUnlocked = <String>[...state.recentlyUnlocked];

      for (final achievement in collection.allAchievements) {
        // すでにアンロックされているかチェック
        final alreadyUnlocked = collection.stats.unlockedAchievements
            .any((a) => a.achievementId == achievement.achievementId);

        if (alreadyUnlocked) continue;

        // 条件をチェック
        for (final condition in achievement.conditions) {
          if (condition.metricKey == metricKey) {
            // 条件を満たしたかチェック
            if (_checkCondition(condition, value)) {
              anyUnlocked = true;
              newRecentlyUnlocked.add(achievement.achievementId);

              // UserAchievementを作成
              final userAchievement = UserAchievement(
                achievementId: achievement.achievementId,
                userId: userId,
                unlockedAt: DateTime.now(),
                currentProgress: value,
                isLocked: false,
                notificationSentAt: DateTime.now().toIso8601String(),
              );

              // 統計を更新
              final updatedStats = AchievementStats(
                userId: collection.stats.userId,
                totalAchievements: collection.stats.totalAchievements,
                unlockedCount: collection.stats.unlockedCount + 1,
                totalXpFromAchievements:
                    collection.stats.totalXpFromAchievements +
                        achievement.xpReward,
                totalCoinsFromAchievements:
                    collection.stats.totalCoinsFromAchievements +
                        achievement.coinReward,
                unlockedAchievements: [
                  userAchievement,
                  ...collection.stats.unlockedAchievements,
                ],
                lastUpdatedAt: DateTime.now(),
              );

              final updatedCollection = AchievementCollection(
                allAchievements: collection.allAchievements,
                stats: updatedStats,
                generatedAt: DateTime.now(),
              );

              state = state.copyWith(
                collection: updatedCollection,
                recentlyUnlocked: newRecentlyUnlocked,
              );
            }
          }
        }
      }

      if (anyUnlocked) {
        await _persistAchievements(userId);
      }

      return anyUnlocked;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 条件をチェック
  bool _checkCondition(UnlockCondition condition, int value) {
    switch (condition.operator) {
      case 'equal':
        return value == condition.targetValue;
      case 'greater_than':
        return value >= condition.targetValue;
      case 'less_than':
        return value <= condition.targetValue;
      case 'between':
        return value >= condition.targetValue &&
            (condition.maxValue == null || value <= condition.maxValue!);
      default:
        return value >= condition.targetValue;
    }
  }

  /// 特定のアチーブメントの進捗を取得
  AchievementProgress? getProgress(String achievementId) {
    return state.collection?.getProgress(achievementId);
  }

  /// すべてのアンロック済みアチーブメントを取得
  List<Achievement> getUnlockedAchievements() {
    final collection = state.collection;
    if (collection == null) return [];

    final unlockedIds =
        collection.stats.unlockedAchievements.map((a) => a.achievementId).toSet();
    return collection.allAchievements
        .where((a) => unlockedIds.contains(a.achievementId))
        .toList();
  }

  /// すべてのロック済みアチーブメントを取得
  List<Achievement> getLockedAchievements() {
    return state.collection?.getLockedAchievements() ?? [];
  }

  /// タイプ別にアチーブメントを取得
  List<Achievement> getByType(AchievementType type) {
    return state.collection?.getByType(type) ?? [];
  }

  /// レアリティ別にアチーブメントを取得
  List<Achievement> getByRarity(AchievementRarity rarity) {
    return state.collection?.getByRarity(rarity) ?? [];
  }

  /// 最近アンロックされたアチーブメントをクリア
  void clearRecentlyUnlocked() {
    state = state.copyWith(recentlyUnlocked: []);
  }

  Future<void> _persistAchievements(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection = state.collection;
      if (collection != null) {
        await prefs.setString(
          'achievement_stats_$userId',
          collection.stats.toJson().toString(),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  int getUnlockedCount() => state.collection?.stats.unlockedCount ?? 0;
  int getTotalAchievements() => state.collection?.stats.totalAchievements ?? 0;
  double getUnlockedPercentage() =>
      state.collection?.stats.unlockedPercentage ?? 0;
  int getTotalXpFromAchievements() =>
      state.collection?.stats.totalXpFromAchievements ?? 0;
  int getTotalCoinsFromAchievements() =>
      state.collection?.stats.totalCoinsFromAchievements ?? 0;
}

final achievementProvider = StateNotifierProvider.autoDispose<
    AchievementNotifier,
    AchievementState>((ref) => AchievementNotifier());

final unlockedAchievementsProvider =
    Provider.autoDispose<List<Achievement>>((ref) {
  return ref.watch(achievementProvider).collection?.stats.unlockedAchievements
          .map((ua) {
        try {
          return ref.watch(achievementProvider).collection!.getAchievement(ua.achievementId);
        } catch (_) {
          return null;
        }
      }).whereType<Achievement>().toList() ?? [];
});

final lockedAchievementsProvider =
    Provider.autoDispose<List<Achievement>>((ref) {
  return ref.watch(achievementProvider).collection?.getLockedAchievements() ?? [];
});

final achievementStatsProvider =
    Provider.autoDispose<AchievementStats?>((ref) {
  return ref.watch(achievementProvider).collection?.stats;
});

final unlockedCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(achievementProvider).collection?.stats.unlockedCount ?? 0;
});

final unlockedPercentageProvider =
    Provider.autoDispose<double>((ref) {
  return ref.watch(achievementProvider).collection?.stats.unlockedPercentage ?? 0;
});

final totalXpFromAchievementsProvider =
    Provider.autoDispose<int>((ref) {
  return ref.watch(achievementProvider).collection?.stats.totalXpFromAchievements ?? 0;
});

final totalCoinsFromAchievementsProvider =
    Provider.autoDispose<int>((ref) {
  return ref.watch(achievementProvider).collection?.stats.totalCoinsFromAchievements ?? 0;
});
