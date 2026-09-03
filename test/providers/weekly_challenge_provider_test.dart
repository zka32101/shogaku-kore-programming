import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/weekly_challenge.dart';
import 'package:shogaku_kore_programming/providers/weekly_challenge_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('WeeklyChallengeNotifier', () {
    test('initializes with empty state', () {
      final notifier = WeeklyChallengeNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeChallenges creates default challenges', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final state = container.read(weeklyChallengeProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.challenges.length, 6);
      expect(state.isLoading, false);
    });

    test('initializeChallenges creates user progress for all challenges', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final state = container.read(weeklyChallengeProvider);
      expect(state.collection!.userProgress.length, 6);
    });

    test('initializeChallenges sets default stats', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('new_user');

      final state = container.read(weeklyChallengeProvider);
      expect(state.collection!.stats.userId, 'new_user');
      expect(state.collection!.stats.completedChallenges, 0);
      expect(state.collection!.stats.totalXpEarned, 0);
    });

    test('updateChallengeProgress completes challenge when target reached',
        () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final completed = await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      expect(completed, true);

      final state = container.read(weeklyChallengeProvider);
      expect(state.collection!.stats.completedChallenges, 1);
    });

    test('updateChallengeProgress adds to recently completed', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      final state = container.read(weeklyChallengeProvider);
      expect(state.recentlyCompleted.isNotEmpty, true);
      expect(state.recentlyCompleted.contains('wch_learn_100'), true);
    });

    test('updateChallengeProgress calculates reward multiplier', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      final state = container.read(weeklyChallengeProvider);
      expect(state.collection!.stats.totalXpEarned, greaterThan(0));
      expect(state.collection!.stats.totalCoinsEarned, greaterThan(0));
    });

    test('updateChallengeProgress prevents duplicate completions', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      var state = container.read(weeklyChallengeProvider);
      final countAfterFirst = state.collection!.stats.completedChallenges;

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        150,
      );

      state = container.read(weeklyChallengeProvider);
      expect(state.collection!.stats.completedChallenges, countAfterFirst);
    });

    test('calculateRewardTier returns correct tier', () async {
      final notifier = WeeklyChallengeNotifier();

      expect(
// notifier._calculateRewardTier(100, 100),
        ChallengeRewardTier.platinum,
      );
      expect(
// notifier._calculateRewardTier(95, 100),
        ChallengeRewardTier.gold,
      );
      expect(
// notifier._calculateRewardTier(75, 100),
        ChallengeRewardTier.silver,
      );
      expect(
// notifier._calculateRewardTier(50, 100),
        ChallengeRewardTier.bronze,
      );
    });

    test('calculateReward applies difficulty and tier multipliers', () async {
      final notifier = WeeklyChallengeNotifier();
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      final challenge = WeeklyChallenge(
        challengeId: 'test',
        title: 'Test',
        description: '',
        category: ChallengeCategory.writing,
        difficulty: ChallengeDifficulty.hard,  // 2.0x multiplier
        iconId: 'i',
        targetValue: 100,
        metricKey: 'm',
        baseBonusXp: 100,
        baseBonusCoins: 50,
        weekStartDate: now,
        weekEndDate: weekEnd,
      );

// final reward = notifier._calculateReward(
        challenge,
        ChallengeRewardTier.platinum,  // 2.0x bonus
      );

      // 100 * 2.0 (difficulty) * 2.0 (platinum) = 400
      expect(reward['xp'], 400);
      expect(reward['coins'], 200);
    });

    test('getCompletedChallenges returns only completed', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      final completed = notifier.getCompletedChallenges();
      expect(completed.length, 1);
    });

    test('getActiveChallenges returns uncompleted', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final active = notifier.getActiveChallenges();
      expect(active.length, 6);

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      final activeAfter = notifier.getActiveChallenges();
      expect(activeAfter.length, 5);
    });

    test('getBonusChallenges returns bonus only', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final bonus = notifier.getBonusChallenges();
      expect(bonus.isNotEmpty, true);
      expect(bonus.every((c) => c.isBonusChallenge), true);
    });

    test('getByCategory filters correctly', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final learning = notifier.getByCategory(ChallengeCategory.learning);
      expect(learning.isNotEmpty, true);
      expect(learning.every((c) => c.category == ChallengeCategory.learning), true);
    });

    test('getByDifficulty filters correctly', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final normal = notifier.getByDifficulty(ChallengeDifficulty.normal);
      expect(normal.isNotEmpty, true);
    });

    test('clearRecentlyCompleted empties list', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      var state = container.read(weeklyChallengeProvider);
      expect(state.recentlyCompleted.isNotEmpty, true);

      notifier.clearRecentlyCompleted();

      state = container.read(weeklyChallengeProvider);
      expect(state.recentlyCompleted.isEmpty, true);
    });

    test('getters return correct values', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      expect(notifier.getCompletedCount(), 0);
      expect(notifier.getTotalChallenges(), 6);
      expect(notifier.getCompletionPercentage(), 0);

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      expect(notifier.getCompletedCount(), 1);
      expect(notifier.getCompletionPercentage(), greaterThan(0));
      expect(notifier.getWeeklyXpEarned(), greaterThan(0));
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('persist_test');

      await notifier.updateChallengeProgress(
        'persist_test',
        'learning_minutes',
        100,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('challenge_progress_persist_test'), true);
      expect(prefs.containsKey('challenge_stats_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('completedChallengesProvider returns correct challenges', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var completed = container.read(completedChallengesProvider);
      expect(completed.isEmpty, true);

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      completed = container.read(completedChallengesProvider);
      expect(completed.length, 1);
    });

    test('activeChallengesProvider provides active only', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var active = container.read(activeChallengesProvider);
      expect(active.length, 6);
    });

    test('completionPercentageProvider calculates correctly', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      var percentage = container.read(completionPercentageProvider);
      expect(percentage, 0);

      await notifier.updateChallengeProgress(
        'test_user',
        'learning_minutes',
        100,
      );

      percentage = container.read(completionPercentageProvider);
      expect(percentage, greaterThan(0));
    });

    test('weeklyChallengeStatsProvider provides stats', () async {
      final notifier = container.read(weeklyChallengeProvider.notifier);
      await notifier.initializeChallenges('test_user');

      final stats = container.read(weeklyChallengeStatsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });
  });
}
