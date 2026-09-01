import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/models/challenge.dart';
import 'package:shogaku_kore_programming/providers/challenge_provider.dart';

void main() {
  group('ChallengeState', () {
    test('should initialize with default values', () {
      final state = ChallengeState();
      expect(state.challengeData, isNull);
      expect(state.isLoading, false);
      expect(state.userProgress.isEmpty, true);
    });

    test('copyWith should update fields', () {
      final state = ChallengeState(isLoading: true);
      final updated = state.copyWith(isLoading: false, error: 'Test error');
      expect(updated.isLoading, false);
      expect(updated.error, 'Test error');
    });
  });

  group('ChallengeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should generate daily challenges', () async {
      final notifier = container.read(challengeProvider.notifier);
      final challenges = await notifier.generateDailyChallenges(count: 3);

      expect(challenges.availableChallenges.length, 3);
      expect(challenges.availableChallenges[0].type, ChallengeType.daily);
    });

    test('should start challenge', () async {
      final notifier = container.read(challengeProvider.notifier);
      await notifier.startChallenge('user-1', 'ch-1');

      final state = container.read(challengeProvider);
      expect(state.userProgress.containsKey('ch-1'), true);
    });

    test('should complete challenge', () async {
      final notifier = container.read(challengeProvider.notifier);
      await notifier.startChallenge('user-1', 'ch-1');

      final completion = await notifier.completeChallenge(
        'user-1',
        'ch-1',
        100,
        50,
      );

      expect(completion.earnedXp, 100);
      expect(completion.earnedCoins, 50);

      final state = container.read(challengeProvider);
      expect(
        state.userProgress['ch-1']?.status,
        ChallengeStatus.completed,
      );
    });

    test('getActiveChallenges should return live challenges', () async {
      final notifier = container.read(challengeProvider.notifier);
      await notifier.generateDailyChallenges();

      final active = notifier.getActiveChallenges();
      expect(active.isNotEmpty, true);
      expect(active.every((c) => c.isLive), true);
    });

    test('getStreakCount should return current streak', () async {
      final notifier = container.read(challengeProvider.notifier);
      expect(notifier.getStreakCount(ChallengeType.daily), 0);
    });
  });

  group('Challenge Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('activeChallengesProvider should provide active challenges', () async {
      final notifier = container.read(challengeProvider.notifier);
      await notifier.generateDailyChallenges();

      final active = container.read(activeChallengesProvider);
      expect(active.isNotEmpty, true);
    });

    test('userStreakProvider should provide streak count', () {
      final streak = container.read(
        userStreakProvider(ChallengeType.daily),
      );
      expect(streak, isA<int>());
    });
  });
}
