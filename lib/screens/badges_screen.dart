import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';
import '../providers/badge_provider.dart';
import '../widgets/badge_card.dart';

/// バッジ一覧画面
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: BadgeCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeState = ref.watch(badgeProvider);
    final unlockedBadges = ref.watch(unlockedBadgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('バッジコレクション'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: BadgeCategory.values
              .map((category) => Tab(text: _getCategoryLabel(category)))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: BadgeCategory.values.map((category) {
          return _buildCategoryView(category, badgeState);
        }).toList(),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _buildBadgeStatsButton(unlockedBadges),
      ),
    );
  }

  /// カテゴリビューを構築
  Widget _buildCategoryView(BadgeCategory category, BadgeState badgeState) {
    final badges = badgeState.badges.where((b) => b.category == category).toList();

    if (badges.isEmpty) {
      return Center(
        child: Text(
          'このカテゴリにはバッジがありません',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリ説明
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getCategoryDescription(category),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // バッジグリッド
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                final isUnlocked =
                    badgeState.unlockedBadgeIds.contains(badge.id);
                final currentValue =
                    badgeState.badgeProgress[badge.id] ?? 0;
                final remainingValue = (badge.requiredValue - currentValue).abs();
                final progressPercentage =
                    (currentValue / badge.requiredValue * 100)
                        .clamp(0.0, 100.0);

                final badgeInfo = BadgeProgressInfo(
                  badge: badge,
                  currentValue: currentValue,
                  remainingValue: remainingValue,
                  progressPercentage: progressPercentage,
                  isUnlocked: isUnlocked,
                  canUnlock: currentValue >= badge.requiredValue &&
                      !isUnlocked,
                );

                return _buildBadgeDetailCard(badgeInfo);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// バッジ詳細カードを構築
  Widget _buildBadgeDetailCard(BadgeProgressInfo badgeInfo) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badgeInfo),
      child: BadgeCard(
        badgeInfo: badgeInfo,
        showProgress: true,
      ),
    );
  }

  /// バッジ詳細ダイアログを表示
  void _showBadgeDetails(BadgeProgressInfo badgeInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badgeInfo.badge.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(badgeInfo.badge.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 説明
              Text(
                badgeInfo.badge.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // 難易度
              Row(
                children: [
                  Text(
                    '難易度: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _getDifficultyColor(badgeInfo.badge.difficulty)
                          .withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      badgeInfo.badge.difficulty.name.toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(
                          badgeInfo.badge.difficulty,
                        ),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // カテゴリ
              Text(
                'カテゴリ: ${_getCategoryLabel(badgeInfo.badge.category)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // 進捗情報
              if (!badgeInfo.isUnlocked) ...[
                Text(
                  '進捗',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: badgeInfo.progressPercentage / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${badgeInfo.currentValue}/${badgeInfo.badge.requiredValue} (${badgeInfo.progressPercentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (badgeInfo.remainingValue > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'あと${badgeInfo.remainingValue}で獲得できます',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange[600],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'アンロック済み',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (badgeInfo.badge.unlockedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'アンロック日: ${_formatDate(badgeInfo.badge.unlockedAt!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ],

              // ヒント
              if (badgeInfo.badge.hint != null &&
                  badgeInfo.badge.hint!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          badgeInfo.badge.hint!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.blue[600],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// バッジ統計ボタンを構築
  Widget _buildBadgeStatsButton(
    AsyncValue<List<BadgeProgressInfo>> unlockedBadges,
  ) {
    return unlockedBadges.when(
      data: (unlocked) {
        return FloatingActionButton.extended(
          onPressed: () => _showBadgeStats(unlocked),
          icon: const Icon(Icons.emoji_events),
          label: Text('${unlocked.length}個獲得'),
        );
      },
      loading: () => const FloatingActionButton(
        onPressed: null,
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => FloatingActionButton(
        onPressed: null,
        child: const Icon(Icons.error),
      ),
    );
  }

  /// バッジ統計を表示
  void _showBadgeStats(List<BadgeProgressInfo> unlockedBadges) {
    final totalBadges = ref.read(badgeProvider).badges.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バッジ統計'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${unlockedBadges.length}/$totalBadges',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '取得済みバッジ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: unlockedBadges.length / totalBadges,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '完成度: ${(unlockedBadges.length / totalBadges * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.quiz:
        return 'クイズ';
      case BadgeCategory.progress:
        return '進捗';
      case BadgeCategory.consistency:
        return '継続';
      case BadgeCategory.mastery:
        return '習熟';
      case BadgeCategory.social:
        return 'ソーシャル';
      case BadgeCategory.special:
        return 'スペシャル';
    }
  }

  String _getCategoryDescription(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.quiz:
        return 'クイズに関連するバッジ';
      case BadgeCategory.progress:
        return '学習の進捗に関連するバッジ';
      case BadgeCategory.consistency:
        return '学習の継続性に関連するバッジ';
      case BadgeCategory.mastery:
        return 'スキル習熟度に関連するバッジ';
      case BadgeCategory.social:
        return 'ランキングやソーシャル機能に関連するバッジ';
      case BadgeCategory.special:
        return 'スペシャルなマイルストーンバッジ';
    }
  }

  IconData _getCategoryIcon(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.quiz:
        return Icons.quiz;
      case BadgeCategory.progress:
        return Icons.trending_up;
      case BadgeCategory.consistency:
        return Icons.local_fire_department;
      case BadgeCategory.mastery:
        return Icons.star;
      case BadgeCategory.social:
        return Icons.group;
      case BadgeCategory.special:
        return Icons.emoji_events;
    }
  }

  Color _getDifficultyColor(BadgeDifficulty difficulty) {
    return switch (difficulty) {
      BadgeDifficulty.bronze => Colors.brown,
      BadgeDifficulty.silver => Colors.grey,
      BadgeDifficulty.gold => Colors.amber,
      BadgeDifficulty.platinum => Colors.purple,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
