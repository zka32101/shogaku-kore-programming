/// Challenge difficulty level
enum ChallengeDifficulty {
  easy,      // Basic challenge
  normal,    // Standard challenge
  hard,      // Difficult challenge
  expert,    // Very difficult
  insane,    // Extreme difficulty
}

/// Challenge category
enum ChallengeCategory {
  reading,        // Reading comprehension
  writing,        // Writing practice
  mathematics,    // Math problems
  vocabulary,     // Vocabulary/language
  listening,      // Listening comprehension
  speaking,       // Speaking practice
  grammar,        // Grammar exercises
  culture,        // Cultural knowledge
  puzzle,         // Logic puzzles
  creative,       // Creative challenges
}

/// Challenge reward currency type
enum RewardCurrency {
  xp,            // Experience points
  coins,         // In-game currency
  premium,       // Premium currency
}

/// Challenge frequency
enum ChallengeFrequency {
  daily,         // Resets daily
  weekly,        // Resets weekly
  seasonal,      // Seasonal challenge
  oneTime,       // One-time only
}

/// Challenge status for user
enum ChallengeStatus {
  available,     // Can be started
  inProgress,    // Currently working on it
  completed,     // Completed
  expired,       // Time limit exceeded
}

/// Reward information
class ChallengeReward {
  final RewardCurrency currency;
  final int amount;
  final int? bonusAmount;      // Bonus if completed early
  final Map<String, dynamic>? additionalRewards; // Items, badges, etc.

  ChallengeReward({
    required this.currency,
    required this.amount,
    this.bonusAmount,
    this.additionalRewards,
  });

  int getTotalReward({bool includeBonus = false}) {
    if (includeBonus && bonusAmount != null) {
      return amount + bonusAmount!;
    }
    return amount;
  }

  Map<String, dynamic> toJson() => {
        'currency': currency.name,
        'amount': amount,
        'bonusAmount': bonusAmount,
        'additionalRewards': additionalRewards,
      };

  factory ChallengeReward.fromJson(Map<String, dynamic> json) => ChallengeReward(
        currency: RewardCurrency.values.byName(json['currency'] as String),
        amount: json['amount'] as int,
        bonusAmount: json['bonusAmount'] as int?,
        additionalRewards: json['additionalRewards'] as Map<String, dynamic>?,
      );
}

/// Individual challenge/quest
class Challenge {
  final String challengeId;
  final String title;           // Challenge title (Japanese)
  final String description;     // Challenge description
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final ChallengeFrequency frequency;
  final int targetCount;        // Number of tasks to complete
  final int? timeLimit;         // Time limit in minutes
  final ChallengeReward reward;
  final String? imageId;        // Challenge icon/image
  final Map<String, dynamic>? data; // Additional challenge data
  final DateTime createdAt;
  final DateTime startsAt;      // When challenge becomes available
  final DateTime? endsAt;       // When challenge expires
  final int totalCompletions;   // Total times completed by user
  final int difficulty_multiplier; // Reward multiplier based on difficulty

  Challenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.frequency,
    required this.targetCount,
    this.timeLimit,
    required this.reward,
    this.imageId,
    this.data,
    required this.createdAt,
    required this.startsAt,
    this.endsAt,
    this.totalCompletions = 0,
    this.difficulty_multiplier = 1,
  });

  /// Check if challenge is available now
  bool get isAvailable {
    final now = DateTime.now();
    return now.isAfter(startsAt) && (endsAt == null || now.isBefore(endsAt!));
  }

  /// Check if challenge has expired
  bool get isExpired => endsAt != null && DateTime.now().isAfter(endsAt!);

  /// Get time remaining in minutes
  int? get timeRemaining {
    if (endsAt == null) return null;
    return DateTime.now().difference(endsAt!).inMinutes.abs();
  }

  /// Check if challenge is expiring soon (within 1 hour)
  bool get isExpiringSoon {
    if (endsAt == null) return false;
    final now = DateTime.now();
    final oneHourFromNow = now.add(const Duration(hours: 1));
    return endsAt!.isBefore(oneHourFromNow) && endsAt!.isAfter(now);
  }

  /// Get formatted difficulty text
  String get difficultyText {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return '簡単';
      case ChallengeDifficulty.normal:
        return '普通';
      case ChallengeDifficulty.hard:
        return '難しい';
      case ChallengeDifficulty.expert:
        return '非常に難しい';
      case ChallengeDifficulty.insane:
        return '極難';
    }
  }

  /// Calculate adjusted reward based on difficulty
  int getAdjustedReward() {
    return (reward.amount * difficulty_multiplier).toInt();
  }

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'title': title,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name,
        'frequency': frequency.name,
        'targetCount': targetCount,
        'timeLimit': timeLimit,
        'reward': reward.toJson(),
        'imageId': imageId,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt?.toIso8601String(),
        'totalCompletions': totalCompletions,
        'difficulty_multiplier': difficulty_multiplier,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        challengeId: json['challengeId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: ChallengeCategory.values.byName(json['category'] as String),
        difficulty: ChallengeDifficulty.values.byName(json['difficulty'] as String),
        frequency: ChallengeFrequency.values.byName(json['frequency'] as String),
        targetCount: json['targetCount'] as int,
        timeLimit: json['timeLimit'] as int?,
        reward: ChallengeReward.fromJson(json['reward'] as Map<String, dynamic>),
        imageId: json['imageId'] as String?,
        data: json['data'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: json['endsAt'] != null ? DateTime.parse(json['endsAt'] as String) : null,
        totalCompletions: json['totalCompletions'] as int? ?? 0,
        difficulty_multiplier: json['difficulty_multiplier'] as int? ?? 1,
      );
}

/// User's challenge progress
class ChallengeProgress {
  final String challengeId;
  final String userId;
  final int currentProgress;    // Current completion count
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime startedAt;
  final DateTime? firstAttemptAt;
  final int attemptCount;
  final bool claimedReward;

  ChallengeProgress({
    required this.challengeId,
    required this.userId,
    required this.currentProgress,
    this.isCompleted = false,
    this.completedAt,
    required this.startedAt,
    this.firstAttemptAt,
    this.attemptCount = 0,
    this.claimedReward = false,
  });

  /// Calculate progress percentage
  double getProgressPercentage(int targetCount) {
    if (targetCount == 0) return 0;
    return (currentProgress / targetCount * 100).clamp(0, 100);
  }

  /// Check if challenge was completed early
  bool get completedEarly => completedAt != null && firstAttemptAt != null &&
      completedAt!.difference(firstAttemptAt!).inMinutes < 30;

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'userId': userId,
        'currentProgress': currentProgress,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'startedAt': startedAt.toIso8601String(),
        'firstAttemptAt': firstAttemptAt?.toIso8601String(),
        'attemptCount': attemptCount,
        'claimedReward': claimedReward,
      };

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) => ChallengeProgress(
        challengeId: json['challengeId'] as String,
        userId: json['userId'] as String,
        currentProgress: json['currentProgress'] as int,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        startedAt: DateTime.parse(json['startedAt'] as String),
        firstAttemptAt: json['firstAttemptAt'] != null ? DateTime.parse(json['firstAttemptAt'] as String) : null,
        attemptCount: json['attemptCount'] as int? ?? 0,
        claimedReward: json['claimedReward'] as bool? ?? false,
      );
}

/// Challenge completion record
class ChallengeCompletion {
  final String completionId;
  final String challengeId;
  final String userId;
  final int rewardEarned;
  final bool bonusRewardEarned;
  final DateTime completedAt;
  final int? timeSpentMinutes;

  ChallengeCompletion({
    required this.completionId,
    required this.challengeId,
    required this.userId,
    required this.rewardEarned,
    this.bonusRewardEarned = false,
    required this.completedAt,
    this.timeSpentMinutes,
  });

  Map<String, dynamic> toJson() => {
        'completionId': completionId,
        'challengeId': challengeId,
        'userId': userId,
        'rewardEarned': rewardEarned,
        'bonusRewardEarned': bonusRewardEarned,
        'completedAt': completedAt.toIso8601String(),
        'timeSpentMinutes': timeSpentMinutes,
      };

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) => ChallengeCompletion(
        completionId: json['completionId'] as String,
        challengeId: json['challengeId'] as String,
        userId: json['userId'] as String,
        rewardEarned: json['rewardEarned'] as int,
        bonusRewardEarned: json['bonusRewardEarned'] as bool? ?? false,
        completedAt: DateTime.parse(json['completedAt'] as String),
        timeSpentMinutes: json['timeSpentMinutes'] as int?,
      );
}

/// User's challenge collection
class UserChallenges {
  final String userId;
  final List<Challenge> availableChallenges;        // Max 50
  final Map<String, ChallengeProgress> progress;   // challengeId -> progress
  final List<ChallengeCompletion> completionHistory; // Max 200
  final DateTime lastUpdatedAt;
  final DateTime generatedAt;

  UserChallenges({
    required this.userId,
    required this.availableChallenges,
    required this.progress,
    required this.completionHistory,
    required this.lastUpdatedAt,
    required this.generatedAt,
  });

  /// Get available challenges for user
  List<Challenge> getAvailableChallenges() =>
      availableChallenges.where((c) => c.isAvailable).toList();

  /// Get in-progress challenges
  List<Challenge> getInProgressChallenges() => availableChallenges.where((c) {
        final p = progress[c.challengeId];
        return p != null && !p.isCompleted && c.isAvailable;
      }).toList();

  /// Get completed challenges
  List<Challenge> getCompletedChallenges() => availableChallenges.where((c) {
        final p = progress[c.challengeId];
        return p != null && p.isCompleted;
      }).toList();

  /// Get challenges by category
  List<Challenge> getChallengesByCategory(ChallengeCategory category) =>
      availableChallenges.where((c) => c.category == category).toList();

  /// Get challenges by difficulty
  List<Challenge> getChallengesByDifficulty(ChallengeDifficulty difficulty) =>
      availableChallenges.where((c) => c.difficulty == difficulty).toList();

  /// Get daily challenges
  List<Challenge> getDailyChallenges() =>
      availableChallenges.where((c) => c.frequency == ChallengeFrequency.daily).toList();

  /// Get weekly challenges
  List<Challenge> getWeeklyChallenges() =>
      availableChallenges.where((c) => c.frequency == ChallengeFrequency.weekly).toList();

  /// Get expiring soon challenges (within 1 hour)
  List<Challenge> getExpiringChallenges() =>
      availableChallenges.where((c) => c.isExpiringSoon).toList();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'availableChallenges': availableChallenges.map((c) => c.toJson()).toList(),
        'progress': progress.map((k, v) => MapEntry(k, v.toJson())),
        'completionHistory': completionHistory.map((c) => c.toJson()).toList(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory UserChallenges.fromJson(Map<String, dynamic> json) => UserChallenges(
        userId: json['userId'] as String,
        availableChallenges: ((json['availableChallenges'] as List?) ?? [])
            .map((c) => Challenge.fromJson(c as Map<String, dynamic>))
            .toList(),
        progress: ((json['progress'] as Map<String, dynamic>?) ?? {}).map(
          (k, v) => MapEntry(k, ChallengeProgress.fromJson(v as Map<String, dynamic>)),
        ),
        completionHistory: ((json['completionHistory'] as List?) ?? [])
            .map((c) => ChallengeCompletion.fromJson(c as Map<String, dynamic>))
            .toList(),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}

/// Challenge statistics
class ChallengeStats {
  final String userId;
  final int totalChallengesAvailable;
  final int totalChallengesCompleted;
  final int totalRewardsEarned;
  final int totalBonusesEarned;
  final int currentStreak;           // Consecutive days of challenge completion
  final int longestStreak;
  final Map<ChallengeCategory, int> completionsByCategory;
  final Map<ChallengeDifficulty, int> completionsByDifficulty;
  final DateTime lastCompletionAt;
  final DateTime lastUpdatedAt;

  ChallengeStats({
    required this.userId,
    required this.totalChallengesAvailable,
    required this.totalChallengesCompleted,
    required this.totalRewardsEarned,
    required this.totalBonusesEarned,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionsByCategory,
    required this.completionsByDifficulty,
    required this.lastCompletionAt,
    required this.lastUpdatedAt,
  });

  /// Get completion rate percentage
  double get completionRate {
    if (totalChallengesAvailable == 0) return 0;
    return (totalChallengesCompleted / totalChallengesAvailable * 100);
  }

  /// Get average reward per challenge
  int get averageReward {
    if (totalChallengesCompleted == 0) return 0;
    return (totalRewardsEarned / totalChallengesCompleted).round();
  }

  /// Get bonus earned percentage
  double get bonusPercentage {
    if (totalChallengesCompleted == 0) return 0;
    return (totalBonusesEarned / totalChallengesCompleted * 100);
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalChallengesAvailable': totalChallengesAvailable,
        'totalChallengesCompleted': totalChallengesCompleted,
        'totalRewardsEarned': totalRewardsEarned,
        'totalBonusesEarned': totalBonusesEarned,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'completionsByCategory': completionsByCategory.map((k, v) => MapEntry(k.name, v)),
        'completionsByDifficulty': completionsByDifficulty.map((k, v) => MapEntry(k.name, v)),
        'lastCompletionAt': lastCompletionAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory ChallengeStats.fromJson(Map<String, dynamic> json) {
    final categoryMap = (json['completionsByCategory'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(ChallengeCategory.values.byName(k), v as int));
    final difficultyMap = (json['completionsByDifficulty'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(ChallengeDifficulty.values.byName(k), v as int));

    return ChallengeStats(
      userId: json['userId'] as String,
      totalChallengesAvailable: json['totalChallengesAvailable'] as int,
      totalChallengesCompleted: json['totalChallengesCompleted'] as int,
      totalRewardsEarned: json['totalRewardsEarned'] as int,
      totalBonusesEarned: json['totalBonusesEarned'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      completionsByCategory: categoryMap,
      completionsByDifficulty: difficultyMap,
      lastCompletionAt: DateTime.parse(json['lastCompletionAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }
}

/// Complete challenge collection
class ChallengeCollection {
  final String userId;
  final UserChallenges challenges;
  final ChallengeStats stats;
  final DateTime generatedAt;

  ChallengeCollection({
    required this.userId,
    required this.challenges,
    required this.stats,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'challenges': challenges.toJson(),
        'stats': stats.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ChallengeCollection.fromJson(Map<String, dynamic> json) =>
      ChallengeCollection(
        userId: json['userId'] as String,
        challenges: UserChallenges.fromJson(json['challenges'] as Map<String, dynamic>),
        stats: ChallengeStats.fromJson(json['stats'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
