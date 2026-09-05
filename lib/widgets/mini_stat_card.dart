import 'package:flutter/material.dart';
import '../config/theme.dart';

/// カラフルな統計ミニカード
/// 背景色付きで、アイコン、値、ラベルを表示
class MiniStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const MiniStatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
