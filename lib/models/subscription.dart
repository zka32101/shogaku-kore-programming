/// サブスクリプション・トライアル状態を管理するモデル
class SubscriptionState {
  // トライアル関連
  final DateTime? trialStartDate;      // トライアル開始日
  final bool isTrialActive;            // トライアル期間中かどうか
  final int trialDaysRemaining;        // 残り試用日数
  final bool hasUsedTrial;             // トライアルを使用済みかどうか

  // 購読関連
  final bool isPremiumSubscriber;      // プレミアム購読者かどうか
  final DateTime? premiumExpiryDate;   // プレミアム購読終了日

  // 広告関連
  final bool shouldShowAds;            // 広告を表示するかどうか

  const SubscriptionState({
    this.trialStartDate,
    this.isTrialActive = false,
    this.trialDaysRemaining = 0,
    this.hasUsedTrial = false,
    this.isPremiumSubscriber = false,
    this.premiumExpiryDate,
    this.shouldShowAds = true,
  });

  /// ユーザーが有料コンテンツにアクセス可能かどうかを判定
  bool canAccessPremiumContent() {
    return isTrialActive || isPremiumSubscriber;
  }

  /// トライアル期間の割合を取得 (0.0 - 1.0)
  double getTrialProgress() {
    if (!hasUsedTrial) return 0.0;
    if (!isTrialActive) return 1.0;

    final remainingPercent = trialDaysRemaining / 14;
    return 1.0 - remainingPercent;
  }

  /// トライアル終了時の処理用フラグ
  bool isTrialExpired() {
    return hasUsedTrial && !isTrialActive;
  }

  SubscriptionState copyWith({
    DateTime? trialStartDate,
    bool? isTrialActive,
    int? trialDaysRemaining,
    bool? hasUsedTrial,
    bool? isPremiumSubscriber,
    DateTime? premiumExpiryDate,
    bool? shouldShowAds,
  }) {
    return SubscriptionState(
      trialStartDate: trialStartDate ?? this.trialStartDate,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
      isPremiumSubscriber: isPremiumSubscriber ?? this.isPremiumSubscriber,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      shouldShowAds: shouldShowAds ?? this.shouldShowAds,
    );
  }

  @override
  String toString() {
    return '''SubscriptionState(
      trialStartDate: $trialStartDate,
      isTrialActive: $isTrialActive,
      trialDaysRemaining: $trialDaysRemaining,
      hasUsedTrial: $hasUsedTrial,
      isPremiumSubscriber: $isPremiumSubscriber,
      premiumExpiryDate: $premiumExpiryDate,
      shouldShowAds: $shouldShowAds,
      canAccessPremium: ${canAccessPremiumContent()},
      isTrialExpired: ${isTrialExpired()}
    )''';
  }
}
