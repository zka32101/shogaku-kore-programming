import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileState {
  final UserProfileCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  UserProfileState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  UserProfileState copyWith({
    UserProfileCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      UserProfileState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier() : super(UserProfileState());

  /// Initialize profile for user
  Future<void> initializeProfile(
    String userId,
    String username, {
    String? displayName,
    String? avatarId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile_$userId');

      late UserProfile profile;
      late UserStatistics statistics;
      late List<UserAchievement> achievements;
      late List<UserAchievement> featuredAchievements;
      late List<LevelMilestone> milestones;

      if (profileJson != null) {
        try {
          final parsed = Map<String, dynamic>.from(profileJson as Map);
          profile = UserProfile.fromJson(parsed['profile'] as Map<String, dynamic>);
          statistics = UserStatistics.fromJson(parsed['statistics'] as Map<String, dynamic>);
          achievements = ((parsed['achievements'] as List?) ?? [])
              .map((a) => UserAchievement.fromJson(a as Map<String, dynamic>))
              .toList();
          featuredAchievements = ((parsed['featuredAchievements'] as List?) ?? [])
              .map((a) => UserAchievement.fromJson(a as Map<String, dynamic>))
              .toList();
          milestones = ((parsed['milestones'] as List?) ?? [])
              .map((m) => LevelMilestone.fromJson(m as Map<String, dynamic>))
              .toList();
        } catch (e) {
          profile = _createDefaultProfile(userId, username, displayName, avatarId);
          statistics = _createDefaultStatistics(userId);
          achievements = [];
          featuredAchievements = [];
          milestones = _createDefaultMilestones();
        }
      } else {
        profile = _createDefaultProfile(userId, username, displayName, avatarId);
        statistics = _createDefaultStatistics(userId);
        achievements = [];
        featuredAchievements = [];
        milestones = _createDefaultMilestones();
      }

      final collection = UserProfileCollection(
        userId: userId,
        profile: profile,
        statistics: statistics,
        achievements: achievements,
        featuredAchievements: featuredAchievements,
        milestones: milestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistProfile(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update profile information
  Future<bool> updateProfile({
    required String userId,
    String? displayName,
    String? bioDescription,
    String? avatarId,
    String? bannerImageId,
    ProfileVisibility? visibility,
    String? preferredLanguage,
    String? nativeLanguage,
  }) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedProfile = UserProfile(
        userId: collection.profile.userId,
        username: collection.profile.username,
        displayName: displayName ?? collection.profile.displayName,
        bioDescription: bioDescription ?? collection.profile.bioDescription,
        avatarId: avatarId ?? collection.profile.avatarId,
        bannerImageId: bannerImageId ?? collection.profile.bannerImageId,
        visibility: visibility ?? collection.profile.visibility,
        totalXp: collection.profile.totalXp,
        currentLevel: collection.profile.currentLevel,
        coins: collection.profile.coins,
        premiumCurrency: collection.profile.premiumCurrency,
        createdAt: collection.profile.createdAt,
        lastActivityAt: DateTime.now(),
        preferredLanguage: preferredLanguage ?? collection.profile.preferredLanguage,
        nativeLanguage: nativeLanguage ?? collection.profile.nativeLanguage,
        customization: collection.profile.customization,
      );

      final updatedCollection = UserProfileCollection(
        userId: collection.userId,
        profile: updatedProfile,
        statistics: collection.statistics,
        achievements: collection.achievements,
        featuredAchievements: collection.featuredAchievements,
        milestones: collection.milestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add or update XP
  Future<bool> addXp(String userId, int xpAmount) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final newTotalXp = collection.profile.totalXp + xpAmount;
      final newLevel = (newTotalXp ~/ 100) + 1;
      final leveledUp = newLevel > collection.profile.currentLevel;

      final updatedProfile = UserProfile(
        userId: collection.profile.userId,
        username: collection.profile.username,
        displayName: collection.profile.displayName,
        bioDescription: collection.profile.bioDescription,
        avatarId: collection.profile.avatarId,
        bannerImageId: collection.profile.bannerImageId,
        visibility: collection.profile.visibility,
        totalXp: newTotalXp,
        currentLevel: newLevel,
        coins: collection.profile.coins,
        premiumCurrency: collection.profile.premiumCurrency,
        createdAt: collection.profile.createdAt,
        lastActivityAt: DateTime.now(),
        preferredLanguage: collection.profile.preferredLanguage,
        nativeLanguage: collection.profile.nativeLanguage,
        customization: collection.profile.customization,
      );

      // Update milestones if leveled up
      late List<LevelMilestone> updatedMilestones;
      if (leveledUp) {
        updatedMilestones = collection.milestones.map((m) {
          if (m.level <= newLevel && !m.isUnlocked) {
            return LevelMilestone(
              level: m.level,
              totalXpRequired: m.totalXpRequired,
              rewardId: m.rewardId,
              milestoneTitle: m.milestoneTitle,
              isUnlocked: true,
            );
          }
          return m;
        }).toList();
      } else {
        updatedMilestones = collection.milestones;
      }

      final updatedCollection = UserProfileCollection(
        userId: collection.userId,
        profile: updatedProfile,
        statistics: collection.statistics,
        achievements: collection.achievements,
        featuredAchievements: collection.featuredAchievements,
        milestones: updatedMilestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add coins
  Future<bool> addCoins(String userId, int coinAmount) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedProfile = UserProfile(
        userId: collection.profile.userId,
        username: collection.profile.username,
        displayName: collection.profile.displayName,
        bioDescription: collection.profile.bioDescription,
        avatarId: collection.profile.avatarId,
        bannerImageId: collection.profile.bannerImageId,
        visibility: collection.profile.visibility,
        totalXp: collection.profile.totalXp,
        currentLevel: collection.profile.currentLevel,
        coins: collection.profile.coins + coinAmount,
        premiumCurrency: collection.profile.premiumCurrency,
        createdAt: collection.profile.createdAt,
        lastActivityAt: DateTime.now(),
        preferredLanguage: collection.profile.preferredLanguage,
        nativeLanguage: collection.profile.nativeLanguage,
        customization: collection.profile.customization,
      );

      final updatedCollection = UserProfileCollection(
        userId: collection.userId,
        profile: updatedProfile,
        statistics: collection.statistics,
        achievements: collection.achievements,
        featuredAchievements: collection.featuredAchievements,
        milestones: collection.milestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add premium currency
  Future<bool> addPremiumCurrency(String userId, int premiumAmount) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedProfile = UserProfile(
        userId: collection.profile.userId,
        username: collection.profile.username,
        displayName: collection.profile.displayName,
        bioDescription: collection.profile.bioDescription,
        avatarId: collection.profile.avatarId,
        bannerImageId: collection.profile.bannerImageId,
        visibility: collection.profile.visibility,
        totalXp: collection.profile.totalXp,
        currentLevel: collection.profile.currentLevel,
        coins: collection.profile.coins,
        premiumCurrency: collection.profile.premiumCurrency + premiumAmount,
        createdAt: collection.profile.createdAt,
        lastActivityAt: DateTime.now(),
        preferredLanguage: collection.profile.preferredLanguage,
        nativeLanguage: collection.profile.nativeLanguage,
        customization: collection.profile.customization,
      );

      final updatedCollection = UserProfileCollection(
        userId: collection.userId,
        profile: updatedProfile,
        statistics: collection.statistics,
        achievements: collection.achievements,
        featuredAchievements: collection.featuredAchievements,
        milestones: collection.milestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Unlock achievement
  Future<bool> unlockAchievement(
    String userId,
    String achievementId,
    String title,
    String description, {
    String? iconId,
    int? rarity,
    String? category,
  }) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      // Check if already unlocked
      if (collection.achievements.any((a) => a.achievementId == achievementId)) {
        return true;
      }

      final newAchievement = UserAchievement(
        achievementId: achievementId,
        title: title,
        description: description,
        iconId: iconId,
        unlockedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        status: AchievementStatus.unlocked,
        rarity: rarity,
        category: category,
      );

      final newAchievements = [newAchievement, ...collection.achievements].take(100).toList();

      final updatedStatistics = UserStatistics(
        userId: collection.statistics.userId,
        totalLessonsTaken: collection.statistics.totalLessonsTaken,
        totalLessonsCompleted: collection.statistics.totalLessonsCompleted,
        totalMinutesLearned: collection.statistics.totalMinutesLearned,
        currentStreak: collection.statistics.currentStreak,
        longestStreak: collection.statistics.longestStreak,
        totalAchievementsUnlocked: collection.statistics.totalAchievementsUnlocked + 1,
        totalBadgesEarned: collection.statistics.totalBadgesEarned,
        totalChallengesCompleted: collection.statistics.totalChallengesCompleted,
        totalPostsCreated: collection.statistics.totalPostsCreated,
        totalCommentsPosted: collection.statistics.totalCommentsPosted,
        totalLikesReceived: collection.statistics.totalLikesReceived,
        totalFollowers: collection.statistics.totalFollowers,
        totalFollowing: collection.statistics.totalFollowing,
        averageLessonScore: collection.statistics.averageLessonScore,
        lastUpdatedAt: DateTime.now(),
      );

      final updatedCollection = UserProfileCollection(
        userId: collection.userId,
        profile: collection.profile,
        statistics: updatedStatistics,
        achievements: newAchievements,
        featuredAchievements: collection.featuredAchievements,
        milestones: collection.milestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Feature achievement on profile
  Future<bool> featureAchievement(String userId, String achievementId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final achievement = collection.achievements.firstWhere(
        (a) => a.achievementId == achievementId,
        orElse: () => null as dynamic,
      );
      if (achievement == null) return false;

      var newFeatured = List<UserAchievement>.from(collection.featuredAchievements);

      // Check if already featured
      if (newFeatured.any((a) => a.achievementId == achievementId)) {
        return true;
      }

      // Add to featured (max 5)
      newFeatured = [
        UserAchievement(
          achievementId: achievement.achievementId,
          title: achievement.title,
          description: achievement.description,
          iconId: achievement.iconId,
          unlockedAt: achievement.unlockedAt,
          status: AchievementStatus.featured,
          rarity: achievement.rarity,
          category: achievement.category,
        ),
        ...newFeatured,
      ].take(5).toList();

      final updatedCollection = UserProfileCollection(
        userId: collection.userId,
        profile: collection.profile,
        statistics: collection.statistics,
        achievements: collection.achievements,
        featuredAchievements: newFeatured,
        milestones: collection.milestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update statistics
  Future<bool> updateStatistics(
    String userId, {
    int? lessonsTaken,
    int? lessonsCompleted,
    int? minutesLearned,
    int? currentStreak,
    int? challengesCompleted,
    int? postsCreated,
    int? commentsPosted,
    int? likesReceived,
    int? followers,
    int? following,
    double? averageLessonScore,
  }) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final stats = collection.statistics;
      final updatedStatistics = UserStatistics(
        userId: stats.userId,
        totalLessonsTaken: lessonsTaken ?? stats.totalLessonsTaken,
        totalLessonsCompleted: lessonsCompleted ?? stats.totalLessonsCompleted,
        totalMinutesLearned: minutesLearned ?? stats.totalMinutesLearned,
        currentStreak: currentStreak ?? stats.currentStreak,
        longestStreak: (currentStreak ?? stats.currentStreak) > stats.longestStreak
            ? (currentStreak ?? stats.currentStreak)
            : stats.longestStreak,
        totalAchievementsUnlocked: stats.totalAchievementsUnlocked,
        totalBadgesEarned: stats.totalBadgesEarned,
        totalChallengesCompleted: challengesCompleted ?? stats.totalChallengesCompleted,
        totalPostsCreated: postsCreated ?? stats.totalPostsCreated,
        totalCommentsPosted: commentsPosted ?? stats.totalCommentsPosted,
        totalLikesReceived: likesReceived ?? stats.totalLikesReceived,
        totalFollowers: followers ?? stats.totalFollowers,
        totalFollowing: following ?? stats.totalFollowing,
        averageLessonScore: averageLessonScore ?? stats.averageLessonScore,
        lastUpdatedAt: DateTime.now(),
      );

      final updatedCollection = UserProfileCollection(
        userId: collection.userId,
        profile: collection.profile,
        statistics: updatedStatistics,
        achievements: collection.achievements,
        featuredAchievements: collection.featuredAchievements,
        milestones: collection.milestones,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get total achievements count
  int getTotalAchievements() => state.collection?.achievements.length ?? 0;

  /// Get unlocked achievements count
  int getUnlockedAchievements() =>
      state.collection?.getUnlockedAchievements().length ?? 0;

  /// Get user rank
  UserRank? getUserRank() => state.collection?.profile.getRank();

  /// Get engagement score
  int getEngagementScore() => state.collection?.statistics.getEngagementScore() ?? 0;

  UserProfile _createDefaultProfile(
    String userId,
    String username,
    String? displayName,
    String? avatarId,
  ) {
    return UserProfile(
      userId: userId,
      username: username,
      displayName: displayName ?? username,
      avatarId: avatarId,
      visibility: ProfileVisibility.public,
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );
  }

  UserStatistics _createDefaultStatistics(String userId) {
    return UserStatistics(
      userId: userId,
      lastUpdatedAt: DateTime.now(),
    );
  }

  List<LevelMilestone> _createDefaultMilestones() {
    return [
      LevelMilestone(level: 1, totalXpRequired: 0, milestoneTitle: 'スタート'),
      LevelMilestone(level: 5, totalXpRequired: 500, milestoneTitle: '初級達成'),
      LevelMilestone(level: 10, totalXpRequired: 1000, milestoneTitle: '初級完了'),
      LevelMilestone(level: 25, totalXpRequired: 2500, milestoneTitle: '中級達成'),
      LevelMilestone(level: 50, totalXpRequired: 5000, milestoneTitle: '中級完了'),
      LevelMilestone(level: 75, totalXpRequired: 7500, milestoneTitle: '上級達成'),
      LevelMilestone(level: 100, totalXpRequired: 10000, milestoneTitle: 'マスター達成'),
    ];
  }

  Future<void> _persistProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection = state.collection;
      if (collection != null) {
        await prefs.setString(
          'user_profile_$userId',
          collection.toJson().toString(),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }
}

final userProfileProvider = StateNotifierProvider.autoDispose<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(),
);

final userProfileCollectionProvider = Provider.autoDispose<UserProfileCollection?>(
  (ref) => ref.watch(userProfileProvider).collection,
);

final userProfileProvider_profile = Provider.autoDispose<UserProfile?>(
  (ref) => ref.watch(userProfileProvider).collection?.profile,
);

final userStatisticsProvider = Provider.autoDispose<UserStatistics?>(
  (ref) => ref.watch(userProfileProvider).collection?.statistics,
);

final userAchievementsProvider = Provider.autoDispose<List<UserAchievement>>(
  (ref) => ref.watch(userProfileProvider).collection?.achievements ?? [],
);

final userFeaturedAchievementsProvider = Provider.autoDispose<List<UserAchievement>>(
  (ref) => ref.watch(userProfileProvider).collection?.featuredAchievements ?? [],
);

final userLevelMilestonesProvider = Provider.autoDispose<List<LevelMilestone>>(
  (ref) => ref.watch(userProfileProvider).collection?.milestones ?? [],
);

final unlockedAchievementsProvider = Provider.autoDispose<List<UserAchievement>>(
  (ref) => ref.watch(userProfileProvider).collection?.getUnlockedAchievements() ?? [],
);

final lockedAchievementsProvider = Provider.autoDispose<List<UserAchievement>>(
  (ref) => ref.watch(userProfileProvider).collection?.getLockedAchievements() ?? [],
);

final userRankProvider = Provider.autoDispose<UserRank?>(
  (ref) => ref.watch(userProfileProvider).collection?.profile.getRank(),
);

final userRankTitleProvider = Provider.autoDispose<String?>(
  (ref) => ref.watch(userProfileProvider).collection?.profile.getRankTitle(),
);

final learningLevelProvider = Provider.autoDispose<String?>(
  (ref) => ref.watch(userProfileProvider).collection?.statistics.getLearningLevel(),
);

final engagementScoreProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(userProfileProvider).collection?.statistics.getEngagementScore() ?? 0,
);
