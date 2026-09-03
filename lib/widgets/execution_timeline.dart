import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../providers/step_executor_provider.dart';

class ExecutionTimeline extends StatelessWidget {
  final List<ExecutionSnapshot> history;
  final int currentHistoryIndex;
  final Function(int) onTimelineChanged;
  final int totalBlocks;

  const ExecutionTimeline({
    super.key,
    required this.history,
    required this.currentHistoryIndex,
    required this.onTimelineChanged,
    required this.totalBlocks,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final progressPercent = (currentHistoryIndex + 1) / totalBlocks;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── タイトル ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⏱️ 実行履歴',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
              ),
              Text(
                '${currentHistoryIndex + 1} / ${history.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── スライダー ──────────────────────────────────────
          Slider(
            value: currentHistoryIndex.toDouble(),
            min: 0,
            max: (history.length - 1).toDouble(),
            divisions: history.length - 1,
            label: 'ステップ ${currentHistoryIndex + 1}',
            onChanged: (value) {
              onTimelineChanged(value.toInt());
            },
          ),

          // ─── 進捗バー ────────────────────────────────────────
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 6,
              backgroundColor: context.subCardBg,
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
            ),
          ),

          // ─── 時間軸 ──────────────────────────────────────────
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                (history.length / 5).ceil(),
                (index) {
                  final step = index * 5;
                  final isCurrentStep =
                      step <= currentHistoryIndex && currentHistoryIndex < step + 5;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: step < history.length
                          ? () => onTimelineChanged(
                              (step + 2).clamp(0, history.length - 1))
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentStep
                              ? kPrimaryColor.withValues(alpha: 0.2)
                              : context.subCardBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCurrentStep
                                ? kPrimaryColor
                                : context.borderColor,
                          ),
                        ),
                        child: Text(
                          'S${step + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isCurrentStep
                                ? kPrimaryColor
                                : context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
