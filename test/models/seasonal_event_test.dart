import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/seasonal_event.dart';

void main() {
  group('EventType Enum', () {
    test('has all expected types', () {
      expect(EventType.values.length, 6);
      expect(EventType.values, contains(EventType.competition));
      expect(EventType.values, contains(EventType.special));
    });
  });

  group('EventStatus Enum', () {
    test('has all expected statuses', () {
      expect(EventStatus.values.length, 4);
      expect(EventStatus.values, contains(EventStatus.active));
      expect(EventStatus.values, contains(EventStatus.archived));
    });
  });

  group('EventRank Enum', () {
    test('has all expected ranks', () {
      expect(EventRank.values.length, 7);
      expect(EventRank.values, contains(EventRank.gold));
      expect(EventRank.values, contains(EventRank.participant));
    });
  });

  group('EventRewardTier', () {
    test('creates tier with required fields', () {
      final tier = EventRewardTier(
        minRank: 1,
        maxRank: 1,
        xpReward: 500,
        coinReward: 1000,
      );

      expect(tier.minRank, 1);
      expect(tier.maxRank, 1);
      expect(tier.xpReward, 500);
    });

    test('qualifiesForTier returns true for matching rank', () {
      final tier = EventRewardTier(
        minRank: 1,
        maxRank: 10,
        xpReward: 100,
        coinReward: 200,
      );

      expect(tier.qualifiesForTier(5), true);
      expect(tier.qualifiesForTier(1), true);
      expect(tier.qualifiesForTier(10), true);
    });

    test('qualifiesForTier returns false for non-matching rank', () {
      final tier = EventRewardTier(
        minRank: 1,
        maxRank: 10,
        xpReward: 100,
        coinReward: 200,
      );

      expect(tier.qualifiesForTier(11), false);
      expect(tier.qualifiesForTier(0), false);
    });

    test('toJson serializes tier', () {
      final tier = EventRewardTier(
        minRank: 1,
        maxRank: 3,
        xpReward: 250,
        coinReward: 500,
        premiumReward: 10,
        badgeRewardId: 'badge1',
      );

      final json = tier.toJson();
      expect(json['minRank'], 1);
      expect(json['xpReward'], 250);
      expect(json['badgeRewardId'], 'badge1');
    });

    test('fromJson deserializes tier', () {
      final json = {
        'minRank': 1,
        'maxRank': 1,
        'xpReward': 500,
        'coinReward': 1000,
      };

      final tier = EventRewardTier.fromJson(json);
      expect(tier.minRank, 1);
      expect(tier.xpReward, 500);
    });
  });

  group('SeasonalEvent', () {
    test('creates event with required fields', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'テスト大会',
        description: 'Test event',
        type: EventType.competition,
        status: EventStatus.active,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 6)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.eventId, 'evt1');
      expect(event.title, 'テスト大会');
      expect(event.type, EventType.competition);
    });

    test('isActive returns true for active event', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Active Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.active,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.isActive, true);
    });

    test('isActive returns false for ended event', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Ended Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.ended,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(days: 8)),
        endDate: now.subtract(const Duration(days: 1)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.isActive, false);
    });

    test('isRegistrationOpen checks deadline', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.upcoming,
        maxParticipants: 100,
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 8)),
        registrationDeadline: now.add(const Duration(days: 3)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.isRegistrationOpen, true);
    });

    test('isFull returns true when participant count reached', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Full Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.active,
        maxParticipants: 5,
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        rewardTiers: [],
        currentParticipantCount: 5,
        createdAt: now,
      );

      expect(event.isFull, true);
    });

    test('daysRemaining calculates correctly', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.active,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 5)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.daysRemaining, greaterThanOrEqualTo(4));
    });

    test('getProgressPercentage returns 0 before start', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Upcoming Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.upcoming,
        maxParticipants: 100,
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 8)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.getProgressPercentage(), 0);
    });

    test('getProgressPercentage returns 100 after end', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Ended Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.ended,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(days: 8)),
        endDate: now.subtract(const Duration(days: 1)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.getProgressPercentage(), 100);
    });

    test('getTimeRemaining returns イベント終了 for ended event', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Event',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.ended,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.subtract(const Duration(days: 1)),
        rewardTiers: [],
        createdAt: now,
      );

      expect(event.getTimeRemaining(), 'イベント終了');
    });

    test('toJson serializes event', () {
      final now = DateTime.now();
      final event = SeasonalEvent(
        eventId: 'evt1',
        title: 'Event',
        description: 'Description',
        type: EventType.competition,
        status: EventStatus.active,
        maxParticipants: 100,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        rewardTiers: [],
        createdAt: now,
      );

      final json = event.toJson();
      expect(json['eventId'], 'evt1');
      expect(json['title'], 'Event');
      expect(json['type'], 'competition');
    });

    test('fromJson deserializes event', () {
      final now = DateTime.now();
      final json = {
        'eventId': 'evt1',
        'title': 'Event',
        'description': 'Description',
        'type': 'competition',
        'status': 'active',
        'maxParticipants': 100,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 7)).toIso8601String(),
        'rewardTiers': [],
      };

      final event = SeasonalEvent.fromJson(json);
      expect(event.eventId, 'evt1');
      expect(event.type, EventType.competition);
    });
  });

  group('EventParticipation', () {
    test('creates participation with required fields', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
      );

      expect(participation.eventId, 'evt1');
      expect(participation.userId, 'user1');
      expect(participation.isCompleted, false);
    });

    test('isRanked returns true for top 100', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 50,
      );

      expect(participation.isRanked, true);
    });

    test('isRanked returns false for unranked', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 0,
      );

      expect(participation.isRanked, false);
    });

    test('getEventRank returns gold for rank 1', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 1,
      );

      expect(participation.getEventRank(), EventRank.gold);
    });

    test('getEventRank returns silver for rank 2', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 2,
      );

      expect(participation.getEventRank(), EventRank.silver);
    });

    test('getEventRank returns bronze for rank 3', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 3,
      );

      expect(participation.getEventRank(), EventRank.bronze);
    });

    test('getEventRank returns top10 for rank 10', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 10,
      );

      expect(participation.getEventRank(), EventRank.top10);
    });

    test('getEventRank returns top50 for rank 25', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 25,
      );

      expect(participation.getEventRank(), EventRank.top50);
    });

    test('getEventRank returns participant for unranked', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 0,
      );

      expect(participation.getEventRank(), EventRank.participant);
    });

    test('toJson serializes participation', () {
      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentScore: 100,
        currentRank: 5,
        isCompleted: true,
      );

      final json = participation.toJson();
      expect(json['eventId'], 'evt1');
      expect(json['currentScore'], 100);
      expect(json['isCompleted'], true);
    });

    test('fromJson deserializes participation', () {
      final now = DateTime.now();
      final json = {
        'eventId': 'evt1',
        'userId': 'user1',
        'joinedAt': now.toIso8601String(),
        'currentScore': 100,
        'currentRank': 5,
      };

      final participation = EventParticipation.fromJson(json);
      expect(participation.eventId, 'evt1');
      expect(participation.currentScore, 100);
    });
  });

  group('EventLeaderboardEntry', () {
    test('creates leaderboard entry', () {
      final entry = EventLeaderboardEntry(
        userId: 'user1',
        username: 'testuser',
        rank: 1,
        score: 1000,
        eventRank: EventRank.gold,
      );

      expect(entry.userId, 'user1');
      expect(entry.rank, 1);
      expect(entry.eventRank, EventRank.gold);
    });

    test('toJson serializes entry', () {
      final entry = EventLeaderboardEntry(
        userId: 'user1',
        username: 'testuser',
        rank: 1,
        score: 1000,
        eventRank: EventRank.gold,
        xpEarned: 500,
      );

      final json = entry.toJson();
      expect(json['userId'], 'user1');
      expect(json['rank'], 1);
      expect(json['eventRank'], 'gold');
    });

    test('fromJson deserializes entry', () {
      final json = {
        'userId': 'user1',
        'username': 'testuser',
        'rank': 1,
        'score': 1000,
        'eventRank': 'gold',
      };

      final entry = EventLeaderboardEntry.fromJson(json);
      expect(entry.userId, 'user1');
      expect(entry.eventRank, EventRank.gold);
    });
  });

  group('UserEventParticipations', () {
    test('creates participations collection', () {
      final now = DateTime.now();
      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [],
        upcomingEventIds: [],
        completedEventIds: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      expect(participations.userId, 'user1');
      expect(participations.participations.isEmpty, true);
    });

    test('getActiveParticipations filters uncompleted', () {
      final now = DateTime.now();
      final p1 = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        isCompleted: false,
      );
      final p2 = EventParticipation(
        eventId: 'evt2',
        userId: 'user1',
        joinedAt: now,
        isCompleted: true,
      );

      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [p1, p2],
        upcomingEventIds: ['evt1'],
        completedEventIds: ['evt2'],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final active = participations.getActiveParticipations();
      expect(active.length, 1);
      expect(active[0].eventId, 'evt1');
    });

    test('getCompletedParticipations filters completed', () {
      final now = DateTime.now();
      final p1 = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        isCompleted: false,
      );
      final p2 = EventParticipation(
        eventId: 'evt2',
        userId: 'user1',
        joinedAt: now,
        isCompleted: true,
      );

      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [p1, p2],
        upcomingEventIds: ['evt1'],
        completedEventIds: ['evt2'],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final completed = participations.getCompletedParticipations();
      expect(completed.length, 1);
      expect(completed[0].eventId, 'evt2');
    });

    test('getRankedParticipations filters top 100', () {
      final now = DateTime.now();
      final p1 = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentRank: 50,
      );
      final p2 = EventParticipation(
        eventId: 'evt2',
        userId: 'user1',
        joinedAt: now,
        currentRank: 0,
      );

      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [p1, p2],
        upcomingEventIds: [],
        completedEventIds: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final ranked = participations.getRankedParticipations();
      expect(ranked.length, 1);
      expect(ranked[0].currentRank, 50);
    });

    test('getTotalEventRewardsEarned sums scores', () {
      final now = DateTime.now();
      final p1 = EventParticipation(
        eventId: 'evt1',
        userId: 'user1',
        joinedAt: now,
        currentScore: 100,
      );
      final p2 = EventParticipation(
        eventId: 'evt2',
        userId: 'user1',
        joinedAt: now,
        currentScore: 50,
      );

      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [p1, p2],
        upcomingEventIds: [],
        completedEventIds: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      expect(participations.getTotalEventRewardsEarned(), 150);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [],
        upcomingEventIds: ['evt1'],
        completedEventIds: ['evt2'],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final json = participations.toJson();
      final restored = UserEventParticipations.fromJson(json);

      expect(restored.userId, 'user1');
      expect(restored.upcomingEventIds.length, 1);
    });
  });

  group('EventStatistics', () {
    test('creates statistics with required fields', () {
      final now = DateTime.now();
      final stats = EventStatistics(
        userId: 'user1',
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalEventsParticipated, 0);
    });

    test('getCompetitionLevel returns correct levels', () {
      final now = DateTime.now();

      final beginnerStats = EventStatistics(
        userId: 'user1',
        totalEventsParticipated: 2,
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );
      expect(beginnerStats.getCompetitionLevel(), '初心者');

      final experiencedStats = EventStatistics(
        userId: 'user2',
        totalEventsParticipated: 15,
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );
      expect(experiencedStats.getCompetitionLevel(), '経験者');

      const veteranStats = EventStatistics(
        userId: 'user3',
        totalEventsParticipated: 30,
        lastEventParticipationAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(veteranStats.getCompetitionLevel(), 'ベテラン');
    });

    test('getTotalMedals sums all medals', () {
      final now = DateTime.now();
      final stats = EventStatistics(
        userId: 'user1',
        goldMedals: 3,
        silverMedals: 2,
        bronzeMedals: 1,
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.getTotalMedals(), 6);
    });

    test('toJson serializes statistics', () {
      final now = DateTime.now();
      final stats = EventStatistics(
        userId: 'user1',
        totalEventsParticipated: 10,
        goldMedals: 2,
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      expect(json['userId'], 'user1');
      expect(json['totalEventsParticipated'], 10);
      expect(json['goldMedals'], 2);
    });

    test('fromJson deserializes statistics', () {
      final now = DateTime.now();
      final json = {
        'userId': 'user1',
        'totalEventsParticipated': 10,
        'goldMedals': 2,
        'lastEventParticipationAt': now.toIso8601String(),
        'lastUpdatedAt': now.toIso8601String(),
      };

      final stats = EventStatistics.fromJson(json);
      expect(stats.userId, 'user1');
      expect(stats.totalEventsParticipated, 10);
    });
  });

  group('EventCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final stats = EventStatistics(
        userId: 'user1',
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );
      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [],
        upcomingEventIds: [],
        completedEventIds: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final collection = EventCollection(
        userId: 'user1',
        allEvents: [],
        participations: participations,
        statistics: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.allEvents.isEmpty, true);
    });

    test('getActiveEvents filters by status', () {
      final now = DateTime.now();
      final activeEvent = SeasonalEvent(
        eventId: 'evt1',
        title: 'Active',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.active,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        rewardTiers: [],
        createdAt: now,
      );
      final upcomingEvent = SeasonalEvent(
        eventId: 'evt2',
        title: 'Upcoming',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.upcoming,
        maxParticipants: 100,
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 8)),
        rewardTiers: [],
        createdAt: now,
      );

      final stats = EventStatistics(
        userId: 'user1',
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );
      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [],
        upcomingEventIds: [],
        completedEventIds: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final collection = EventCollection(
        userId: 'user1',
        allEvents: [activeEvent, upcomingEvent],
        participations: participations,
        statistics: stats,
        generatedAt: now,
      );

      final active = collection.getActiveEvents();
      expect(active.length, 1);
      expect(active[0].eventId, 'evt1');
    });

    test('getEventsByType filters by type', () {
      final now = DateTime.now();
      final competitionEvent = SeasonalEvent(
        eventId: 'evt1',
        title: 'Competition',
        description: 'Test',
        type: EventType.competition,
        status: EventStatus.active,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        rewardTiers: [],
        createdAt: now,
      );
      final seasonalEvent = SeasonalEvent(
        eventId: 'evt2',
        title: 'Seasonal',
        description: 'Test',
        type: EventType.seasonal,
        status: EventStatus.active,
        maxParticipants: 100,
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        rewardTiers: [],
        createdAt: now,
      );

      final stats = EventStatistics(
        userId: 'user1',
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );
      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [],
        upcomingEventIds: [],
        completedEventIds: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final collection = EventCollection(
        userId: 'user1',
        allEvents: [competitionEvent, seasonalEvent],
        participations: participations,
        statistics: stats,
        generatedAt: now,
      );

      final competitions = collection.getEventsByType(EventType.competition);
      expect(competitions.length, 1);
      expect(competitions[0].type, EventType.competition);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = EventStatistics(
        userId: 'user1',
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );
      final participations = UserEventParticipations(
        userId: 'user1',
        participations: [],
        upcomingEventIds: [],
        completedEventIds: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final collection = EventCollection(
        userId: 'user1',
        allEvents: [],
        participations: participations,
        statistics: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = EventCollection.fromJson(json);

      expect(restored.userId, collection.userId);
    });
  });
}
