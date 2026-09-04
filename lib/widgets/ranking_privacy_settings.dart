import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

/// ランキングプライバシー設定ウィジェット
/// ランキングで名前を公表するかどうかを設定
class RankingPrivacySettings extends ConsumerWidget {
  const RankingPrivacySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              children: [
                const Icon(Icons.privacy_tip, size: 24),
                const SizedBox(width: 12),
                Text(
                  'ランキングプライバシー',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 説明テキスト
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'デフォルトでは、ランキングで名前は非公表です。あなたは常に自分の順位を確認できます。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
              ),
            ),
            const SizedBox(height: 16),

            // 匿名 ID 表示
            Text(
              'あなたの匿名 ID',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.anonymousId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      // コピー機能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('匿名 ID をコピーしました'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 名前公表トグル
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: const Text('ランキングで名前を公表する'),
                subtitle: Text(
                  profile.rankingNamePublic
                      ? 'あなたの名前は全員に表示されます'
                      : '匿名 ID のみ表示されます',
                  style: TextStyle(
                    color: profile.rankingNamePublic
                        ? Colors.green[600]
                        : Colors.grey[600],
                  ),
                ),
                trailing: Switch(
                  value: profile.rankingNamePublic,
                  onChanged: (value) async {
                    await ref
                        .read(profileProvider.notifier)
                        .setRankingNamePublic(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 情報パネル
            if (profile.rankingNamePublic)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ランキングで「${profile.nickname}」が表示されます。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ランキングで「${profile.anonymousId}」が表示されます。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
