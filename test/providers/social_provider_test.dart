import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/models/social.dart';
import 'package:shogaku_kore_programming/providers/social_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SocialState', () {
    test('should initialize with default values', () {
      final state = SocialState();

      expect(state.friends, isEmpty);
      expect(state.pendingRequests, isEmpty);
      expect(state.activeChallenges, isEmpty);
      expect(state.activityFeed, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith should update fields', () {
      final state = SocialState(isLoading: true);
      final updated = state.copyWith(isLoading: false, error: 'Test error');

      expect(updated.isLoading, false);
      expect(updated.error, 'Test error');
    });

    test('activeFriendsCount should count only active friends', () {
      final friends = [
        Friend(
          userId: 'user-1',
          username: 'active',
          displayName: 'Active',
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
          username: 'blocked',
          displayName: 'Blocked',
          profileImageUrl: null,
          level: 3,
          totalXp: 1500,
          lastSeenAt: DateTime.now(),
          onlineStatus: UserOnlineStatus.offline,
          status: FriendshipStatus.blocked,
          connectedAt: DateTime.now(),
          blockedAt: DateTime.now(),
        ),
      ];

      final state = SocialState(friends: friends);
      expect(state.activeFriendsCount, 1);
    });

    test('onlineFriendsCount should count only online friends', () {
      final friends = [
        Friend(
          userId: 'user-1',
          username: 'online',
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
          username: 'offline',
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

      final state = SocialState(friends: friends);
      expect(state.onlineFriendsCount, 1);
    });
  });

  group('SocialNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should load friends data', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final state = container.read(socialProvider);
      expect(state.friends.isNotEmpty, true);
      expect(state.isLoading, false);
    });

    test('should send friend request', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.sendFriendRequest(
        'user-1',
        'john_doe',
        'user-2',
        'Let\'s study!',
      );

      final state = container.read(socialProvider);
      expect(state.pendingRequests.isNotEmpty, true);
    });

    test('should accept friend request', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.sendFriendRequest(
        'user-2',
        'jane_doe',
        'user-1',
        'Hi!',
      );

      final stateAfterRequest = container.read(socialProvider);
      final requestId = stateAfterRequest.pendingRequests[0].requestId;

      await notifier.acceptFriendRequest(requestId, 'user-2');

      final state = container.read(socialProvider);
      expect(state.friends.length, greaterThan(0));
    });

    test('should reject friend request', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.sendFriendRequest(
        'user-2',
        'jane_doe',
        'user-1',
        'Hi!',
      );

      var state = container.read(socialProvider);
      final requestCount = state.pendingRequests.length;
      final requestId = state.pendingRequests[0].requestId;

      await notifier.rejectFriendRequest(requestId);

      state = container.read(socialProvider);
      expect(state.pendingRequests.length, lessThan(requestCount));
    });

    test('should block user', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      var state = container.read(socialProvider);
      final friendId = state.friends[0].userId;

      await notifier.blockUser(friendId);

      state = container.read(socialProvider);
      final blocked = state.friendsMap[friendId];
      expect(blocked?.isBlocked, true);
    });

    test('should unblock user', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      var state = container.read(socialProvider);
      final friendId = state.friends[0].userId;

      await notifier.blockUser(friendId);
      var blockedState = container.read(socialProvider);
      expect(blockedState.friendsMap[friendId]?.isBlocked, true);

      await notifier.unblockUser(friendId);

      state = container.read(socialProvider);
      expect(state.friendsMap[friendId]?.isBlocked, false);
    });

    test('should create friend challenge', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.createFriendChallenge(
        'user-1',
        'user-2',
        'Quiz Challenge',
        20,
      );

      final state = container.read(socialProvider);
      expect(state.activeChallenges.isNotEmpty, true);
    });

    test('should update challenge progress', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.createFriendChallenge(
        'user-1',
        'user-2',
        'Quiz Challenge',
        20,
      );

      var state = container.read(socialProvider);
      final challengeId = state.activeChallenges[0].challengeId;

      await notifier.updateChallengeProgress(challengeId, 'user-1', 15);

      state = container.read(socialProvider);
      final updated = state.activeChallenges
          .firstWhere((c) => c.challengeId == challengeId);
      expect(updated.initiatorProgress, 15);
    });

    test('should update friend online status', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      var state = container.read(socialProvider);
      final friendId = state.friends[0].userId;

      await notifier.updateFriendOnlineStatus(
        friendId,
        UserOnlineStatus.away,
      );

      state = container.read(socialProvider);
      expect(
        state.friendsMap[friendId]?.onlineStatus,
        UserOnlineStatus.away,
      );
    });

    test('getActiveFriends should return only active friends', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final activeFriends = notifier.getActiveFriends();
      expect(activeFriends.isNotEmpty, true);
      expect(activeFriends.every((f) => f.isActive), true);
    });

    test('getOnlineFriends should return only online friends', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final onlineFriends = notifier.getOnlineFriends();
      expect(
        onlineFriends.every((f) => f.onlineStatus == UserOnlineStatus.online),
        true,
      );
    });

    test('getActiveChallenges should return non-expired challenges', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.createFriendChallenge(
        'user-1',
        'user-2',
        'Quiz Challenge',
        20,
      );

      final activeChallenges = notifier.getActiveChallenges();
      expect(activeChallenges.isNotEmpty, true);
    });

    test('getRecentActivity should return limited activity', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final recent = notifier.getRecentActivity(limit: 5);
      expect(recent.length, lessThanOrEqualTo(5));
    });
  });

  group('Social Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('activeFriendsProvider should provide active friends', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final active = container.read(activeFriendsProvider);
      expect(active.isNotEmpty, true);
    });

    test('onlineFriendsProvider should provide online friends', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final online = container.read(onlineFriendsProvider);
      expect(
        online.every((f) => f.onlineStatus == UserOnlineStatus.online),
        true,
      );
    });

    test('pendingRequestsProvider should provide pending requests', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.sendFriendRequest(
        'user-2',
        'jane_doe',
        'user-1',
        'Hi!',
      );

      final pending = container.read(pendingRequestsProvider);
      expect(pending.isNotEmpty, true);
    });

    test('activeChallengesProvider should provide active challenges', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      await notifier.createFriendChallenge(
        'user-1',
        'user-2',
        'Quiz Challenge',
        20,
      );

      final active = container.read(activeChallengesProvider);
      expect(active.isNotEmpty, true);
    });

    test('recentActivityProvider should provide recent activities', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final recent = container.read(recentActivityProvider);
      expect(recent.isNotEmpty, true);
    });

    test('socialDataProvider should aggregate all data', () async {
      final notifier = container.read(socialProvider.notifier);
      await notifier.loadFriendsData('user-1');

      final data = container.read(socialDataProvider);
      expect(data.friends.isNotEmpty, true);
    });
  });
}
