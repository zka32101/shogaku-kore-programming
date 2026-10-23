// Application Constants
// Phase 4.2: RevenueCat Configuration

class AppConstants {
  // RevenueCat の API キーはここに置かない（開発用キーが本番ビルドに残るのを防ぐ）。
  // `--dart-define=REVENUE_CAT_GOOGLE_KEY` / `REVENUE_CAT_APPLE_KEY` で渡し、
  // revenue_cat_service.dart の SubscriptionConfig が読む。

  static const String subscriptionProductId = 'programming_premium_monthly';
  static const String premiumEntitlementId = 'premium_access';

  // Feature Flags
  static const bool adsFreeWithSubscription = true;
  static const bool unlimitedQuizzesWithSubscription = true;

  // Pricing (for display)
  static const String monthlyPrice = '¥300';
  static const String yearlyPrice = '¥2,400';
  static const int trialDays = 7;

  // App info
  static const String appName = '小学コレ！プログラミング';
  static const String appVersion = '0.1.0';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String challengesCollection = 'challenges';
  static const String progressCollection = 'progress';
}
