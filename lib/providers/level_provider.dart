import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/level.dart';

/// ユーザーレベルの状態
class LevelState {
  final int currentLevel;                // 現在のレベル（1-50）
  final int totalXpEarned;               // 累積経験値
  final DateTime? lastLevelUpDate;       // 最後にレベルアップした日時
  final List<int> milestoneReached;      // 達成したマイルストーン（レベル10, 25, 40, 50など）
  final LevelUpEvent? lastLevelUpEvent;  // 最後のレベルアップイベント

  const LevelState({
    this.currentLevel = 1,
    this.totalXpEarned = 0,
    this.lastLevelUpDate,
    this.milestoneReached = const [],
    this.lastLevelUpEvent,
  });

  /// コピーメソッド
  LevelState copyWith({
    int? currentLevel,
    int? totalXpEarned,
    DateTime? lastLevelUpDate,
    List<int>? milestoneReached,
    LevelUpEvent? lastLevelUpEvent,
  }) =>
      LevelState(
        currentLevel: currentLevel ?? this.currentLevel,
        totalXpEarned: totalXpEarned ?? this.totalXpEarned,
        lastLevelUpDate: lastLevelUpDate ?? this.lastLevelUpDate,
        milestoneReached: milestoneReached ?? this.milestoneReached,
        lastLevelUpEvent: lastLevelUpEvent ?? this.lastLevelUpEvent,
      );

  @override
  String toString() =>
      'LevelState(Level $currentLevel, Total XP: $totalXpEarned)';
}

/// ユーザーレベル管理プロバイダ
class LevelNotifier extends StateNotifier<LevelState> {
  LevelNotifier() : super(const LevelState()) {
    _initializeLevelData();
  }

  static const String _levelKey = 'user_level';
  static const String _xpKey = 'user_total_xp';
  static const String _lastLevelUpKey = 'last_level_up_date';
  static const String _milestonesKey = 'milestones_reached';

  /// レベルデータの初期化
  Future<void> _initializeLevelData() async {
    final prefs = await SharedPreferences.getInstance();

    final currentLevel = prefs.getInt(_levelKey) ?? 1;
    final totalXp = prefs.getInt(_xpKey) ?? 0;
    final lastLevelUpStr = prefs.getString(_lastLevelUpKey);
    final milestonesJson = prefs.getStringList(_milestonesKey) ?? [];

    DateTime? lastLevelUp;
    if (lastLevelUpStr != null) {
      lastLevelUp = DateTime.parse(lastLevelUpStr);
    }

    final milestones =
        milestonesJson.map((m) => int.parse(m)).toList();

    state = LevelState(
      currentLevel: currentLevel,
      totalXpEarned: totalXp,
      lastLevelUpDate: lastLevelUp,
      milestoneReached: milestones,
    );
  }

  /// 経験値を追加
  Future<List<LevelUpEvent>> addExperience(int xpAmount) async {
    final prefs = await SharedPreferences.getInstance();
    final oldLevel = state.currentLevel;
    var newTotalXp = state.totalXpEarned + xpAmount;
    var newLevel = DefaultLevels.getLevelFromTotalXp(newTotalXp);
    var newMilestones = List<int>.from(state.milestoneReached);
    final levelUpEvents = <LevelUpEvent>[];

    // レベルアップ処理
    while (newLevel > oldLevel + (levelUpEvents.length)) {
      final levelUpNum = oldLevel + levelUpEvents.length + 1;
      final levelData = DefaultLevels.getLevelByNumber(levelUpNum);

      if (levelData != null) {
        final event = LevelUpEvent(
          oldLevel: oldLevel + levelUpEvents.length,
          newLevel: levelUpNum,
          levelData: levelData,
          timestamp: DateTime.now(),
          coinsReward: levelData.rewardCoins,
          xpBonus: levelData.rewardXp,
        );
        levelUpEvents.add(event);

        // マイルストーン記録
        if (!newMilestones.contains(levelUpNum)) {
          newMilestones.add(levelUpNum);
        }
      }
    }

    // 状態更新
    final lastEvent = levelUpEvents.isNotEmpty ? levelUpEvents.last : null;
    state = state.copyWith(
      currentLevel: newLevel,
      totalXpEarned: newTotalXp,
      lastLevelUpDate: lastEvent?.timestamp,
      milestoneReached: newMilestones,
      lastLevelUpEvent: lastEvent,
    );

    // SharedPreferencesに保存
    await prefs.setInt(_levelKey, newLevel);
    await prefs.setInt(_xpKey, newTotalXp);
    if (lastEvent != null) {
      await prefs.setString(_lastLevelUpKey, lastEvent.timestamp.toIso8601String());
    }
    await prefs.setStringList(
      _milestonesKey,
      newMilestones.map((m) => m.toString()).toList(),
    );

    return levelUpEvents;
  }

  /// 現在のレベル情報を取得
  UserLevelProgress getLevelProgress() {
    final level = DefaultLevels.getLevelByNumber(state.currentLevel);
    if (level == null) {
      throw Exception('Invalid level: ${state.currentLevel}');
    }

    final nextLevelNumber = state.currentLevel + 1;
    late final int nextLevelXp;

    if (nextLevelNumber > 50) {
      nextLevelXp = level.requiredXp + 100000; // Max level
    } else {
      final nextLevel = DefaultLevels.getLevelByNumber(nextLevelNumber);
      nextLevelXp = nextLevel?.requiredXp ?? level.requiredXp + 1000;
    }

    final currentLevelXp = state.totalXpEarned - level.requiredXp;
    final xpForLevel = nextLevelXp - level.requiredXp;
    final progressPercentage =
        (currentLevelXp / xpForLevel * 100).clamp(0.0, 100.0);

    return UserLevelProgress(
      level: level,
      currentXp: currentLevelXp,
      totalXpEarned: state.totalXpEarned,
      progress: progressPercentage,
    );
  }

  /// 次のレベルまでの必要XPを取得
  int getXpToNextLevel() {
    final progress = getLevelProgress();
    return progress.remainingXp;
  }

  /// マイルストーン達成状況を取得
  Map<int, bool> getMilestoneStatus() {
    return {
      10: state.milestoneReached.contains(10),
      25: state.milestoneReached.contains(25),
      40: state.milestoneReached.contains(40),
      50: state.milestoneReached.contains(50),
    };
  }

  /// レベルアップ可能か判定
  bool canLevelUp() {
    return getLevelProgress().canLevelUp;
  }

  /// レベル統計情報を取得
  Map<String, dynamic> getStats() {
    final progress = getLevelProgress();
    final milestones = getMilestoneStatus();

    return {
      'currentLevel': state.currentLevel,
      'totalXpEarned': state.totalXpEarned,
      'currentLevelXp': progress.currentXp,
      'nextLevelXp': progress.remainingXp,
      'progressPercentage': progress.progress,
      'lastLevelUpDate': state.lastLevelUpDate?.toIso8601String(),
      'milestonesReached': milestones,
      'maxLevel': 50,
    };
  }
}

/// プロバイダー定義

/// レベル状態プロバイダ
final levelProvider = StateNotifierProvider<LevelNotifier, LevelState>(
  (ref) => LevelNotifier(),
);

/// レベル進捗情報プロバイダ
final levelProgressProvider = FutureProvider<UserLevelProgress>((ref) async {
  final levelState = ref.watch(levelProvider);
  final notifier = ref.read(levelProvider.notifier);

  // 状態が更新されるたびに再計算
  return notifier.getLevelProgress();
});

/// 次のレベルまでのXPプロバイダ
final xpToNextLevelProvider = FutureProvider<int>((ref) async {
  ref.watch(levelProvider);
  final notifier = ref.read(levelProvider.notifier);
  return notifier.getXpToNextLevel();
});

/// マイルストーン状態プロバイダ
final milestonesProvider = FutureProvider<Map<int, bool>>((ref) async {
  ref.watch(levelProvider);
  final notifier = ref.read(levelProvider.notifier);
  return notifier.getMilestoneStatus();
});

/// レベル統計情報プロバイダ
final levelStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(levelProvider);
  final notifier = ref.read(levelProvider.notifier);
  return notifier.getStats();
});
