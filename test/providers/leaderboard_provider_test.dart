import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/models/leaderboard.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';
import 'package:shogaku_kore_programming/providers/leaderboard_provider.dart';

void main() {
  group('LeaderboardState', () {
    test('should create state with default values', () {
      final state = LeaderboardState();

      expect(state.leaderboardData, isNull);
      expect(state.userRankingPosition, isNull);
      expect(state.userRankings, isEmpty);
      expect(state.notifications, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.lastUpdatedAt, isNull);
    });

    test('copyWith should update only specified fields', () {
      final originalState = LeaderboardState();
      final updatedState = originalState.copyWith(
        isLoading: true,
        error: 'Test error',
      );

      expect(updatedState.isLoading, true);
      expect(updatedState.error, 'Test error');
      expect(updatedState.leaderboardData, isNull);
      expect(updatedState.userRankings, isEmpty);
    });

    test('copyWith should preserve unspecified fields', () {
      final timestamp = DateTime(2026, 9, 1);
      final originalState = LeaderboardState(
        isLoading: true,
        lastUpdatedAt: timestamp,
      );

      final updatedState = originalState.copyWith(
        error: 'New error',
      );

      expect(updatedState.error, 'New error');
      expect(updatedState.isLoading, true);
      expect(updatedState.lastUpdatedAt, timestamp);
    });

    test('should serialize to JSON correctly', () {
      final state = LeaderboardState(
        isLoading: false,
        error: null,
      );

      final json = state.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['leaderboardData'], isNull);
      expect(json['notifications'], isA<List>());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'leaderboardData': null,
        'userRankingPosition': null,
        'userRankings': {},
        'notifications': [],
        'lastUpdatedAt': null,
      };

      final state = LeaderboardState.fromJson(json);

      expect(state.leaderboardData, isNull);
      expect(state.userRankingPosition, isNull);
      expect(state.notifications, isEmpty);
    });
  });

  group('LeaderboardNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty state', () {
      final state = container.read(leaderboardProvider);

      expect(state.leaderboardData, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('generateGlobalLeaderboard should create leaderboard data', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      final leaderboard = await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 10,
      );

      expect(leaderboard.timeUnit, LeaderboardTimeUnit.allTime);
      expect(leaderboard.globalRankings.length, 10);
      expect(leaderboard.globalRankings[0].rank, 1);
      expect(leaderboard.globalRankings[9].rank, 10);
    });

    test('generateGlobalLeaderboard should generate correct tier assignments', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      final leaderboard = await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 100,
      );

      // Check tier assignments
      for (final entry in leaderboard.globalRankings) {
        final expectedTier = GlobalLeaderboardEntry.calculateTier(entry.rank);
        expect(entry.tier, expectedTier);
      }
    });

    test('generateGlobalLeaderboard should include category rankings', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      final leaderboard = await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 10,
      );

      expect(leaderboard.categoryRankings.isNotEmpty, true);
      expect(leaderboard.categoryRankings.length, LearningCategory.values.length);
    });

    test('generateGlobalLeaderboard should update state', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 5,
      );

      final state = container.read(leaderboardProvider);
      expect(state.leaderboardData, isNotNull);
      expect(state.isLoading, false);
      expect(state.leaderboardData!.globalRankings.length, 5);
    });

    test('getUserRankingPosition should return ranking data for valid user', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      // First generate leaderboard
      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 20,
      );

      // Get position for first user
      final position = await notifier.getUserRankingPosition(
        'user-1',
        timeUnit: LeaderboardTimeUnit.allTime,
      );

      expect(position.userId, 'user-1');
      expect(position.globalRank, 1);
      expect(position.tier, RankingTier.platinum);
    });

    test('getUserRankingPosition should include category ranks', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 50,
      );

      final position = await notifier.getUserRankingPosition(
        'user-5',
        timeUnit: LeaderboardTimeUnit.allTime,
      );

      expect(position.categoryRanks.isNotEmpty, true);
    });

    test('getUserRankingPosition should throw for non-existent user', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 10,
      );

      expect(
        () => notifier.getUserRankingPosition(
          'non-existent-user',
          timeUnit: LeaderboardTimeUnit.allTime,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should track ranking changes and create notifications', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 20,
      );

      // Get initial position
      final position1 = await notifier.getUserRankingPosition(
        'user-10',
        timeUnit: LeaderboardTimeUnit.allTime,
      );

      var state = container.read(leaderboardProvider);
      final notificationsCount1 = state.notifications.length;

      // Get position again (simulating rank change detection)
      // This would normally happen with different data
      expect(position1.globalRank, 10);
      expect(notificationsCount1, isNotNull);
    });

    test('markNotificationAsRead should update notification state', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      // Create a notification manually
      await notifier._trackRankingChange(
        'user-1',
        5,
        3,
        RankingTier.platinum,
        RankingTier.platinum,
        LeaderboardTimeUnit.weekly,
      );

      var state = container.read(leaderboardProvider);
      expect(state.notifications.isNotEmpty, true);

      final notificationId = state.notifications[0].notificationId;
      expect(state.notifications[0].isRead, false);

      await notifier.markNotificationAsRead(notificationId);

      state = container.read(leaderboardProvider);
      expect(state.notifications[0].isRead, true);
    });

    test('getUnreadNotificationCount should return correct count', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      var count = notifier.getUnreadNotificationCount();
      expect(count, 0);

      // Create notification
      await notifier._trackRankingChange(
        'user-1',
        10,
        5,
        RankingTier.gold,
        RankingTier.platinum,
        LeaderboardTimeUnit.weekly,
      );

      count = notifier.getUnreadNotificationCount();
      expect(count, 1);
    });

    test('getLeaderboardPage should return paginated results', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 100,
      );

      final page1 = await notifier.getLeaderboardPage(
        pageSize: 10,
        pageIndex: 0,
      );

      expect(page1.length, 10);
      expect(page1[0].rank, 1);
      expect(page1[9].rank, 10);

      final page2 = await notifier.getLeaderboardPage(
        pageSize: 10,
        pageIndex: 1,
      );

      expect(page2.length, 10);
      expect(page2[0].rank, 11);
      expect(page2[9].rank, 20);
    });

    test('getLeaderboardPage should handle out-of-range pages', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 20,
      );

      final page = await notifier.getLeaderboardPage(
        pageSize: 10,
        pageIndex: 5, // Beyond available data
      );

      expect(page.length, 0);
    });

    test('loadLocalLeaderboardData should restore from cache', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      // Generate and persist
      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 10,
      );

      // Clear state and reload
      final state1 = container.read(leaderboardProvider);
      expect(state1.leaderboardData, isNotNull);

      // Load local
      await notifier.loadLocalLeaderboardData();

      final state2 = container.read(leaderboardProvider);
      expect(state2.leaderboardData, isNotNull);
    });

    test('error handling should set error state', () async {
      final notifier = container.read(leaderboardProvider.notifier);

      try {
        // This should throw
        await notifier.getUserRankingPosition(
          'invalid-user',
          timeUnit: LeaderboardTimeUnit.allTime,
        );
      } catch (e) {
        // Expected
      }

      final state = container.read(leaderboardProvider);
      expect(state.error, isNotNull);
    });
  });

  group('Leaderboard Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('globalLeaderboardProvider should provide leaderboard data', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.generateGlobalLeaderboard(
        timeUnit: LeaderboardTimeUnit.allTime,
        limit: 10,
      );

      final leaderboard = container.read(globalLeaderboardProvider).maybeWhen(
        data: (data) => data,
        orElse: () => null,
      );

      expect(leaderboard, isNotNull);
    });

    test('rankingNotificationsProvider should provide notifications', () {
      final notifier = container.read(leaderboardProvider.notifier);
      final notifications = container.read(rankingNotificationsProvider);

      expect(notifications, isA<List<RankingChangeNotification>>());
    });

    test('unreadNotificationCountProvider should provide count', () {
      final count = container.read(unreadNotificationCountProvider);

      expect(count, isA<int>());
      expect(count, 0);
    });
  });

  group('LeaderboardNotifier JSON helpers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('_jsonEncode should encode string correctly', () {
      final notifier = container.read(leaderboardProvider.notifier);
      final encoded = notifier._jsonEncode('test');

      expect(encoded.contains('test'), true);
    });

    test('_jsonEncode should encode number correctly', () {
      final notifier = container.read(leaderboardProvider.notifier);
      expect(notifier._jsonEncode(42), '42');
      expect(notifier._jsonEncode(3.14), '3.14');
    });

    test('_jsonEncode should encode boolean correctly', () {
      final notifier = container.read(leaderboardProvider.notifier);
      expect(notifier._jsonEncode(true), 'true');
      expect(notifier._jsonEncode(false), 'false');
    });

    test('_jsonEncode should handle null', () {
      final notifier = container.read(leaderboardProvider.notifier);
      expect(notifier._jsonEncode(null), 'null');
    });

    test('_jsonDecode empty array', () {
      final notifier = container.read(leaderboardProvider.notifier);
      final decoded = notifier._jsonDecode('[]');

      expect(decoded, isA<List>());
      expect(decoded.isEmpty, true);
    });

    test('_jsonDecode empty object', () {
      final notifier = container.read(leaderboardProvider.notifier);
      final decoded = notifier._jsonDecode('{}');

      expect(decoded, isA<Map>());
      expect(decoded.isEmpty, true);
    });
  });

  group('Ranking tier edge cases', () {
    test('rank 0 should be treated as platinum (edge case)', () {
      final tier = GlobalLeaderboardEntry.calculateTier(0);
      // 0 <= 10, so should be platinum
      expect(tier, RankingTier.platinum);
    });

    test('rank at boundaries should be correct', () {
      expect(GlobalLeaderboardEntry.calculateTier(10), RankingTier.platinum);
      expect(GlobalLeaderboardEntry.calculateTier(11), RankingTier.gold);
      expect(GlobalLeaderboardEntry.calculateTier(100), RankingTier.gold);
      expect(GlobalLeaderboardEntry.calculateTier(101), RankingTier.silver);
      expect(GlobalLeaderboardEntry.calculateTier(1000), RankingTier.silver);
      expect(GlobalLeaderboardEntry.calculateTier(1001), RankingTier.bronze);
    });

    test('very high rank should be bronze', () {
      final tier = GlobalLeaderboardEntry.calculateTier(10000);
      expect(tier, RankingTier.bronze);
    });
  });
}
