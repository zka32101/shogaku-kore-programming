/// Achievement unlock conditions and progress tracking
enum AchievementType {
  streak,           // Login streak based
  xp,               // Experience points based
  challenge,        // Challenge completion based
  social,           // Social interaction based
  milestone,        // Milestone achievement
  skill,            // Skill mastery based
  participation,    // Event participation based
  exploration,      // Discovery based
}

/// Achievement rarity and visual weight
enum AchievementRarity {
  common,     // Common (gray)
  uncommon,   // Uncommon (green)
  rare,       // Rare (blue)
  epic,       // Epic (purple)
  legendary,  // Legendary (gold)
}

/// Achievement unlock condition
class UnlockCondition {
  final String conditionId;
  final String description;
  final int targetValue;          // Target value to reach
  final String metricKey;         // What metric to track
  final String? operator;         // 'equal', 'greater_than', 'less_than', 'between'
  final int? maxValue;            // For 'between' operator

  UnlockCondition({
    required this.conditionId,
    required this.description,
    required this.targetValue,
    required this.metricKey,
    this.operator = 'greater_than',
    this.maxValue,
  });

  Map<String, dynamic> toJson() => {
        'conditionId': conditionId,
        'description': description,
        'targetValue': targetValue,
        'metricKey': metricKey,
        'operator': operator,
        'maxValue': maxValue,
      };

  factory UnlockCondition.fromJson(Map<String, dynamic> json) =>
      UnlockCondition(
        conditionId: json['conditionId'] as String,
        description: json['description'] as String,
        targetValue: json['targetValue'] as int,
        metricKey: json['metricKey'] as String,
        operator: json['operator'] as String?,
        maxValue: json['maxValue'] as int?,
      );
}

/// Achievement definition with unlock conditions
class Achievement {
  final String achievementId;
  final String name;                    // Achievement name (Japanese)
  final String description;             // Achievement description
  final AchievementType type;
  final AchievementRarity rarity;
  final String iconId;                  // Icon/badge identifier
  final int xpReward;                   // XP granted on unlock
  final int coinReward;                 // Coins granted on unlock
  final List<UnlockCondition> conditions;  // All conditions must be met
  final bool isSelfLocking;             // Can only be unlocked once
  final bool isSecret;                  // Hidden until unlocked

  Achievement({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.iconId,
    required this.xpReward,
    required this.coinReward,
    required this.conditions,
    this.isSelfLocking = true,
    this.isSecret = false,
  });

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'name': name,
        'description': description,
        'type': type.name,
        'rarity': rarity.name,
        'iconId': iconId,
        'xpReward': xpReward,
        'coinReward': coinReward,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'isSelfLocking': isSelfLocking,
        'isSecret': isSecret,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        achievementId: json['achievementId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: AchievementType.values.byName(json['type'] as String),
        rarity: AchievementRarity.values.byName(json['rarity'] as String),
        iconId: json['iconId'] as String,
        xpReward: json['xpReward'] as int,
        coinReward: json['coinReward'] as int,
        conditions: ((json['conditions'] as List?) ?? [])
            .map((c) => UnlockCondition.fromJson(c as Map<String, dynamic>))
            .toList(),
        isSelfLocking: json['isSelfLocking'] as bool? ?? true,
        isSecret: json['isSecret'] as bool? ?? false,
      );
}

/// User's achievement unlock record
class UserAchievement {
  final String achievementId;
  final String userId;
  final DateTime unlockedAt;
  final int currentProgress;           // Current progress towards unlock
  final bool isLocked;                  // Still locked or already unlocked
  final String? notificationSentAt;    // Timestamp of unlock notification

  UserAchievement({
    required this.achievementId,
    required this.userId,
    required this.unlockedAt,
    this.currentProgress = 0,
    this.isLocked = true,
    this.notificationSentAt,
  });

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'userId': userId,
        'unlockedAt': unlockedAt.toIso8601String(),
        'currentProgress': currentProgress,
        'isLocked': isLocked,
        'notificationSentAt': notificationSentAt,
      };

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      UserAchievement(
        achievementId: json['achievementId'] as String,
        userId: json['userId'] as String,
        unlockedAt: DateTime.parse(json['unlockedAt'] as String),
        currentProgress: json['currentProgress'] as int? ?? 0,
        isLocked: json['isLocked'] as bool? ?? true,
        notificationSentAt: json['notificationSentAt'] as String?,
      );
}

/// Achievement progress tracking
class AchievementProgress {
  final String achievementId;
  final int currentProgress;           // Current progress value
  final int targetProgress;            // Target value to reach
  final double progressPercentage;     // Calculated percentage (0-100)
  final bool isUnlocked;               // Unlocked or not
  final DateTime? unlockedDate;        // When it was unlocked

  AchievementProgress({
    required this.achievementId,
    required this.currentProgress,
    required this.targetProgress,
    required this.isUnlocked,
    this.unlockedDate,
  }) : progressPercentage = targetProgress > 0
            ? (currentProgress / targetProgress * 100).clamp(0, 100)
            : 0;

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'currentProgress': currentProgress,
        'targetProgress': targetProgress,
        'progressPercentage': progressPercentage,
        'isUnlocked': isUnlocked,
        'unlockedDate': unlockedDate?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        achievementId: json['achievementId'] as String,
        currentProgress: json['currentProgress'] as int,
        targetProgress: json['targetProgress'] as int,
        isUnlocked: json['isUnlocked'] as bool,
        unlockedDate: json['unlockedDate'] != null
            ? DateTime.parse(json['unlockedDate'] as String)
            : null,
      );
}

/// Achievement statistics and collection data
class AchievementStats {
  final String userId;
  final int totalAchievements;         // Total achievements in system
  final int unlockedCount;             // How many unlocked
  final int totalXpFromAchievements;   // Total XP earned from achievements
  final int totalCoinsFromAchievements; // Total coins earned
  final List<UserAchievement> unlockedAchievements;  // Max 50
  final DateTime lastUpdatedAt;

  AchievementStats({
    required this.userId,
    required this.totalAchievements,
    required this.unlockedCount,
    required this.totalXpFromAchievements,
    required this.totalCoinsFromAchievements,
    required this.unlockedAchievements,
    required this.lastUpdatedAt,
  });

  /// Calculate unlock percentage (0-100)
  double get unlockedPercentage =>
      totalAchievements > 0 ? (unlockedCount / totalAchievements * 100) : 0;

  /// Get next achievement to unlock (hint for user)
  UserAchievement? get nextToUnlock =>
      unlockedAchievements.isEmpty ? null : unlockedAchievements.first;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalAchievements': totalAchievements,
        'unlockedCount': unlockedCount,
        'totalXpFromAchievements': totalXpFromAchievements,
        'totalCoinsFromAchievements': totalCoinsFromAchievements,
        'unlockedAchievements':
            unlockedAchievements.map((a) => a.toJson()).toList(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory AchievementStats.fromJson(Map<String, dynamic> json) =>
      AchievementStats(
        userId: json['userId'] as String,
        totalAchievements: json['totalAchievements'] as int,
        unlockedCount: json['unlockedCount'] as int,
        totalXpFromAchievements: json['totalXpFromAchievements'] as int,
        totalCoinsFromAchievements: json['totalCoinsFromAchievements'] as int,
        unlockedAchievements: ((json['unlockedAchievements'] as List?) ?? [])
            .map((a) => UserAchievement.fromJson(a as Map<String, dynamic>))
            .toList(),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Achievement collection with progress data
class AchievementCollection {
  final List<Achievement> allAchievements;  // All available achievements
  final AchievementStats stats;            // User's achievement stats
  final DateTime generatedAt;

  AchievementCollection({
    required this.allAchievements,
    required this.stats,
    required this.generatedAt,
  });

  /// Get achievement by ID
  Achievement? getAchievement(String id) =>
      allAchievements.firstWhere(
        (a) => a.achievementId == id,
        orElse: () => throw Exception('Achievement not found: $id'),
      );

  /// Get progress for specific achievement
  AchievementProgress? getProgress(String achievementId) {
    try {
      final achievement = getAchievement(achievementId);
      if (achievement == null) return null;

      final userAchievement = stats.unlockedAchievements
          .firstWhere((a) => a.achievementId == achievementId);

      return AchievementProgress(
        achievementId: achievementId,
        currentProgress: userAchievement.currentProgress,
        targetProgress: achievement.conditions.isNotEmpty
            ? achievement.conditions.first.targetValue
            : 0,
        isUnlocked: !userAchievement.isLocked,
        unlockedDate: !userAchievement.isLocked ? userAchievement.unlockedAt : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get achievements by type
  List<Achievement> getByType(AchievementType type) =>
      allAchievements.where((a) => a.type == type).toList();

  /// Get achievements by rarity
  List<Achievement> getByRarity(AchievementRarity rarity) =>
      allAchievements.where((a) => a.rarity == rarity).toList();

  /// Get locked achievements (not yet unlocked)
  List<Achievement> getLockedAchievements() {
    final unlockedIds = stats.unlockedAchievements.map((a) => a.achievementId).toSet();
    return allAchievements.where((a) => !unlockedIds.contains(a.achievementId)).toList();
  }

  Map<String, dynamic> toJson() => {
        'allAchievements': allAchievements.map((a) => a.toJson()).toList(),
        'stats': stats.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory AchievementCollection.fromJson(Map<String, dynamic> json) =>
      AchievementCollection(
        allAchievements: ((json['allAchievements'] as List?) ?? [])
            .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
            .toList(),
        stats: AchievementStats.fromJson(
            json['stats'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
