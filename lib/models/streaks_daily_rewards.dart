/// Daily login reward tier
class DailyRewardTier {
  final int dayNumber;               // Day 1, 2, 3, etc.
  final String rewardName;           // Reward name (Japanese)
  final int coinReward;
  final int xpReward;
  final int? premiumCoinReward;
  final String? specialItemId;       // Special item on milestone days
  final bool isMilestone;            // Day 7, 14, 21, 30, etc.

  DailyRewardTier({
    required this.dayNumber,
    required this.rewardName,
    required this.coinReward,
    required this.xpReward,
    this.premiumCoinReward,
    this.specialItemId,
    this.isMilestone = false,
  });

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'rewardName': rewardName,
        'coinReward': coinReward,
        'xpReward': xpReward,
        'premiumCoinReward': premiumCoinReward,
        'specialItemId': specialItemId,
        'isMilestone': isMilestone,
      };

  factory DailyRewardTier.fromJson(Map<String, dynamic> json) => DailyRewardTier(
        dayNumber: json['dayNumber'] as int,
        rewardName: json['rewardName'] as String,
        coinReward: json['coinReward'] as int,
        xpReward: json['xpReward'] as int,
        premiumCoinReward: json['premiumCoinReward'] as int?,
        specialItemId: json['specialItemId'] as String?,
        isMilestone: json['isMilestone'] as bool? ?? false,
      );
}

/// User's daily login record
class DailyLogin {
  final String loginId;
  final String userId;
  final DateTime loginDate;
  final DateTime? logoutDate;
  final int minutesActive;           // Session duration
  final bool claimedReward;
  final int coinsEarned;
  final int xpEarned;
  final String? deviceInfo;
  final Map<String, dynamic>? metadata;

  DailyLogin({
    required this.loginId,
    required this.userId,
    required this.loginDate,
    this.logoutDate,
    this.minutesActive = 0,
    this.claimedReward = false,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.deviceInfo,
    this.metadata,
  });

  /// Check if login is from today
  bool get isToday {
    final now = DateTime.now();
    return loginDate.year == now.year &&
        loginDate.month == now.month &&
        loginDate.day == now.day;
  }

  /// Get session duration in minutes
  int getSessionMinutes() {
    if (logoutDate == null) {
      return DateTime.now().difference(loginDate).inMinutes;
    }
    return logoutDate!.difference(loginDate).inMinutes;
  }

  Map<String, dynamic> toJson() => {
        'loginId': loginId,
        'userId': userId,
        'loginDate': loginDate.toIso8601String(),
        'logoutDate': logoutDate?.toIso8601String(),
        'minutesActive': minutesActive,
        'claimedReward': claimedReward,
        'coinsEarned': coinsEarned,
        'xpEarned': xpEarned,
        'deviceInfo': deviceInfo,
        'metadata': metadata,
      };

  factory DailyLogin.fromJson(Map<String, dynamic> json) => DailyLogin(
        loginId: json['loginId'] as String,
        userId: json['userId'] as String,
        loginDate: DateTime.parse(json['loginDate'] as String),
        logoutDate:
            json['logoutDate'] != null ? DateTime.parse(json['logoutDate'] as String) : null,
        minutesActive: json['minutesActive'] as int? ?? 0,
        claimedReward: json['claimedReward'] as bool? ?? false,
        coinsEarned: json['coinsEarned'] as int? ?? 0,
        xpEarned: json['xpEarned'] as int? ?? 0,
        deviceInfo: json['deviceInfo'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// User's active streak
class UserStreak {
  final String streakId;
  final String userId;
  final int currentStreak;           // Current consecutive days
  final int longestStreak;           // All-time longest
  final DateTime streakStartDate;
  final DateTime lastLoginDate;
  final DateTime? streakBrokenDate;
  final int timesStreakBroken;
  final bool isActive;               // Has logged in today
  final int totalDaysParticipated;
  final DateTime lastUpdatedAt;

  UserStreak({
    required this.streakId,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakStartDate,
    required this.lastLoginDate,
    this.streakBrokenDate,
    this.timesStreakBroken = 0,
    this.isActive = true,
    this.totalDaysParticipated = 0,
    required this.lastUpdatedAt,
  });

  /// Get days until streak is broken
  int get daysUntilBroken {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final difference = tomorrow.difference(lastLoginDate).inDays;
    return (2 - difference).clamp(0, 2);
  }

  /// Check if streak is at risk (no login today)
  bool get isAtRisk {
    final today = DateTime.now();
    return lastLoginDate.year != today.year ||
        lastLoginDate.month != today.month ||
        lastLoginDate.day != today.day;
  }

  /// Get streak status
  String getStreakStatus() {
    if (currentStreak == 0) return '中断';
    if (isAtRisk) return '危機';
    return 'アクティブ';
  }

  Map<String, dynamic> toJson() => {
        'streakId': streakId,
        'userId': userId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'streakStartDate': streakStartDate.toIso8601String(),
        'lastLoginDate': lastLoginDate.toIso8601String(),
        'streakBrokenDate': streakBrokenDate?.toIso8601String(),
        'timesStreakBroken': timesStreakBroken,
        'isActive': isActive,
        'totalDaysParticipated': totalDaysParticipated,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory UserStreak.fromJson(Map<String, dynamic> json) => UserStreak(
        streakId: json['streakId'] as String,
        userId: json['userId'] as String,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        streakStartDate: DateTime.parse(json['streakStartDate'] as String),
        lastLoginDate: DateTime.parse(json['lastLoginDate'] as String),
        streakBrokenDate: json['streakBrokenDate'] != null
            ? DateTime.parse(json['streakBrokenDate'] as String)
            : null,
        timesStreakBroken: json['timesStreakBroken'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        totalDaysParticipated: json['totalDaysParticipated'] as int? ?? 0,
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Daily reward claim record
class DailyRewardClaim {
  final String claimId;
  final String userId;
  final int dayNumber;               // Which day was claimed
  final DateTime claimedAt;
  final int coinsReward;
  final int xpReward;
  final int? premiumCoinReward;
  final String? specialItemId;
  final double? streakMultiplier;    // Bonus multiplier for streak bonus

  DailyRewardClaim({
    required this.claimId,
    required this.userId,
    required this.dayNumber,
    required this.claimedAt,
    required this.coinsReward,
    required this.xpReward,
    this.premiumCoinReward,
    this.specialItemId,
    this.streakMultiplier,
  });

  Map<String, dynamic> toJson() => {
        'claimId': claimId,
        'userId': userId,
        'dayNumber': dayNumber,
        'claimedAt': claimedAt.toIso8601String(),
        'coinsReward': coinsReward,
        'xpReward': xpReward,
        'premiumCoinReward': premiumCoinReward,
        'specialItemId': specialItemId,
        'streakMultiplier': streakMultiplier,
      };

  factory DailyRewardClaim.fromJson(Map<String, dynamic> json) => DailyRewardClaim(
        claimId: json['claimId'] as String,
        userId: json['userId'] as String,
        dayNumber: json['dayNumber'] as int,
        claimedAt: DateTime.parse(json['claimedAt'] as String),
        coinsReward: json['coinsReward'] as int,
        xpReward: json['xpReward'] as int,
        premiumCoinReward: json['premiumCoinReward'] as int?,
        specialItemId: json['specialItemId'] as String?,
        streakMultiplier: (json['streakMultiplier'] as num?)?.toDouble(),
      );
}

/// Streak statistics
class StreakStatistics {
  final String userId;
  final int totalLoginsEver;
  final int consecutiveDaysActive;   // Current streak
  final int longestStreak;           // All-time best
  final int streaksAchieved;         // Times reached 7+ day streak
  final int totalCoinsFromStreaks;
  final int totalXpFromStreaks;
  final DateTime firstLoginAt;
  final DateTime lastLoginAt;
  final DateTime lastUpdatedAt;

  StreakStatistics({
    required this.userId,
    this.totalLoginsEver = 0,
    this.consecutiveDaysActive = 0,
    this.longestStreak = 0,
    this.streaksAchieved = 0,
    this.totalCoinsFromStreaks = 0,
    this.totalXpFromStreaks = 0,
    required this.firstLoginAt,
    required this.lastLoginAt,
    required this.lastUpdatedAt,
  });

  /// Get streak tier based on current streak
  String getStreakTier() {
    if (consecutiveDaysActive < 3) return '初心者';
    if (consecutiveDaysActive < 7) return '着実';
    if (consecutiveDaysActive < 14) return '堅実';
    if (consecutiveDaysActive < 30) return '習慣形成';
    if (consecutiveDaysActive < 100) return 'コミットメント';
    return 'レジェンド';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalLoginsEver': totalLoginsEver,
        'consecutiveDaysActive': consecutiveDaysActive,
        'longestStreak': longestStreak,
        'streaksAchieved': streaksAchieved,
        'totalCoinsFromStreaks': totalCoinsFromStreaks,
        'totalXpFromStreaks': totalXpFromStreaks,
        'firstLoginAt': firstLoginAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory StreakStatistics.fromJson(Map<String, dynamic> json) => StreakStatistics(
        userId: json['userId'] as String,
        totalLoginsEver: json['totalLoginsEver'] as int? ?? 0,
        consecutiveDaysActive: json['consecutiveDaysActive'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        streaksAchieved: json['streaksAchieved'] as int? ?? 0,
        totalCoinsFromStreaks: json['totalCoinsFromStreaks'] as int? ?? 0,
        totalXpFromStreaks: json['totalXpFromStreaks'] as int? ?? 0,
        firstLoginAt: DateTime.parse(json['firstLoginAt'] as String),
        lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete streaks and daily rewards collection
class StreakAndRewardCollection {
  final String userId;
  final UserStreak currentStreak;
  final List<DailyLogin> loginHistory;          // Max 400 (13 months)
  final List<DailyRewardClaim> rewardClaims;    // Max 365
  final List<DailyRewardTier> rewardSchedule;   // Daily reward tiers
  final StreakStatistics statistics;
  final DateTime generatedAt;

  StreakAndRewardCollection({
    required this.userId,
    required this.currentStreak,
    required this.loginHistory,
    required this.rewardClaims,
    required this.rewardSchedule,
    required this.statistics,
    required this.generatedAt,
  });

  /// Get today's streak bonus multiplier
  double getStreakBonusMultiplier() {
    if (currentStreak.currentStreak < 3) return 1.0;
    if (currentStreak.currentStreak < 7) return 1.1;
    if (currentStreak.currentStreak < 14) return 1.2;
    if (currentStreak.currentStreak < 30) return 1.5;
    if (currentStreak.currentStreak < 100) return 2.0;
    return 2.5;
  }

  /// Get today's login reward
  DailyRewardTier? getTodaysReward() {
    final dayOfMonth = DateTime.now().day;
    return rewardSchedule.firstWhere(
      (r) => r.dayNumber == dayOfMonth,
      orElse: () => null as dynamic,
    ) as DailyRewardTier?;
  }

  /// Get logins this month
  List<DailyLogin> getLoginsThisMonth() {
    final now = DateTime.now();
    return loginHistory
        .where((l) => l.loginDate.year == now.year && l.loginDate.month == now.month)
        .toList();
  }

  /// Get recent logins (last N days)
  List<DailyLogin> getRecentLogins({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return loginHistory.where((l) => l.loginDate.isAfter(cutoff)).toList();
  }

  /// Get login streak history
  List<int> getStreakHistory() {
    final streaks = <int>[];
    int currentCount = 0;

    for (final login in loginHistory.reversed) {
      if (login.loginDate.day > 0) {
        currentCount++;
      } else {
        if (currentCount > 0) {
          streaks.add(currentCount);
        }
        currentCount = 0;
      }
    }

    return streaks;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentStreak': currentStreak.toJson(),
        'loginHistory': loginHistory.map((l) => l.toJson()).toList(),
        'rewardClaims': rewardClaims.map((c) => c.toJson()).toList(),
        'rewardSchedule': rewardSchedule.map((r) => r.toJson()).toList(),
        'statistics': statistics.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory StreakAndRewardCollection.fromJson(Map<String, dynamic> json) =>
      StreakAndRewardCollection(
        userId: json['userId'] as String,
        currentStreak: UserStreak.fromJson(json['currentStreak'] as Map<String, dynamic>),
        loginHistory: ((json['loginHistory'] as List?) ?? [])
            .map((l) => DailyLogin.fromJson(l as Map<String, dynamic>))
            .toList(),
        rewardClaims: ((json['rewardClaims'] as List?) ?? [])
            .map((c) => DailyRewardClaim.fromJson(c as Map<String, dynamic>))
            .toList(),
        rewardSchedule: ((json['rewardSchedule'] as List?) ?? [])
            .map((r) => DailyRewardTier.fromJson(r as Map<String, dynamic>))
            .toList(),
        statistics: StreakStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
