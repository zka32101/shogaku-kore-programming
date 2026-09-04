import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/friend_system.dart';

void main() {
  group('FriendStatus Enum', () {
    test('has all expected statuses', () {
      expect(FriendStatus.values.length, 4);
      expect(FriendStatus.values, contains(FriendStatus.accepted));
      expect(FriendStatus.values, contains(FriendStatus.blocked));
    });
  });

  group('FriendshipType Enum', () {
    test('has all expected types', () {
      expect(FriendshipType.values.length, 3);
      expect(FriendshipType.values, contains(FriendshipType.mutual));
      expect(FriendshipType.values, contains(FriendshipType.blocked));
    });
  });

  group('FriendInfo', () {
    test('creates friend info with required fields', () {
      final friendInfo = FriendInfo(
        friendId: 'friend1',
        username: 'testfriend',
        currentLevel: 10,
        userRank: UserRank.learner,
      );

      expect(friendInfo.friendId, 'friend1');
      expect(friendInfo.username, 'testfriend');
      expect(friendInfo.currentLevel, 10);
    });

    test('toJson serializes friend info', () {
      final friendInfo = FriendInfo(
        friendId: 'friend1',
        username: 'testfriend',
        displayName: 'Test Friend',
        currentLevel: 10,
        userRank: UserRank.learner,
        isOnline: true,
      );

      final json = friendInfo.toJson();
      expect(json['friendId'], 'friend1');
      expect(json['isOnline'], true);
      expect(json['userRank'], 'learner');
    });

    test('fromJson deserializes friend info', () {
      final json = {
        'friendId': 'friend1',
        'username': 'testfriend',
        'currentLevel': 10,
        'userRank': 'learner',
      };

      final friendInfo = FriendInfo.fromJson(json);
      expect(friendInfo.friendId, 'friend1');
      expect(friendInfo.currentLevel, 10);
    });
  });

  group('FriendRequest', () {
    test('creates friend request with required fields', () {
      final now = DateTime.now();
      final request = FriendRequest(
        requestId: 'req1',
        senderId: 'sender1',
        senderUsername: 'sender',
        recipientId: 'recipient1',
        status: FriendStatus.pending,
        sentAt: now,
      );

      expect(request.requestId, 'req1');
      expect(request.senderId, 'sender1');
      expect(request.isPending, true);
    });

    test('isPending returns correct status', () {
      final now = DateTime.now();
      final pendingRequest = FriendRequest(
        requestId: 'req1',
        senderId: 'sender1',
        senderUsername: 'sender',
        recipientId: 'recipient1',
        status: FriendStatus.pending,
        sentAt: now,
      );

      expect(pendingRequest.isPending, true);

      final acceptedRequest = FriendRequest(
        requestId: 'req2',
        senderId: 'sender1',
        senderUsername: 'sender',
        recipientId: 'recipient1',
        status: FriendStatus.accepted,
        sentAt: now,
      );

      expect(acceptedRequest.isPending, false);
    });

    test('isRecent returns true for recent requests', () {
      final now = DateTime.now();
      final recentRequest = FriendRequest(
        requestId: 'req1',
        senderId: 'sender1',
        senderUsername: 'sender',
        recipientId: 'recipient1',
        status: FriendStatus.pending,
        sentAt: now.subtract(const Duration(days: 3)),
      );

      expect(recentRequest.isRecent, true);
    });

    test('isRecent returns false for old requests', () {
      final now = DateTime.now();
      final oldRequest = FriendRequest(
        requestId: 'req1',
        senderId: 'sender1',
        senderUsername: 'sender',
        recipientId: 'recipient1',
        status: FriendStatus.pending,
        sentAt: now.subtract(const Duration(days: 10)),
      );

      expect(oldRequest.isRecent, false);
    });

    test('toJson serializes request', () {
      final now = DateTime.now();
      final request = FriendRequest(
        requestId: 'req1',
        senderId: 'sender1',
        senderUsername: 'sender',
        recipientId: 'recipient1',
        status: FriendStatus.pending,
        sentAt: now,
      );

      final json = request.toJson();
      expect(json['requestId'], 'req1');
      expect(json['status'], 'pending');
    });

    test('fromJson deserializes request', () {
      final now = DateTime.now();
      final json = {
        'requestId': 'req1',
        'senderId': 'sender1',
        'senderUsername': 'sender',
        'recipientId': 'recipient1',
        'status': 'pending',
        'sentAt': now.toIso8601String(),
      };

      final request = FriendRequest.fromJson(json);
      expect(request.requestId, 'req1');
      expect(request.status, FriendStatus.pending);
    });
  });

  group('Friendship', () {
    test('creates friendship with required fields', () {
      final now = DateTime.now();
      final friendship = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
      );

      expect(friendship.friendshipId, 'fs1');
      expect(friendship.isAccepted, true);
      expect(friendship.isBlocked, false);
    });

    test('isAccepted returns correct status', () {
      final now = DateTime.now();
      final accepted = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
      );

      expect(accepted.isAccepted, true);

      final pending = Friendship(
        friendshipId: 'fs2',
        userId: 'user1',
        friendId: 'friend2',
        status: FriendStatus.pending,
        type: FriendshipType.following,
        connectedAt: now,
      );

      expect(pending.isAccepted, false);
    });

    test('friendshipDuration calculates correctly', () {
      final now = DateTime.now();
      final friendship = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now.subtract(const Duration(days: 5)),
      );

      expect(friendship.friendshipDuration.inDays, greaterThanOrEqualTo(4));
    });

    test('toJson serializes friendship', () {
      final now = DateTime.now();
      final friendship = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
        isFavorited: true,
      );

      final json = friendship.toJson();
      expect(json['friendshipId'], 'fs1');
      expect(json['isFavorited'], true);
      expect(json['type'], 'mutual');
    });

    test('fromJson deserializes friendship', () {
      final now = DateTime.now();
      final json = {
        'friendshipId': 'fs1',
        'userId': 'user1',
        'friendId': 'friend1',
        'status': 'accepted',
        'type': 'mutual',
        'connectedAt': now.toIso8601String(),
      };

      final friendship = Friendship.fromJson(json);
      expect(friendship.friendshipId, 'fs1');
      expect(friendship.isAccepted, true);
    });
  });

  group('FriendGroup', () {
    test('creates friend group with required fields', () {
      final now = DateTime.now();
      final group = FriendGroup(
        groupId: 'fg1',
        userId: 'user1',
        groupName: 'Close Friends',
        friendIds: ['friend1', 'friend2'],
        createdAt: now,
      );

      expect(group.groupId, 'fg1');
      expect(group.groupName, 'Close Friends');
      expect(group.friendIds.length, 2);
    });

    test('toJson serializes group', () {
      final now = DateTime.now();
      final group = FriendGroup(
        groupId: 'fg1',
        userId: 'user1',
        groupName: 'Study Group',
        color: '#FF5733',
        friendIds: ['friend1'],
        createdAt: now,
      );

      final json = group.toJson();
      expect(json['groupId'], 'fg1');
      expect(json['color'], '#FF5733');
    });

    test('fromJson deserializes group', () {
      final now = DateTime.now();
      final json = {
        'groupId': 'fg1',
        'userId': 'user1',
        'groupName': 'Close Friends',
        'friendIds': ['friend1', 'friend2'],
        'createdAt': now.toIso8601String(),
      };

      final group = FriendGroup.fromJson(json);
      expect(group.groupId, 'fg1');
      expect(group.friendIds.length, 2);
    });
  });

  group('FriendStatistics', () {
    test('creates statistics with required fields', () {
      final now = DateTime.now();
      final stats = FriendStatistics(
        userId: 'user1',
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalFriends, 0);
    });

    test('getFriendTier returns correct levels', () {
      final now = DateTime.now();

      final newbieStats = FriendStatistics(
        userId: 'user1',
        totalFriends: 2,
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );
      expect(newbieStats.getFriendTier(), '新米');

      const friendlyStats = FriendStatistics(
        userId: 'user2',
        totalFriends: 15,
        lastFriendAddedAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(friendlyStats.getFriendTier(), '友好');

      const popularStats = FriendStatistics(
        userId: 'user3',
        totalFriends: 60,
        lastFriendAddedAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(popularStats.getFriendTier(), '人気者');
    });

    test('toJson serializes statistics', () {
      final now = DateTime.now();
      final stats = FriendStatistics(
        userId: 'user1',
        totalFriends: 10,
        acceptedFriends: 10,
        favoriteFriends: 3,
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      expect(json['userId'], 'user1');
      expect(json['totalFriends'], 10);
      expect(json['favoriteFriends'], 3);
    });

    test('fromJson deserializes statistics', () {
      final now = DateTime.now();
      final json = {
        'userId': 'user1',
        'totalFriends': 10,
        'acceptedFriends': 10,
        'lastFriendAddedAt': now.toIso8601String(),
        'lastUpdatedAt': now.toIso8601String(),
      };

      final stats = FriendStatistics.fromJson(json);
      expect(stats.userId, 'user1');
      expect(stats.totalFriends, 10);
    });
  });

  group('FriendSystemCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final stats = FriendStatistics(
        userId: 'user1',
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final collection = FriendSystemCollection(
        userId: 'user1',
        friendships: [],
        incomingRequests: [],
        outgoingRequests: [],
        friendGroups: [],
        statistics: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.friendships.isEmpty, true);
    });

    test('getAcceptedFriends filters accepted only', () {
      final now = DateTime.now();
      final accepted = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
      );
      final pending = Friendship(
        friendshipId: 'fs2',
        userId: 'user1',
        friendId: 'friend2',
        status: FriendStatus.pending,
        type: FriendshipType.following,
        connectedAt: now,
      );

      final stats = FriendStatistics(
        userId: 'user1',
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final collection = FriendSystemCollection(
        userId: 'user1',
        friendships: [accepted, pending],
        incomingRequests: [],
        outgoingRequests: [],
        friendGroups: [],
        statistics: stats,
        generatedAt: now,
      );

      final acceptedList = collection.getAcceptedFriends();
      expect(acceptedList.length, 1);
      expect(acceptedList[0].friendId, 'friend1');
    });

    test('getMutualFriends filters mutual only', () {
      final now = DateTime.now();
      final mutual = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
      );
      final oneWay = Friendship(
        friendshipId: 'fs2',
        userId: 'user1',
        friendId: 'friend2',
        status: FriendStatus.accepted,
        type: FriendshipType.following,
        connectedAt: now,
      );

      final stats = FriendStatistics(
        userId: 'user1',
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final collection = FriendSystemCollection(
        userId: 'user1',
        friendships: [mutual, oneWay],
        incomingRequests: [],
        outgoingRequests: [],
        friendGroups: [],
        statistics: stats,
        generatedAt: now,
      );

      final mutualList = collection.getMutualFriends();
      expect(mutualList.length, 1);
      expect(mutualList[0].type, FriendshipType.mutual);
    });

    test('getFavoriteFriends filters favorited only', () {
      final now = DateTime.now();
      final favorite = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
        isFavorited: true,
      );
      final notFavorite = Friendship(
        friendshipId: 'fs2',
        userId: 'user1',
        friendId: 'friend2',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
        isFavorited: false,
      );

      final stats = FriendStatistics(
        userId: 'user1',
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final collection = FriendSystemCollection(
        userId: 'user1',
        friendships: [favorite, notFavorite],
        incomingRequests: [],
        outgoingRequests: [],
        friendGroups: [],
        statistics: stats,
        generatedAt: now,
      );

      final favorites = collection.getFavoriteFriends();
      expect(favorites.length, 1);
      expect(favorites[0].isFavorited, true);
    });

    test('getBlockedFriends filters blocked only', () {
      final now = DateTime.now();
      final blocked = Friendship(
        friendshipId: 'fs1',
        userId: 'user1',
        friendId: 'friend1',
        status: FriendStatus.blocked,
        type: FriendshipType.blocked,
        connectedAt: now,
      );
      final accepted = Friendship(
        friendshipId: 'fs2',
        userId: 'user1',
        friendId: 'friend2',
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
      );

      final stats = FriendStatistics(
        userId: 'user1',
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final collection = FriendSystemCollection(
        userId: 'user1',
        friendships: [blocked, accepted],
        incomingRequests: [],
        outgoingRequests: [],
        friendGroups: [],
        statistics: stats,
        generatedAt: now,
      );

      final blockedList = collection.getBlockedFriends();
      expect(blockedList.length, 1);
      expect(blockedList[0].isBlocked, true);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = FriendStatistics(
        userId: 'user1',
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final collection = FriendSystemCollection(
        userId: 'user1',
        friendships: [],
        incomingRequests: [],
        outgoingRequests: [],
        friendGroups: [],
        statistics: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = FriendSystemCollection.fromJson(json);

      expect(restored.userId, collection.userId);
    });
  });
}
