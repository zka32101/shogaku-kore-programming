/// Friend request status
enum FriendStatus {
  pending,    // Request awaiting response
  accepted,   // Friends
  blocked,    // Blocked by either user
  declined,   // Request declined
}

/// Friend relationship type
enum FriendshipType {
  mutual,     // Both follow each other
  following,  // One-way following
  blocked,    // Blocked relationship
}

/// Basic friend info for lists
class FriendInfo {
  final String friendId;
  final String username;
  final String? displayName;
  final String? avatarId;
  final int currentLevel;
  final UserRank userRank;
  final bool isOnline;
  final DateTime? lastSeenAt;

  FriendInfo({
    required this.friendId,
    required this.username,
    this.displayName,
    this.avatarId,
    required this.currentLevel,
    required this.userRank,
    this.isOnline = false,
    this.lastSeenAt,
  });

  Map<String, dynamic> toJson() => {
        'friendId': friendId,
        'username': username,
        'displayName': displayName,
        'avatarId': avatarId,
        'currentLevel': currentLevel,
        'userRank': userRank.name,
        'isOnline': isOnline,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
      };

  factory FriendInfo.fromJson(Map<String, dynamic> json) => FriendInfo(
        friendId: json['friendId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        avatarId: json['avatarId'] as String?,
        currentLevel: json['currentLevel'] as int? ?? 1,
        userRank: UserRank.values.byName(json['userRank'] as String? ?? 'beginner'),
        isOnline: json['isOnline'] as bool? ?? false,
        lastSeenAt: json['lastSeenAt'] != null ? DateTime.parse(json['lastSeenAt'] as String) : null,
      );
}

/// Friend request
class FriendRequest {
  final String requestId;
  final String senderId;           // User who sent request
  final String senderUsername;
  final String recipientId;        // User who receives request
  final FriendStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;
  final String? responseMessage;

  FriendRequest({
    required this.requestId,
    required this.senderId,
    required this.senderUsername,
    required this.recipientId,
    required this.status,
    required this.sentAt,
    this.respondedAt,
    this.responseMessage,
  });

  /// Check if request is pending
  bool get isPending => status == FriendStatus.pending;

  /// Check if request is recent (within 7 days)
  bool get isRecent {
    final now = DateTime.now();
    final dayInSeconds = 24 * 60 * 60;
    return (now.millisecondsSinceEpoch ~/ 1000) - (sentAt.millisecondsSinceEpoch ~/ 1000) <
        (7 * dayInSeconds);
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'senderId': senderId,
        'senderUsername': senderUsername,
        'recipientId': recipientId,
        'status': status.name,
        'sentAt': sentAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        'responseMessage': responseMessage,
      };

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        requestId: json['requestId'] as String,
        senderId: json['senderId'] as String,
        senderUsername: json['senderUsername'] as String,
        recipientId: json['recipientId'] as String,
        status: FriendStatus.values.byName(json['status'] as String? ?? 'pending'),
        sentAt: DateTime.parse(json['sentAt'] as String),
        respondedAt:
            json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
        responseMessage: json['responseMessage'] as String?,
      );
}

/// Friend relationship
class Friendship {
  final String friendshipId;
  final String userId;
  final String friendId;
  final FriendStatus status;
  final FriendshipType type;
  final DateTime connectedAt;     // When friendship was established
  final DateTime? mutualAt;        // When it became mutual (if applicable)
  final bool isFavorited;          // User has favorited this friend
  final String? friendGroupId;     // Group/category this friend belongs to
  final Map<String, dynamic>? metadata; // Custom data

  Friendship({
    required this.friendshipId,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.type,
    required this.connectedAt,
    this.mutualAt,
    this.isFavorited = false,
    this.friendGroupId,
    this.metadata,
  });

  /// Get duration of friendship
  Duration get friendshipDuration => DateTime.now().difference(connectedAt);

  /// Check if friend is accepted
  bool get isAccepted => status == FriendStatus.accepted;

  /// Check if friend is blocked
  bool get isBlocked => status == FriendStatus.blocked;

  Map<String, dynamic> toJson() => {
        'friendshipId': friendshipId,
        'userId': userId,
        'friendId': friendId,
        'status': status.name,
        'type': type.name,
        'connectedAt': connectedAt.toIso8601String(),
        'mutualAt': mutualAt?.toIso8601String(),
        'isFavorited': isFavorited,
        'friendGroupId': friendGroupId,
        'metadata': metadata,
      };

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        friendshipId: json['friendshipId'] as String,
        userId: json['userId'] as String,
        friendId: json['friendId'] as String,
        status: FriendStatus.values.byName(json['status'] as String? ?? 'pending'),
        type: FriendshipType.values.byName(json['type'] as String? ?? 'following'),
        connectedAt: DateTime.parse(json['connectedAt'] as String),
        mutualAt: json['mutualAt'] != null ? DateTime.parse(json['mutualAt'] as String) : null,
        isFavorited: json['isFavorited'] as bool? ?? false,
        friendGroupId: json['friendGroupId'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Friend group/category
class FriendGroup {
  final String groupId;
  final String userId;
  final String groupName;          // e.g., "Close Friends", "Study Group"
  final String? color;             // Hex color code
  final List<String> friendIds;    // Max 50 per group
  final DateTime createdAt;

  FriendGroup({
    required this.groupId,
    required this.userId,
    required this.groupName,
    this.color,
    required this.friendIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'userId': userId,
        'groupName': groupName,
        'color': color,
        'friendIds': friendIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FriendGroup.fromJson(Map<String, dynamic> json) => FriendGroup(
        groupId: json['groupId'] as String,
        userId: json['userId'] as String,
        groupName: json['groupName'] as String,
        color: json['color'] as String?,
        friendIds: ((json['friendIds'] as List?) ?? []).map((id) => id as String).toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Friend statistics
class FriendStatistics {
  final String userId;
  final int totalFriends;
  final int acceptedFriends;
  final int pendingRequests;       // Awaiting user response
  final int sentRequests;          // User sent, awaiting response
  final int blockedFriends;
  final int favoriteFriends;
  final int friendGroups;
  final DateTime lastFriendAddedAt;
  final DateTime lastUpdatedAt;

  FriendStatistics({
    required this.userId,
    this.totalFriends = 0,
    this.acceptedFriends = 0,
    this.pendingRequests = 0,
    this.sentRequests = 0,
    this.blockedFriends = 0,
    this.favoriteFriends = 0,
    this.friendGroups = 0,
    required this.lastFriendAddedAt,
    required this.lastUpdatedAt,
  });

  /// Get friend tier based on count
  String getFriendTier() {
    if (totalFriends < 5) return '新米';
    if (totalFriends < 20) return '友好';
    if (totalFriends < 50) return '人気者';
    if (totalFriends < 100) return 'ソーシャル';
    return 'インフルエンサー';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalFriends': totalFriends,
        'acceptedFriends': acceptedFriends,
        'pendingRequests': pendingRequests,
        'sentRequests': sentRequests,
        'blockedFriends': blockedFriends,
        'favoriteFriends': favoriteFriends,
        'friendGroups': friendGroups,
        'lastFriendAddedAt': lastFriendAddedAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory FriendStatistics.fromJson(Map<String, dynamic> json) => FriendStatistics(
        userId: json['userId'] as String,
        totalFriends: json['totalFriends'] as int? ?? 0,
        acceptedFriends: json['acceptedFriends'] as int? ?? 0,
        pendingRequests: json['pendingRequests'] as int? ?? 0,
        sentRequests: json['sentRequests'] as int? ?? 0,
        blockedFriends: json['blockedFriends'] as int? ?? 0,
        favoriteFriends: json['favoriteFriends'] as int? ?? 0,
        friendGroups: json['friendGroups'] as int? ?? 0,
        lastFriendAddedAt: DateTime.parse(json['lastFriendAddedAt'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete friend system collection
class FriendSystemCollection {
  final String userId;
  final List<Friendship> friendships;              // Max 500
  final List<FriendRequest> incomingRequests;      // Max 100
  final List<FriendRequest> outgoingRequests;      // Max 100
  final List<FriendGroup> friendGroups;            // Max 20
  final FriendStatistics statistics;
  final DateTime generatedAt;

  FriendSystemCollection({
    required this.userId,
    required this.friendships,
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.friendGroups,
    required this.statistics,
    required this.generatedAt,
  });

  /// Get accepted friends
  List<Friendship> getAcceptedFriends() =>
      friendships.where((f) => f.status == FriendStatus.accepted).toList();

  /// Get pending friendships (awaiting user response)
  List<FriendRequest> getPendingIncoming() =>
      incomingRequests.where((r) => r.status == FriendStatus.pending).toList();

  /// Get mutual friends (both accepted each other)
  List<Friendship> getMutualFriends() =>
      friendships.where((f) => f.type == FriendshipType.mutual && f.isAccepted).toList();

  /// Get friends by group
  List<Friendship> getFriendsByGroup(String groupId) {
    final group = friendGroups.firstWhere(
      (g) => g.groupId == groupId,
      orElse: () => throw Exception('Group not found'),
    );
    return friendships.where((f) => group.friendIds.contains(f.friendId)).toList();
  }

  /// Get favorite friends
  List<Friendship> getFavoriteFriends() =>
      friendships.where((f) => f.isFavorited && f.isAccepted).toList();

  /// Get blocked friends
  List<Friendship> getBlockedFriends() =>
      friendships.where((f) => f.isBlocked).toList();

  /// Search friends by username
  List<Friendship> searchFriends(String query) => friendships
      .where((f) => f.friendId.toLowerCase().contains(query.toLowerCase()))
      .toList();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'friendships': friendships.map((f) => f.toJson()).toList(),
        'incomingRequests': incomingRequests.map((r) => r.toJson()).toList(),
        'outgoingRequests': outgoingRequests.map((r) => r.toJson()).toList(),
        'friendGroups': friendGroups.map((g) => g.toJson()).toList(),
        'statistics': statistics.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory FriendSystemCollection.fromJson(Map<String, dynamic> json) =>
      FriendSystemCollection(
        userId: json['userId'] as String,
        friendships: ((json['friendships'] as List?) ?? [])
            .map((f) => Friendship.fromJson(f as Map<String, dynamic>))
            .toList(),
        incomingRequests: ((json['incomingRequests'] as List?) ?? [])
            .map((r) => FriendRequest.fromJson(r as Map<String, dynamic>))
            .toList(),
        outgoingRequests: ((json['outgoingRequests'] as List?) ?? [])
            .map((r) => FriendRequest.fromJson(r as Map<String, dynamic>))
            .toList(),
        friendGroups: ((json['friendGroups'] as List?) ?? [])
            .map((g) => FriendGroup.fromJson(g as Map<String, dynamic>))
            .toList(),
        statistics: FriendStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}

// Import for UserRank - needed for FriendInfo
enum UserRank {
  beginner,
  learner,
  intermediate,
  advanced,
  expert,
  master,
}
