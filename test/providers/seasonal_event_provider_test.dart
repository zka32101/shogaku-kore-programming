import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/seasonal_event.dart';
import 'package:shogaku_kore_programming/providers/seasonal_event_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SeasonalEventNotifier', () {
    test('initializes with empty state', () {
      final notifier = SeasonalEventNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeEvents creates default events', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final state = container.read(seasonalEventProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
      expect(state.collection!.allEvents.isNotEmpty, true);
    });

    test('initializeEvents creates correct default event count', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final state = container.read(seasonalEventProvider);
      expect(state.collection!.allEvents.length, 3);
    });

    test('initializeEvents creates competition event', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final state = container.read(seasonalEventProvider);
      final competitionEvent = state.collection!.allEvents
          .firstWhere((e) => e.type == EventType.competition);
      expect(competitionEvent.title, '日本語スピード大会');
    });

    test('initializeEvents loads existing events', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final firstEventId = state.collection!.allEvents[0].eventId;

      // Create new notifier and reinitialize
      final _notifier2 = SeasonalEventNotifier();
      final container2 = ProviderContainer();
      container2.read(seasonalEventProvider.notifier).initializeEvents('test_user');

      final newState = container2.read(seasonalEventProvider);
      expect(newState.collection!.allEvents[0].eventId, firstEventId);
    });

    test('joinEvent adds participation', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.participations.participations.isNotEmpty, true);
      expect(state.collection!.participations.participations[0].eventId, eventId);
    });

    test('joinEvent increments participant count', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;
      final initialCount = state.collection!.allEvents[0].currentParticipantCount;

      await notifier.joinEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      final updatedEvent = state.collection!.allEvents[0];
      expect(updatedEvent.currentParticipantCount, initialCount + 1);
    });

    test('joinEvent increments total events participated', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      expect(state.collection!.statistics.totalEventsParticipated, 0);

      final _eventId = state.collection!.allEvents[0].eventId;
      await notifier.joinEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.statistics.totalEventsParticipated, 1);
    });

    test('joinEvent prevents duplicates', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      state = container.read(seasonalEventProvider);
      final firstParticipationCount = state.collection!.participations.participations.length;

      await notifier.joinEvent('test_user', eventId);
      state = container.read(seasonalEventProvider);
      expect(state.collection!.participations.participations.length, firstParticipationCount);
    });

    test('updateEventScore increases score', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      await notifier.updateEventScore('test_user', eventId, 100);

      state = container.read(seasonalEventProvider);
      final participation = state.collection!.participations.participations[0];
      expect(participation.currentScore, 100);
    });

    test('updateEventScore accumulates score', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      await notifier.updateEventScore('test_user', eventId, 100);
      await notifier.updateEventScore('test_user', eventId, 50);

      state = container.read(seasonalEventProvider);
      final participation = state.collection!.participations.participations[0];
      expect(participation.currentScore, 150);
    });

    test('completeEvent marks as completed', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      expect(
        container.read(seasonalEventProvider).participations.participations[0].isCompleted,
        false,
      );

      await notifier.completeEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.participations.participations[0].isCompleted, true);
      expect(state.collection!.participations.participations[0].completedAt, isNotNull);
    });

    test('completeEvent increments completed count', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      expect(state.collection!.statistics.totalEventsCompleted, 0);

      final _eventId = state.collection!.allEvents[0].eventId;
      await notifier.joinEvent('test_user', eventId);
      await notifier.completeEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.statistics.totalEventsCompleted, 1);
    });

    test('completeEvent adds to completed IDs', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      await notifier.completeEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.participations.completedEventIds.contains(eventId), true);
    });

    test('leaveEvent removes participation', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      expect(state.collection!.participations.participations.isNotEmpty, true);

      await notifier.leaveEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.participations.participations.isEmpty, true);
    });

    test('leaveEvent decrements participant count', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;
      final initialCount = state.collection!.allEvents[0].currentParticipantCount;

      await notifier.joinEvent('test_user', eventId);
      await notifier.leaveEvent('test_user', eventId);

      state = container.read(seasonalEventProvider);
      final updatedEvent = state.collection!.allEvents[0];
      expect(updatedEvent.currentParticipantCount, initialCount);
    });

    test('claimEventReward marks reward claimed', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      await notifier.completeEvent('test_user', eventId);
      await notifier.claimEventReward('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.participations.participations[0].hasClaimedReward, true);
    });

    test('claimEventReward requires completed event', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      await notifier.claimEventReward('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.error, isNotNull);
    });

    test('claimEventReward prevents duplicate claims', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      await notifier.completeEvent('test_user', eventId);
      await notifier.claimEventReward('test_user', eventId);
      await notifier.claimEventReward('test_user', eventId);

      state = container.read(seasonalEventProvider);
      expect(state.collection!.error, isNotNull);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('persist_test');

      await notifier.updateEventScore('persist_test', 'evt1', 100);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('seasonal_events_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('eventCollectionProvider provides collection', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final collection = container.read(eventCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('allEventsProvider provides all events', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final events = container.read(allEventsProvider);
      expect(events.isNotEmpty, true);
    });

    test('activeEventsProvider filters active events', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final activeEvents = container.read(activeEventsProvider);
      expect(activeEvents.isNotEmpty, true);
      expect(activeEvents.every((e) => e.isActive), true);
    });

    test('upcomingEventsProvider filters upcoming events', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final upcomingEvents = container.read(upcomingEventsProvider);
      expect(upcomingEvents.isNotEmpty, true);
    });

    test('eventsByTypeProvider filters by type', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final competitions = container.read(eventsByTypeProvider(EventType.competition));
      expect(competitions.isNotEmpty, true);
      expect(competitions.every((e) => e.type == EventType.competition), true);
    });

    test('userParticipationsProvider provides participations', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var participations = container.read(userParticipationsProvider);
      expect(participations.isEmpty, true);

      final state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;
      await notifier.joinEvent('test_user', eventId);

      participations = container.read(userParticipationsProvider);
      expect(participations.length, 1);
    });

    test('activeParticipationsProvider filters active participations', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      var activeParticipations = container.read(activeParticipationsProvider);
      expect(activeParticipations.length, 1);

      await notifier.completeEvent('test_user', eventId);
      activeParticipations = container.read(activeParticipationsProvider);
      expect(activeParticipations.isEmpty, true);
    });

    test('completedParticipationsProvider filters completed', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      await notifier.joinEvent('test_user', eventId);
      var completed = container.read(completedParticipationsProvider);
      expect(completed.isEmpty, true);

      await notifier.completeEvent('test_user', eventId);
      completed = container.read(completedParticipationsProvider);
      expect(completed.length, 1);
    });

    test('eventStatisticsProvider provides statistics', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      final stats = container.read(eventStatisticsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('competitionLevelProvider provides correct level', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var level = container.read(competitionLevelProvider);
      expect(level, '初心者');

      // Update stats to increase level
      var state = container.read(seasonalEventProvider);
      final _eventId = state.collection!.allEvents[0].eventId;

      for (int i = 0; i < 5; i++) {
        await notifier.joinEvent('test_user', 'evt$i');
      }

      level = container.read(competitionLevelProvider);
      expect(level, isNotEmpty);
    });

    test('totalMedalsProvider counts medals', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var medals = container.read(totalMedalsProvider);
      expect(medals, 0);
    });

    test('rankedParticipationsProvider filters top 100', () async {
      final notifier = container.read(seasonalEventProvider.notifier);
      await notifier.initializeEvents('test_user');

      var ranked = container.read(rankedParticipationsProvider);
      expect(ranked.isEmpty, true);
    });
  });
}
