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
    final categories = ['quiz', 'progress', 'consistency', 'mastery', 'social', 'special'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('バッジコレクション'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: categories
              .map((category) => Tab(text: _getCategoryLabel(category)))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: categories.map((category) {
          return _buildCategoryView(category, badgeState);
        }).toList(),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _buildBadgeStatsButton(badgeState),
      ),
    );
  }

  /// カテゴリビューを構築
  Widget _buildCategoryView(String category, BadgeState badgeState) {
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
                final currentValue = badge.progressCurrent ?? 0;
                final targetValue = badge.progressTarget ?? 1;
                final remainingValue = (targetValue - currentValue).abs();
                final progressPercentage =
                    (currentValue / targetValue * 100)
                        .clamp(0.0, 100.0);

                return GestureDetector(
                  onTap: () => _showBadgeDetails(badge),
                  child: _buildBadgeCard(badge, currentValue, remainingValue, progressPercentage),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// バッジカードを構築
  Widget _buildBadgeCard(Badge badge, int currentValue, int remainingValue, double progressPercentage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (badge.progressTarget != null && badge.progressTarget! > 0)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercentage / 100,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentValue/${badge.progressTarget}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// バッジ詳細ダイアログを表示
  void _showBadgeDetails(Badge badge) {
    final currentValue = badge.progressCurrent ?? 0;
    final targetValue = badge.progressTarget ?? 1;
    final progressPercentage = (currentValue / targetValue * 100).clamp(0.0, 100.0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(badge.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 説明
              Text(
                badge.description,
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
                      color: _getDifficultyColor(badge.progressTarget ?? 0)
                          .withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Lv.${(badge.progressTarget ?? 0) ~/ 10 + 1}',
                      style: TextStyle(
                        color: _getDifficultyColor(
                          badge.progressTarget ?? 0,
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
                'カテゴリ: ${_getCategoryLabel(badge.category)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // 進捗情報
              if (!badge.isUnlocked) ...[
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
                    value: progressPercentage / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$currentValue/$targetValue (${progressPercentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (currentValue < targetValue) ...[
                  const SizedBox(height: 8),
                  Text(
                    'あと${targetValue - currentValue}で獲得できます',
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
  Widget _buildBadgeStatsButton(BadgeState badgeState) {
    final unlockedCount = badgeState.badges.where((b) => b.isUnlocked).length;
    return FloatingActionButton.extended(
      onPressed: () => _showBadgeStats(badgeState),
      icon: const Icon(Icons.emoji_events),
      label: Text('$unlockedCount個獲得'),
    );
  }

  /// バッジ統計を表示
  void _showBadgeStats(BadgeState badgeState) {
    final totalBadges = badgeState.badges.length;
    final unlockedCount = badgeState.badges.where((b) => b.isUnlocked).length;

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
                    '$unlockedCount/$totalBadges',
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
                value: totalBadges > 0 ? unlockedCount / totalBadges : 0,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '完成度: ${totalBadges > 0 ? (unlockedCount / totalBadges * 100).toStringAsFixed(1) : '0'}%',
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

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'quiz':
        return 'クイズ';
      case 'progress':
        return '進捗';
      case 'consistency':
        return '継続';
      case 'mastery':
        return '習熟';
      case 'social':
        return 'ソーシャル';
      case 'special':
        return 'スペシャル';
      default:
        return category;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'quiz':
        return 'クイズに関連するバッジ';
      case 'progress':
        return '学習の進捗に関連するバッジ';
      case 'consistency':
        return '学習の継続性に関連するバッジ';
      case 'mastery':
        return 'スキル習熟度に関連するバッジ';
      case 'social':
        return 'ランキングやソーシャル機能に関連するバッジ';
      case 'special':
        return 'スペシャルなマイルストーンバッジ';
      default:
        return 'バッジカテゴリー';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'quiz':
        return Icons.quiz;
      case 'progress':
        return Icons.trending_up;
      case 'consistency':
        return Icons.local_fire_department;
      case 'mastery':
        return Icons.star;
      case 'social':
        return Icons.group;
      case 'special':
        return Icons.emoji_events;
      default:
        return Icons.badge;
    }
  }

  Color _getDifficultyColor(int progressTarget) {
    // Use progressTarget value to determine color
    if (progressTarget <= 1) {
      return Colors.brown;
    } else if (progressTarget <= 10) {
      return Colors.grey;
    } else if (progressTarget <= 50) {
      return Colors.amber;
    } else {
      return Colors.purple;
    }
  }

}
