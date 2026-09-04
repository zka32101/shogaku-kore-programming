/// Event type
enum EventType {
  competition,   // Competitive tournament
  collaborative, // Cooperative/group event
  timeChallenge, // Time-based challenge
  quest,         // Quest series
  seasonal,      // Seasonal celebration
  special,       // Special/limited event
}

/// Event status
enum EventStatus {
  upcoming,      // Not started yet
  active,        // Currently running
  ended,         // Finished
  archived,      // Old/historical
}

/// Participant rank in event
enum EventRank {
  gold,          // 1st place
  silver,        // 2nd place
  bronze,        // 3rd place
  top10,         // 4-10
  top50,         // 11-50
  top100,        // 51-100
  participant,   // Participated but not ranked
}

/// Event reward tier
class EventRewardTier {
  final int minRank;              // Minimum rank to earn this tier
  final int maxRank;              // Maximum rank for this tier
  final int xpReward;
  final int coinReward;
  final int? premiumReward;
  final String? badgeRewardId;    // Badge earned at this tier
  final Map<String, dynamic>? bonusRewards; // Additional rewards

  EventRewardTier({
    required this.minRank,
    required this.maxRank,
    required this.xpReward,
    required this.coinReward,
    this.premiumReward,
    this.badgeRewardId,
    this.bonusRewards,
  });

  /// Check if rank qualifies for this tier
  bool qualifiesForTier(int rank) => rank >= minRank && rank <= maxRank;

  Map<String, dynamic> toJson() => {
        'minRank': minRank,
        'maxRank': maxRank,
        'xpReward': xpReward,
        'coinReward': coinReward,
        'premiumReward': premiumReward,
        'badgeRewardId': badgeRewardId,
        'bonusRewards': bonusRewards,
      };

  factory EventRewardTier.fromJson(Map<String, dynamic> json) => EventRewardTier(
        minRank: json['minRank'] as int,
        maxRank: json['maxRank'] as int,
        xpReward: json['xpReward'] as int,
        coinReward: json['coinReward'] as int,
        premiumReward: json['premiumReward'] as int?,
        badgeRewardId: json['badgeRewardId'] as String?,
        bonusRewards: json['bonusRewards'] as Map<String, dynamic>?,
      );
}

/// Seasonal event/tournament
class SeasonalEvent {
  final String eventId;
  final String title;             // Event title (Japanese)
  final String description;
  final EventType type;
  final EventStatus status;
  final String? imageId;          // Event banner
  final int maxParticipants;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;
  final int minimumLevel;         // Minimum level to participate
  final int? maxDailyParticipations; // Per user per day
  final String? rules;            // Event rules
  final List<EventRewardTier> rewardTiers;
  final Map<String, dynamic>? eventData; // Custom event data
  final int currentParticipantCount;
  final DateTime createdAt;

  SeasonalEvent({
    required this.eventId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.imageId,
    required this.maxParticipants,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    this.minimumLevel = 1,
    this.maxDailyParticipations,
    this.rules,
    required this.rewardTiers,
    this.eventData,
    this.currentParticipantCount = 0,
    required this.createdAt,
  });

  /// Check if event is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if registration is still open
  bool get isRegistrationOpen {
    final now = DateTime.now();
    final deadline = registrationDeadline ?? endDate;
    return now.isBefore(deadline) && now.isAfter(startDate.subtract(const Duration(hours: 1)));
  }

  /// Get days remaining
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  /// Check if event is full
  bool get isFull => currentParticipantCount >= maxParticipants;

  /// Get progress percentage (0-100)
  double getProgressPercentage() {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return 100;
    final total = endDate.difference(startDate).inSeconds;
    final elapsed = now.difference(startDate).inSeconds;
    return (elapsed / total * 100).clamp(0, 100);
  }

  /// Get time remaining string
  String getTimeRemaining() {
    if (!isActive) return 'イベント終了';
    final remaining = daysRemaining;
    if (remaining <= 0) return '本日まで';
    if (remaining == 1) return '明日まで';
    return '$remaining日間';
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'imageId': imageId,
        'maxParticipants': maxParticipants,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'registrationDeadline': registrationDeadline?.toIso8601String(),
        'minimumLevel': minimumLevel,
        'maxDailyParticipations': maxDailyParticipations,
        'rules': rules,
        'rewardTiers': rewardTiers.map((t) => t.toJson()).toList(),
        'eventData': eventData,
        'currentParticipantCount': currentParticipantCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SeasonalEvent.fromJson(Map<String, dynamic> json) => SeasonalEvent(
        eventId: json['eventId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: EventType.values.byName(json['type'] as String),
        status: EventStatus.values.byName(json['status'] as String),
        imageId: json['imageId'] as String?,
        maxParticipants: json['maxParticipants'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        registrationDeadline: json['registrationDeadline'] != null
            ? DateTime.parse(json['registrationDeadline'] as String)
            : null,
        minimumLevel: json['minimumLevel'] as int? ?? 1,
        maxDailyParticipations: json['maxDailyParticipations'] as int?,
        rules: json['rules'] as String?,
        rewardTiers: ((json['rewardTiers'] as List?) ?? [])
            .map((t) => EventRewardTier.fromJson(t as Map<String, dynamic>))
            .toList(),
        eventData: json['eventData'] as Map<String, dynamic>?,
        currentParticipantCount: json['currentParticipantCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// User's event participation
class EventParticipation {
  final String eventId;
  final String userId;
  final DateTime joinedAt;
  final int currentScore;          // Event-specific score
  final int currentRank;           // Current rank in event
  final bool isCompleted;
  final DateTime? completedAt;
  final int participationCount;    // Times participated in this event
  final bool hasClaimedReward;
  final Map<String, dynamic>? progressData; // Event-specific progress

  EventParticipation({
    required this.eventId,
    required this.userId,
    required this.joinedAt,
    this.currentScore = 0,
    this.currentRank = 0,
    this.isCompleted = false,
    this.completedAt,
    this.participationCount = 1,
    this.hasClaimedReward = false,
    this.progressData,
  });

  /// Check if user is in top 100
  bool get isRanked => currentRank > 0 && currentRank <= 100;

  /// Get event rank
  EventRank getEventRank() {
    if (currentRank == 1) return EventRank.gold;
    if (currentRank == 2) return EventRank.silver;
    if (currentRank == 3) return EventRank.bronze;
    if (currentRank <= 10) return EventRank.top10;
    if (currentRank <= 50) return EventRank.top50;
    if (currentRank <= 100) return EventRank.top100;
    return EventRank.participant;
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'userId': userId,
        'joinedAt': joinedAt.toIso8601String(),
        'currentScore': currentScore,
        'currentRank': currentRank,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'participationCount': participationCount,
        'hasClaimedReward': hasClaimedReward,
        'progressData': progressData,
      };

  factory EventParticipation.fromJson(Map<String, dynamic> json) => EventParticipation(
        eventId: json['eventId'] as String,
        userId: json['userId'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        currentScore: json['currentScore'] as int? ?? 0,
        currentRank: json['currentRank'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        participationCount: json['participationCount'] as int? ?? 1,
        hasClaimedReward: json['hasClaimedReward'] as bool? ?? false,
        progressData: json['progressData'] as Map<String, dynamic>?,
      );
}

/// User event leaderboard entry
class EventLeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarId;
  final int rank;
  final int score;
  final EventRank eventRank;
  final int? xpEarned;
  final int? coinsEarned;
  final bool isCurrentUser;

  EventLeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarId,
    required this.rank,
    required this.score,
    required this.eventRank,
    this.xpEarned,
    this.coinsEarned,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'avatarId': avatarId,
        'rank': rank,
        'score': score,
        'eventRank': eventRank.name,
        'xpEarned': xpEarned,
        'coinsEarned': coinsEarned,
        'isCurrentUser': isCurrentUser,
      };

  factory EventLeaderboardEntry.fromJson(Map<String, dynamic> json) => EventLeaderboardEntry(
        userId: json['userId'] as String,
        username: json['username'] as String,
        avatarId: json['avatarId'] as String?,
        rank: json['rank'] as int,
        score: json['score'] as int,
        eventRank: EventRank.values.byName(json['eventRank'] as String),
        xpEarned: json['xpEarned'] as int?,
        coinsEarned: json['coinsEarned'] as int?,
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      );
}

/// User's event collection
class UserEventParticipations {
  final String userId;
  final List<EventParticipation> participations; // Max 100
  final List<String> upcomingEventIds;          // Events user is registered for
  final List<String> completedEventIds;
  final DateTime lastUpdatedAt;
  final DateTime generatedAt;

  UserEventParticipations({
    required this.userId,
    required this.participations,
    required this.upcomingEventIds,
    required this.completedEventIds,
    required this.lastUpdatedAt,
    required this.generatedAt,
  });

  /// Get active participations
  List<EventParticipation> getActiveParticipations() =>
      participations.where((p) => !p.isCompleted).toList();

  /// Get completed participations
  List<EventParticipation> getCompletedParticipations() =>
      participations.where((p) => p.isCompleted).toList();

  /// Get ranked participations (top 100)
  List<EventParticipation> getRankedParticipations() =>
      participations.where((p) => p.isRanked).toList();

  /// Get total rewards earned from events
  int getTotalEventRewardsEarned() {
    var total = 0;
    for (final p in participations) {
      total += p.currentScore;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'participations': participations.map((p) => p.toJson()).toList(),
        'upcomingEventIds': upcomingEventIds,
        'completedEventIds': completedEventIds,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory UserEventParticipations.fromJson(Map<String, dynamic> json) =>
      UserEventParticipations(
        userId: json['userId'] as String,
        participations: ((json['participations'] as List?) ?? [])
            .map((p) => EventParticipation.fromJson(p as Map<String, dynamic>))
            .toList(),
        upcomingEventIds: ((json['upcomingEventIds'] as List?) ?? [])
            .map((id) => id as String)
            .toList(),
        completedEventIds: ((json['completedEventIds'] as List?) ?? [])
            .map((id) => id as String)
            .toList(),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}

/// Event statistics
class EventStatistics {
  final String userId;
  final int totalEventsParticipated;
  final int totalEventsCompleted;
  final int totalEventRewardsEarned;
  final int totalEventRankings;      // Times placed in top 100
  final int goldMedals;              // 1st place finishes
  final int silverMedals;            // 2nd place finishes
  final int bronzeMedals;            // 3rd place finishes
  final int topTenFinishes;
  final double averageEventScore;
  final DateTime lastEventParticipationAt;
  final DateTime lastUpdatedAt;

  EventStatistics({
    required this.userId,
    this.totalEventsParticipated = 0,
    this.totalEventsCompleted = 0,
    this.totalEventRewardsEarned = 0,
    this.totalEventRankings = 0,
    this.goldMedals = 0,
    this.silverMedals = 0,
    this.bronzeMedals = 0,
    this.topTenFinishes = 0,
    this.averageEventScore = 0.0,
    required this.lastEventParticipationAt,
    required this.lastUpdatedAt,
  });

  /// Get competition experience level
  String getCompetitionLevel() {
    if (totalEventsParticipated < 5) return '初心者';
    if (totalEventsParticipated < 20) return '経験者';
    if (totalEventsParticipated < 50) return 'ベテラン';
    if (totalEventsParticipated < 100) return 'エリート';
    return 'マスター';
  }

  /// Get total medals
  int getTotalMedals() => goldMedals + silverMedals + bronzeMedals;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalEventsParticipated': totalEventsParticipated,
        'totalEventsCompleted': totalEventsCompleted,
        'totalEventRewardsEarned': totalEventRewardsEarned,
        'totalEventRankings': totalEventRankings,
        'goldMedals': goldMedals,
        'silverMedals': silverMedals,
        'bronzeMedals': bronzeMedals,
        'topTenFinishes': topTenFinishes,
        'averageEventScore': averageEventScore,
        'lastEventParticipationAt': lastEventParticipationAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory EventStatistics.fromJson(Map<String, dynamic> json) => EventStatistics(
        userId: json['userId'] as String,
        totalEventsParticipated: json['totalEventsParticipated'] as int? ?? 0,
        totalEventsCompleted: json['totalEventsCompleted'] as int? ?? 0,
        totalEventRewardsEarned: json['totalEventRewardsEarned'] as int? ?? 0,
        totalEventRankings: json['totalEventRankings'] as int? ?? 0,
        goldMedals: json['goldMedals'] as int? ?? 0,
        silverMedals: json['silverMedals'] as int? ?? 0,
        bronzeMedals: json['bronzeMedals'] as int? ?? 0,
        topTenFinishes: json['topTenFinishes'] as int? ?? 0,
        averageEventScore: (json['averageEventScore'] as num?)?.toDouble() ?? 0.0,
        lastEventParticipationAt: DateTime.parse(json['lastEventParticipationAt'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete event collection
class EventCollection {
  final String userId;
  final List<SeasonalEvent> allEvents;           // Max 50
  final UserEventParticipations participations;
  final EventStatistics statistics;
  final DateTime generatedAt;

  EventCollection({
    required this.userId,
    required this.allEvents,
    required this.participations,
    required this.statistics,
    required this.generatedAt,
  });

  /// Get active events
  List<SeasonalEvent> getActiveEvents() =>
      allEvents.where((e) => e.isActive).toList();

  /// Get upcoming events
  List<SeasonalEvent> getUpcomingEvents() =>
      allEvents.where((e) => e.status == EventStatus.upcoming).toList();

  /// Get events by type
  List<SeasonalEvent> getEventsByType(EventType type) =>
      allEvents.where((e) => e.type == type).toList();

  /// Get events user can still register for
  List<SeasonalEvent> getAvailableEvents(int userLevel) => allEvents
      .where((e) =>
          e.isRegistrationOpen &&
          !e.isFull &&
          userLevel >= e.minimumLevel &&
          !participations.participations.any((p) => p.eventId == e.eventId))
      .toList();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'allEvents': allEvents.map((e) => e.toJson()).toList(),
        'participations': participations.toJson(),
        'statistics': statistics.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory EventCollection.fromJson(Map<String, dynamic> json) => EventCollection(
        userId: json['userId'] as String,
        allEvents: ((json['allEvents'] as List?) ?? [])
            .map((e) => SeasonalEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        participations:
            UserEventParticipations.fromJson(json['participations'] as Map<String, dynamic>),
        statistics: EventStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
