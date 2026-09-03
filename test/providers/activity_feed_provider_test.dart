import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/activity_feed.dart';
import 'package:shogaku_kore_programming/providers/activity_feed_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('ActivityFeedNotifier', () {
    test('initializes with empty state', () {
      final notifier = ActivityFeedNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeActivityFeed creates default feed', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final state = container.read(activityFeedProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
      expect(state.collection!.feed.feed, isEmpty);
    });

    test('initializeActivityFeed creates empty activity list', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.isEmpty, true);
      expect(state.collection!.stats.totalActivities, 0);
    });

    test('addActivity creates new activity', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final success = await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'アチーブメント',
        'バッジを獲得しました',
      );

      expect(success, true);

      final state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.length, 1);
      expect(state.collection!.stats.totalActivities, 1);
    });

    test('addActivity supports custom data', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final success = await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test message',
        data: {'achievementId': 'badge_7day', 'xpReward': 100},
      );

      expect(success, true);

      final state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.first.data?['achievementId'], 'badge_7day');
    });

    test('addActivity increments recent activity list', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      var state = container.read(activityFeedProvider);
      expect(state.recentActivityIds, isEmpty);

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Level Up',
        'You leveled up',
      );

      state = container.read(activityFeedProvider);
      expect(state.recentActivityIds.length, 1);
    });

    test('likeActivity updates like count', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;
      expect(state.collection!.feed.feed.first.likeCount, 0);

      await notifier.likeActivity('test_user', activityId);

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.first.likeCount, 1);
      expect(state.collection!.feed.likedActivityIds.contains(activityId), true);
    });

    test('likeActivity sets isLikedByCurrentUser', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.likeActivity('test_user', activityId);

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.first.isLikedByCurrentUser, true);
    });

    test('unlikeActivity decreases like count', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.likeActivity('test_user', activityId);
      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.first.likeCount, 1);

      await notifier.unlikeActivity('test_user', activityId);

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.first.likeCount, 0);
      expect(state.collection!.feed.likedActivityIds.contains(activityId), false);
    });

    test('commentOnActivity adds comment and increments count', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      final success = await notifier.commentOnActivity(
        'user2',
        activityId,
        'commenter',
        null,
        'これは良い',
      );

      expect(success, true);

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.first.commentCount, 1);
      expect(state.collection!.feed.comments[activityId]?.length, 1);
    });

    test('commentOnActivity preserves previous comments', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.commentOnActivity('user2', activityId, 'user2', null, 'comment 1');
      await notifier.commentOnActivity('user3', activityId, 'user3', null, 'comment 2');

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.comments[activityId]?.length, 2);
    });

    test('deleteComment decreases comment count', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.commentOnActivity('user2', activityId, 'user2', null, 'comment');

      state = container.read(activityFeedProvider);
      final commentId = state.collection!.feed.comments[activityId]!.first.commentId;

      await notifier.deleteComment('test_user', activityId, commentId);

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.first.commentCount, 0);
    });

    test('deleteActivity removes activity', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;
      expect(state.collection!.feed.feed.length, 1);

      await notifier.deleteActivity('test_user', activityId);

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.length, 0);
    });

    test('deleteActivity removes associated comments', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.commentOnActivity('user2', activityId, 'user2', null, 'comment');

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.comments.containsKey(activityId), true);

      await notifier.deleteActivity('test_user', activityId);

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.comments.containsKey(activityId), false);
    });

    test('followUser adds to following list', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      var state = container.read(activityFeedProvider);
      expect(state.collection!.feed.followingUserIds, isEmpty);

      await notifier.followUser('test_user', 'user2');

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.followingUserIds.contains('user2'), true);
      expect(state.collection!.stats.totalFollowing, 1);
    });

    test('unfollowUser removes from following list', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.followUser('test_user', 'user2');
      var state = container.read(activityFeedProvider);
      expect(state.collection!.feed.followingUserIds.contains('user2'), true);

      await notifier.unfollowUser('test_user', 'user2');

      state = container.read(activityFeedProvider);
      expect(state.collection!.feed.followingUserIds.contains('user2'), false);
      expect(state.collection!.stats.totalFollowing, 0);
    });

    test('getUnreadActivityCount returns correct count', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      expect(notifier.getUnreadActivityCount(), 0);

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test 1',
        'Test',
      );

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test 2',
        'Test',
      );

      expect(notifier.getUnreadActivityCount(), 2);
    });

    test('getTotalCommentsCount returns sum of all comments', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.commentOnActivity('user2', activityId, 'user2', null, 'c1');
      await notifier.commentOnActivity('user2', activityId, 'user2', null, 'c2');

      expect(notifier.getTotalCommentsCount(), 2);
    });

    test('getTotalLikesCount returns sum of all likes', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.likeActivity('test_user', activityId);

      expect(notifier.getTotalLikesCount(), 1);
    });

    test('clearRecentlyCreated empties list', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      expect(state.recentActivityIds.isNotEmpty, true);

      notifier.clearRecentlyCreated();

      state = container.read(activityFeedProvider);
      expect(state.recentActivityIds.isEmpty, true);
    });

    test('handles max 500 activities', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      for (int i = 0; i < 510; i++) {
        await notifier.addActivity(
          'test_user',
          'testuser',
          null,
          ActivityType.achievementUnlocked,
          ActivityVisibility.public,
          'Test $i',
          'Test message $i',
        );
      }

      final state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.length, lessThanOrEqualTo(500));
    });

    test('supports different activity types', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final types = [
        ActivityType.achievementUnlocked,
        ActivityType.levelUp,
        ActivityType.rankChanged,
      ];

      for (var type in types) {
        await notifier.addActivity(
          'test_user',
          'testuser',
          null,
          type,
          ActivityVisibility.public,
          'Test',
          'Test message',
        );
      }

      final state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.length, types.length);
    });

    test('supports different visibilities', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final visibilities = [
        ActivityVisibility.public,
        ActivityVisibility.friends,
        ActivityVisibility.private,
      ];

      for (var visibility in visibilities) {
        await notifier.addActivity(
          'test_user',
          'testuser',
          null,
          ActivityType.achievementUnlocked,
          visibility,
          'Test',
          'Test message',
        );
      }

      final state = container.read(activityFeedProvider);
      expect(state.collection!.feed.feed.length, visibilities.length);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('persist_test');

      await notifier.addActivity(
        'persist_test',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test message',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('activity_feed_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('activityFeedCollectionProvider provides collection', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final collection = container.read(activityFeedCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('activitiesProvider returns all activities', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      final activities = container.read(activitiesProvider);
      expect(activities.length, 1);
    });

    test('activityCountProvider returns activity count', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      final count = container.read(activityCountProvider);
      expect(count, 1);
    });

    test('activitiesByTypeProvider filters by type', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.achievementUnlocked,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      final levelUps = container.read(activitiesByTypeProvider(ActivityType.levelUp));
      expect(levelUps.length, 1);

      final achievements = container.read(activitiesByTypeProvider(ActivityType.achievementUnlocked));
      expect(achievements.length, 1);
    });

    test('activitiesByVisibilityProvider filters by visibility', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.private,
        'Test',
        'Test',
      );

      final public = container.read(activitiesByVisibilityProvider(ActivityVisibility.public));
      expect(public.length, 1);

      final private = container.read(activitiesByVisibilityProvider(ActivityVisibility.private));
      expect(private.length, 1);
    });

    test('todayActivitiesProvider returns today only', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      final today = container.read(todayActivitiesProvider);
      expect(today.length, 1);
    });

    test('followingActivitiesProvider filters following users', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'user2',
        'user2',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      await notifier.followUser('test_user', 'user2');

      final following = container.read(followingActivitiesProvider);
      expect(following.length, 1);
    });

    test('publicActivitiesProvider filters public only', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      final public = container.read(publicActivitiesProvider);
      expect(public.length, 1);
    });

    test('activityCommentsProvider returns comments for activity', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.commentOnActivity('user2', activityId, 'user2', null, 'comment');

      final comments = container.read(activityCommentsProvider(activityId));
      expect(comments.length, 1);
    });

    test('activityStatsProvider provides stats', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      final stats = container.read(activityStatsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('likedActivitiesProvider returns liked activity IDs', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.addActivity(
        'test_user',
        'testuser',
        null,
        ActivityType.levelUp,
        ActivityVisibility.public,
        'Test',
        'Test',
      );

      var state = container.read(activityFeedProvider);
      final activityId = state.collection!.feed.feed.first.activityId;

      await notifier.likeActivity('test_user', activityId);

      final liked = container.read(likedActivitiesProvider);
      expect(liked.contains(activityId), true);
    });

    test('followingUsersProvider returns following user IDs', () async {
      final notifier = container.read(activityFeedProvider.notifier);
      await notifier.initializeActivityFeed('test_user');

      await notifier.followUser('test_user', 'user2');
      await notifier.followUser('test_user', 'user3');

      final following = container.read(followingUsersProvider);
      expect(following.length, 2);
      expect(following.contains('user2'), true);
      expect(following.contains('user3'), true);
    });
  });
}
