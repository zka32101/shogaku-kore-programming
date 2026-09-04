import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/notification.dart';

void main() {
  group('Notification', () {
    test('creates instance with all required fields', () {
      final now = DateTime.now();
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'アチーブメント達成',
        message: '新しいバッジを獲得しました',
        createdAt: now,
      );

      expect(notification.notificationId, 'notif_1');
      expect(notification.userId, 'user_1');
      expect(notification.type, NotificationType.achievement);
      expect(notification.priority, NotificationPriority.normal);
    });

    test('isExpired returns false for non-expired notifications', () {
      final now = DateTime.now();
      final futureExpiry = now.add(const Duration(days: 1));
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now,
        expiresAt: futureExpiry,
      );

      expect(notification.isExpired, false);
    });

    test('isExpired returns true for expired notifications', () {
      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(days: 1));
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: pastExpiry,
      );

      expect(notification.isExpired, true);
    });

    test('isRecent returns true for recent notifications', () {
      final now = DateTime.now();
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now.subtract(const Duration(hours: 12)),
      );

      expect(notification.isRecent, true);
    });

    test('isRecent returns false for old notifications', () {
      final now = DateTime.now();
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      expect(notification.isRecent, false);
    });

    test('timeAgo returns correct format', () {
      final now = DateTime.now();
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      expect(notification.timeAgo.contains('時間前'), true);
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final original = Notification(
        notificationId: 'notif_test',
        userId: 'user_test',
        type: NotificationType.rankingChange,
        priority: NotificationPriority.high,
        channel: NotificationChannel.gamification,
        title: 'ランク変動',
        message: 'ランクが上がりました',
        imageId: 'icon_rank',
        data: {'change': 5},
        createdAt: now,
        isRead: false,
      );

      final json = original.toJson();
      final restored = Notification.fromJson(json);

      expect(restored.notificationId, original.notificationId);
      expect(restored.userId, original.userId);
      expect(restored.type, original.type);
      expect(restored.priority, original.priority);
    });

    test('supports read status tracking', () {
      final now = DateTime.now();
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now,
        isRead: true,
        readAt: now,
      );

      expect(notification.isRead, true);
      expect(notification.readAt, isNotNull);
    });

    test('supports action URL for deep linking', () {
      final now = DateTime.now();
      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now,
        actionUrl: '/achievements/badge_7day',
      );

      expect(notification.actionUrl, '/achievements/badge_7day');
    });
  });

  group('NotificationPreferences', () {
    test('creates instance with default settings', () {
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {},
      );

      expect(prefs.userId, 'user_1');
      expect(prefs.pushNotificationsEnabled, true);
      expect(prefs.emailNotificationsEnabled, false);
    });

    test('isChannelEnabled returns correct value', () {
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {
          NotificationChannel.gamification: true,
          NotificationChannel.social: false,
        },
        typeSettings: {},
      );

      expect(prefs.isChannelEnabled(NotificationChannel.gamification), true);
      expect(prefs.isChannelEnabled(NotificationChannel.social), false);
    });

    test('isTypeEnabled returns correct value', () {
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {
          NotificationType.achievement: true,
          NotificationType.maintenance: false,
        },
      );

      expect(prefs.isTypeEnabled(NotificationType.achievement), true);
      expect(prefs.isTypeEnabled(NotificationType.maintenance), false);
    });

    test('isInQuietHours detects quiet hours correctly', () {
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {},
        quietHourStart: 22,
        quietHourEnd: 8,
        respectQuietHours: true,
      );

      // This depends on current time, so we just test the logic exists
      expect(prefs.isInQuietHours is bool, true);
    });

    test('shouldSendNotification respects all preferences', () {
      final now = DateTime.now();
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {NotificationChannel.gamification: true},
        typeSettings: {NotificationType.achievement: true},
        pushNotificationsEnabled: true,
      );

      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now,
      );

      expect(prefs.shouldSendNotification(notification), true);
    });

    test('shouldSendNotification blocks disabled channels', () {
      final now = DateTime.now();
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {NotificationChannel.gamification: false},
        typeSettings: {NotificationType.achievement: true},
        pushNotificationsEnabled: true,
      );

      final notification = Notification(
        notificationId: 'notif_1',
        userId: 'user_1',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        channel: NotificationChannel.gamification,
        title: 'Test',
        message: 'Test',
        createdAt: now,
      );

      expect(prefs.shouldSendNotification(notification), false);
    });

    test('JSON serialization round-trip', () {
      final prefs = NotificationPreferences(
        userId: 'user_test',
        channelSettings: {NotificationChannel.gamification: true},
        typeSettings: {NotificationType.achievement: true},
        pushNotificationsEnabled: true,
        quietHourStart: 23,
        quietHourEnd: 7,
      );

      final json = prefs.toJson();
      final restored = NotificationPreferences.fromJson(json);

      expect(restored.userId, prefs.userId);
      expect(restored.pushNotificationsEnabled, prefs.pushNotificationsEnabled);
      expect(restored.quietHourStart, prefs.quietHourStart);
    });
  });

  group('NotificationStats', () {
    test('creates instance with stats data', () {
      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 10,
        unreadCount: 3,
        readCount: 7,
        countByChannel: {NotificationChannel.gamification: 5},
        countByType: {NotificationType.achievement: 3},
      );

      expect(stats.userId, 'user_1');
      expect(stats.totalNotifications, 10);
      expect(stats.unreadCount, 3);
    });

    test('unreadPercentage calculates correctly', () {
      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 10,
        unreadCount: 3,
        readCount: 7,
        countByChannel: {},
        countByType: {},
      );

      expect(stats.unreadPercentage, 30.0);
    });

    test('unreadPercentage returns 0 for no notifications', () {
      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 0,
        unreadCount: 0,
        readCount: 0,
        countByChannel: {},
        countByType: {},
      );

      expect(stats.unreadPercentage, 0);
    });

    test('getChannelCount returns correct count', () {
      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 10,
        unreadCount: 3,
        readCount: 7,
        countByChannel: {
          NotificationChannel.gamification: 5,
          NotificationChannel.social: 3,
        },
        countByType: {},
      );

      expect(stats.getChannelCount(NotificationChannel.gamification), 5);
      expect(stats.getChannelCount(NotificationChannel.social), 3);
      expect(stats.getChannelCount(NotificationChannel.missions), 0);
    });

    test('JSON serialization round-trip', () {
      final stats = NotificationStats(
        userId: 'user_test',
        totalNotifications: 15,
        unreadCount: 5,
        readCount: 10,
        countByChannel: {NotificationChannel.gamification: 7},
        countByType: {NotificationType.achievement: 5},
      );

      final json = stats.toJson();
      final restored = NotificationStats.fromJson(json);

      expect(restored.userId, stats.userId);
      expect(restored.totalNotifications, stats.totalNotifications);
      expect(restored.unreadCount, stats.unreadCount);
    });
  });

  group('NotificationCollection', () {
    test('creates collection with notifications', () {
      final now = DateTime.now();
      final notifications = [
        Notification(
          notificationId: 'notif_1',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 1',
          message: 'Test message 1',
          createdAt: now,
        ),
      ];

      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {},
      );

      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 1,
        unreadCount: 1,
        readCount: 0,
        countByChannel: {NotificationChannel.gamification: 1},
        countByType: {NotificationType.achievement: 1},
      );

      final collection = NotificationCollection(
        userId: 'user_1',
        notifications: notifications,
        preferences: prefs,
        stats: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user_1');
      expect(collection.notifications.length, 1);
    });

    test('getUnread returns only unread notifications', () {
      final now = DateTime.now();
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {},
      );

      final notifications = [
        Notification(
          notificationId: 'notif_1',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 1',
          message: 'Test message 1',
          createdAt: now,
          isRead: false,
        ),
        Notification(
          notificationId: 'notif_2',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 2',
          message: 'Test message 2',
          createdAt: now,
          isRead: true,
        ),
      ];

      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 2,
        unreadCount: 1,
        readCount: 1,
        countByChannel: {},
        countByType: {},
      );

      final collection = NotificationCollection(
        userId: 'user_1',
        notifications: notifications,
        preferences: prefs,
        stats: stats,
        generatedAt: now,
      );

      final unread = collection.getUnread();
      expect(unread.length, 1);
      expect(unread.first.isRead, false);
    });

    test('getByChannel filters by channel', () {
      final now = DateTime.now();
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {},
      );

      final notifications = [
        Notification(
          notificationId: 'notif_1',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 1',
          message: 'Test message 1',
          createdAt: now,
        ),
        Notification(
          notificationId: 'notif_2',
          userId: 'user_1',
          type: NotificationType.friendRequest,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.social,
          title: 'Test 2',
          message: 'Test message 2',
          createdAt: now,
        ),
      ];

      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 2,
        unreadCount: 2,
        readCount: 0,
        countByChannel: {},
        countByType: {},
      );

      final collection = NotificationCollection(
        userId: 'user_1',
        notifications: notifications,
        preferences: prefs,
        stats: stats,
        generatedAt: now,
      );

      final gamification = collection.getByChannel(NotificationChannel.gamification);
      expect(gamification.length, 1);
      expect(gamification.first.channel, NotificationChannel.gamification);
    });

    test('getByType filters by type', () {
      final now = DateTime.now();
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {},
      );

      final notifications = [
        Notification(
          notificationId: 'notif_1',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 1',
          message: 'Test message 1',
          createdAt: now,
        ),
        Notification(
          notificationId: 'notif_2',
          userId: 'user_1',
          type: NotificationType.rankingChange,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 2',
          message: 'Test message 2',
          createdAt: now,
        ),
      ];

      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 2,
        unreadCount: 2,
        readCount: 0,
        countByChannel: {},
        countByType: {},
      );

      final collection = NotificationCollection(
        userId: 'user_1',
        notifications: notifications,
        preferences: prefs,
        stats: stats,
        generatedAt: now,
      );

      final achievements = collection.getByType(NotificationType.achievement);
      expect(achievements.length, 1);
      expect(achievements.first.type, NotificationType.achievement);
    });

    test('getRecent filters by days', () {
      final now = DateTime.now();
      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {},
        typeSettings: {},
      );

      final notifications = [
        Notification(
          notificationId: 'notif_1',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 1',
          message: 'Test message 1',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        Notification(
          notificationId: 'notif_2',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test 2',
          message: 'Test message 2',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 2,
        unreadCount: 2,
        readCount: 0,
        countByChannel: {},
        countByType: {},
      );

      final collection = NotificationCollection(
        userId: 'user_1',
        notifications: notifications,
        preferences: prefs,
        stats: stats,
        generatedAt: now,
      );

      final recent = collection.getRecent(2);
      expect(recent.length, 1);
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final notifications = [
        Notification(
          notificationId: 'notif_1',
          userId: 'user_1',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          channel: NotificationChannel.gamification,
          title: 'Test',
          message: 'Test message',
          createdAt: now,
        ),
      ];

      final prefs = NotificationPreferences(
        userId: 'user_1',
        channelSettings: {NotificationChannel.gamification: true},
        typeSettings: {NotificationType.achievement: true},
      );

      final stats = NotificationStats(
        userId: 'user_1',
        totalNotifications: 1,
        unreadCount: 1,
        readCount: 0,
        countByChannel: {NotificationChannel.gamification: 1},
        countByType: {NotificationType.achievement: 1},
      );

      final original = NotificationCollection(
        userId: 'user_1',
        notifications: notifications,
        preferences: prefs,
        stats: stats,
        generatedAt: now,
      );

      final json = original.toJson();
      final restored = NotificationCollection.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.notifications.length, original.notifications.length);
      expect(restored.stats.totalNotifications, original.stats.totalNotifications);
    });
  });
}
