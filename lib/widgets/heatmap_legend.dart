import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Legend widget for heatmap showing color intensity from min to max
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('少', style: TextStyle(fontSize: 9, color: kTextSecondary)),
        const SizedBox(width: 2),
        ...List.generate(4, (i) {
          final alphas = [0.08, 0.35, 0.6, 1.0];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: i == 0
                  ? (kPrimaryColor.withValues(alpha: 0.08))
                  : kPrimaryColor.withValues(alpha: alphas[i]),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 2),
        const Text('多', style: TextStyle(fontSize: 9, color: kTextSecondary)),
      ],
    );
  }
}
