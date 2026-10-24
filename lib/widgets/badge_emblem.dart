import 'package:flutter/material.dart';
import 'ukalab_emoji.dart';

/// 実績バッジの共通意匠（assets/badges/badge_<意匠>.webp）。
/// [design] が null、または画像を読めない場合は従来の絵文字で出す。
class BadgeEmblem extends StatelessWidget {
  const BadgeEmblem({
    super.key,
    required this.design,
    required this.fallbackEmoji,
    this.size = 32,
  });

  final String? design;
  final String fallbackEmoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = design;
    if (name == null) return UkalabEmoji(fallbackEmoji, size: size);
    return Image.asset(
      'assets/badges/badge_$name.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          UkalabEmoji(fallbackEmoji, size: size),
    );
  }
}
