/// Notification types
enum NotificationType {
  achievement,      // Achievement unlocked
  rankingChange,    // Ranking position changed
  challengeComplete, // Challenge completed
  rewardClaimed,    // Reward claimed
  levelUp,          // Level increased
  streakMilestone,  // Streak milestone reached
  friendRequest,    // Friend request received
  leaderboardUpdate, // User entered/exited leaderboard
  shopItemNew,      // New item in shop
  dailyMissionStart, // Daily mission available
  eventStart,       // Event started
  maintenance,      // System maintenance notification
  systemMessage,    // General system message
}

/// Notification priority levels
enum NotificationPriority {
  low,              // Background update
  normal,           // Regular notification
  high,             // Important notification
  critical,         // Urgent/critical
}

/// Notification channel for grouping
enum NotificationChannel {
  gamification,     // Achievement, ranking, streaks
  social,           // Friends, requests, messages
  shop,             // Shop items, rewards
  missions,         // Challenges, quests, missions
  system,           // System messages, maintenance
}

/// Individual notification
class Notification {
  final String notificationId;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationChannel channel;
  final String title;           // Notification title (Japanese)
  final String message;         // Notification message body
  final String? imageId;        // Icon/image ID
  final Map<String, dynamic>? data; // Additional data (achievement ID, etc.)
  final DateTime createdAt;
  final DateTime? expiresAt;    // Notification expiration (optional)
  final bool isRead;
  final DateTime? readAt;       // When user read this
  final String? actionUrl;      // Deep link to related screen
  final bool isSent;            // Whether OS notification was sent

  Notification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.priority,
    required this.channel,
    required this.title,
    required this.message,
    this.imageId,
    this.data,
    required this.createdAt,
    this.expiresAt,
    this.isRead = false,
    this.readAt,
    this.actionUrl,
    this.isSent = false,
  });

  /// Check if notification has expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if notification is recent (within last 24 hours)
  bool get isRecent => DateTime.now().difference(createdAt).inHours < 24;

  /// Get time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${diff.inDays ~/ 7}週間前';
  }

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'userId': userId,
        'type': type.name,
        'priority': priority.name,
        'channel': channel.name,
        'title': title,
        'message': message,
        'imageId': imageId,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'isRead': isRead,
        'readAt': readAt?.toIso8601String(),
        'actionUrl': actionUrl,
        'isSent': isSent,
      };

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        notificationId: json['notificationId'] as String,
        userId: json['userId'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        priority: NotificationPriority.values.byName(json['priority'] as String),
        channel: NotificationChannel.values.byName(json['channel'] as String),
        title: json['title'] as String,
        message: json['message'] as String,
        imageId: json['imageId'] as String?,
        data: json['data'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
        isRead: json['isRead'] as bool? ?? false,
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
        actionUrl: json['actionUrl'] as String?,
        isSent: json['isSent'] as bool? ?? false,
      );
}

/// Notification preferences for a user
class NotificationPreferences {
  final String userId;
  final Map<NotificationChannel, bool> channelSettings; // Channel -> enabled
  final Map<NotificationType, bool> typeSettings;       // Type -> enabled
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final String? pushToken;                              // Device token for push
  final int quietHourStart;                             // Start hour (0-23)
  final int quietHourEnd;                               // End hour (0-23)
  final bool respectQuietHours;
  final DateTime? lastUpdatedAt;

  NotificationPreferences({
    required this.userId,
    required this.channelSettings,
    required this.typeSettings,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = false,
    this.pushToken,
    this.quietHourStart = 22,           // 10 PM
    this.quietHourEnd = 8,              // 8 AM
    this.respectQuietHours = true,
    this.lastUpdatedAt,
  });

  /// Check if channel is enabled
  bool isChannelEnabled(NotificationChannel channel) =>
      channelSettings[channel] ?? true;

  /// Check if type is enabled
  bool isTypeEnabled(NotificationType type) =>
      typeSettings[type] ?? true;

  /// Check if currently in quiet hours
  bool get isInQuietHours {
    if (!respectQuietHours) return false;
    final now = DateTime.now();
    final hour = now.hour;
    if (quietHourStart < quietHourEnd) {
      return hour >= quietHourStart && hour < quietHourEnd;
    } else {
      return hour >= quietHourStart || hour < quietHourEnd;
    }
  }

  /// Check if notification should be sent based on preferences
  bool shouldSendNotification(Notification notification) {
    if (!isChannelEnabled(notification.channel)) return false;
    if (!isTypeEnabled(notification.type)) return false;
    if (!pushNotificationsEnabled) return false;
    if (isInQuietHours && notification.priority != NotificationPriority.critical) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'channelSettings': channelSettings.map((k, v) => MapEntry(k.name, v)),
        'typeSettings': typeSettings.map((k, v) => MapEntry(k.name, v)),
        'pushNotificationsEnabled': pushNotificationsEnabled,
        'emailNotificationsEnabled': emailNotificationsEnabled,
        'pushToken': pushToken,
        'quietHourStart': quietHourStart,
        'quietHourEnd': quietHourEnd,
        'respectQuietHours': respectQuietHours,
        'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final channelMap = (json['channelSettings'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(NotificationChannel.values.byName(k), v as bool));
    final typeMap = (json['typeSettings'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(NotificationType.values.byName(k), v as bool));

    return NotificationPreferences(
      userId: json['userId'] as String,
      channelSettings: channelMap,
      typeSettings: typeMap,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] as bool? ?? false,
      pushToken: json['pushToken'] as String?,
      quietHourStart: json['quietHourStart'] as int? ?? 22,
      quietHourEnd: json['quietHourEnd'] as int? ?? 8,
      respectQuietHours: json['respectQuietHours'] as bool? ?? true,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'] as String)
          : null,
    );
  }
}

/// Notification statistics
class NotificationStats {
  final String userId;
  final int totalNotifications;
  final int unreadCount;
  final int readCount;
  final Map<NotificationChannel, int> countByChannel;
  final Map<NotificationType, int> countByType;
  final DateTime? lastReadAt;
  final DateTime? lastNotificationAt;

  NotificationStats({
    required this.userId,
    required this.totalNotifications,
    required this.unreadCount,
    required this.readCount,
    required this.countByChannel,
    required this.countByType,
    this.lastReadAt,
    this.lastNotificationAt,
  });

  /// Get unread percentage
  double get unreadPercentage =>
      totalNotifications == 0 ? 0 : (unreadCount / totalNotifications * 100);

  /// Get count for specific channel
  int getChannelCount(NotificationChannel channel) => countByChannel[channel] ?? 0;

  /// Get count for specific type
  int getTypeCount(NotificationType type) => countByType[type] ?? 0;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalNotifications': totalNotifications,
        'unreadCount': unreadCount,
        'readCount': readCount,
        'countByChannel': countByChannel.map((k, v) => MapEntry(k.name, v)),
        'countByType': countByType.map((k, v) => MapEntry(k.name, v)),
        'lastReadAt': lastReadAt?.toIso8601String(),
        'lastNotificationAt': lastNotificationAt?.toIso8601String(),
      };

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    final channelMap = (json['countByChannel'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(NotificationChannel.values.byName(k), v as int));
    final typeMap = (json['countByType'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(NotificationType.values.byName(k), v as int));

    return NotificationStats(
      userId: json['userId'] as String,
      totalNotifications: json['totalNotifications'] as int,
      unreadCount: json['unreadCount'] as int,
      readCount: json['readCount'] as int,
      countByChannel: channelMap,
      countByType: typeMap,
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt'] as String) : null,
      lastNotificationAt: json['lastNotificationAt'] != null
          ? DateTime.parse(json['lastNotificationAt'] as String)
          : null,
    );
  }
}

/// Notification collection for user
class NotificationCollection {
  final String userId;
  final List<Notification> notifications; // Max 500 recent notifications
  final NotificationPreferences preferences;
  final NotificationStats stats;
  final DateTime generatedAt;

  NotificationCollection({
    required this.userId,
    required this.notifications,
    required this.preferences,
    required this.stats,
    required this.generatedAt,
  });

  /// Get unread notifications
  List<Notification> getUnread() => notifications.where((n) => !n.isRead).toList();

  /// Get read notifications
  List<Notification> getRead() => notifications.where((n) => n.isRead).toList();

  /// Get notifications by channel
  List<Notification> getByChannel(NotificationChannel channel) =>
      notifications.where((n) => n.channel == channel).toList();

  /// Get notifications by type
  List<Notification> getByType(NotificationType type) =>
      notifications.where((n) => n.type == type).toList();

  /// Get notifications by priority
  List<Notification> getByPriority(NotificationPriority priority) =>
      notifications.where((n) => n.priority == priority).toList();

  /// Get recent notifications (last N days)
  List<Notification> getRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return notifications.where((n) => n.createdAt.isAfter(cutoff)).toList();
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'preferences': preferences.toJson(),
        'stats': stats.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory NotificationCollection.fromJson(Map<String, dynamic> json) =>
      NotificationCollection(
        userId: json['userId'] as String,
        notifications: ((json['notifications'] as List?) ?? [])
            .map((n) => Notification.fromJson(n as Map<String, dynamic>))
            .toList(),
        preferences: NotificationPreferences.fromJson(
            json['preferences'] as Map<String, dynamic>),
        stats: NotificationStats.fromJson(json['stats'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
