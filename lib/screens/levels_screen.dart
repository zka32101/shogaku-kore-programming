import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/level.dart';
import '../providers/level_provider.dart';
import '../widgets/level_progress_widget.dart';

/// レベルシステム表示画面
class LevelsScreen extends ConsumerStatefulWidget {
  const LevelsScreen({super.key});

  @override
  ConsumerState<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends ConsumerState<LevelsScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelState = ref.watch(levelProvider);
    final progressAsync = ref.watch(levelProgressProvider);
    final milestonesAsync = ref.watch(milestonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Progression'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 現在のレベル表示
            progressAsync.when(
              data: (progress) => Padding(
                padding: const EdgeInsets.all(16),
                child: LevelProgressWidget(progress: progress),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $error'),
              ),
            ),

            const SizedBox(height: 24),

            // マイルストーン表示
            milestonesAsync.when(
              data: (milestones) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Milestones',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMilestonesGrid(context, milestones),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // すべてのレベル表示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Levels',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLevelGrid(context, levelState.currentLevel),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// マイルストーングリッドを構築
  Widget _buildMilestonesGrid(BuildContext context, Map<int, bool> milestones) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMilestoneCard(context, 10, milestones[10] ?? false),
        _buildMilestoneCard(context, 25, milestones[25] ?? false),
        _buildMilestoneCard(context, 40, milestones[40] ?? false),
        _buildMilestoneCard(context, 50, milestones[50] ?? false),
      ],
    );
  }

  /// マイルストーンカード
  Widget _buildMilestoneCard(BuildContext context, int level, bool reached) {
    final levelData = DefaultLevels.getLevelByNumber(level);
    if (levelData == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: reached
            ? _getLevelColor(levelData.tier).withValues(alpha: 0.2)
            : Colors.grey[200],
        border: Border.all(
          color: reached
              ? _getLevelColor(levelData.tier)
              : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                levelData.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                'Lv$level',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (reached)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.check_circle,
                color: _getLevelColor(levelData.tier),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  /// レベルグリッドを構築
  Widget _buildLevelGrid(BuildContext context, int currentLevel) {
    final levels = DefaultLevels.allLevels;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: levels.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final level = levels[index];
        final isReached = level.levelNumber <= currentLevel;
        final isCurrent = level.levelNumber == currentLevel;

        return GestureDetector(
          onTap: () => _showLevelDetails(context, level),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isReached
                  ? _getLevelColor(level.tier).withValues(alpha: 0.2)
                  : Colors.grey[200],
              border: Border.all(
                color: isCurrent
                    ? _getLevelColor(level.tier)
                    : (isReached
                    ? _getLevelColor(level.tier).withValues(alpha: 0.5)
                    : Colors.grey[400]!),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      level.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${level.levelNumber}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isCurrent)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getLevelColor(level.tier),
                      ),
                    ),
                  ),
                if (!isReached)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// レベル詳細ダイアログを表示
  void _showLevelDetails(BuildContext context, Level level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              level.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${level.levelNumber}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    level.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 18, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text('${level.requiredXp} Total XP'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rewards',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.monetization_on, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text('+${level.rewardCoins} Coins'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 18, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text('+${level.rewardXp} XP'),
                      ],
                    ),
                    if (level.rewardBadgeId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 18, color: Colors.purple[700]),
                          const SizedBox(width: 8),
                          Text('Unlock: ${level.rewardBadgeId}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
