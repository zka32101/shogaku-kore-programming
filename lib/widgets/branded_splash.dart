import 'package:flutter/material.dart';

/// 起動画面の背景色（白固定。ダークモードでも変えない）。
const Color kSplashBackground = Color(0xFFFFFFFF);

/// 小学コレ！シリーズ共通の起動画面（1枚構成・白背景）。
///
/// 中央にアプリアイコン + 小さな読み込み表示、下寄りにシリーズロゴ、
/// 最下部に組織ロゴ。アプリ内のスプラッシュ画面と同じ見た目に揃える。
class BrandedSplash extends StatelessWidget {
  const BrandedSplash({
    super.key,
    this.iconAsset = 'assets/logos/app_icon_512.jpg',
    this.seriesLogoAsset = 'assets/logos/series_logo.png',
    this.companyLogoAsset = 'assets/logos/company_app_icon.jpg',
    this.progressColor = const Color(0xFF263250),
  });

  final String iconAsset;
  final String seriesLogoAsset;
  final String companyLogoAsset;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSplashBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        iconAsset,
                        key: const ValueKey('splash_app_icon'),
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Image.asset(
              seriesLogoAsset,
              key: const ValueKey('splash_series_logo'),
              width: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                companyLogoAsset,
                key: const ValueKey('splash_company_logo'),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
