import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/social.dart';
import '../models/learning_analytics.dart';

class SocialState {
  final List<Friend> friends;
  final List<FriendRequest> pendingRequests;
  final List<FriendChallenge> activeChallenges;
  final List<ActivityFeed> activityFeed;
  final Map<String, Friend> friendsMap; // For quick lookup
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  SocialState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.activeChallenges = const [],
    this.activityFeed = const [],
    this.friendsMap = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  SocialState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? pendingRequests,
    List<FriendChallenge>? activeChallenges,
    List<ActivityFeed>? activityFeed,
    Map<String, Friend>? friendsMap,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      SocialState(
        friends: friends ?? this.friends,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        activeChallenges: activeChallenges ?? this.activeChallenges,
        activityFeed: activityFeed ?? this.activityFeed,
        friendsMap: friendsMap ?? this.friendsMap,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );

  int get activeFriendsCount => friends.where((f) => f.isActive).length;
  int get onlineFriendsCount =>
      friends.where((f) => f.onlineStatus == UserOnlineStatus.online).length;
  int get pendingRequestsCount => pendingRequests.length;
}

class SocialNotifier extends StateNotifier<SocialState> {
  SocialNotifier() : super(SocialState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  Future<void> loadFriendsData(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getStringList('friends_$userId') ?? [];
      final requestsJson = prefs.getStringList('friend_requests_$userId') ?? [];
      final challengesJson =
          prefs.getStringList('friend_challenges_$userId') ?? [];
      final activityJson = prefs.getStringList('activity_feed_$userId') ?? [];

      // Parse stored data (simplified - in production use proper JSON parsing)
      final friends = <Friend>[];
      final friendsMap = <String, Friend>{};

      // Mock data generation for testing
      for (int i = 0; i < 5; i++) {
        final friend = Friend(
          userId: _generateId('user'),
          username: 'friend_${i + 1}',
          displayName: 'Friend ${i + 1}',
          profileImageUrl: null,
          level: 5 + i,
          totalXp: 1000 + (i * 500),
          lastSeenAt: DateTime.now().subtract(Duration(hours: i)),
          onlineStatus: i % 2 == 0
              ? UserOnlineStatus.online
              : UserOnlineStatus.offline,
          status: FriendshipStatus.accepted,
          connectedAt: DateTime.now().subtract(Duration(days: 30 + i)),
        );
        friends.add(friend);
        friendsMap[friend.userId] = friend;
      }

      final requests = <FriendRequest>[];
      for (int i = 0; i < 2; i++) {
        requests.add(FriendRequest(
          requestId: _generateId('request'),
          senderId: _generateId('user'),
          senderUsername: 'pending_friend_${i + 1}',
          recipientId: userId,
          message: 'Let\'s study together!',
          sentAt: DateTime.now().subtract(Duration(days: i)),
          isRead: i == 0,
        ));
      }

      final challenges = <FriendChallenge>[];
      for (int i = 0; i < 2; i++) {
        challenges.add(FriendChallenge(
          challengeId: _generateId('fc'),
          initiatorId: friends[i].userId,
          challengedId: userId,
          description: 'Quiz Challenge: solve 20 questions first!',
          targetAmount: 20,
          createdAt: DateTime.now().subtract(Duration(days: i)),
          expiresAt: DateTime.now().add(Duration(days: 7 - i)),
          initiatorProgress: 15 + (i * 2),
          challengedProgress: 10 + (i * 3),
          isCompleted: false,
        ));
      }

      final activities = <ActivityFeed>[];
      for (int i = 0; i < 5; i++) {
        activities.add(ActivityFeed(
          activityId: _generateId('activity'),
          userId: friends[i % friends.length].userId,
          activityType: i % 3 == 0
              ? 'level_up'
              : (i % 3 == 1 ? 'quiz_complete' : 'badge_unlock'),
          description: i % 3 == 0
              ? 'Reached Level ${5 + (i ~/ 3)}'
              : (i % 3 == 1
                  ? 'Completed 10 quizzes'
                  : 'Unlocked a new badge'),
          relatedUserId: friends[i % friends.length].userId,
          createdAt: DateTime.now().subtract(Duration(hours: i)),
        ));
      }

      state = state.copyWith(
        friends: friends,
        friendsMap: friendsMap,
        pendingRequests: requests,
        activeChallenges: challenges,
        activityFeed: activities,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistFriendData(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendFriendRequest(
    String senderId,
    String senderUsername,
    String recipientId,
    String message,
  ) async {
    try {
      final request = FriendRequest(
        requestId: _generateId('request'),
        senderId: senderId,
        senderUsername: senderUsername,
        recipientId: recipientId,
        message: message,
        sentAt: DateTime.now(),
        isRead: false,
      );

      state = state.copyWith(
        pendingRequests: [request, ...state.pendingRequests].take(100).toList(),
      );

      // Add activity
      await _addActivity(
        userId: senderId,
        activityType: 'friend_request_sent',
        description: 'Sent friend request to $senderUsername',
        relatedUserId: recipientId,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> acceptFriendRequest(String requestId, String friendUserId) async {
    try {
      final request = state.pendingRequests.firstWhere(
        (r) => r.requestId == requestId,
        orElse: () => throw Exception('Request not found'),
      );

      // Create friend record
      final friend = Friend(
        userId: friendUserId,
        username: request.senderUsername,
        displayName: request.senderUsername,
        profileImageUrl: null,
        level: 1,
        totalXp: 0,
        lastSeenAt: DateTime.now(),
        onlineStatus: UserOnlineStatus.offline,
        status: FriendshipStatus.accepted,
        connectedAt: DateTime.now(),
      );

      final updatedFriends = [...state.friends, friend];
      final updatedMap = {...state.friendsMap, friendUserId: friend};
      final updatedRequests = state.pendingRequests
          .where((r) => r.requestId != requestId)
          .toList();

      state = state.copyWith(
        friends: updatedFriends,
        friendsMap: updatedMap,
        pendingRequests: updatedRequests,
      );

      await _addActivity(
        userId: request.recipientId,
        activityType: 'friend_accepted',
        description: 'Accepted friend request from ${request.senderUsername}',
        relatedUserId: friendUserId,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      state = state.copyWith(
        pendingRequests: state.pendingRequests
            .where((r) => r.requestId != requestId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> blockUser(String friendUserId) async {
    try {
      final friend = state.friendsMap[friendUserId];
      if (friend != null) {
        final blockedFriend = Friend(
          userId: friend.userId,
          username: friend.username,
          displayName: friend.displayName,
          profileImageUrl: friend.profileImageUrl,
          level: friend.level,
          totalXp: friend.totalXp,
          lastSeenAt: friend.lastSeenAt,
          onlineStatus: friend.onlineStatus,
          status: FriendshipStatus.blocked,
          connectedAt: friend.connectedAt,
          blockedAt: DateTime.now(),
        );

        final updatedFriends = state.friends
            .map((f) => f.userId == friendUserId ? blockedFriend : f)
            .toList();
        final updatedMap = {...state.friendsMap, friendUserId: blockedFriend};

        state = state.copyWith(
          friends: updatedFriends,
          friendsMap: updatedMap,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unblockUser(String friendUserId) async {
    try {
      final friend = state.friendsMap[friendUserId];
      if (friend != null) {
        final unblockedFriend = Friend(
          userId: friend.userId,
          username: friend.username,
          displayName: friend.displayName,
          profileImageUrl: friend.profileImageUrl,
          level: friend.level,
          totalXp: friend.totalXp,
          lastSeenAt: friend.lastSeenAt,
          onlineStatus: friend.onlineStatus,
          status: FriendshipStatus.accepted,
          connectedAt: friend.connectedAt,
        );

        final updatedFriends = state.friends
            .map((f) => f.userId == friendUserId ? unblockedFriend : f)
            .toList();
        final updatedMap = {...state.friendsMap, friendUserId: unblockedFriend};

        state = state.copyWith(
          friends: updatedFriends,
          friendsMap: updatedMap,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createFriendChallenge(
    String initiatorId,
    String challengedId,
    String description,
    int targetAmount,
  ) async {
    try {
      final challenge = FriendChallenge(
        challengeId: _generateId('fc'),
        initiatorId: initiatorId,
        challengedId: challengedId,
        description: description,
        targetAmount: targetAmount,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 7)),
        initiatorProgress: 0,
        challengedProgress: 0,
        isCompleted: false,
      );

      state = state.copyWith(
        activeChallenges: [challenge, ...state.activeChallenges]
            .take(100)
            .toList(),
      );

      await _addActivity(
        userId: initiatorId,
        activityType: 'challenge_created',
        description: 'Created a challenge: $description',
        relatedUserId: challengedId,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateChallengeProgress(
    String challengeId,
    String userId,
    int newProgress,
  ) async {
    try {
      final challengeIndex = state.activeChallenges
          .indexWhere((c) => c.challengeId == challengeId);

      if (challengeIndex >= 0) {
        final challenge = state.activeChallenges[challengeIndex];
        final isInitiator = challenge.initiatorId == userId;

        final updated = FriendChallenge(
          challengeId: challenge.challengeId,
          initiatorId: challenge.initiatorId,
          challengedId: challenge.challengedId,
          description: challenge.description,
          targetAmount: challenge.targetAmount,
          createdAt: challenge.createdAt,
          expiresAt: challenge.expiresAt,
          initiatorProgress: isInitiator ? newProgress : challenge.initiatorProgress,
          challengedProgress:
              !isInitiator ? newProgress : challenge.challengedProgress,
          isCompleted: newProgress >= challenge.targetAmount,
        );

        final updatedChallenges = [...state.activeChallenges];
        updatedChallenges[challengeIndex] = updated;

        state = state.copyWith(activeChallenges: updatedChallenges);

        if (updated.isCompleted) {
          await _addActivity(
            userId: userId,
            activityType: 'challenge_completed',
            description: 'Completed friend challenge',
            relatedUserId: isInitiator ? challenge.challengedId : challenge.initiatorId,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateFriendOnlineStatus(
    String friendUserId,
    UserOnlineStatus status,
  ) async {
    try {
      final friend = state.friendsMap[friendUserId];
      if (friend != null) {
        final updated = Friend(
          userId: friend.userId,
          username: friend.username,
          displayName: friend.displayName,
          profileImageUrl: friend.profileImageUrl,
          level: friend.level,
          totalXp: friend.totalXp,
          lastSeenAt: status == UserOnlineStatus.online ? DateTime.now() : friend.lastSeenAt,
          onlineStatus: status,
          status: friend.status,
          connectedAt: friend.connectedAt,
          blockedAt: friend.blockedAt,
        );

        final updatedFriends = state.friends
            .map((f) => f.userId == friendUserId ? updated : f)
            .toList();
        final updatedMap = {...state.friendsMap, friendUserId: updated};

        state = state.copyWith(
          friends: updatedFriends,
          friendsMap: updatedMap,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _addActivity({
    required String userId,
    required String activityType,
    required String description,
    required String relatedUserId,
  }) async {
    final activity = ActivityFeed(
      activityId: _generateId('activity'),
      userId: userId,
      activityType: activityType,
      description: description,
      relatedUserId: relatedUserId,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      activityFeed: [activity, ...state.activityFeed].take(100).toList(),
    );
  }

  Future<void> _persistFriendData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simplified persistence - in production use proper JSON serialization
      await prefs.setString('social_last_updated_$userId', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently fail
    }
  }

  List<Friend> getActiveFriends() =>
      state.friends.where((f) => f.isActive).toList();

  List<Friend> getOnlineFriends() =>
      state.friends
          .where((f) => f.onlineStatus == UserOnlineStatus.online)
          .toList();

  List<FriendRequest> getPendingRequests() => state.pendingRequests;

  List<FriendChallenge> getActiveChallenges() =>
      state.activeChallenges
          .where((c) => c.isActive && !c.isCompleted)
          .toList();

  List<ActivityFeed> getRecentActivity({int limit = 20}) =>
      state.activityFeed.take(limit).toList();

  List<ActivityFeed> getActivityForFriend(String friendUserId) =>
      state.activityFeed
          .where((a) => a.userId == friendUserId || a.relatedUserId == friendUserId)
          .toList();
}

final socialProvider =
    StateNotifierProvider.autoDispose<SocialNotifier, SocialState>(
      (ref) => SocialNotifier(),
    );

final activeFriendsProvider = Provider.autoDispose<List<Friend>>((ref) {
  return ref.watch(socialProvider).friends.where((f) => f.isActive).toList();
});

final onlineFriendsProvider = Provider.autoDispose<List<Friend>>((ref) {
  return ref
      .watch(socialProvider)
      .friends
      .where((f) => f.onlineStatus == UserOnlineStatus.online)
      .toList();
});

final pendingRequestsProvider =
    Provider.autoDispose<List<FriendRequest>>((ref) {
  return ref.watch(socialProvider).pendingRequests;
});

final activeChallengesProvider =
    Provider.autoDispose<List<FriendChallenge>>((ref) {
  return ref
      .watch(socialProvider)
      .activeChallenges
      .where((c) => c.isActive && !c.isCompleted)
      .toList();
});

final recentActivityProvider = Provider.autoDispose<List<ActivityFeed>>((ref) {
  return ref.watch(socialProvider).activityFeed.take(20).toList();
});

final friendActivityProvider =
    Provider.autoDispose.family<List<ActivityFeed>, String>((ref, friendUserId) {
  return ref
      .watch(socialProvider)
      .activityFeed
      .where(
        (a) => a.userId == friendUserId || a.relatedUserId == friendUserId,
      )
      .toList();
});

final socialDataProvider = Provider.autoDispose<SocialData>((ref) {
  final state = ref.watch(socialProvider);
  return SocialData(
    friends: state.friends,
    friendRequests: state.pendingRequests,
    activeChallenges: state.activeChallenges,
    activityFeed: state.activityFeed,
    generatedAt: state.lastUpdatedAt ?? DateTime.now(),
  );
});
