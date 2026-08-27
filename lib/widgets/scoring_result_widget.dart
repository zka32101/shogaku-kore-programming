import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../providers/step_executor_provider.dart';

class ScoringResultWidget extends StatelessWidget {
  final ScoringResult result;

  const ScoringResultWidget({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.isAchieved
              ? kPrimaryColor.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── メッセージ ────────────────────────────────────────────
          Text(
            result.getMessage(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: result.isAchieved ? kPrimaryColor : Colors.red,
                ),
          ),
          const SizedBox(height: 16),

          // ─── 詳細情報 ────────────────────────────────────────────
          if (result.goalX != null && result.goalY != null)
            Column(
              children: [
                // 位置情報
                _buildDetailRow(
                  context,
                  icon: '📍',
                  label: '位置',
                  current:
                      '(${result.currentX?.toStringAsFixed(2)}, ${result.currentY?.toStringAsFixed(2)})',
                  goal:
                      '(${result.goalX?.toStringAsFixed(2)}, ${result.goalY?.toStringAsFixed(2)})',
                  isCorrect: result.isPositionCorrect,
                  tolerance: result.tolerance?.toStringAsFixed(2),
                ),
                const SizedBox(height: 12),

                // 角度情報（指定されている場合）
                if (result.expectedAngle != null)
                  _buildDetailRow(
                    context,
                    icon: '🔄',
                    label: '角度',
                    current: '${result.currentAngle?.toStringAsFixed(0)}°',
                    goal: '${result.expectedAngle?.toStringAsFixed(0)}°',
                    isCorrect: result.isAngleCorrect,
                    tolerance:
                        '±${result.angleToleranceDeg?.toStringAsFixed(0)}°',
                  ),
              ],
            ),

          if (result.isAchieved) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🎉 チャレンジ達成！おめでとうございます！',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String icon,
    required String label,
    required String current,
    required String goal,
    required bool isCorrect,
    String? tolerance,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCorrect
                    ? kPrimaryColor.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCorrect ? '✓ 正解' : '✗ 不正解',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? kPrimaryColor : Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '現在: $current',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
              ),
              Text(
                '目標: $goal',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (tolerance != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              '許容誤差: $tolerance',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: context.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
