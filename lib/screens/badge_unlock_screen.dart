import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../services/sound_service.dart';

class BadgeUnlockScreen extends StatefulWidget {
  final String badgeIcon;
  final String badgeName;
  final String message;
  final int pointsEarned;
  final String nextGoal;
  final VoidCallback onContinue;
  final String continueLabel;

  const BadgeUnlockScreen({
    super.key,
    required this.badgeIcon,
    required this.badgeName,
    required this.message,
    required this.pointsEarned,
    required this.nextGoal,
    required this.onContinue,
    this.continueLabel = '次のステージへ',
  });

  @override
  State<BadgeUnlockScreen> createState() => _BadgeUnlockScreenState();
}

class _BadgeUnlockScreenState extends State<BadgeUnlockScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _badgeController;
  late AnimationController _raysController;
  late AnimationController _textController;

  late Animation<double> _badgeScale;
  late Animation<double> _raysScale;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _raysController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _badgeScale = CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _raysScale = CurvedAnimation(
      parent: _raysController,
      curve: Curves.easeOut,
    );

    // 順番にアニメーション開始
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _badgeController.forward();
        HapticService.heavyImpact();
        SoundService().playComplete();
      }
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _badgeController.dispose();
    _raysController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onContinue() {
    HapticService.heavyImpact();
    SoundService().playTap();
    widget.onContinue();
    Navigator.pop(context);
  }

  void _onShare() {
    HapticService.lightImpact();
    final text = '🏅 バッジをゲットしたよ！\n'
        '${widget.badgeIcon} ${widget.badgeName}\n'
        '${widget.message}\n'
        '+${widget.pointsEarned}pt獲得！\n'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 コピーしました！LINEやメモに貼り付けてね'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.keyS) {
          _onShare();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.backspace) {
          _onContinue();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      backgroundColor: context.isDark ? kDarkBackground : const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Stack(
          children: [
            // 紙吹雪
            ..._buildConfetti(),
            // メインコンテンツ
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // バッジ＋光線
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 光線
                          AnimatedBuilder(
                            animation: _raysScale,
                            builder: (context, child) => CustomPaint(
                              size: const Size(200, 200),
                              painter: _RaysPainter(
                                progress: _raysScale.value,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          // バッジ
                          ScaleTransition(
                            scale: _badgeScale,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFF4D03F), Color(0xFFF8B88B)],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFD4A530),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF4D03F).withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.badgeIcon,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  Text(
                                    widget.badgeName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B6914),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // テキスト（スライドアップ）
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '+${widget.pointsEarned} ポイント',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.nextGoal,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kTextSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // ボタン
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _onShare,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('コピー'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(widget.continueLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  List<Widget> _buildConfetti() {
    final emojis = ['🎉', '✨', '🎊', '⭐', '🌟', '💫'];
    final random = math.Random(42);
    return List.generate(8, (i) {
      final startX = random.nextDouble();
      return AnimatedBuilder(
        animation: _confettiController,
        builder: (context, _) {
          final progress = (_confettiController.value + i / 8) % 1.0;
          final x = startX * MediaQuery.of(context).size.width;
          final y = progress * MediaQuery.of(context).size.height;
          return Positioned(
            left: x,
            top: y - 40,
            child: Opacity(
              opacity: progress < 0.8 ? 1.0 : (1.0 - progress) / 0.2,
              child: Transform.rotate(
                angle: progress * math.pi * 4,
                child: Text(
                  emojis[i % emojis.length],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _RaysPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RaysPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3 * progress)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final innerRadius = 75.0;
      final outerRadius = 90.0 + 10 * progress;
      final start = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// 便利なショートカット関数
void showBadgeUnlock(
  BuildContext context, {
  required String icon,
  required String name,
  required String message,
  required int points,
  required String nextGoal,
  required VoidCallback onContinue,
  String continueLabel = '次のステージへ',
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => BadgeUnlockScreen(
        badgeIcon: icon,
        badgeName: name,
        message: message,
        pointsEarned: points,
        nextGoal: nextGoal,
        onContinue: onContinue,
        continueLabel: continueLabel,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

/// お気に入り追加後のマイルストーンバッジをチェックして表示する。
/// [wasAdded] が false（削除）なら何もしない。
void checkFavoriteMilestoneBadge(
  BuildContext context, {
  required bool wasAdded,
  required int newCount,
}) {
  if (!wasAdded) return;
  final (icon, name, message, nextGoal) = switch (newCount) {
    1  => ('❤️',  'お気に入り登録',       'はじめてのお気に入り登録！',                 '5つ追加でコレクターバッジ獲得！'),
    5  => ('💝',  'お気に入りコレクター',   'ステージを5つお気に入りに追加！',            '10つ追加でマスターバッジ獲得！'),
    10 => ('💖',  'お気に入りマスター',    'ステージを10つお気に入りに追加！お気に入りの達人！', 'さらにお気に入りを増やそう！'),
    _  => ('', '', '', ''),
  };
  if (icon.isEmpty) return;
  Future.delayed(const Duration(milliseconds: 400), () {
    if (!context.mounted) return;
    showBadgeUnlock(
      context,
      icon: icon,
      name: name,
      message: message,
      points: newCount * 5,
      nextGoal: nextGoal,
      onContinue: () {},
      continueLabel: 'とじる',
    );
  });
}
