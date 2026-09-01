import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/learning_analytics.dart';

class ChallengeState {
  final ChallengeData? challengeData;
  final Map<String, UserChallengeProgress> userProgress;
  final Map<ChallengeType, ChallengeStreak> streaks;
  final List<ChallengeCompletion> completionHistory;
  final bool isLoading;
  final String? error;

  ChallengeState({
    this.challengeData,
    this.userProgress = const {},
    this.streaks = const {},
    this.completionHistory = const [],
    this.isLoading = false,
    this.error,
  });

  ChallengeState copyWith({
    ChallengeData? challengeData,
    Map<String, UserChallengeProgress>? userProgress,
    Map<ChallengeType, ChallengeStreak>? streaks,
    List<ChallengeCompletion>? completionHistory,
    bool? isLoading,
    String? error,
  }) =>
      ChallengeState(
        challengeData: challengeData ?? this.challengeData,
        userProgress: userProgress ?? this.userProgress,
        streaks: streaks ?? this.streaks,
        completionHistory: completionHistory ?? this.completionHistory,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class ChallengeNotifier extends StateNotifier<ChallengeState> {
  ChallengeNotifier() : super(ChallengeState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  Future<ChallengeData> generateDailyChallenges({int count = 3}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final challenges = <Challenge>[];
      final now = DateTime.now();
      final tomorrow = now.add(Duration(days: 1));

      for (int i = 0; i < count; i++) {
        challenges.add(Challenge(
          challengeId: _generateId('challenge'),
          title: 'Daily Challenge ${i + 1}',
          description: 'Complete ${10 + (i * 5)} quiz questions',
          type: ChallengeType.daily,
          difficulty: [
            ChallengeDifficulty.easy,
            ChallengeDifficulty.medium,
            ChallengeDifficulty.hard,
          ][i % 3],
          condition: ChallengeCondition(
            conditionId: _generateId('condition'),
            description: 'Quiz completions',
            requiredAmount: 10 + (i * 5),
          ),
          reward: ChallengeReward(
            xpAmount: 50 + (i * 25),
            coinAmount: 10 + (i * 5),
            categoryBonusXp: {
              'variables': 25,
              'loops': 20,
            },
          ),
          startedAt: now,
          expiresAt: tomorrow,
          isActive: true,
        ));
      }

      final data = ChallengeData(
        availableChallenges: challenges,
        userProgress: [],
        streaks: {},
        recentCompletions: [],
        generatedAt: now,
      );

      state = state.copyWith(challengeData: data, isLoading: false);
      return data;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> startChallenge(String userId, String challengeId) async {
    try {
      final progress = UserChallengeProgress(
        userId: userId,
        challengeId: challengeId,
        status: ChallengeStatus.inProgress,
        currentProgress: 0,
        startedAt: DateTime.now(),
        attemptCount: 1,
      );

      state = state.copyWith(
        userProgress: {
          ...state.userProgress,
          challengeId: progress,
        },
      );

      await _persistProgress();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<ChallengeCompletion> completeChallenge(
    String userId,
    String challengeId,
    int earnedXp,
    int earnedCoins,
  ) async {
    try {
      final completion = ChallengeCompletion(
        completionId: _generateId('completion'),
        userId: userId,
        challengeId: challengeId,
        earnedXp: earnedXp,
        earnedCoins: earnedCoins,
        completedAt: DateTime.now(),
        isBonusUnlocked: true,
      );

      // Update progress
      if (state.userProgress.containsKey(challengeId)) {
        final current = state.userProgress[challengeId]!;
        final updated = UserChallengeProgress(
          userId: current.userId,
          challengeId: current.challengeId,
          status: ChallengeStatus.completed,
          currentProgress: current.currentProgress,
          startedAt: current.startedAt,
          completedAt: DateTime.now(),
          attemptCount: current.attemptCount,
        );

        state = state.copyWith(
          userProgress: {
            ...state.userProgress,
            challengeId: updated,
          },
          completionHistory: [completion, ...state.completionHistory]
              .take(100)
              .toList(),
        );
      }

      // Update streak
      await _updateStreak(userId, ChallengeType.daily);
      await _persistProgress();

      return completion;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> _updateStreak(String userId, ChallengeType type) async {
    final existing = state.streaks[type];
    final now = DateTime.now();

    final streak = ChallengeStreak(
      userId: userId,
      type: type,
      currentStreak: (existing?.isStreakActive ?? false)
          ? (existing!.currentStreak + 1)
          : 1,
      longestStreak: (existing?.longestStreak ?? 0) +
          ((existing?.isStreakActive ?? false) ? 1 : 0),
      lastCompletedDate: now,
      resetDate: now.add(Duration(days: type == ChallengeType.daily ? 1 : 7)),
    );

    state = state.copyWith(
      streaks: {
        ...state.streaks,
        type: streak,
      },
    );
  }

  Future<void> _persistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'challenge_progress',
        state.userProgress.toString(),
      );
    } catch (e) {
      // Silently fail
    }
  }

  int getStreakCount(ChallengeType type) =>
      state.streaks[type]?.currentStreak ?? 0;

  List<Challenge> getActiveChallenges() =>
      state.challengeData?.availableChallenges
          .where((c) => c.isLive)
          .toList() ??
      [];
}

final challengeProvider =
    StateNotifierProvider.autoDispose<ChallengeNotifier, ChallengeState>(
      (ref) => ChallengeNotifier(),
    );

final activeChallengesProvider = Provider.autoDispose<List<Challenge>>((ref) {
  return ref.watch(challengeProvider).challengeData?.availableChallenges
          .where((c) => c.isLive)
          .toList() ??
      [];
});

final userStreakProvider = Provider.autoDispose.family<int, ChallengeType>(
  (ref, type) {
    final notifier = ref.watch(challengeProvider.notifier);
    return notifier.getStreakCount(type);
  },
);

final dailyChallengesProvider = FutureProvider.autoDispose<ChallengeData?>((ref) async {
  final notifier = ref.read(challengeProvider.notifier);
  return await notifier.generateDailyChallenges();
});
