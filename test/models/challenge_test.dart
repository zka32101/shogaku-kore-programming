import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/challenge.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';

void main() {
  group('ChallengeType enum', () {
    test('should have all required values', () {
      expect(ChallengeType.daily, isNotNull);
      expect(ChallengeType.weekly, isNotNull);
      expect(ChallengeType.monthly, isNotNull);
      expect(ChallengeType.special, isNotNull);
    });
  });

  group('ChallengeDifficulty enum', () {
    test('should have correct ordering', () {
      expect(ChallengeDifficulty.easy.index, 0);
      expect(ChallengeDifficulty.medium.index, 1);
      expect(ChallengeDifficulty.hard.index, 2);
      expect(ChallengeDifficulty.expert.index, 3);
    });
  });

  group('ChallengeCondition', () {
    late ChallengeCondition condition;

    setUp(() {
      condition = ChallengeCondition(
        conditionId: 'cond-1',
        description: 'Complete 10 quizzes',
        requiredAmount: 10,
        category: LearningCategory.programming,
      );
    });

    test('should create condition with correct values', () {
      expect(condition.conditionId, 'cond-1');
      expect(condition.requiredAmount, 10);
      expect(condition.category, LearningCategory.programming);
    });

    test('should serialize to JSON', () {
      final json = condition.toJson();
      expect(json['conditionId'], 'cond-1');
      expect(json['requiredAmount'], 10);
    });

    test('should deserialize from JSON', () {
      final json = condition.toJson();
      final deserialized = ChallengeCondition.fromJson(json);
      expect(deserialized.conditionId, condition.conditionId);
      expect(deserialized.requiredAmount, condition.requiredAmount);
    });
  });

  group('ChallengeReward', () {
    late ChallengeReward reward;

    setUp(() {
      reward = ChallengeReward(
        xpAmount: 100,
        coinAmount: 50,
        badgeId: 'badge-daily-1',
        categoryBonusXp: {'variables': 25},
      );
    });

    test('should create reward with correct values', () {
      expect(reward.xpAmount, 100);
      expect(reward.coinAmount, 50);
      expect(reward.badgeId, 'badge-daily-1');
    });

    test('should include category bonuses', () {
      expect(reward.categoryBonusXp['variables'], 25);
    });
  });

  group('Challenge', () {
    late Challenge challenge;

    setUp(() {
      challenge = Challenge(
        challengeId: 'ch-1',
        title: 'Daily Challenge',
        description: 'Complete 10 quizzes today',
        type: ChallengeType.daily,
        difficulty: ChallengeDifficulty.medium,
        condition: ChallengeCondition(
          conditionId: 'cond-1',
          description: 'Quiz completions',
          requiredAmount: 10,
        ),
        reward: ChallengeReward(xpAmount: 100, coinAmount: 50),
        startedAt: DateTime(2026, 9, 1),
        expiresAt: DateTime(2026, 9, 2),
        isActive: true,
        isFree: true,
      );
    });

    test('isExpired should return false for future date', () {
      expect(challenge.isExpired, false);
    });

    test('isExpired should return true for past date', () {
      final expiredChallenge = Challenge(
        challengeId: 'ch-2',
        title: 'Old Challenge',
        description: 'Old',
        type: ChallengeType.daily,
        difficulty: ChallengeDifficulty.easy,
        condition: ChallengeCondition(
          conditionId: 'cond-2',
          description: 'Test',
          requiredAmount: 5,
        ),
        reward: ChallengeReward(xpAmount: 50, coinAmount: 25),
        startedAt: DateTime(2026, 8, 1),
        expiresAt: DateTime(2026, 8, 31),
        isActive: true,
        isFree: false,
      );
      expect(expiredChallenge.isExpired, true);
    });

    test('should serialize/deserialize correctly', () {
      final json = challenge.toJson();
      final deserialized = Challenge.fromJson(json);
      expect(deserialized.challengeId, challenge.challengeId);
      expect(deserialized.type, challenge.type);
      expect(deserialized.difficulty, challenge.difficulty);
    });
  });

  group('UserChallengeProgress', () {
    late UserChallengeProgress progress;

    setUp(() {
      progress = UserChallengeProgress(
        userId: 'user-1',
        challengeId: 'ch-1',
        status: ChallengeStatus.inProgress,
        currentProgress: 5,
        startedAt: DateTime(2026, 9, 1),
        attemptCount: 1,
      );
    });

    test('getProgressPercentage should return correct value', () {
      expect(progress.getProgressPercentage(10), 0.5);
      expect(progress.getProgressPercentage(5), 1.0);
      expect(progress.getProgressPercentage(20), 0.25);
    });

    test('isCompleted should return false when in progress', () {
      expect(progress.isCompleted, false);
    });

    test('isCompleted should return true when completed', () {
      final completed = UserChallengeProgress(
        userId: 'user-1',
        challengeId: 'ch-1',
        status: ChallengeStatus.completed,
        currentProgress: 10,
        startedAt: DateTime(2026, 9, 1),
        completedAt: DateTime(2026, 9, 1, 12),
        attemptCount: 1,
      );
      expect(completed.isCompleted, true);
    });
  });

  group('ChallengeStreak', () {
    late ChallengeStreak streak;

    setUp(() {
      streak = ChallengeStreak(
        userId: 'user-1',
        type: ChallengeType.daily,
        currentStreak: 5,
        longestStreak: 10,
        lastCompletedDate: DateTime.now().subtract(Duration(hours: 12)),
        resetDate: DateTime.now().add(Duration(days: 1)),
      );
    });

    test('isStreakActive should return true if completed recently', () {
      expect(streak.isStreakActive, true);
    });

    test('isStreakActive should return false if not completed recently', () {
      final oldStreak = ChallengeStreak(
        userId: 'user-2',
        type: ChallengeType.daily,
        currentStreak: 3,
        longestStreak: 5,
        lastCompletedDate: DateTime.now().subtract(Duration(days: 2)),
        resetDate: DateTime.now(),
      );
      expect(oldStreak.isStreakActive, false);
    });
  });

  group('ChallengeCompletion', () {
    late ChallengeCompletion completion;

    setUp(() {
      completion = ChallengeCompletion(
        completionId: 'comp-1',
        userId: 'user-1',
        challengeId: 'ch-1',
        earnedXp: 100,
        earnedCoins: 50,
        completedAt: DateTime.now(),
        isBonusUnlocked: true,
      );
    });

    test('should serialize/deserialize correctly', () {
      final json = completion.toJson();
      final deserialized = ChallengeCompletion.fromJson(json);
      expect(deserialized.earnedXp, completion.earnedXp);
      expect(deserialized.earnedCoins, completion.earnedCoins);
      expect(deserialized.isBonusUnlocked, true);
    });
  });

  group('ChallengeData', () {
    test('should aggregate all challenge data', () {
      final data = ChallengeData(
        availableChallenges: [],
        userProgress: [],
        streaks: {},
        recentCompletions: [],
        generatedAt: DateTime.now(),
      );

      expect(data.availableChallenges.isEmpty, true);
      expect(data.userProgress.isEmpty, true);
    });
  });
}
