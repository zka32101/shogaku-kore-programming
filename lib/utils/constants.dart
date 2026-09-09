// Application Constants
// Phase 4.2: RevenueCat Configuration

class AppConstants {
  // RevenueCat Configuration
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUE_CAT_API_KEY',
    defaultValue: 'appl_ProgrammingKoreDevelopment',
  );

  static const String subscriptionProductId = 'programming_premium_monthly';
  static const String premiumEntitlementId = 'premium_access';

  // Feature Flags
  static const bool adsFreeWithSubscription = true;
  static const bool unlimitedQuizzesWithSubscription = true;

  // Pricing (for display)
  static const String monthlyPrice = '¥120';
  static const int trialDays = 7;

  // App info
  static const String appName = '小学コレ！プログラミング';
  static const String appVersion = '0.1.0';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String challengesCollection = 'challenges';
  static const String progressCollection = 'progress';
}
