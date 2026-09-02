import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_feed.dart';

class ActivityFeedState {
  final ActivityFeedCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;
  final List<String> recentActivityIds; // Activity IDs created in this session

  ActivityFeedState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
    this.recentActivityIds = const [],
  });

  ActivityFeedState copyWith({
    ActivityFeedCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
    List<String>? recentActivityIds,
  }) =>
      ActivityFeedState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        recentActivityIds: recentActivityIds ?? this.recentActivityIds,
      );
}

class ActivityFeedNotifier extends StateNotifier<ActivityFeedState> {
  ActivityFeedNotifier() : super(ActivityFeedState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// Initialize activity feed for user
  Future<void> initializeActivityFeed(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedJson = prefs.getString('activity_feed_$userId');

      late List<Activity> activities;
      late List<String> followingUserIds;
      late ActivityStats stats;

      if (feedJson != null) {
        try {
          final parsed = Map<String, dynamic>.from(feedJson as Map);
          activities = ((parsed['feed'] as List?) ?? [])
              .map((a) => Activity.fromJson(a as Map<String, dynamic>))
              .toList();
          followingUserIds = ((parsed['followingUserIds'] as List?) ?? [])
              .map((id) => id as String)
              .toList();
          stats = ActivityStats.fromJson(parsed['stats'] as Map<String, dynamic>);
        } catch (e) {
          activities = [];
          followingUserIds = [];
          stats = _createDefaultStats(userId);
        }
      } else {
        activities = [];
        followingUserIds = [];
        stats = _createDefaultStats(userId);
      }

      // Load comments
      final commentsJson = prefs.getString('activity_comments_$userId');
      late Map<String, List<ActivityComment>> comments;

      if (commentsJson != null) {
        try {
          final parsed = Map<String, dynamic>.from(commentsJson as Map);
          comments = (parsed.cast<String, List>()).map(
            (key, value) => MapEntry(
              key,
              ((value as List?) ?? [])
                  .map((c) => ActivityComment.fromJson(c as Map<String, dynamic>))
                  .toList(),
            ),
          );
        } catch (e) {
          comments = {};
        }
      } else {
        comments = {};
      }

      // Load liked activity IDs
      final likedJson = prefs.getStringList('liked_activities_$userId') ?? [];

      final feed = ActivityFeed(
        userId: userId,
        feed: activities,
        comments: comments,
        likedActivityIds: likedJson,
        followingUserIds: followingUserIds,
        lastFetchedAt: DateTime.now(),
        generatedAt: DateTime.now(),
      );

      final collection = ActivityFeedCollection(
        userId: userId,
        feed: feed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistActivityFeed(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create new activity
  Future<bool> addActivity(
    String userId,
    String username,
    String? userAvatarId,
    ActivityType type,
    ActivityVisibility visibility,
    String title,
    String description, {
    String? imageId,
    Map<String, dynamic>? data,
    int? relatedUserId,
    String? relatedUsername,
    String? actionUrl,
  }) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final activity = Activity(
        activityId: _generateId('activity'),
        userId: userId,
        username: username,
        userAvatarId: userAvatarId,
        type: type,
        visibility: visibility,
        title: title,
        description: description,
        imageId: imageId,
        data: data,
        relatedUserId: relatedUserId,
        relatedUsername: relatedUsername,
        likeCount: 0,
        commentCount: 0,
        isLikedByCurrentUser: false,
        createdAt: DateTime.now(),
        actionUrl: actionUrl,
      );

      // Add to activities (keep max 500)
      final newActivities = [activity, ...collection.feed.feed].take(500).toList();

      // Update stats
      final stats = _calculateStats(collection.stats, newActivities);

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: newActivities,
        comments: collection.feed.comments,
        likedActivityIds: collection.feed.likedActivityIds,
        followingUserIds: collection.feed.followingUserIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      final newRecentActivityIds = [...state.recentActivityIds, activity.activityId];

      state = state.copyWith(
        collection: updatedCollection,
        recentActivityIds: newRecentActivityIds,
      );

      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Like an activity
  Future<bool> likeActivity(String userId, String activityId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      // Check if already liked
      if (collection.feed.likedActivityIds.contains(activityId)) {
        return true; // Already liked
      }

      // Update activity like count
      final updatedActivities = collection.feed.feed.map((a) {
        if (a.activityId == activityId) {
          return Activity(
            activityId: a.activityId,
            userId: a.userId,
            username: a.username,
            userAvatarId: a.userAvatarId,
            type: a.type,
            visibility: a.visibility,
            title: a.title,
            description: a.description,
            imageId: a.imageId,
            data: a.data,
            relatedUserId: a.relatedUserId,
            relatedUsername: a.relatedUsername,
            likeCount: a.likeCount + 1,
            commentCount: a.commentCount,
            isLikedByCurrentUser: true,
            createdAt: a.createdAt,
            updatedAt: DateTime.now(),
            actionUrl: a.actionUrl,
          );
        }
        return a;
      }).toList();

      final newLikedIds = [...collection.feed.likedActivityIds, activityId];
      final stats = _calculateStats(collection.stats, updatedActivities);

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: updatedActivities,
        comments: collection.feed.comments,
        likedActivityIds: newLikedIds,
        followingUserIds: collection.feed.followingUserIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Unlike an activity
  Future<bool> unlikeActivity(String userId, String activityId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      // Check if liked
      if (!collection.feed.likedActivityIds.contains(activityId)) {
        return true; // Not liked, nothing to do
      }

      // Update activity like count
      final updatedActivities = collection.feed.feed.map((a) {
        if (a.activityId == activityId) {
          return Activity(
            activityId: a.activityId,
            userId: a.userId,
            username: a.username,
            userAvatarId: a.userAvatarId,
            type: a.type,
            visibility: a.visibility,
            title: a.title,
            description: a.description,
            imageId: a.imageId,
            data: a.data,
            relatedUserId: a.relatedUserId,
            relatedUsername: a.relatedUsername,
            likeCount: a.likeCount > 0 ? a.likeCount - 1 : 0,
            commentCount: a.commentCount,
            isLikedByCurrentUser: false,
            createdAt: a.createdAt,
            updatedAt: DateTime.now(),
            actionUrl: a.actionUrl,
          );
        }
        return a;
      }).toList();

      final newLikedIds = collection.feed.likedActivityIds
          .where((id) => id != activityId)
          .toList();
      final stats = _calculateStats(collection.stats, updatedActivities);

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: updatedActivities,
        comments: collection.feed.comments,
        likedActivityIds: newLikedIds,
        followingUserIds: collection.feed.followingUserIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Comment on activity
  Future<bool> commentOnActivity(
    String userId,
    String activityId,
    String username,
    String? userAvatarId,
    String content,
  ) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final comment = ActivityComment(
        commentId: _generateId('comment'),
        activityId: activityId,
        userId: userId,
        username: username,
        userAvatarId: userAvatarId,
        content: content,
        createdAt: DateTime.now(),
      );

      // Add comment
      final newComments = Map<String, List<ActivityComment>>.from(collection.feed.comments);
      if (!newComments.containsKey(activityId)) {
        newComments[activityId] = [];
      }
      newComments[activityId] = [comment, ...newComments[activityId]!].take(100).toList();

      // Update activity comment count
      final updatedActivities = collection.feed.feed.map((a) {
        if (a.activityId == activityId) {
          return Activity(
            activityId: a.activityId,
            userId: a.userId,
            username: a.username,
            userAvatarId: a.userAvatarId,
            type: a.type,
            visibility: a.visibility,
            title: a.title,
            description: a.description,
            imageId: a.imageId,
            data: a.data,
            relatedUserId: a.relatedUserId,
            relatedUsername: a.relatedUsername,
            likeCount: a.likeCount,
            commentCount: a.commentCount + 1,
            isLikedByCurrentUser: a.isLikedByCurrentUser,
            createdAt: a.createdAt,
            updatedAt: DateTime.now(),
            actionUrl: a.actionUrl,
          );
        }
        return a;
      }).toList();

      final stats = _calculateStats(collection.stats, updatedActivities);

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: updatedActivities,
        comments: newComments,
        likedActivityIds: collection.feed.likedActivityIds,
        followingUserIds: collection.feed.followingUserIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(
    String userId,
    String activityId,
    String commentId,
  ) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      // Remove comment
      final newComments = Map<String, List<ActivityComment>>.from(collection.feed.comments);
      if (newComments.containsKey(activityId)) {
        newComments[activityId] = newComments[activityId]!
            .where((c) => c.commentId != commentId)
            .toList();
        if (newComments[activityId]!.isEmpty) {
          newComments.remove(activityId);
        }
      }

      // Update activity comment count
      final updatedActivities = collection.feed.feed.map((a) {
        if (a.activityId == activityId) {
          return Activity(
            activityId: a.activityId,
            userId: a.userId,
            username: a.username,
            userAvatarId: a.userAvatarId,
            type: a.type,
            visibility: a.visibility,
            title: a.title,
            description: a.description,
            imageId: a.imageId,
            data: a.data,
            relatedUserId: a.relatedUserId,
            relatedUsername: a.relatedUsername,
            likeCount: a.likeCount,
            commentCount: a.commentCount > 0 ? a.commentCount - 1 : 0,
            isLikedByCurrentUser: a.isLikedByCurrentUser,
            createdAt: a.createdAt,
            updatedAt: DateTime.now(),
            actionUrl: a.actionUrl,
          );
        }
        return a;
      }).toList();

      final stats = _calculateStats(collection.stats, updatedActivities);

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: updatedActivities,
        comments: newComments,
        likedActivityIds: collection.feed.likedActivityIds,
        followingUserIds: collection.feed.followingUserIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete activity
  Future<bool> deleteActivity(String userId, String activityId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedActivities =
          collection.feed.feed.where((a) => a.activityId != activityId).toList();

      // Remove comments for this activity
      final newComments = Map<String, List<ActivityComment>>.from(collection.feed.comments);
      newComments.remove(activityId);

      final stats = _calculateStats(collection.stats, updatedActivities);

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: updatedActivities,
        comments: newComments,
        likedActivityIds: collection.feed.likedActivityIds,
        followingUserIds: collection.feed.followingUserIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Follow user
  Future<bool> followUser(String userId, String targetUserId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      // Check if already following
      if (collection.feed.followingUserIds.contains(targetUserId)) {
        return true;
      }

      final newFollowingIds = [...collection.feed.followingUserIds, targetUserId];

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: collection.feed.feed,
        comments: collection.feed.comments,
        likedActivityIds: collection.feed.likedActivityIds,
        followingUserIds: newFollowingIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final stats = _updateFollowingStats(collection.stats, newFollowingIds.length);

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Unfollow user
  Future<bool> unfollowUser(String userId, String targetUserId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final newFollowingIds = collection.feed.followingUserIds
          .where((id) => id != targetUserId)
          .toList();

      final updatedFeed = ActivityFeed(
        userId: collection.feed.userId,
        feed: collection.feed.feed,
        comments: collection.feed.comments,
        likedActivityIds: collection.feed.likedActivityIds,
        followingUserIds: newFollowingIds,
        lastFetchedAt: collection.feed.lastFetchedAt,
        generatedAt: DateTime.now(),
      );

      final stats = _updateFollowingStats(collection.stats, newFollowingIds.length);

      final updatedCollection = ActivityFeedCollection(
        userId: collection.userId,
        feed: updatedFeed,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistActivityFeed(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get unread activity count
  int getUnreadActivityCount() => state.collection?.feed.feed.length ?? 0;

  /// Get total comments count
  int getTotalCommentsCount() =>
      state.collection?.feed.comments.values.fold(0, (sum, comments) => sum + comments.length) ??
      0;

  /// Get total likes count
  int getTotalLikesCount() =>
      state.collection?.feed.feed.fold(0, (sum, activity) => sum + activity.likeCount) ?? 0;

  /// Clear recently created
  void clearRecentlyCreated() {
    state = state.copyWith(recentActivityIds: []);
  }

  /// Calculate updated stats
  ActivityStats _calculateStats(
    ActivityStats oldStats,
    List<Activity> activities,
  ) {
    final countByType = <ActivityType, int>{};
    var totalComments = 0;
    var totalLikes = 0;

    for (final activity in activities) {
      countByType[activity.type] = (countByType[activity.type] ?? 0) + 1;
      totalComments += activity.commentCount;
      totalLikes += activity.likeCount;
    }

    return ActivityStats(
      userId: oldStats.userId,
      totalActivities: activities.length,
      totalComments: totalComments,
      totalLikes: totalLikes,
      totalFollowers: oldStats.totalFollowers,
      totalFollowing: oldStats.totalFollowing,
      countByType: countByType,
      firstActivityAt: activities.isNotEmpty
          ? activities.last.createdAt
          : oldStats.firstActivityAt,
      lastActivityAt: activities.isNotEmpty
          ? activities.first.createdAt
          : oldStats.lastActivityAt,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Update following stats
  ActivityStats _updateFollowingStats(ActivityStats oldStats, int followingCount) {
    return ActivityStats(
      userId: oldStats.userId,
      totalActivities: oldStats.totalActivities,
      totalComments: oldStats.totalComments,
      totalLikes: oldStats.totalLikes,
      totalFollowers: oldStats.totalFollowers,
      totalFollowing: followingCount,
      countByType: oldStats.countByType,
      firstActivityAt: oldStats.firstActivityAt,
      lastActivityAt: oldStats.lastActivityAt,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Create default stats
  ActivityStats _createDefaultStats(String userId) {
    return ActivityStats(
      userId: userId,
      totalActivities: 0,
      totalComments: 0,
      totalLikes: 0,
      totalFollowers: 0,
      totalFollowing: 0,
      countByType: {},
      firstActivityAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
  }

  Future<void> _persistActivityFeed(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection = state.collection;
      if (collection != null) {
        // Persist feed
        await prefs.setString(
          'activity_feed_$userId',
          collection.feed.toJson().toString(),
        );

        // Persist comments
        final commentsJson = collection.feed.comments.map(
          (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
        );
        await prefs.setString(
          'activity_comments_$userId',
          commentsJson.toString(),
        );

        // Persist liked IDs
        await prefs.setStringList(
          'liked_activities_$userId',
          collection.feed.likedActivityIds,
        );
      }
    } catch (e) {
      // Silently fail
    }
  }
}

final activityFeedProvider = StateNotifierProvider.autoDispose<ActivityFeedNotifier, ActivityFeedState>(
  (ref) => ActivityFeedNotifier(),
);

final activityFeedCollectionProvider = Provider.autoDispose<ActivityFeedCollection?>(
  (ref) => ref.watch(activityFeedProvider).collection,
);

final activitiesProvider = Provider.autoDispose<List<Activity>>(
  (ref) => ref.watch(activityFeedProvider).collection?.feed.feed ?? [],
);

final activityCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(activityFeedProvider).collection?.feed.feed.length ?? 0,
);

final activitiesByTypeProvider = Provider.autoDispose.family<List<Activity>, ActivityType>(
  (ref, type) => ref.watch(activityFeedProvider).collection?.feed.getByType(type) ?? [],
);

final activitiesByVisibilityProvider =
    Provider.autoDispose.family<List<Activity>, ActivityVisibility>(
  (ref, visibility) =>
      ref.watch(activityFeedProvider).collection?.feed.feed
          .where((a) => a.visibility == visibility)
          .toList() ??
      [],
);

final todayActivitiesProvider = Provider.autoDispose<List<Activity>>(
  (ref) => ref.watch(activityFeedProvider).collection?.feed.getTodayActivities() ?? [],
);

final followingActivitiesProvider = Provider.autoDispose<List<Activity>>(
  (ref) => ref.watch(activityFeedProvider).collection?.feed.getFollowingActivities() ?? [],
);

final publicActivitiesProvider = Provider.autoDispose<List<Activity>>(
  (ref) => ref.watch(activityFeedProvider).collection?.feed.getPublicActivities() ?? [],
);

final recentActivitiesProvider = Provider.autoDispose.family<List<Activity>, int>(
  (ref, days) => ref.watch(activityFeedProvider).collection?.feed.getRecent(days) ?? [],
);

final activityCommentsProvider = Provider.autoDispose.family<List<ActivityComment>, String>(
  (ref, activityId) =>
      ref.watch(activityFeedProvider).collection?.feed.getComments(activityId) ?? [],
);

final activityStatsProvider = Provider.autoDispose<ActivityStats?>(
  (ref) => ref.watch(activityFeedProvider).collection?.stats,
);

final likedActivitiesProvider = Provider.autoDispose<List<String>>(
  (ref) => ref.watch(activityFeedProvider).collection?.feed.likedActivityIds ?? [],
);

final followingUsersProvider = Provider.autoDispose<List<String>>(
  (ref) => ref.watch(activityFeedProvider).collection?.feed.followingUserIds ?? [],
);
