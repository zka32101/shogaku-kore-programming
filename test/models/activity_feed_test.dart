import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/activity_feed.dart';

void main() {
  group('ActivityType Enum', () {
    test('has all expected types', () {
      expect(ActivityType.values.length, 10);
      expect(ActivityType.values, contains(ActivityType.achievementUnlocked));
      expect(ActivityType.values, contains(ActivityType.levelUp));
    });

    test('can convert to string', () {
      expect(ActivityType.achievementUnlocked.name, 'achievementUnlocked');
      expect(ActivityType.challengeCompleted.name, 'challengeCompleted');
    });
  });

  group('ActivityVisibility Enum', () {
    test('has all expected visibilities', () {
      expect(ActivityVisibility.values.length, 3);
      expect(ActivityVisibility.values, contains(ActivityVisibility.public));
      expect(ActivityVisibility.values, contains(ActivityVisibility.friends));
      expect(ActivityVisibility.values, contains(ActivityVisibility.private));
    });
  });

  group('Activity', () {
    test('creates activity with required fields', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        type: ActivityType.achievementUnlocked,
        visibility: ActivityVisibility.public,
        title: 'アチーブメント獲得',
        description: 'バッジを獲得しました',
        createdAt: now,
      );

      expect(activity.activityId, 'act1');
      expect(activity.userId, 'user1');
      expect(activity.username, 'testuser');
      expect(activity.type, ActivityType.achievementUnlocked);
      expect(activity.visibility, ActivityVisibility.public);
      expect(activity.title, 'アチーブメント獲得');
      expect(activity.likeCount, 0);
      expect(activity.commentCount, 0);
      expect(activity.isLikedByCurrentUser, false);
    });

    test('isRecent returns true for recent activities', () {
      final recentTime = DateTime.now().subtract(const Duration(hours: 12));
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'レベルアップ',
        description: 'レベルが上がった',
        createdAt: recentTime,
      );

      expect(activity.isRecent, true);
    });

    test('isRecent returns false for old activities', () {
      final oldTime = DateTime.now().subtract(const Duration(hours: 25));
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'レベルアップ',
        description: 'レベルが上がった',
        createdAt: oldTime,
      );

      expect(activity.isRecent, false);
    });

    test('isToday returns true for today activities', () {
      final today = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'レベルアップ',
        description: 'レベルが上がった',
        createdAt: today,
      );

      expect(activity.isToday, true);
    });

    test('isToday returns false for yesterday activities', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'レベルアップ',
        description: 'レベルが上がった',
        createdAt: yesterday,
      );

      expect(activity.isToday, false);
    });

    test('timeAgo returns correct format', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'レベルアップ',
        description: 'レベルが上がった',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(activity.timeAgo, '5分前');
    });

    test('timeAgo returns "今" for activities just created', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'レベルアップ',
        description: 'レベルが上がった',
        createdAt: now.subtract(const Duration(seconds: 5)),
      );

      expect(activity.timeAgo, '今');
    });

    test('toJson serializes activity', () {
      final now = DateTime.now();
      final activity = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        userAvatarId: 'avatar1',
        type: ActivityType.achievementUnlocked,
        visibility: ActivityVisibility.public,
        title: 'アチーブメント',
        description: 'バッジ獲得',
        imageId: 'img1',
        data: {'achievementId': 'badge_7day'},
        relatedUserId: 2,
        relatedUsername: 'related',
        likeCount: 5,
        commentCount: 3,
        isLikedByCurrentUser: true,
        createdAt: now,
        updatedAt: now,
        actionUrl: 'app://achievement/badge_7day',
      );

      final json = activity.toJson();

      expect(json['activityId'], 'act1');
      expect(json['userId'], 'user1');
      expect(json['username'], 'testuser');
      expect(json['type'], 'achievementUnlocked');
      expect(json['visibility'], 'public');
      expect(json['likeCount'], 5);
      expect(json['commentCount'], 3);
      expect(json['isLikedByCurrentUser'], true);
    });

    test('fromJson deserializes activity', () {
      final now = DateTime.now();
      final json = {
        'activityId': 'act1',
        'userId': 'user1',
        'username': 'testuser',
        'userAvatarId': 'avatar1',
        'type': 'achievementUnlocked',
        'visibility': 'public',
        'title': 'アチーブメント',
        'description': 'バッジ獲得',
        'imageId': 'img1',
        'data': {'achievementId': 'badge_7day'},
        'relatedUserId': 2,
        'relatedUsername': 'related',
        'likeCount': 5,
        'commentCount': 3,
        'isLikedByCurrentUser': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'actionUrl': 'app://achievement/badge_7day',
      };

      final activity = Activity.fromJson(json);

      expect(activity.activityId, 'act1');
      expect(activity.userId, 'user1');
      expect(activity.type, ActivityType.achievementUnlocked);
      expect(activity.visibility, ActivityVisibility.public);
      expect(activity.likeCount, 5);
    });

    test('fromJson handles missing optional fields', () {
      final now = DateTime.now();
      final json = {
        'activityId': 'act1',
        'userId': 'user1',
        'username': 'testuser',
        'type': 'levelUp',
        'visibility': 'private',
        'title': 'レベル',
        'description': '説明',
        'createdAt': now.toIso8601String(),
      };

      final activity = Activity.fromJson(json);

      expect(activity.userAvatarId, isNull);
      expect(activity.imageId, isNull);
      expect(activity.data, isNull);
      expect(activity.likeCount, 0);
      expect(activity.commentCount, 0);
      expect(activity.isLikedByCurrentUser, false);
    });
  });

  group('ActivityComment', () {
    test('creates comment with required fields', () {
      final now = DateTime.now();
      final comment = ActivityComment(
        commentId: 'comment1',
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        content: 'これは素晴らしい',
        createdAt: now,
      );

      expect(comment.commentId, 'comment1');
      expect(comment.activityId, 'act1');
      expect(comment.userId, 'user1');
      expect(comment.content, 'これは素晴らしい');
      expect(comment.likeCount, 0);
    });

    test('timeAgo returns correct format', () {
      final now = DateTime.now();
      final comment = ActivityComment(
        commentId: 'comment1',
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        content: 'comment',
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      expect(comment.timeAgo, '2時間前');
    });

    test('toJson serializes comment', () {
      final now = DateTime.now();
      final comment = ActivityComment(
        commentId: 'comment1',
        activityId: 'act1',
        userId: 'user1',
        username: 'testuser',
        userAvatarId: 'avatar1',
        content: 'comment text',
        createdAt: now,
        updatedAt: now,
        likeCount: 2,
      );

      final json = comment.toJson();

      expect(json['commentId'], 'comment1');
      expect(json['activityId'], 'act1');
      expect(json['content'], 'comment text');
      expect(json['likeCount'], 2);
    });

    test('fromJson deserializes comment', () {
      final now = DateTime.now();
      final json = {
        'commentId': 'comment1',
        'activityId': 'act1',
        'userId': 'user1',
        'username': 'testuser',
        'userAvatarId': 'avatar1',
        'content': 'comment text',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'likeCount': 2,
      };

      final comment = ActivityComment.fromJson(json);

      expect(comment.commentId, 'comment1');
      expect(comment.content, 'comment text');
      expect(comment.likeCount, 2);
    });
  });

  group('ActivityFeed', () {
    test('creates feed with required fields', () {
      final now = DateTime.now();
      final feed = ActivityFeed(
        userId: 'user1',
        feed: [],
        comments: {},
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: now,
      );

      expect(feed.userId, 'user1');
      expect(feed.feed, isEmpty);
      expect(feed.comments, isEmpty);
      expect(feed.likedActivityIds, isEmpty);
      expect(feed.followingUserIds, isEmpty);
    });

    test('getComments returns comments for activity', () {
      final now = DateTime.now();
      final comment1 = ActivityComment(
        commentId: 'c1',
        activityId: 'act1',
        userId: 'user2',
        username: 'user2',
        content: 'comment1',
        createdAt: now,
      );
      final comment2 = ActivityComment(
        commentId: 'c2',
        activityId: 'act1',
        userId: 'user3',
        username: 'user3',
        content: 'comment2',
        createdAt: now,
      );

      final feed = ActivityFeed(
        userId: 'user1',
        feed: [],
        comments: {
          'act1': [comment1, comment2],
        },
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: now,
      );

      final comments = feed.getComments('act1');
      expect(comments.length, 2);
      expect(comments[0].commentId, 'c1');
    });

    test('getComments returns empty list for activity without comments', () {
      final now = DateTime.now();
      final feed = ActivityFeed(
        userId: 'user1',
        feed: [],
        comments: {},
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: now,
      );

      final comments = feed.getComments('act1');
      expect(comments, isEmpty);
    });

    test('hasLiked returns true for liked activities', () {
      final now = DateTime.now();
      final feed = ActivityFeed(
        userId: 'user1',
        feed: [],
        comments: {},
        likedActivityIds: ['act1', 'act2'],
        followingUserIds: [],
        generatedAt: now,
      );

      expect(feed.hasLiked('act1'), true);
      expect(feed.hasLiked('act2'), true);
      expect(feed.hasLiked('act3'), false);
    });

    test('getTodayActivities filters by date', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final activity1 = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'user1',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'title',
        description: 'desc',
        createdAt: today,
      );

      final activity2 = Activity(
        activityId: 'act2',
        userId: 'user1',
        username: 'user1',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'title',
        description: 'desc',
        createdAt: yesterday,
      );

      final feed = ActivityFeed(
        userId: 'user1',
        feed: [activity1, activity2],
        comments: {},
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: today,
      );

      final todayActivities = feed.getTodayActivities();
      expect(todayActivities.length, 1);
      expect(todayActivities[0].activityId, 'act1');
    });

    test('getByType filters by activity type', () {
      final now = DateTime.now();
      final activity1 = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'user1',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'title',
        description: 'desc',
        createdAt: now,
      );

      final activity2 = Activity(
        activityId: 'act2',
        userId: 'user1',
        username: 'user1',
        type: ActivityType.achievementUnlocked,
        visibility: ActivityVisibility.public,
        title: 'title',
        description: 'desc',
        createdAt: now,
      );

      final feed = ActivityFeed(
        userId: 'user1',
        feed: [activity1, activity2],
        comments: {},
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: now,
      );

      final levelUpActivities = feed.getByType(ActivityType.levelUp);
      expect(levelUpActivities.length, 1);
      expect(levelUpActivities[0].type, ActivityType.levelUp);
    });

    test('getFollowingActivities filters by following users', () {
      final now = DateTime.now();
      final activity1 = Activity(
        activityId: 'act1',
        userId: 'user2',
        username: 'user2',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'title',
        description: 'desc',
        createdAt: now,
      );

      final activity2 = Activity(
        activityId: 'act2',
        userId: 'user3',
        username: 'user3',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'title',
        description: 'desc',
        createdAt: now,
      );

      final feed = ActivityFeed(
        userId: 'user1',
        feed: [activity1, activity2],
        comments: {},
        likedActivityIds: [],
        followingUserIds: ['user2'],
        generatedAt: now,
      );

      final followingActivities = feed.getFollowingActivities();
      expect(followingActivities.length, 1);
      expect(followingActivities[0].userId, 'user2');
    });

    test('getPublicActivities filters by visibility', () {
      final now = DateTime.now();
      final activity1 = Activity(
        activityId: 'act1',
        userId: 'user1',
        username: 'user1',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.public,
        title: 'title',
        description: 'desc',
        createdAt: now,
      );

      final activity2 = Activity(
        activityId: 'act2',
        userId: 'user1',
        username: 'user1',
        type: ActivityType.levelUp,
        visibility: ActivityVisibility.private,
        title: 'title',
        description: 'desc',
        createdAt: now,
      );

      final feed = ActivityFeed(
        userId: 'user1',
        feed: [activity1, activity2],
        comments: {},
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: now,
      );

      final publicActivities = feed.getPublicActivities();
      expect(publicActivities.length, 1);
      expect(publicActivities[0].visibility, ActivityVisibility.public);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final feed = ActivityFeed(
        userId: 'user1',
        feed: [],
        comments: {},
        likedActivityIds: ['act1'],
        followingUserIds: ['user2'],
        lastFetchedAt: now,
        generatedAt: now,
      );

      final json = feed.toJson();
      final restored = ActivityFeed.fromJson(json);

      expect(restored.userId, feed.userId);
      expect(restored.likedActivityIds, feed.likedActivityIds);
      expect(restored.followingUserIds, feed.followingUserIds);
    });
  });

  group('ActivityStats', () {
    test('creates stats with required fields', () {
      final now = DateTime.now();
      final stats = ActivityStats(
        userId: 'user1',
        totalActivities: 10,
        totalComments: 5,
        totalLikes: 20,
        totalFollowers: 50,
        totalFollowing: 30,
        countByType: {},
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalActivities, 10);
      expect(stats.totalComments, 5);
      expect(stats.totalLikes, 20);
      expect(stats.totalFollowers, 50);
      expect(stats.totalFollowing, 30);
    });

    test('getTypeCount returns count for type', () {
      final now = DateTime.now();
      final stats = ActivityStats(
        userId: 'user1',
        totalActivities: 10,
        totalComments: 5,
        totalLikes: 20,
        totalFollowers: 50,
        totalFollowing: 30,
        countByType: {
          ActivityType.levelUp: 5,
          ActivityType.achievementUnlocked: 3,
        },
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.getTypeCount(ActivityType.levelUp), 5);
      expect(stats.getTypeCount(ActivityType.achievementUnlocked), 3);
      expect(stats.getTypeCount(ActivityType.challengeCompleted), 0);
    });

    test('followerRatio calculates correctly', () {
      final now = DateTime.now();
      final stats = ActivityStats(
        userId: 'user1',
        totalActivities: 10,
        totalComments: 5,
        totalLikes: 20,
        totalFollowers: 100,
        totalFollowing: 50,
        countByType: {},
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.followerRatio, 2.0);
    });

    test('followerRatio returns 0 when no following', () {
      final now = DateTime.now();
      final stats = ActivityStats(
        userId: 'user1',
        totalActivities: 10,
        totalComments: 5,
        totalLikes: 20,
        totalFollowers: 100,
        totalFollowing: 0,
        countByType: {},
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.followerRatio, 0);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = ActivityStats(
        userId: 'user1',
        totalActivities: 10,
        totalComments: 5,
        totalLikes: 20,
        totalFollowers: 50,
        totalFollowing: 30,
        countByType: {
          ActivityType.levelUp: 5,
          ActivityType.achievementUnlocked: 3,
        },
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      final restored = ActivityStats.fromJson(json);

      expect(restored.userId, stats.userId);
      expect(restored.totalActivities, stats.totalActivities);
      expect(restored.totalComments, stats.totalComments);
    });
  });

  group('ActivityFeedCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final feed = ActivityFeed(
        userId: 'user1',
        feed: [],
        comments: {},
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: now,
      );
      final stats = ActivityStats(
        userId: 'user1',
        totalActivities: 0,
        totalComments: 0,
        totalLikes: 0,
        totalFollowers: 0,
        totalFollowing: 0,
        countByType: {},
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityFeedCollection(
        userId: 'user1',
        feed: feed,
        stats: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.feed.feed, isEmpty);
      expect(collection.stats.totalActivities, 0);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final feed = ActivityFeed(
        userId: 'user1',
        feed: [],
        comments: {},
        likedActivityIds: [],
        followingUserIds: [],
        generatedAt: now,
      );
      final stats = ActivityStats(
        userId: 'user1',
        totalActivities: 0,
        totalComments: 0,
        totalLikes: 0,
        totalFollowers: 0,
        totalFollowing: 0,
        countByType: {},
        firstActivityAt: now,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final collection = ActivityFeedCollection(
        userId: 'user1',
        feed: feed,
        stats: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = ActivityFeedCollection.fromJson(json);

      expect(restored.userId, collection.userId);
      expect(restored.feed.userId, collection.feed.userId);
    });
  });
}
