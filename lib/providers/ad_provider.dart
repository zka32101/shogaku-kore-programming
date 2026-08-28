import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/monetization_service.dart';
import 'subscription_provider.dart';

/// Google Mobile Ads サービスプロバイダー
final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

/// バナー広告のロード状態
final bannerAdProvider = FutureProvider<BannerAd?>((ref) async {
  final adService = ref.watch(adServiceProvider);
  final shouldShowAds = ref.watch(shouldShowAdsProvider);

  if (!shouldShowAds) {
    return null; // 広告を表示しない
  }

  await adService.initialize();
  return await adService.loadBannerAd();
});

/// インタースティシャル広告をロード済みか
final isInterstitialAdReadyProvider = StateProvider<bool>((ref) {
  return false; // 初期値は未ロード
});

/// リワード広告をロード済みか
final isRewardedAdReadyProvider = StateProvider<bool>((ref) {
  return false; // 初期値は未ロード
});

/// 広告初期化
class AdInitializerNotifier extends StateNotifier<AsyncValue<void>> {
  final AdService _adService;

  AdInitializerNotifier(this._adService)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _adService.initialize();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adInitializerProvider =
    StateNotifierProvider<AdInitializerNotifier, AsyncValue<void>>((ref) {
  final adService = ref.watch(adServiceProvider);
  return AdInitializerNotifier(adService);
});

/// インタースティシャル広告を表示（チャレンジ完了時など）
class InterstitialAdController {
  final AdService _adService;
  final Ref _ref;

  InterstitialAdController(this._adService, this._ref);

  /// 広告を表示
  Future<void> show({VoidCallback? onAdDismissed}) async {
    final subscription = _ref.read(subscriptionProvider);

    // トライアル中またはプレミアム購読中は広告を表示しない
    if (!MonetizationService.shouldDisplayAds(subscription)) {
      return;
    }

    // まだロードされていない場合はロード
    if (!_adService.isBannerAdLoaded()) {
      await _adService.loadInterstitialAd();
    }

    await _adService.showInterstitialAd(
      onAdDismissedCallback: onAdDismissed,
    );
  }

  /// 事前ロード（バックグラウンド）
  Future<void> preload() async {
    await _adService.loadInterstitialAd();
  }
}

/// リワード広告コントローラー
class RewardedAdController {
  final AdService _adService;
  final Ref _ref;

  RewardedAdController(this._adService, this._ref);

  /// 広告を表示してリワードを獲得
  Future<bool> show({
    VoidCallback? onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) async {
    final subscription = _ref.read(subscriptionProvider);

    // プレミアム購読中は広告を表示しない（ただしリワードを与える）
    if (subscription.isPremiumSubscriber) {
      onUserEarnedReward?.call();
      return true;
    }

    // トライアル中も広告を表示しない（ただしリワードを与える）
    if (subscription.isTrialActive) {
      onUserEarnedReward?.call();
      return true;
    }

    // 通常ユーザーには広告を表示
    return await _adService.showRewardedAd(
      onUserEarnedReward: onUserEarnedReward,
      onAdDismissedCallback: onAdDismissed,
    );
  }

  /// 事前ロード
  Future<void> preload() async {
    await _adService.loadRewardedAd();
  }
}

/// インタースティシャル広告コントローラープロバイダー
final interstitialAdControllerProvider = Provider((ref) {
  final adService = ref.watch(adServiceProvider);
  return InterstitialAdController(adService, ref);
});

/// リワード広告コントローラープロバイダー
final rewardedAdControllerProvider = Provider((ref) {
  final adService = ref.watch(adServiceProvider);
  return RewardedAdController(adService, ref);
});

/// 広告が有効か（初期化済みかつ表示対象）
final isAdEnabledProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  final adService = ref.watch(adServiceProvider);

  // トライアル中またはプレミアム購読中は広告を表示しない
  if (!MonetizationService.shouldDisplayAds(subscription)) {
    return false;
  }

  // 広告が初期化されているか
  return adService.isInitialized;
});
