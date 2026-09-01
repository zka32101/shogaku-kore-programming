/// 毎日ミッションモデル
class DailyMission {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final MissionType type;
  final MissionDifficulty difficulty;
  final int targetValue;        // 達成に必要な値
  final int rewardCoins;        // 報酬コイン
  final int rewardXp;           // 報酬XP
  final String? rewardBadgeId;  // 報酬バッジID（オプション）
  final DateTime? completedAt;  // 完了日時

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.difficulty,
    required this.targetValue,
    required this.rewardCoins,
    required this.rewardXp,
    this.rewardBadgeId,
    this.completedAt,
  });

  /// ミッションが完了しているか
  bool get isCompleted => completedAt != null;

  /// コピーメソッド
  DailyMission copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    MissionType? type,
    MissionDifficulty? difficulty,
    int? targetValue,
    int? rewardCoins,
    int? rewardXp,
    String? rewardBadgeId,
    DateTime? completedAt,
  }) =>
      DailyMission(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        type: type ?? this.type,
        difficulty: difficulty ?? this.difficulty,
        targetValue: targetValue ?? this.targetValue,
        rewardCoins: rewardCoins ?? this.rewardCoins,
        rewardXp: rewardXp ?? this.rewardXp,
        rewardBadgeId: rewardBadgeId ?? this.rewardBadgeId,
        completedAt: completedAt ?? this.completedAt,
      );

  /// JSONシリアライズ
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'type': type.name,
    'difficulty': difficulty.name,
    'targetValue': targetValue,
    'rewardCoins': rewardCoins,
    'rewardXp': rewardXp,
    'rewardBadgeId': rewardBadgeId,
    'completedAt': completedAt?.toIso8601String(),
  };

  /// JSONデシリアライズ
  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    emoji: json['emoji'] as String,
    type: MissionType.values.byName(json['type'] as String),
    difficulty: MissionDifficulty.values.byName(json['difficulty'] as String),
    targetValue: json['targetValue'] as int,
    rewardCoins: json['rewardCoins'] as int,
    rewardXp: json['rewardXp'] as int,
    rewardBadgeId: json['rewardBadgeId'] as String?,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMission && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DailyMission(id: $id, title: $title, isCompleted: $isCompleted)';
}

/// ミッションタイプ
enum MissionType {
  quiz,           // クイズ系
  lesson,         // レッスン系
  streak,         // 連続学習
  accuracy,       // 正答率
  timeSpent,      // 学習時間
  socialShare,    // シェア
}

/// ミッション難易度
enum MissionDifficulty {
  easy,           // 簡単
  normal,         // 普通
  hard,           // 難しい
  extreme,        // 極難
}

/// 毎日ミッションの進捗情報
class DailyMissionProgress {
  final DailyMission mission;
  final int currentValue;        // 現在の進捗値
  final double progress;         // 進捗率（0.0-1.0）

  const DailyMissionProgress({
    required this.mission,
    required this.currentValue,
    required this.progress,
  });

  /// 完了までの残り値
  int get remainingValue => (mission.targetValue - currentValue).abs();

  /// 完了可能か
  bool get canComplete =>
      currentValue >= mission.targetValue && !mission.isCompleted;

  @override
  String toString() =>
    'DailyMissionProgress(${mission.title}: $currentValue/${mission.targetValue}, $progress%)';
}

/// 1日のミッションセット
class DailyMissionSet {
  final DateTime date;
  final List<DailyMission> missions;
  final int totalRewardCoins;
  final int totalRewardXp;

  const DailyMissionSet({
    required this.date,
    required this.missions,
    required this.totalRewardCoins,
    required this.totalRewardXp,
  });

  /// 完了したミッションの数
  int get completedCount => missions.where((m) => m.isCompleted).length;

  /// 完了率
  double get completionRate =>
      missions.isEmpty ? 0.0 : completedCount / missions.length;

  /// 全ミッション完了か
  bool get isAllCompleted => completedCount == missions.length;

  /// 本日のミッションセットか
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  String toString() =>
    'DailyMissionSet(${date.toIso8601String()}, $completedCount/${missions.length})';
}
