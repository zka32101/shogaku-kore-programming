/// Types of activities that appear in the feed
enum ActivityType {
  achievementUnlocked,    // User unlocked achievement
  challengeCompleted,     // User completed challenge
  levelUp,                // User leveled up
  rankChanged,            // User rank changed
  streakMilestone,        // User reached streak milestone
  itemPurchased,          // User purchased item
  friendAdded,            // User added friend
  commentPosted,          // User posted comment
  contentShared,          // User shared content
  customEvent,            // Custom activity event
}

/// Activity visibility/privacy settings
enum ActivityVisibility {
  public,     // Visible to all users
  friends,    // Visible to friends only
  private,    // Private (only user sees it)
}

/// Individual activity entry
class Activity {
  final String activityId;
  final String userId;
  final String username;           // User's display name
  final String? userAvatarId;      // User's avatar
  final ActivityType type;
  final ActivityVisibility visibility;
  final String title;              // Activity title (Japanese)
  final String description;        // Activity description
  final String? imageId;           // Optional image/icon
  final Map<String, dynamic>? data; // Additional data (achievement ID, etc.)
  final int? relatedUserId;        // If activity involves another user
  final String? relatedUsername;   // Related user's name
  final int likeCount;             // Number of likes
  final int commentCount;          // Number of comments
  final bool isLikedByCurrentUser; // If current user liked it
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? actionUrl;         // Deep link to related content

  Activity({
    required this.activityId,
    required this.userId,
    required this.username,
    this.userAvatarId,
    required this.type,
    required this.visibility,
    required this.title,
    required this.description,
    this.imageId,
    this.data,
    this.relatedUserId,
    this.relatedUsername,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
    required this.createdAt,
    this.updatedAt,
    this.actionUrl,
  });

  /// Check if activity is recent (within last 24 hours)
  bool get isRecent => DateTime.now().difference(createdAt).inHours < 24;

  /// Get time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}週間前';
    return '${diff.inDays ~/ 30}ヶ月前';
  }

  /// Check if activity is from today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'userId': userId,
        'username': username,
        'userAvatarId': userAvatarId,
        'type': type.name,
        'visibility': visibility.name,
        'title': title,
        'description': description,
        'imageId': imageId,
        'data': data,
        'relatedUserId': relatedUserId,
        'relatedUsername': relatedUsername,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'isLikedByCurrentUser': isLikedByCurrentUser,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'actionUrl': actionUrl,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        activityId: json['activityId'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String,
        userAvatarId: json['userAvatarId'] as String?,
        type: ActivityType.values.byName(json['type'] as String),
        visibility: ActivityVisibility.values.byName(json['visibility'] as String),
        title: json['title'] as String,
        description: json['description'] as String,
        imageId: json['imageId'] as String?,
        data: json['data'] as Map<String, dynamic>?,
        relatedUserId: json['relatedUserId'] as int?,
        relatedUsername: json['relatedUsername'] as String?,
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        actionUrl: json['actionUrl'] as String?,
      );
}

/// Activity comment
class ActivityComment {
  final String commentId;
  final String activityId;
  final String userId;
  final String username;
  final String? userAvatarId;
  final String content;          // Comment text
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;

  ActivityComment({
    required this.commentId,
    required this.activityId,
    required this.userId,
    required this.username,
    this.userAvatarId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
  });

  /// Get time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }

  Map<String, dynamic> toJson() => {
        'commentId': commentId,
        'activityId': activityId,
        'userId': userId,
        'username': username,
        'userAvatarId': userAvatarId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'likeCount': likeCount,
      };

  factory ActivityComment.fromJson(Map<String, dynamic> json) => ActivityComment(
        commentId: json['commentId'] as String,
        activityId: json['activityId'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String,
        userAvatarId: json['userAvatarId'] as String?,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        likeCount: json['likeCount'] as int? ?? 0,
      );
}

/// User's activity feed
class ActivityFeed {
  final String userId;
  final List<Activity> feed;                    // User's feed (max 500)
  final Map<String, List<ActivityComment>> comments; // activityId -> comments
  final List<String> likedActivityIds;         // Activity IDs user liked
  final List<String> followingUserIds;         // Users this user follows
  final DateTime? lastFetchedAt;
  final DateTime generatedAt;

  ActivityFeed({
    required this.userId,
    required this.feed,
    required this.comments,
    required this.likedActivityIds,
    required this.followingUserIds,
    this.lastFetchedAt,
    required this.generatedAt,
  });

  /// Get comments for an activity
  List<ActivityComment> getComments(String activityId) =>
      comments[activityId] ?? [];

  /// Check if user liked an activity
  bool hasLiked(String activityId) => likedActivityIds.contains(activityId);

  /// Get activities from today
  List<Activity> getTodayActivities() => feed.where((a) => a.isToday).toList();

  /// Get recent activities (last N days)
  List<Activity> getRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return feed.where((a) => a.createdAt.isAfter(cutoff)).toList();
  }

  /// Get activities by type
  List<Activity> getByType(ActivityType type) =>
      feed.where((a) => a.type == type).toList();

  /// Get activities from following users
  List<Activity> getFollowingActivities() =>
      feed.where((a) => followingUserIds.contains(a.userId)).toList();

  /// Get public activities
  List<Activity> getPublicActivities() =>
      feed.where((a) => a.visibility == ActivityVisibility.public).toList();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'feed': feed.map((a) => a.toJson()).toList(),
        'comments': comments.map(
          (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
        ),
        'likedActivityIds': likedActivityIds,
        'followingUserIds': followingUserIds,
        'lastFetchedAt': lastFetchedAt?.toIso8601String(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ActivityFeed.fromJson(Map<String, dynamic> json) => ActivityFeed(
        userId: json['userId'] as String,
        feed: ((json['feed'] as List?) ?? [])
            .map((a) => Activity.fromJson(a as Map<String, dynamic>))
            .toList(),
        comments: ((json['comments'] as Map<String, dynamic>?) ?? {}).map(
          (key, value) => MapEntry(
            key,
            ((value as List?) ?? [])
                .map((c) => ActivityComment.fromJson(c as Map<String, dynamic>))
                .toList(),
          ),
        ),
        likedActivityIds: ((json['likedActivityIds'] as List?) ?? [])
            .map((id) => id as String)
            .toList(),
        followingUserIds: ((json['followingUserIds'] as List?) ?? [])
            .map((id) => id as String)
            .toList(),
        lastFetchedAt: json['lastFetchedAt'] != null
            ? DateTime.parse(json['lastFetchedAt'] as String)
            : null,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}

/// Activity statistics
class ActivityStats {
  final String userId;
  final int totalActivities;
  final int totalComments;
  final int totalLikes;
  final int totalFollowers;
  final int totalFollowing;
  final Map<ActivityType, int> countByType;
  final DateTime firstActivityAt;
  final DateTime lastActivityAt;
  final DateTime lastUpdatedAt;

  ActivityStats({
    required this.userId,
    required this.totalActivities,
    required this.totalComments,
    required this.totalLikes,
    required this.totalFollowers,
    required this.totalFollowing,
    required this.countByType,
    required this.firstActivityAt,
    required this.lastActivityAt,
    required this.lastUpdatedAt,
  });

  /// Get activity count for specific type
  int getTypeCount(ActivityType type) => countByType[type] ?? 0;

  /// Get engagement score (activities + comments + likes)
  int getEngagementScore() => totalActivities + totalComments + totalLikes;

  /// Get follower/following ratio
  double get followerRatio =>
      totalFollowing == 0 ? 0 : totalFollowers / totalFollowing;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalActivities': totalActivities,
        'totalComments': totalComments,
        'totalLikes': totalLikes,
        'totalFollowers': totalFollowers,
        'totalFollowing': totalFollowing,
        'countByType': countByType.map((k, v) => MapEntry(k.name, v)),
        'firstActivityAt': firstActivityAt.toIso8601String(),
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    final typeMap = (json['countByType'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(ActivityType.values.byName(k), v as int));

    return ActivityStats(
      userId: json['userId'] as String,
      totalActivities: json['totalActivities'] as int,
      totalComments: json['totalComments'] as int,
      totalLikes: json['totalLikes'] as int,
      totalFollowers: json['totalFollowers'] as int,
      totalFollowing: json['totalFollowing'] as int,
      countByType: typeMap,
      firstActivityAt: DateTime.parse(json['firstActivityAt'] as String),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }
}

/// Complete activity feed collection
class ActivityFeedCollection {
  final String userId;
  final ActivityFeed feed;
  final ActivityStats stats;
  final DateTime generatedAt;

  ActivityFeedCollection({
    required this.userId,
    required this.feed,
    required this.stats,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'feed': feed.toJson(),
        'stats': stats.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ActivityFeedCollection.fromJson(Map<String, dynamic> json) =>
      ActivityFeedCollection(
        userId: json['userId'] as String,
        feed: ActivityFeed.fromJson(json['feed'] as Map<String, dynamic>),
        stats: ActivityStats.fromJson(json['stats'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
