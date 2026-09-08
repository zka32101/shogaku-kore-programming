import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';

/// バッジの状態を保持するクラス
class BadgeState {
  final List<Badge> badges; // 全バッジ
  final Map<String, int> badgeProgress; // バッジの進捗状況
  final List<String> unlockedBadgeIds; // ロック解除されたバッジID
  final DateTime? lastUpdatedAt; // 最後に更新された時刻

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
  String toString() => 'BadgeState(badges: ${badges.length})';
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
      'BadgeProgressInfo(${badge.name}: $currentValue/${badge.progressTarget})';
}

/// バッジ管理プロバイダ
class BadgeNotifier extends StateNotifier<BadgeState> {
  BadgeNotifier() : super(const BadgeState()) {
    _initializeBadges();
  }

  /// バッジの初期化
  void _initializeBadges() {
    final badges = _createDefaultBadges();
    state = BadgeState(badges: badges);
  }

  /// バッジを直接ロック解除
  Future<void> unlockBadge(String badgeId) async {
    final unlockedIds = List<String>.from(state.unlockedBadgeIds);
    if (!unlockedIds.contains(badgeId)) {
      unlockedIds.add(badgeId);
    }

    // Rebuild all badges with correct isUnlocked status based on unlockedIds
    final updatedBadges = state.badges.map((badge) {
      final shouldBeUnlocked = badge.id != null && unlockedIds.contains(badge.id);
      if (badge.isUnlocked != shouldBeUnlocked) {
        return Badge(
          id: badge.id,
          icon: badge.icon,
          name: badge.name,
          description: badge.description,
          category: badge.category,
          isUnlocked: shouldBeUnlocked,
          progressCurrent: badge.progressCurrent,
          progressTarget: badge.progressTarget,
        );
      }
      return badge;
    }).toList();

    state = state.copyWith(
      badges: updatedBadges,
      unlockedBadgeIds: unlockedIds,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// バッジの進捗を更新
  Future<void> updateBadgeProgress(String badgeId, int progress) async {
    final progressMap = Map<String, int>.from(state.badgeProgress);
    progressMap[badgeId] = progress;

    final unlockedIds = List<String>.from(state.unlockedBadgeIds);
    if (!unlockedIds.contains(badgeId)) {
      unlockedIds.add(badgeId);
    }

    // Rebuild all badges with correct progress and unlock status
    final updatedBadges = state.badges.map((badge) {
      if (badge.id == badgeId) {
        final newProgress = progress;
        final target = badge.progressTarget ?? 0;
        final shouldBeUnlocked = newProgress >= target;

        return Badge(
          id: badge.id,
          icon: badge.icon,
          name: badge.name,
          description: badge.description,
          category: badge.category,
          isUnlocked: shouldBeUnlocked,
          progressCurrent: newProgress,
          progressTarget: badge.progressTarget,
        );
      }

      // Update isUnlocked status for all badges based on unlockedIds
      final shouldBeUnlocked = badge.id != null && unlockedIds.contains(badge.id);
      if (badge.isUnlocked != shouldBeUnlocked) {
        return Badge(
          id: badge.id,
          icon: badge.icon,
          name: badge.name,
          description: badge.description,
          category: badge.category,
          isUnlocked: shouldBeUnlocked,
          progressCurrent: badge.progressCurrent,
          progressTarget: badge.progressTarget,
        );
      }
      return badge;
    }).toList();

    state = state.copyWith(
      badges: updatedBadges,
      badgeProgress: progressMap,
      unlockedBadgeIds: unlockedIds,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// クイズ正答数をインクリメント
  Future<void> incrementQuizCorrectCount() async {
    final progressMap = Map<String, int>.from(state.badgeProgress);
    progressMap['quiz_starter'] = (progressMap['quiz_starter'] ?? 0) + 1;
    progressMap['quiz_master_10'] = (progressMap['quiz_master_10'] ?? 0) + 1;

    state = state.copyWith(
      badgeProgress: progressMap,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// レッスン完了
  Future<void> completeLesson() async {
    final progressMap = Map<String, int>.from(state.badgeProgress);
    progressMap['lesson_complete_1'] = (progressMap['lesson_complete_1'] ?? 0) + 1;
    progressMap['lesson_complete_10'] = (progressMap['lesson_complete_10'] ?? 0) + 1;

    state = state.copyWith(
      badgeProgress: progressMap,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// 連続日数を更新
  Future<void> updateConsecutiveDays(int days) async {
    final progressMap = Map<String, int>.from(state.badgeProgress);
    progressMap['daily_1day'] = days;
    progressMap['daily_7day'] = days;

    state = state.copyWith(
      badgeProgress: progressMap,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// 勉強時間を更新
  Future<void> updateStudyHours(int hours) async {
    final progressMap = Map<String, int>.from(state.badgeProgress);
    progressMap['milestone_100hours'] = hours;

    state = state.copyWith(
      badgeProgress: progressMap,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// デフォルトバッジを作成
  static List<Badge> _createDefaultBadges() => [
        // クイズ系バッジ
        Badge(
          id: 'quiz_starter',
          icon: '🎯',
          name: 'クイズ始める',
          description: '初めてクイズに挑戦した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 1,
        ),
        Badge(
          id: 'quiz_master_10',
          icon: '⭐',
          name: 'クイズマスター Lv.1',
          description: 'クイズを10問正解した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 10,
        ),
        Badge(
          id: 'quiz_master_50',
          icon: '✨',
          name: 'クイズマスター Lv.2',
          description: 'クイズを50問正解した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 50,
        ),
        Badge(
          id: 'quiz_master_100',
          icon: '👑',
          name: 'クイズマスター Lv.3',
          description: 'クイズを100問正解した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 100,
        ),

        // 進捗系バッジ
        Badge(
          id: 'lesson_complete_1',
          icon: '✅',
          name: 'レッスン完了',
          description: 'レッスンを1つ完了した',
          category: 'progress',
          isUnlocked: false,
          progressTarget: 1,
        ),
        Badge(
          id: 'lesson_complete_10',
          icon: '🎓',
          name: 'レッスン達成者',
          description: 'レッスンを10個完了した',
          category: 'progress',
          isUnlocked: false,
          progressTarget: 10,
        ),

        // 継続系バッジ
        Badge(
          id: 'daily_1day',
          icon: '🔥',
          name: '毎日挑戦',
          description: '1日連続で学習した',
          category: 'consistency',
          isUnlocked: false,
          progressTarget: 1,
        ),
        Badge(
          id: 'daily_7day',
          icon: '🌟',
          name: '1週間チャレンジ',
          description: '7日連続で学習した',
          category: 'consistency',
          isUnlocked: false,
          progressTarget: 7,
        ),

        // 習熟系バッジ
        Badge(
          id: 'mastery_accuracy_90',
          icon: '🎯',
          name: '正確性マスター',
          description: 'クイズの正答率が90%以上',
          category: 'mastery',
          isUnlocked: false,
          progressTarget: 90,
        ),

        // ソーシャル系バッジ
        Badge(
          id: 'social_ranking_top10',
          icon: '🏆',
          name: 'ランキング入賞',
          description: 'ランキングでトップ10に入った',
          category: 'social',
          isUnlocked: false,
          progressTarget: 1,
        ),

        // スペシャル系バッジ
        Badge(
          id: 'milestone_100hours',
          icon: '💎',
          name: '100時間マイルストーン',
          description: '学習時間が累計100時間に達した',
          category: 'special',
          isUnlocked: false,
          progressTarget: 100,
        ),
      ];
}

/// バッジプロバイダ
final badgeProvider = StateNotifierProvider<BadgeNotifier, BadgeState>((ref) {
  return BadgeNotifier();
});
