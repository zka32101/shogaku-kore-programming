import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Small stat cell displaying a colored value and label
class StatMiniCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatMiniCell({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: kTextSecondary),
        ),
      ],
    );
  }
}
