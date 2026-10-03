import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/config/constants.dart'
    show AppConstants;
import 'package:shogaku_kore_programming/models/challenge.dart';
import 'package:shogaku_kore_programming/models/subscription.dart';
import 'package:shogaku_kore_programming/services/monetization_service.dart';

Challenge _challenge({required bool isFree}) => Challenge(
      challengeId: 'c_${isFree ? 'free' : 'paid'}',
      title: 't',
      description: 'd',
      type: ChallengeType.daily,
      difficulty: CoreChallengeDifficulty.easy,
      condition: ChallengeCondition(
        conditionId: 'cond',
        description: 'd',
        requiredAmount: 1,
      ),
      reward: ChallengeReward(xpAmount: 1, coinAmount: 1),
      startedAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 12, 31),
      isActive: true,
      isFree: isFree,
    );

void main() {
  const notStarted = SubscriptionState();
  const trialActive = SubscriptionState(
    isTrialActive: true,
    hasUsedTrial: true,
    trialDaysRemaining: 7,
  );
  const trialExpired = SubscriptionState(hasUsedTrial: true);
  const premium = SubscriptionState(
    hasUsedTrial: true,
    isPremiumSubscriber: true,
  );

  test('公開ビルドでは全解放フラグが無効', () {
    expect(AppConstants.unlockAllForTesting, isFalse);
  });

  group('canAccessChallenge', () {
    test('無料チャレンジは常にアクセス可能', () {
      final c = _challenge(isFree: true);
      for (final s in [notStarted, trialActive, trialExpired, premium]) {
        expect(MonetizationService.canAccessChallenge(c, s), isTrue);
      }
    });

    test('有料チャレンジはトライアル中・購読者のみ', () {
      final c = _challenge(isFree: false);
      expect(MonetizationService.canAccessChallenge(c, notStarted), isFalse);
      expect(MonetizationService.canAccessChallenge(c, trialActive), isTrue);
      expect(MonetizationService.canAccessChallenge(c, trialExpired), isFalse);
      expect(MonetizationService.canAccessChallenge(c, premium), isTrue);
    });
  });

  group('getChallengeLockReason', () {
    final paid = _challenge(isFree: false);

    test('アクセス可能ならnull', () {
      expect(MonetizationService.getChallengeLockReason(
          _challenge(isFree: true), notStarted), isNull);
      expect(MonetizationService.getChallengeLockReason(paid, trialActive),
          isNull);
      expect(MonetizationService.getChallengeLockReason(paid, premium),
          isNull);
    });

    test('期限切れと未開始で文言が異なる', () {
      final expired =
          MonetizationService.getChallengeLockReason(paid, trialExpired);
      final fresh =
          MonetizationService.getChallengeLockReason(paid, notStarted);
      expect(expired, contains('終了'));
      expect(fresh, contains('14日間'));
    });
  });

  group('SubscriptionState', () {
    test('isTrialExpired は使用済みかつ非アクティブのとき true', () {
      expect(notStarted.isTrialExpired(), isFalse);
      expect(trialActive.isTrialExpired(), isFalse);
      expect(trialExpired.isTrialExpired(), isTrue);
    });

    test('getTrialProgress', () {
      expect(notStarted.getTrialProgress(), 0.0);
      expect(trialExpired.getTrialProgress(), 1.0);
      expect(trialActive.getTrialProgress(), closeTo(0.5, 1e-9));
    });
  });

  group('メッセージ・CTA', () {
    test('トライアル残り日数', () {
      expect(MonetizationService.getTrialMessage(trialActive), contains('7日'));
      expect(
        MonetizationService.getTrialMessage(
            trialActive.copyWith(trialDaysRemaining: 1)),
        contains('明日'),
      );
    });

    test('CTA', () {
      expect(MonetizationService.getCallToAction(notStarted), 'トライアルを開始');
      expect(MonetizationService.getCallToAction(trialActive),
          'プレミアム購読に登録');
      expect(MonetizationService.getCallToAction(trialExpired),
          'プレミアム購読で続ける');
    });
  });

  test('getStatistics: 無料/有料/アクセス可能数', () {
    final all = [
      _challenge(isFree: true),
      _challenge(isFree: false),
      _challenge(isFree: false),
      _challenge(isFree: true),
    ];
    final locked = MonetizationService.getStatistics(all, trialExpired);
    expect(locked.free, 2);
    expect(locked.paid, 2);
    expect(locked.accessible, 2);
    final open = MonetizationService.getStatistics(all, premium);
    expect(open.accessible, 4);
  });
}
