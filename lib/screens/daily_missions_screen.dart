import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_mission.dart';
import '../providers/daily_mission_provider.dart';
import '../widgets/daily_mission_card.dart';

/// 毎日ミッション画面
class DailyMissionsScreen extends ConsumerStatefulWidget {
  const DailyMissionsScreen({super.key});

  @override
  ConsumerState<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends ConsumerState<DailyMissionsScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final missionState = ref.watch(dailyMissionProvider);
    final incompleteMissions = ref.watch(incompleteMissionsProvider);
    final completedMissions = ref.watch(completedMissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本日のミッション'),
        elevation: 0,
      ),
      body: missionState.todayMissions == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // 統計セクション
            _buildStatsSection(context, missionState.todayMissions!),
            const SizedBox(height: 24),

            // ミッションタブ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'ミッション一覧',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showCompleted = !_showCompleted;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _showCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[200],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        _showCompleted ? '完了済み表示' : '未完了のみ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _showCompleted
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ミッションリスト
            incompleteMissions.when(
              data: (incompleteList) => completedMissions.when(
                data: (completedList) {
                  final displayMissions = _showCompleted
                      ? [...incompleteList, ...completedList]
                      : incompleteList;

                  if (displayMissions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              _showCompleted
                                  ? Icons.task_alt
                                  : Icons.check_circle,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showCompleted
                                  ? 'ミッションがありません'
                                  : '本日のミッションは全て完了です！',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return DailyMissionsList(
                    missions: displayMissions,
                    showCompleted: _showCompleted,
                    onMissionComplete: () {
                      setState(() {});
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('エラー: $error'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('エラー: $error'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 統計セクションを構築
  Widget _buildStatsSection(BuildContext context, DailyMissionSet missionSet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル
          Text(
            '本日の進捗',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 進捗バー
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${missionSet.completedCount}/${missionSet.missions.length}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: missionSet.completionRate,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(missionSet.completionRate * 100).toStringAsFixed(0)}% 完了',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // 報酬情報
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.monetization_on,
                      color: Colors.amber[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${missionSet.totalRewardCoins}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'コイン',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // XP情報
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.star,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${missionSet.totalRewardXp}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'XP',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 完了時のボーナス表示
          if (missionSet.isAllCompleted) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '全ミッション完了！すべての報酬を獲得しました🎉',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
