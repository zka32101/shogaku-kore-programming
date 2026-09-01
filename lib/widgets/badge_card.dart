import 'package:flutter/material.dart';
import '../models/badge.dart';
import '../providers/badge_provider.dart';

/// バッジカードウィジェット
/// 単一のバッジを表示する
class BadgeCard extends StatelessWidget {
  final BadgeProgressInfo badgeInfo;
  final bool showProgress;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.badgeInfo,
    this.showProgress = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badgeInfo.isUnlocked;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isUnlocked ? 4 : 1,
        color: isUnlocked
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey[isDarkMode ? 800 : 100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // バッジアイコン
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  badgeInfo.badge.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 12),

              // バッジ名
              Text(
                badgeInfo.badge.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.grey[600],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 難易度バッジ
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _getDifficultyColor(badgeInfo.badge.difficulty)
                      .withValues(alpha: 0.2),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  badgeInfo.badge.difficulty.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getDifficultyColor(badgeInfo.badge.difficulty),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),

              // アンロック状況を表示
              if (isUnlocked)
                Text(
                  'アンロック済み ✓',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                )
              else
                // 進捗情報を表示
                if (showProgress && badgeInfo.currentValue > 0)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: badgeInfo.progressPercentage / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${badgeInfo.currentValue.toStringAsFixed(0)}/${badgeInfo.badge.requiredValue}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  )
                else
                  Text(
                    'ロック中',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(BadgeDifficulty difficulty) {
    return switch (difficulty) {
      BadgeDifficulty.bronze => Colors.brown,
      BadgeDifficulty.silver => Colors.grey,
      BadgeDifficulty.gold => Colors.amber,
      BadgeDifficulty.platinum => Colors.purple,
    };
  }
}

/// バッジリストウィジェット
/// 複数のバッジを一覧表示
class BadgesList extends StatelessWidget {
  final List<BadgeProgressInfo> badges;
  final bool showProgress;
  final int crossAxisCount;
  final EdgeInsetsGeometry padding;

  const BadgesList({
    super.key,
    required this.badges,
    this.showProgress = true,
    this.crossAxisCount = 2,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Padding(
          padding: padding,
          child: Text(
            'バッジがありません',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          return BadgeCard(
            badgeInfo: badges[index],
            showProgress: showProgress,
          );
        },
      ),
    );
  }
}
