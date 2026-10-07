import 'package:flutter/material.dart';
import 'package:shogaku_kore_programming/widgets/ukalab_emoji.dart';

/// シンプルな統計アイテム表示ウィジェット
/// アイコン、値、ラベルを縦に並べて表示
class StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UkalabEmoji(icon, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}
