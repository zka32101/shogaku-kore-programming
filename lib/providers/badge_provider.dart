import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/badge.dart';
import '../providers/profile_provider.dart';

/// バッジの状態を保持するクラス
class BadgeState {
  final List<Badge> badges;              // 全バッジ
  final Map<String, int> badgeProgress;  // バッジID -> 現在の進捗値
  final List<String> unlockedBadgeIds;   // アンロック済みバッジID
  final DateTime? lastUpdatedAt;         // 最終更新日時

  const BadgeState({
    this.badges = const [],
    this.badgeProgress = const {},
    this.unlockedBadgeIds = const [],
    this.lastUpdatedAt,
  });

  /// コピーメソッド
  BadgeState copyWith({
    List<Badge>? badges,
    Map<String, int>? badgeProgress,
    List<String>? unlockedBadgeIds,
    DateTime? lastUpdatedAt,
  }) =>
      BadgeState(
        badges: badges ?? this.badges,
        badgeProgress: badgeProgress ?? this.badgeProgress,
        unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );

  @override
  String toString() =>
      'BadgeState(badges: ${badges.length}, unlockedBadgeIds: ${unlockedBadgeIds.length})';
}

/// バッジ進捗情報を取得
class BadgeProgressInfo {
  final Badge badge;
  final int currentValue;
  final int remainingValue;
  final double progressPercentage;
  final bool isUnlocked;
  final bool canUnlock;

  const BadgeProgressInfo({
    required this.badge,
    required this.currentValue,
    required this.remainingValue,
    required this.progressPercentage,
    required this.isUnlocked,
    required this.canUnlock,
  });

  @override
  String toString() =>
      'BadgeProgressInfo(${badge.name}: $currentValue/${badge.requiredValue})';
}

/// バッジ管理プロバイダ
class BadgeNotifier extends StateNotifier<BadgeState> {
  BadgeNotifier() : super(const BadgeState()) {
    _initializeBadges();
  }

  static const String _badgesKey = 'badges';
  static const String _badgeProgressKey = 'badge_progress';
  static const String _unlockedBadgesKey = 'unlocked_badges';

  /// バッジの初期化
  Future<void> _initializeBadges() async {
    final prefs = await SharedPreferences.getInstance();

    // 保存されたバッジを読み込む
    final savedBadgesJson = prefs.getStringList(_badgesKey) ?? [];
    final savedProgress = prefs.getStringList(_badgeProgressKey) ?? [];
    final unlockedIds = prefs.getStringList(_unlockedBadgesKey) ?? [];

    // バッジを復元
    List<Badge> badges = [];
    if (savedBadgesJson.isNotEmpty) {
      badges = savedBadgesJson
          .map((json) => Badge.fromJson(jsonDecode(json)))
          .toList();
    } else {
      // デフォルトバッジを作成
      badges = _createDefaultBadges();
    }

    // 進捗を復元
    Map<String, int> progress = {};
    for (final progressJson in savedProgress) {
      final decoded = jsonDecode(progressJson) as Map<String, dynamic>;
      progress[decoded['id'] as String] = decoded['value'] as int;
    }

    state = BadgeState(
      badges: badges,
      badgeProgress: progress,
      unlockedBadgeIds: unlockedIds,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// デフォルトバッジを作成
  static List<Badge> _createDefaultBadges() => [
        // クイズ系バッジ
        Badge(
          id: 'quiz_starter',
          name: 'クイズ始める',
          description: '初めてクイズに挑戦した',
          emoji: '🎯',
          category: BadgeCategory.quiz,
          difficulty: BadgeDifficulty.bronze,
          requiredValue: 1,
          hint: '最初のクイズに挑戦しよう',
        ),
        Badge(
          id: 'quiz_master_10',
          name: 'クイズマスター Lv.1',
          description: 'クイズを10問正解した',
          emoji: '⭐',
          category: BadgeCategory.quiz,
          difficulty: BadgeDifficulty.silver,
          requiredValue: 10,
          hint: '10問正解を目指そう',
        ),
        Badge(
          id: 'quiz_master_50',
          name: 'クイズマスター Lv.2',
          description: 'クイズを50問正解した',
          emoji: '✨',
          category: BadgeCategory.quiz,
          difficulty: BadgeDifficulty.gold,
          requiredValue: 50,
          hint: '50問正解を目指そう',
        ),
        Badge(
          id: 'quiz_master_100',
          name: 'クイズマスター Lv.3',
          description: 'クイズを100問正解した',
          emoji: '👑',
          category: BadgeCategory.quiz,
          difficulty: BadgeDifficulty.platinum,
          requiredValue: 100,
          hint: '100問正解を目指そう',
        ),

        // 進捗系バッジ
        Badge(
          id: 'lesson_complete_1',
          name: 'レッスン完了',
          description: 'レッスンを1つ完了した',
          emoji: '✅',
          category: BadgeCategory.progress,
          difficulty: BadgeDifficulty.bronze,
          requiredValue: 1,
          hint: 'レッスンを完了しよう',
        ),
        Badge(
          id: 'lesson_complete_10',
          name: 'レッスン達成者',
          description: 'レッスンを10個完了した',
          emoji: '🎓',
          category: BadgeCategory.progress,
          difficulty: BadgeDifficulty.silver,
          requiredValue: 10,
          hint: '10レッスン完了を目指そう',
        ),

        // 継続系バッジ
        Badge(
          id: 'daily_1day',
          name: '毎日挑戦',
          description: '1日連続で学習した',
          emoji: '🔥',
          category: BadgeCategory.consistency,
          difficulty: BadgeDifficulty.bronze,
          requiredValue: 1,
          hint: '毎日学習を続けよう',
        ),
        Badge(
          id: 'daily_7day',
          name: '1週間チャレンジ',
          description: '7日連続で学習した',
          emoji: '🌟',
          category: BadgeCategory.consistency,
          difficulty: BadgeDifficulty.silver,
          requiredValue: 7,
          hint: '1週間連続学習を目指そう',
        ),

        // 習熟系バッジ
        Badge(
          id: 'accuracy_90',
          name: '正確性マスター',
          description: 'クイズの正答率が90%以上',
          emoji: '🎯',
          category: BadgeCategory.mastery,
          difficulty: BadgeDifficulty.gold,
          requiredValue: 90,
          hint: '正答率90%を目指そう',
        ),

        // ソーシャル系バッジ
        Badge(
          id: 'ranking_top10',
          name: 'ランキング入賞',
          description: 'ランキングでトップ10に入った',
          emoji: '🏆',
          category: BadgeCategory.social,
          difficulty: BadgeDifficulty.gold,
          requiredValue: 1,
          hint: 'ランキングトップ10を目指そう',
        ),

        // スペシャル系バッジ
        Badge(
          id: 'milestone_100hours',
          name: '100時間マイルストーン',
          description: '学習時間が累計100時間に達した',
          emoji: '💎',
          category: BadgeCategory.special,
          difficulty: BadgeDifficulty.platinum,
          requiredValue: 100,
          hint: '100時間の学習を目指そう',
        ),
      ];

  /// バッジの進捗を更新
  Future<void> updateBadgeProgress(String badgeId, int newValue) async {
    final prefs = await SharedPreferences.getInstance();

    final updatedProgress = Map<String, int>.from(state.badgeProgress);
    updatedProgress[badgeId] = newValue;

    // アンロック可能かチェック
    final badge = state.badges.firstWhere(
      (b) => b.id == badgeId,
      orElse: () => throw Exception('Badge not found: $badgeId'),
    );

    List<String> unlockedIds = List.from(state.unlockedBadgeIds);
    if (newValue >= badge.requiredValue &&
        !unlockedIds.contains(badgeId) &&
        badge.unlockedAt == null) {
      unlockedIds.add(badgeId);
      // アンロック日時を更新したバッジを作成
      final unlockedBadge = badge.copyWith(unlockedAt: DateTime.now());
      final badgeIndex = state.badges.indexWhere((b) => b.id == badgeId);
      final updatedBadges = List<Badge>.from(state.badges);
      updatedBadges[badgeIndex] = unlockedBadge;
      state = state.copyWith(badges: updatedBadges);
    }

    // SharedPreferences に保存
    final badgesList = state.badges
        .map((b) => jsonEncode(b.toJson()))
        .toList();
    final progressList = updatedProgress.entries
        .map((e) => jsonEncode({'id': e.key, 'value': e.value}))
        .toList();

    await prefs.setStringList(_badgesKey, badgesList);
    await prefs.setStringList(_badgeProgressKey, progressList);
    await prefs.setStringList(_unlockedBadgesKey, unlockedIds);

    state = state.copyWith(
      badgeProgress: updatedProgress,
      unlockedBadgeIds: unlockedIds,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// バッジをアンロック（直接アンロック、テスト用）
  Future<void> unlockBadge(String badgeId) async {
    final prefs = await SharedPreferences.getInstance();

    if (state.unlockedBadgeIds.contains(badgeId)) {
      return; // すでにアンロック済み
    }

    final badgeIndex =
        state.badges.indexWhere((b) => b.id == badgeId);
    if (badgeIndex < 0) {
      throw Exception('Badge not found: $badgeId');
    }

    // アンロック日時を設定
    final updatedBadges = List<Badge>.from(state.badges);
    updatedBadges[badgeIndex] =
        updatedBadges[badgeIndex].copyWith(unlockedAt: DateTime.now());

    final unlockedIds = List<String>.from(state.unlockedBadgeIds)
      ..add(badgeId);

    // SharedPreferences に保存
    final badgesList = updatedBadges
        .map((b) => jsonEncode(b.toJson()))
        .toList();
    await prefs.setStringList(_badgesKey, badgesList);
    await prefs.setStringList(_unlockedBadgesKey, unlockedIds);

    state = state.copyWith(
      badges: updatedBadges,
      unlockedBadgeIds: unlockedIds,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// クイズ正解数を増やす
  Future<void> incrementQuizCorrectCount() async {
    await updateBadgeProgress('quiz_starter', 1);
    await updateBadgeProgress(
      'quiz_master_10',
      (state.badgeProgress['quiz_master_10'] ?? 0) + 1,
    );
    await updateBadgeProgress(
      'quiz_master_50',
      (state.badgeProgress['quiz_master_50'] ?? 0) + 1,
    );
    await updateBadgeProgress(
      'quiz_master_100',
      (state.badgeProgress['quiz_master_100'] ?? 0) + 1,
    );
  }

  /// レッスン完了
  Future<void> completeLesson() async {
    await updateBadgeProgress(
      'lesson_complete_1',
      (state.badgeProgress['lesson_complete_1'] ?? 0) + 1,
    );
    await updateBadgeProgress(
      'lesson_complete_10',
      (state.badgeProgress['lesson_complete_10'] ?? 0) + 1,
    );
  }

  /// 連続日数を更新
  Future<void> updateConsecutiveDays(int days) async {
    if (days >= 1) {
      await updateBadgeProgress('daily_1day', days);
    }
    if (days >= 7) {
      await updateBadgeProgress('daily_7day', days);
    }
  }

  /// 学習時間を更新（時間単位）
  Future<void> updateStudyHours(int hours) async {
    if (hours >= 100) {
      await updateBadgeProgress('milestone_100hours', hours);
    }
  }

  /// バッジの進捗情報を取得
  BadgeProgressInfo getBadgeProgressInfo(String badgeId) {
    final badge = state.badges.firstWhere(
      (b) => b.id == badgeId,
      orElse: () => throw Exception('Badge not found: $badgeId'),
    );

    final currentValue = state.badgeProgress[badgeId] ?? 0;
    final isUnlocked = state.unlockedBadgeIds.contains(badgeId);
    final remainingValue = (badge.requiredValue - currentValue).abs();
    final progressPercentage =
        (currentValue / badge.requiredValue * 100).clamp(0, 100);

    return BadgeProgressInfo(
      badge: badge,
      currentValue: currentValue,
      remainingValue: remainingValue,
      progressPercentage: progressPercentage,
      isUnlocked: isUnlocked,
      canUnlock: currentValue >= badge.requiredValue && !isUnlocked,
    );
  }

  /// 特定カテゴリのバッジを取得
  List<BadgeProgressInfo> getBadgesByCategory(BadgeCategory category) {
    return state.badges
        .where((b) => b.category == category)
        .map((b) => getBadgeProgressInfo(b.id))
        .toList();
  }

  /// アンロック済みバッジを取得
  List<BadgeProgressInfo> getUnlockedBadges() {
    return state.badges
        .where((b) => state.unlockedBadgeIds.contains(b.id))
        .map((b) => getBadgeProgressInfo(b.id))
        .toList();
  }

  /// 進捗中のバッジを取得（アンロックまであと少しなもの）
  List<BadgeProgressInfo> getInProgressBadges({int limit = 5}) {
    return state.badges
        .where((b) => !state.unlockedBadgeIds.contains(b.id))
        .map((b) => getBadgeProgressInfo(b.id))
        .where((info) => info.currentValue > 0)
        .toList()
        .take(limit)
        .toList();
  }
}

/// バッジプロバイダ
final badgeProvider = StateNotifierProvider<BadgeNotifier, BadgeState>(
  (ref) => BadgeNotifier(),
);

/// バッジの進捗情報を取得するプロバイダ
final badgeProgressProvider =
    FutureProvider.family<BadgeProgressInfo, String>((ref, badgeId) async {
  final badgeNotifier = ref.watch(badgeProvider.notifier);
  return badgeNotifier.getBadgeProgressInfo(badgeId);
});

/// カテゴリ別バッジを取得するプロバイダ
final badgesByCategoryProvider = FutureProvider.family<
    List<BadgeProgressInfo>, BadgeCategory>((ref, category) async {
  final badgeNotifier = ref.watch(badgeProvider.notifier);
  return badgeNotifier.getBadgesByCategory(category);
});

/// アンロック済みバッジを取得するプロバイダ
final unlockedBadgesProvider =
    FutureProvider<List<BadgeProgressInfo>>((ref) async {
  final badgeNotifier = ref.watch(badgeProvider.notifier);
  return badgeNotifier.getUnlockedBadges();
});

/// 進捗中のバッジを取得するプロバイダ
final inProgressBadgesProvider =
    FutureProvider<List<BadgeProgressInfo>>((ref) async {
  final badgeNotifier = ref.watch(badgeProvider.notifier);
  return badgeNotifier.getInProgressBadges();
});
