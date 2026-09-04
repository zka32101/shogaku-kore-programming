import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _floatController;
  late Animation<double> _logoAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // スプラッシュ表示後にルーティング
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _navigate();
    });
  }

  void _navigate() {
    final currentUser = ref.read(currentUserProvider);

    // ─────────────────────────────────────────────────────────
    // 認証状態に基づいてナビゲーション先を決定
    // ─────────────────────────────────────────────────────────
    final destination = _getNextScreen(currentUser);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// 現在の認証状態と設定に基づいて、次のスクリーンを決定
  Widget _getNextScreen(dynamic currentUser) {
    // ログインしていない → LoginScreen
    if (currentUser == null) {
      return const LoginScreen();
    }

    // ログイン済み
    final profile = ref.read(profileProvider);

    // オンボーディング完了 → MainNavigator
    if (profile.isOnboardingComplete) {
      return const MainNavigator();
    }

    // オンボーディング未完了 → OnboardingScreen
    return const OnboardingScreen();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // グラジェント背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kPrimaryColor, kPrimaryDark],
              ),
            ),
          ),
          // 浮かぶ星
          ..._buildFloatingStars(),
          // ロゴ＆タイトル
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoAnimation,
                  child: const Text(
                    '💻',
                    style: TextStyle(fontSize: 96),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '小学コレ！プログラミング',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut, duration: 400.ms),
                const SizedBox(height: 8),
                const Text(
                  'コードの世界を探険しよう！',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ).animate(delay: 450.ms).fadeIn(duration: 350.ms),
                const SizedBox(height: 32),
                // 特徴タグ
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _FeatureTag(label: '🧩 ブロックプログラミング')
                        .animate(delay: 550.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 300.ms),
                    _FeatureTag(label: '🐍 Python入門')
                        .animate(delay: 620.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 300.ms),
                    _FeatureTag(label: '🏆 達成バッジ')
                        .animate(delay: 690.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 300.ms),
                  ],
                ),
                const SizedBox(height: 48),
                // ローディングインジケーター
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white.withValues(alpha: 0.7),
                    strokeWidth: 2.5,
                  ),
                ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingStars() {
    final stars = ['⭐', '✨', '🌟', '💫'];
    return List.generate(6, (i) {
      final angle = (i / 6) * math.pi * 2;
      final radius = 110.0 + (i % 3) * 50;
      return Positioned(
        top: MediaQuery.of(context).size.height * 0.35 +
            math.sin(angle) * radius * 0.5,
        left: MediaQuery.of(context).size.width * 0.5 +
            math.cos(angle) * radius -
            12,
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnimation.value * (i.isEven ? 1 : -1)),
            child: Opacity(
              opacity: 0.5,
              child: Text(
                stars[i % stars.length],
                style: TextStyle(fontSize: 16.0 + (i % 3) * 4),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _FeatureTag extends StatelessWidget {
  final String label;

  const _FeatureTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
