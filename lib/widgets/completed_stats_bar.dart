import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/stage.dart';
import '../providers/progress_provider.dart';
import 'stat_mini_cell.dart';

/// Bar displaying completion statistics
class CompletedStatsBar extends StatelessWidget {
  final List<Stage> completed;
  final Map<String, UserProgress> progressMap;

  const CompletedStatsBar({
    super.key,
    required this.completed,
    required this.progressMap,
  });

  @override
  Widget build(BuildContext context) {
    final total = completed.length;
    final perfectCount = completed
        .where((c) => (progressMap[c.id]?.starsEarned ?? 0) >= 3)
        .length;
    final totalStars = completed.fold<int>(
      0,
      (sum, c) => sum + (progressMap[c.id]?.starsEarned ?? 0),
    );
    final avgStars = total > 0 ? totalStars / total : 0.0;
    final improveable = total - perfectCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.subCardBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatMiniCell(label: 'クリア', value: '$total', color: kPrimaryColor),
          Container(width: 1, height: 28, color: context.borderColor),
          StatMiniCell(
            label: '平均⭐',
            value: avgStars.toStringAsFixed(1),
            color: kStarColor,
          ),
          Container(width: 1, height: 28, color: context.borderColor),
          StatMiniCell(
            label: '満点',
            value: '$perfectCount',
            color: const Color(0xFF27AE60),
          ),
          Container(width: 1, height: 28, color: context.borderColor),
          StatMiniCell(
            label: '改善可',
            value: '$improveable',
            color: improveable > 0 ? const Color(0xFFE67E22) : kPrimaryColor,
          ),
        ],
      ),
    );
  }
}
