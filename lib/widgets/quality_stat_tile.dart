import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'package:shogaku_kore_programming/widgets/ukalab_emoji.dart';

/// Mini stat tile displaying emoji, value, and label
class QualityStatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const QualityStatTile({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UkalabEmoji(emoji, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: kTextSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
