import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_puzzle_provider.dart';
import '../services/ai_programming_coach_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

class DailyPuzzleScreen extends ConsumerStatefulWidget {
  const DailyPuzzleScreen({super.key});

  @override
  ConsumerState<DailyPuzzleScreen> createState() => _DailyPuzzleScreenState();
}

class _DailyPuzzleScreenState extends ConsumerState<DailyPuzzleScreen> {
  String _userSolution = '';
  String? _feedback;
  bool _submitted = false;
  bool _isEvaluating = false;
  bool _isCorrect = false;
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  Future<void> _submitSolution() async {
    if (_userSolution.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コードを入力してください')),
      );
      return;
    }

    HapticService.lightImpact();

    final puzzle = ref.read(dailyPuzzleProvider).puzzle;

    setState(() {
      _isEvaluating = true;
    });

    final aiService = AIProgrammingCoachService();
    final result = await aiService.evaluatePuzzleSolution(
      problemDescription: puzzle?['description'] as String? ?? '',
      goalBehavior: puzzle?['goalBehavior'] as String? ?? '',
      userCode: _userSolution,
    );

    if (!mounted) return;

    final isCorrect = result['isCorrect'] == true;

    setState(() {
      _isEvaluating = false;
      _submitted = true;
      _isCorrect = isCorrect;
      _feedback = result['feedback'] as String? ?? '';
    });

    if (isCorrect) {
      SoundService().playCorrect();
      // 正解の場合のみストリーク更新
      ref.read(dailyPuzzleProvider.notifier).markSolvedToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(dailyPuzzleProvider);
    final puzzle = puzzleState.puzzle;

    if (puzzleState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('⚡ 今日の詰め問'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (puzzleState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('⚡ 今日の詰め問'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Text('エラー: ${puzzleState.error}'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ 今日の詰め問'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              puzzle?['title'] ?? '詰め問',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 問題文
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
                    '📖 問題',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(puzzle?['description'] ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 初期コード
            if (puzzle != null && puzzle['initialCode'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 初期コード',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      puzzle['initialCode'] as String,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 目標
            if (puzzle != null && puzzle['goalBehavior'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 目標',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(puzzle['goalBehavior'] as String),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ヒント
            if (puzzle != null && puzzle['hint'] != null)
              ExpansionTile(
                title: const Text('💡 ヒント'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(puzzle['hint'] as String),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // 解答入力
            if (!_submitted) ...[
              const Text(
                'あなたのコードを入力してください',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                onChanged: (v) => setState(() => _userSolution = v),
                maxLines: 6,
                style: const TextStyle(fontFamily: 'Courier'),
                decoration: InputDecoration(
                  hintText: '// ここにコードを書いてください',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEvaluating ? null : _submitSolution,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isEvaluating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '✓ 解答を送信',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],

            // 結果表示
            if (_submitted && _feedback != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isCorrect ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_isCorrect ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCorrect ? '🎉 良い解答です！' : '🤔 もう少し！',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_feedback!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCorrect
                      ? () => Navigator.of(context).pop()
                      : () {
                          setState(() {
                            _submitted = false;
                            _feedback = null;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isCorrect ? Colors.green : Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _isCorrect ? '✓ 完了' : 'もう一度挑戦する',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
