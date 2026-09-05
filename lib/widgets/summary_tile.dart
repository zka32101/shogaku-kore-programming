import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Summary tile displaying emoji, animated number, and label
class SummaryTile extends StatelessWidget {
  final String emoji;
  final int numValue;
  final String suffix;
  final String label;

  const SummaryTile({
    super.key,
    required this.emoji,
    required this.numValue,
    required this.suffix,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: numValue),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, value, _) => Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kTextSecondary),
        ),
      ],
    );
  }
}
