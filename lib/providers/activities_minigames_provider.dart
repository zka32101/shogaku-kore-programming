import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/activities_minigames.dart';

/// Activity state
class ActivityState {
  final ActivityCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  ActivityState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  ActivityState copyWith({
    ActivityCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      ActivityState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

/// Activity notifier
class ActivityNotifier extends StateNotifier<ActivityState> {
  ActivityNotifier() : super(ActivityState());

  /// Initialize activities
  Future<void> initializeActivities(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'activities_$userId';

      final stored = prefs.getString(key);
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        state = state.copyWith(
          collection: ActivityCollection.fromJson(json),
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
        return;
      }

      final now = DateTime.now();
      final defaultActivities = _createDefaultActivities(now);

      final collection = ActivityCollection(
        userId: userId,
        allActivities: defaultActivities,
        participations: [],
        results: [],
        statistics: ActivityStatistics(
          userId: userId,
          firstActivityAt: now,
          lastActivityAt: now,
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
        error: 'Failed to initialize activities: $e',
      );
    }
  }

  /// Start activity
  Future<void> startActivity(String userId, String activityId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final activity = collection.allActivities.firstWhere(
        (a) => a.activityId == activityId,
        orElse: () => throw Exception('Activity not found'),
      );

      if (!activity.isAvailable) {
        throw Exception('Activity not available');
      }

      // Check if daily activity already completed today
      if (activity.isDaily) {
        final completedToday = collection.results
            .where((r) =>
                r.activityId == activityId &&
                r.completedAt.year == now.year &&
                r.completedAt.month == now.month &&
                r.completedAt.day == now.day)
            .isNotEmpty;

        if (completedToday && activity.maxAttempts == 1) {
          throw Exception('Already completed today');
        }
      }

      // Check max attempts
      if (activity.maxAttempts > 0) {
        final todayCount = collection.participations
            .where((p) =>
                p.activityId == activityId &&
                p.startedAt.year == now.year &&
                p.startedAt.month == now.month &&
                p.startedAt.day == now.day)
            .length;

        if (todayCount >= activity.maxAttempts) {
          throw Exception('Max attempts reached');
        }
      }

      final participationId =
          'part_${now.millisecondsSinceEpoch}_${(now.microsecond % 10000)}';
      final participation = ActivityParticipation(
        participationId: participationId,
        userId: userId,
        activityId: activityId,
        startedAt: now,
      );

      final updatedParticipations = [...collection.participations, participation]
          .take(500)
          .toList();

      final updatedCollection = ActivityCollection(
        userId: userId,
        allActivities: collection.allActivities,
        participations: updatedParticipations,
        results: collection.results,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to start activity: $e');
    }
  }

  /// Complete activity
  Future<void> completeActivity(
    String userId,
    String activityId,
    int score,
  ) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final activity = collection.allActivities.firstWhere(
        (a) => a.activityId == activityId,
        orElse: () => throw Exception('Activity not found'),
      );

      // Find the participation record
      final participation = collection.participations
          .where((p) =>
              p.activityId == activityId && p.userId == userId && !p.isCompleted)
          .fold<ActivityParticipation?>(null, (prev, curr) =>
              prev == null || curr.startedAt.isAfter(prev.startedAt) ? curr : prev);

      if (participation == null) {
        throw Exception('No active participation');
      }

      // Calculate rewards
      final scoreMultiplier = score / 100.0;
      final coinsReward =
          (activity.baseCoins * activity.coinMultiplier * scoreMultiplier).toInt();
      final xpReward =
          (activity.baseXp * activity.xpMultiplier * scoreMultiplier).toInt();

      // Add difficulty multiplier
      final difficultyBonus = switch (activity.difficulty) {
        ActivityDifficulty.easy => 1.0,
        ActivityDifficulty.normal => 1.2,
        ActivityDifficulty.hard => 1.5,
        ActivityDifficulty.expert => 2.0,
      };

      final finalCoins = (coinsReward * difficultyBonus).toInt();
      final finalXp = (xpReward * difficultyBonus).toInt();

      // Check for perfect score
      final isPerfect = score == 100;

      // Check for new high score
      final previousBest = collection.getPersonalBest(activityId);
      final isNewBest = previousBest == null || score > previousBest.score;

      final resultId =
          'result_${now.millisecondsSinceEpoch}_${(now.microsecond % 10000)}';
      final result = ActivityResult(
        resultId: resultId,
        userId: userId,
        activityId: activityId,
        score: score,
        coinsReward: finalCoins,
        xpReward: finalXp,
        premiumCoinReward: isPerfect ? 1 : null,
        completedAt: now,
        timeSpentSeconds: now.difference(participation.startedAt).inSeconds,
        isPerfectScore: isPerfect,
        isNewHighScore: isNewBest,
        feedbackMessage: _getFeedback(score),
      );

      // Update participation to completed
      final updatedParticipations = collection.participations.map((p) {
        if (p.participationId == participation.participationId) {
          return ActivityParticipation(
            participationId: p.participationId,
            userId: p.userId,
            activityId: p.activityId,
            startedAt: p.startedAt,
            completedAt: now,
            isCompleted: true,
            score: score,
            coinsEarned: finalCoins,
            xpEarned: finalXp,
            premiumCoinEarned: isPerfect ? 1 : null,
            timeSpentSeconds: result.timeSpentSeconds,
          );
        }
        return p;
      }).toList();

      final updatedResults = [...collection.results, result].take(1000).toList();

      // Update activity play count
      final updatedActivities = collection.allActivities.map((a) {
        if (a.activityId == activityId) {
          return Activity(
            activityId: a.activityId,
            name: a.name,
            description: a.description,
            type: a.type,
            difficulty: a.difficulty,
            requiredLevel: a.requiredLevel,
            timeLimit: a.timeLimit,
            maxAttempts: a.maxAttempts,
            baseCoins: a.baseCoins,
            baseXp: a.baseXp,
            premiumCoinReward: a.premiumCoinReward,
            coinMultiplier: a.coinMultiplier,
            xpMultiplier: a.xpMultiplier,
            imageId: a.imageId,
            instructions: a.instructions,
            addedAt: a.addedAt,
            availableUntil: a.availableUntil,
            isDaily: a.isDaily,
            isWeekly: a.isWeekly,
            isFeatured: a.isFeatured,
            playCount: a.playCount + 1,
            averageScore: _calculateAverageScore(a.activityId, updatedResults),
            metadata: a.metadata,
          );
        }
        return a;
      }).toList();

      // Update statistics
      final stats = collection.statistics;
      final updatedStats = ActivityStatistics(
        userId: userId,
        totalActivitiesCompleted: stats.totalActivitiesCompleted + 1,
        totalCoinsEarned: stats.totalCoinsEarned + finalCoins,
        totalXpEarned: stats.totalXpEarned + finalXp,
        perfectScores: isPerfect ? stats.perfectScores + 1 : stats.perfectScores,
        personalBests:
            isNewBest ? stats.personalBests + 1 : stats.personalBests,
        averageScore: _calculateOverallAverage(updatedResults),
        longestPlayStreak: stats.longestPlayStreak,
        firstActivityAt: stats.firstActivityAt,
        lastActivityAt: now,
        lastUpdatedAt: now,
      );

      final updatedCollection = ActivityCollection(
        userId: userId,
        allActivities: updatedActivities,
        participations: updatedParticipations,
        results: updatedResults,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to complete activity: $e');
    }
  }

  /// Persist to SharedPreferences
  Future<void> _persist(String userId, ActivityCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'activities_$userId',
      jsonEncode(collection.toJson()),
    );
  }

  /// Create default activities
  List<Activity> _createDefaultActivities(DateTime now) {
    final activities = <Activity>[];

    // Quick games
    activities.add(Activity(
      activityId: 'quick_memory_1',
      name: 'メモリーチャレンジ',
      description: 'タイルをマッチさせてください',
      type: ActivityType.memoryGame,
      difficulty: ActivityDifficulty.easy,
      baseCoins: 50,
      baseXp: 25,
      addedAt: now,
      isDaily: true,
      isFeatured: true,
      timeLimit: 60,
    ));

    activities.add(Activity(
      activityId: 'quick_speed_1',
      name: 'スピードマス',
      description: '素早く計算問題を解く',
      type: ActivityType.speedGame,
      difficulty: ActivityDifficulty.normal,
      baseCoins: 75,
      baseXp: 40,
      addedAt: now,
      isDaily: true,
      timeLimit: 90,
    ));

    activities.add(Activity(
      activityId: 'quick_word_1',
      name: 'ワードビルダー',
      description: 'letters から単語を作成',
      type: ActivityType.wordGame,
      difficulty: ActivityDifficulty.normal,
      baseCoins: 60,
      baseXp: 30,
      addedAt: now,
      isDaily: true,
      timeLimit: 120,
    ));

    // Daily challenges
    activities.add(Activity(
      activityId: 'daily_math_1',
      name: '数学パズル',
      description: '毎日の数学チャレンジ',
      type: ActivityType.mathGame,
      difficulty: ActivityDifficulty.hard,
      baseCoins: 100,
      baseXp: 60,
      premiumCoinReward: 1,
      addedAt: now,
      isDaily: true,
      isFeatured: true,
    ));

    activities.add(Activity(
      activityId: 'daily_trivia_1',
      name: 'トリビアマスター',
      description: '一般知識トリビア',
      type: ActivityType.trivia,
      difficulty: ActivityDifficulty.normal,
      baseCoins: 70,
      baseXp: 45,
      addedAt: now,
      isDaily: true,
    ));

    // Puzzle games
    activities.add(Activity(
      activityId: 'puzzle_logic_1',
      name: 'ロジックパズル',
      description: '論理的思考力を鍛える',
      type: ActivityType.puzzleGame,
      difficulty: ActivityDifficulty.hard,
      requiredLevel: 5,
      baseCoins: 150,
      baseXp: 80,
      premiumCoinReward: 2,
      addedAt: now,
      isFeatured: true,
    ));

    activities.add(Activity(
      activityId: 'puzzle_pattern_1',
      name: 'パターンマッチ',
      description: 'パターンを完成させる',
      type: ActivityType.puzzleGame,
      difficulty: ActivityDifficulty.normal,
      baseCoins: 80,
      baseXp: 50,
      addedAt: now,
    ));

    // Expert activities
    activities.add(Activity(
      activityId: 'expert_challenge_1',
      name: 'エキスパートチャレンジ',
      description: '究極の難易度',
      type: ActivityType.speedGame,
      difficulty: ActivityDifficulty.expert,
      requiredLevel: 20,
      baseCoins: 300,
      baseXp: 200,
      premiumCoinReward: 5,
      addedAt: now,
      isFeatured: true,
    ));

    // Weekly challenges
    activities.add(Activity(
      activityId: 'weekly_achievement_1',
      name: '週間チャレンジ',
      description: '1週間のみ利用可能',
      type: ActivityType.speedGame,
      difficulty: ActivityDifficulty.hard,
      baseCoins: 200,
      baseXp: 120,
      premiumCoinReward: 3,
      addedAt: now,
      isWeekly: true,
      isFeatured: true,
    ));

    return activities;
  }

  /// Get feedback message based on score
  String _getFeedback(int score) {
    if (score == 100) return '完璧！すばらしい！';
    if (score >= 90) return 'excellent!';
    if (score >= 80) return 'great!';
    if (score >= 70) return 'good!';
    if (score >= 60) return 'okay!';
    return 'try again!';
  }

  /// Calculate average score for activity
  double _calculateAverageScore(String activityId, List<ActivityResult> results) {
    final activityResults = results.where((r) => r.activityId == activityId).toList();
    if (activityResults.isEmpty) return 0.0;
    final sum = activityResults.fold<int>(0, (sum, r) => sum + r.score);
    return sum / activityResults.length;
  }

  /// Calculate overall average score
  double _calculateOverallAverage(List<ActivityResult> results) {
    if (results.isEmpty) return 0.0;
    final sum = results.fold<int>(0, (sum, r) => sum + r.score);
    return sum / results.length;
  }
}

// Riverpod providers
final activityProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier();
});

final activityCollectionProvider = Provider<ActivityCollection?>((ref) {
  final state = ref.watch(activityProvider);
  return state.collection;
});

final allActivitiesProvider = Provider<List<Activity>>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.allActivities ?? [];
});

final availableActivitiesProvider = Provider<List<Activity>>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.getAvailableActivities() ?? [];
});

final featuredActivitiesProvider = Provider<List<Activity>>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.getFeaturedActivities() ?? [];
});

final activitiesByTypeProvider =
    Provider.family<List<Activity>, ActivityType>((ref, type) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.getActivitiesByType(type) ?? [];
});

final activitiesByDifficultyProvider = Provider
    .family<List<Activity>, ActivityDifficulty>((ref, difficulty) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.getActivitiesByDifficulty(difficulty) ?? [];
});

final todaysActivitiesProvider = Provider<List<Activity>>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.getTodaysActivities() ?? [];
});

final activityStatisticsProvider = Provider<ActivityStatistics?>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.statistics;
});

final activityTierProvider = Provider<String>((ref) {
  final stats = ref.watch(activityStatisticsProvider);
  return stats?.getActivityTier() ?? 'ビギナー';
});

final totalActivitiesCompletedProvider = Provider<int>((ref) {
  final stats = ref.watch(activityStatisticsProvider);
  return stats?.totalActivitiesCompleted ?? 0;
});

final totalCoinsFromActivitiesProvider = Provider<int>((ref) {
  final stats = ref.watch(activityStatisticsProvider);
  return stats?.totalCoinsEarned ?? 0;
});

final totalXpFromActivitiesProvider = Provider<int>((ref) {
  final stats = ref.watch(activityStatisticsProvider);
  return stats?.totalXpEarned ?? 0;
});

final averageActivityScoreProvider = Provider<double>((ref) {
  final stats = ref.watch(activityStatisticsProvider);
  return stats?.averageScore ?? 0.0;
});

final perfectScoresProvider = Provider<int>((ref) {
  final stats = ref.watch(activityStatisticsProvider);
  return stats?.perfectScores ?? 0;
});

final personalBestsProvider = Provider<int>((ref) {
  final stats = ref.watch(activityStatisticsProvider);
  return stats?.personalBests ?? 0;
});

final activityResultsProvider = Provider<List<ActivityResult>>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.results ?? [];
});

final completedTodayProvider = Provider<List<ActivityResult>>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.getCompletedToday() ?? [];
});

final activityParticipationsProvider = Provider<List<ActivityParticipation>>((ref) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.participations ?? [];
});

final personalBestProvider = Provider.family<ActivityResult?, String>((ref, activityId) {
  final collection = ref.watch(activityCollectionProvider);
  return collection?.getPersonalBest(activityId);
});
