import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/challenges_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/auth_provider.dart';
import 'quiz_screen.dart';
import 'editor_screen.dart';
import 'login_screen.dart';
import '../widgets/tap_scale.dart';

/// チャレンジの詳細表示画面
/// チャレンジ情報、難易度、解説などを表示し、チャレンジ開始ボタンを提供
class ChallengeDetailScreen extends ConsumerWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final challengeProgress = progress[challenge.id] ??
        UserProgress(challengeId: challenge.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─────────────────────────────────────────────
            // チャレンジアイコン＆タイトル
            // ─────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    challenge.icon,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─────────────────────────────────────────────
            // チャレンジ情報カード
            // ─────────────────────────────────────────────
            _buildInfoCard(context, [
              _InfoRow(
                icon: '📊',
                label: 'ステージ',
                value: '#${challenge.stageNumber}',
              ),
              _InfoRow(
                icon: '⭐',
                label: '難易度',
                value: _getLevelLabel(challenge.level),
              ),
              _InfoRow(
                icon: '🎯',
                label: 'タイプ',
                value: _getTypeLabel(challenge.type),
              ),
              _InfoRow(
                icon: '⭐',
                label: '最大スター',
                value: '${challenge.maxStars}',
              ),
            ]),
            const SizedBox(height: 16),

            // ─────────────────────────────────────────────
            // ステータス情報
            // ─────────────────────────────────────────────
            if (challengeProgress.isCompleted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '✅ クリア済み',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '⭐ ${challengeProgress.starsEarned}/${challenge.maxStars}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (challengeProgress.completedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '完了日時: ${_formatDate(challengeProgress.completedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─────────────────────────────────────────────
            // 概念説明（Quizの場合）
            // ─────────────────────────────────────────────
            if (challenge.conceptExplanation != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📚 チャレンジの説明',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      challenge.conceptExplanation!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─────────────────────────────────────────────
            // ヒント（Visualの場合）
            // ─────────────────────────────────────────────
            if (challenge.hints.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 ヒント',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...challenge.hints.map((hint) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  hint,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─────────────────────────────────────────────
            // チャレンジ開始ボタン
            // ─────────────────────────────────────────────
            const SizedBox(height: 8),
            TapScale(
              child: ElevatedButton(
                onPressed: () => _startChallenge(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'チャレンジを開始する',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      challengeProgress.isCompleted ? '🔄 再挑戦' : '🎯 開始',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// チャレンジ開始時の処理
  void _startChallenge(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);

    // ─────────────────────────────────────────────────────────
    // 認証チェック
    // ─────────────────────────────────────────────────────────
    if (currentUser == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ログインが必要です'),
          content: const Text('チャレンジに挑戦するにはログインしてください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
              child: const Text('ログイン'),
            ),
          ],
        ),
      );
      return;
    }

    // ─────────────────────────────────────────────────────────
    // チャレンジタイプに応じた画面遷移
    // ─────────────────────────────────────────────────────────
    final destination = challenge.type == ChallengeType.quiz
        ? QuizScreen(challenge: challenge)
        : EditorScreen(challenge: challenge);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  /// チャレンジタイプのラベル取得
  String _getTypeLabel(String type) {
    return type == ChallengeType.quiz ? 'クイズ 📝' : 'ビジュアルプログラミング 🖼️';
  }

  /// 難易度ラベル取得
  String _getLevelLabel(String level) {
    switch (level) {
      case StageLevel.beginner:
        return '初級 🌱';
      case StageLevel.intermediate:
        return '中級 🌿';
      case StageLevel.advanced:
        return '上級 🌳';
      default:
        return level;
    }
  }

  /// 日付フォーマット
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 情報カード構築
  Widget _buildInfoCard(BuildContext context, List<_InfoRow> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          return Column(
            children: [
              entry.value.build(context),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.grey[300]),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 情報行ウィジェット
class _InfoRow {
  final String icon;
  final String label;
  final String value;

  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
