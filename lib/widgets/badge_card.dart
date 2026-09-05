import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/badge.dart';
import '../services/haptic_service.dart';

/// Badge display card with unlock progress and detail modal
class AchievementBadgeCard extends StatelessWidget {
  final Badge badge;

  const AchievementBadgeCard({super.key, required this.badge});

  void _showDetails(BuildContext context) {
    HapticService.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge.isUnlocked ? badge.icon : '🔒',
              style: TextStyle(
                fontSize: 56,
                color: badge.isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked ? context.textPrimary : kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: const TextStyle(
                fontSize: 14,
                color: kTextSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? kPrimaryColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge.isUnlocked ? '✅ 達成済み！' : '🔒 未達成',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked ? kPrimaryColor : kTextSecondary,
                ),
              ),
            ),
            // 未達成かつ進捗あり → プログレスバー
            if (!badge.isUnlocked &&
                badge.progressRatio != null &&
                badge.progressRatio! > 0) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '進捗',
                          style: const TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                        Text(
                          '${badge.progressCurrent} / ${badge.progressTarget}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: badge.progressRatio!),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 達成済みのときだけシェアボタンを表示
            if (badge.isUnlocked) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticService.lightImpact();
                    final text =
                        '🎓 小学生向けプログラミングアプリで「${badge.icon} ${badge.name}」バッジを獲得！\n'
                        '${badge.description}\n#しょうがくプログラミング';
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 シェア用テキストをコピーしました！'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('シェアする'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.5)),
                    foregroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = badge.progressRatio;
    final showProgress = !badge.isUnlocked && ratio != null && ratio > 0;

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: badge.isUnlocked ? context.cardBg : context.subCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge.isUnlocked
                ? kPrimaryColor.withValues(alpha: 0.3)
                : context.borderColor,
          ),
          boxShadow: badge.isUnlocked
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.isUnlocked ? badge.icon : '🔒',
                style: TextStyle(
                  fontSize: 28,
                  color: badge.isUnlocked ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked ? context.textPrimary : kTextSecondary,
                ),
              ),
              if (showProgress) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: ratio),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOut,
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            backgroundColor: context.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kPrimaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${badge.progressCurrent}/${badge.progressTarget}',
                        style: TextStyle(
                          fontSize: 10,
                          color: kPrimaryColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: kTextSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
