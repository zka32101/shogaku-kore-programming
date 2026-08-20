import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

/// 汎用のローディング表示。単なるスピナーではなく、絵文字が
/// ふわふわ動くアニメーション＋短いメッセージで「待っている感」を
/// やわらげる。
class FriendlyLoading extends StatelessWidget {
  final String message;
  final String emoji;

  const FriendlyLoading({
    super.key,
    this.message = '読み込み中…',
    this.emoji = '🧩',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -6, end: 6, duration: 700.ms, curve: Curves.easeInOut),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
