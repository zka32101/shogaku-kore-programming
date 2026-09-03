import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';

class NotificationState {
  final NotificationCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;
  final List<String> recentlyReadIds; // Notification IDs read in this session

  NotificationState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
    this.recentlyReadIds = const [],
  });

  NotificationState copyWith({
    NotificationCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
    List<String>? recentlyReadIds,
  }) =>
      NotificationState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        recentlyReadIds: recentlyReadIds ?? this.recentlyReadIds,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// Initialize notifications for user
  Future<void> initializeNotifications(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionJson = prefs.getString('notifications_$userId');
      final prefsJson = prefs.getString('notification_prefs_$userId');

      late NotificationPreferences preferences;
      late List<Notification> notifications;

      if (prefsJson != null) {
        preferences = NotificationPreferences.fromJson(
          Map<String, dynamic>.from(prefsJson as Map),
        );
      } else {
        preferences = NotificationPreferences(
          userId: userId,
          channelSettings: {
            for (var ch in NotificationChannel.values) ch: true,
          },
          typeSettings: {
            for (var type in NotificationType.values) type: true,
          },
        );
      }

      if (collectionJson != null) {
        try {
          final parsed = Map<String, dynamic>.from(collectionJson as Map);
          notifications = ((parsed['notifications'] as List?) ?? [])
              .map((n) => Notification.fromJson(n as Map<String, dynamic>))
              .toList();
        } catch (e) {
          notifications = [];
        }
      } else {
        notifications = [];
      }

      // Calculate stats
      final unreadCount = notifications.where((n) => !n.isRead).length;
      final readCount = notifications.length - unreadCount;
      final countByChannel = <NotificationChannel, int>{};
      final countByType = <NotificationType, int>{};

      for (final notif in notifications) {
        countByChannel[notif.channel] = (countByChannel[notif.channel] ?? 0) + 1;
        countByType[notif.type] = (countByType[notif.type] ?? 0) + 1;
      }

      final stats = NotificationStats(
        userId: userId,
        totalNotifications: notifications.length,
        unreadCount: unreadCount,
        readCount: readCount,
        countByChannel: countByChannel,
        countByType: countByType,
        lastReadAt: notifications.firstWhere((n) => n.isRead, orElse: () => null as dynamic)?.readAt,
        lastNotificationAt: notifications.isNotEmpty ? notifications.first.createdAt : null,
      );

      final collection = NotificationCollection(
        userId: userId,
        notifications: notifications,
        preferences: preferences,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistNotifications(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create and add a new notification
  Future<bool> addNotification(
    String userId,
    NotificationType type,
    NotificationPriority priority,
    NotificationChannel channel,
    String title,
    String message, {
    String? imageId,
    Map<String, dynamic>? data,
    DateTime? expiresAt,
    String? actionUrl,
  }) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      // Check if notification should be sent based on preferences
      final notification = Notification(
        notificationId: _generateId('notif'),
        userId: userId,
        type: type,
        priority: priority,
        channel: channel,
        title: title,
        message: message,
        imageId: imageId,
        data: data,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        actionUrl: actionUrl,
        isSent: collection.preferences.shouldSendNotification(
          Notification(
            notificationId: '',
            userId: userId,
            type: type,
            priority: priority,
            channel: channel,
            title: title,
            message: message,
            imageId: imageId,
            data: data,
            createdAt: DateTime.now(),
            expiresAt: expiresAt,
            actionUrl: actionUrl,
          ),
        ),
      );

      // Add to notifications (keep max 500)
      final newNotifications = [notification, ...collection.notifications].take(500).toList();

      // Update stats
      final stats = _calculateStats(collection.stats, newNotifications);

      final updatedCollection = NotificationCollection(
        userId: collection.userId,
        notifications: newNotifications,
        preferences: collection.preferences,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistNotifications(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String userId, String notificationId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedNotifications = collection.notifications.map((n) {
        if (n.notificationId == notificationId && !n.isRead) {
          return Notification(
            notificationId: n.notificationId,
            userId: n.userId,
            type: n.type,
            priority: n.priority,
            channel: n.channel,
            title: n.title,
            message: n.message,
            imageId: n.imageId,
            data: n.data,
            createdAt: n.createdAt,
            expiresAt: n.expiresAt,
            isRead: true,
            readAt: DateTime.now(),
            actionUrl: n.actionUrl,
            isSent: n.isSent,
          );
        }
        return n;
      }).toList();

      final stats = _calculateStats(collection.stats, updatedNotifications);

      final updatedCollection = NotificationCollection(
        userId: collection.userId,
        notifications: updatedNotifications,
        preferences: collection.preferences,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      final newRecentlyReadIds = [...state.recentlyReadIds, notificationId];

      state = state.copyWith(
        collection: updatedCollection,
        recentlyReadIds: newRecentlyReadIds,
      );

      await _persistNotifications(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedNotifications = collection.notifications.map((n) {
        if (!n.isRead) {
          return Notification(
            notificationId: n.notificationId,
            userId: n.userId,
            type: n.type,
            priority: n.priority,
            channel: n.channel,
            title: n.title,
            message: n.message,
            imageId: n.imageId,
            data: n.data,
            createdAt: n.createdAt,
            expiresAt: n.expiresAt,
            isRead: true,
            readAt: DateTime.now(),
            actionUrl: n.actionUrl,
            isSent: n.isSent,
          );
        }
        return n;
      }).toList();

      final stats = _calculateStats(collection.stats, updatedNotifications);

      final updatedCollection = NotificationCollection(
        userId: collection.userId,
        notifications: updatedNotifications,
        preferences: collection.preferences,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      final recentlyReadIds = [
        ...state.recentlyReadIds,
        ...updatedNotifications.where((n) => n.isRead).map((n) => n.notificationId),
      ];

      state = state.copyWith(
        collection: updatedCollection,
        recentlyReadIds: recentlyReadIds,
      );

      await _persistNotifications(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String userId, String notificationId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedNotifications =
          collection.notifications.where((n) => n.notificationId != notificationId).toList();

      final stats = _calculateStats(collection.stats, updatedNotifications);

      final updatedCollection = NotificationCollection(
        userId: collection.userId,
        notifications: updatedNotifications,
        preferences: collection.preferences,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistNotifications(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear expired notifications
  Future<int> clearExpiredNotifications(String userId) async {
    try {
      final collection = state.collection;
      if (collection == null) return 0;

      final beforeCount = collection.notifications.length;
      final updatedNotifications =
          collection.notifications.where((n) => !n.isExpired).toList();
      final clearedCount = beforeCount - updatedNotifications.length;

      if (clearedCount > 0) {
        final stats = _calculateStats(collection.stats, updatedNotifications);

        final updatedCollection = NotificationCollection(
          userId: collection.userId,
          notifications: updatedNotifications,
          preferences: collection.preferences,
          stats: stats,
          generatedAt: DateTime.now(),
        );

        state = state.copyWith(collection: updatedCollection);
        await _persistNotifications(userId);
      }

      return clearedCount;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  /// Update notification preferences
  Future<bool> updatePreferences(String userId, NotificationPreferences newPreferences) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final updatedCollection = NotificationCollection(
        userId: collection.userId,
        notifications: collection.notifications,
        preferences: newPreferences,
        stats: collection.stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistNotifications(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Enable/disable channel
  Future<bool> setChannelEnabled(
    String userId,
    NotificationChannel channel,
    bool enabled,
  ) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final newSettings = Map<NotificationChannel, bool>.from(collection.preferences.channelSettings);
      newSettings[channel] = enabled;

      final newPreferences = NotificationPreferences(
        userId: collection.preferences.userId,
        channelSettings: newSettings,
        typeSettings: collection.preferences.typeSettings,
        pushNotificationsEnabled: collection.preferences.pushNotificationsEnabled,
        emailNotificationsEnabled: collection.preferences.emailNotificationsEnabled,
        pushToken: collection.preferences.pushToken,
        quietHourStart: collection.preferences.quietHourStart,
        quietHourEnd: collection.preferences.quietHourEnd,
        respectQuietHours: collection.preferences.respectQuietHours,
      );

      return await updatePreferences(userId, newPreferences);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get unread count
  int getUnreadCount() => state.collection?.stats.unreadCount ?? 0;

  /// Get total notification count
  int getTotalCount() => state.collection?.stats.totalNotifications ?? 0;

  /// Clear recently read
  void clearRecentlyRead() {
    state = state.copyWith(recentlyReadIds: []);
  }

  /// Calculate updated stats
  NotificationStats _calculateStats(
    NotificationStats oldStats,
    List<Notification> notifications,
  ) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final readCount = notifications.length - unreadCount;
    final countByChannel = <NotificationChannel, int>{};
    final countByType = <NotificationType, int>{};

    for (final notif in notifications) {
      countByChannel[notif.channel] = (countByChannel[notif.channel] ?? 0) + 1;
      countByType[notif.type] = (countByType[notif.type] ?? 0) + 1;
    }

    return NotificationStats(
      userId: oldStats.userId,
      totalNotifications: notifications.length,
      unreadCount: unreadCount,
      readCount: readCount,
      countByChannel: countByChannel,
      countByType: countByType,
      lastReadAt: notifications.firstWhere((n) => n.isRead, orElse: () => null as dynamic)?.readAt,
      lastNotificationAt: notifications.isNotEmpty ? notifications.first.createdAt : oldStats.lastNotificationAt,
    );
  }

  Future<void> _persistNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection = state.collection;
      if (collection != null) {
        await prefs.setString(
          'notifications_$userId',
          collection.toJson().toString(),
        );
        await prefs.setString(
          'notification_prefs_$userId',
          collection.preferences.toJson().toString(),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }
}

final notificationProvider = StateNotifierProvider.autoDispose<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);

final notificationCollectionProvider = Provider.autoDispose<NotificationCollection?>(
  (ref) => ref.watch(notificationProvider).collection,
);

final unreadNotificationsProvider = Provider.autoDispose<List<Notification>>(
  (ref) => ref.watch(notificationProvider).collection?.getUnread() ?? [],
);

final notificationCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(notificationProvider).collection?.stats.unreadCount ?? 0,
);

final notificationsByChannelProvider =
    Provider.autoDispose.family<List<Notification>, NotificationChannel>(
  (ref, channel) => ref.watch(notificationProvider).collection?.getByChannel(channel) ?? [],
);

final notificationsByTypeProvider = Provider.autoDispose.family<List<Notification>, NotificationType>(
  (ref, type) => ref.watch(notificationProvider).collection?.getByType(type) ?? [],
);

final notificationPreferencesProvider = Provider.autoDispose<NotificationPreferences?>(
  (ref) => ref.watch(notificationProvider).collection?.preferences,
);

final notificationStatsProvider = Provider.autoDispose<NotificationStats?>(
  (ref) => ref.watch(notificationProvider).collection?.stats,
);

final recentNotificationsProvider = Provider.autoDispose.family<List<Notification>, int>(
  (ref, days) => ref.watch(notificationProvider).collection?.getRecent(days) ?? [],
);
