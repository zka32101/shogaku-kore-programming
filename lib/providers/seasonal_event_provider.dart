import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/seasonal_event.dart';

/// Seasonal event state
class SeasonalEventState {
  final EventCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  SeasonalEventState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  SeasonalEventState copyWith({
    EventCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      SeasonalEventState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

/// Seasonal event notifier
class SeasonalEventNotifier extends StateNotifier<SeasonalEventState> {
  SeasonalEventNotifier() : super(SeasonalEventState());

  /// Initialize events for user
  Future<void> initializeEvents(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'seasonal_events_$userId';

      // Check if already exists
      final stored = prefs.getString(key);
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        state = state.copyWith(
          collection: EventCollection.fromJson(json),
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
        return;
      }

      // Create default events
      final now = DateTime.now();
      final defaultEvents = _createDefaultEvents(now);

      final collection = EventCollection(
        userId: userId,
        allEvents: defaultEvents,
        participations: UserEventParticipations(
          userId: userId,
          participations: [],
          upcomingEventIds: [],
          completedEventIds: [],
          lastUpdatedAt: now,
          generatedAt: now,
        ),
        statistics: EventStatistics(
          userId: userId,
          lastEventParticipationAt: now,
          lastUpdatedAt: now,
        ),
        generatedAt: now,
      );

      await prefs.setString(key, jsonEncode(collection.toJson()));
      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize events: $e',
      );
    }
  }

  /// Join event
  Future<void> joinEvent(String userId, String eventId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final event = collection.allEvents.firstWhere(
        (e) => e.eventId == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      if (event.isFull) throw Exception('Event is full');
      if (!event.isRegistrationOpen) throw Exception('Registration closed');

      // Check if already joined
      final alreadyJoined = collection.participations.participations
          .any((p) => p.eventId == eventId && p.userId == userId);
      if (alreadyJoined) throw Exception('Already joined');

      final now = DateTime.now();
      final participation = EventParticipation(
        eventId: eventId,
        userId: userId,
        joinedAt: now,
        currentScore: 0,
        currentRank: 0,
        isCompleted: false,
        participationCount: 1,
      );

      final updatedParticipations = [...collection.participations.participations];
      updatedParticipations.add(participation);

      final updatedEvents = collection.allEvents.map((e) {
        if (e.eventId == eventId) {
          return SeasonalEvent(
            eventId: e.eventId,
            title: e.title,
            description: e.description,
            type: e.type,
            status: e.status,
            imageId: e.imageId,
            maxParticipants: e.maxParticipants,
            startDate: e.startDate,
            endDate: e.endDate,
            registrationDeadline: e.registrationDeadline,
            minimumLevel: e.minimumLevel,
            maxDailyParticipations: e.maxDailyParticipations,
            rules: e.rules,
            rewardTiers: e.rewardTiers,
            eventData: e.eventData,
            currentParticipantCount: e.currentParticipantCount + 1,
            createdAt: e.createdAt,
          );
        }
        return e;
      }).toList();

      final updatedUpcoming = [...collection.participations.upcomingEventIds];
      if (!updatedUpcoming.contains(eventId)) {
        updatedUpcoming.add(eventId);
      }

      final updatedParticipationObj = UserEventParticipations(
        userId: userId,
        participations: updatedParticipations.take(100).toList(),
        upcomingEventIds: updatedUpcoming,
        completedEventIds: collection.participations.completedEventIds,
        lastUpdatedAt: now,
        generatedAt: collection.participations.generatedAt,
      );

      final updatedStats = EventStatistics(
        userId: userId,
        totalEventsParticipated: collection.statistics.totalEventsParticipated + 1,
        totalEventsCompleted: collection.statistics.totalEventsCompleted,
        totalEventRewardsEarned: collection.statistics.totalEventRewardsEarned,
        totalEventRankings: collection.statistics.totalEventRankings,
        goldMedals: collection.statistics.goldMedals,
        silverMedals: collection.statistics.silverMedals,
        bronzeMedals: collection.statistics.bronzeMedals,
        topTenFinishes: collection.statistics.topTenFinishes,
        averageEventScore: collection.statistics.averageEventScore,
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );

      final updatedCollection = EventCollection(
        userId: userId,
        allEvents: updatedEvents.take(50).toList(),
        participations: updatedParticipationObj,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to join event: $e');
    }
  }

  /// Update event score
  Future<void> updateEventScore(
    String userId,
    String eventId,
    int scoreAmount,
  ) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedParticipations = collection.participations.participations.map((p) {
        if (p.eventId == eventId && p.userId == userId) {
          return EventParticipation(
            eventId: p.eventId,
            userId: p.userId,
            joinedAt: p.joinedAt,
            currentScore: p.currentScore + scoreAmount,
            currentRank: p.currentRank,
            isCompleted: p.isCompleted,
            completedAt: p.completedAt,
            participationCount: p.participationCount,
            hasClaimedReward: p.hasClaimedReward,
            progressData: p.progressData,
          );
        }
        return p;
      }).toList();

      final updatedParticipationObj = UserEventParticipations(
        userId: userId,
        participations: updatedParticipations,
        upcomingEventIds: collection.participations.upcomingEventIds,
        completedEventIds: collection.participations.completedEventIds,
        lastUpdatedAt: now,
        generatedAt: collection.participations.generatedAt,
      );

      final updatedCollection = EventCollection(
        userId: userId,
        allEvents: collection.allEvents,
        participations: updatedParticipationObj,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update score: $e');
    }
  }

  /// Complete event
  Future<void> completeEvent(String userId, String eventId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedParticipations = collection.participations.participations.map((p) {
        if (p.eventId == eventId && p.userId == userId) {
          return EventParticipation(
            eventId: p.eventId,
            userId: p.userId,
            joinedAt: p.joinedAt,
            currentScore: p.currentScore,
            currentRank: p.currentRank,
            isCompleted: true,
            completedAt: now,
            participationCount: p.participationCount,
            hasClaimedReward: p.hasClaimedReward,
            progressData: p.progressData,
          );
        }
        return p;
      }).toList();

      final updatedCompleted = [...collection.participations.completedEventIds];
      if (!updatedCompleted.contains(eventId)) {
        updatedCompleted.add(eventId);
      }

      final updatedUpcoming = collection.participations.upcomingEventIds
          .where((id) => id != eventId)
          .toList();

      final updatedParticipationObj = UserEventParticipations(
        userId: userId,
        participations: updatedParticipations,
        upcomingEventIds: updatedUpcoming,
        completedEventIds: updatedCompleted,
        lastUpdatedAt: now,
        generatedAt: collection.participations.generatedAt,
      );

      final updatedStats = EventStatistics(
        userId: userId,
        totalEventsParticipated: collection.statistics.totalEventsParticipated,
        totalEventsCompleted: collection.statistics.totalEventsCompleted + 1,
        totalEventRewardsEarned: collection.statistics.totalEventRewardsEarned,
        totalEventRankings: collection.statistics.totalEventRankings,
        goldMedals: collection.statistics.goldMedals,
        silverMedals: collection.statistics.silverMedals,
        bronzeMedals: collection.statistics.bronzeMedals,
        topTenFinishes: collection.statistics.topTenFinishes,
        averageEventScore: collection.statistics.averageEventScore,
        lastEventParticipationAt: now,
        lastUpdatedAt: now,
      );

      final updatedCollection = EventCollection(
        userId: userId,
        allEvents: collection.allEvents,
        participations: updatedParticipationObj,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to complete event: $e');
    }
  }

  /// Leave event
  Future<void> leaveEvent(String userId, String eventId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedParticipations = collection.participations.participations
          .where((p) => !(p.eventId == eventId && p.userId == userId))
          .toList();

      final updatedUpcoming = collection.participations.upcomingEventIds
          .where((id) => id != eventId)
          .toList();

      final updatedParticipationObj = UserEventParticipations(
        userId: userId,
        participations: updatedParticipations,
        upcomingEventIds: updatedUpcoming,
        completedEventIds: collection.participations.completedEventIds,
        lastUpdatedAt: now,
        generatedAt: collection.participations.generatedAt,
      );

      final updatedEvents = collection.allEvents.map((e) {
        if (e.eventId == eventId && e.currentParticipantCount > 0) {
          return SeasonalEvent(
            eventId: e.eventId,
            title: e.title,
            description: e.description,
            type: e.type,
            status: e.status,
            imageId: e.imageId,
            maxParticipants: e.maxParticipants,
            startDate: e.startDate,
            endDate: e.endDate,
            registrationDeadline: e.registrationDeadline,
            minimumLevel: e.minimumLevel,
            maxDailyParticipations: e.maxDailyParticipations,
            rules: e.rules,
            rewardTiers: e.rewardTiers,
            eventData: e.eventData,
            currentParticipantCount: e.currentParticipantCount - 1,
            createdAt: e.createdAt,
          );
        }
        return e;
      }).toList();

      final updatedCollection = EventCollection(
        userId: userId,
        allEvents: updatedEvents,
        participations: updatedParticipationObj,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to leave event: $e');
    }
  }

  /// Claim event reward
  Future<void> claimEventReward(String userId, String eventId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final event = collection.allEvents.firstWhere(
        (e) => e.eventId == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final participation = collection.participations.participations.firstWhere(
        (p) => p.eventId == eventId && p.userId == userId,
        orElse: () => throw Exception('Participation not found'),
      );

      if (participation.hasClaimedReward) {
        throw Exception('Reward already claimed');
      }

      if (!participation.isCompleted) {
        throw Exception('Event not completed');
      }

      final now = DateTime.now();
      final tier = event.rewardTiers.firstWhere(
        (t) => t.qualifiesForTier(participation.currentRank),
        orElse: () => event.rewardTiers.last,
      );

      final updatedParticipations =
          collection.participations.participations.map((p) {
        if (p.eventId == eventId && p.userId == userId) {
          return EventParticipation(
            eventId: p.eventId,
            userId: p.userId,
            joinedAt: p.joinedAt,
            currentScore: p.currentScore,
            currentRank: p.currentRank,
            isCompleted: p.isCompleted,
            completedAt: p.completedAt,
            participationCount: p.participationCount,
            hasClaimedReward: true,
            progressData: p.progressData,
          );
        }
        return p;
      }).toList();

      final updatedParticipationObj = UserEventParticipations(
        userId: userId,
        participations: updatedParticipations,
        upcomingEventIds: collection.participations.upcomingEventIds,
        completedEventIds: collection.participations.completedEventIds,
        lastUpdatedAt: now,
        generatedAt: collection.participations.generatedAt,
      );

      var updatedStats = collection.statistics;
      if (participation.getEventRank() == EventRank.gold) {
        updatedStats = EventStatistics(
          userId: userId,
          totalEventsParticipated: updatedStats.totalEventsParticipated,
          totalEventsCompleted: updatedStats.totalEventsCompleted,
          totalEventRewardsEarned:
              updatedStats.totalEventRewardsEarned + tier.xpReward,
          totalEventRankings: updatedStats.totalEventRankings,
          goldMedals: updatedStats.goldMedals + 1,
          silverMedals: updatedStats.silverMedals,
          bronzeMedals: updatedStats.bronzeMedals,
          topTenFinishes: updatedStats.topTenFinishes,
          averageEventScore: updatedStats.averageEventScore,
          lastEventParticipationAt: now,
          lastUpdatedAt: now,
        );
      } else if (participation.getEventRank() == EventRank.silver) {
        updatedStats = EventStatistics(
          userId: userId,
          totalEventsParticipated: updatedStats.totalEventsParticipated,
          totalEventsCompleted: updatedStats.totalEventsCompleted,
          totalEventRewardsEarned:
              updatedStats.totalEventRewardsEarned + tier.xpReward,
          totalEventRankings: updatedStats.totalEventRankings,
          goldMedals: updatedStats.goldMedals,
          silverMedals: updatedStats.silverMedals + 1,
          bronzeMedals: updatedStats.bronzeMedals,
          topTenFinishes: updatedStats.topTenFinishes,
          averageEventScore: updatedStats.averageEventScore,
          lastEventParticipationAt: now,
          lastUpdatedAt: now,
        );
      } else if (participation.getEventRank() == EventRank.bronze) {
        updatedStats = EventStatistics(
          userId: userId,
          totalEventsParticipated: updatedStats.totalEventsParticipated,
          totalEventsCompleted: updatedStats.totalEventsCompleted,
          totalEventRewardsEarned:
              updatedStats.totalEventRewardsEarned + tier.xpReward,
          totalEventRankings: updatedStats.totalEventRankings,
          goldMedals: updatedStats.goldMedals,
          silverMedals: updatedStats.silverMedals,
          bronzeMedals: updatedStats.bronzeMedals + 1,
          topTenFinishes: updatedStats.topTenFinishes,
          averageEventScore: updatedStats.averageEventScore,
          lastEventParticipationAt: now,
          lastUpdatedAt: now,
        );
      }

      final updatedCollection = EventCollection(
        userId: userId,
        allEvents: collection.allEvents,
        participations: updatedParticipationObj,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to claim reward: $e');
    }
  }

  /// Persist to SharedPreferences
  Future<void> _persist(String userId, EventCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'seasonal_events_$userId',
      jsonEncode(collection.toJson()),
    );
  }

  /// Create default events
  List<SeasonalEvent> _createDefaultEvents(DateTime now) {
    final events = <SeasonalEvent>[];

    // Competition event
    final competitionEvent = SeasonalEvent(
      eventId: 'comp_${now.millisecondsSinceEpoch}',
      title: '日本語スピード大会',
      description: '最速で日本語の問題に答えるコンペティション',
      type: EventType.competition,
      status: EventStatus.active,
      maxParticipants: 1000,
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now.add(const Duration(days: 23)),
      registrationDeadline: now.add(const Duration(days: 20)),
      minimumLevel: 1,
      maxDailyParticipations: 5,
      rewardTiers: [
        EventRewardTier(
          minRank: 1,
          maxRank: 1,
          xpReward: 500,
          coinReward: 1000,
          premiumReward: 50,
          badgeRewardId: 'badge_gold',
        ),
        EventRewardTier(
          minRank: 2,
          maxRank: 2,
          xpReward: 300,
          coinReward: 600,
          premiumReward: 30,
          badgeRewardId: 'badge_silver',
        ),
        EventRewardTier(
          minRank: 3,
          maxRank: 3,
          xpReward: 200,
          coinReward: 400,
          premiumReward: 20,
          badgeRewardId: 'badge_bronze',
        ),
        EventRewardTier(
          minRank: 4,
          maxRank: 10,
          xpReward: 100,
          coinReward: 200,
        ),
        EventRewardTier(
          minRank: 11,
          maxRank: 50,
          xpReward: 50,
          coinReward: 100,
        ),
        EventRewardTier(
          minRank: 51,
          maxRank: 100,
          xpReward: 25,
          coinReward: 50,
        ),
      ],
      createdAt: now,
    );
    events.add(competitionEvent);

    // Seasonal event
    final seasonalEvent = SeasonalEvent(
      eventId: 'seasonal_${now.millisecondsSinceEpoch}',
      title: '秋のお祭りチャレンジ',
      description: '季節のお祭りテーマでチャレンジに参加しよう',
      type: EventType.seasonal,
      status: EventStatus.upcoming,
      maxParticipants: 500,
      startDate: now.add(const Duration(days: 7)),
      endDate: now.add(const Duration(days: 14)),
      minimumLevel: 5,
      rewardTiers: [
        EventRewardTier(
          minRank: 1,
          maxRank: 100,
          xpReward: 150,
          coinReward: 300,
        ),
      ],
      createdAt: now,
    );
    events.add(seasonalEvent);

    // Time challenge event
    final timeChallengeEvent = SeasonalEvent(
      eventId: 'time_${now.millisecondsSinceEpoch}',
      title: '48時間チャレンジ',
      description: '48時間以内にできるだけ多くの問題を解く',
      type: EventType.timeChallenge,
      status: EventStatus.active,
      maxParticipants: 250,
      startDate: now.subtract(const Duration(hours: 12)),
      endDate: now.add(const Duration(hours: 36)),
      minimumLevel: 1,
      maxDailyParticipations: 10,
      rewardTiers: [
        EventRewardTier(
          minRank: 1,
          maxRank: 100,
          xpReward: 75,
          coinReward: 150,
        ),
      ],
      createdAt: now,
    );
    events.add(timeChallengeEvent);

    return events;
  }
}

// Riverpod providers
final seasonalEventProvider =
    StateNotifierProvider<SeasonalEventNotifier, SeasonalEventState>((ref) {
  return SeasonalEventNotifier();
});

final eventCollectionProvider = Provider<EventCollection?>((ref) {
  final state = ref.watch(seasonalEventProvider);
  return state.collection;
});

final allEventsProvider = Provider<List<SeasonalEvent>>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.allEvents ?? [];
});

final activeEventsProvider = Provider<List<SeasonalEvent>>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.getActiveEvents() ?? [];
});

final upcomingEventsProvider = Provider<List<SeasonalEvent>>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.getUpcomingEvents() ?? [];
});

final eventsByTypeProvider =
    Provider.family<List<SeasonalEvent>, EventType>((ref, type) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.getEventsByType(type) ?? [];
});

final userParticipationsProvider = Provider<List<EventParticipation>>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.participations.participations ?? [];
});

final activeParticipationsProvider =
    Provider<List<EventParticipation>>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.participations.getActiveParticipations() ?? [];
});

final completedParticipationsProvider =
    Provider<List<EventParticipation>>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.participations.getCompletedParticipations() ?? [];
});

final eventStatisticsProvider = Provider<EventStatistics?>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.statistics;
});

final competitionLevelProvider = Provider<String>((ref) {
  final stats = ref.watch(eventStatisticsProvider);
  return stats?.getCompetitionLevel() ?? '初心者';
});

final totalMedalsProvider = Provider<int>((ref) {
  final stats = ref.watch(eventStatisticsProvider);
  return stats?.getTotalMedals() ?? 0;
});

final rankedParticipationsProvider = Provider<List<EventParticipation>>((ref) {
  final collection = ref.watch(eventCollectionProvider);
  return collection?.participations.getRankedParticipations() ?? [];
});
