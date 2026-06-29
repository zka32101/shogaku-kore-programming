import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../services/ai_programming_coach_service.dart';

class ReverseTeachingScreen extends ConsumerStatefulWidget {
  const ReverseTeachingScreen({super.key});

  @override
  ConsumerState<ReverseTeachingScreen> createState() =>
      _ReverseTeachingScreenState();
}

class _ReverseTeachingScreenState extends ConsumerState<ReverseTeachingScreen> {
  final List<_ReverseQuestion> _questions = [
    _ReverseQuestion(
      topic: 'if文（分岐）',
      wrongStatement: 'if (x = 5) { print("等しい"); }',
      difficulty: '初級',
      hint: '比較と代入の違いをチェック',
    ),
    _ReverseQuestion(
      topic: 'ループ（for）',
      wrongStatement: 'for (int i = 0; i < 5; i--) { print(i); }',
      difficulty: '初級',
      hint: 'ループの進行方向をチェック',
    ),
    _ReverseQuestion(
      topic: '配列のアクセス',
      wrongStatement: 'int[] arr = {1, 2, 3}; print(arr[3]);',
      difficulty: '中級',
      hint: 'インデックスは0から始まる',
    ),
  ];

  int _currentIndex = 0;
  String _studentExplanation = '';
  String? _aiEvaluation;
  bool _isLoading = false;
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

  Future<void> _submitExplanation() async {
    if (_studentExplanation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('説明を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final aiService = AIProgrammingCoachService();
    final q = _questions[_currentIndex];

    final evaluation = await aiService.evaluateStudentExplanation(
      topic: q.topic,
      studentExplanation: _studentExplanation,
      difficulty: q.difficulty,
    );

    setState(() {
      _aiEvaluation = evaluation;
      _isLoading = false;
    });

    HapticService.lightImpact();
  }

  void _nextQuestion() {
    HapticService.selectionClick();
    SoundService().playCorrect();

    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _studentExplanation = '';
        _aiEvaluation = null;
        _textController?.clear();
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 完了！'),
        content: const Text('全ての問題を説明しました。\nこれからも頑張ってね！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AIに教える逆転モード'),
        backgroundColor: const Color(0xFF9B59B6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 進捗
            Text(
              '問題 ${_currentIndex + 1} / ${_questions.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 6,
            ),
            const SizedBox(height: 24),

            // 題目
            Text(
              '【${q.topic}】',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // 間違ったコード表示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'このコードは間違っています。何が問題か説明してください。',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      q.wrongStatement,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ヒント
            ExpansionTile(
              title: const Text('💡 ヒント'),
              children: [
                Text(q.hint),
              ],
            ),
            const SizedBox(height: 24),

            // 説明入力
            Text(
              '説明を入力してください',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              onChanged: (v) => setState(() => _studentExplanation = v),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '例：「if の条件に = を使ってるから、代入になってる。比較するなら == を使うべき」',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),

            // 送信ボタン
            if (_aiEvaluation == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitExplanation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B59B6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'AIに評価してもらう',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

            // AI評価表示
            if (_aiEvaluation != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤖 AIの評価',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(_aiEvaluation!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('次へ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

class _ReverseQuestion {
  final String topic;
  final String wrongStatement;
  final String difficulty;
  final String hint;

  _ReverseQuestion({
    required this.topic,
    required this.wrongStatement,
    required this.difficulty,
    required this.hint,
  });
}
