import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../services/sound_service.dart';
import '../widgets/code_highlight.dart';
import 'quiz_result_screen.dart';
import 'quiz_review_screen.dart';
import 'badge_unlock_screen.dart';
import '../widgets/shortcut_help.dart';
import '../widgets/app_dialog.dart';

// ── タイムアタックモード ─────────────────────────────────────────────────────
// 全ステージから最大10問をランダムに抽出し、1問30秒で回答するモード。
// 残り時間に応じてボーナス点 (0〜3) を付与する。

class TimeAttackScreen extends ConsumerStatefulWidget {
  /// true の場合、起動時に苦手問題モードを選択した状態で開始する
  final bool initialWeakMode;

  const TimeAttackScreen({super.key, this.initialWeakMode = false});

  @override
  ConsumerState<TimeAttackScreen> createState() => _TimeAttackScreenState();
}

class _TimeAttackScreenState extends ConsumerState<TimeAttackScreen>
    with SingleTickerProviderStateMixin {
  static const int _questionCount  = 10;
  static const int _defaultSeconds = 30;

  // 難易度: 0=やさしい(45s), 1=ふつう(30s), 2=むずかしい(20s)
  static const List<int> _difficultySeconds = [45, 30, 20];
  static const List<String> _difficultyLabels = ['🌱 やさしい', '🔥 ふつう', '⚡ むずかしい'];

  String? _selectedLevel; // null = 全て、'__weak__' = 苦手問題モード
  int _selectedDifficulty = 1; // ふつう
  int get _secondsPerQ => _difficultySeconds[_selectedDifficulty];

  List<_TAQuestion> _questions = [];
  int _currentIndex     = 0;
  int? _selectedIndex;
  bool _hasAnswered     = false;
  bool _isCorrect       = false;
  int _score            = 0;          // 正解数
  int _totalBonus       = 0;          // 合計タイムボーナス
  int _combo            = 0;          // 現在の連続正解数
  int _maxCombo         = 0;          // 今回プレイの最大コンボ
  bool _showComboAnim   = false;      // コンボ演出表示フラグ
  double _timeLeft      = _defaultSeconds.toDouble();
  bool _urgentHapticFired = false;    // 緊急ハプティック発火済みフラグ
  bool _flagged = false;              // 現在の問題を苦手フラグ済み
  DateTime? _sessionStart;            // セッション開始時刻（学習時間計測用）
  bool _timeRecorded = false;         // 学習時間の二重記録防止フラグ
  Timer? _timer;
  Timer? _timeoutAdvanceTimer;        // タイムアウト後の自動次問タイマー
  final FocusNode _focusNode = FocusNode(); // キーボードショートカット用

  // カウントダウンバーアニメーション
  late AnimationController _barController;
  late Animation<double> _barAnim;

  final List<_TAResult> _results = [];

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _defaultSeconds),
    );
    _barAnim = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _barController, curve: Curves.linear));

    // レベル選択 → 問題抽出 → スタート
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 前回の難易度選択を復元
      final savedDifficulty = ref.read(timeAttackProvider).selectedDifficulty;
      setState(() => _selectedDifficulty = savedDifficulty);
      if (widget.initialWeakMode) {
        // 苦手問題モードで直接開始
        setState(() => _selectedLevel = '__weak__');
        _buildQuestions();
        _sessionStart = DateTime.now();
        _startQuestion();
        _focusNode.requestFocus();
      } else {
        _showLevelPicker();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeoutAdvanceTimer?.cancel();
    // 通常完了以外（中途終了）の場合も学習時間を記録
    if (!_timeRecorded && _sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
      if (elapsed >= 5) {
        ref.read(progressProvider.notifier).recordLearningSeconds(elapsed);
      }
    }
    _barController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_questions.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // 回答済みのとき: Enter/Space で次へ
    if (_hasAnswered) {
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
        _nextQuestion();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Tab / Shift+Tab で選択肢を順送り / 逆送り
    if (key == LogicalKeyboardKey.tab) {
      final q = _questions[_currentIndex];
      final optCount = q.question.options.length;
      if (HardwareKeyboard.instance.isShiftPressed) {
        final next = _selectedIndex == null
            ? optCount - 1
            : (_selectedIndex! - 1 + optCount) % optCount;
        setState(() => _selectedIndex = next);
      } else {
        final next = _selectedIndex == null
            ? 0
            : (_selectedIndex! + 1) % optCount;
        setState(() => _selectedIndex = next);
      }
      HapticService.selectionClick();
      return KeyEventResult.handled;
    }

    // 未回答: 1/2/3/4 で選択肢を選ぶ
    final numMap = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.digit1: 0,
      LogicalKeyboardKey.digit2: 1,
      LogicalKeyboardKey.digit3: 2,
      LogicalKeyboardKey.digit4: 3,
      LogicalKeyboardKey.numpad1: 0,
      LogicalKeyboardKey.numpad2: 1,
      LogicalKeyboardKey.numpad3: 2,
      LogicalKeyboardKey.numpad4: 3,
    };
    final idx = numMap[key];
    if (idx != null) {
      final q = _questions[_currentIndex];
      if (idx < q.question.options.length) {
        _selectOption(idx);
        return KeyEventResult.handled;
      }
    }

    // Enter/Space で確定
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_selectedIndex != null) {
        _submitAnswer();
        return KeyEventResult.handled;
      }
    }

    // F → 苦手フラグ（苦手リストに追加）
    if (key == LogicalKeyboardKey.keyF && !_flagged) {
      _flagCurrentQuestion();
      return KeyEventResult.handled;
    }

    // Esc / Backspace → ゲームを終了（確認ダイアログ）
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      _confirmExit();
      return KeyEventResult.handled;
    }

    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('1 〜 4', '選択肢を選ぶ'),
        ('Tab / Shift+Tab', '選択肢を順送り / 逆送り'),
        ('Enter / Space', '確定 / 次へ'),
        ('F', '苦手リストに追加'),
        ('Esc / BS', 'ゲームを終了して戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// 現在の問題を苦手リストに追加する（Fキー・ヘッダーのボタン共通ロジック）
  void _flagCurrentQuestion() {
    HapticService.lightImpact();
    final q = _questions[_currentIndex];
    ref.read(wrongAnswersProvider.notifier).addWrongAnswers([
      QuizAnswer(
        questionText: q.question.text,
        isCorrect: false,
        selectedAnswer: '📌 手動追加',
        correctAnswer: q.question.options[q.question.correctIndex],
        explanation: q.question.explanation,
        codeSnippet: q.question.codeSnippet,
        hintUsed: false,
      ),
    ]);
    setState(() => _flagged = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📌 苦手リストに追加しました'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────

  Future<void> _showLevelPicker() async {
    final taState = ref.read(timeAttackProvider);
    int dialogDifficulty = _selectedDifficulty;
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '⚡ タイムアタック',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 難易度選択
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '難易度',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(_difficultyLabels.length, (i) {
                final selected = dialogDifficulty == i;
                final colors = [Colors.green, const Color(0xFFE67E22), Colors.red];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    child: GestureDetector(
                      onTap: () {
                        HapticService.selectionClick();
                        setDialogState(() => dialogDifficulty = i);
                        ref.read(timeAttackProvider.notifier).setDifficulty(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors[i].withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? colors[i]
                                : Colors.grey.withValues(alpha: 0.3),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _difficultyLabels[i].split(' ')[0],
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              _difficultyLabels[i].split(' ')[1],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? colors[i] : kTextSecondary,
                              ),
                            ),
                            Text(
                              '${_difficultySeconds[i]}秒',
                              style: TextStyle(
                                fontSize: 9,
                                color: selected ? colors[i] : kTextSecondary,
                              ),
                            ),
                            if (taState.bestScoreByDifficulty[i] > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '🏅${taState.bestScoreByDifficulty[i]}pt',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? colors[i] : kTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text(
              'レベルを選んでね',
              style: TextStyle(color: kTextSecondary),
            ),
            if (taState.playCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE67E22).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 18)),
                        Text(
                          'ベスト ${taState.bestCorrect}/$_questionCount問',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('🎮', style: TextStyle(fontSize: 18)),
                        Text(
                          '${taState.playCount}回プレイ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 苦手問題モード（苦手リストが空でない場合のみ表示）
            Builder(builder: (context) {
              final wrongState = ref.read(wrongAnswersProvider);
              if (wrongState.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedDifficulty = dialogDifficulty);
                      Navigator.pop(ctx, '__weak__');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '🔥 苦手問題モード (${wrongState.count}問)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
            const Divider(height: 16),
            ...{
              '🌐 全レベル': '__all__',
              '🧩 初級': StageLevel.beginner,
              '🐍 中級': StageLevel.intermediate,
              '🚀 上級': StageLevel.advanced,
            }.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedDifficulty = dialogDifficulty);
                      Navigator.pop(ctx, e.value);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(e.key),
                  ),
                ),
              );
            }),
          ],
        ),
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
      return;
    }
    _selectedLevel = result == '__all__' ? null : result as String?;
    _buildQuestions();
    _sessionStart = DateTime.now();
    _startQuestion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _buildQuestions() {
    // 苦手問題モード: wrongAnswersProvider の問題のみを使用
    if (_selectedLevel == '__weak__') {
      final wrongState = ref.read(wrongAnswersProvider);
      final allChallenges = ref.read(allChallengesProvider);
      final wrongTexts = wrongState.answers.map((a) => a.questionText).toSet();
      final allQs = <_TAQuestion>[];
      for (final c in allChallenges) {
        if (c.type == 'quiz') {
          final questions = c.questions ?? [];
          for (final q in questions) {
            if (wrongTexts.contains(q.text)) {
              allQs.add(_TAQuestion(question: q, challengeTitle: c.title));
            }
          }
        }
      }
      // 頻度降順でソートしてから最大_questionCount問
      allQs.sort((a, b) => wrongState
          .wrongCountFor(b.question.text)
          .compareTo(wrongState.wrongCountFor(a.question.text)));
      _questions = allQs.take(_questionCount).toList();
      return;
    }

    final allChallenges = ref.read(allChallengesProvider);
    // クイズ形式かつ質問が1問以上あるステージから全問を収集（レベルフィルター適用）
    final allQs = <_TAQuestion>[];
    for (final c in allChallenges) {
      if (c.type == 'quiz' &&
          (_selectedLevel == null || c.level == _selectedLevel)) {
        final questions = c.questions ?? [];
        for (final q in questions) {
          allQs.add(_TAQuestion(question: q, challengeTitle: c.title));
        }
      }
    }
    // シャッフルして最大_questionCount問
    allQs.shuffle(math.Random());
    _questions = allQs.take(_questionCount).toList();
  }

  void _startQuestion() {
    _timeLeft = _secondsPerQ.toDouble();
    _urgentHapticFired = false;
    _barController.duration = Duration(seconds: _secondsPerQ);
    _barController.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (!_urgentHapticFired && _timeLeft <= _secondsPerQ * 0.25 && _timeLeft > 0) {
        _urgentHapticFired = true;
        HapticService.mediumImpact();
      }
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        t.cancel();
        _barController.stop();
        if (!_hasAnswered) _handleTimeout();
      }
    });
  }

  Future<void> _confirmExit() async {
    // ゲーム未開始 or 完了後はそのまま戻る
    if (_questions.isEmpty || _currentIndex == 0 && _score == 0 && !_hasAnswered) {
      _timer?.cancel();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _timer?.cancel();
    _barController.stop();
    final progress = _currentIndex + (_hasAnswered ? 1 : 0);
    final confirmed = await AppDialog.confirm(
      context,
      emoji: '⏱️',
      title: 'タイムアタックをやめる？',
      message: '$progress / ${_questions.length} 問まで進んでいるよ。\nやめるとスコアは保存されないよ。',
      okLabel: 'やめる',
      cancelLabel: 'つづける',
      danger: true,
    );
    if (confirmed) {
      if (mounted) Navigator.of(context).pop();
    } else {
      // タイマー再開
      _startQuestion();
    }
  }

  void _handleTimeout() {
    final q = _questions[_currentIndex];
    SoundService().playWrong();
    _results.add(_TAResult(
      questionText: q.question.text,
      isCorrect: false,
      timeBonus: 0,
      selectedAnswer: '⏰ 時間切れ',
      correctAnswer: q.question.options[q.question.correctIndex],
      explanation: q.question.explanation,
      codeSnippet: q.question.codeSnippet,
    ));
    setState(() {
      _hasAnswered = true;
      _isCorrect = false;
      _combo = 0;
      _showComboAnim = false;
    });
    _timeoutAdvanceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _nextQuestion();
    });
  }

  void _selectOption(int index) {
    if (_hasAnswered) return;
    SoundService().playTap();
    setState(() => _selectedIndex = index);
  }

  Future<void> _submitAnswer() async {
    if (_selectedIndex == null || _hasAnswered) return;
    _timer?.cancel();
    _barController.stop();

    final q = _questions[_currentIndex];
    final correct = _selectedIndex == q.question.correctIndex;
    final bonus = _calcBonus(_timeLeft);

    if (correct) {
      _score++;
      _totalBonus += bonus;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      // コンボボーナス（3連続ごとに+1）
      if (_combo >= 3 && _combo % 3 == 0) {
        _totalBonus += 1;
      }
      HapticService.lightImpact();
      if (_combo >= 2) {
        SoundService().playCombo(_combo);
      } else {
        SoundService().playCorrect();
      }
      // 苦手リストにある問題を正解したらカウントを減らす（完全克服でボーナスポイント）
      final resolved = await ref.read(wrongAnswersProvider.notifier).markCorrect(q.question.text);
      if (resolved) {
        ref.read(progressProvider.notifier).addBonusPoints(5);
      }
    } else {
      _combo = 0;
      HapticService.mediumImpact();
      SoundService().playWrong();
    }

    _results.add(_TAResult(
      questionText: q.question.text,
      isCorrect: correct,
      timeBonus: correct ? bonus : 0,
      selectedAnswer: q.question.options[_selectedIndex!],
      correctAnswer: q.question.options[q.question.correctIndex],
      explanation: q.question.explanation,
      codeSnippet: q.question.codeSnippet,
    ));

    setState(() {
      _hasAnswered = true;
      _isCorrect = correct;
      _showComboAnim = correct && _combo >= 2;
    });
  }

  void _nextQuestion() {
    _timeoutAdvanceTimer?.cancel();
    _timer?.cancel();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _hasAnswered = false;
        _isCorrect = false;
        _flagged = false;
      });
      _startQuestion();
    } else {
      _showResult();
    }
  }

  Future<void> _showResult() async {
    if (_score > 0) SoundService().playComplete();

    // recordResult() が provider state を更新する前に「更新前」の値を退避しておく。
    // （更新後に taState から逆算すると isNewRecord==true のケースで old==new に潰れてしまうため）
    final oldBestCorrect = ref.read(timeAttackProvider).bestCorrect;
    final oldBestCombo = ref.read(timeAttackProvider).bestMaxCombo;

    final (isNewRecord, isNewCombo) = await ref
        .read(timeAttackProvider.notifier)
        .recordResult(score: _score, bonus: _totalBonus, difficulty: _selectedDifficulty, maxCombo: _maxCombo);

    // 不正解問題を苦手リストに保存
    final wrongList = _results
        .where((r) => !r.isCorrect)
        .map((r) => QuizAnswer(
              questionText: r.questionText,
              isCorrect: false,
              selectedAnswer: r.selectedAnswer,
              correctAnswer: r.correctAnswer,
              explanation: r.explanation,
              codeSnippet: r.codeSnippet,
            ))
        .toList();
    if (wrongList.isNotEmpty) {
      await ref.read(wrongAnswersProvider.notifier).addWrongAnswers(wrongList);
    }

    // 累計回答数・学習時間を記録（dispose時の二重記録防止）
    _timeRecorded = true;
    final prevAnswered = ref.read(progressProvider.notifier).totalQuestionsAnswered;
    await ref.read(progressProvider.notifier).recordQuestionsAnswered(_results.length);
    final newAnswered = ref.read(progressProvider.notifier).totalQuestionsAnswered;
    // アクティビティログに記録（タイムアタックのカレンダー反映）
    await ref.read(progressProvider.notifier).recordActivity();
    (String, String, String, String)? learningBadge;
    if (_sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
      if (elapsed > 0) {
        learningBadge = await ref.read(progressProvider.notifier).recordLearningSeconds(elapsed);
      }
    }

    // TAマイルストーンバッジ（プレイ数・スコア・コンボ）
    final taState = ref.read(timeAttackProvider);
    final newPlayCount = taState.playCount;
    final taBadges = <(String, String, String, String)>[];

    // プレイ数バッジ
    if (newPlayCount == 1) {
      taBadges.add(('⚡', 'タイムアタック参戦', 'タイムアタックに初挑戦！スピードの世界へようこそ！', '10回挑戦でスピードランナーバッジ獲得！'));
    } else if (newPlayCount == 10) {
      taBadges.add(('🏎️', 'スピードランナー', 'タイムアタック10回達成！本物のスピードランナー！', '記録更新を目指そう！'));
    }
    // スコアバッジ（このゲームのスコアが基準を超え、かつ以前は超えていなかった場合）
    if (_score >= 10 && oldBestCorrect < 10) {
      taBadges.add(('⚡', 'ライトニングクイズ', 'タイムアタック全問正解！パーフェクトスコア！', '記録を維持しよう！'));
    } else if (_score >= 8 && oldBestCorrect < 8) {
      taBadges.add(('🔥', 'タイムアタック達人', 'タイムアタックで8問以上正解！達人の域！', '全問正解を目指そう！'));
    }
    // コンボバッジ（このゲームのコンボが基準を超え、かつ以前は超えていなかった場合）
    if (_maxCombo >= 10 && oldBestCombo < 10) {
      taBadges.add(('🌟', 'コンボ神業', 'タイムアタック全問コンボ達成！圧倒的な集中力！', '次も記録更新を目指せ！'));
    } else if (_maxCombo >= 5 && oldBestCombo < 5) {
      taBadges.add(('🔥', 'コンボ5連続', 'タイムアタックで5問連続正解！素晴らしいリズム！', '10連続コンボを目指そう！'));
    }
    // 累計回答数マイルストーンバッジ
    const qMilestones = [
      (100,  '📝', '100問挑戦！',    '累計100問に回答達成！', '次は500問を目指そう！'),
      (500,  '📚', '500問達成！',    '累計500問に回答！本格的なコーダー！', '次は1000問を目指そう！'),
      (1000, '🧠', '1000問マスター！', '累計1000問に回答！あなたはコードマスター！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in qMilestones) {
      if (prevAnswered < target && newAnswered >= target) {
        taBadges.add((icon, name, message, goal));
        break;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _TimeAttackResultScreen(
          score: _score,
          total: _questions.length,
          totalBonus: _totalBonus,
          maxCombo: _maxCombo,
          results: _results,
          isNewRecord: isNewRecord,
          isNewCombo: isNewCombo,
          difficulty: _selectedDifficulty,
          learningBadge: learningBadge,
          taBadges: taBadges,
        ),
      ),
    );
  }

  int _calcBonus(double timeLeft) {
    if (timeLeft > _secondsPerQ * 0.7) return 3;   // 残り70%以上: ボーナス3
    if (timeLeft > _secondsPerQ * 0.4) return 2;   // 残り40%以上: ボーナス2
    if (timeLeft > 0) return 1;                      // 残りわずか: ボーナス1
    return 0;
  }

  Widget _buildComboBanner() {
    final (emoji, label) = switch (_combo) {
      >= 7 => ('🌟', '$_combo連続！神業コンボ！'),
      >= 5 => ('🔥', '$_combo連続！すごいコンボ！'),
      >= 3 => ('⚡', '$_combo連続コンボ！'),
      _    => ('✨', '$_combo連続正解！'),
    };
    final color = _combo >= 5
        ? const Color(0xFFE74C3C)
        : _combo >= 3
            ? const Color(0xFFE67E22)
            : const Color(0xFF27AE60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (_combo >= 3) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+1ボーナス！',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = _questions[_currentIndex];
    final isUrgent = _timeLeft <= _secondsPerQ * 0.25;
    final urgentColor = isUrgent ? Colors.red : kPrimaryColor;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── ヘッダー
            _buildHeader(urgentColor, isUrgent),
            // ─── コンボバナー
            if (_showComboAnim)
              _buildComboBanner()
                  .animate(key: ValueKey(_combo))
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: -0.3, curve: Curves.easeOut, duration: 200.ms),
            // ─── カウントダウンバー
            AnimatedBuilder(
              animation: _barAnim,
              builder: (context, child) => _buildTimerBar(isUrgent),
            ),
            // ─── 問題エリア
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  key: ValueKey(_currentIndex),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ソース（どのステージの問題か）
                    Text(
                      '📌 ${q.challengeTitle}',
                      style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    ),
                    const SizedBox(height: 6),
                    // 問題文
                    Text(
                      q.question.text,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // コードスニペット
                    if (q.question.codeSnippet != null) ...[
                      CodeHighlightWidget(code: q.question.codeSnippet!),
                      const SizedBox(height: 12),
                    ],
                    // 選択肢
                    ...q.question.options.asMap().entries.map((e) {
                      final i = e.key;
                      final opt = e.value;
                      return _OptionTile(
                        label: String.fromCharCode(65 + i),
                        text: opt,
                        isSelected: _selectedIndex == i,
                        isCorrect: _hasAnswered && i == q.question.correctIndex,
                        isWrong: _hasAnswered && _selectedIndex == i && i != q.question.correctIndex,
                        onTap: () => _selectOption(i),
                      ).animate(delay: Duration(milliseconds: 60 * i))
                          .fadeIn(duration: 220.ms)
                          .slideX(begin: 0.05, curve: Curves.easeOut, duration: 220.ms);
                    }),
                    // 解説
                    if (_hasAnswered) ...[
                      const SizedBox(height: 12),
                      _buildExplanation(q.question.explanation, _isCorrect),
                    ],
                    const SizedBox(height: 80),
                  ],
                ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.05, curve: Curves.easeOut, duration: 250.ms),
              ),
            ),
            // ─── ボタン
            _buildButtons(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(Color urgentColor, bool isUrgent) {
    final secsLeft = _timeLeft.ceil();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUrgent
              ? [Colors.red.shade700, Colors.red.shade900]
              : [kPrimaryColor, kPrimaryDark],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _confirmExit,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '⚡ タイムアタック',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_selectedLevel == '__weak__') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.7)),
                        ),
                        child: const Text(
                          '🔥 苦手',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '問${_currentIndex + 1} / ${_questions.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          // 苦手フラグボタン（タッチ操作でも押せるように）
          Tooltip(
            message: _flagged ? '苦手リストに追加済み' : '苦手リストに追加',
            child: GestureDetector(
              onTap: _flagged ? null : _flagCurrentQuestion,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _flagged
                      ? Colors.red.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.25),
                ),
                child: Center(
                  child: Text(
                    _flagged ? '🚩' : '🏳️',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // スコア表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '✅ $_score',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // タイマー数字
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.white : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$secsLeft',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isUrgent ? Colors.red.shade800 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar(bool isUrgent) {
    return AnimatedBuilder(
      animation: _barAnim,
      builder: (context, child) {
        final frac = (_timeLeft / _secondsPerQ).clamp(0.0, 1.0);
        return SizedBox(
          height: 6,
          child: LinearProgressIndicator(
            value: frac,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isUrgent ? Colors.red : kPrimaryColor,
            ),
            minHeight: 6,
          ),
        );
      },
    );
  }

  Widget _buildExplanation(String explanation, bool isCorrect) {
    final bonus = isCorrect ? _calcBonus(_timeLeft) : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? kPrimaryColor.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? kPrimaryColor : Colors.red,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isCorrect ? '✅ 正解！' : '❌ 不正解',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? kPrimaryColor : Colors.red,
                ),
              ),
              if (isCorrect && bonus > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 2),
                      Text(
                        'ボーナス +$bonus',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: TextStyle(fontSize: 12, color: context.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final isLast = _currentIndex == _questions.length - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Row(
          key: ValueKey(_hasAnswered),
          children: [
            if (!_hasAnswered) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedIndex != null ? _submitAnswer : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('⚡ 確認する', style: TextStyle(fontSize: 15)),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isLast ? '結果を見る' : '次へ',
                      style: const TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 結果画面 ──────────────────────────────────────────────────────────────────

class _TimeAttackResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final int totalBonus;
  final int maxCombo;
  final List<_TAResult> results;
  final bool isNewRecord;
  final bool isNewCombo;
  final int difficulty; // 0=やさしい, 1=ふつう, 2=むずかしい
  final (String, String, String, String)? learningBadge;
  final List<(String, String, String, String)> taBadges;

  const _TimeAttackResultScreen({
    required this.score,
    required this.total,
    required this.totalBonus,
    required this.maxCombo,
    required this.results,
    required this.isNewRecord,
    this.isNewCombo = false,
    required this.difficulty,
    this.learningBadge,
    this.taBadges = const [],
  });

  @override
  ConsumerState<_TimeAttackResultScreen> createState() =>
      _TimeAttackResultScreenState();
}

class _TimeAttackResultScreenState
    extends ConsumerState<_TimeAttackResultScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      var delay = 2000;
      if (widget.learningBadge != null) {
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          final b = widget.learningBadge!;
          showBadgeUnlock(
            context,
            icon: b.$1,
            name: b.$2,
            message: b.$3,
            points: 50,
            nextGoal: b.$4,
            onContinue: () {},
          );
        });
        delay += 3500;
      }
      for (final b in widget.taBadges) {
        final d = delay;
        Future.delayed(Duration(milliseconds: d), () {
          if (!mounted) return;
          showBadgeUnlock(
            context,
            icon: b.$1,
            name: b.$2,
            message: b.$3,
            points: 30,
            nextGoal: b.$4,
            onContinue: () {},
          );
        });
        delay += 3500;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // Enter/Space/R → もう一度
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.keyR) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TimeAttackScreen()),
      );
      return KeyEventResult.handled;
    }
    // W → 間違えた問題を復習
    if (key == LogicalKeyboardKey.keyW) {
      final wrongAnswers = widget.results
          .where((r) => !r.isCorrect)
          .map((r) => QuizAnswer(
                questionText: r.questionText,
                isCorrect: false,
                selectedAnswer: r.selectedAnswer,
                correctAnswer: r.correctAnswer,
                explanation: r.explanation,
                codeSnippet: r.codeSnippet,
              ))
          .toList();
      if (wrongAnswers.isNotEmpty) {
        HapticService.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizReviewScreen(wrongAnswers: wrongAnswers),
          ),
        );
        return KeyEventResult.handled;
      }
    }
    // S → スコアをコピー
    if (key == LogicalKeyboardKey.keyS) {
      _shareScore(context);
      return KeyEventResult.handled;
    }
    // Esc/Backspace → ホームへ
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('Enter / Space / R', 'もう一度プレイ'),
        ('W', '間違えた問題を復習'),
        ('S', 'スコアをコピー'),
        ('Esc / Backspace', 'ホームへ戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Local aliases for widget properties (convenience)
    final score = widget.score;
    final total = widget.total;
    final totalBonus = widget.totalBonus;
    final maxCombo = widget.maxCombo;
    final results = widget.results;
    final isNewRecord = widget.isNewRecord;

    final percent = total > 0 ? score / total : 0.0;
    final rank = _rank(percent, totalBonus);
    final taState = ref.watch(timeAttackProvider);
    final totalPt = score + totalBonus;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── ランクヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C3483), Color(0xFF9B59B6)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '⚡ タイムアタック結果',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      if (isNewRecord) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🎉 新記録！',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ).animate(delay: 500.ms)
                          .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 500.ms)
                          .fadeIn(duration: 200.ms),
                      ],
                      if (widget.isNewCombo && !isNewRecord) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🔥 コンボ新記録！',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ).animate(delay: 500.ms)
                          .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 500.ms)
                          .fadeIn(duration: 200.ms),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rank.emoji,
                    style: const TextStyle(fontSize: 56),
                  ).animate().scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                    duration: 700.ms,
                  ),
                  Text(
                    rank.label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ResultChip('正解数', '$score / $total', '✅',
                              subtitle: '${(percent * 100).round()}%')
                          .animate(delay: 320.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut, duration: 300.ms),
                      _ResultChip('ボーナス', '+$totalBonus', '⚡')
                          .animate(delay: 380.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut, duration: 300.ms),
                      _ResultChip('最大コンボ', '$maxCombo連続', '🔥')
                          .animate(delay: 420.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut, duration: 300.ms),
                      _ResultChip('合計', '${totalPt}pt', '🏆')
                          .animate(delay: 460.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut, duration: 300.ms),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ベストスコア表示
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          'ベスト: ${taState.bestScore}pt'
                          '  (${taState.playCount}回プレイ)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 直近スコアトレンド
                  if (taState.recentScores.length >= 3) ...[
                    const SizedBox(height: 6),
                    _buildScoreTrend(taState.recentScores),
                    const SizedBox(height: 6),
                  ],
                  // 問題別正誤ドット
                  const SizedBox(height: 8),
                  _buildAccuracyDots(results),
                  const SizedBox(height: 8),
                  // 難易度別ベストスコア
                  _buildDifficultyRecords(taState),
                ],
              ),
            ),

            // ─── 問題リスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (ctx, i) {
                  final r = results[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ctx.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: r.isCorrect
                            ? kPrimaryColor.withValues(alpha: 0.4)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.isCorrect ? '✅' : '❌',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.questionText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: ctx.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!r.isCorrect) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '正解: ${r.correctAnswer}',
                                  style: const TextStyle(
                                      fontSize: 11, color: kPrimaryColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (r.isCorrect && r.timeBonus > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '⚡+${r.timeBonus}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: 60 * i),
                  ).slideX(begin: 0.08, curve: Curves.easeOut);
                },
              ),
            ),

            // ─── ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // スコアコピーボタン
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _shareScore(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('スコアをコピー'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF9B59B6)),
                        foregroundColor: const Color(0xFF9B59B6),
                      ),
                    ),
                  ),
                  // 間違えた問題を復習ボタン
                  if (results.any((r) => !r.isCorrect)) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticService.lightImpact();
                          final wrongAnswers = results
                              .where((r) => !r.isCorrect)
                              .map((r) => QuizAnswer(
                                    questionText: r.questionText,
                                    isCorrect: false,
                                    selectedAnswer: r.selectedAnswer,
                                    correctAnswer: r.correctAnswer,
                                    explanation: r.explanation,
                                    codeSnippet: r.codeSnippet,
                                  ))
                              .toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizReviewScreen(wrongAnswers: wrongAnswers),
                            ),
                          );
                        },
                        icon: const Text('📖', style: TextStyle(fontSize: 14)),
                        label: Text(
                          '間違えた${results.where((r) => !r.isCorrect).length}問を復習する',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFE74C3C)),
                          foregroundColor: const Color(0xFFE74C3C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('ホームへ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TimeAttackScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('もう一度'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),   // closes Scaffold (child of Focus)
  );     // closes Focus return
  }

  void _shareScore(BuildContext context) {
    final taState = ref.read(timeAttackProvider);
    final s = widget.score;
    final t = widget.total;
    final tb = widget.totalBonus;
    final totalPt = s + tb;
    final percent = t > 0 ? (s / t * 100).round() : 0;
    final rank = _rank(t > 0 ? s / t : 0.0, tb);

    final percentStr = '$percent%';
    final totalPtStr = '${totalPt}pt';
    final bestStr = '${taState.bestScore}pt';
    final maxCombo = widget.maxCombo;
    final text = '⚡ タイムアタック結果 ⚡\n'
        '${rank.emoji} ${rank.label}\n'
        '正解: $s / $t ($percentStr)\n'
        'ボーナス: +$tb  合計: $totalPtStr\n'
        '🔥 最大コンボ: $maxCombo連続\n'
        '🏅 ベストスコア: $bestStr\n'
        '#しょうがくプログラミング';

    Clipboard.setData(ClipboardData(text: text));
    HapticService.lightImpact();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📋 クリップボードにコピーしました'),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ctx.subCardBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyDots(List<_TAResult> results) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: results.asMap().entries.map((e) {
        final r = e.value;
        final isLast = e.key == results.length - 1;
        return Container(
          width: 20,
          height: 20,
          margin: EdgeInsets.only(right: isLast ? 0 : 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: r.isCorrect
                ? const Color(0xFF2ECC71)
                : const Color(0xFFE74C3C),
            boxShadow: [
              BoxShadow(
                color: (r.isCorrect
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFE74C3C))
                    .withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              r.isCorrect ? '✓' : '✗',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: 300 + e.key * 60))
            .scale(begin: const Offset(0.0, 0.0), curve: Curves.elasticOut, duration: 400.ms)
            .fadeIn(duration: 200.ms);
      }).toList(),
    );
  }

  Widget _buildScoreTrend(List<int> recentScores) {
    final maxScore = recentScores.reduce((a, b) => a > b ? a : b);
    final half = recentScores.length ~/ 2;
    final older = recentScores.sublist(0, half);
    final newer = recentScores.sublist(half);
    final avgOlder = older.reduce((a, b) => a + b) / older.length;
    final avgNewer = newer.reduce((a, b) => a + b) / newer.length;
    final isUp = avgNewer > avgOlder;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isUp ? '📈 上昇中' : '📉 低下中',
          style: TextStyle(
            fontSize: 11,
            color: isUp ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recentScores.asMap().entries.map((e) {
              final heightRatio = maxScore > 0 ? e.value / maxScore : 0.0;
              final isLast = e.key == recentScores.length - 1;
              return Container(
                width: 6,
                height: (4 + 16 * heightRatio).clamp(4.0, 20.0),
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: isLast
                      ? const Color(0xFFFFC107)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyRecords(TimeAttackState taState) {
    const diffLabels = ['🌱 やさしい', '🔥 ふつう', '⚡ むずかしい'];
    return Row(
      children: List.generate(3, (i) {
        final bestPt = taState.bestScoreByDifficulty[i];
        final bestC = taState.bestCorrectByDifficulty[i];
        final isCurrent = i == widget.difficulty;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: i == 0 ? 0 : 4,
              right: i == 2 ? 0 : 4,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isCurrent ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(10),
              border: isCurrent
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  diffLabels[i],
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: isCurrent ? 0.9 : 0.6),
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  bestPt > 0 ? '${bestPt}pt' : '—',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: isCurrent ? 1.0 : 0.7),
                  ),
                ),
                Text(
                  bestPt > 0 ? '$bestC/10問' : '未プレイ',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: isCurrent ? 0.85 : 0.5),
                  ),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: 500 + i * 80))
           .fadeIn(duration: 300.ms)
           .slideY(begin: 0.1, curve: Curves.easeOut, duration: 300.ms),
        );
      }),
    );
  }

  _Rank _rank(double percent, int bonus) {
    final combined = percent + bonus / 30.0;
    if (combined >= 1.4) return _Rank('🏆', 'Sランク！');
    if (combined >= 1.0) return _Rank('🥇', 'Aランク！');
    if (combined >= 0.7) return _Rank('🥈', 'Bランク');
    if (combined >= 0.5) return _Rank('🥉', 'Cランク');
    return _Rank('💪', 'またチャレンジ！');
  }
}

// ── 選択肢ボタン ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = context.borderColor;
    Color bgColor = context.cardBg;
    Color textColor = context.textPrimary;

    if (isCorrect) {
      borderColor = kPrimaryColor;
      bgColor = kPrimaryColor;
      textColor = Colors.white;
    } else if (isWrong) {
      borderColor = Colors.red;
      bgColor = Colors.red;
      textColor = Colors.white;
    } else if (isSelected) {
      borderColor = kPrimaryColor;
      bgColor = kPrimaryColor.withValues(alpha: 0.1);
    }

    final widget = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 14, color: textColor)),
            ),
            if (isCorrect) const Icon(Icons.check_circle, color: Colors.white, size: 18),
            if (isWrong) const Icon(Icons.cancel, color: Colors.white, size: 18),
          ],
        ),
      ),
    );

    if (isCorrect) {
      return widget
          .animate(key: const ValueKey('correct'))
          .scale(
            begin: const Offset(0.94, 0.94),
            curve: Curves.elasticOut,
            duration: 450.ms,
          );
    } else if (isWrong) {
      return widget
          .animate(key: const ValueKey('wrong'))
          .shake(hz: 4, curve: Curves.easeInOut, duration: 350.ms);
    }
    return widget;
  }
}

// ── 結果チップ ───────────────────────────────────────────────────────────────

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final String? subtitle;

  const _ResultChip(this.label, this.value, this.emoji, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

// ── データクラス ──────────────────────────────────────────────────────────────

class _TAQuestion {
  final Question question;
  final String challengeTitle;
  const _TAQuestion({required this.question, required this.challengeTitle});
}

class _TAResult {
  final String questionText;
  final bool isCorrect;
  final int timeBonus;
  final String selectedAnswer;
  final String correctAnswer;
  final String explanation;
  final String? codeSnippet;

  const _TAResult({
    required this.questionText,
    required this.isCorrect,
    required this.timeBonus,
    required this.selectedAnswer,
    required this.correctAnswer,
    this.explanation = '',
    this.codeSnippet,
  });
}

class _Rank {
  final String emoji;
  final String label;
  const _Rank(this.emoji, this.label);
}
