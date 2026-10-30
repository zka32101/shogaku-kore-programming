import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show onboardingProvider, reviewDueCountProvider, weeklyChallengeProvider;

import '../config/theme.dart' show kPrimaryColor;
import '../screens/wrong_answers_list_screen.dart';
import '../utils/page_transitions.dart';

/// ホーム画面に出す定着率施策（初回7日間の報酬・まちがい復習・週次チャレンジ）。
/// 出すものがなければ何も表示しない（週次チャレンジは常に表示）。
class RetentionSection extends ConsumerWidget {
  const RetentionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);
    final weekly = ref.watch(weeklyChallengeProvider);
    final dueCount = ref.watch(reviewDueCountProvider);
    final claimable = onboarding.claimable;

    return Column(
      children: [
        if (claimable.isNotEmpty) ...[
          Card(
            margin: EdgeInsets.zero,
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎁 はじめての7日間ごほうび（${onboarding.claimedDays.length}/7）',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  for (final r in claimable)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${r.day}日目: ${r.title}',
                          style: const TextStyle(color: Colors.black87)),
                      subtitle: Text(r.description,
                          style: const TextStyle(color: Colors.black54)),
                      trailing: FilledButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final got = await ref
                              .read(onboardingProvider.notifier)
                              .claim(r.day);
                          if (got != null) {
                            messenger.showSnackBar(SnackBar(
                                content: Text('🪙 ${got.coins} コインをもらったよ！')));
                          }
                        },
                        child: Text('🪙 ${r.coins}'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (dueCount > 0) ...[
          // ホームには既に「今日の復習」(ランダム5問) があるので、名前を分けて
          // 「まちがい復習」とし、既存の「にがて問題」画面へ案内する。
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.replay_circle_filled,
                  color: kPrimaryColor, size: 36),
              title: const Text('まちがい復習'),
              subtitle: Text('まちがえた問題 $dueCount問 · 忘れる前にもう一回！'),
              trailing: FilledButton(
                onPressed: () => Navigator.of(context)
                    .push(smoothPageRoute(const WrongAnswersListScreen())),
                child: const Text('はじめる'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekly.isComplete
                      ? '🎉 今週のチャレンジ達成！'
                      : '🎯 今週のチャレンジ：あと${weekly.remaining}問正解',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                    value: weekly.progress, color: kPrimaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
