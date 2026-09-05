import 'package:flutter/material.dart';

/// シンプルな統計アイテム表示ウィジェット
/// アイコン、値、ラベルを縦に並べて表示
class StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
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
