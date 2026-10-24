import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../providers/profile_provider.dart';
import '../providers/challenges_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/weekly_report_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../utils/parent_message.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  bool _reportGenerated = false;

  /// 端末内のデータから、直近7日間の保護者向けまとめを作る。
  ParentWeekSummary _weekSummary(String childName) {
    final notifier = ref.read(progressProvider.notifier);
    return buildParentWeekSummary(
      childName: childName,
      now: DateTime.now(),
      stages: [
        ...ref.read(allChallengesProvider),
        ...ref.read(bugHunterStagesProvider),
      ],
      progress: ref.read(progressProvider),
      wrong: ref.read(wrongAnswersProvider),
      hintStageIds: notifier.hintStageIdsWithin(),
      streakDays: notifier.streakDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(weeklyReportProvider);
    final profileState = ref.watch(profileProvider);
    ref.watch(progressProvider); // 進捗の変化でリビルドさせる
    final progressNotifier = ref.read(progressProvider.notifier);
    final completedCount = progressNotifier.completedCount;
    final currentLevel = progressNotifier.currentLevel;
    final streakDays = progressNotifier.streakDays;
    ref.watch(wrongAnswersProvider); // まちがいの変化でもリビルドさせる
    final parentMessage = buildParentMessage(_weekSummary(profileState.nickname));

    return Scaffold(
      appBar: AppBar(
        title: const Text('📧 週次レポート'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              '保護者向けレポート',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'お子さんの学習進捗をAIが分析し、保護者様向けのレポートを生成します。',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // おうちの人へのメッセージ（通信なし・端末内のデータだけで作る）
            _ParentMessageCard(message: parentMessage),
            const SizedBox(height: 24),

            // レポート生成ボタン
            if (!_reportGenerated && reportState.report == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 学習データ（今週）',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('お子さんの名前: ${profileState.nickname}'),
                    const SizedBox(height: 4),
                    Text('完了ステージ: $completedCount / ${AppConstants.totalStages}'),
                    const SizedBox(height: 4),
                    Text('現在レベル: $currentLevel'),
                    const SizedBox(height: 4),
                    Text('学習ストリーク: $streakDays 日'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: reportState.isLoading
                      ? null
                      : () => _generateReport(context, ref, profileState),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'レポートを生成',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (reportState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],

            // レポート表示
            if (reportState.report != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 今週のレポート',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reportState.report!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'レポート生成日時: ${reportState.lastReportDate?.toLocal().toString().split('.')[0] ?? '今日'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticService.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📧 メール送信機能は準備中です'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('メールで送信'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // エラー表示
            if (reportState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    reportState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport(
    BuildContext context,
    WidgetRef ref,
    dynamic profileState,
  ) async {
    HapticService.lightImpact();
    SoundService().playTap();

    final progressNotifier = ref.read(progressProvider.notifier);
    final completedCount = progressNotifier.completedCount;
    final currentLevel = progressNotifier.currentLevel;
    final streakDays = progressNotifier.streakDays;
    final completedThisWeek = progressNotifier.weeklyActivity(weeks: 1).last;

    final summary = _weekSummary(profileState.nickname ?? 'お子さん');
    await ref.read(weeklyReportProvider.notifier).generateReport(
      profileState.nickname ?? 'お子さん',
      completedThisWeek,
      completedCount, // totalCompleted
      summary.clearedTitles.take(3).toList(), // 得意: 最近クリアしたステージ
      summary.struggledTitles.take(3).toList(), // 苦手: 最近まちがいが多いステージ
      currentLevel,
      streakDays,
    );

    if (!mounted) return;

    setState(() {
      _reportGenerated = true;
    });
  }
}

/// 直近7日間の様子をまとめた、保護者向けのメッセージ。コピーして家族に送れる。
class _ParentMessageCard extends StatelessWidget {
  final ParentMessage message;

  const _ParentMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    Widget section(String title, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('・$item', style: const TextStyle(height: 1.5)),
              ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('parentMessageCard'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💌 おうちの人へ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message.headline,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
          ),
          section('がんばったこと', message.good),
          section('つまずいたところ', message.concerns),
          const SizedBox(height: 12),
          const Text('声かけのヒント', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(message.advice, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('copyParentMessage'),
              onPressed: () {
                HapticService.lightImpact();
                Clipboard.setData(ClipboardData(text: message.toPlainText()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('メッセージをコピーしました'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('コピーする'),
            ),
          ),
        ],
      ),
    );
  }
}
