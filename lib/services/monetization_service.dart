import '../models/challenge.dart';
import '../models/subscription.dart';

/// マネタイズに関するビジネスロジックを管理するサービス
class MonetizationService {
  static const int trialDurationDays = 14;

  /// チャレンジへのアクセス可能性を判定
  static bool canAccessChallenge(
    Challenge challenge,
    SubscriptionState subscription,
  ) {
    // 無料チャレンジは常にアクセス可能
    if (challenge.isFree) {
      return true;
    }

    // 有料チャレンジはトライアルまたはプレミアム購読で利用可能
    return subscription.canAccessPremiumContent();
  }

  /// チャレンジのロック理由を取得
  static String? getChallengeLockReason(
    Challenge challenge,
    SubscriptionState subscription,
  ) {
    if (challenge.isFree) {
      return null; // ロックされていない
    }

    if (subscription.isTrialActive) {
      return null; // トライアル中は利用可能
    }

    if (subscription.isPremiumSubscriber) {
      return null; // プレミアム購読者は利用可能
    }

    if (subscription.isTrialExpired()) {
      return 'トライアル期間が終了しました。プレミアム購読で続ける';
    }

    // まだトライアルを開始していない
    return 'プレミアム機能です。14日間の無料トライアルを開始できます';
  }

  /// 有料コンテンツへのアクセスが可能かどうか
  static bool hasPremiumAccess(SubscriptionState subscription) {
    return subscription.canAccessPremiumContent();
  }

  /// 広告表示判定
  static bool shouldDisplayAds(SubscriptionState subscription) {
    return subscription.shouldShowAds;
  }

  /// トライアルが利用可能かどうか
  static bool isTrialAvailable(SubscriptionState subscription) {
    return !subscription.hasUsedTrial;
  }

  /// トライアル進捗を取得（0-100%）
  static int getTrialProgressPercent(SubscriptionState subscription) {
    return (subscription.getTrialProgress() * 100).toInt();
  }

  /// 無料コンテンツの割合を計算（全チャレンジから）
  static double calculateFreeContentPercentage(List<Challenge> allChallenges) {
    if (allChallenges.isEmpty) {
      return 0.0;
    }

    final freeCount = allChallenges.where((c) => c.isFree).length;
    return (freeCount / allChallenges.length) * 100;
  }

  /// トライアルメッセージを生成
  static String getTrialMessage(SubscriptionState subscription) {
    if (!subscription.hasUsedTrial) {
      return '🎉 14日間の無料トライアルをお試しください！すべてのチャレンジが利用できます。';
    }

    if (subscription.isTrialActive) {
      final remaining = subscription.trialDaysRemaining;
      if (remaining == 1) {
        return '⏰ トライアルは明日で終了します。プレミアム購読で続けましょう。';
      }
      return '⏰ トライアルは残り$remaining日です。';
    }

    if (subscription.isTrialExpired()) {
      return '❌ トライアルが終了しました。プレミアム購読ですべてのコンテンツをお楽しみください。';
    }

    if (subscription.isPremiumSubscriber) {
      return '✨ プレミアム購読中です。すべてのコンテンツが利用できます。';
    }

    return '';
  }

  /// 推奨アクション文言を取得
  static String getCallToAction(SubscriptionState subscription) {
    if (!subscription.hasUsedTrial) {
      return 'トライアルを開始';
    }

    if (subscription.isTrialActive) {
      return 'プレミアム購読に登録';
    }

    if (subscription.isTrialExpired() && !subscription.isPremiumSubscriber) {
      return 'プレミアム購読で続ける';
    }

    return '';
  }

  /// チャレンジ統計を取得
  static ChallengeStats getStatistics(
    List<Challenge> allChallenges,
    SubscriptionState subscription,
  ) {
    final total = allChallenges.length;
    final free = allChallenges.where((c) => c.isFree).length;
    final paid = total - free;

    final accessible = allChallenges.where((c) {
      return canAccessChallenge(c, subscription);
    }).length;

    return ChallengeStats(
      total: total,
      free: free,
      paid: paid,
      accessible: accessible,
      freePercentage: (free / total) * 100,
      accessiblePercentage: (accessible / total) * 100,
    );
  }
}

/// チャレンジ統計情報
class ChallengeStats {
  final int total;
  final int free;
  final int paid;
  final int accessible;
  final double freePercentage;
  final double accessiblePercentage;

  ChallengeStats({
    required this.total,
    required this.free,
    required this.paid,
    required this.accessible,
    required this.freePercentage,
    required this.accessiblePercentage,
  });

  @override
  String toString() {
    return '''ChallengeStats(
      total: $total,
      free: $free ($freePercentage%),
      paid: $paid,
      accessible: $accessible ($accessiblePercentage%)
    )''';
  }
}
