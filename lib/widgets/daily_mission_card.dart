import 'package:flutter/material.dart';
import '../models/daily_mission.dart';
import '../providers/daily_mission_provider.dart';

/// 毎日ミッションカードウィジェット
class DailyMissionCard extends StatelessWidget {
  final DailyMissionProgress missionProgress;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const DailyMissionCard({
    super.key,
    required this.missionProgress,
    this.onComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mission = missionProgress.mission;
    final isCompleted = mission.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isCompleted ? 2 : 4,
        color: isCompleted
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  // ミッションアイコン
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      mission.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // タイトルと説明
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mission.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ステータスアイコン
                  if (isCompleted)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 難易度バッジと報酬
              Row(
                children: [
                  // 難易度
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _getDifficultyColor(mission.difficulty)
                          .withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      mission.difficulty.name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getDifficultyColor(mission.difficulty),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 報酬表示
                  Row(
                    children: [
                      Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${mission.rewardCoins}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '${mission.rewardXp}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // プログレスバー
              if (!isCompleted) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: missionProgress.progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${missionProgress.currentValue}/${mission.targetValue}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${missionProgress.progress.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // 完了時の表示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '完了！報酬を獲得済み',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(MissionDifficulty difficulty) {
    return switch (difficulty) {
      MissionDifficulty.easy => Colors.green,
      MissionDifficulty.normal => Colors.blue,
      MissionDifficulty.hard => Colors.orange,
      MissionDifficulty.extreme => Colors.red,
    };
  }
}

/// 毎日ミッションリスト
class DailyMissionsList extends StatelessWidget {
  final List<DailyMissionProgress> missions;
  final bool showCompleted;
  final VoidCallback? onMissionComplete;
  final EdgeInsetsGeometry padding;

  const DailyMissionsList({
    super.key,
    required this.missions,
    this.showCompleted = true,
    this.onMissionComplete,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Padding(
          padding: padding,
          child: Text(
            'ミッションがありません',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: missions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return DailyMissionCard(
            missionProgress: missions[index],
            onComplete: onMissionComplete,
          );
        },
      ),
    );
  }
}
