import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_puzzle_provider.dart';
import '../screens/daily_puzzle_screen.dart';

class DailyPuzzleCard extends ConsumerWidget {
  const DailyPuzzleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleState = ref.watch(dailyPuzzleProvider);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DailyPuzzleScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.7),
              Colors.deepOrange.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚡ 今日の詰め問',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                if (puzzleState.solvedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✓ 完了',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              puzzleState.isLoading
                  ? '読み込み中...'
                  : (puzzleState.puzzle?['title'] ?? '詰め問を準備中...'),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            if (puzzleState.streak > 0) ...[
              const SizedBox(height: 6),
              Text(
                '🔥 ${puzzleState.streak}日連続',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
