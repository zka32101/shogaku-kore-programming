/// User level rank
enum UserRank {
  beginner,      // Level 1-10
  learner,       // Level 11-25
  intermediate,  // Level 26-50
  advanced,      // Level 51-75
  expert,        // Level 76-100
  master,        // Level 100+
}

/// User achievement status
enum AchievementStatus {
  locked,        // Not yet earned
  unlocked,      // Earned but not displayed
  featured,      // Currently showcased on profile
}

/// Profile visibility setting
enum ProfileVisibility {
  public,        // Visible to all users
  friends,       // Visible to friends only
  private,       // Only visible to user
}

/// User achievement record
class UserAchievement {
  final String achievementId;
  final String title;           // Achievement title (Japanese)
  final String description;
  final String? iconId;
  final int unlockedAt;         // Timestamp when unlocked
  final AchievementStatus status;
  final int? rarity;            // Rarity score (1-5)
  final String? category;

  UserAchievement({
    required this.achievementId,
    required this.title,
    required this.description,
    this.iconId,
    required this.unlockedAt,
    this.status = AchievementStatus.locked,
    this.rarity,
    this.category,
  });

  /// Check if achievement is recently unlocked (within 7 days)
  bool get isRecentlyUnlocked {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final dayInSeconds = 24 * 60 * 60;
    return (now - unlockedAt) < (7 * dayInSeconds);
  }

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'title': title,
        'description': description,
        'iconId': iconId,
        'unlockedAt': unlockedAt,
        'status': status.name,
        'rarity': rarity,
        'category': category,
      };

  factory UserAchievement.fromJson(Map<String, dynamic> json) => UserAchievement(
        achievementId: json['achievementId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        iconId: json['iconId'] as String?,
        unlockedAt: json['unlockedAt'] as int,
        status: AchievementStatus.values.byName(json['status'] as String? ?? 'locked'),
        rarity: json['rarity'] as int?,
        category: json['category'] as String?,
      );
}

/// User level milestone
class LevelMilestone {
  final int level;
  final int totalXpRequired;
  final String? rewardId;       // Associated reward/badge
  final String? milestoneTitle;
  final bool isUnlocked;

  LevelMilestone({
    required this.level,
    required this.totalXpRequired,
    this.rewardId,
    this.milestoneTitle,
    this.isUnlocked = false,
  });

  /// Get XP needed for this level
  int get xpForThisLevel => totalXpRequired - (level > 1 ? (level - 1) * 100 : 0);

  Map<String, dynamic> toJson() => {
        'level': level,
        'totalXpRequired': totalXpRequired,
        'rewardId': rewardId,
        'milestoneTitle': milestoneTitle,
        'isUnlocked': isUnlocked,
      };

  factory LevelMilestone.fromJson(Map<String, dynamic> json) => LevelMilestone(
        level: json['level'] as int,
        totalXpRequired: json['totalXpRequired'] as int,
        rewardId: json['rewardId'] as String?,
        milestoneTitle: json['milestoneTitle'] as String?,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
      );
}

/// User profile basic information
class UserProfile {
  final String userId;
  final String username;
  final String? displayName;
  final String? bioDescription;
  final String? avatarId;
  final String? bannerImageId;
  final ProfileVisibility visibility;
  final int totalXp;
  final int currentLevel;
  final int coins;
  final int premiumCurrency;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final String? preferredLanguage;  // Learning language preference
  final String? nativeLanguage;
  final Map<String, dynamic>? customization; // Theme, badges, etc.

  UserProfile({
    required this.userId,
    required this.username,
    this.displayName,
    this.bioDescription,
    this.avatarId,
    this.bannerImageId,
    this.visibility = ProfileVisibility.public,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.coins = 0,
    this.premiumCurrency = 0,
    required this.createdAt,
    this.lastActivityAt,
    this.preferredLanguage = 'ja',
    this.nativeLanguage,
    this.customization,
  });

  /// Get user rank based on level
  UserRank getRank() {
    if (currentLevel <= 10) return UserRank.beginner;
    if (currentLevel <= 25) return UserRank.learner;
    if (currentLevel <= 50) return UserRank.intermediate;
    if (currentLevel <= 75) return UserRank.advanced;
    if (currentLevel <= 100) return UserRank.expert;
    return UserRank.master;
  }

  /// Get rank title in Japanese
  String getRankTitle() {
    switch (getRank()) {
      case UserRank.beginner:
        return '初心者';
      case UserRank.learner:
        return '学習者';
      case UserRank.intermediate:
        return '中級者';
      case UserRank.advanced:
        return '上級者';
      case UserRank.expert:
        return 'エキスパート';
      case UserRank.master:
        return 'マスター';
    }
  }

  /// Get XP progress to next level
  int getXpToNextLevel() => (currentLevel * 100) - (totalXp % (currentLevel * 100));

  /// Get account age in days
  int getAccountAgeDays() =>
      DateTime.now().difference(createdAt).inDays;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'bioDescription': bioDescription,
        'avatarId': avatarId,
        'bannerImageId': bannerImageId,
        'visibility': visibility.name,
        'totalXp': totalXp,
        'currentLevel': currentLevel,
        'coins': coins,
        'premiumCurrency': premiumCurrency,
        'createdAt': createdAt.toIso8601String(),
        'lastActivityAt': lastActivityAt?.toIso8601String(),
        'preferredLanguage': preferredLanguage,
        'nativeLanguage': nativeLanguage,
        'customization': customization,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        bioDescription: json['bioDescription'] as String?,
        avatarId: json['avatarId'] as String?,
        bannerImageId: json['bannerImageId'] as String?,
        visibility: ProfileVisibility.values.byName(json['visibility'] as String? ?? 'public'),
        totalXp: json['totalXp'] as int? ?? 0,
        currentLevel: json['currentLevel'] as int? ?? 1,
        coins: json['coins'] as int? ?? 0,
        premiumCurrency: json['premiumCurrency'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt'] as String) : null,
        preferredLanguage: json['preferredLanguage'] as String? ?? 'ja',
        nativeLanguage: json['nativeLanguage'] as String?,
        customization: json['customization'] as Map<String, dynamic>?,
      );
}

/// Comprehensive user statistics
class UserStatistics {
  final String userId;
  final int totalLessonsTaken;
  final int totalLessonsCompleted;
  final int totalMinutesLearned;
  final int currentStreak;           // Consecutive days of activity
  final int longestStreak;
  final int totalAchievementsUnlocked;
  final int totalBadgesEarned;
  final int totalChallengesCompleted;
  final int totalPostsCreated;
  final int totalCommentsPosted;
  final int totalLikesReceived;
  final int totalFollowers;
  final int totalFollowing;
  final double averageLessonScore;
  final DateTime lastUpdatedAt;

  UserStatistics({
    required this.userId,
    this.totalLessonsTaken = 0,
    this.totalLessonsCompleted = 0,
    this.totalMinutesLearned = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalAchievementsUnlocked = 0,
    this.totalBadgesEarned = 0,
    this.totalChallengesCompleted = 0,
    this.totalPostsCreated = 0,
    this.totalCommentsPosted = 0,
    this.totalLikesReceived = 0,
    this.totalFollowers = 0,
    this.totalFollowing = 0,
    this.averageLessonScore = 0.0,
    required this.lastUpdatedAt,
  });

  /// Get completion rate percentage
  double get completionRate {
    if (totalLessonsTaken == 0) return 0;
    return (totalLessonsCompleted / totalLessonsTaken * 100);
  }

  /// Get engagement score (combines various metrics)
  int getEngagementScore() =>
      totalLessonsTaken +
      totalAchievementsUnlocked * 5 +
      totalChallengesCompleted * 3 +
      totalPostsCreated * 2 +
      (totalFollowers ~/ 10);

  /// Get learning level based on lessons completed
  String getLearningLevel() {
    if (totalLessonsCompleted < 50) return '初級';
    if (totalLessonsCompleted < 150) return '中級';
    if (totalLessonsCompleted < 300) return '上級';
    if (totalLessonsCompleted < 500) return '上級+';
    return 'マスター';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalLessonsTaken': totalLessonsTaken,
        'totalLessonsCompleted': totalLessonsCompleted,
        'totalMinutesLearned': totalMinutesLearned,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalAchievementsUnlocked': totalAchievementsUnlocked,
        'totalBadgesEarned': totalBadgesEarned,
        'totalChallengesCompleted': totalChallengesCompleted,
        'totalPostsCreated': totalPostsCreated,
        'totalCommentsPosted': totalCommentsPosted,
        'totalLikesReceived': totalLikesReceived,
        'totalFollowers': totalFollowers,
        'totalFollowing': totalFollowing,
        'averageLessonScore': averageLessonScore,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory UserStatistics.fromJson(Map<String, dynamic> json) => UserStatistics(
        userId: json['userId'] as String,
        totalLessonsTaken: json['totalLessonsTaken'] as int? ?? 0,
        totalLessonsCompleted: json['totalLessonsCompleted'] as int? ?? 0,
        totalMinutesLearned: json['totalMinutesLearned'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        totalAchievementsUnlocked: json['totalAchievementsUnlocked'] as int? ?? 0,
        totalBadgesEarned: json['totalBadgesEarned'] as int? ?? 0,
        totalChallengesCompleted: json['totalChallengesCompleted'] as int? ?? 0,
        totalPostsCreated: json['totalPostsCreated'] as int? ?? 0,
        totalCommentsPosted: json['totalCommentsPosted'] as int? ?? 0,
        totalLikesReceived: json['totalLikesReceived'] as int? ?? 0,
        totalFollowers: json['totalFollowers'] as int? ?? 0,
        totalFollowing: json['totalFollowing'] as int? ?? 0,
        averageLessonScore: (json['averageLessonScore'] as num?)?.toDouble() ?? 0.0,
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete user profile collection
class UserProfileCollection {
  final String userId;
  final UserProfile profile;
  final UserStatistics statistics;
  final List<UserAchievement> achievements;      // Max 100
  final List<UserAchievement> featuredAchievements; // Up to 5 featured
  final List<LevelMilestone> milestones;
  final DateTime generatedAt;

  UserProfileCollection({
    required this.userId,
    required this.profile,
    required this.statistics,
    required this.achievements,
    required this.featuredAchievements,
    required this.milestones,
    required this.generatedAt,
  });

  /// Get recently unlocked achievements
  List<UserAchievement> getRecentAchievements(int days) =>
      achievements.where((a) => a.isRecentlyUnlocked).toList();

  /// Get achievements by category
  List<UserAchievement> getAchievementsByCategory(String category) =>
      achievements.where((a) => a.category == category).toList();

  /// Get locked achievements
  List<UserAchievement> getLockedAchievements() =>
      achievements.where((a) => a.status == AchievementStatus.locked).toList();

  /// Get unlocked achievements
  List<UserAchievement> getUnlockedAchievements() =>
      achievements.where((a) => a.status != AchievementStatus.locked).toList();

  /// Get rarity breakdown
  Map<int, int> getRarityBreakdown() {
    final breakdown = <int, int>{};
    for (final achievement in achievements) {
      if (achievement.rarity != null) {
        breakdown[achievement.rarity!] = (breakdown[achievement.rarity!] ?? 0) + 1;
      }
    }
    return breakdown;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'profile': profile.toJson(),
        'statistics': statistics.toJson(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'featuredAchievements': featuredAchievements.map((a) => a.toJson()).toList(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory UserProfileCollection.fromJson(Map<String, dynamic> json) =>
      UserProfileCollection(
        userId: json['userId'] as String,
        profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
        statistics: UserStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
        achievements: ((json['achievements'] as List?) ?? [])
            .map((a) => UserAchievement.fromJson(a as Map<String, dynamic>))
            .toList(),
        featuredAchievements: ((json['featuredAchievements'] as List?) ?? [])
            .map((a) => UserAchievement.fromJson(a as Map<String, dynamic>))
            .toList(),
        milestones: ((json['milestones'] as List?) ?? [])
            .map((m) => LevelMilestone.fromJson(m as Map<String, dynamic>))
            .toList(),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
