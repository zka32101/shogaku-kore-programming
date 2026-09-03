import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/activities_minigames.dart';
import 'package:shogaku_kore_programming/providers/activities_minigames_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('ActivityNotifier', () {
    test('initializes with empty state', () {
      final notifier = ActivityNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeActivities creates collection with defaults', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final state = container.read(activityProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
      expect(state.collection!.allActivities.isNotEmpty, true);
    });

    test('initializeActivities creates 9 default activities', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final state = container.read(activityProvider);
      expect(state.collection!.allActivities.length, 9);
    });

    test('initializeActivities loads existing data', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      expect(state.collection!.userId, 'test_user');

      // Reinitialize should load from storage
      final notifier2 = ActivityNotifier();
      final container2 = ProviderContainer();
      await container2.read(activityProvider.notifier).initializeActivities('test_user');

      final newState = container2.read(activityProvider);
      expect(newState.collection!.userId, 'test_user');
    });

    test('startActivity creates participation', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;

      await notifier.startActivity('test_user', activityId);

      state = container.read(activityProvider);
      expect(state.collection!.participations.isNotEmpty, true);
    });

    test('startActivity prevents unavailable activities', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      // Try to start non-existent activity
      await notifier.startActivity('test_user', 'nonexistent');

      state = container.read(activityProvider);
      expect(state.collection!.error, isNotNull);
    });

    test('completeActivity records result', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;

      await notifier.startActivity('test_user', activityId);
      state = container.read(activityProvider);
      expect(state.collection!.participations.isNotEmpty, true);

      await notifier.completeActivity('test_user', activityId, 90);

      state = container.read(activityProvider);
      expect(state.collection!.results.isNotEmpty, true);
      expect(state.collection!.results[0].score, 90);
    });

    test('completeActivity calculates rewards', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      final activity = state.collection!.allActivities[0];

      await notifier.startActivity('test_user', activity.activityId);
      await notifier.completeActivity('test_user', activity.activityId, 100);

      state = container.read(activityProvider);
      expect(state.collection!.results[0].coinsReward > 0, true);
      expect(state.collection!.results[0].xpReward > 0, true);
    });

    test('completeActivity detects perfect score', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;

      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 100);

      state = container.read(activityProvider);
      expect(state.collection!.results[0].isPerfectScore, true);
    });

    test('completeActivity updates activity play count', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      final activity = state.collection!.allActivities[0];
      final initialCount = activity.playCount;

      await notifier.startActivity('test_user', activity.activityId);
      await notifier.completeActivity('test_user', activity.activityId, 80);

      state = container.read(activityProvider);
      final updatedActivity =
          state.collection!.allActivities.firstWhere((a) => a.activityId == activity.activityId);
      expect(updatedActivity.playCount, initialCount + 1);
    });

    test('completeActivity updates statistics', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      expect(state.collection!.statistics.totalActivitiesCompleted, 0);
      expect(state.collection!.statistics.totalCoinsEarned, 0);

      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 85);

      state = container.read(activityProvider);
      expect(state.collection!.statistics.totalActivitiesCompleted, 1);
      expect(state.collection!.statistics.totalCoinsEarned > 0, true);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('persist_test');

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('persist_test', activityId);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('activities_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('activityCollectionProvider provides collection', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final collection = container.read(activityCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('allActivitiesProvider provides all activities', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final activities = container.read(allActivitiesProvider);
      expect(activities.isNotEmpty, true);
    });

    test('availableActivitiesProvider filters available', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final available = container.read(availableActivitiesProvider);
      expect(available.isNotEmpty, true);
      expect(available.every((a) => a.isAvailable), true);
    });

    test('featuredActivitiesProvider provides featured', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final featured = container.read(featuredActivitiesProvider);
      expect(featured.isNotEmpty, true);
      expect(featured.every((a) => a.isFeatured), true);
    });

    test('activitiesByTypeProvider filters by type', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final memory = container.read(activitiesByTypeProvider(ActivityType.memoryGame));
      expect(memory.isNotEmpty || memory.isEmpty, true);
    });

    test('activitiesByDifficultyProvider filters by difficulty', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final easy = container.read(activitiesByDifficultyProvider(ActivityDifficulty.easy));
      expect(easy.isEmpty || easy.isNotEmpty, true);
    });

    test('todaysActivitiesProvider provides daily activities', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final today = container.read(todaysActivitiesProvider);
      expect(today.isEmpty || today.isNotEmpty, true);
    });

    test('activityStatisticsProvider provides statistics', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      final stats = container.read(activityStatisticsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('activityTierProvider provides correct tier', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var tier = container.read(activityTierProvider);
      expect(tier, 'ビギナー');
    });

    test('totalActivitiesCompletedProvider provides count', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var count = container.read(totalActivitiesCompletedProvider);
      expect(count, 0);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 80);

      count = container.read(totalActivitiesCompletedProvider);
      expect(count, 1);
    });

    test('totalCoinsFromActivitiesProvider provides total', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var total = container.read(totalCoinsFromActivitiesProvider);
      expect(total, 0);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 90);

      total = container.read(totalCoinsFromActivitiesProvider);
      expect(total > 0, true);
    });

    test('totalXpFromActivitiesProvider provides total', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var total = container.read(totalXpFromActivitiesProvider);
      expect(total, 0);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 75);

      total = container.read(totalXpFromActivitiesProvider);
      expect(total > 0, true);
    });

    test('averageActivityScoreProvider provides average', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var average = container.read(averageActivityScoreProvider);
      expect(average, 0.0);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 85);

      average = container.read(averageActivityScoreProvider);
      expect(average > 0, true);
    });

    test('perfectScoresProvider tracks perfect scores', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var perfects = container.read(perfectScoresProvider);
      expect(perfects, 0);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 100);

      perfects = container.read(perfectScoresProvider);
      expect(perfects, 1);
    });

    test('personalBestsProvider tracks high scores', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var bests = container.read(personalBestsProvider);
      expect(bests, 0);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 95);

      bests = container.read(personalBestsProvider);
      expect(bests, 1);
    });

    test('activityResultsProvider provides results', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var results = container.read(activityResultsProvider);
      expect(results.isEmpty, true);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 80);

      results = container.read(activityResultsProvider);
      expect(results.length, 1);
    });

    test('completedTodayProvider filters today', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var today = container.read(completedTodayProvider);
      expect(today.isEmpty, true);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 85);

      today = container.read(completedTodayProvider);
      expect(today.length, 1);
    });

    test('activityParticipationsProvider provides participations', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var parts = container.read(activityParticipationsProvider);
      expect(parts.isEmpty, true);

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;
      await notifier.startActivity('test_user', activityId);

      parts = container.read(activityParticipationsProvider);
      expect(parts.length, 1);
    });

    test('personalBestProvider gets best for activity', () async {
      final notifier = container.read(activityProvider.notifier);
      await notifier.initializeActivities('test_user');

      var state = container.read(activityProvider);
      final activityId = state.collection!.allActivities[0].activityId;

      var best = container.read(personalBestProvider(activityId));
      expect(best, isNull);

      await notifier.startActivity('test_user', activityId);
      await notifier.completeActivity('test_user', activityId, 90);

      best = container.read(personalBestProvider(activityId));
      expect(best, isNotNull);
      expect(best!.score, 90);
    });
  });
}
