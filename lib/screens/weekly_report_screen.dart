import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weekly_report_provider.dart';
import '../providers/profile_provider.dart';
import '../services/sound_service.dart';
import '../services/haptic_service.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  bool _reportGenerated = false;

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(weeklyReportProvider);
    final profileState = ref.watch(profileProvider);

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
                    Text('完了ステージ: 0 / 55'),
                    const SizedBox(height: 4),
                    Text('現在レベル: 1'),
                    const SizedBox(height: 4),
                    Text('学習ストリーク: 0 日'),
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

    // サンプルデータ（実装では Providers から取得）
    await ref.read(weeklyReportProvider.notifier).generateReport(
      profileState.nickname ?? 'お子さん',
      5, // completedThisWeek
      10, // totalCompleted
      ['if文', 'ループ'],
      ['配列操作'],
      1, // currentLevel
      0, // streakDays
    );

    setState(() {
      _reportGenerated = true;
    });
  }
}
