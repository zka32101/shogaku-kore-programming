import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/step_executor_provider.dart';
import '../config/theme.dart';

class StepExecutionControls extends ConsumerWidget {
  final int totalBlocks;
  final VoidCallback onStepForward;

  const StepExecutionControls({
    Key? key,
    required this.totalBlocks,
    required this.onStepForward,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(stepExecutorProvider);
    final executor = ref.read(stepExecutorProvider.notifier);
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── 進捗インジケーター ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ステップ実行',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.subCardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${execState.currentStepIndex} / $totalBlocks',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── プログレスバー ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalBlocks > 0 ? execState.currentStepIndex / totalBlocks : 0,
              minHeight: 8,
              backgroundColor: context.subCardBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                execState.lastExecutionSuccess ? kPrimaryColor : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── メインコントロール ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 戻るボタン
              _ControlButton(
                icon: Icons.skip_previous,
                label: '戻す',
                onPressed: execState.currentStepIndex > 0
                    ? () => executor.stepBackward()
                    : null,
                isDark: isDark,
              ),

              // ステップ実行ボタン
              _ControlButton(
                icon: Icons.skip_next,
                label: 'ステップ',
                onPressed: execState.currentStepIndex < totalBlocks
                    ? () {
                        executor.stepForward().then((_) {
                          onStepForward();
                        });
                      }
                    : null,
                isDark: isDark,
                isHighlighted: true,
              ),

              // リセットボタン
              _ControlButton(
                icon: Icons.restart_alt,
                label: 'リセット',
                onPressed: () => executor.reset(),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── 実行速度コントロール ──────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '実行速度',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    _getSpeedLabel(execState.executionSpeed),
                    style: TextStyle(
                      fontSize: 12,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: execState.executionSpeed.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _getSpeedLabel(execState.executionSpeed),
                onChanged: (value) {
                  executor.setExecutionSpeed(value.toInt());
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── 実行メッセージ ────────────────────────────────────────
          if (execState.outputMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.subCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: execState.lastExecutionSuccess
                      ? kPrimaryColor.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                execState.outputMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String _getSpeedLabel(int speed) {
    switch (speed) {
      case 1:
        return '🐢 遅い';
      case 2:
        return '🚶 普通遅';
      case 3:
        return '⚡ 普通';
      case 4:
        return '🏃 普通速';
      case 5:
        return '🚀 速い';
      default:
        return '普通';
    }
  }
}

// ─── コントロールボタン ────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDark;
  final bool isHighlighted;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighlighted && !isDisabled
                  ? kPrimaryColor
                  : (isDisabled
                      ? context.subCardBg
                      : isDark
                          ? kDarkSurface2
                          : Colors.grey[200]),
              foregroundColor: isHighlighted && !isDisabled ? Colors.white : null,
              disabledForegroundColor: context.textSecondary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.zero,
              elevation: isHighlighted && !isDisabled ? 4 : 0,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isHighlighted && !isDisabled
                  ? Colors.white
                  : (isDisabled
                      ? context.textSecondary.withValues(alpha: 0.4)
                      : context.textPrimary),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDisabled ? context.textSecondary.withValues(alpha: 0.5) : context.textSecondary,
          ),
        ),
      ],
    );
  }
}
