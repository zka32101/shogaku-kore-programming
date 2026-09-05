import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/stage.dart';

/// Card displaying a completed stage with stars and level indicator
class CompletedStageCard extends StatelessWidget {
  final Stage challenge;
  final int starsEarned;
  final DateTime? completedAt;

  const CompletedStageCard({
    super.key,
    required this.challenge,
    required this.starsEarned,
    this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = challenge.level == StageLevel.beginner
        ? kPrimaryColor
        : challenge.level == StageLevel.intermediate
            ? const Color(0xFF9B59B6)
            : const Color(0xFFE67E22);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: levelColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(challenge.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stage ${challenge.stageNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    color: levelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (completedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${completedAt!.year}/${completedAt!.month.toString().padLeft(2, '0')}/${completedAt!.day.toString().padLeft(2, '0')} クリア',
                    style: const TextStyle(fontSize: 10, color: kTextSecondary),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: List.generate(
              challenge.maxStars,
              (i) => Icon(
                i < starsEarned ? Icons.star : Icons.star_border,
                size: 18,
                color: i < starsEarned ? kStarColor : context.borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
