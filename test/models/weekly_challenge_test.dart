import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/weekly_challenge.dart';

void main() {
  group('WeeklyChallenge', () {
    test('creates instance with all required fields', () {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      final challenge = WeeklyChallenge(
        challengeId: 'wch_learn_100',
        title: '100分学習チャレンジ',
        description: '100分以上学習する',
        category: ChallengeCategory.learning,
        difficulty: ChallengeDifficulty.normal,
        iconId: 'icon_learn',
        targetValue: 100,
        metricKey: 'learning_minutes',
        baseBonusXp: 150,
        baseBonusCoins: 75,
        weekStartDate: now,
        weekEndDate: weekEnd,
      );

      expect(challenge.challengeId, 'wch_learn_100');
      expect(challenge.title, '100分学習チャレンジ');
      expect(challenge.category, ChallengeCategory.learning);
      expect(challenge.difficulty, ChallengeDifficulty.normal);
      expect(challenge.targetValue, 100);
    });

    test('calculates difficulty multiplier correctly', () {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      final easy = WeeklyChallenge(
        challengeId: 'c1',
        title: 'Easy',
        description: '',
        category: ChallengeCategory.quiz,
        difficulty: ChallengeDifficulty.easy,
        iconId: 'i1',
        targetValue: 10,
        metricKey: 'm',
        baseBonusXp: 100,
        baseBonusCoins: 50,
        weekStartDate: now,
        weekEndDate: weekEnd,
      );

      expect(easy.difficultyMultiplier, 1.0);

      final hard = WeeklyChallenge(
        challengeId: 'c2',
        title: 'Hard',
        description: '',
        category: ChallengeCategory.writing,
        difficulty: ChallengeDifficulty.hard,
        iconId: 'i2',
        targetValue: 10,
        metricKey: 'm',
        baseBonusXp: 100,
        baseBonusCoins: 50,
        weekStartDate: now,
        weekEndDate: weekEnd,
      );

      expect(hard.difficultyMultiplier, 2.0);
    });

    test('isActive checks time correctly', () {
      final now = DateTime.now();
      final pastStart = now.subtract(const Duration(days: 1));
      final futureEnd = now.add(const Duration(days: 7));

      final active = WeeklyChallenge(
        challengeId: 'active',
        title: 'Active',
        description: '',
        category: ChallengeCategory.learning,
        difficulty: ChallengeDifficulty.normal,
        iconId: 'i',
        targetValue: 100,
        metricKey: 'm',
        baseBonusXp: 100,
        baseBonusCoins: 50,
        weekStartDate: pastStart,
        weekEndDate: futureEnd,
      );

      expect(active.isActive, true);
    });

    test('daysRemaining calculation', () {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 3));

      final challenge = WeeklyChallenge(
        challengeId: 'c',
        title: 'Test',
        description: '',
        category: ChallengeCategory.learning,
        difficulty: ChallengeDifficulty.normal,
        iconId: 'i',
        targetValue: 100,
        metricKey: 'm',
        baseBonusXp: 100,
        baseBonusCoins: 50,
        weekStartDate: now,
        weekEndDate: weekEnd,
      );

      expect(challenge.daysRemaining, greaterThanOrEqualTo(3));
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      final original = WeeklyChallenge(
        challengeId: 'wch_test',
        title: 'Test Challenge',
        description: 'Test Description',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.hard,
        iconId: 'icon_test',
        targetValue: 50,
        metricKey: 'test_metric',
        baseBonusXp: 200,
        baseBonusCoins: 100,
        weekStartDate: now,
        weekEndDate: weekEnd,
        isStreakBooster: true,
        isBonusChallenge: false,
      );

      final json = original.toJson();
      final restored = WeeklyChallenge.fromJson(json);

      expect(restored.challengeId, original.challengeId);
      expect(restored.title, original.title);
      expect(restored.difficulty, original.difficulty);
    });
  });

  group('ChallengeProgress', () {
    test('calculates progress percentage', () {
      final progress = ChallengeProgress(
        challengeId: 'ch_1',
        userId: 'user1',
        currentValue: 50,
        targetValue: 100,
        startedAt: DateTime.now(),
        isCompleted: false,
      );

      expect(progress.progressPercentage, 50.0);
    });

    test('getTierForProgress returns correct tier', () {
      final platinum = ChallengeProgress(
        challengeId: 'ch_1',
        userId: 'user1',
        currentValue: 100,
        targetValue: 100,
        startedAt: DateTime.now(),
        isCompleted: true,
      );

      expect(platinum.getTierForProgress(), ChallengeRewardTier.platinum);

      final gold = ChallengeProgress(
        challengeId: 'ch_2',
        userId: 'user1',
        currentValue: 95,
        targetValue: 100,
        startedAt: DateTime.now(),
        isCompleted: true,
      );

      expect(gold.getTierForProgress(), ChallengeRewardTier.gold);
    });

    test('JSON round-trip preserves data', () {
      final now = DateTime.now();
      final original = ChallengeProgress(
        challengeId: 'ch_test',
        userId: 'user_test',
        currentValue: 75,
        targetValue: 100,
        attemptCount: 3,
        startedAt: now,
        isCompleted: false,
      );

      final json = original.toJson();
      final restored = ChallengeProgress.fromJson(json);

      expect(restored.progressPercentage, original.progressPercentage);
      expect(restored.attemptCount, original.attemptCount);
    });
  });

  group('ChallengeReward', () {
    test('creates instance with all data', () {
      final now = DateTime.now();
      final reward = ChallengeReward(
        rewardId: 'rew_1',
        userId: 'user1',
        challengeId: 'ch_1',
        xpEarned: 300,
        coinsEarned: 150,
        claimedAt: now,
        tier: ChallengeRewardTier.platinum,
        difficultyMultiplier: 2.0,
      );

      expect(reward.rewardId, 'rew_1');
      expect(reward.xpEarned, 300);
      expect(reward.tier, ChallengeRewardTier.platinum);
    });

    test('JSON serialization works', () {
      final now = DateTime.now();
      final original = ChallengeReward(
        rewardId: 'rew_test',
        userId: 'user_test',
        challengeId: 'ch_test',
        xpEarned: 250,
        coinsEarned: 125,
        claimedAt: now,
        tier: ChallengeRewardTier.gold,
        difficultyMultiplier: 1.5,
      );

      final json = original.toJson();
      final restored = ChallengeReward.fromJson(json);

      expect(restored.xpEarned, original.xpEarned);
      expect(restored.tier, original.tier);
    });
  });

  group('WeeklyChallengeStats', () {
    test('creates instance with stats', () {
      final now = DateTime.now();
      final stats = WeeklyChallengeStats(
        userId: 'user1',
        totalChallengesThisWeek: 6,
        completedChallenges: 3,
        totalXpEarned: 500,
        totalCoinsEarned: 250,
        rewardHistory: [],
        weeklyStreak: 2,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.completedChallenges, 3);
      expect(stats.weeklyStreak, 2);
    });

    test('calculates completion percentage', () {
      final now = DateTime.now();
      final stats = WeeklyChallengeStats(
        userId: 'user1',
        totalChallengesThisWeek: 10,
        completedChallenges: 5,
        totalXpEarned: 0,
        totalCoinsEarned: 0,
        rewardHistory: [],
        weeklyStreak: 0,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
        lastUpdatedAt: now,
      );

      expect(stats.completionPercentage, 50.0);
    });

    test('allCompleted returns correct value', () {
      final now = DateTime.now();
      final complete = WeeklyChallengeStats(
        userId: 'user1',
        totalChallengesThisWeek: 5,
        completedChallenges: 5,
        totalXpEarned: 0,
        totalCoinsEarned: 0,
        rewardHistory: [],
        weeklyStreak: 0,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
        lastUpdatedAt: now,
      );

      expect(complete.allCompleted, true);

      final incomplete = WeeklyChallengeStats(
        userId: 'user2',
        totalChallengesThisWeek: 5,
        completedChallenges: 3,
        totalXpEarned: 0,
        totalCoinsEarned: 0,
        rewardHistory: [],
        weeklyStreak: 0,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
        lastUpdatedAt: now,
      );

      expect(incomplete.allCompleted, false);
    });

    test('JSON round-trip preserves data', () {
      final now = DateTime.now();
      final original = WeeklyChallengeStats(
        userId: 'user_test',
        totalChallengesThisWeek: 6,
        completedChallenges: 4,
        totalXpEarned: 600,
        totalCoinsEarned: 300,
        rewardHistory: [],
        weeklyStreak: 3,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
        lastUpdatedAt: now,
      );

      final json = original.toJson();
      final restored = WeeklyChallengeStats.fromJson(json);

      expect(restored.completedChallenges, original.completedChallenges);
      expect(restored.weeklyStreak, original.weeklyStreak);
    });
  });

  group('WeeklyChallengeCollection', () {
    test('creates collection with challenges', () {
      final now = DateTime.now();
      final challenges = [
        WeeklyChallenge(
          challengeId: 'ch_1',
          title: 'Challenge 1',
          description: '',
          category: ChallengeCategory.learning,
          difficulty: ChallengeDifficulty.normal,
          iconId: 'i1',
          targetValue: 100,
          metricKey: 'm1',
          baseBonusXp: 100,
          baseBonusCoins: 50,
          weekStartDate: now,
          weekEndDate: now.add(const Duration(days: 7)),
        ),
      ];

      final stats = WeeklyChallengeStats(
        userId: 'user1',
        totalChallengesThisWeek: 1,
        completedChallenges: 0,
        totalXpEarned: 0,
        totalCoinsEarned: 0,
        rewardHistory: [],
        weeklyStreak: 0,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
        lastUpdatedAt: now,
      );

      final collection = WeeklyChallengeCollection(
        challenges: challenges,
        stats: stats,
        userProgress: {},
        generatedAt: now,
      );

      expect(collection.challenges.length, 1);
      expect(collection.stats.userId, 'user1');
    });

    test('getByCategory filters correctly', () {
      final now = DateTime.now();
      final learning = WeeklyChallenge(
        challengeId: 'ch_learn',
        title: 'Learning',
        description: '',
        category: ChallengeCategory.learning,
        difficulty: ChallengeDifficulty.normal,
        iconId: 'i1',
        targetValue: 100,
        metricKey: 'm',
        baseBonusXp: 100,
        baseBonusCoins: 50,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
      );

      final quiz = WeeklyChallenge(
        challengeId: 'ch_quiz',
        title: 'Quiz',
        description: '',
        category: ChallengeCategory.quiz,
        difficulty: ChallengeDifficulty.easy,
        iconId: 'i2',
        targetValue: 10,
        metricKey: 'm',
        baseBonusXp: 50,
        baseBonusCoins: 25,
        weekStartDate: now,
        weekEndDate: now.add(const Duration(days: 7)),
      );

      final collection = WeeklyChallengeCollection(
        challenges: [learning, quiz],
        stats: WeeklyChallengeStats(
          userId: 'user1',
          totalChallengesThisWeek: 2,
          completedChallenges: 0,
          totalXpEarned: 0,
          totalCoinsEarned: 0,
          rewardHistory: [],
          weeklyStreak: 0,
          weekStartDate: now,
          weekEndDate: now.add(const Duration(days: 7)),
          lastUpdatedAt: now,
        ),
        userProgress: {},
        generatedAt: now,
      );

      final learning_list = collection.getByCategory(ChallengeCategory.learning);
      expect(learning_list.length, 1);
      expect(learning_list.first.challengeId, 'ch_learn');
    });

    test('JSON round-trip preserves structure', () {
      final now = DateTime.now();
      final original = WeeklyChallengeCollection(
        challenges: [],
        stats: WeeklyChallengeStats(
          userId: 'user_test',
          totalChallengesThisWeek: 6,
          completedChallenges: 2,
          totalXpEarned: 300,
          totalCoinsEarned: 150,
          rewardHistory: [],
          weeklyStreak: 1,
          weekStartDate: now,
          weekEndDate: now.add(const Duration(days: 7)),
          lastUpdatedAt: now,
        ),
        userProgress: {},
        generatedAt: now,
      );

      final json = original.toJson();
      final restored = WeeklyChallengeCollection.fromJson(json);

      expect(restored.stats.userId, original.stats.userId);
      expect(restored.stats.completedChallenges, original.stats.completedChallenges);
    });
  });
}
