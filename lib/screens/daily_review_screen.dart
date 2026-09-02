import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../config/theme.dart';
import '../models/challenge.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/daily_review_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../services/sound_service.dart';
import '../widgets/code_highlight.dart';
import 'quiz_result_screen.dart';
import 'badge_unlock_screen.dart';
import '../widgets/shortcut_help.dart';
import 'quiz_review_screen.dart';
import '../providers/ai_programming_coach_provider.dart';
import '../widgets/ai_response_dialog.dart';

// ── 今日の復習 (Daily Review) ────────────────────────────────────────────────
// 完了済みステージからランダムに5問を抽出する毎日リセット型の復習クイズ。
// 1日1回のボーナスポイント付与（正解1問 = 20pt）。

const _kBonusPerCorrect = 20;

class DailyReviewScreen extends ConsumerStatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen> {
  late List<_ReviewQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _hasAnswered = false;
  bool _isCorrect = false;
  int _score = 0;
  int _comboStreak = 0;        // 連続正解数（コンボサウンド用）
  int _maxCombo = 0;           // セッション中の最大連続正解数
  int _resolvedInSession = 0; // このセッションで克服した苦手問題数
  bool _sessionDone = false;
  bool _isLoading = true;
  bool _hintShown = false;
  bool _flagged = false;
  // 各問の正誤・選択肢・ヒント使用を記録
  final List<bool> _results = [];
  final List<int> _selectedAnswers = []; // 各問に選んだ選択肢インデックス
  final List<bool> _hintUsages = [];     // 各問のヒント使用有無
  DateTime? _sessionStartTime;
  int _elapsedSeconds = 0;
  bool _timeRecorded = false; // 学習時間の二重記録防止フラグ
  int _displaySeconds = 0;   // リアルタイム経過時間表示用
  Timer? _displayTimer;       // 経過時間更新タイマー
  late ConfettiController _confettiController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    // 通常完了以外（中途終了）の場合も学習時間を記録
    if (!_timeRecorded && _sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (elapsed >= 5) {
        ref.read(progressProvider.notifier).recordLearningSeconds(elapsed);
      }
    }
    _confettiController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // Esc / Backspace → 戻る（セッション完了後も有効）
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }

    // Enter/Space → セッション完了後は戻る
    if (_sessionDone) {
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
      }
      // S → 結果をシェア
      if (key == LogicalKeyboardKey.keyS) {
        _shareResult(context);
        return KeyEventResult.handled;
      }
      // W → 間違い問題の復習（不正解がある場合のみ）
      if (key == LogicalKeyboardKey.keyW) {
        final wrong = <QuizAnswer>[];
        for (int i = 0; i < _results.length; i++) {
          if (!_results[i] && i < _questions.length && i < _selectedAnswers.length) {
            final q = _questions[i].question;
            final sel = _selectedAnswers[i];
            wrong.add(QuizAnswer(
              questionText: q.text,
              isCorrect: false,
              selectedAnswer: sel < q.options.length ? q.options[sel] : '',
              correctAnswer: q.options[q.correctIndex],
              explanation: q.explanation,
              codeSnippet: q.codeSnippet,
            ));
          }
        }
        if (wrong.isNotEmpty) {
          HapticService.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuizReviewScreen(wrongAnswers: wrong),
            ),
          );
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_isLoading || _questions.isEmpty) return KeyEventResult.ignored;

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

    // 未回答: 1/2/3/4 またはテンキーで選択肢を選ぶ
    final optionKeys = {
      LogicalKeyboardKey.digit1: 0,
      LogicalKeyboardKey.digit2: 1,
      LogicalKeyboardKey.digit3: 2,
      LogicalKeyboardKey.digit4: 3,
      LogicalKeyboardKey.numpad1: 0,
      LogicalKeyboardKey.numpad2: 1,
      LogicalKeyboardKey.numpad3: 2,
      LogicalKeyboardKey.numpad4: 3,
    };
    if (optionKeys.containsKey(key)) {
      final idx = optionKeys[key]!;
      if (_questions.isNotEmpty && idx < _questions[_currentIndex].question.options.length) {
        _selectOption(idx);
        return KeyEventResult.handled;
      }
    }

    // Enter/Space で答え合わせ
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_selectedIndex != null) {
        _submitAnswer();
        return KeyEventResult.handled;
      }
    }

    // H でヒント表示
    if (key == LogicalKeyboardKey.keyH) {
      final q = _questions[_currentIndex];
      if (q.question.hint != null && !_hintShown) {
        HapticService.selectionClick();
        setState(() => _hintShown = true);
        return KeyEventResult.handled;
      }
    }

    // F → 苦手フラグ（苦手リストに追加）
    if (key == LogicalKeyboardKey.keyF && !_flagged && !_hasAnswered) {
      _flagCurrentQuestion();
      return KeyEventResult.handled;
    }

    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('1 〜 4', '選択肢を選ぶ'),
        ('Tab / Shift+Tab', '選択肢を順送り / 逆送り'),
        ('Enter / Space', '確定 / 次へ / 戻る'),
        ('H', 'ヒントを表示'),
        ('F', '苦手リストに追加'),
        ('S', '結果をシェア（結果画面）'),
        ('W', '間違い問題を復習（結果画面）'),
        ('Esc / BS', '戻る'),
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
        hintUsed: _hintShown,
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

  Future<void> _init() async {
    final allStage?s = ref.read(allStage?sProvider);
    final progressMap = ref.read(progressProvider);
    final wrongAnswers = ref.read(wrongAnswersProvider).answers;

    // 完了済みかつクイズ問題を持つステージのみ収集
    final pool = <_ReviewQuestion>[];
    for (final c in allStage?s) {
      if (progressMap[c.id]?.isCompleted != true) continue;
      if (c.questions.isEmpty) continue;
      for (final q in c.questions) {
        pool.add(_ReviewQuestion(question: q, challengeTitle: c.title));
      }
    }

    if (pool.isEmpty) {
      // 完了済みステージがない場合は全ステージから
      for (final c in allStage?s) {
        for (final q in c.questions) {
          pool.add(_ReviewQuestion(question: q, challengeTitle: c.title));
        }
      }
    }

    // 苦手問題を優先して選ぶ: wrongAnswers と questionText が一致するものを先頭に
    // さらに、間違い回数の多い問題ほど前に配置（頻度優先）
    final wrongState = ref.read(wrongAnswersProvider);
    final wrongTexts = wrongAnswers.map((a) => a.questionText).toSet();
    final weak = pool.where((q) => wrongTexts.contains(q.question.text)).toList();
    // 頻度の多い順でソートし、同頻度はランダムシャッフル
    weak.shuffle(Random());
    weak.sort((a, b) => wrongState.wrongCountFor(b.question.text)
        .compareTo(wrongState.wrongCountFor(a.question.text)));
    final rest = pool.where((q) => !wrongTexts.contains(q.question.text)).toList();
    rest.shuffle(Random());
    final prioritized = [...weak, ...rest];
    final reviewCount = ref.read(profileProvider).reviewQuestionCount;
    _questions = prioritized.take(reviewCount).toList();

    setState(() {
      _isLoading = false;
      _sessionStartTime = DateTime.now();
    });
    // 経過時間を毎秒更新
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sessionDone) return;
      setState(() {
        _displaySeconds = _sessionStartTime != null
            ? DateTime.now().difference(_sessionStartTime!).inSeconds
            : 0;
      });
    });
  }

  void _selectOption(int index) {
    if (_hasAnswered) return;
    SoundService().playTap();
    setState(() => _selectedIndex = index);
  }

  Future<void> _submitAnswer() async {
    if (_selectedIndex == null || _hasAnswered) return;
    final q = _questions[_currentIndex];
    final correct = _selectedIndex == q.question.correctIndex;
    if (correct) {
      _score++;
      _comboStreak++;
      if (_comboStreak > _maxCombo) _maxCombo = _comboStreak;
      HapticService.lightImpact();
      if (_comboStreak >= 2) {
        SoundService().playCombo(_comboStreak);
      } else {
        SoundService().playCorrect();
      }
      // 苦手リストにある問題を正解したらカウントを減らす（完全克服でボーナスポイント）
      final resolved = await ref.read(wrongAnswersProvider.notifier).markCorrect(q.question.text);
      if (resolved) {
        ref.read(progressProvider.notifier).addBonusPoints(5);
        _resolvedInSession++;
      }
    } else {
      _comboStreak = 0;
      HapticService.mediumImpact();
      SoundService().playWrong();
    }
    _results.add(correct);
    _selectedAnswers.add(_selectedIndex!);
    _hintUsages.add(_hintShown);
    setState(() {
      _hasAnswered = true;
      _isCorrect = correct;
    });
    // 自動進行（設定が有効かつ正解時）
    if (correct && ref.read(profileProvider).autoAdvanceEnabled) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _hasAnswered) _nextQuestion();
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _hasAnswered = false;
        _isCorrect = false;
        _hintShown = false;
        _flagged = false;
      });
    } else {
      _finishReview();
    }
  }

  Future<void> _finishReview() async {
    _elapsedSeconds = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;
    // 今日の日付を記録（再度プレイ不可に）
    await ref.read(dailyReviewProvider.notifier).markDoneToday();

    // ボーナスポイント（正解数 × 20pt）
    final bonus = _score * _kBonusPerCorrect;
    if (bonus > 0) {
      final levelBefore = ref.read(progressProvider.notifier).currentLevel;
      await ref.read(progressProvider.notifier).addBonusPoints(bonus);
      final levelAfter = ref.read(progressProvider.notifier).currentLevel;
      SoundService().playComplete();
      if (levelAfter > levelBefore && mounted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          SoundService().playLevelUp();
          HapticService.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('⬆️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'レベルアップ！ Lv.$levelAfter になった！',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE67E22),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
    }

    // 不正解問題を苦手リストに保存
    final wrongList = <QuizAnswer>[];
    for (int i = 0; i < _results.length; i++) {
      if (!_results[i] && i < _questions.length && i < _selectedAnswers.length) {
        final q = _questions[i].question;
        final selected = _selectedAnswers[i];
        wrongList.add(QuizAnswer(
          questionText: q.text,
          isCorrect: false,
          selectedAnswer: selected < q.options.length ? q.options[selected] : '',
          correctAnswer: q.options[q.correctIndex],
          explanation: q.explanation,
          codeSnippet: q.codeSnippet,
          hintUsed: i < _hintUsages.length && _hintUsages[i],
        ));
      }
    }
    if (wrongList.isNotEmpty) {
      await ref.read(wrongAnswersProvider.notifier).addWrongAnswers(wrongList);
    }

    // アクティビティログに記録（復習モードのカレンダー反映）
    await ref.read(progressProvider.notifier).recordActivity();

    // 累計回答数・学習時間を記録（dispose時の二重記録防止）
    _timeRecorded = true;
    if (_questions.isNotEmpty) {
      final prevAnswered = ref.read(progressProvider.notifier).totalQuestionsAnswered;
      await ref.read(progressProvider.notifier).recordQuestionsAnswered(_questions.length);
      final newAnswered = ref.read(progressProvider.notifier).totalQuestionsAnswered;
      _checkQuestionsAnsweredBadge(prevAnswered, newAnswered);
    }
    (String, String, String, String)? learningBadge;
    if (_elapsedSeconds > 0) {
      learningBadge = await ref.read(progressProvider.notifier).recordLearningSeconds(_elapsedSeconds);
    }

    // 復習ストリーク・累計回数マイルストーンバッジ
    final reviewState = ref.read(dailyReviewProvider);
    final newStreak = reviewState.reviewStreak;
    final newTotal  = reviewState.totalReviewsCompleted;

    if (mounted) {
      setState(() => _sessionDone = true);
      // 満点ならハプティクス + 紙吹雪
      if (_score == _questions.length && _questions.isNotEmpty) {
        HapticService.heavyImpact();
        _confettiController.play();
      }
      // 学習時間マイルストーン達成バッジ
      if (learningBadge != null) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          showBadgeUnlock(
            context,
            icon: learningBadge!.$1,
            name: learningBadge.$2,
            message: learningBadge.$3,
            points: 50,
            nextGoal: learningBadge.$4,
            onContinue: () {},
          );
        });
      }
      // 復習ストリークバッジ（初達成時）
      _checkReviewMilestoneBadges(newStreak, newTotal, hasLearningBadge: learningBadge != null);
    }
  }

  void _checkQuestionsAnsweredBadge(int prevTotal, int newTotal) {
    const milestones = [
      (100,  '📝', '100問挑戦！',    '累計100問に回答達成！', '次は500問を目指そう！'),
      (500,  '📚', '500問達成！',    '累計500問に回答！本格的なコーダー！', '次は1000問を目指そう！'),
      (1000, '🧠', '1000問マスター！', '累計1000問に回答！あなたはコードマスター！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in milestones) {
      if (prevTotal < target && newTotal >= target) {
        Future.delayed(const Duration(milliseconds: 5000), () {
          if (!mounted) return;
          showBadgeUnlock(context, icon: icon, name: name, message: message,
            points: 100, nextGoal: goal, onContinue: () {});
        });
        return;
      }
    }
  }

  void _checkReviewMilestoneBadges(int streak, int total, {required bool hasLearningBadge}) {
    final baseDelay = hasLearningBadge ? 3200 : 1600;
    // ストリークマイルストーン
    const streakMilestones = [
      (3,  '📖',       '復習3日連続',   '今日の復習を3日連続で完了！'),
      (7,  '📖📖',     '復習1週間連続', '今日の復習を7日連続で完了！'),
      (14, '📖📖📖',   '復習2週間連続', '今日の復習を14日連続で完了！'),
      (30, '🔖',       '復習1ヶ月連続', '今日の復習を30日連続で完了！すごい！'),
    ];
    bool streakBadgeShown = false;
    for (final (target, icon, name, message) in streakMilestones) {
      if (streak == target) {
        Future.delayed(Duration(milliseconds: baseDelay), () {
          if (!mounted) return;
          showBadgeUnlock(context, icon: icon, name: name, message: message,
            points: target * 5, nextGoal: '実績画面で確認しよう！', onContinue: () {});
        });
        streakBadgeShown = true;
        break;
      }
    }
    // 累計回数マイルストーン
    const totalMilestones = [
      (5,  '📋', '復習5回達成',  '今日の復習を累計5回完了！'),
      (10, '📒', '復習10回達成', '今日の復習を累計10回完了！'),
      (30, '📕', '復習30回達成！', '今日の復習を累計30回完了！復習の達人！'),
    ];
    for (final (target, icon, name, message) in totalMilestones) {
      if (total == target) {
        final delay = baseDelay + (streakBadgeShown ? 1600 : 0);
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          showBadgeUnlock(context, icon: icon, name: name, message: message,
            points: 50, nextGoal: '実績画面で確認しよう！', onContinue: () {});
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_sessionDone)
                Expanded(child: _buildResult(context))
              else if (_questions.isEmpty)
                Expanded(child: _buildEmptyState(context))
              else
                Expanded(child: _buildQuiz(context)),
            ],
          ),
          // 紙吹雪（満点時）
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Color(0xFF1ABC9C),
                Color(0xFFFFC107),
                Color(0xFFE91E63),
                Color(0xFF2196F3),
                Color(0xFF4CAF50),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      '📖 今日の復習',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Builder(builder: (ctx) {
                      final streak = ref.read(dailyReviewProvider).reviewStreak;
                      if (streak < 2) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🔥 $streak日',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (!_sessionDone && !_isLoading && _questions.isNotEmpty) ...[
                if (!_hasAnswered)
                  Tooltip(
                    message: _flagged ? '苦手リストに追加済み' : '苦手リストに追加',
                    child: GestureDetector(
                      onTap: _flagged ? null : _flagCurrentQuestion,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _flagged
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.22),
                        ),
                        child: Center(
                          child: Text(
                            _flagged ? '🚩' : '🏳️',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_displaySeconds > 0)
                  Text(
                    _displaySeconds >= 60
                        ? '⏱ ${_displaySeconds ~/ 60}:${(_displaySeconds % 60).toString().padLeft(2, '0')}'
                        : '⏱ ${_displaySeconds}s',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${_currentIndex + 1} / ${_questions.length}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ],
          ),
          if (!_sessionDone && !_isLoading && _questions.isNotEmpty) ...[
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: (_currentIndex + 1) / _questions.length),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'まだ復習できる問題がありません。\nステージをクリアしよう！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('もどる'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(BuildContext context) {
    final q = _questions[_currentIndex];
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              key: ValueKey(_currentIndex),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 出典
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '📌 ${q.challengeTitle}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF16A085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 苦手バッジ（複数回間違えた問題）
                Builder(builder: (ctx) {
                  final wc = ref
                      .read(wrongAnswersProvider)
                      .wrongCountFor(q.question.text);
                  if (wc < 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFFF6B35).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF6B35)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '🔥 苦手問題 ×$wc回間違えた',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE64A00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
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
                if (q.question.codeSnippet != null) ...[
                  CodeHighlightWidget(code: q.question.codeSnippet!, showLineNumbers: true),
                  const SizedBox(height: 12),
                ],
                // AIデバッグヒントボタン
                if (!_hasAnswered) ...[
                  Consumer(builder: (context, ref, _) {
                    return GestureDetector(
                      onTap: () {
                        ref.read(aiProgrammingCoachProvider.notifier).getDebugHint(
                          codeSnippet: q.question.codeSnippet ?? '(コードなし)',
                          expectedBehavior: q.question.explanation,
                          actualBehavior: '現在、答えを考え中...',
                        );
                        showDialog(
                          context: context,
                          builder: (ctx) => Consumer(
                            builder: (context, ref, _) {
                              final coachState =
                                  ref.watch(aiProgrammingCoachProvider);
                              return AIResponseDialog(
                                title: '💡 AI デバッグヒント',
                                content: coachState.content,
                                isLoading: coachState.isLoading,
                                error: coachState.error,
                                onDismiss: () => Navigator.pop(ctx),
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6C5CE7)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💡', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Text(
                              'AIにもうすこしヒントをもらう',
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
                  const SizedBox(height: 12),
                ],
                // ヒントボタン
                if (q.question.hint != null && !_hasAnswered) ...[
                  GestureDetector(
                    onTap: () {
                      HapticService.selectionClick();
                      setState(() => _hintShown = true);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _hintShown
                            ? (context.isDark
                                ? const Color(0xFF3D2E00)
                                : const Color(0xFFFFF8E1))
                            : (context.isDark
                                ? const Color(0xFF3D2E00).withValues(alpha: 0.5)
                                : const Color(0xFFFFF8E1).withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFB300).withValues(alpha: _hintShown ? 0.8 : 0.4),
                        ),
                      ),
                      child: _hintShown
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    q.question.hint!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.isDark
                                          ? const Color(0xFFFFE082)
                                          : const Color(0xFF795548),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFFFFB300)),
                                SizedBox(width: 6),
                                Text(
                                  'ヒントを見る',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFFB300),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // 選択肢
                ...q.question.options.asMap().entries.map((e) {
                  final i = e.key;
                  final opt = e.value;
                  return _ReviewOptionTile(
                    label: String.fromCharCode(65 + i),
                    text: opt,
                    isSelected: _selectedIndex == i,
                    isCorrect:
                        _hasAnswered && i == q.question.correctIndex,
                    isWrong: _hasAnswered &&
                        _selectedIndex == i &&
                        i != q.question.correctIndex,
                    onTap: () => _selectOption(i),
                  ).animate(delay: Duration(milliseconds: 60 * i))
                      .fadeIn(duration: 220.ms)
                      .slideX(begin: 0.05, curve: Curves.easeOut, duration: 220.ms);
                }),
                // 解説
                if (_hasAnswered) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? const Color(0xFF1ABC9C).withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _isCorrect ? const Color(0xFF1ABC9C) : Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCorrect ? '✅ 正解！' : '❌ 不正解',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isCorrect
                                ? const Color(0xFF1ABC9C)
                                : Colors.red,
                          ),
                        ),
                        if (q.question.explanation.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            q.question.explanation,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.05, curve: Curves.easeOut, duration: 250.ms),
          ),
        ),
        // ボタンバー
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            boxShadow: [
              BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: SizedBox(
              key: ValueKey(_hasAnswered),
              width: double.infinity,
              child: _hasAnswered
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF1ABC9C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentIndex < _questions.length - 1
                                  ? '次の問題へ'
                                  : '結果を見る',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '[Enter] または [Space] で次へ',
                          style: TextStyle(fontSize: 11, color: Color(0xFF95A5A6)),
                        ),
                        if (_isCorrect && ref.read(profileProvider).autoAdvanceEnabled) ...[
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(milliseconds: 1200),
                            builder: (context, value, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 3,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1ABC9C)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '自動で次へ...',
                            style: TextStyle(fontSize: 10, color: Color(0xFF1ABC9C)),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedIndex != null ? _submitAnswer : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF1ABC9C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '答え合わせ',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '[1〜4][Tab] で選択  [Enter] で決定  [H] ヒント  [F] 苦手',
                          style: TextStyle(fontSize: 11, color: Color(0xFF95A5A6)),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareResult(BuildContext context) {
    HapticService.lightImpact();
    final percent = _questions.isNotEmpty
        ? (_score / _questions.length * 100).round()
        : 0;
    final bonus = _score * _kBonusPerCorrect;
    final timeStr = _elapsedSeconds >= 60
        ? '${_elapsedSeconds ~/ 60}分${_elapsedSeconds % 60}秒'
        : '$_elapsedSeconds秒';
    final streak = ref.read(dailyReviewProvider).reviewStreak;
    final streakLine = streak >= 2 ? '📖 復習$streak日連続！\n' : '';
    final comboLine = _maxCombo >= 2 ? '🔥 最大コンボ: $_maxCombo連続\n' : '';
    final text =
        '📖 毎日の復習 結果\n'
        '正解: $_score/${_questions.length} ($percent%)\n'
        '⭐ ボーナス: +$bonus pt\n'
        '⏱ タイム: $timeStr\n'
        '$comboLine'
        '$streakLine'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 結果をコピーしました！'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final percent = _questions.isNotEmpty
        ? (_score / _questions.length * 100).round()
        : 0;
    final bonus = _score * _kBonusPerCorrect;
    final String emoji;
    final String message;
    if (percent >= 80) {
      emoji = '🏆';
      message = 'すばらしい復習！';
    } else if (percent >= 60) {
      emoji = '⭐';
      message = 'よくできました！';
    } else {
      emoji = '📖';
      message = '復習を続けよう！';
    }

    final isPerfect = _questions.isNotEmpty && _score == _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // 満点バナー
          if (isPerfect) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🌟', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    '満点！全問正解！',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('🌟', style: TextStyle(fontSize: 20)),
                ],
              ),
            )
                .animate()
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 600.ms)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
          ],
          Text(emoji, style: const TextStyle(fontSize: 72))
              .animate()
              .scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 600.ms)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 350.ms).slideY(begin: 0.2, curve: Curves.easeOut),
          const SizedBox(height: 24),
          // スコアカード
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _ResultRow(
                  label: '正解数',
                  value: '$_score / ${_questions.length}',
                  color: const Color(0xFF1ABC9C),
                ),
                const Divider(height: 20),
                _ResultRow(
                  label: '正答率',
                  value: '$percent%',
                  color: const Color(0xFF16A085),
                ),
                const Divider(height: 20),
                _ResultRow(
                  label: 'ボーナスポイント',
                  value: '+$bonus pt',
                  color: const Color(0xFFF39C12),
                ),
                if (_elapsedSeconds > 0) ...[
                  const Divider(height: 20),
                  _ResultRow(
                    label: '⏱ タイム',
                    value: _elapsedSeconds >= 60
                        ? '${_elapsedSeconds ~/ 60}分${_elapsedSeconds % 60}秒'
                        : '$_elapsedSeconds秒',
                    color: Colors.blueAccent,
                  ),
                  // 平均回答時間/問
                  if (_questions.isNotEmpty) ...[
                    const Divider(height: 20),
                    _ResultRow(
                      label: '📊 平均回答時間',
                      value: '${(_elapsedSeconds / _questions.length).round()}秒/問',
                      color: Colors.blueGrey,
                    ),
                  ],
                ],
                if (_maxCombo >= 2) ...[
                  const Divider(height: 20),
                  _ResultRow(
                    label: '🔥 最大コンボ',
                    value: '$_maxCombo連続',
                    color: const Color(0xFFE67E22),
                  ),
                ],
                Builder(builder: (context) {
                  final hintCount = _hintUsages.where((h) => h).length;
                  if (hintCount == 0) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const Divider(height: 20),
                      _ResultRow(
                        label: '💡 ヒント使用',
                        value: '$hintCount問',
                        color: const Color(0xFFF39C12),
                      ),
                    ],
                  );
                }),
                if (_resolvedInSession > 0) ...[
                  const Divider(height: 20),
                  _ResultRow(
                    label: '🎉 苦手克服',
                    value: '$_resolvedInSession問',
                    color: const Color(0xFF8E44AD),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 問題別正誤ドット
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '問題別結果',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 6,
                  runSpacing: 8,
                  children: _results.asMap().entries.map((e) {
                    final i = e.key;
                    final correct = e.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 80),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: correct
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (correct
                                    ? const Color(0xFF2ECC71)
                                    : const Color(0xFFE74C3C))
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              correct ? '✓' : '✗',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${i + 1}問',
                          style: const TextStyle(fontSize: 10, color: kTextSecondary),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut),
          const SizedBox(height: 12),
          Consumer(builder: (context, ref, _) {
            final streak = ref.watch(dailyReviewProvider).reviewStreak;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1ABC9C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1ABC9C).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    streak >= 2 ? '📖' : '📅',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    streak >= 2
                        ? '復習$streak日連続達成！明日も続けよう'
                        : '明日また復習できます',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.isDark ? const Color(0xFF26D0AB) : const Color(0xFF16A085),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          // 問題別正誤サマリー
          if (_results.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        '問題の結果',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._questions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final q = entry.value;
                    final correct = i < _results.length ? _results[i] : false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            correct ? '✅' : '❌',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.question.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '📌 ${q.challengeTitle}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: Duration(milliseconds: 100 * i))
                        .fadeIn(duration: 250.ms)
                        .slideX(begin: 0.05, curve: Curves.easeOut, duration: 250.ms);
                  }),
                ],
              ),
            ).animate(delay: 400.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 32),
          // 不正解があれば「苦手問題を復習」ボタン
          if (_results.any((r) => !r)) ...[
            Builder(builder: (context) {
              // 今セッションの不正解問題を抽出
              final sessionWrong = <QuizAnswer>[];
              for (int i = 0; i < _results.length; i++) {
                if (!_results[i] && i < _questions.length && i < _selectedAnswers.length) {
                  final q = _questions[i].question;
                  final sel = _selectedAnswers[i];
                  sessionWrong.add(QuizAnswer(
                    questionText: q.text,
                    isCorrect: false,
                    selectedAnswer: sel < q.options.length ? q.options[sel] : '',
                    correctAnswer: q.options[q.correctIndex],
                    explanation: q.explanation,
                    codeSnippet: q.codeSnippet,
                  ));
                }
              }
              if (sessionWrong.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticService.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizReviewScreen(wrongAnswers: sessionWrong),
                        ),
                      );
                    },
                    icon: const Text('📖', style: TextStyle(fontSize: 14)),
                    label: Text('間違えた${sessionWrong.length}問を復習する'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFE74C3C)),
                      foregroundColor: const Color(0xFFE74C3C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareResult(context),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('結果をシェア'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1ABC9C),
                side: BorderSide(color: const Color(0xFF1ABC9C).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF1ABC9C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ホームへ戻る',
                  style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 選択肢ウィジェット ────────────────────────────────────────────────────────

class _ReviewOptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _ReviewOptionTile({
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
      borderColor = const Color(0xFF1ABC9C);
      bgColor = const Color(0xFF1ABC9C);
      textColor = Colors.white;
    } else if (isWrong) {
      borderColor = Colors.red;
      bgColor = Colors.red;
      textColor = Colors.white;
    } else if (isSelected) {
      borderColor = const Color(0xFF1ABC9C);
      bgColor = const Color(0xFF1ABC9C).withValues(alpha: 0.12);
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
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 14, color: textColor))),
            if (isCorrect)
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
            if (isWrong)
              const Icon(Icons.cancel, color: Colors.white, size: 18),
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

// ── 結果行 ────────────────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 15, color: kTextSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

// ── データクラス ────────────────────────────────────────────────────────────

class _ReviewQuestion {
  final Question question;
  final String challengeTitle;
  const _ReviewQuestion(
      {required this.question, required this.challengeTitle});
}
