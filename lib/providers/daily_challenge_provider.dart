import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge.dart';

class DailyChallengeState {
  final ChallengeCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;
  final List<String> recentlyCompletedIds; // Challenge IDs completed in this session

  DailyChallengeState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
    this.recentlyCompletedIds = const [],
  });

  DailyChallengeState copyWith({
    ChallengeCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
    List<String>? recentlyCompletedIds,
  }) =>
      DailyChallengeState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        recentlyCompletedIds: recentlyCompletedIds ?? this.recentlyCompletedIds,
      );
}

class DailyChallengeNotifier extends StateNotifier<DailyChallengeState> {
  DailyChallengeNotifier() : super(DailyChallengeState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// Initialize challenges for user
  Future<void> initializeChallenges(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = prefs.getString('challenges_$userId');

      late List<Challenge> availableChallenges;
      late Map<String, ChallengeProgress> progress;
      late List<ChallengeCompletion> completionHistory;

      if (challengesJson != null) {
        try {
          final parsed = Map<String, dynamic>.from(challengesJson as Map);
          availableChallenges = ((parsed['availableChallenges'] as List?) ?? [])
              .map((c) => Challenge.fromJson(c as Map<String, dynamic>))
              .toList();
          progress = ((parsed['progress'] as Map<String, dynamic>?) ?? {}).map(
            (k, v) => MapEntry(k, ChallengeProgress.fromJson(v as Map<String, dynamic>)),
          );
          completionHistory = ((parsed['completionHistory'] as List?) ?? [])
              .map((c) => ChallengeCompletion.fromJson(c as Map<String, dynamic>))
              .toList();
        } catch (e) {
          availableChallenges = _createDefaultChallenges();
          progress = {};
          completionHistory = [];
        }
      } else {
        availableChallenges = _createDefaultChallenges();
        progress = {};
        completionHistory = [];
      }

      final stats = _createDefaultStats(userId);

      final challenges = UserChallenges(
        userId: userId,
        availableChallenges: availableChallenges,
        progress: progress,
        completionHistory: completionHistory,
        lastUpdatedAt: DateTime.now(),
        generatedAt: DateTime.now(),
      );

      final collection = ChallengeCollection(
        userId: userId,
        challenges: challenges,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _persistChallenges(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Start a challenge
  Future<bool> startChallenge(String userId, String challengeId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final challenge = collection.challenges.availableChallenges
          .firstWhere((c) => c.challengeId == challengeId, orElse: () => null as dynamic);
      if (challenge == null) return false;

      if (!challenge.isAvailable) return false;

      final newProgress = Map<String, ChallengeProgress>.from(collection.challenges.progress);

      if (!newProgress.containsKey(challengeId)) {
        newProgress[challengeId] = ChallengeProgress(
          challengeId: challengeId,
          userId: userId,
          currentProgress: 0,
          startedAt: DateTime.now(),
          firstAttemptAt: DateTime.now(),
          attemptCount: 1,
        );
      } else {
        final existing = newProgress[challengeId]!;
        newProgress[challengeId] = ChallengeProgress(
          challengeId: challengeId,
          userId: userId,
          currentProgress: existing.currentProgress,
          isCompleted: existing.isCompleted,
          completedAt: existing.completedAt,
          startedAt: existing.startedAt,
          firstAttemptAt: existing.firstAttemptAt ?? DateTime.now(),
          attemptCount: existing.attemptCount + 1,
          claimedReward: existing.claimedReward,
        );
      }

      final updatedChallenges = UserChallenges(
        userId: collection.challenges.userId,
        availableChallenges: collection.challenges.availableChallenges,
        progress: newProgress,
        completionHistory: collection.challenges.completionHistory,
        lastUpdatedAt: DateTime.now(),
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ChallengeCollection(
        userId: collection.userId,
        challenges: updatedChallenges,
        stats: collection.stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistChallenges(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update challenge progress
  Future<bool> updateProgress(
    String userId,
    String challengeId,
    int progressAmount,
  ) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final challenge = collection.challenges.availableChallenges
          .firstWhere((c) => c.challengeId == challengeId, orElse: () => null as dynamic);
      if (challenge == null) return false;

      final progress = collection.challenges.progress[challengeId];
      if (progress == null) return false;

      final newProgress = Map<String, ChallengeProgress>.from(collection.challenges.progress);
      final updatedProgress = progress.currentProgress + progressAmount;
      final isCompleted = updatedProgress >= challenge.targetCount;

      newProgress[challengeId] = ChallengeProgress(
        challengeId: challengeId,
        userId: userId,
        currentProgress: isCompleted ? challenge.targetCount : updatedProgress,
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : progress.completedAt,
        startedAt: progress.startedAt,
        firstAttemptAt: progress.firstAttemptAt,
        attemptCount: progress.attemptCount,
        claimedReward: progress.claimedReward,
      );

      final updatedChallenges = UserChallenges(
        userId: collection.challenges.userId,
        availableChallenges: collection.challenges.availableChallenges,
        progress: newProgress,
        completionHistory: collection.challenges.completionHistory,
        lastUpdatedAt: DateTime.now(),
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ChallengeCollection(
        userId: collection.userId,
        challenges: updatedChallenges,
        stats: collection.stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistChallenges(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Complete challenge and claim reward
  Future<bool> completeChallenge(String userId, String challengeId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final challenge = collection.challenges.availableChallenges
          .firstWhere((c) => c.challengeId == challengeId, orElse: () => null as dynamic);
      if (challenge == null) return false;

      final progress = collection.challenges.progress[challengeId];
      if (progress == null || !progress.isCompleted) return false;

      // Calculate reward
      final baseReward = challenge.getAdjustedReward();
      final bonusEarned = progress.completedEarly;
      final totalReward = bonusEarned
          ? (baseReward + (challenge.reward.bonusAmount ?? 0))
          : baseReward;

      // Create completion record
      final completion = ChallengeCompletion(
        completionId: _generateId('completion'),
        challengeId: challengeId,
        userId: userId,
        rewardEarned: totalReward,
        bonusRewardEarned: bonusEarned,
        completedAt: DateTime.now(),
        timeSpentMinutes: progress.completedAt != null
            ? progress.completedAt!.difference(progress.startedAt).inMinutes
            : null,
      );

      final newProgress = Map<String, ChallengeProgress>.from(collection.challenges.progress);
      newProgress[challengeId] = ChallengeProgress(
        challengeId: challengeId,
        userId: userId,
        currentProgress: progress.currentProgress,
        isCompleted: progress.isCompleted,
        completedAt: progress.completedAt,
        startedAt: progress.startedAt,
        firstAttemptAt: progress.firstAttemptAt,
        attemptCount: progress.attemptCount,
        claimedReward: true,
      );

      final newCompletionHistory = [
        completion,
        ...collection.challenges.completionHistory,
      ].take(200).toList();

      final updatedChallenges = UserChallenges(
        userId: collection.challenges.userId,
        availableChallenges: collection.challenges.availableChallenges,
        progress: newProgress,
        completionHistory: newCompletionHistory,
        lastUpdatedAt: DateTime.now(),
        generatedAt: DateTime.now(),
      );

      // Update stats
      final stats = _updateStatsForCompletion(
        collection.stats,
        challenge,
        bonusEarned,
        totalReward,
      );

      final updatedCollection = ChallengeCollection(
        userId: collection.userId,
        challenges: updatedChallenges,
        stats: stats,
        generatedAt: DateTime.now(),
      );

      final newRecentlyCompleted = [...state.recentlyCompletedIds, challengeId];

      state = state.copyWith(
        collection: updatedCollection,
        recentlyCompletedIds: newRecentlyCompleted,
      );

      await _persistChallenges(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Abandon a challenge
  Future<bool> abandonChallenge(String userId, String challengeId) async {
    try {
      final collection = state.collection;
      if (collection == null) return false;

      final newProgress = Map<String, ChallengeProgress>.from(collection.challenges.progress);
      newProgress.remove(challengeId);

      final updatedChallenges = UserChallenges(
        userId: collection.challenges.userId,
        availableChallenges: collection.challenges.availableChallenges,
        progress: newProgress,
        completionHistory: collection.challenges.completionHistory,
        lastUpdatedAt: DateTime.now(),
        generatedAt: DateTime.now(),
      );

      final updatedCollection = ChallengeCollection(
        userId: collection.userId,
        challenges: updatedChallenges,
        stats: collection.stats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(collection: updatedCollection);
      await _persistChallenges(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get challenge by ID
  Challenge? getChallenge(String challengeId) =>
      state.collection?.challenges.availableChallenges
          .firstWhere((c) => c.challengeId == challengeId, orElse: () => null as dynamic);

  /// Get progress for challenge
  ChallengeProgress? getProgress(String challengeId) =>
      state.collection?.challenges.progress[challengeId];

  /// Get available challenge count
  int getAvailableChallengeCount() =>
      state.collection?.challenges.getAvailableChallenges().length ?? 0;

  /// Get completed challenge count
  int getCompletedChallengeCount() =>
      state.collection?.challenges.getCompletedChallenges().length ?? 0;

  /// Get total rewards earned
  int getTotalRewardsEarned() =>
      state.collection?.stats.totalRewardsEarned ?? 0;

  /// Clear recently completed
  void clearRecentlyCompleted() {
    state = state.copyWith(recentlyCompletedIds: []);
  }

  /// Create default challenges
  List<Challenge> _createDefaultChallenges() {
    final now = DateTime.now();
    return [
      Challenge(
        challengeId: 'challenge-daily-1',
        title: '読解チャレンジ',
        description: '5つの記事を読む',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 5,
        timeLimit: 60,
        reward: ChallengeReward(
          currency: RewardCurrency.xp,
          amount: 100,
          bonusAmount: 25,
        ),
        createdAt: now,
        startsAt: now,
        endsAt: now.add(const Duration(days: 1)),
        difficulty_multiplier: 1,
      ),
      Challenge(
        challengeId: 'challenge-daily-2',
        title: '単語マスター',
        description: '10個の新しい単語を学ぶ',
        category: ChallengeCategory.vocabulary,
        difficulty: ChallengeDifficulty.easy,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        timeLimit: 45,
        reward: ChallengeReward(
          currency: RewardCurrency.xp,
          amount: 75,
          bonusAmount: 15,
        ),
        createdAt: now,
        startsAt: now,
        endsAt: now.add(const Duration(days: 1)),
        difficulty_multiplier: 1,
      ),
      Challenge(
        challengeId: 'challenge-weekly-1',
        title: 'ライティングマスター',
        description: '3つの記事を書く',
        category: ChallengeCategory.writing,
        difficulty: ChallengeDifficulty.hard,
        frequency: ChallengeFrequency.weekly,
        targetCount: 3,
        timeLimit: 180,
        reward: ChallengeReward(
          currency: RewardCurrency.xp,
          amount: 300,
          bonusAmount: 100,
        ),
        createdAt: now,
        startsAt: now,
        endsAt: now.add(const Duration(days: 7)),
        difficulty_multiplier: 2,
      ),
      Challenge(
        challengeId: 'challenge-math-1',
        title: '数学問題集',
        description: '20個の数学問題を解く',
        category: ChallengeCategory.mathematics,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 20,
        reward: ChallengeReward(
          currency: RewardCurrency.coins,
          amount: 50,
          bonusAmount: 10,
        ),
        createdAt: now,
        startsAt: now,
        endsAt: now.add(const Duration(days: 1)),
        difficulty_multiplier: 1,
      ),
    ];
  }

  /// Create default stats
  ChallengeStats _createDefaultStats(String userId) {
    final now = DateTime.now();
    return ChallengeStats(
      userId: userId,
      totalChallengesAvailable: 0,
      totalChallengesCompleted: 0,
      totalRewardsEarned: 0,
      totalBonusesEarned: 0,
      currentStreak: 0,
      longestStreak: 0,
      completionsByCategory: {},
      completionsByDifficulty: {},
      lastCompletionAt: now,
      lastUpdatedAt: now,
    );
  }

  /// Update stats for challenge completion
  ChallengeStats _updateStatsForCompletion(
    ChallengeStats oldStats,
    Challenge challenge,
    bool bonusEarned,
    int rewardAmount,
  ) {
    final categoryCount = Map<ChallengeCategory, int>.from(oldStats.completionsByCategory);
    final difficultyCount = Map<ChallengeDifficulty, int>.from(oldStats.completionsByDifficulty);

    categoryCount[challenge.category] = (categoryCount[challenge.category] ?? 0) + 1;
    difficultyCount[challenge.difficulty] = (difficultyCount[challenge.difficulty] ?? 0) + 1;

    return ChallengeStats(
      userId: oldStats.userId,
      totalChallengesAvailable: oldStats.totalChallengesAvailable,
      totalChallengesCompleted: oldStats.totalChallengesCompleted + 1,
      totalRewardsEarned: oldStats.totalRewardsEarned + rewardAmount,
      totalBonusesEarned: oldStats.totalBonusesEarned + (bonusEarned ? 1 : 0),
      currentStreak: oldStats.currentStreak + 1,
      longestStreak: oldStats.longestStreak > oldStats.currentStreak
          ? oldStats.longestStreak
          : oldStats.currentStreak + 1,
      completionsByCategory: categoryCount,
      completionsByDifficulty: difficultyCount,
      lastCompletionAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
  }

  Future<void> _persistChallenges(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection = state.collection;
      if (collection != null) {
        await prefs.setString(
          'challenges_$userId',
          collection.challenges.toJson().toString(),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }
}

final dailyChallengeProvider = StateNotifierProvider.autoDispose<DailyChallengeNotifier, DailyChallengeState>(
  (ref) => DailyChallengeNotifier(),
);

final challengeCollectionProvider = Provider.autoDispose<ChallengeCollection?>(
  (ref) => ref.watch(dailyChallengeProvider).collection,
);

final availableChallengesProvider = Provider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.challenges.getAvailableChallenges() ?? [],
);

final inProgressChallengesProvider = Provider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.challenges.getInProgressChallenges() ?? [],
);

final completedChallengesProvider = Provider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.challenges.getCompletedChallenges() ?? [],
);

final dailyChallengesProvider = Provider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.challenges.getDailyChallenges() ?? [],
);

final weeklyChallengesProvider = Provider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.challenges.getWeeklyChallenges() ?? [],
);

final expiringChallengesProvider = Provider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.challenges.getExpiringChallenges() ?? [],
);

final challengesByDifficultyProvider =
    Provider.autoDispose.family<List<Challenge>, ChallengeDifficulty>(
  (ref, difficulty) =>
      ref.watch(dailyChallengeProvider).collection?.challenges.getChallengesByDifficulty(difficulty) ?? [],
);

final challengesByCategoryProvider = Provider.autoDispose.family<List<Challenge>, ChallengeCategory>(
  (ref, category) =>
      ref.watch(dailyChallengeProvider).collection?.challenges.getChallengesByCategory(category) ?? [],
);

final challengeStatsProvider = Provider.autoDispose<ChallengeStats?>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.stats,
);

final challengeProgressProvider = Provider.autoDispose.family<ChallengeProgress?, String>(
  (ref, challengeId) =>
      ref.watch(dailyChallengeProvider).collection?.challenges.progress[challengeId],
);

final completionHistoryProvider = Provider.autoDispose<List<ChallengeCompletion>>(
  (ref) => ref.watch(dailyChallengeProvider).collection?.challenges.completionHistory ?? [],
);
