import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/social.dart';

void main() {
  group('FriendshipStatus enum', () {
    test('should have all required values', () {
      expect(FriendshipStatus.pending, isNotNull);
      expect(FriendshipStatus.accepted, isNotNull);
      expect(FriendshipStatus.blocked, isNotNull);
      expect(FriendshipStatus.rejected, isNotNull);
    });
  });

  group('UserOnlineStatus enum', () {
    test('should have correct values', () {
      expect(UserOnlineStatus.online, isNotNull);
      expect(UserOnlineStatus.away, isNotNull);
      expect(UserOnlineStatus.offline, isNotNull);
    });
  });

  group('Friend', () {
    late Friend friend;

    setUp(() {
      friend = Friend(
        userId: 'user-1',
        username: 'john_doe',
        displayName: 'John Doe',
        profileImageUrl: 'https://example.com/image.jpg',
        level: 5,
        totalXp: 2500,
        lastSeenAt: DateTime.now(),
        onlineStatus: UserOnlineStatus.online,
        status: FriendshipStatus.accepted,
        connectedAt: DateTime.now().subtract(Duration(days: 30)),
      );
    });

    test('should create friend with correct values', () {
      expect(friend.userId, 'user-1');
      expect(friend.username, 'john_doe');
      expect(friend.level, 5);
      expect(friend.totalXp, 2500);
      expect(friend.status, FriendshipStatus.accepted);
    });

    test('isActive should return true for accepted friend', () {
      expect(friend.isActive, true);
    });

    test('isActive should return false for blocked friend', () {
      final blockedFriend = Friend(
        userId: 'user-2',
        username: 'blocked_user',
        displayName: 'Blocked User',
        profileImageUrl: null,
        level: 3,
        totalXp: 1500,
        lastSeenAt: DateTime.now(),
        onlineStatus: UserOnlineStatus.offline,
        status: FriendshipStatus.blocked,
        connectedAt: DateTime.now(),
        blockedAt: DateTime.now(),
      );
      expect(blockedFriend.isActive, false);
    });

    test('isBlocked should return true when status is blocked', () {
      final blockedFriend = Friend(
        userId: 'user-2',
        username: 'blocked_user',
        displayName: 'Blocked User',
        profileImageUrl: null,
        level: 3,
        totalXp: 1500,
        lastSeenAt: DateTime.now(),
        onlineStatus: UserOnlineStatus.offline,
        status: FriendshipStatus.blocked,
        connectedAt: DateTime.now(),
        blockedAt: DateTime.now(),
      );
      expect(blockedFriend.isBlocked, true);
    });

    test('should serialize/deserialize correctly', () {
      final json = friend.toJson();
      final deserialized = Friend.fromJson(json);

      expect(deserialized.userId, friend.userId);
      expect(deserialized.username, friend.username);
      expect(deserialized.level, friend.level);
      expect(deserialized.status, friend.status);
    });
  });

  group('FriendRequest', () {
    late FriendRequest request;

    setUp(() {
      request = FriendRequest(
        requestId: 'req-1',
        senderId: 'user-1',
        senderUsername: 'john_doe',
        recipientId: 'user-2',
        message: 'Let\'s study together!',
        sentAt: DateTime.now(),
        isRead: false,
      );
    });

    test('should create request with correct values', () {
      expect(request.requestId, 'req-1');
      expect(request.senderId, 'user-1');
      expect(request.recipientId, 'user-2');
      expect(request.isRead, false);
    });

    test('should serialize/deserialize correctly', () {
      final json = request.toJson();
      final deserialized = FriendRequest.fromJson(json);

      expect(deserialized.requestId, request.requestId);
      expect(deserialized.senderId, request.senderId);
      expect(deserialized.message, request.message);
    });
  });

  group('ActivityFeed', () {
    late ActivityFeed activity;

    setUp(() {
      activity = ActivityFeed(
        activityId: 'act-1',
        userId: 'user-1',
        activityType: 'level_up',
        description: 'Reached Level 6',
        relatedUserId: 'user-2',
        createdAt: DateTime.now(),
      );
    });

    test('should create activity with correct values', () {
      expect(activity.activityId, 'act-1');
      expect(activity.userId, 'user-1');
      expect(activity.activityType, 'level_up');
    });

    test('should serialize/deserialize correctly', () {
      final json = activity.toJson();
      final deserialized = ActivityFeed.fromJson(json);

      expect(deserialized.activityId, activity.activityId);
      expect(deserialized.activityType, activity.activityType);
      expect(deserialized.description, activity.description);
    });
  });

  group('FriendChallenge', () {
    late FriendChallenge challenge;

    setUp(() {
      challenge = FriendChallenge(
        challengeId: 'fc-1',
        initiatorId: 'user-1',
        challengedId: 'user-2',
        description: 'Solve 20 quiz questions first',
        targetAmount: 20,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 7)),
        initiatorProgress: 10,
        challengedProgress: 8,
        isCompleted: false,
      );
    });

    test('should create challenge with correct values', () {
      expect(challenge.challengeId, 'fc-1');
      expect(challenge.targetAmount, 20);
      expect(challenge.isCompleted, false);
    });

    test('isActive should return true for non-expired challenge', () {
      expect(challenge.isActive, true);
    });

    test('isActive should return false for expired challenge', () {
      final expired = FriendChallenge(
        challengeId: 'fc-2',
        initiatorId: 'user-1',
        challengedId: 'user-2',
        description: 'Old challenge',
        targetAmount: 10,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        expiresAt: DateTime.now().subtract(Duration(days: 3)),
        initiatorProgress: 5,
        challengedProgress: 4,
        isCompleted: false,
      );
      expect(expired.isActive, false);
    });

    test('initiatorWon should return true when initiator has higher progress', () {
      expect(challenge.initiatorWon, true);
    });

    test('initiatorWon should return false when challenged has higher progress', () {
      final challenged = FriendChallenge(
        challengeId: 'fc-2',
        initiatorId: 'user-1',
        challengedId: 'user-2',
        description: 'Challenge',
        targetAmount: 20,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 7)),
        initiatorProgress: 5,
        challengedProgress: 15,
        isCompleted: true,
      );
      expect(challenged.initiatorWon, false);
    });

    test('should serialize/deserialize correctly', () {
      final json = challenge.toJson();
      final deserialized = FriendChallenge.fromJson(json);

      expect(deserialized.challengeId, challenge.challengeId);
      expect(deserialized.targetAmount, challenge.targetAmount);
      expect(deserialized.initiatorProgress, challenge.initiatorProgress);
    });
  });

  group('SocialData', () {
    test('should aggregate all social data', () {
      final friends = [
        Friend(
          userId: 'user-1',
          username: 'john',
          displayName: 'John',
          profileImageUrl: null,
          level: 5,
          totalXp: 2500,
          lastSeenAt: DateTime.now(),
          onlineStatus: UserOnlineStatus.online,
          status: FriendshipStatus.accepted,
          connectedAt: DateTime.now(),
        ),
      ];

      final data = SocialData(
        friends: friends,
        friendRequests: [],
        activeChallenges: [],
        activityFeed: [],
        generatedAt: DateTime.now(),
      );

      expect(data.friends.length, 1);
      expect(data.activeFriendsCount, 1);
    });

    test('onlineFriendsCount should count only online friends', () {
      final friends = [
        Friend(
          userId: 'user-1',
          username: 'online_user',
          displayName: 'Online',
          profileImageUrl: null,
          level: 5,
          totalXp: 2500,
          lastSeenAt: DateTime.now(),
          onlineStatus: UserOnlineStatus.online,
          status: FriendshipStatus.accepted,
          connectedAt: DateTime.now(),
        ),
        Friend(
          userId: 'user-2',
          username: 'offline_user',
          displayName: 'Offline',
          profileImageUrl: null,
          level: 3,
          totalXp: 1500,
          lastSeenAt: DateTime.now(),
          onlineStatus: UserOnlineStatus.offline,
          status: FriendshipStatus.accepted,
          connectedAt: DateTime.now(),
        ),
      ];

      final data = SocialData(
        friends: friends,
        friendRequests: [],
        activeChallenges: [],
        activityFeed: [],
        generatedAt: DateTime.now(),
      );

      expect(data.onlineFriendsCount, 1);
    });
  });
}
