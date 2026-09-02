import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/models/daily_login_reward.dart';
import 'package:shogaku_kore_programming/providers/daily_login_reward_provider.dart';

/// Daily Login Reward screen displaying streak and claim UI
class DailyRewardScreen extends ConsumerWidget {
  const DailyRewardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardState = ref.watch(dailyLoginRewardProvider);

    if (rewardState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('日次ログインリワード')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (rewardState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('日次ログインリワード')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: ${rewardState.error}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _retryInitialize(context, ref),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('日次ログインリワード'),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStreakHeader(context, ref),
            const SizedBox(height: 24),
            _buildClaimRewardCard(context, ref),
            const SizedBox(height: 24),
            _buildRewardMilestones(context, ref),
            const SizedBox(height: 24),
            _buildStatisticsCard(context, ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHeader(BuildContext context, WidgetRef ref) {
    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'ログインストリーク',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStreakIndicator(
                context,
                'Current',
                currentStreak,
                Icons.flame,
              ),
              Container(
                width: 1,
                height: 80,
                color: Colors.white30,
              ),
              _buildStreakIndicator(
                context,
                'Best',
                longestStreak,
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakIndicator(
    BuildContext context,
    String label,
    int value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.yellow.shade300,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildClaimRewardCard(BuildContext context, WidgetRef ref) {
    final canClaim = ref.watch(canClaimTodayProvider);
    final nextReward = ref.watch(nextRewardProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (nextReward != null) ...[
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextReward.description,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${nextReward.xpAmount} XP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${nextReward.coinAmount} Coins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.yellow.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (canClaim)
                ElevatedButton.icon(
                  onPressed: () => _handleClaimReward(context, ref),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('リワードを獲得'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '本日のリワードは獲得済みです',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardMilestones(BuildContext context, WidgetRef ref) {
    final rewardState = ref.watch(dailyLoginRewardProvider);
    final rewards = rewardState.rewardData?.availableRewards ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'マイルストーン報酬',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...rewards.map((reward) => _buildMilestoneCard(context, reward)).toList(),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(BuildContext context, DailyLoginReward reward) {
    final dayLabel = _getRewardLevelLabel(reward.level);
    final isAchieved = _isRewardAchieved(reward.level);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAchieved ? Colors.green.shade50 : Colors.grey.shade50,
          border: Border.all(
            color: isAchieved ? Colors.green.shade300 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isAchieved ? Icons.check_circle : Icons.lock_clock,
              color: isAchieved ? Colors.green.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isAchieved ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${reward.xpAmount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+${reward.coinAmount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(loginRewardStatsProvider);

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '統計情報',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                context,
                'リワード獲得数',
                '${stats.totalRewardsClaimed}',
                Icons.card_giftcard,
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                '合計 XP 獲得',
                '${stats.totalXpEarned}',
                Icons.bolt,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                '合計コイン獲得',
                '${stats.totalCoinEarned}',
                Icons.paid,
                Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _handleClaimReward(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(dailyLoginRewardProvider.notifier);

    // In a real app, you'd get the actual user ID from authentication
    const userId = 'current_user';

    final claim = await notifier.claimDailyReward(userId);

    if (!context.mounted) return;

    if (claim != null) {
      _showRewardDialog(context, claim);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('リワード獲得に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRewardDialog(BuildContext context, LoginRewardClaim claim) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 リワード獲得！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 40,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ストリーク: ${claim.streakDayAtClaim}日',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${claim.xpEarned} XP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${claim.coinEarned} Coins',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }

  Future<void> _retryInitialize(BuildContext context, WidgetRef ref) async {
    const userId = 'current_user';
    final notifier = ref.read(dailyLoginRewardProvider.notifier);
    await notifier.initializeLoginRewards(userId);
  }

  String _getRewardLevelLabel(RewardLevel level) {
    switch (level) {
      case RewardLevel.day1:
        return '1日目';
      case RewardLevel.day3:
        return '3日連続';
      case RewardLevel.day7:
        return '7日連続';
      case RewardLevel.day14:
        return '14日連続';
      case RewardLevel.day30:
        return '30日連続';
      case RewardLevel.milestone:
        return 'マイルストーン';
    }
  }

  bool _isRewardAchieved(RewardLevel level) {
    // This would typically check against user's actual achieved levels
    // For now, return false for all
    return false;
  }
}
