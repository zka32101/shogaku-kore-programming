/// レベルシステムのモデル定義

/// レベルの難易度
enum LevelTier {
  beginner,   // 初心者
  intermediate, // 中級者
  advanced,   // 上級者
  expert,     // エキスパート
}

/// ユーザーレベルの定義
class Level {
  final int levelNumber;                // レベル番号（1-50）
  final String title;                   // レベルの名前
  final String description;             // レベルの説明
  final int requiredXp;                 // このレベルに到達するまでの累積XP
  final int rewardCoins;                // レベルアップ時の報酬コイン
  final int rewardXp;                   // ボーナスXP
  final String? rewardBadgeId;          // 報酬バッジID
  final LevelTier tier;                 // 難易度ランク
  final String emoji;                   // レベルのエモジ

  Level({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.requiredXp,
    required this.rewardCoins,
    required this.rewardXp,
    required this.tier,
    required this.emoji,
    this.rewardBadgeId,
  });

  /// JSON形式に変換
  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'title': title,
    'description': description,
    'requiredXp': requiredXp,
    'rewardCoins': rewardCoins,
    'rewardXp': rewardXp,
    'rewardBadgeId': rewardBadgeId,
    'tier': tier.name,
    'emoji': emoji,
  };

  /// JSONから復元
  factory Level.fromJson(Map<String, dynamic> json) => Level(
    levelNumber: json['levelNumber'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    requiredXp: json['requiredXp'] as int,
    rewardCoins: json['rewardCoins'] as int,
    rewardXp: json['rewardXp'] as int,
    tier: LevelTier.values.byName(json['tier'] as String),
    emoji: json['emoji'] as String,
    rewardBadgeId: json['rewardBadgeId'] as String?,
  );

  /// 同値判定
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Level &&
          runtimeType == other.runtimeType &&
          levelNumber == other.levelNumber;

  @override
  int get hashCode => levelNumber.hashCode;

  @override
  String toString() => '$title (Level $levelNumber)';
}

/// ユーザーのレベル進捗
class UserLevelProgress {
  final Level level;                    // 現在のレベル
  final int currentXp;                  // 現在のレベル内での経験値
  final int totalXpEarned;              // 累積経験値
  final double progress;                // 次のレベルまでの進捗率（0.0-100.0）
  final DateTime? levelUpAt;            // レベルアップ日時

  UserLevelProgress({
    required this.level,
    required this.currentXp,
    required this.totalXpEarned,
    required this.progress,
    this.levelUpAt,
  });

  /// 次のレベルまでの必要XP
  int get remainingXp {
    final nextLevel = level.levelNumber + 1;
    if (nextLevel > 50) return 0; // Max level is 50
    final xpForNextLevel = _calculateRequiredXp(nextLevel);
    return (xpForNextLevel - totalXpEarned).clamp(0, xpForNextLevel);
  }

  /// レベルアップ可能か判定
  bool get canLevelUp => remainingXp == 0;

  /// XP要件に基づいて次のレベルまでのXPを計算
  static int _calculateRequiredXp(int nextLevelNumber) {
    // 指数関数的な成長: 各レベルは前のレベルより1.15倍のXPが必要
    // レベル1: 100XP, レベル2: 115XP, ..., レベル50: 数千XP
    int baseXp = 100;
    return (baseXp * (1.15 ^ (nextLevelNumber - 1))).toInt();
  }

  @override
  String toString() => '${level.title} - $currentXp/${_calculateRequiredXp(level.levelNumber + 1)} XP';
}

/// レベルアップイベント
class LevelUpEvent {
  final int oldLevel;
  final int newLevel;
  final Level levelData;
  final DateTime timestamp;
  final int coinsReward;
  final int xpBonus;

  LevelUpEvent({
    required this.oldLevel,
    required this.newLevel,
    required this.levelData,
    required this.timestamp,
    required this.coinsReward,
    required this.xpBonus,
  });

  @override
  String toString() =>
      'LevelUpEvent(Level $oldLevel → $newLevel at ${timestamp.toLocal()})';
}

/// デフォルトレベル定義
class DefaultLevels {
  static List<Level> generateLevels() {
    final levels = <Level>[];

    // レベル1-10: 初心者 (100XP基準, 1.15倍成長)
    for (int i = 1; i <= 10; i++) {
      final requiredXp = _calculateLevelXp(i);
      levels.add(Level(
        levelNumber: i,
        title: 'Beginner $i',
        description: 'Beginner level - learning the basics',
        requiredXp: requiredXp,
        rewardCoins: 50 + (i * 10),
        rewardXp: 25 + (i * 5),
        tier: LevelTier.beginner,
        emoji: '🌱',
        rewardBadgeId: i == 10 ? 'beginner_master' : null,
      ));
    }

    // レベル11-25: 中級者
    for (int i = 11; i <= 25; i++) {
      final requiredXp = _calculateLevelXp(i);
      levels.add(Level(
        levelNumber: i,
        title: 'Intermediate ${i - 10}',
        description: 'Intermediate level - improving your skills',
        requiredXp: requiredXp,
        rewardCoins: 100 + ((i - 10) * 15),
        rewardXp: 50 + ((i - 10) * 10),
        tier: LevelTier.intermediate,
        emoji: '🌿',
        rewardBadgeId: i == 25 ? 'intermediate_master' : null,
      ));
    }

    // レベル26-40: 上級者
    for (int i = 26; i <= 40; i++) {
      final requiredXp = _calculateLevelXp(i);
      levels.add(Level(
        levelNumber: i,
        title: 'Advanced ${i - 25}',
        description: 'Advanced level - mastering complex concepts',
        requiredXp: requiredXp,
        rewardCoins: 200 + ((i - 25) * 20),
        rewardXp: 100 + ((i - 25) * 15),
        tier: LevelTier.advanced,
        emoji: '🌳',
        rewardBadgeId: i == 40 ? 'advanced_master' : null,
      ));
    }

    // レベル41-50: エキスパート
    for (int i = 41; i <= 50; i++) {
      final requiredXp = _calculateLevelXp(i);
      levels.add(Level(
        levelNumber: i,
        title: 'Expert ${i - 40}',
        description: 'Expert level - you are a programming master',
        requiredXp: requiredXp,
        rewardCoins: 500 + ((i - 40) * 50),
        rewardXp: 250 + ((i - 40) * 25),
        tier: LevelTier.expert,
        emoji: '🏆',
        rewardBadgeId: i == 50 ? 'ultimate_master' : null,
      ));
    }

    return levels;
  }

  static int _calculateLevelXp(int levelNumber) {
    // 指数関数的成長: 各レベルは1.15倍のXPが必要
    // レベル1: 100XP, レベル2: 115XP, ..., レベル50: ~50,000 XP
    const baseXp = 100;
    return (baseXp * (1.15 ^ (levelNumber - 1))).toInt();
  }

  /// デフォルトレベルを取得
  static final List<Level> allLevels = generateLevels();

  /// レベル番号からレベルを取得
  static Level? getLevelByNumber(int levelNumber) {
    try {
      return allLevels.firstWhere((level) => level.levelNumber == levelNumber);
    } catch (e) {
      return null;
    }
  }

  /// 累積XPから現在のレベルを取得
  static int getLevelFromTotalXp(int totalXp) {
    for (int i = allLevels.length - 1; i >= 0; i--) {
      if (totalXp >= allLevels[i].requiredXp) {
        return allLevels[i].levelNumber;
      }
    }
    return 1;
  }
}
