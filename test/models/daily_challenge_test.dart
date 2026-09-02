import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/daily_challenge.dart';

void main() {
  group('ChallengeReward', () {
    test('creates reward with required fields', () {
      final reward = ChallengeReward(
        currency: RewardCurrency.xp,
        amount: 100,
      );

      expect(reward.currency, RewardCurrency.xp);
      expect(reward.amount, 100);
      expect(reward.bonusAmount, isNull);
    });

    test('getTotalReward returns base amount by default', () {
      final reward = ChallengeReward(
        currency: RewardCurrency.xp,
        amount: 100,
        bonusAmount: 25,
      );

      expect(reward.getTotalReward(), 100);
    });

    test('getTotalReward includes bonus when requested', () {
      final reward = ChallengeReward(
        currency: RewardCurrency.xp,
        amount: 100,
        bonusAmount: 25,
      );

      expect(reward.getTotalReward(includeBonus: true), 125);
    });

    test('toJson serializes reward', () {
      final reward = ChallengeReward(
        currency: RewardCurrency.coins,
        amount: 50,
        bonusAmount: 10,
        additionalRewards: {'badge': 'badge_1'},
      );

      final json = reward.toJson();
      expect(json['currency'], 'coins');
      expect(json['amount'], 50);
      expect(json['bonusAmount'], 10);
    });

    test('fromJson deserializes reward', () {
      final json = {
        'currency': 'xp',
        'amount': 100,
        'bonusAmount': 25,
      };

      final reward = ChallengeReward.fromJson(json);
      expect(reward.currency, RewardCurrency.xp);
      expect(reward.amount, 100);
      expect(reward.bonusAmount, 25);
    });
  });

  group('Challenge', () {
    test('creates challenge with required fields', () {
      final now = DateTime.now();
      final challenge = Challenge(
        challengeId: 'ch1',
        title: 'チャレンジ',
        description: '説明',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
      );

      expect(challenge.challengeId, 'ch1');
      expect(challenge.title, 'チャレンジ');
      expect(challenge.category, ChallengeCategory.reading);
      expect(challenge.totalCompletions, 0);
      expect(challenge.difficulty_multiplier, 1);
    });

    test('isAvailable returns true for active challenges', () {
      final now = DateTime.now();
      final challenge = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now.subtract(const Duration(minutes: 5)),
        endsAt: now.add(const Duration(hours: 1)),
      );

      expect(challenge.isAvailable, true);
    });

    test('isAvailable returns false for not yet started', () {
      final now = DateTime.now();
      final challenge = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now.add(const Duration(hours: 1)),
      );

      expect(challenge.isAvailable, false);
    });

    test('isExpired returns true for expired challenges', () {
      final now = DateTime.now();
      final challenge = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: now.subtract(const Duration(hours: 1)),
      );

      expect(challenge.isExpired, true);
    });

    test('isExpiringSoon returns true for expiring challenges', () {
      final now = DateTime.now();
      final challenge = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
        endsAt: now.add(const Duration(minutes: 30)),
      );

      expect(challenge.isExpiringSoon, true);
    });

    test('difficultyText returns correct Japanese text', () {
      final now = DateTime.now();
      final challengeNormal = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
      );

      expect(challengeNormal.difficultyText, '普通');
    });

    test('getAdjustedReward calculates with multiplier', () {
      final now = DateTime.now();
      final challenge = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
        difficulty_multiplier: 2,
      );

      expect(challenge.getAdjustedReward(), 200);
    });

    test('toJson serializes challenge', () {
      final now = DateTime.now();
      final challenge = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
      );

      final json = challenge.toJson();
      expect(json['challengeId'], 'ch1');
      expect(json['category'], 'reading');
      expect(json['difficulty'], 'normal');
    });

    test('fromJson deserializes challenge', () {
      final now = DateTime.now();
      final json = {
        'challengeId': 'ch1',
        'title': 'Test',
        'description': 'Test',
        'category': 'reading',
        'difficulty': 'normal',
        'frequency': 'daily',
        'targetCount': 10,
        'reward': {
          'currency': 'xp',
          'amount': 100,
        },
        'createdAt': now.toIso8601String(),
        'startsAt': now.toIso8601String(),
      };

      final challenge = Challenge.fromJson(json);
      expect(challenge.challengeId, 'ch1');
      expect(challenge.difficulty, ChallengeDifficulty.normal);
    });
  });

  group('ChallengeProgress', () {
    test('creates progress with required fields', () {
      final now = DateTime.now();
      final progress = ChallengeProgress(
        challengeId: 'ch1',
        userId: 'user1',
        currentProgress: 5,
        startedAt: now,
      );

      expect(progress.challengeId, 'ch1');
      expect(progress.userId, 'user1');
      expect(progress.currentProgress, 5);
      expect(progress.isCompleted, false);
      expect(progress.attemptCount, 0);
    });

    test('getProgressPercentage calculates correctly', () {
      final now = DateTime.now();
      final progress = ChallengeProgress(
        challengeId: 'ch1',
        userId: 'user1',
        currentProgress: 5,
        startedAt: now,
      );

      expect(progress.getProgressPercentage(10), 50);
    });

    test('completedEarly returns true for quick completion', () {
      final now = DateTime.now();
      final progress = ChallengeProgress(
        challengeId: 'ch1',
        userId: 'user1',
        currentProgress: 10,
        isCompleted: true,
        completedAt: now,
        startedAt: now.subtract(const Duration(minutes: 15)),
        firstAttemptAt: now.subtract(const Duration(minutes: 15)),
      );

      expect(progress.completedEarly, true);
    });

    test('toJson serializes progress', () {
      final now = DateTime.now();
      final progress = ChallengeProgress(
        challengeId: 'ch1',
        userId: 'user1',
        currentProgress: 5,
        isCompleted: true,
        completedAt: now,
        startedAt: now,
      );

      final json = progress.toJson();
      expect(json['challengeId'], 'ch1');
      expect(json['currentProgress'], 5);
      expect(json['isCompleted'], true);
    });
  });

  group('ChallengeCompletion', () {
    test('creates completion with required fields', () {
      final now = DateTime.now();
      final completion = ChallengeCompletion(
        completionId: 'comp1',
        challengeId: 'ch1',
        userId: 'user1',
        rewardEarned: 100,
        completedAt: now,
      );

      expect(completion.completionId, 'comp1');
      expect(completion.rewardEarned, 100);
      expect(completion.bonusRewardEarned, false);
    });

    test('toJson serializes completion', () {
      final now = DateTime.now();
      final completion = ChallengeCompletion(
        completionId: 'comp1',
        challengeId: 'ch1',
        userId: 'user1',
        rewardEarned: 100,
        bonusRewardEarned: true,
        completedAt: now,
        timeSpentMinutes: 30,
      );

      final json = completion.toJson();
      expect(json['rewardEarned'], 100);
      expect(json['bonusRewardEarned'], true);
    });
  });

  group('UserChallenges', () {
    test('creates user challenges collection', () {
      final now = DateTime.now();
      final userChallenges = UserChallenges(
        userId: 'user1',
        availableChallenges: [],
        progress: {},
        completionHistory: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      expect(userChallenges.userId, 'user1');
      expect(userChallenges.availableChallenges, isEmpty);
    });

    test('getAvailableChallenges filters correctly', () {
      final now = DateTime.now();
      final challenge1 = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now.subtract(const Duration(hours: 1)),
        endsAt: now.add(const Duration(hours: 1)),
      );

      final challenge2 = Challenge(
        challengeId: 'ch2',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now.add(const Duration(hours: 1)),
      );

      final userChallenges = UserChallenges(
        userId: 'user1',
        availableChallenges: [challenge1, challenge2],
        progress: {},
        completionHistory: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final available = userChallenges.getAvailableChallenges();
      expect(available.length, 1);
      expect(available[0].challengeId, 'ch1');
    });

    test('getChallengesByCategory filters correctly', () {
      final now = DateTime.now();
      final challenge1 = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
      );

      final challenge2 = Challenge(
        challengeId: 'ch2',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.writing,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
      );

      final userChallenges = UserChallenges(
        userId: 'user1',
        availableChallenges: [challenge1, challenge2],
        progress: {},
        completionHistory: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final reading = userChallenges.getChallengesByCategory(ChallengeCategory.reading);
      expect(reading.length, 1);
      expect(reading[0].category, ChallengeCategory.reading);
    });

    test('getDailyChallenges returns daily only', () {
      final now = DateTime.now();
      final dailyChallenge = Challenge(
        challengeId: 'ch1',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.daily,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
      );

      final weeklyChallenge = Challenge(
        challengeId: 'ch2',
        title: 'Test',
        description: 'Test',
        category: ChallengeCategory.reading,
        difficulty: ChallengeDifficulty.normal,
        frequency: ChallengeFrequency.weekly,
        targetCount: 10,
        reward: ChallengeReward(currency: RewardCurrency.xp, amount: 100),
        createdAt: now,
        startsAt: now,
      );

      final userChallenges = UserChallenges(
        userId: 'user1',
        availableChallenges: [dailyChallenge, weeklyChallenge],
        progress: {},
        completionHistory: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final daily = userChallenges.getDailyChallenges();
      expect(daily.length, 1);
      expect(daily[0].frequency, ChallengeFrequency.daily);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final userChallenges = UserChallenges(
        userId: 'user1',
        availableChallenges: [],
        progress: {},
        completionHistory: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );

      final json = userChallenges.toJson();
      final restored = UserChallenges.fromJson(json);

      expect(restored.userId, userChallenges.userId);
      expect(restored.availableChallenges.length, userChallenges.availableChallenges.length);
    });
  });

  group('ChallengeStats', () {
    test('creates stats with required fields', () {
      final now = DateTime.now();
      final stats = ChallengeStats(
        userId: 'user1',
        totalChallengesAvailable: 10,
        totalChallengesCompleted: 5,
        totalRewardsEarned: 500,
        totalBonusesEarned: 1,
        currentStreak: 3,
        longestStreak: 5,
        completionsByCategory: {},
        completionsByDifficulty: {},
        lastCompletionAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalChallengesCompleted, 5);
    });

    test('completionRate calculates correctly', () {
      final now = DateTime.now();
      final stats = ChallengeStats(
        userId: 'user1',
        totalChallengesAvailable: 10,
        totalChallengesCompleted: 5,
        totalRewardsEarned: 500,
        totalBonusesEarned: 1,
        currentStreak: 3,
        longestStreak: 5,
        completionsByCategory: {},
        completionsByDifficulty: {},
        lastCompletionAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.completionRate, 50);
    });

    test('averageReward calculates correctly', () {
      final now = DateTime.now();
      final stats = ChallengeStats(
        userId: 'user1',
        totalChallengesAvailable: 10,
        totalChallengesCompleted: 5,
        totalRewardsEarned: 500,
        totalBonusesEarned: 1,
        currentStreak: 3,
        longestStreak: 5,
        completionsByCategory: {},
        completionsByDifficulty: {},
        lastCompletionAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.averageReward, 100);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = ChallengeStats(
        userId: 'user1',
        totalChallengesAvailable: 10,
        totalChallengesCompleted: 5,
        totalRewardsEarned: 500,
        totalBonusesEarned: 1,
        currentStreak: 3,
        longestStreak: 5,
        completionsByCategory: {
          ChallengeCategory.reading: 3,
          ChallengeCategory.writing: 2,
        },
        completionsByDifficulty: {
          ChallengeDifficulty.normal: 4,
          ChallengeDifficulty.hard: 1,
        },
        lastCompletionAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      final restored = ChallengeStats.fromJson(json);

      expect(restored.userId, stats.userId);
      expect(restored.totalChallengesCompleted, stats.totalChallengesCompleted);
    });
  });

  group('ChallengeCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final userChallenges = UserChallenges(
        userId: 'user1',
        availableChallenges: [],
        progress: {},
        completionHistory: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );
      final stats = ChallengeStats(
        userId: 'user1',
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

      final collection = ChallengeCollection(
        userId: 'user1',
        challenges: userChallenges,
        stats: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.challenges.userId, 'user1');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final userChallenges = UserChallenges(
        userId: 'user1',
        availableChallenges: [],
        progress: {},
        completionHistory: [],
        lastUpdatedAt: now,
        generatedAt: now,
      );
      final stats = ChallengeStats(
        userId: 'user1',
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

      final collection = ChallengeCollection(
        userId: 'user1',
        challenges: userChallenges,
        stats: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = ChallengeCollection.fromJson(json);

      expect(restored.userId, collection.userId);
    });
  });
}
