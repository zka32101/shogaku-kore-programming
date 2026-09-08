import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';

/// バッジの状態を保持するクラス
class BadgeState {
  final List<Badge> badges; // 全バッジ

  const BadgeState({
    this.badges = const [],
  });

  /// コピーメソッド
  BadgeState copyWith({
    List<Badge>? badges,
  }) =>
      BadgeState(
        badges: badges ?? this.badges,
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
  Future<void> _initializeBadges() async {
    final badges = _createDefaultBadges();

    state = BadgeState(badges: badges);
  }

  /// バッジを直接ロック解除
  Future<void> unlockBadge(String badgeId) async {
    final updatedBadges = state.badges.map((badge) {
      if (badge.name.contains(badgeId) || badge.icon == badgeId) {
        return Badge(
          icon: badge.icon,
          name: badge.name,
          description: badge.description,
          category: badge.category,
          isUnlocked: true,
          progressCurrent: badge.progressCurrent,
          progressTarget: badge.progressTarget,
        );
      }
      return badge;
    }).toList();

    state = BadgeState(badges: updatedBadges);
  }

  /// バッジの進捗を更新
  Future<void> updateBadgeProgress(String badgeId, int progress) async {
    final updatedBadges = state.badges.map((badge) {
      if (badge.name.contains(badgeId) || badge.icon == badgeId) {
        return Badge(
          icon: badge.icon,
          name: badge.name,
          description: badge.description,
          category: badge.category,
          isUnlocked: progress >= (badge.progressTarget ?? 0),
          progressCurrent: progress,
          progressTarget: badge.progressTarget,
        );
      }
      return badge;
    }).toList();

    state = BadgeState(badges: updatedBadges);
  }

  /// クイズ正答数をインクリメント
  Future<void> incrementQuizCorrectCount() async {
    await updateBadgeProgress('quiz_starter', 1);
    await updateBadgeProgress('quiz_master_10', 10);
  }

  /// レッスン完了
  Future<void> completeLesson() async {
    await updateBadgeProgress('lesson_complete_1', 1);
    await updateBadgeProgress('lesson_complete_10', 10);
  }

  /// 連続日数を更新
  Future<void> updateConsecutiveDays(int days) async {
    await updateBadgeProgress('daily_1day', days);
    await updateBadgeProgress('daily_7day', days);
  }

  /// 勉強時間を更新
  Future<void> updateStudyHours(int hours) async {
    await updateBadgeProgress('milestone_100hours', hours);
  }

  /// デフォルトバッジを作成
  static List<Badge> _createDefaultBadges() => [
        // クイズ系バッジ
        Badge(
          icon: '🎯',
          name: 'クイズ始める',
          description: '初めてクイズに挑戦した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 1,
        ),
        Badge(
          icon: '⭐',
          name: 'クイズマスター Lv.1',
          description: 'クイズを10問正解した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 10,
        ),
        Badge(
          icon: '✨',
          name: 'クイズマスター Lv.2',
          description: 'クイズを50問正解した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 50,
        ),
        Badge(
          icon: '👑',
          name: 'クイズマスター Lv.3',
          description: 'クイズを100問正解した',
          category: 'quiz',
          isUnlocked: false,
          progressTarget: 100,
        ),

        // 進捗系バッジ
        Badge(
          icon: '✅',
          name: 'レッスン完了',
          description: 'レッスンを1つ完了した',
          category: 'progress',
          isUnlocked: false,
          progressTarget: 1,
        ),
        Badge(
          icon: '🎓',
          name: 'レッスン達成者',
          description: 'レッスンを10個完了した',
          category: 'progress',
          isUnlocked: false,
          progressTarget: 10,
        ),

        // 継続系バッジ
        Badge(
          icon: '🔥',
          name: '毎日挑戦',
          description: '1日連続で学習した',
          category: 'consistency',
          isUnlocked: false,
          progressTarget: 1,
        ),
        Badge(
          icon: '🌟',
          name: '1週間チャレンジ',
          description: '7日連続で学習した',
          category: 'consistency',
          isUnlocked: false,
          progressTarget: 7,
        ),

        // 習熟系バッジ
        Badge(
          icon: '🎯',
          name: '正確性マスター',
          description: 'クイズの正答率が90%以上',
          category: 'mastery',
          isUnlocked: false,
          progressTarget: 90,
        ),

        // ソーシャル系バッジ
        Badge(
          icon: '🏆',
          name: 'ランキング入賞',
          description: 'ランキングでトップ10に入った',
          category: 'social',
          isUnlocked: false,
          progressTarget: 1,
        ),

        // スペシャル系バッジ
        Badge(
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
