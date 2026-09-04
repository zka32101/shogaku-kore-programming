import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/daily_challenge.dart';
import 'package:shogaku_kore_programming/providers/daily_challenge_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('DailyChallengeNotifier', () {
    test('initializes with empty state', () {
      final notifier = DailyChallengeNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeChallenges creates default challenges', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final state = container.read(dailyChallengeProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
      expect(state.collection!.challenges.availableChallenges.isNotEmpty, true);
    });

    test('initializeChallenges creates empty progress map', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress, isEmpty);
    });

    test('initializeChallenges creates default stats', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final state = container.read(dailyChallengeProvider);
      expect(state.collection!.stats.userId, 'test_user');
      expect(state.collection!.stats.totalChallengesCompleted, 0);
    });

    test('startChallenge creates progress entry', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      final success = await notifier.startChallenge('test_user', challengeId);
      expect(success, true);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress.containsKey(challengeId), true);
    });

    test('startChallenge increments attempt count', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.startChallenge('test_user', challengeId);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress[challengeId]!.attemptCount, 2);
    });

    test('updateProgress increments progress', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, 5);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress[challengeId]!.currentProgress, 5);
    });

    test('updateProgress marks complete when target reached', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress[challengeId]!.isCompleted, true);
    });

    test('completeChallenge creates completion record', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);

      final success = await notifier.completeChallenge('test_user', challengeId);
      expect(success, true);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.completionHistory.isNotEmpty, true);
    });

    test('completeChallenge marks reward as claimed', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);
      await notifier.completeChallenge('test_user', challengeId);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress[challengeId]!.claimedReward, true);
    });

    test('completeChallenge updates stats', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;
      final initialRewards = state.collection!.stats.totalRewardsEarned;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);
      await notifier.completeChallenge('test_user', challengeId);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.stats.totalRewardsEarned, greaterThan(initialRewards));
      expect(state.collection!.stats.totalChallengesCompleted, 1);
    });

    test('abandonChallenge removes progress', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress.containsKey(challengeId), true);

      await notifier.abandonChallenge('test_user', challengeId);

      state = container.read(dailyChallengeProvider);
      expect(state.collection!.challenges.progress.containsKey(challengeId), false);
    });

    test('getChallenge returns correct challenge', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      final challenge = notifier.getChallenge(challengeId);
      expect(challenge, isNotNull);
      expect(challenge!.challengeId, challengeId);
    });

    test('getProgress returns correct progress', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      await notifier.startChallenge('test_user', challengeId);

      final progress = notifier.getProgress(challengeId);
      expect(progress, isNotNull);
      expect(progress!.challengeId, challengeId);
    });

    test('getAvailableChallengeCount returns correct count', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final count = notifier.getAvailableChallengeCount();
      expect(count, greaterThan(0));
    });

    test('getCompletedChallengeCount returns correct count', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      expect(notifier.getCompletedChallengeCount(), 0);

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);
      await notifier.completeChallenge('test_user', challengeId);

      expect(notifier.getCompletedChallengeCount(), 1);
    });

    test('getTotalRewardsEarned returns correct sum', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      expect(notifier.getTotalRewardsEarned(), 0);

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);
      await notifier.completeChallenge('test_user', challengeId);

      expect(notifier.getTotalRewardsEarned(), greaterThan(0));
    });

    test('clearRecentlyCompleted empties list', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);
      await notifier.completeChallenge('test_user', challengeId);

      state = container.read(dailyChallengeProvider);
      expect(state.recentlyCompletedIds.isNotEmpty, true);

      notifier.clearRecentlyCompleted();

      state = container.read(dailyChallengeProvider);
      expect(state.recentlyCompletedIds.isEmpty, true);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('persist_test');

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('persist_test', challengeId);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('challenges_persist_test'), true);
    });

    test('supports different difficulty levels', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      expect(
        state.collection!.challenges.availableChallenges
            .map((c) => c.difficulty)
            .toSet()
            .length,
        greaterThan(0),
      );
    });

    test('supports different categories', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      expect(
        state.collection!.challenges.availableChallenges
            .map((c) => c.category)
            .toSet()
            .length,
        greaterThan(0),
      );
    });

    test('supports different frequencies', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      expect(
        state.collection!.challenges.availableChallenges
            .map((c) => c.frequency)
            .toSet()
            .length,
        greaterThan(0),
      );
    });
  });

  group('Riverpod Providers', () {
    test('challengeCollectionProvider provides collection', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final collection = container.read(challengeCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('availableChallengesProvider returns available challenges', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final available = container.read(availableChallengesProvider);
      expect(available.isNotEmpty, true);
    });

    test('dailyChallengesProvider filters daily only', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final daily = container.read(dailyChallengesProvider);
      expect(daily.isNotEmpty, true);
      expect(daily.every((c) => c.frequency == ChallengeFrequency.daily), true);
    });

    test('weeklyChallengesProvider filters weekly only', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final weekly = container.read(weeklyChallengesProvider);
      expect(weekly.every((c) => c.frequency == ChallengeFrequency.weekly), true);
    });

    test('challengesByDifficultyProvider filters by difficulty', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final easy = container.read(challengesByDifficultyProvider(ChallengeDifficulty.easy));
      expect(easy.every((c) => c.difficulty == ChallengeDifficulty.easy), true);
    });

    test('challengesByCategoryProvider filters by category', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final reading = container.read(challengesByCategoryProvider(ChallengeCategory.reading));
      expect(reading.every((c) => c.category == ChallengeCategory.reading), true);
    });

    test('challengeStatsProvider provides stats', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final stats = container.read(challengeStatsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('inProgressChallengesProvider filters in-progress', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var inProgress = container.read(inProgressChallengesProvider);
      expect(inProgress.isEmpty, true);

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      await notifier.startChallenge('test_user', challengeId);

      inProgress = container.read(inProgressChallengesProvider);
      expect(inProgress.length, 1);
    });

    test('completedChallengesProvider filters completed', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var completed = container.read(completedChallengesProvider);
      expect(completed.isEmpty, true);

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);
      await notifier.completeChallenge('test_user', challengeId);

      completed = container.read(completedChallengesProvider);
      expect(completed.length, 1);
    });

    test('challengeProgressProvider returns progress', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var state = container.read(dailyChallengeProvider);
      final challengeId = state.collection!.challenges.availableChallenges.first.challengeId;

      await notifier.startChallenge('test_user', challengeId);

      final progress = container.read(challengeProgressProvider(challengeId));
      expect(progress, isNotNull);
      expect(progress!.challengeId, challengeId);
    });

    test('completionHistoryProvider returns history', () async {
      final notifier = container.read(dailyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var history = container.read(completionHistoryProvider);
      expect(history.isEmpty, true);

      var state = container.read(dailyChallengeProvider);
      final challenge = state.collection!.challenges.availableChallenges.first;
      final challengeId = challenge.challengeId;

      await notifier.startChallenge('test_user', challengeId);
      await notifier.updateProgress('test_user', challengeId, challenge.targetCount);
      await notifier.completeChallenge('test_user', challengeId);

      history = container.read(completionHistoryProvider);
      expect(history.isNotEmpty, true);
    });
  });
}
