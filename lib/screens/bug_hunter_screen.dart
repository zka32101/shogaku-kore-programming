import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/progress_provider.dart';
import 'quiz_screen.dart';

/// バグハンター: コードの中のまちがい(バグ)がある行をタップして見つけるステージ群。
class BugHunterScreen extends ConsumerWidget {
  const BugHunterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(bugHunterStagesProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 バグハンター'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'コードの中にかくれた「バグ(まちがい)」を見つけよう！\nまちがっている行をタップして、「確認する」をおすよ。',
            style: TextStyle(fontSize: 14, height: 1.5, color: context.textPrimary),
          ),
          const SizedBox(height: 16),
          for (final stage in stages) ...[
            _StageCard(
              stage: stage,
              stars: progress[stage.id]?.starsEarned ?? 0,
              completed: progress[stage.id]?.isCompleted ?? false,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Stage stage;
  final int stars;
  final bool completed;

  const _StageCard({
    required this.stage,
    required this.stars,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('bugStage_${stage.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QuizScreen(challenge: stage)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(stage.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.description,
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                    if (completed) ...[
                      const SizedBox(height: 6),
                      Text('⭐' * stars.clamp(1, 3),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kPrimaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
