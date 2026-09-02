/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy,      // Beginner friendly
  normal,    // Standard difficulty
  hard,      // Challenging
  expert,    // Very difficult
}

/// Challenge category/type
enum ChallengeCategory {
  learning,      // Learning-focused
  practice,      // Practice sessions
  reading,       // Reading comprehension
  writing,       // Writing exercises
  speaking,      // Speaking/pronunciation
  listening,     // Listening comprehension
  quiz,          // Quiz/assessment
  creative,      // Creative tasks
}

/// Reward tier based on completion
enum ChallengeRewardTier {
  bronze,    // Partial completion (30-69%)
  silver,    // Good completion (70-89%)
  gold,      // Excellent completion (90-99%)
  platinum,  // Perfect completion (100%)
}

/// Individual weekly challenge
class WeeklyChallenge {
  final String challengeId;
  final String title;               // Challenge title (Japanese)
  final String description;         // Challenge description
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final String iconId;              // Icon/badge identifier
  final int targetValue;            // Goal to achieve
  final String metricKey;           // Metric being tracked
  final int baseBonusXp;            // Base XP for completion
  final int baseBonusCoins;         // Base coins for completion
  final DateTime weekStartDate;     // When this week starts
  final DateTime weekEndDate;       // When this week ends
  final int maxAttempts;            // How many attempts allowed (-1 = unlimited)
  final String? prerequisiteId;     // Must complete this challenge first
  final bool isStreakBooster;       // Counts toward weekly streak
  final bool isBonusChallenge;      // Secret/bonus challenge

  WeeklyChallenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.iconId,
    required this.targetValue,
    required this.metricKey,
    required this.baseBonusXp,
    required this.baseBonusCoins,
    required this.weekStartDate,
    required this.weekEndDate,
    this.maxAttempts = -1,
    this.prerequisiteId,
    this.isStreakBooster = false,
    this.isBonusChallenge = false,
  });

  /// Calculate reward multiplier based on difficulty
  double get difficultyMultiplier {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 1.0;
      case ChallengeDifficulty.normal:
        return 1.5;
      case ChallengeDifficulty.hard:
        return 2.0;
      case ChallengeDifficulty.expert:
        return 3.0;
    }
  }

  /// Check if challenge is still active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(weekStartDate) && now.isBefore(weekEndDate);
  }

  /// Days remaining in week
  int get daysRemaining {
    final now = DateTime.now();
    if (!isActive) return 0;
    return weekEndDate.difference(now).inDays + 1;
  }

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'title': title,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name,
        'iconId': iconId,
        'targetValue': targetValue,
        'metricKey': metricKey,
        'baseBonusXp': baseBonusXp,
        'baseBonusCoins': baseBonusCoins,
        'weekStartDate': weekStartDate.toIso8601String(),
        'weekEndDate': weekEndDate.toIso8601String(),
        'maxAttempts': maxAttempts,
        'prerequisiteId': prerequisiteId,
        'isStreakBooster': isStreakBooster,
        'isBonusChallenge': isBonusChallenge,
      };

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) =>
      WeeklyChallenge(
        challengeId: json['challengeId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: ChallengeCategory.values.byName(json['category'] as String),
        difficulty: ChallengeDifficulty.values.byName(json['difficulty'] as String),
        iconId: json['iconId'] as String,
        targetValue: json['targetValue'] as int,
        metricKey: json['metricKey'] as String,
        baseBonusXp: json['baseBonusXp'] as int,
        baseBonusCoins: json['baseBonusCoins'] as int,
        weekStartDate: DateTime.parse(json['weekStartDate'] as String),
        weekEndDate: DateTime.parse(json['weekEndDate'] as String),
        maxAttempts: json['maxAttempts'] as int? ?? -1,
        prerequisiteId: json['prerequisiteId'] as String?,
        isStreakBooster: json['isStreakBooster'] as bool? ?? false,
        isBonusChallenge: json['isBonusChallenge'] as bool? ?? false,
      );
}

/// User's progress on a challenge
class ChallengeProgress {
  final String challengeId;
  final String userId;
  final int currentValue;           // Current progress
  final int targetValue;            // Target to achieve
  final int attemptCount;           // Number of attempts made
  final DateTime startedAt;         // When user started
  final DateTime? completedAt;      // When user completed (if completed)
  final bool isCompleted;           // Is challenge completed
  final ChallengeRewardTier? tier;  // Reward tier achieved

  ChallengeProgress({
    required this.challengeId,
    required this.userId,
    required this.currentValue,
    required this.targetValue,
    this.attemptCount = 0,
    required this.startedAt,
    this.completedAt,
    required this.isCompleted,
    this.tier,
  });

  /// Calculate progress percentage (0-100)
  double get progressPercentage =>
      (currentValue / targetValue * 100).clamp(0, 100);

  /// Get reward tier based on current progress
  ChallengeRewardTier getTierForProgress() {
    final percentage = progressPercentage;
    if (percentage >= 100) return ChallengeRewardTier.platinum;
    if (percentage >= 90) return ChallengeRewardTier.gold;
    if (percentage >= 70) return ChallengeRewardTier.silver;
    return ChallengeRewardTier.bronze;
  }

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'userId': userId,
        'currentValue': currentValue,
        'targetValue': targetValue,
        'attemptCount': attemptCount,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isCompleted': isCompleted,
        'tier': tier?.name,
      };

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) =>
      ChallengeProgress(
        challengeId: json['challengeId'] as String,
        userId: json['userId'] as String,
        currentValue: json['currentValue'] as int,
        targetValue: json['targetValue'] as int,
        attemptCount: json['attemptCount'] as int? ?? 0,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool,
        tier: json['tier'] != null
            ? ChallengeRewardTier.values.byName(json['tier'] as String)
            : null,
      );
}

/// Challenge completion reward
class ChallengeReward {
  final String rewardId;
  final String userId;
  final String challengeId;
  final int xpEarned;
  final int coinsEarned;
  final DateTime claimedAt;
  final ChallengeRewardTier tier;
  final double difficultyMultiplier;

  ChallengeReward({
    required this.rewardId,
    required this.userId,
    required this.challengeId,
    required this.xpEarned,
    required this.coinsEarned,
    required this.claimedAt,
    required this.tier,
    required this.difficultyMultiplier,
  });

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'userId': userId,
        'challengeId': challengeId,
        'xpEarned': xpEarned,
        'coinsEarned': coinsEarned,
        'claimedAt': claimedAt.toIso8601String(),
        'tier': tier.name,
        'difficultyMultiplier': difficultyMultiplier,
      };

  factory ChallengeReward.fromJson(Map<String, dynamic> json) =>
      ChallengeReward(
        rewardId: json['rewardId'] as String,
        userId: json['userId'] as String,
        challengeId: json['challengeId'] as String,
        xpEarned: json['xpEarned'] as int,
        coinsEarned: json['coinsEarned'] as int,
        claimedAt: DateTime.parse(json['claimedAt'] as String),
        tier: ChallengeRewardTier.values.byName(json['tier'] as String),
        difficultyMultiplier: (json['difficultyMultiplier'] as num).toDouble(),
      );
}

/// Weekly challenge statistics
class WeeklyChallengeStats {
  final String userId;
  final int totalChallengesThisWeek;      // Total challenges available this week
  final int completedChallenges;         // How many user completed
  final int totalXpEarned;               // Total XP from challenges this week
  final int totalCoinsEarned;            // Total coins from challenges
  final List<ChallengeReward> rewardHistory;  // Recent rewards (max 50)
  final int weeklyStreak;                // Consecutive weeks with completion
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final DateTime lastUpdatedAt;

  WeeklyChallengeStats({
    required this.userId,
    required this.totalChallengesThisWeek,
    required this.completedChallenges,
    required this.totalXpEarned,
    required this.totalCoinsEarned,
    required this.rewardHistory,
    required this.weeklyStreak,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.lastUpdatedAt,
  });

  /// Calculate completion percentage
  double get completionPercentage => totalChallengesThisWeek > 0
      ? (completedChallenges / totalChallengesThisWeek * 100)
      : 0;

  /// Check if all challenges completed
  bool get allCompleted => completedChallenges == totalChallengesThisWeek;

  /// Days remaining in week
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(weekEndDate)) return 0;
    return weekEndDate.difference(now).inDays + 1;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalChallengesThisWeek': totalChallengesThisWeek,
        'completedChallenges': completedChallenges,
        'totalXpEarned': totalXpEarned,
        'totalCoinsEarned': totalCoinsEarned,
        'rewardHistory': rewardHistory.map((r) => r.toJson()).toList(),
        'weeklyStreak': weeklyStreak,
        'weekStartDate': weekStartDate.toIso8601String(),
        'weekEndDate': weekEndDate.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory WeeklyChallengeStats.fromJson(Map<String, dynamic> json) =>
      WeeklyChallengeStats(
        userId: json['userId'] as String,
        totalChallengesThisWeek: json['totalChallengesThisWeek'] as int,
        completedChallenges: json['completedChallenges'] as int,
        totalXpEarned: json['totalXpEarned'] as int,
        totalCoinsEarned: json['totalCoinsEarned'] as int,
        rewardHistory: ((json['rewardHistory'] as List?) ?? [])
            .map((r) => ChallengeReward.fromJson(r as Map<String, dynamic>))
            .toList(),
        weeklyStreak: json['weeklyStreak'] as int? ?? 0,
        weekStartDate: DateTime.parse(json['weekStartDate'] as String),
        weekEndDate: DateTime.parse(json['weekEndDate'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete weekly challenge collection
class WeeklyChallengeCollection {
  final List<WeeklyChallenge> challenges;  // All challenges this week
  final WeeklyChallengeStats stats;
  final Map<String, ChallengeProgress> userProgress;  // By challengeId
  final DateTime generatedAt;

  WeeklyChallengeCollection({
    required this.challenges,
    required this.stats,
    required this.userProgress,
    required this.generatedAt,
  });

  /// Get challenge by ID
  WeeklyChallenge? getChallenge(String id) =>
      challenges.firstWhere(
        (c) => c.challengeId == id,
        orElse: () => throw Exception('Challenge not found: $id'),
      );

  /// Get progress for challenge
  ChallengeProgress? getProgress(String challengeId) =>
      userProgress[challengeId];

  /// Get challenges by category
  List<WeeklyChallenge> getByCategory(ChallengeCategory category) =>
      challenges.where((c) => c.category == category).toList();

  /// Get challenges by difficulty
  List<WeeklyChallenge> getByDifficulty(ChallengeDifficulty difficulty) =>
      challenges.where((c) => c.difficulty == difficulty).toList();

  /// Get active challenges (not yet completed)
  List<WeeklyChallenge> getActiveChallenges() =>
      challenges.where((c) => getProgress(c.challengeId)?.isCompleted != true).toList();

  /// Get completed challenges
  List<WeeklyChallenge> getCompletedChallenges() =>
      challenges.where((c) => getProgress(c.challengeId)?.isCompleted == true).toList();

  /// Get bonus challenges
  List<WeeklyChallenge> getBonusChallenges() =>
      challenges.where((c) => c.isBonusChallenge).toList();

  Map<String, dynamic> toJson() => {
        'challenges': challenges.map((c) => c.toJson()).toList(),
        'stats': stats.toJson(),
        'userProgress': userProgress.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory WeeklyChallengeCollection.fromJson(Map<String, dynamic> json) =>
      WeeklyChallengeCollection(
        challenges: ((json['challenges'] as List?) ?? [])
            .map((c) => WeeklyChallenge.fromJson(c as Map<String, dynamic>))
            .toList(),
        stats: WeeklyChallengeStats.fromJson(
            json['stats'] as Map<String, dynamic>),
        userProgress: ((json['userProgress'] as Map?) ?? {})
            .cast<String, Map<String, dynamic>>()
            .map((key, value) => MapEntry(
              key,
              ChallengeProgress.fromJson(value),
            )),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
