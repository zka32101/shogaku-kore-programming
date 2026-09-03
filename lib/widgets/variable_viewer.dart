import 'package:flutter/material.dart';
import '../config/theme.dart';

class VariableViewer extends StatelessWidget {
  final Map<String, dynamic> variables;

  const VariableViewer({
    super.key,
    required this.variables,
  });

  @override
  Widget build(BuildContext context) {
    if (variables.isEmpty) {
      return _buildEmptyState(context);
    }

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
          // ─── タイトル ────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 20,
                color: kPrimaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '変数',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── 変数リスト ────────────────────────────────────────────
          ...variables.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 20,
            color: context.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            '変数はまだ使用されていません',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
