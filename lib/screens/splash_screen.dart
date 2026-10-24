import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../providers/profile_provider.dart';
import '../widgets/branded_splash.dart';
import 'onboarding_screen.dart';

/// 起動画面（白背景: 中央にアプリアイコン、下にシリーズロゴと組織ロゴ）。
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // スプラッシュ表示後にルーティング
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _navigate();
    });
  }

  void _navigate() {
    // ─────────────────────────────────────────────────────────
    // 認証は起動時に自動で匿名ログインされるため、設定のみで
    // ナビゲーション先を決定する
    // ─────────────────────────────────────────────────────────
    final destination = _getNextScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// 設定に基づいて、次のスクリーンを決定
  Widget _getNextScreen() {
    final profile = ref.read(profileProvider);

    // オンボーディング完了 → MainNavigator
    if (profile.isOnboardingComplete) {
      return const MainNavigator();
    }

    // オンボーディング未完了 → OnboardingScreen
    return const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedSplash();
  }
}
