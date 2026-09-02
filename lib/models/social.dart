import 'package:flutter/foundation.dart';

/// フレンド関係のステータス
enum FriendshipStatus {
  pending,    // 保留中
  accepted,   // 承認済み
  blocked,    // ブロック中
  rejected,   // 却下
}

/// ユーザーのオンラインステータス
enum UserOnlineStatus {
  online,     // オンライン
  away,       // 離席中
  offline,    // オフライン
}

/// フレンド情報
class Friend {
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final int level;
  final int totalXp;
  final DateTime? lastSeenAt;
  final UserOnlineStatus onlineStatus;
  final FriendshipStatus status;
  final DateTime connectedAt;
  final DateTime? blockedAt;

  Friend({
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    required this.level,
    required this.totalXp,
    this.lastSeenAt,
    required this.onlineStatus,
    required this.status,
    required this.connectedAt,
    this.blockedAt,
  });

  /// フレンドシップが有効か判定
  bool get isActive => status == FriendshipStatus.accepted;

  /// ブロック中か判定
  bool get isBlocked => status == FriendshipStatus.blocked;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'profileImageUrl': profileImageUrl,
        'level': level,
        'totalXp': totalXp,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'onlineStatus': onlineStatus.name,
        'status': status.name,
        'connectedAt': connectedAt.toIso8601String(),
        'blockedAt': blockedAt?.toIso8601String(),
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        level: json['level'] as int,
        totalXp: json['totalXp'] as int,
        lastSeenAt: json['lastSeenAt'] != null
            ? DateTime.parse(json['lastSeenAt'] as String)
            : null,
        onlineStatus:
            UserOnlineStatus.values.byName(json['onlineStatus'] as String),
        status: FriendshipStatus.values.byName(json['status'] as String),
        connectedAt: DateTime.parse(json['connectedAt'] as String),
        blockedAt: json['blockedAt'] != null
            ? DateTime.parse(json['blockedAt'] as String)
            : null,
      );
}

/// フレンドリクエスト
class FriendRequest {
  final String requestId;
  final String senderId;
  final String senderUsername;
  final String recipientId;
  final String? message;
  final DateTime sentAt;
  final bool isRead;

  FriendRequest({
    required this.requestId,
    required this.senderId,
    required this.senderUsername,
    required this.recipientId,
    this.message,
    required this.sentAt,
    required this.isRead,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'senderId': senderId,
        'senderUsername': senderUsername,
        'recipientId': recipientId,
        'message': message,
        'sentAt': sentAt.toIso8601String(),
        'isRead': isRead,
      };

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      FriendRequest(
        requestId: json['requestId'] as String,
        senderId: json['senderId'] as String,
        senderUsername: json['senderUsername'] as String,
        recipientId: json['recipientId'] as String,
        message: json['message'] as String?,
        sentAt: DateTime.parse(json['sentAt'] as String),
        isRead: json['isRead'] as bool,
      );
}

/// アクティビティフィード
class ActivityFeed {
  final String activityId;
  final String userId;
  final String activityType; // level_up, challenge_completed, badge_earned, etc
  final String description;
  final String? relatedUserId; // コラボレーティブアクティビティの場合
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  ActivityFeed({
    required this.activityId,
    required this.userId,
    required this.activityType,
    required this.description,
    this.relatedUserId,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'userId': userId,
        'activityType': activityType,
        'description': description,
        'relatedUserId': relatedUserId,
        'createdAt': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory ActivityFeed.fromJson(Map<String, dynamic> json) => ActivityFeed(
        activityId: json['activityId'] as String,
        userId: json['userId'] as String,
        activityType: json['activityType'] as String,
        description: json['description'] as String,
        relatedUserId: json['relatedUserId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// フレンドチャレンジ
class FriendChallenge {
  final String challengeId;
  final String initiatorId;
  final String challengedId;
  final String description;
  final int targetAmount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isCompleted;
  final int initiatorProgress;
  final int challengedProgress;

  FriendChallenge({
    required this.challengeId,
    required this.initiatorId,
    required this.challengedId,
    required this.description,
    required this.targetAmount,
    required this.createdAt,
    required this.expiresAt,
    required this.isCompleted,
    required this.initiatorProgress,
    required this.challengedProgress,
  });

  /// チャレンジが有効か判定
  bool get isActive => !isCompleted && DateTime.now().isBefore(expiresAt);

  /// イニシエーターが勝利したか判定
  bool get initiatorWon => initiatorProgress > challengedProgress;

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'initiatorId': initiatorId,
        'challengedId': challengedId,
        'description': description,
        'targetAmount': targetAmount,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isCompleted': isCompleted,
        'initiatorProgress': initiatorProgress,
        'challengedProgress': challengedProgress,
      };

  factory FriendChallenge.fromJson(Map<String, dynamic> json) =>
      FriendChallenge(
        challengeId: json['challengeId'] as String,
        initiatorId: json['initiatorId'] as String,
        challengedId: json['challengedId'] as String,
        description: json['description'] as String,
        targetAmount: json['targetAmount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isCompleted: json['isCompleted'] as bool,
        initiatorProgress: json['initiatorProgress'] as int,
        challengedProgress: json['challengedProgress'] as int,
      );
}

/// ユーザーのソーシャルデータ
class SocialData {
  final String userId;
  final List<Friend> friends;
  final List<FriendRequest> incomingRequests;
  final List<FriendRequest> outgoingRequests;
  final List<FriendChallenge> friendChallenges;
  final List<ActivityFeed> activityFeed;
  final DateTime generatedAt;

  SocialData({
    required this.userId,
    required this.friends,
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.friendChallenges,
    required this.activityFeed,
    required this.generatedAt,
  });

  /// アクティブなフレンドシップの数
  int get activeFriendsCount =>
      friends.where((f) => f.isActive).length;

  /// オンラインのフレンドの数
  int get onlineFriendsCount => friends
      .where((f) => f.isActive && f.onlineStatus == UserOnlineStatus.online)
      .length;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'friends': friends.map((e) => e.toJson()).toList(),
        'incomingRequests': incomingRequests.map((e) => e.toJson()).toList(),
        'outgoingRequests': outgoingRequests.map((e) => e.toJson()).toList(),
        'friendChallenges': friendChallenges.map((e) => e.toJson()).toList(),
        'activityFeed': activityFeed.map((e) => e.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory SocialData.fromJson(Map<String, dynamic> json) => SocialData(
        userId: json['userId'] as String,
        friends: ((json['friends'] as List?) ?? [])
            .map((e) => Friend.fromJson(e as Map<String, dynamic>))
            .toList(),
        incomingRequests: ((json['incomingRequests'] as List?) ?? [])
            .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
        outgoingRequests: ((json['outgoingRequests'] as List?) ?? [])
            .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
        friendChallenges: ((json['friendChallenges'] as List?) ?? [])
            .map((e) => FriendChallenge.fromJson(e as Map<String, dynamic>))
            .toList(),
        activityFeed: ((json['activityFeed'] as List?) ?? [])
            .map((e) => ActivityFeed.fromJson(e as Map<String, dynamic>))
            .toList(),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
