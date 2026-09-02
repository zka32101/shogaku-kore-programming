import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shogaku_kore_programming/models/leaderboards_rankings.dart';

/// State for leaderboard management
class LeaderboardState {
  final LeaderboardCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  const LeaderboardState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  LeaderboardState copyWith({
    LeaderboardCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) {
    return LeaderboardState(
      collection: collection ?? this.collection,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

/// StateNotifier for leaderboard management
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(const LeaderboardState());

  /// Initialize leaderboards for a user
  Future<void> initializeLeaderboards(
    String userId,
    String userName,
    int birthYear,
  ) async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'leaderboards_$userId';

      // Try to load existing data
      final existingData = prefs.getString(key);
      if (existingData != null) {
        final collection = LeaderboardCollection.fromJson(
          jsonDecode(existingData) as Map<String, dynamic>,
        );
        state = state.copyWith(
          collection: collection,
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
        return;
      }

      // Create new leaderboards
      final now = DateTime.now();
      final userGrade = UserGrade(
        userId: userId,
        currentGrade: SchoolGrade.fromBirthYear(birthYear),
        birthYear: birthYear,
        lastGradeChangeAt: now,
        firstEnrolledAt: now,
        autoPromoteEnabled: true,
      );

      final statistics = RankingStatistics(
        userId: userId,
        userName: userName,
        currentGrade: userGrade.currentGrade,
        rankPositions: {
          RankingMetric.totalCoins: 0,
          RankingMetric.activityCompletions: 0,
          RankingMetric.compositeScore: 0,
        },
        scores: {
          RankingMetric.totalCoins: 0.0,
          RankingMetric.activityCompletions: 0.0,
          RankingMetric.compositeScore: 0.0,
        },
        tiers: {
          RankingMetric.totalCoins: 'ビギナー',
          RankingMetric.activityCompletions: 'ビギナー',
          RankingMetric.compositeScore: 'ビギナー',
        },
        totalCoinsEarned: 0,
        totalActivitiesCompleted: 0,
        compositeScore: 0.0,
        firstRankedAt: now,
        lastUpdatedAt: now,
      );

      final collection = LeaderboardCollection(
        userId: userId,
        userGrade: userGrade,
        statistics: statistics,
        allLeaderboards: _createDefaultLeaderboards(userId, userName, now),
        userRankings: [],
        generatedAt: now,
      );

      // Save to SharedPreferences
      await prefs.setString(key, jsonEncode(collection.toJson()));

      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'リーダーボード初期化エラー: $e',
      );
    }
  }

  /// Check and promote grade if needed (April auto-promotion)
  Future<void> checkAndPromoteGrade(String userId) async {
    if (state.collection?.userGrade == null) return;

    try {
      final userGrade = state.collection!.userGrade!;

      if (userGrade.shouldPromoteToNextGrade()) {
        final promotedGrade = userGrade.promoteToNextGrade();

        final updatedCollection = state.collection!.copyWith(
          userGrade: promotedGrade,
          statistics: state.collection!.statistics?.copyWith(
            currentGrade: promotedGrade.currentGrade,
          ),
        );

        state = state.copyWith(collection: updatedCollection);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final key = 'leaderboards_$userId';
        await prefs.setString(key, jsonEncode(updatedCollection.toJson()));
      }
    } catch (e) {
      state = state.copyWith(error: '学年昇進エラー: $e');
    }
  }

  /// Update rankings based on current user metrics
  /// Requires totalCoins and activityCompletions from other providers
  Future<void> updateRankings(
    String userId,
    int totalCoins,
    int activityCompletions,
  ) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      // Calculate composite score
      final compositeScore = (totalCoins * 0.6) + (activityCompletions * 40);

      final updatedStatistics = collection.statistics?.copyWith(
            totalCoinsEarned: totalCoins,
            totalActivitiesCompleted: activityCompletions,
            compositeScore: compositeScore,
            rankPositions: {
              RankingMetric.totalCoins: 0, // Will be calculated from leaderboard
              RankingMetric.activityCompletions: 0,
              RankingMetric.compositeScore: 0,
            },
            lastUpdatedAt: now,
          ) ??
          collection.statistics!;

      final updatedCollection = collection.copyWith(
        statistics: updatedStatistics,
      );

      state = state.copyWith(
        collection: updatedCollection,
        lastUpdatedAt: now,
      );

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = 'leaderboards_$userId';
      await prefs.setString(key, jsonEncode(updatedCollection.toJson()));
    } catch (e) {
      state = state.copyWith(error: 'ランキング更新エラー: $e');
    }
  }

  /// Create default leaderboards for all metrics and groupings
  List<Leaderboard> _createDefaultLeaderboards(
    String userId,
    String userName,
    DateTime now,
  ) {
    final leaderboards = <Leaderboard>[];

    for (final metric in RankingMetric.values) {
      // Overall leaderboard
      leaderboards.add(
        Leaderboard(
          leaderboardId: '${metric.name}_overall_${DateTime.now().millisecondsSinceEpoch}',
          metric: metric,
          grouping: RankingGrouping.overall,
          groupValue: null,
          entries: [],
          calculatedAt: now,
          lastUpdatedAt: now,
        ),
      );

      // By grade leaderboards (4年生, 5年生, 6年生)
      for (final grade in SchoolGrade.values) {
        leaderboards.add(
          Leaderboard(
            leaderboardId:
                '${metric.name}_grade_${grade.name}_${DateTime.now().millisecondsSinceEpoch}',
            metric: metric,
            grouping: RankingGrouping.byGrade,
            groupValue: grade.displayName,
            entries: [],
            calculatedAt: now,
            lastUpdatedAt: now,
          ),
        );
      }

      // By start month leaderboards (2026年1月, 2月, etc.)
      final currentYear = DateTime.now().year;
      for (int month = 1; month <= 12; month++) {
        final monthName = '${currentYear}年${month}月';
        leaderboards.add(
          Leaderboard(
            leaderboardId:
                '${metric.name}_month_${month}_${DateTime.now().millisecondsSinceEpoch}',
            metric: metric,
            grouping: RankingGrouping.byStartMonth,
            groupValue: monthName,
            entries: [],
            calculatedAt: now,
            lastUpdatedAt: now,
          ),
        );
      }
    }

    return leaderboards;
  }

  /// Persist to SharedPreferences
  Future<void> persist(String userId) async {
    try {
      if (state.collection == null) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'leaderboards_$userId';
      await prefs.setString(key, jsonEncode(state.collection!.toJson()));
    } catch (e) {
      state = state.copyWith(error: '永続化エラー: $e');
    }
  }
}

/// Main leaderboard provider
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(),
);

/// Leaderboard collection provider
final leaderboardCollectionProvider =
    Provider<LeaderboardCollection?>((ref) {
  final state = ref.watch(leaderboardProvider);
  return state.collection;
});

/// User grade provider
final userGradeProvider = Provider<UserGrade?>((ref) {
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.userGrade;
});

/// Current school grade provider
final currentGradeProvider = Provider<SchoolGrade?>((ref) {
  final grade = ref.watch(userGradeProvider);
  return grade?.currentGrade;
});

/// Current grade display name provider
final currentGradeDisplayProvider = Provider<String>((ref) {
  final grade = ref.watch(currentGradeProvider);
  return grade?.displayName ?? '未設定';
});

/// Ranking statistics provider
final rankingStatisticsProvider = Provider<RankingStatistics?>((ref) {
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.statistics;
});

/// Get leaderboard for specific metric and grouping
final leaderboardByMetricAndGroupingProvider =
    Provider.family<Leaderboard?, (RankingMetric, RankingGrouping)>((ref, params) {
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.getLeaderboard(params.$1, params.$2);
});

/// Get all leaderboards for a specific metric
final leaderboardsByMetricProvider =
    Provider.family<List<Leaderboard>, RankingMetric>((ref, metric) {
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.getLeaderboardsByMetric(metric) ?? [];
});

/// Overall leaderboard provider (all users, all metrics)
final overallLeaderboardProvider =
    Provider.family<Leaderboard?, RankingMetric>((ref, metric) {
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.getLeaderboard(metric, RankingGrouping.overall);
});

/// Grade-specific leaderboard provider
final gradeLeaderboardProvider = Provider.family<Leaderboard?, (RankingMetric, SchoolGrade)>(
  (ref, params) {
    final collection = ref.watch(leaderboardCollectionProvider);
    return collection?.getLeaderboard(
      params.$1,
      RankingGrouping.byGrade,
      params.$2.displayName,
    );
  },
);

/// Month-specific leaderboard provider
final monthLeaderboardProvider =
    Provider.family<Leaderboard?, (RankingMetric, String)>((ref, params) {
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.getLeaderboard(
    params.$1,
    RankingGrouping.byStartMonth,
    params.$2,
  );
});

/// User's ranking for specific metric
final userRankingForMetricProvider =
    Provider.family<RankingEntry?, RankingMetric>((ref, metric) {
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.getUserRankingForMetric(metric);
});

/// Total coins ranking provider
final totalCoinsLeaderboardProvider =
    Provider<Leaderboard?>((ref) {
  return ref.watch(
    leaderboardByMetricAndGroupingProvider(
      (RankingMetric.totalCoins, RankingGrouping.overall),
    ),
  );
});

/// Activity completions ranking provider
final activityCompletionsLeaderboardProvider =
    Provider<Leaderboard?>((ref) {
  return ref.watch(
    leaderboardByMetricAndGroupingProvider(
      (RankingMetric.activityCompletions, RankingGrouping.overall),
    ),
  );
});

/// Composite score ranking provider
final compositeScoreLeaderboardProvider =
    Provider<Leaderboard?>((ref) {
  return ref.watch(
    leaderboardByMetricAndGroupingProvider(
      (RankingMetric.compositeScore, RankingGrouping.overall),
    ),
  );
});

/// Top 10 users for coins
final top10CoinUsersProvider = Provider<List<RankingEntry>>((ref) {
  final leaderboard = ref.watch(totalCoinsLeaderboardProvider);
  return leaderboard?.getTopEntries(10) ?? [];
});

/// Top 10 users for activity completions
final top10ActivityUsersProvider = Provider<List<RankingEntry>>((ref) {
  final leaderboard = ref.watch(activityCompletionsLeaderboardProvider);
  return leaderboard?.getTopEntries(10) ?? [];
});

/// Top 10 users for composite score
final top10CompositeScoreUsersProvider = Provider<List<RankingEntry>>((ref) {
  final leaderboard = ref.watch(compositeScoreLeaderboardProvider);
  return leaderboard?.getTopEntries(10) ?? [];
});

/// User's rank for total coins
final userCoinsRankProvider = Provider<int?>((ref) {
  final ranking = ref.watch(userRankingForMetricProvider(RankingMetric.totalCoins));
  return ranking?.rankPosition;
});

/// User's rank for activity completions
final userActivityRankProvider = Provider<int?>((ref) {
  final ranking =
      ref.watch(userRankingForMetricProvider(RankingMetric.activityCompletions));
  return ranking?.rankPosition;
});

/// User's rank for composite score
final userCompositeScoreRankProvider = Provider<int?>((ref) {
  final ranking = ref.watch(userRankingForMetricProvider(RankingMetric.compositeScore));
  return ranking?.rankPosition;
});

/// Best tier across all metrics
final bestTierProvider = Provider<String>((ref) {
  final stats = ref.watch(rankingStatisticsProvider);
  return stats?.getBestTier() ?? 'ビギナー';
});

/// Overall rank (average across metrics)
final overallRankProvider = Provider<int>((ref) {
  final stats = ref.watch(rankingStatisticsProvider);
  return stats?.overallRank ?? 0;
});

/// Get user's current grade with auto-promotion check
final userGradeWithPromotionProvider =
    FutureProvider.family<UserGrade?, String>((ref, userId) async {
  final notifier = ref.read(leaderboardProvider.notifier);
  await notifier.checkAndPromoteGrade(userId);
  final collection = ref.watch(leaderboardCollectionProvider);
  return collection?.userGrade;
});

/// Total leaderboard participants provider
final leaderboardParticipantCountProvider =
    Provider.family<int, RankingMetric>((ref, metric) {
  final leaderboard = ref.watch(overallLeaderboardProvider(metric));
  return leaderboard?.totalParticipants ?? 0;
});

/// Grade-specific participant count
final gradeParticipantCountProvider =
    Provider.family<int, (SchoolGrade, RankingMetric)>((ref, params) {
  final leaderboard = ref.watch(gradeLeaderboardProvider((params.$2, params.$1)));
  return leaderboard?.totalParticipants ?? 0;
});

/// All metrics available
final allRankingMetricsProvider = Provider<List<RankingMetric>>((ref) {
  return RankingMetric.values;
});

/// All school grades
final allSchoolGradesProvider = Provider<List<SchoolGrade>>((ref) {
  return SchoolGrade.values;
});

/// All grouping options
final allGroupingOptionsProvider = Provider<List<RankingGrouping>>((ref) {
  return RankingGrouping.values;
});
