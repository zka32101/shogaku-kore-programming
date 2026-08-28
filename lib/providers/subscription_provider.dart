import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

/// トライアル・サブスクリプション状態を管理するプロバイダー
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _initialize();
  }

  static const _keyTrialStartDate = 'subscription_trial_start_date';
  static const _keyTrialUsed = 'subscription_trial_used';
  static const _keyPremiumExpiry = 'subscription_premium_expiry';
  static const _trialDurationDays = 14;

  /// 初期化：SharedPreferences からデータを読み込む
  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final trialStartDateStr = prefs.getString(_keyTrialStartDate);
      final hasUsedTrial = prefs.getBool(_keyTrialUsed) ?? false;
      final premiumExpiryStr = prefs.getString(_keyPremiumExpiry);

      DateTime? trialStartDate;
      if (trialStartDateStr != null) {
        trialStartDate = DateTime.parse(trialStartDateStr);
      }

      DateTime? premiumExpiryDate;
      if (premiumExpiryStr != null) {
        premiumExpiryDate = DateTime.parse(premiumExpiryStr);
      }

      // トライアルの有効性を判定
      final isTrialActive = _isTrialActive(trialStartDate, hasUsedTrial);
      final trialDaysRemaining = _calculateTrialDaysRemaining(trialStartDate);

      // プレミアム購読の有効性を判定
      final isPremiumSubscriber = premiumExpiryDate != null &&
          premiumExpiryDate.isAfter(DateTime.now());

      // 広告表示判定
      final shouldShowAds = !isTrialActive && !isPremiumSubscriber;

      state = SubscriptionState(
        trialStartDate: trialStartDate,
        isTrialActive: isTrialActive,
        trialDaysRemaining: trialDaysRemaining,
        hasUsedTrial: hasUsedTrial,
        isPremiumSubscriber: isPremiumSubscriber,
        premiumExpiryDate: premiumExpiryDate,
        shouldShowAds: shouldShowAds,
      );
    } catch (e) {
      state = const SubscriptionState();
    }
  }

  /// トライアルを開始
  Future<void> startTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setString(_keyTrialStartDate, now.toIso8601String());
      await prefs.setBool(_keyTrialUsed, true);

      state = state.copyWith(
        trialStartDate: now,
        isTrialActive: true,
        trialDaysRemaining: _trialDurationDays,
        hasUsedTrial: true,
        shouldShowAds: false,
      );
    } catch (e) {
      // Error starting trial
    }
  }

  /// プレミアム購読を設定（1ヶ月間）
  Future<void> setPremiumSubscription({int monthsDuration = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryDate = DateTime.now().add(Duration(days: monthsDuration * 30));

      await prefs.setString(_keyPremiumExpiry, expiryDate.toIso8601String());

      state = state.copyWith(
        isPremiumSubscriber: true,
        premiumExpiryDate: expiryDate,
        shouldShowAds: false,
      );
    } catch (e) {
      // Error setting premium subscription
    }
  }

  /// プレミアム購読をキャンセル
  Future<void> cancelPremiumSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPremiumExpiry);

      state = state.copyWith(
        isPremiumSubscriber: false,
        premiumExpiryDate: null,
        shouldShowAds: !state.isTrialActive,
      );
    } catch (e) {
      // Error canceling premium subscription
    }
  }

  /// トライアル終了後に広告表示を有効化
  Future<void> expireTrialAndShowAds() async {
    if (state.isTrialActive) {
      state = state.copyWith(
        isTrialActive: false,
        shouldShowAds: !state.isPremiumSubscriber,
      );
    }
  }

  /// トライアルが有効かどうかを判定
  bool _isTrialActive(DateTime? trialStartDate, bool hasUsedTrial) {
    if (!hasUsedTrial || trialStartDate == null) {
      return false;
    }

    final now = DateTime.now();
    final trialEndDate =
        trialStartDate.add(const Duration(days: _trialDurationDays));

    return now.isBefore(trialEndDate);
  }

  /// 残りトライアル日数を計算
  int _calculateTrialDaysRemaining(DateTime? trialStartDate) {
    if (trialStartDate == null) {
      return 0;
    }

    final now = DateTime.now();
    final trialEndDate =
        trialStartDate.add(const Duration(days: _trialDurationDays));

    if (now.isAfter(trialEndDate)) {
      return 0;
    }

    return trialEndDate.difference(now).inDays + 1;
  }

  /// トライアル状態を更新（毎日チェック用）
  Future<void> refreshTrialStatus() async {
    await _initialize();
  }
}

/// グローバルプロバイダー
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

/// トライアル関連のヘルパープロバイダー
final isTrialActiveProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isTrialActive;
});

final canAccessPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).canAccessPremiumContent();
});

final shouldShowAdsProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).shouldShowAds;
});

final trialDaysRemainingProvider = Provider<int>((ref) {
  return ref.watch(subscriptionProvider).trialDaysRemaining;
});

final trialProgressProvider = Provider<double>((ref) {
  return ref.watch(subscriptionProvider).getTrialProgress();
});
