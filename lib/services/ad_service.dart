import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google Mobile Ads を管理するシングルトンサービス
class AdService {
  static final AdService _instance = AdService._internal();

  late BannerAd _bannerAd;
  late InterstitialAd? _interstitialAd;
  late RewardedAd? _rewardedAd;

  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _adsInitialized = false;

  AdService._internal();

  factory AdService() {
    return _instance;
  }

  /// 広告 ID
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy'; // テスト ID
      // 本番: 'ca-app-pub-3940256099942544/6300978111'; // Google Demo Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy'; // テスト ID
      // 本番: 'ca-app-pub-3940256099942544/4469989529'; // Google Demo Banner
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy'; // テスト ID
      // 本番: 'ca-app-pub-3940256099942544/1033173712'; // Google Demo Interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy'; // テスト ID
      // 本番: 'ca-app-pub-3940256099942544/4411468910'; // Google Demo Interstitial
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy'; // テスト ID
      // 本番: 'ca-app-pub-3940256099942544/5224354917'; // Google Demo Rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy'; // テスト ID
      // 本番: 'ca-app-pub-3940256099942544/1712485313'; // Google Demo Rewarded
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Google Mobile Ads 初期化
  /// main.dart で呼び出す
  Future<void> initialize() async {
    if (_adsInitialized) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _adsInitialized = true;
    } catch (e) {
      // Error initializing Google Mobile Ads
      rethrow;
    }
  }

  /// ========== バナー広告 ==========

  /// バナー広告をロード
  Future<BannerAd?> loadBannerAd() async {
    if (!_adsInitialized) {
      await initialize();
    }

    try {
      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isBannerAdLoaded = false;
          },
        ),
      );

      await _bannerAd.load();
      return _bannerAd;
    } catch (e) {
      return null;
    }
  }

  /// バナー広告を取得
  BannerAd? getBannerAd() {
    return _isBannerAdLoaded ? _bannerAd : null;
  }

  /// バナー広告がロード済みか確認
  bool isBannerAdLoaded() => _isBannerAdLoaded;

  /// ========== インタースティシャル広告 ==========

  /// インタースティシャル広告をロード
  Future<void> loadInterstitialAd() async {
    if (!_adsInitialized) {
      await initialize();
    }

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isInterstitialAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      _isInterstitialAdLoaded = false;
    }
  }

  /// インタースティシャル広告を表示
  Future<void> showInterstitialAd({
    VoidCallback? onAdDismissedCallback,
  }) async {
    if (_interstitialAd == null || !_isInterstitialAdLoaded) {
      await loadInterstitialAd();
      return;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          onAdDismissedCallback?.call();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
        },
      );

      await _interstitialAd!.show();
    } catch (e) {
      // Error showing interstitial ad
      rethrow;
    }
  }

  /// ========== リワード広告 ==========

  /// リワード広告をロード
  Future<void> loadRewardedAd() async {
    if (!_adsInitialized) {
      await initialize();
    }

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isRewardedAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      _isRewardedAdLoaded = false;
    }
  }

  /// リワード広告を表示
  Future<bool> showRewardedAd({
    VoidCallback? onUserEarnedReward,
    VoidCallback? onAdDismissedCallback,
  }) async {
    if (_rewardedAd == null || !_isRewardedAdLoaded) {
      await loadRewardedAd();
      return false;
    }

    try {
      bool userEarnedReward = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          onAdDismissedCallback?.call();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          userEarnedReward = true;
          onUserEarnedReward?.call();
        },
      );

      return userEarnedReward;
    } catch (e) {
      return false;
    }
  }

  /// ========== クリーンアップ ==========

  /// すべての広告を破棄
  void dispose() {
    if (_isBannerAdLoaded) {
      _bannerAd.dispose();
      _isBannerAdLoaded = false;
    }
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }

  /// 広告が初期化されているか
  bool get isInitialized => _adsInitialized;
}
