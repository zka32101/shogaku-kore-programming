import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/notification.dart';
import 'package:shogaku_kore_programming/providers/notification_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('NotificationNotifier', () {
    test('initializes with empty state', () {
      final notifier = NotificationNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeNotifications creates default preferences', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final state = container.read(notificationProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.preferences.userId, 'test_user');
      expect(state.collection!.preferences.pushNotificationsEnabled, true);
    });

    test('initializeNotifications creates empty notification list', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final state = container.read(notificationProvider);
      expect(state.collection!.notifications.isEmpty, true);
      expect(state.collection!.stats.totalNotifications, 0);
    });

    test('addNotification creates new notification', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final success = await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'アチーブメント',
        'バッジを獲得しました',
      );

      expect(success, true);

      final state = container.read(notificationProvider);
      expect(state.collection!.notifications.length, 1);
      expect(state.collection!.stats.unreadCount, 1);
    });

    test('addNotification respects preferences', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      // Disable gamification channel
      await notifier.setChannelEnabled('test_user', NotificationChannel.gamification, false);

      final success = await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      // Should still add, but isSent may be false
      expect(success, true);
    });

    test('addNotification supports custom data', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final success = await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
        data: {'achievementId': 'badge_7day', 'xpReward': 100},
      );

      expect(success, true);

      final state = container.read(notificationProvider);
      expect(state.collection!.notifications.first.data?['achievementId'], 'badge_7day');
    });

    test('markAsRead updates read status', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      var state = container.read(notificationProvider);
      final notificationId = state.collection!.notifications.first.notificationId;
      expect(state.collection!.stats.unreadCount, 1);

      await notifier.markAsRead('test_user', notificationId);

      state = container.read(notificationProvider);
      expect(state.collection!.stats.unreadCount, 0);
      expect(state.collection!.notifications.first.isRead, true);
    });

    test('markAsRead adds to recently read', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      var state = container.read(notificationProvider);
      final notificationId = state.collection!.notifications.first.notificationId;

      await notifier.markAsRead('test_user', notificationId);

      state = container.read(notificationProvider);
      expect(state.recentlyReadIds.contains(notificationId), true);
    });

    test('markAllAsRead marks all notifications as read', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test 1',
        'Test message 1',
      );

      await notifier.addNotification(
        'test_user',
        NotificationType.rankingChange,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test 2',
        'Test message 2',
      );

      var state = container.read(notificationProvider);
      expect(state.collection!.stats.unreadCount, 2);

      await notifier.markAllAsRead('test_user');

      state = container.read(notificationProvider);
      expect(state.collection!.stats.unreadCount, 0);
      expect(state.collection!.notifications.every((n) => n.isRead), true);
    });

    test('deleteNotification removes notification', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      var state = container.read(notificationProvider);
      final notificationId = state.collection!.notifications.first.notificationId;
      expect(state.collection!.notifications.length, 1);

      await notifier.deleteNotification('test_user', notificationId);

      state = container.read(notificationProvider);
      expect(state.collection!.notifications.length, 0);
    });

    test('clearExpiredNotifications removes expired ones', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(days: 1));

      // Add expired notification
      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Expired',
        'Test message',
        expiresAt: pastExpiry,
      );

      // Add valid notification
      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Valid',
        'Test message',
        expiresAt: now.add(const Duration(days: 1)),
      );

      var state = container.read(notificationProvider);
      expect(state.collection!.notifications.length, 2);

      final cleared = await notifier.clearExpiredNotifications('test_user');

      state = container.read(notificationProvider);
      expect(cleared, greaterThan(0));
      expect(state.collection!.notifications.length, lessThan(2));
    });

    test('setChannelEnabled updates preferences', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      var state = container.read(notificationProvider);
      expect(state.collection!.preferences.isChannelEnabled(NotificationChannel.social), true);

      await notifier.setChannelEnabled('test_user', NotificationChannel.social, false);

      state = container.read(notificationProvider);
      expect(state.collection!.preferences.isChannelEnabled(NotificationChannel.social), false);
    });

    test('updatePreferences replaces preferences', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final newPrefs = NotificationPreferences(
        userId: 'test_user',
        channelSettings: {NotificationChannel.gamification: false},
        typeSettings: {},
        pushNotificationsEnabled: false,
      );

      await notifier.updatePreferences('test_user', newPrefs);

      final state = container.read(notificationProvider);
      expect(state.collection!.preferences.pushNotificationsEnabled, false);
    });

    test('getUnreadCount returns correct count', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test 1',
        'Test',
      );

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test 2',
        'Test',
      );

      expect(notifier.getUnreadCount(), 2);
    });

    test('getTotalCount returns all notifications', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test 1',
        'Test',
      );

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test 2',
        'Test',
      );

      expect(notifier.getTotalCount(), 2);
    });

    test('clearRecentlyRead empties list', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      var state = container.read(notificationProvider);
      final notificationId = state.collection!.notifications.first.notificationId;

      await notifier.markAsRead('test_user', notificationId);

      state = container.read(notificationProvider);
      expect(state.recentlyReadIds.isNotEmpty, true);

      notifier.clearRecentlyRead();

      state = container.read(notificationProvider);
      expect(state.recentlyReadIds.isEmpty, true);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('persist_test');

      await notifier.addNotification(
        'persist_test',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('notifications_persist_test'), true);
      expect(prefs.containsKey('notification_prefs_persist_test'), true);
    });

    test('handles max 500 notifications', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      // Add multiple notifications
      for (int i = 0; i < 510; i++) {
        await notifier.addNotification(
          'test_user',
          NotificationType.achievement,
          NotificationPriority.normal,
          NotificationChannel.gamification,
          'Test $i',
          'Test message $i',
        );
      }

      final state = container.read(notificationProvider);
      expect(state.collection!.notifications.length, lessThanOrEqualTo(500));
    });

    test('supports different notification types', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final types = [
        NotificationType.achievement,
        NotificationType.rankingChange,
        NotificationType.challengeComplete,
      ];

      for (var type in types) {
        await notifier.addNotification(
          'test_user',
          type,
          NotificationPriority.normal,
          NotificationChannel.gamification,
          'Test',
          'Test message',
        );
      }

      final state = container.read(notificationProvider);
      expect(state.collection!.notifications.length, types.length);
    });

    test('supports different notification priorities', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final priorities = [
        NotificationPriority.low,
        NotificationPriority.normal,
        NotificationPriority.high,
        NotificationPriority.critical,
      ];

      for (var priority in priorities) {
        await notifier.addNotification(
          'test_user',
          NotificationType.achievement,
          priority,
          NotificationChannel.gamification,
          'Test',
          'Test message',
        );
      }

      final state = container.read(notificationProvider);
      expect(state.collection!.notifications.length, priorities.length);
    });

    test('supports different notification channels', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final channels = [
        NotificationChannel.gamification,
        NotificationChannel.social,
        NotificationChannel.shop,
        NotificationChannel.missions,
      ];

      for (var channel in channels) {
        await notifier.addNotification(
          'test_user',
          NotificationType.achievement,
          NotificationPriority.normal,
          channel,
          'Test',
          'Test message',
        );
      }

      final state = container.read(notificationProvider);
      expect(state.collection!.notifications.length, channels.length);
    });
  });

  group('Riverpod Providers', () {
    test('notificationCollectionProvider provides collection', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final collection = container.read(notificationCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('unreadNotificationsProvider returns unread only', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      var unread = container.read(unreadNotificationsProvider);
      expect(unread.length, 1);

      var state = container.read(notificationProvider);
      final notifId = state.collection!.notifications.first.notificationId;
      await notifier.markAsRead('test_user', notifId);

      unread = container.read(unreadNotificationsProvider);
      expect(unread.isEmpty, true);
    });

    test('notificationCountProvider returns unread count', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      final count = container.read(notificationCountProvider);
      expect(count, 1);
    });

    test('notificationsByChannelProvider filters by channel', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      final gamification =
          container.read(notificationsByChannelProvider(NotificationChannel.gamification));
      expect(gamification.length, 1);

      final social = container.read(notificationsByChannelProvider(NotificationChannel.social));
      expect(social.isEmpty, true);
    });

    test('notificationStatsProvider provides stats', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      final stats = container.read(notificationStatsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('recentNotificationsProvider returns recent only', () async {
      final notifier = container.read(notificationProvider.notifier);
      await notifier.initializeNotifications('test_user');

      await notifier.addNotification(
        'test_user',
        NotificationType.achievement,
        NotificationPriority.normal,
        NotificationChannel.gamification,
        'Test',
        'Test message',
      );

      final recent = container.read(recentNotificationsProvider(1));
      expect(recent.length, 1);

      final old = container.read(recentNotificationsProvider(30));
      expect(old.length, greaterThanOrEqualTo(1));
    });
  });
}
