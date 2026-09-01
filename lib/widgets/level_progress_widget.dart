import 'package:flutter/material.dart';
import '../models/level.dart';

/// レベル進捗表示ウィジェット
class LevelProgressWidget extends StatelessWidget {
  final UserLevelProgress? progress;
  final VoidCallback? onTap;

  const LevelProgressWidget({
    super.key,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getLevelColor(progress!.level.tier).withValues(alpha: 0.2),
              _getLevelColor(progress!.level.tier).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getLevelColor(progress!.level.tier),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Text(
                  progress!.level.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${progress!.level.levelNumber}',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getLevelColor(progress!.level.tier),
                        ),
                      ),
                      Text(
                        progress!.level.title,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // XP進捗バー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Experience',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${progress!.currentXp}/${progress!.remainingXp + progress!.currentXp}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress!.progress / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getLevelColor(progress!.level.tier),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress!.progress.toStringAsFixed(1)}% to next level',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 説明
            Text(
              progress!.level.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(LevelTier tier) {
    return switch (tier) {
      LevelTier.beginner => Colors.green,
      LevelTier.intermediate => Colors.blue,
      LevelTier.advanced => Colors.orange,
      LevelTier.expert => Colors.red,
    };
  }
}

/// レベルバッジウィジェット（小型）
class LevelBadgeWidget extends StatelessWidget {
  final int levelNumber;
  final double size;

  const LevelBadgeWidget({
    super.key,
    required this.levelNumber,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final level = DefaultLevels.getLevelByNumber(levelNumber);
    if (level == null) return SizedBox(width: size, height: size);

    final color = _getLevelColor(level.tier);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            level.emoji,
            style: TextStyle(fontSize: size * 0.4),
          ),
          Text(
            'Lv$levelNumber',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LevelTier tier) {
    return switch (tier) {
      LevelTier.beginner => Colors.green,
      LevelTier.intermediate => Colors.blue,
      LevelTier.advanced => Colors.orange,
      LevelTier.expert => Colors.red,
    };
  }
}

/// 小型レベル表示（ヘッダー用）
class LevelHeaderWidget extends StatelessWidget {
  final int currentLevel;
  final int totalXp;
  final VoidCallback? onTap;

  const LevelHeaderWidget({
    super.key,
    required this.currentLevel,
    required this.totalXp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = DefaultLevels.getLevelByNumber(currentLevel);
    if (level == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getLevelColor(level.tier).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getLevelColor(level.tier),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              level.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $currentLevel',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(level.tier),
                  ),
                ),
                Text(
                  '$totalXp XP',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(LevelTier tier) {
    return switch (tier) {
      LevelTier.beginner => Colors.green,
      LevelTier.intermediate => Colors.blue,
      LevelTier.advanced => Colors.orange,
      LevelTier.expert => Colors.red,
    };
  }
}
