import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/stage.dart';
import '../providers/progress_provider.dart';
import '../providers/challenges_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/sound_service.dart';
import 'quiz_result_screen.dart';
import 'badge_unlock_screen.dart';
import '../widgets/code_highlight.dart';
import '../widgets/shortcut_help.dart';
import '../providers/ai_programming_coach_provider.dart';
import '../widgets/ai_response_dialog.dart';
import '../providers/coin_provider.dart';
import '../widgets/app_dialog.dart';
import '../providers/bgm_provider.dart';
import '../providers/character_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Stage challenge;
  /// 指定した場合、challenge.questions の代わりにこのリストを使用する（再挑戦用）
  final List<Question>? overrideQuestions;

  const QuizScreen({super.key, required this.challenge, this.overrideQuestions});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  List<Question> get _questions =>
      widget.overrideQuestions ?? widget.challenge.questions ?? [];

  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  bool _isCorrect = false;
  bool _showConceptCard = false;
  int _correctCount = 0;
  int _timerSeconds = 60;       // 1問あたりの制限時間（設定から読み込む）
  int _secondsRemaining = 60;
  late Timer _timer;
  final List<QuizAnswer> _answers = [];
  int _comboStreak = 0;       // 現在の連続正解数
  int _maxCombo = 0;          // セッション中の最大連続正解数
  int _resolvedWrongCount = 0; // このセッションで克服した苦手問題数
  int _speedBonusCount = 0;   // スピードボーナス付与回数
  String? _comboMessage;     // コンボメッセージ表示用
  bool _hintUsed = false;    // 現在の問題でヒントを使ったか
  bool _hintVisible = false; // ヒントバブル表示中か
  bool _flagged = false;    // 現在の問題をブックマーク済みか
  late DateTime _sessionStart; // セッション開始時刻
  bool _timerEnabled = true; // タイマー有効フラグ（設定から読み込む）
  bool _timeRecorded = false; // 学習時間の二重記録防止フラグ
  final FocusNode _focusNode = FocusNode(); // キーボードショートカット用

  // 自動進行カウントダウンアニメーション
  late AnimationController _autoAdvanceController;
  late Animation<double> _autoAdvanceAnim;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _showConceptCard = widget.challenge.conceptExplanation != null;
    _autoAdvanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _autoAdvanceAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _autoAdvanceController, curve: Curves.linear),
    );
    final profileState = ref.read(profileProvider);
    _timerEnabled = profileState.quizTimerEnabled;
    _timerSeconds = profileState.quizTimerSeconds;
    _secondsRemaining = _timerSeconds;
    _startTimer();

    // BGM を開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bgmProvider.notifier).playBgm('${widget.challenge.level}_quiz');
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    // BGM を停止
    ref.read(bgmProvider.notifier).stopBgm();
    // 通常完了以外（中途終了）の場合も学習時間を記録
    if (!_timeRecorded) {
      final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
      if (elapsed >= 5) {
        ref.read(progressProvider.notifier).recordLearningSeconds(elapsed);
      }
    }
    _focusNode.dispose();
    _autoAdvanceController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // 数字キーで選択肢を選択
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
      final q = _questions[_currentQuestionIndex];
      if (idx < q.options.length) {
        _selectOption(idx);
        return KeyEventResult.handled;
      }
    }
    // Tab / Shift+Tab で選択肢をサイクル（未回答のみ）
    if (key == LogicalKeyboardKey.tab && !_hasAnswered) {
      final q = _questions[_currentQuestionIndex];
      final optCount = q.options.length;
      if (HardwareKeyboard.instance.isShiftPressed) {
        // 前の選択肢へ
        final next = _selectedOptionIndex == null
            ? optCount - 1
            : (_selectedOptionIndex! - 1 + optCount) % optCount;
        setState(() => _selectedOptionIndex = next);
      } else {
        // 次の選択肢へ
        final next = _selectedOptionIndex == null
            ? 0
            : (_selectedOptionIndex! + 1) % optCount;
        setState(() => _selectedOptionIndex = next);
      }
      HapticService.selectionClick();
      return KeyEventResult.handled;
    }
    // Enter / Space で確定 or 次へ
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_hasAnswered) {
        _nextQuestion();
      } else if (_selectedOptionIndex != null) {
        _submitAnswer();
      }
      return KeyEventResult.handled;
    }
    // H → ヒント表示/非表示
    if (key == LogicalKeyboardKey.keyH) {
      final question = _questions[_currentQuestionIndex];
      if (question.hint != null && !_hasAnswered) {
        HapticService.selectionClick();
        setState(() {
          _hintUsed = true;
          _hintVisible = !_hintVisible;
        });
        return KeyEventResult.handled;
      }
    }
    // B → お気に入りトグル
    if (key == LogicalKeyboardKey.keyB) {
      HapticService.selectionClick();
      ref.read(favoritesProvider.notifier)
          .toggle(widget.challenge.id)
          .then((result) {
        final (wasAdded, newCount) = result;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
          SnackBar(
            content: Text(wasAdded ? '❤️ お気に入りに追加しました' : '💔 お気に入りから削除しました'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        checkFavoriteMilestoneBadge(
          context, // ignore: use_build_context_synchronously
          wasAdded: wasAdded,
          newCount: newCount,
        );
      });
      return KeyEventResult.handled;
    }
    // F → 苦手フラグ（苦手リストに追加）
    if (key == LogicalKeyboardKey.keyF && !_flagged) {
      HapticService.lightImpact();
      final q = _questions[_currentQuestionIndex];
      ref.read(wrongAnswersProvider.notifier).addWrongAnswers([
        QuizAnswer(
          questionText: q.text,
          isCorrect: false,
          selectedAnswer: '📌 手動追加',
          correctAnswer: q.options[q.correctIndex],
          explanation: q.explanation,
          codeSnippet: q.codeSnippet,
          hintUsed: _hintUsed,
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
      return KeyEventResult.handled;
    }
    // S → スキップ（未回答のみ）
    if (key == LogicalKeyboardKey.keyS && !_hasAnswered) {
      HapticService.selectionClick();
      _nextQuestion();
      return KeyEventResult.handled;
    }
    // Esc / Backspace → 終了確認（1問以上回答済みの場合）
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
        ('H', 'ヒントを表示'),
        ('B', 'お気に入りトグル'),
        ('F', '苦手リストに追加'),
        ('S', 'スキップ（未回答のみ）'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _getStageType(Stage challenge) {
    final title = challenge.title.toLowerCase();
    if (title.contains('if') || title.contains('分岐') || title.contains('条件')) return 'branch';
    if (title.contains('ループ') || title.contains('for') || title.contains('while')) return 'loop';
    if (title.contains('配列') || title.contains('リスト')) return 'array';
    if (title.contains('関数') || title.contains('メソッド')) return 'function';
    if (title.contains('変数')) return 'variable';
    if (title.contains('デバッグ')) return 'debug';
    if (title.contains('アルゴリズム') || title.contains('探索') || title.contains('ソート')) return 'algorithm';
    if (challenge.type == 'visual') return 'visual';
    return 'sequence';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_timerEnabled) return; // タイマー無効時はカウントダウンしない
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining == 10) {
          HapticService.mediumImpact();
        }
      } else {
        _timer.cancel();
        if (!_hasAnswered) {
          _handleTimeout();
        }
      }
    });
  }

  void _handleTimeout() {
    final question = _questions[_currentQuestionIndex];
    // タイムアウトを「不正解」として記録
    _answers.add(QuizAnswer(
      questionText: question.text,
      isCorrect: false,
      selectedAnswer: '⏰ 時間切れ',
      correctAnswer: question.options[question.correctIndex],
      explanation: question.explanation,
      codeSnippet: question.codeSnippet,
      hintUsed: _hintUsed,
    ));
    SoundService().playWrong();
    _comboStreak = 0;
    setState(() {
      _hasAnswered = true;
      _isCorrect = false;
      _comboMessage = null;
    });
    // 2秒後に自動で次へ
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _hasAnswered) _nextQuestion();
    });
  }

  void _selectOption(int index) {
    if (_hasAnswered) return;
    SoundService().playTap();
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedOptionIndex == null || _hasAnswered) return;
    // 二重送信（連打・Enter+タップの同時発火）を防ぐため、await前に即座にロックする
    setState(() => _hasAnswered = true);
    _timer.cancel();

    final question = _questions[_currentQuestionIndex];
    final correct = _selectedOptionIndex == question.correctIndex;

    _answers.add(QuizAnswer(
      questionText: question.text,
      isCorrect: correct,
      selectedAnswer: _selectedOptionIndex != null
          ? question.options[_selectedOptionIndex!]
          : '未回答',
      correctAnswer: question.options[question.correctIndex],
      explanation: question.explanation,
      codeSnippet: question.codeSnippet,
      hintUsed: _hintUsed,
    ));

    // 正解した場合、苦手リストのカウントを減らす（完全克服でボーナスポイント）
    if (correct) {
      final resolved = await ref.read(wrongAnswersProvider.notifier).markCorrect(question.text);
      if (resolved) {
        ref.read(progressProvider.notifier).addBonusPoints(5);
        _resolvedWrongCount++;
      }
      // キャラクター成長トリガー
      ref.read(characterProvider.notifier).growFromCorrectAnswer(
        challengeType: _getStageType(widget.challenge),
        difficulty: widget.challenge.level,
      );
    }

    // スピードボーナス: タイマー有効かつ残り時間が元の75%以上（素早く回答）
    bool speedBonus = false;
    if (correct && _timerEnabled && !_hintUsed &&
        _secondsRemaining >= (_timerSeconds * 0.75).round()) {
      speedBonus = true;
      ref.read(progressProvider.notifier).addBonusPoints(2);
      _speedBonusCount++;
    }

    // 効果音 & ハプティクス & コンボ
    String? comboMsg;
    if (correct) {
      HapticService.lightImpact();
      _comboStreak++;
      if (_comboStreak > _maxCombo) _maxCombo = _comboStreak;
      if (_comboStreak >= 2) {
        SoundService().playCombo(_comboStreak);
        if (_comboStreak == 2) {
          comboMsg = speedBonus ? '🔥 2連続！⚡ スピード +2pt' : '🔥 2連続！';
        } else if (_comboStreak == 3) {
          comboMsg = speedBonus ? '⚡ 3連続コンボ！⚡ +2pt' : '⚡ 3連続コンボ！';
        } else {
          comboMsg = speedBonus ? '💥 $_comboStreak連続！⚡ +2pt' : '💥 $_comboStreak連続！すごい！';
        }
      } else {
        SoundService().playCorrect();
        if (speedBonus) comboMsg = '⚡ スピードボーナス +2pt';
      }
    } else {
      HapticService.mediumImpact();
      SoundService().playWrong();
      _comboStreak = 0;
    }

    setState(() {
      _isCorrect = correct;
      if (correct) _correctCount++;
      _comboMessage = comboMsg;
    });

    // コンボ/スピードメッセージを2秒後にクリア
    if (comboMsg != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _comboMessage = null);
      });
    }

    // 自動進行（正解かつ設定オン）
    if (correct && ref.read(profileProvider).autoAdvanceEnabled) {
      _autoAdvanceController.forward(from: 0.0);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _hasAnswered) _nextQuestion();
      });
    }
  }

  void _nextQuestion() {
    // スキップの場合（未回答のまま次へ）、未回答を記録
    if (!_hasAnswered) {
      _timer.cancel();
      _comboStreak = 0;
      final question = _questions[_currentQuestionIndex];
      _answers.add(QuizAnswer(
        questionText: question.text,
        isCorrect: false,
        selectedAnswer: 'スキップ',
        correctAnswer: question.options[question.correctIndex],
        explanation: question.explanation,
        codeSnippet: question.codeSnippet,
        hintUsed: _hintUsed,
      ));
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _autoAdvanceController.reset();
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _hasAnswered = false;
        _isCorrect = false;
        _secondsRemaining = _timerSeconds;
        _hintUsed = false;
        _hintVisible = false;
        _flagged = false;
        _comboMessage = null;
      });
      _startTimer();
    } else {
      _showResult();
    }
  }

  Future<void> _confirmExit() async {
    // 1問も回答していない場合はそのまま戻る
    if (_answers.isEmpty && _currentQuestionIndex == 0 && !_hasAnswered) {
      Navigator.of(context).pop();
      return;
    }
    _timer.cancel();
    final progress = _currentQuestionIndex + (_hasAnswered ? 1 : 0);
    final confirmed = await AppDialog.confirm(
      context,
      emoji: '🤔',
      title: 'やめちゃう？',
      message: '今 $progress / ${_questions.length} 問まで進んでいるよ。\nやめると進捗は保存されないよ。',
      okLabel: 'やめる',
      cancelLabel: 'つづける',
      danger: true,
    );
    if (confirmed) {
      if (mounted) Navigator.of(context).pop();
    } else {
      // ダイアログキャンセル後にタイマー再開
      _startTimer();
    }
  }

  void _showResult() {
    final total = _questions.length;
    final stars = _calculateStars(_correctCount, total);
    final prevProgress = ref.read(progressProvider)[widget.challenge.id];
    final isFirstComplete = !(prevProgress?.isCompleted ?? false);
    final previousStars = prevProgress?.starsEarned ?? 0;

    // レベルアップ検出のため保存前のレベルを記録
    final levelBefore = ref.read(progressProvider.notifier).currentLevel;

    // 進捗を保存
    ref.read(progressProvider.notifier).completeChallenge(
          widget.challenge.id,
          stars,
        );

    // レベルアップ判定
    final levelAfter = ref.read(progressProvider.notifier).currentLevel;
    final didLevelUp = levelAfter > levelBefore;

    // 累計回答数を記録
    ref.read(progressProvider.notifier).recordQuestionsAnswered(_answers.length);

    // パーフェクトラン（全問正解）を記録
    if (stars == 3) {
      ref.read(progressProvider.notifier).recordPerfectRun();
    }

    // ─── コイン獲得 ───
    final (coinTotal, comboBonus, perfectBonus) = calcQuizCoins(
      level: widget.challenge.level,
      correctCount: _correctCount,
      totalCount: total,
      maxCombo: _maxCombo,
    );
    if (coinTotal > 0) {
      ref.read(coinProvider.notifier).earnCoins(coinTotal);
    }

    // 間違い問題を永続保存
    final wrongAnswers = _answers.where((a) => !a.isCorrect).toList();
    if (wrongAnswers.isNotEmpty) {
      ref.read(wrongAnswersProvider.notifier).addWrongAnswers(wrongAnswers);
    }
    final newCompletedCount = ref.read(progressProvider.notifier).completedCount;

    // 次のクイズ系ステージを探す（クイズ形式のみ）
    final allChallenges = ref.read(allChallengesProvider);
    final currentIndex =
        allChallenges.indexWhere((c) => c.id == widget.challenge.id);
    Stage? nextStage;
    if (currentIndex >= 0 && currentIndex < allChallenges.length - 1) {
      // 次のステージがクイズ形式かつ無料のものを探す
      for (int i = currentIndex + 1; i < allChallenges.length; i++) {
        final c = allChallenges[i];
        if (c.type == 'quiz' && c.isFree) {
          nextStage = c;
          break;
        }
      }
    }

    // 結果画面で学習時間を記録するため二重記録を防止
    _timeRecorded = true;

    // フルスクリーン結果画面へ遷移
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          challenge: widget.challenge,
          answers: List.from(_answers),
          correctCount: _correctCount,
          totalCount: total,
          stars: stars,
          isFirstComplete: isFirstComplete,
          previousStars: previousStars,
          didLevelUp: didLevelUp,
          newLevel: levelAfter,
          nextStage: nextStage,
          completedCount: newCompletedCount,
          sessionSeconds: DateTime.now().difference(_sessionStart).inSeconds,
          maxCombo: _maxCombo,
          resolvedWrongCount: _resolvedWrongCount,
          speedBonusCount: _speedBonusCount,
          coinsEarned: coinTotal,
        ),
      ),
    );
  }

  int _calculateStars(int correct, int total) {
    if (correct == total) return 3;
    if (correct >= (total * 0.7).round()) return 2;
    if (correct >= (total * 0.5).round()) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.challenge.title)),
        body: const Center(child: Text('問題がありません')),
      );
    }

    final question = questions[_currentQuestionIndex];
    final totalQuestions = questions.length;
    final hasHint = question.hint != null;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
            // ヘッダー
            _buildHeader(context, _currentQuestionIndex + 1, totalQuestions, hasHint, question),
            // 概念説明カード（クイズ開始前に表示）
            if (_showConceptCard)
              Expanded(child: _buildConceptCard(context))
            else
            // 問題コンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  key: ValueKey(_currentQuestionIndex),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 問題番号 + 問題文（問題変化時にスライドイン）
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          final wc = ref
                              .read(wrongAnswersProvider)
                              .wrongCountFor(question.text);
                          return Row(
                            children: [
                              Text(
                                '第${_currentQuestionIndex + 1}問',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (wc >= 1) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFF6B35)
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '🔥 苦手 ×$wc',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFE64A00),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                        const SizedBox(height: 8),
                        Text(
                          question.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (question.codeSnippet != null) ...[
                          CodeHighlightWidget(code: question.codeSnippet!),
                          const SizedBox(height: 16),
                        ],
                        // AI 概念説明ボタン
                        Consumer(builder: (context, ref, _) {
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(aiProgrammingCoachProvider.notifier)
                                  .explainConcept(
                                    conceptName: widget.challenge.title,
                                    questionContext: question.text,
                                    difficulty: '中級',
                                  );
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  final coachState =
                                      ref.watch(aiProgrammingCoachProvider);
                                  return AIResponseDialog(
                                    title: '🤖 AI概念説明',
                                    content: coachState.content,
                                    isLoading: coachState.isLoading,
                                    error: coachState.error,
                                    onDismiss: () => Navigator.pop(ctx),
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kPrimaryColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text('🤖',
                                      style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI に概念を説明してもらう',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    ).animate()
                     .fadeIn(duration: 250.ms)
                     .slideY(begin: 0.06, curve: Curves.easeOut, duration: 250.ms),
                    // 選択肢
                    ...question.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return _OptionButton(
                        label: String.fromCharCode(65 + index), // A, B, C, D
                        text: option,
                        isSelected: _selectedOptionIndex == index,
                        isCorrect: _hasAnswered && index == question.correctIndex,
                        isWrong: _hasAnswered &&
                            _selectedOptionIndex == index &&
                            index != question.correctIndex,
                        onTap: () => _selectOption(index),
                      ).animate(delay: Duration(milliseconds: 60 * index))
                          .fadeIn(duration: 220.ms)
                          .slideX(begin: 0.05, curve: Curves.easeOut, duration: 220.ms);
                    }),
                    // 解説
                    if (_hasAnswered) ...[
                      const SizedBox(height: 16),
                      _buildExplanation(question.explanation, _isCorrect)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(
                            begin: 0.1,
                            curve: Curves.easeOut,
                            duration: 300.ms,
                          ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ).animate().fadeIn(duration: 250.ms).slideX(
                      begin: 0.05,
                      curve: Curves.easeOut,
                      duration: 250.ms,
                    ),
              ),
            ),
            // ボタンエリア（概念カード表示中は非表示）
            if (!_showConceptCard) _buildButtons(context, totalQuestions),
              ],
            ),
            // ヒントバブルオーバーレイ
            if (_hintVisible && question.hint != null)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _hintVisible = false),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? const Color(0xFF3D2E00)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF39C12), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF39C12).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ヒント',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF39C12),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                question.hint!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.isDark
                                      ? const Color(0xFFFFE082)
                                      : const Color(0xFF7D6608),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.close, size: 16, color: Color(0xFFF39C12)),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: -0.1, curve: Curves.easeOut, duration: 200.ms),
                ),
              ),

            // 残り時間 ウルジェント ボーダーオーバーレイ（10秒以下 + 未回答）
            if (_timerEnabled && _secondsRemaining <= 10 && !_hasAnswered)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red.withValues(
                          alpha: _secondsRemaining % 2 == 0 ? 0.55 : 0.12,
                        ),
                        width: _secondsRemaining <= 5 ? 4 : 3,
                      ),
                    ),
                  ),
                ),
              ),

            // コンボメッセージオーバーレイ
            if (_comboMessage != null)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    key: ValueKey(_comboMessage),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _comboMessage!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        curve: Curves.elasticOut,
                        duration: 500.ms,
                      )
                      .fadeIn(duration: 200.ms),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context, int current, int total, bool hasHint, Question question) {
    final isUrgent = _timerEnabled && _secondsRemaining <= 10;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _confirmExit,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.challenge.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '問$current/$total  ✅ $_correctCount正解',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (_comboStreak >= 2) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.7),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '🔥 $_comboStreak連続',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // フラグボタン（苦手としてマーク）
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: _flagged ? '苦手リストに追加済み' : '苦手リストに追加',
              child: GestureDetector(
                onTap: _flagged
                    ? null
                    : () {
                        HapticService.lightImpact();
                        final q = question;
                        ref.read(wrongAnswersProvider.notifier).addWrongAnswers([
                          QuizAnswer(
                            questionText: q.text,
                            isCorrect: false,
                            selectedAnswer: '📌 手動追加',
                            correctAnswer: q.options[q.correctIndex],
                            explanation: q.explanation,
                            codeSnippet: q.codeSnippet,
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
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _flagged
                        ? Colors.red.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: Text(
                      _flagged ? '🚩' : '🏳️',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ヒントボタン
          if (hasHint && !_hasAnswered)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'ヒントを見る',
                child: GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    setState(() {
                      _hintUsed = true;
                      _hintVisible = !_hintVisible;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hintUsed
                          ? Colors.orange.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    child: const Center(
                      child: Text('💡', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ),
          // お気に入りボタン
          Consumer(builder: (context, ref, _) {
            final isFav = ref.watch(favoritesProvider)
                .isFavorite(widget.challenge.id);
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: isFav ? 'お気に入りから削除 (B)' : 'お気に入りに追加 (B)',
                child: GestureDetector(
                  onTap: () {
                    HapticService.selectionClick();
                    ref.read(favoritesProvider.notifier)
                        .toggle(widget.challenge.id)
                        .then((result) {
                      final (wasAdded, newCount) = result;
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(wasAdded
                              ? '❤️ お気に入りに追加しました'
                              : '💔 お気に入りから削除しました'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      checkFavoriteMilestoneBadge(
                        context, // ignore: use_build_context_synchronously
                        wasAdded: wasAdded,
                        newCount: newCount,
                      );
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFav
                          ? Colors.pink.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    child: Center(
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // タイマー（サークル）
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _timerEnabled ? _secondsRemaining / _timerSeconds : 1.0,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? Colors.red : Colors.white,
                  ),
                  strokeWidth: 3,
                ),
                Text(
                  !_timerEnabled
                      ? '∞'
                      : _secondsRemaining >= _timerSeconds
                          ? _timerSeconds.toString()
                          : _secondsRemaining.toString(),
                  style: TextStyle(
                    fontSize: _timerEnabled ? 13 : 16,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? Colors.red[200] : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
          // 問題別ドット進捗
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final Color dotColor;
              if (i < _answers.length) {
                dotColor = _answers[i].isCorrect ? Colors.greenAccent : Colors.redAccent;
              } else if (i == _currentQuestionIndex) {
                dotColor = Colors.white;
              } else {
                dotColor = Colors.white30;
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentQuestionIndex ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildExplanation(String explanation, bool isCorrect) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? kPrimaryColor.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? kPrimaryColor : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? '✅ 正解！' : '❌ 不正解',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCorrect ? kPrimaryColor : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 13,
              color: context.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, int totalQuestions) {
    final isLastQuestion = _currentQuestionIndex == totalQuestions - 1;

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
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: Row(
          key: ValueKey(_hasAnswered),
          children: [
            if (!_hasAnswered) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _nextQuestion,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('スキップ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selectedOptionIndex != null ? _submitAnswer : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('確認する'),
                ),
              ),
            ] else ...[
              Expanded(
                child: AnimatedBuilder(
                  animation: _autoAdvanceAnim,
                  builder: (context, child) {
                    final isAutoAdvancing = _autoAdvanceController.isAnimating;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isLastQuestion ? '結果を見る' : '次へ'),
                          ),
                        ),
                        if (isAutoAdvancing)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12)),
                              child: LinearProgressIndicator(
                                value: _autoAdvanceAnim.value,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.5),
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 行の先頭が絵文字かどうかを判定する（日本語の通常文と区別するため）。
  bool _startsWithEmoji(String line) {
    if (line.isEmpty) return false;
    final cp = line.runes.first;
    // 主要な絵文字ブロック（記号・絵文字・ダイングバット・乗り物・補助記号 等）
    return (cp >= 0x2600 && cp <= 0x27BF) || // Misc symbols & dingbats (✅ ⭐ 等)
        (cp >= 0x1F300 && cp <= 0x1FAFF) || // Misc symbols/pictographs, emoticons, transport, supplemental
        (cp >= 0x2190 && cp <= 0x21FF) || // Arrows (→ 等)
        cp == 0x2B50; // ⭐ star
  }

  Widget _buildConceptCard(BuildContext context) {
    final explanation = widget.challenge.conceptExplanation!;
    final lines = explanation.split('\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトルヘッダー
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.challenge.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.challenge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    const Text(
                      'クイズの前に読もう！',
                      style: TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, curve: Curves.easeOut),
          const SizedBox(height: 20),
          // 説明本文
          ...lines.asMap().entries.map((e) {
            final line = e.value.trim();
            final i = e.key;
            if (line.isEmpty) return const SizedBox(height: 8);

            // 絵文字で始まる行は見出し風に
            final isHeading = line.length > 1 &&
                _startsWithEmoji(line) &&
                !line.startsWith('•') &&
                !line.startsWith('→') &&
                !line.startsWith('-');

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: isHeading
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                          height: 1.5,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
            ).animate(delay: Duration(milliseconds: 60 * i.toInt()))
             .fadeIn(duration: 250.ms)
             .slideY(begin: 0.08, curve: Curves.easeOut, duration: 250.ms);
          }),
          const SizedBox(height: 24),
          // スタートボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticService.lightImpact();
                setState(() => _showConceptCard = false);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✅', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'わかった！クイズをはじめる',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _OptionButton({
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
      textColor = Colors.white;
    }

    final useGradient = isSelected && !isCorrect && !isWrong;

    final widget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: useGradient
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryColor, kPrimaryDark],
              )
            : null,
        color: useGradient ? null : bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
            if (isCorrect) const Icon(Icons.check_circle, color: Colors.white, size: 22),
            if (isWrong) const Icon(Icons.cancel, color: Colors.white, size: 22),
          ],
        ),
      ),   // closes Padding
    ),     // closes InkWell
  ),       // closes Material
    );     // closes Container

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
