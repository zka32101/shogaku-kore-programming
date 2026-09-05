import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/badge.dart';

/// Card displaying the next badge that can be unlocked
class NextBadgeCard extends StatelessWidget {
  final Badge badge;

  const NextBadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final ratio = badge.progressRatio!;
    final pct = (ratio * 100).round();
    final remaining = badge.progressTarget! - badge.progressCurrent!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.10),
            kPrimaryColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー行
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              const Text(
                '次に解除できるバッジ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // バッジ情報行
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor.withValues(alpha: 0.25)),
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 進捗ラベル
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${badge.progressCurrent} / ${badge.progressTarget}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kTextSecondary,
                ),
              ),
              Text(
                'あと$remaining で解除！',
                style: const TextStyle(
                  fontSize: 11,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ratio),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.06, end: 0, curve: Curves.easeOut);
  }
}
