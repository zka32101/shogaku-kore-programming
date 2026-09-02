/// Activity type
enum ActivityType {
  quickGame,          // Quick 1-3 minute games
  dailyChallenge,     // Daily challenges
  puzzleGame,         // Puzzle/logic games
  speedGame,          // Timed speed games
  memoryGame,         // Memory/matching games
  wordGame,           // Word games
  mathGame,           // Math/calculation games
  trivia,             // Trivia questions
}

/// Activity difficulty
enum ActivityDifficulty {
  easy,               // Easy difficulty
  normal,             // Normal difficulty
  hard,               // Hard difficulty
  expert,             // Expert/extreme difficulty
}

/// Activity status
enum ActivityStatus {
  available,          // Available to play
  locked,             // Locked (requires level/progression)
  completed,          // Completed today
  archived,           // No longer available
}

/// Mini-game/Activity definition
class Activity {
  final String activityId;
  final String name;                  // Activity name (Japanese)
  final String description;
  final ActivityType type;
  final ActivityDifficulty difficulty;
  final int requiredLevel;            // Minimum level to unlock
  final int timeLimit;                // Seconds (0 = no limit)
  final int maxAttempts;              // Max plays per day (0 = unlimited)
  final int baseCoins;                // Base coin reward
  final int baseXp;                   // Base XP reward
  final int? premiumCoinReward;       // Bonus premium coin
  final double coinMultiplier;        // Multiplier for rewards
  final double xpMultiplier;          // XP multiplier
  final String? imageId;              // Activity thumbnail
  final String? instructions;         // How to play
  final DateTime addedAt;
  final DateTime? availableUntil;     // Limited time activity
  final bool isDaily;                 // Resets daily
  final bool isWeekly;                // Resets weekly
  final bool isFeatured;              // Featured activity
  final int playCount;                // Total times played
  final double averageScore;          // Average score (0-100)
  final Map<String, dynamic>? metadata;

  Activity({
    required this.activityId,
    required this.name,
    required this.description,
    required this.type,
    required this.difficulty,
    this.requiredLevel = 1,
    this.timeLimit = 0,
    this.maxAttempts = 0,
    required this.baseCoins,
    required this.baseXp,
    this.premiumCoinReward,
    this.coinMultiplier = 1.0,
    this.xpMultiplier = 1.0,
    this.imageId,
    this.instructions,
    required this.addedAt,
    this.availableUntil,
    this.isDaily = false,
    this.isWeekly = false,
    this.isFeatured = false,
    this.playCount = 0,
    this.averageScore = 0.0,
    this.metadata,
  });

  /// Check if activity is available
  bool get isAvailable {
    if (availableUntil != null && DateTime.now().isAfter(availableUntil!)) {
      return false;
    }
    return true;
  }

  /// Get time remaining for limited activities
  Duration? get timeRemaining {
    if (availableUntil == null) return null;
    final remaining = availableUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Get difficulty color code (for UI)
  String getDifficultyColor() {
    switch (difficulty) {
      case ActivityDifficulty.easy:
        return 'green';
      case ActivityDifficulty.normal:
        return 'blue';
      case ActivityDifficulty.hard:
        return 'orange';
      case ActivityDifficulty.expert:
        return 'red';
    }
  }

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'name': name,
        'description': description,
        'type': type.name,
        'difficulty': difficulty.name,
        'requiredLevel': requiredLevel,
        'timeLimit': timeLimit,
        'maxAttempts': maxAttempts,
        'baseCoins': baseCoins,
        'baseXp': baseXp,
        'premiumCoinReward': premiumCoinReward,
        'coinMultiplier': coinMultiplier,
        'xpMultiplier': xpMultiplier,
        'imageId': imageId,
        'instructions': instructions,
        'addedAt': addedAt.toIso8601String(),
        'availableUntil': availableUntil?.toIso8601String(),
        'isDaily': isDaily,
        'isWeekly': isWeekly,
        'isFeatured': isFeatured,
        'playCount': playCount,
        'averageScore': averageScore,
        'metadata': metadata,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        activityId: json['activityId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: ActivityType.values.byName(json['type'] as String),
        difficulty: ActivityDifficulty.values.byName(json['difficulty'] as String),
        requiredLevel: json['requiredLevel'] as int? ?? 1,
        timeLimit: json['timeLimit'] as int? ?? 0,
        maxAttempts: json['maxAttempts'] as int? ?? 0,
        baseCoins: json['baseCoins'] as int,
        baseXp: json['baseXp'] as int,
        premiumCoinReward: json['premiumCoinReward'] as int?,
        coinMultiplier: (json['coinMultiplier'] as num?)?.toDouble() ?? 1.0,
        xpMultiplier: (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0,
        imageId: json['imageId'] as String?,
        instructions: json['instructions'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
        availableUntil: json['availableUntil'] != null
            ? DateTime.parse(json['availableUntil'] as String)
            : null,
        isDaily: json['isDaily'] as bool? ?? false,
        isWeekly: json['isWeekly'] as bool? ?? false,
        isFeatured: json['isFeatured'] as bool? ?? false,
        playCount: json['playCount'] as int? ?? 0,
        averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// User's activity participation
class ActivityParticipation {
  final String participationId;
  final String userId;
  final String activityId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int score;                    // Score 0-100
  final int coinsEarned;
  final int xpEarned;
  final int? premiumCoinEarned;
  final int timeSpentSeconds;         // Actual time spent
  final Map<String, dynamic>? metadata;

  ActivityParticipation({
    required this.participationId,
    required this.userId,
    required this.activityId,
    required this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    this.score = 0,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.premiumCoinEarned,
    this.timeSpentSeconds = 0,
    this.metadata,
  });

  /// Check if activity is still in progress
  bool get isInProgress => !isCompleted && completedAt == null;

  /// Get duration of activity
  Duration get duration => (completedAt ?? DateTime.now()).difference(startedAt);

  Map<String, dynamic> toJson() => {
        'participationId': participationId,
        'userId': userId,
        'activityId': activityId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isCompleted': isCompleted,
        'score': score,
        'coinsEarned': coinsEarned,
        'xpEarned': xpEarned,
        'premiumCoinEarned': premiumCoinEarned,
        'timeSpentSeconds': timeSpentSeconds,
        'metadata': metadata,
      };

  factory ActivityParticipation.fromJson(Map<String, dynamic> json) =>
      ActivityParticipation(
        participationId: json['participationId'] as String,
        userId: json['userId'] as String,
        activityId: json['activityId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        score: json['score'] as int? ?? 0,
        coinsEarned: json['coinsEarned'] as int? ?? 0,
        xpEarned: json['xpEarned'] as int? ?? 0,
        premiumCoinEarned: json['premiumCoinEarned'] as int?,
        timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Activity result record
class ActivityResult {
  final String resultId;
  final String userId;
  final String activityId;
  final int score;                    // Final score (0-100)
  final int coinsReward;
  final int xpReward;
  final int? premiumCoinReward;
  final DateTime completedAt;
  final int timeSpentSeconds;
  final bool isPerfectScore;          // 100% score
  final bool isNewHighScore;          // Personal best
  final String? feedbackMessage;      // "Good!", "Great!", etc.
  final Map<String, dynamic>? metadata;

  ActivityResult({
    required this.resultId,
    required this.userId,
    required this.activityId,
    required this.score,
    required this.coinsReward,
    required this.xpReward,
    this.premiumCoinReward,
    required this.completedAt,
    required this.timeSpentSeconds,
    this.isPerfectScore = false,
    this.isNewHighScore = false,
    this.feedbackMessage,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'resultId': resultId,
        'userId': userId,
        'activityId': activityId,
        'score': score,
        'coinsReward': coinsReward,
        'xpReward': xpReward,
        'premiumCoinReward': premiumCoinReward,
        'completedAt': completedAt.toIso8601String(),
        'timeSpentSeconds': timeSpentSeconds,
        'isPerfectScore': isPerfectScore,
        'isNewHighScore': isNewHighScore,
        'feedbackMessage': feedbackMessage,
        'metadata': metadata,
      };

  factory ActivityResult.fromJson(Map<String, dynamic> json) => ActivityResult(
        resultId: json['resultId'] as String,
        userId: json['userId'] as String,
        activityId: json['activityId'] as String,
        score: json['score'] as int,
        coinsReward: json['coinsReward'] as int,
        xpReward: json['xpReward'] as int,
        premiumCoinReward: json['premiumCoinReward'] as int?,
        completedAt: DateTime.parse(json['completedAt'] as String),
        timeSpentSeconds: json['timeSpentSeconds'] as int,
        isPerfectScore: json['isPerfectScore'] as bool? ?? false,
        isNewHighScore: json['isNewHighScore'] as bool? ?? false,
        feedbackMessage: json['feedbackMessage'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// User's activity statistics
class ActivityStatistics {
  final String userId;
  final int totalActivitiesCompleted;
  final int totalCoinsEarned;
  final int totalXpEarned;
  final int perfectScores;            // Number of 100% scores
  final int personalBests;            // High score records
  final double averageScore;          // Average score across all activities
  final int longestPlayStreak;        // Consecutive days played
  final DateTime firstActivityAt;
  final DateTime lastActivityAt;
  final DateTime lastUpdatedAt;

  ActivityStatistics({
    required this.userId,
    this.totalActivitiesCompleted = 0,
    this.totalCoinsEarned = 0,
    this.totalXpEarned = 0,
    this.perfectScores = 0,
    this.personalBests = 0,
    this.averageScore = 0.0,
    this.longestPlayStreak = 0,
    required this.firstActivityAt,
    required this.lastActivityAt,
    required this.lastUpdatedAt,
  });

  /// Get activity tier based on total completed
  String getActivityTier() {
    if (totalActivitiesCompleted < 10) return 'ビギナー';
    if (totalActivitiesCompleted < 50) return 'アマチュア';
    if (totalActivitiesCompleted < 100) return 'インターミディエイト';
    if (totalActivitiesCompleted < 200) return 'アドバンス';
    if (totalActivitiesCompleted < 500) return 'エキスパート';
    return 'マスター';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalActivitiesCompleted': totalActivitiesCompleted,
        'totalCoinsEarned': totalCoinsEarned,
        'totalXpEarned': totalXpEarned,
        'perfectScores': perfectScores,
        'personalBests': personalBests,
        'averageScore': averageScore,
        'longestPlayStreak': longestPlayStreak,
        'firstActivityAt': firstActivityAt.toIso8601String(),
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory ActivityStatistics.fromJson(Map<String, dynamic> json) =>
      ActivityStatistics(
        userId: json['userId'] as String,
        totalActivitiesCompleted: json['totalActivitiesCompleted'] as int? ?? 0,
        totalCoinsEarned: json['totalCoinsEarned'] as int? ?? 0,
        totalXpEarned: json['totalXpEarned'] as int? ?? 0,
        perfectScores: json['perfectScores'] as int? ?? 0,
        personalBests: json['personalBests'] as int? ?? 0,
        averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
        longestPlayStreak: json['longestPlayStreak'] as int? ?? 0,
        firstActivityAt: DateTime.parse(json['firstActivityAt'] as String),
        lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete activities collection
class ActivityCollection {
  final String userId;
  final List<Activity> allActivities;           // Max 100 activities
  final List<ActivityParticipation> participations; // Max 500
  final List<ActivityResult> results;           // Max 1000
  final ActivityStatistics statistics;
  final DateTime generatedAt;

  ActivityCollection({
    required this.userId,
    required this.allActivities,
    required this.participations,
    required this.results,
    required this.statistics,
    required this.generatedAt,
  });

  /// Get available activities for user
  List<Activity> getAvailableActivities() =>
      allActivities.where((a) => a.isAvailable).toList();

  /// Get activities by type
  List<Activity> getActivitiesByType(ActivityType type) =>
      allActivities.where((a) => a.type == type).toList();

  /// Get activities by difficulty
  List<Activity> getActivitiesByDifficulty(ActivityDifficulty difficulty) =>
      allActivities.where((a) => a.difficulty == difficulty).toList();

  /// Get featured activities
  List<Activity> getFeaturedActivities() =>
      allActivities.where((a) => a.isFeatured && a.isAvailable).take(10).toList();

  /// Get today's activities (if daily)
  List<Activity> getTodaysActivities() {
    final now = DateTime.now();
    return allActivities
        .where((a) => a.isDaily && a.isAvailable)
        .where((a) {
          final lastResult = results
              .where((r) => r.activityId == a.activityId)
              .fold<DateTime?>(null, (prev, curr) =>
                  prev == null || curr.completedAt.isAfter(prev) ? curr.completedAt : prev);
          if (lastResult == null) return true;
          return lastResult.year != now.year ||
              lastResult.month != now.month ||
              lastResult.day != now.day;
        })
        .toList();
  }

  /// Get completed activities today
  List<ActivityResult> getCompletedToday() {
    final now = DateTime.now();
    return results
        .where((r) =>
            r.completedAt.year == now.year &&
            r.completedAt.month == now.month &&
            r.completedAt.day == now.day)
        .toList();
  }

  /// Get personal best for activity
  ActivityResult? getPersonalBest(String activityId) {
    final activityResults =
        results.where((r) => r.activityId == activityId).toList();
    if (activityResults.isEmpty) return null;
    activityResults.sort((a, b) => b.score.compareTo(a.score));
    return activityResults.first;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'allActivities': allActivities.map((a) => a.toJson()).toList(),
        'participations': participations.map((p) => p.toJson()).toList(),
        'results': results.map((r) => r.toJson()).toList(),
        'statistics': statistics.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ActivityCollection.fromJson(Map<String, dynamic> json) =>
      ActivityCollection(
        userId: json['userId'] as String,
        allActivities: ((json['allActivities'] as List?) ?? [])
            .map((a) => Activity.fromJson(a as Map<String, dynamic>))
            .toList(),
        participations: ((json['participations'] as List?) ?? [])
            .map((p) => ActivityParticipation.fromJson(p as Map<String, dynamic>))
            .toList(),
        results: ((json['results'] as List?) ?? [])
            .map((r) => ActivityResult.fromJson(r as Map<String, dynamic>))
            .toList(),
        statistics:
            ActivityStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
