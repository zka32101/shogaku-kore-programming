import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/ad_provider.dart';

/// バナー広告ウィジェット
class BannerAdWidget extends ConsumerWidget {
  final EdgeInsets padding;

  const BannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAdAsync = ref.watch(bannerAdProvider);
    final isAdEnabled = ref.watch(isAdEnabledProvider);

    // 広告が有効でない場合は表示しない
    if (!isAdEnabled) {
      return const SizedBox.shrink();
    }

    return bannerAdAsync.when(
      loading: () => _buildLoadingPlaceholder(),
      error: (error, stack) {
        return const SizedBox.shrink();
      },
      data: (bannerAd) {
        if (bannerAd == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: padding,
          child: Container(
            color: Colors.grey[200],
            child: SizedBox(
              width: bannerAd.size.width.toDouble(),
              height: bannerAd.size.height.toDouble(),
              child: AdWidget(ad: bannerAd),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Padding(
      padding: padding,
      child: Container(
        width: 320,
        height: 50,
        color: Colors.grey[100],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 1),
        ),
      ),
    );
  }
}

/// 画面下部に配置するバナー広告
class BottomBannerAdWidget extends ConsumerWidget {
  const BottomBannerAdWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdEnabled = ref.watch(isAdEnabledProvider);

    if (!isAdEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: const BannerAdWidget(padding: EdgeInsets.zero),
    );
  }
}

/// アダプティブバナー広告（画面幅に応じて自動調整）
class AdaptiveBannerAdWidget extends ConsumerWidget {
  final EdgeInsets padding;

  const AdaptiveBannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAdAsync = ref.watch(bannerAdProvider);
    final isAdEnabled = ref.watch(isAdEnabledProvider);

    if (!isAdEnabled) {
      return const SizedBox.shrink();
    }

    return bannerAdAsync.when(
      loading: () => _buildLoadingPlaceholder(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (bannerAd) {
        if (bannerAd == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: padding,
          child: Container(
            color: Colors.grey[200],
            child: AdWidget(ad: bannerAd),
          ),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Padding(
      padding: padding,
      child: Container(
        color: Colors.grey[100],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 1),
        ),
      ),
    );
  }
}

/// ラッパー: スクリーン内に広告を組み込む
/// 例: ListView や Column の末尾に追加する場合に使用
class AdContainerWidget extends ConsumerWidget {
  final Widget child;
  final bool showAdBelow;

  const AdContainerWidget({
    super.key,
    required this.child,
    this.showAdBelow = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdEnabled = ref.watch(isAdEnabledProvider);

    if (!isAdEnabled) {
      return child;
    }

    return Column(
      children: [
        Expanded(child: child),
        if (showAdBelow) const BottomBannerAdWidget(),
      ],
    );
  }
}
