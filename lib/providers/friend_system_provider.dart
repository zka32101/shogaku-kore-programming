import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/friend_system.dart';

/// Friend system state
class FriendSystemState {
  final FriendSystemCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  FriendSystemState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  FriendSystemState copyWith({
    FriendSystemCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      FriendSystemState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

/// Friend system notifier
class FriendSystemNotifier extends StateNotifier<FriendSystemState> {
  FriendSystemNotifier() : super(FriendSystemState());

  /// Initialize friend system
  Future<void> initializeFriendSystem(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'friend_system_$userId';

      final stored = prefs.getString(key);
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        state = state.copyWith(
          collection: FriendSystemCollection.fromJson(json),
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
        return;
      }

      final now = DateTime.now();
      final collection = FriendSystemCollection(
        userId: userId,
        friendships: [],
        incomingRequests: [],
        outgoingRequests: [],
        friendGroups: [],
        statistics: FriendStatistics(
          userId: userId,
          lastFriendAddedAt: now,
          lastUpdatedAt: now,
        ),
        generatedAt: now,
      );

      await prefs.setString(key, jsonEncode(collection.toJson()));
      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize friend system: $e',
      );
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(
    String userId,
    String recipientId,
    String senderUsername,
  ) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      // Check if already friends
      final alreadyFriends = collection.friendships.any((f) =>
          f.friendId == recipientId &&
          (f.status == FriendStatus.accepted || f.status == FriendStatus.pending));
      if (alreadyFriends) throw Exception('Already friends or request pending');

      // Check if blocked
      final isBlocked = collection.friendships
          .any((f) => f.friendId == recipientId && f.isBlocked);
      if (isBlocked) throw Exception('User is blocked');

      final requestId =
          'fr_${now.millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
      final request = FriendRequest(
        requestId: requestId,
        senderId: userId,
        senderUsername: senderUsername,
        recipientId: recipientId,
        status: FriendStatus.pending,
        sentAt: now,
      );

      final updatedOutgoing = [...collection.outgoingRequests, request];

      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: stats.totalFriends,
        acceptedFriends: stats.acceptedFriends,
        pendingRequests: stats.pendingRequests,
        sentRequests: stats.sentRequests + 1,
        blockedFriends: stats.blockedFriends,
        favoriteFriends: stats.favoriteFriends,
        friendGroups: stats.friendGroups,
        lastFriendAddedAt: stats.lastFriendAddedAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: collection.friendships,
        incomingRequests: collection.incomingRequests,
        outgoingRequests: updatedOutgoing.take(100).toList(),
        friendGroups: collection.friendGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to send friend request: $e');
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String userId, String requestId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final request = collection.incomingRequests.firstWhere(
        (r) => r.requestId == requestId,
        orElse: () => throw Exception('Request not found'),
      );

      final friendshipId = 'fs_${now.millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
      final friendship = Friendship(
        friendshipId: friendshipId,
        userId: userId,
        friendId: request.senderId,
        status: FriendStatus.accepted,
        type: FriendshipType.mutual,
        connectedAt: now,
        mutualAt: now,
      );

      final updatedIncoming = collection.incomingRequests
          .where((r) => r.requestId != requestId)
          .toList();
      final updatedFriendships = [...collection.friendships, friendship];

      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: stats.totalFriends + 1,
        acceptedFriends: stats.acceptedFriends + 1,
        pendingRequests: stats.pendingRequests - 1,
        sentRequests: stats.sentRequests,
        blockedFriends: stats.blockedFriends,
        favoriteFriends: stats.favoriteFriends,
        friendGroups: stats.friendGroups,
        lastFriendAddedAt: now,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: updatedFriendships.take(500).toList(),
        incomingRequests: updatedIncoming,
        outgoingRequests: collection.outgoingRequests,
        friendGroups: collection.friendGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept friend request: $e');
    }
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String userId, String requestId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedIncoming = collection.incomingRequests.map((r) {
        if (r.requestId == requestId) {
          return FriendRequest(
            requestId: r.requestId,
            senderId: r.senderId,
            senderUsername: r.senderUsername,
            recipientId: r.recipientId,
            status: FriendStatus.declined,
            sentAt: r.sentAt,
            respondedAt: now,
          );
        }
        return r;
      }).toList();

      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: stats.totalFriends,
        acceptedFriends: stats.acceptedFriends,
        pendingRequests: stats.pendingRequests - 1,
        sentRequests: stats.sentRequests,
        blockedFriends: stats.blockedFriends,
        favoriteFriends: stats.favoriteFriends,
        friendGroups: stats.friendGroups,
        lastFriendAddedAt: stats.lastFriendAddedAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: collection.friendships,
        incomingRequests: updatedIncoming,
        outgoingRequests: collection.outgoingRequests,
        friendGroups: collection.friendGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to decline friend request: $e');
    }
  }

  /// Remove friend
  Future<void> removeFriend(String userId, String friendId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedFriendships =
          collection.friendships.where((f) => f.friendId != friendId).toList();

      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: stats.totalFriends - 1,
        acceptedFriends: stats.acceptedFriends - 1,
        pendingRequests: stats.pendingRequests,
        sentRequests: stats.sentRequests,
        blockedFriends: stats.blockedFriends,
        favoriteFriends: stats.favoriteFriends,
        friendGroups: stats.friendGroups,
        lastFriendAddedAt: stats.lastFriendAddedAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: updatedFriendships,
        incomingRequests: collection.incomingRequests,
        outgoingRequests: collection.outgoingRequests,
        friendGroups: collection.friendGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove friend: $e');
    }
  }

  /// Block user
  Future<void> blockUser(String userId, String blockUserId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final existingFriendship = collection.friendships.firstWhere(
        (f) => f.friendId == blockUserId,
        orElse: () => null as dynamic,
      ) as Friendship?;

      Friendship blockedFriendship;
      if (existingFriendship != null) {
        blockedFriendship = Friendship(
          friendshipId: existingFriendship.friendshipId,
          userId: userId,
          friendId: blockUserId,
          status: FriendStatus.blocked,
          type: FriendshipType.blocked,
          connectedAt: existingFriendship.connectedAt,
          mutualAt: existingFriendship.mutualAt,
          isFavorited: false,
        );
      } else {
        final friendshipId =
            'fs_${now.millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
        blockedFriendship = Friendship(
          friendshipId: friendshipId,
          userId: userId,
          friendId: blockUserId,
          status: FriendStatus.blocked,
          type: FriendshipType.blocked,
          connectedAt: now,
        );
      }

      final updatedFriendships = [
        ...collection.friendships.where((f) => f.friendId != blockUserId),
        blockedFriendship,
      ];

      final wasAccepted = existingFriendship?.isAccepted ?? false;
      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: wasAccepted ? stats.totalFriends - 1 : stats.totalFriends,
        acceptedFriends: wasAccepted ? stats.acceptedFriends - 1 : stats.acceptedFriends,
        pendingRequests: stats.pendingRequests,
        sentRequests: stats.sentRequests,
        blockedFriends: stats.blockedFriends + 1,
        favoriteFriends: stats.favoriteFriends,
        friendGroups: stats.friendGroups,
        lastFriendAddedAt: stats.lastFriendAddedAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: updatedFriendships.take(500).toList(),
        incomingRequests: collection.incomingRequests,
        outgoingRequests: collection.outgoingRequests,
        friendGroups: collection.friendGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to block user: $e');
    }
  }

  /// Unblock user
  Future<void> unblockUser(String userId, String unblockUserId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedFriendships =
          collection.friendships.where((f) => f.friendId != unblockUserId).toList();

      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: stats.totalFriends,
        acceptedFriends: stats.acceptedFriends,
        pendingRequests: stats.pendingRequests,
        sentRequests: stats.sentRequests,
        blockedFriends: stats.blockedFriends - 1,
        favoriteFriends: stats.favoriteFriends,
        friendGroups: stats.friendGroups,
        lastFriendAddedAt: stats.lastFriendAddedAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: updatedFriendships,
        incomingRequests: collection.incomingRequests,
        outgoingRequests: collection.outgoingRequests,
        friendGroups: collection.friendGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to unblock user: $e');
    }
  }

  /// Toggle favorite friend
  Future<void> toggleFavoriteFriend(String userId, String friendId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedFriendships = collection.friendships.map((f) {
        if (f.friendId == friendId) {
          return Friendship(
            friendshipId: f.friendshipId,
            userId: f.userId,
            friendId: f.friendId,
            status: f.status,
            type: f.type,
            connectedAt: f.connectedAt,
            mutualAt: f.mutualAt,
            isFavorited: !f.isFavorited,
            friendGroupId: f.friendGroupId,
            metadata: f.metadata,
          );
        }
        return f;
      }).toList();

      final favorited = updatedFriendships
          .firstWhere((f) => f.friendId == friendId, orElse: () => null as dynamic)
          ?.isFavorited ??
          false;
      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: stats.totalFriends,
        acceptedFriends: stats.acceptedFriends,
        pendingRequests: stats.pendingRequests,
        sentRequests: stats.sentRequests,
        blockedFriends: stats.blockedFriends,
        favoriteFriends: favorited ? stats.favoriteFriends + 1 : stats.favoriteFriends - 1,
        friendGroups: stats.friendGroups,
        lastFriendAddedAt: stats.lastFriendAddedAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: updatedFriendships,
        incomingRequests: collection.incomingRequests,
        outgoingRequests: collection.outgoingRequests,
        friendGroups: collection.friendGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle favorite: $e');
    }
  }

  /// Create friend group
  Future<void> createFriendGroup(String userId, String groupName, {String? color}) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      if (collection.friendGroups.length >= 20) {
        throw Exception('Maximum friend groups reached (20)');
      }

      final now = DateTime.now();
      final groupId = 'fg_${now.millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
      final group = FriendGroup(
        groupId: groupId,
        userId: userId,
        groupName: groupName,
        color: color,
        friendIds: [],
        createdAt: now,
      );

      final updatedGroups = [...collection.friendGroups, group];
      final stats = collection.statistics;
      final updatedStats = FriendStatistics(
        userId: userId,
        totalFriends: stats.totalFriends,
        acceptedFriends: stats.acceptedFriends,
        pendingRequests: stats.pendingRequests,
        sentRequests: stats.sentRequests,
        blockedFriends: stats.blockedFriends,
        favoriteFriends: stats.favoriteFriends,
        friendGroups: stats.friendGroups + 1,
        lastFriendAddedAt: stats.lastFriendAddedAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = FriendSystemCollection(
        userId: userId,
        friendships: collection.friendships,
        incomingRequests: collection.incomingRequests,
        outgoingRequests: collection.outgoingRequests,
        friendGroups: updatedGroups,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create friend group: $e');
    }
  }

  /// Persist to SharedPreferences
  Future<void> _persist(String userId, FriendSystemCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'friend_system_$userId',
      jsonEncode(collection.toJson()),
    );
  }
}

// Riverpod providers
final friendSystemProvider =
    StateNotifierProvider<FriendSystemNotifier, FriendSystemState>((ref) {
  return FriendSystemNotifier();
});

final friendSystemCollectionProvider = Provider<FriendSystemCollection?>((ref) {
  final state = ref.watch(friendSystemProvider);
  return state.collection;
});

final acceptedFriendsProvider = Provider<List<Friendship>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.getAcceptedFriends() ?? [];
});

final mutualFriendsProvider = Provider<List<Friendship>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.getMutualFriends() ?? [];
});

final incomingRequestsProvider = Provider<List<FriendRequest>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.incomingRequests ?? [];
});

final pendingIncomingProvider = Provider<List<FriendRequest>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.getPendingIncoming() ?? [];
});

final outgoingRequestsProvider = Provider<List<FriendRequest>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.outgoingRequests ?? [];
});

final favoriteFriendsProvider = Provider<List<Friendship>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.getFavoriteFriends() ?? [];
});

final blockedFriendsProvider = Provider<List<Friendship>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.getBlockedFriends() ?? [];
});

final friendGroupsProvider = Provider<List<FriendGroup>>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.friendGroups ?? [];
});

final friendStatisticsProvider = Provider<FriendStatistics?>((ref) {
  final collection = ref.watch(friendSystemCollectionProvider);
  return collection?.statistics;
});

final friendTierProvider = Provider<String>((ref) {
  final stats = ref.watch(friendStatisticsProvider);
  return stats?.getFriendTier() ?? '新米';
});

final totalFriendsProvider = Provider<int>((ref) {
  final stats = ref.watch(friendStatisticsProvider);
  return stats?.totalFriends ?? 0;
});

final friendsByGroupProvider = Provider.family<List<Friendship>, String>((ref, groupId) {
  final collection = ref.watch(friendSystemCollectionProvider);
  if (collection == null) return [];
  try {
    return collection.getFriendsByGroup(groupId);
  } catch (e) {
    return [];
  }
});

final searchFriendsProvider =
    Provider.family<List<Friendship>, String>((ref, query) {
  final collection = ref.watch(friendSystemCollectionProvider);
  if (collection == null) return [];
  return collection.searchFriends(query);
});
