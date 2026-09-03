import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/favorites_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../config/constants.dart';
import '../services/sound_service.dart';
import '../providers/wrong_answers_provider.dart';
import 'badge_unlock_screen.dart';
import '../widgets/shortcut_help.dart';
import 'quiz_screen.dart';
import 'quiz_review_screen.dart';
import 'flashcard_screen.dart' show FlashcardScreen, kFlashcards;
import '../widgets/code_highlight.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  final Stage challenge;
  final List<QuizAnswer> answers;
  final int correctCount;
  final int totalCount;
  final int stars;
  final bool isFirstComplete;
  final Stage? nextStage;
  final int completedCount;   // ステージ完了数（バッジ判定用）
  final int sessionSeconds;   // セッション所要時間（秒）
  final int previousStars;    // 前回の星数（改善表示用）
  final bool didLevelUp;      // レベルアップしたか
  final int newLevel;         // 新レベル（レベルアップ時）
  final int maxCombo;         // セッション中の最大連続正解数
  final int resolvedWrongCount; // このセッションで克服した苦手問題数
  final int speedBonusCount;  // スピードボーナス獲得回数
  final int coinsEarned;      // このセッションで獲得したコイン数

  const QuizResultScreen({
    super.key,
    required this.challenge,
    required this.answers,
    required this.correctCount,
    required this.totalCount,
    required this.stars,
    required this.isFirstComplete,
    this.nextStage,
    this.completedCount = 0,
    this.sessionSeconds = 0,
    this.previousStars = 0,
    this.didLevelUp = false,
    this.newLevel = 1,
    this.maxCombo = 0,
    this.resolvedWrongCount = 0,
    this.speedBonusCount = 0,
    this.coinsEarned = 0,
  });

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late ConfettiController _confettiController;
  late AnimationController _levelUpController;
  late Animation<double> _levelUpSlide;
  late Animation<double> _levelUpOpacity;
  bool _levelUpVisible = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_bounceController);

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _levelUpSlide = Tween<double>(begin: -40, end: 0).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.easeOut),
    );
    _levelUpOpacity = CurvedAnimation(
      parent: _levelUpController,
      curve: Curves.easeOut,
    );

    _bounceController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (widget.stars >= 2) {
        SoundService().playComplete();
        HapticService.heavyImpact();
        _confettiController.play();
      } else if (widget.stars == 1) {
        SoundService().playCorrect();
        HapticService.lightImpact();
      }
    });
    // 星アニメーションに合わせた効果音
    if (widget.stars > 0) {
      for (int i = 0; i < widget.stars; i++) {
        Future.delayed(Duration(milliseconds: 500 + i * 250), () {
          SoundService().playStar();
        });
      }
    }

    // レベルアップ演出（星サウンド後に表示）
    if (widget.didLevelUp) {
      final delay = 500 + widget.stars * 250 + 400;
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        SoundService().playLevelUp();
        HapticService.heavyImpact();
        setState(() => _levelUpVisible = true);
        _levelUpController.forward();
      });
    }

    // 初クリア3つ星 → バッジ演出
    if (widget.isFirstComplete && widget.stars == 3) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        showBadgeUnlock(
          context,
          icon: widget.challenge.icon,
          name: widget.challenge.title,
          message: '${widget.challenge.title}を完全クリア！',
          points: 150,
          nextGoal: '次のステージに挑戦しよう！',
          onContinue: () {},
        );
      });
    } else if (widget.isFirstComplete) {
      // クリア数マイルストーン バッジ
      _checkMilestoneBadge(widget.completedCount);
    }

    // 各種バッジチェック（初クリア時）
    // initState ではまだ ref が使えないため postFrameCallback で実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(progressProvider.notifier);
      // 初クリア時にユニット全制覇チェック
      if (widget.isFirstComplete) {
        _checkUnitCompleteBadge(widget.challenge.level);
      }
      // 3つ星マイルストーン バッジ（初クリアまたはスコア改善で3つ星到達）
      if (widget.stars == 3 && (widget.isFirstComplete || widget.previousStars < 3)) {
        _checkPerfectStageBadge(notifier.perfectStagesCount);
      }
      // 今日の目標達成バッジ（初クリア時のみ）
      if (widget.isFirstComplete) {
        final dailyGoal = ref.read(profileProvider).dailyGoal;
        _checkDailyGoalBadge(notifier.todayClearedCount, dailyGoal);
      }
      // 累計回答数マイルストーンバッジ
      _checkQuestionsAnsweredBadge(notifier.totalQuestionsAnswered);
      // 累計獲得ポイント（スター）マイルストーンバッジ
      final starsAdded = widget.stars - widget.previousStars;
      if (starsAdded > 0) {
        _checkStarBadge(notifier.totalStarsEarned, starsAdded);
      }
      // 累計学習時間を記録（マイルストーン達成時はバッジ表示）
      if (widget.sessionSeconds > 0) {
        notifier.recordLearningSeconds(widget.sessionSeconds).then((badge) {
          if (badge != null && mounted) {
            final delay = 3000 +
                widget.stars * 250 +
                (widget.didLevelUp ? 1500 : 0);
            Future.delayed(Duration(milliseconds: delay), () {
              if (!mounted) return;
              showBadgeUnlock(
                context,
                icon: badge.$1,
                name: badge.$2,
                message: badge.$3,
                points: 50,
                nextGoal: badge.$4,
                onContinue: () {},
              );
            });
          }
        });
      }
    });
  }

  void _checkMilestoneBadge(int completedCount) {
    final (icon, name, message, goal) = switch (completedCount) {
      1  => ('🚀', 'はじめの一歩！', '最初のステージをクリア！コーディング冒険の始まり！', '次のステージに挑戦しよう！'),
      3  => ('🌿', 'コードビギナー！', '3ステージクリア達成！', '次は5ステージを目指そう！'),
      5  => ('🌱', '成長中！', '5ステージクリア達成！習慣になってきた！', '10ステージが次の目標！'),
      8  => ('🧩', 'ブロック名人！', '8ステージクリア！初級も折り返し！', 'あと2ステージで1/4制覇！'),
      10 => ('🎯', '1/4制覇！', '10ステージクリア！', '残り30ステージ！このまま続けよう！'),
      15 => ('⭐', '15ステージ通過！', '15ステージクリア！半分まであと少し！', 'あと5ステージでPython入門者！'),
      20 => ('🐍', 'Python入門者！', '20ステージクリア！折り返しが近い！', 'あと5ステージで半分制覇！'),
      25 => ('🏅', '半分制覇！', '25ステージクリア！折り返し地点！', 'あと15ステージで全制覇！'),
      30 => ('🔥', '上級者突入！', '30ステージクリア！上位プレイヤー！', 'あと5ステージでゴールが見えてくる！'),
      35 => ('⚡', 'ゴールが見えた！', '35ステージクリア！あと5ステージ！', 'ラストスパート！全ステージ制覇を目指せ！'),
      AppConstants.totalStages => ('👑', '全ステージ制覇！', '${AppConstants.totalStages}ステージ完全クリア！伝説のコード探険家！', '全実績を確認しよう！'),
      _ => ('', '', '', ''),
    };
    if (icon.isEmpty) return;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      showBadgeUnlock(
        context,
        icon: icon,
        name: name,
        message: message,
        points: completedCount * 10,
        nextGoal: goal,
        onContinue: () {},
      );
    });
  }

  void _checkQuestionsAnsweredBadge(int totalAnswered) {
    // このセッションの問題数を引いた「前回まで」の累計で判定
    final prevTotal = totalAnswered - widget.answers.length;
    const milestones = [
      (100,  '📝', '100問挑戦！',   '累計100問に回答達成！', '次は500問を目指そう！'),
      (500,  '📚', '500問達成！',   '累計500問に回答！本格的なコーダー！', '次は1000問を目指そう！'),
      (1000, '🧠', '1000問マスター！', '累計1000問に回答！あなたはコードマスター！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in milestones) {
      if (prevTotal < target && totalAnswered >= target) {
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (!mounted) return;
          showBadgeUnlock(
            context,
            icon: icon,
            name: name,
            message: message,
            points: 100,
            nextGoal: goal,
            onContinue: () {},
          );
        });
        return; // 1つのマイルストーンのみ表示
      }
    }
  }

  void _checkStarBadge(int totalStars, int starsAdded) {
    final prevStars = totalStars - starsAdded;
    const milestones = [
      (50,  '⭐', '星コレクター',   '累計50ポイント達成！',          '60ポイントを目指そう！'),
      (60,  '💎', 'スター収集家',  '累計60ポイント達成！',           '150ポイントを目指そう！'),
      (120, '🌠', 'パーフェクトクリア', '全ステージ3つ星達成！120ポイント！', '150ポイントを目指そう！'),
      (150, '🌟', '輝く星',        '累計150ポイント達成！',          '300ポイントを目指そう！'),
      (300, '💰', 'ポイント長者',   '累計300ポイント達成！',          '全実績を確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in milestones) {
      if (prevStars < target && totalStars >= target) {
        final delay = 4500 + widget.stars * 250 + (widget.didLevelUp ? 1500 : 0);
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          showBadgeUnlock(
            context,
            icon: icon,
            name: name,
            message: message,
            points: target,
            nextGoal: goal,
            onContinue: () {},
          );
        });
        return; // 1つのマイルストーンのみ表示
      }
    }
  }

  void _checkPerfectStageBadge(int perfectCount) {
    final milestones = [
      (3,  '✨', '完璧主義者！',          '3ステージを3つ星でクリア！',               '5ステージ完璧を目指そう！'),
      (5,  '⭐', '5ステージ完璧！',      '5ステージを3つ星でクリア！',              '10ステージ完璧を目指そう！'),
      (10, '🌠', '3つ星コレクター！',    '10ステージを3つ星でクリア！すごい！',       '20ステージ完璧を目指そう！'),
      (20, '🎖️', 'パーフェクトマスター！', '20ステージを3つ星でクリア！折り返し地点！', '全${AppConstants.totalStages}ステージ完璧制覇を目指そう！'),
      (AppConstants.totalStages, '👑', '全ステージ完璧！', '全${AppConstants.totalStages}ステージ3つ星クリア！パーフェクトコーダー！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in milestones) {
      if (perfectCount == target) {
        final delay = 5000 + widget.stars * 250 + (widget.didLevelUp ? 1500 : 0);
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          showBadgeUnlock(
            context,
            icon: icon,
            name: name,
            message: message,
            points: target * 5,
            nextGoal: goal,
            onContinue: () {},
          );
        });
        return;
      }
    }
  }

  void _checkDailyGoalBadge(int todayCleared, int goalTarget) {
    if (todayCleared != goalTarget) return;
    // 重複防止フラグを即座にセット（home_screen SnackBar との二重表示を防ぐ）
    ref.read(progressProvider.notifier).markDailyGoalShownToday();
    final delay = 6500 + widget.stars * 250 + (widget.didLevelUp ? 1500 : 0);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      showBadgeUnlock(
        context, // ignore: use_build_context_synchronously
        icon: '🎯',
        name: '今日の目標達成！',
        message: '今日の目標 $goalTargetステージクリア！',
        points: goalTarget * 10,
        nextGoal: '明日も目標を達成しよう！',
        onContinue: () {},
      );
    });
  }

  void _checkUnitCompleteBadge(String level) {
    final allChallenges = ref.read(allChallengesProvider);
    final progressMap = ref.read(progressProvider);
    final unitStages = allChallenges.where((c) => c.level == level).toList();
    if (unitStages.isEmpty) return;
    final completedInUnit = unitStages.where((c) => progressMap[c.id]?.isCompleted ?? false).length;
    if (completedInUnit < unitStages.length) return;

    final (icon, name, message, goal) = switch (level) {
      StageLevel.beginner     => ('🧩', '初級ユニット制覇！', 'ブロックプログラミング基礎を完全マスター！', '中級Pythonに挑戦しよう！'),
      StageLevel.intermediate => ('🐍', '中級ユニット制覇！', 'Pythonプログラミング入門を完全マスター！', '上級Python応用に挑戦しよう！'),
      StageLevel.advanced     => ('🚀', '全ユニット制覇！', 'Python応用・自動化まで完全マスター！', '全実績を確認しよう！'),
      _                       => ('', '', '', ''),
    };
    if (icon.isEmpty) return;

    final delay = 4000 + widget.stars * 250 + (widget.didLevelUp ? 1500 : 0);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      showBadgeUnlock(
        context,
        icon: icon,
        name: name,
        message: message,
        points: 200,
        nextGoal: goal,
        onContinue: () {},
      );
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _confettiController.dispose();
    _levelUpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // もう一度挑戦する。QuizResultScreen自身の有効なcontextでナビゲーションするため、
  // quiz_screen.dart側の破棄済みcontextを閉じ込めたコールバックには依存しない。
  void _retry(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizScreen(challenge: widget.challenge),
      ),
    );
  }

  void _shareResult(BuildContext context) {
    HapticService.lightImpact();
    final nickname = ref.read(profileProvider).nickname;
    final stars = '⭐' * widget.stars;
    final pct = widget.totalCount > 0
        ? (widget.correctCount / widget.totalCount * 100).round()
        : 0;
    final timeLine = widget.sessionSeconds > 0
        ? '⏱ ${widget.sessionSeconds >= 60 ? '${widget.sessionSeconds ~/ 60}分${widget.sessionSeconds % 60}秒' : '${widget.sessionSeconds}秒'}\n'
        : '';
    final comboLine = widget.maxCombo >= 2
        ? '🔥 最大コンボ: ${widget.maxCombo}連続\n'
        : '';
    final resolvedLine = widget.resolvedWrongCount > 0
        ? '🎯 苦手克服: ${widget.resolvedWrongCount}問\n'
        : '';
    final speedLine = widget.speedBonusCount > 0
        ? '⚡ スピードボーナス: ${widget.speedBonusCount}回\n'
        : '';
    final text =
        '$nickname が「${widget.challenge.title}」をクリア！\n'
        '$stars ($pct% 正解)\n'
        '${widget.correctCount}/${widget.totalCount} 問正解\n'
        '$timeLine'
        '$comboLine'
        '$resolvedLine'
        '$speedLine'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 結果をコピーしました！'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // Enter/Space → 次のステージ（あれば）、なければリトライ
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (widget.nextStage != null && widget.stars >= 1) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizScreen(challenge: widget.nextStage!),
          ),
        );
      } else {
        _retry(context);
      }
      return KeyEventResult.handled;
    }
    // N → 次のステージ（正解かつ nextStage がある場合）
    if (key == LogicalKeyboardKey.keyN) {
      if (widget.nextStage != null && widget.stars >= 1) {
        HapticService.lightImpact();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizScreen(challenge: widget.nextStage!),
          ),
        );
        return KeyEventResult.handled;
      }
    }
    // R → もう一度
    if (key == LogicalKeyboardKey.keyR) {
      _retry(context);
      return KeyEventResult.handled;
    }
    // W → 間違い問題の復習（不正解がある場合のみ）
    if (key == LogicalKeyboardKey.keyW) {
      final wrong = widget.answers.where((a) => !a.isCorrect).toList();
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
    // S → シェア
    if (key == LogicalKeyboardKey.keyS) {
      _shareResult(context);
      return KeyEventResult.handled;
    }
    // F → お気に入りトグル
    if (key == LogicalKeyboardKey.keyF) {
      HapticService.selectionClick();
      ref.read(favoritesProvider.notifier).toggle(widget.challenge.id).then((result) {
        final (wasAdded, newCount) = result;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasAdded ? '❤️ お気に入りに追加しました' : '💔 お気に入りから削除しました'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        checkFavoriteMilestoneBadge(context, wasAdded: wasAdded, newCount: newCount);
      });
      return KeyEventResult.handled;
    }
    // Escape/Backspace → ステージ一覧へ
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('Enter / Space', '次のステージ（正解時）'),
        ('N', '次のステージへ'),
        ('R', 'もう一度挑戦'),
        ('S', '結果をシェア'),
        ('W', '間違い問題を復習'),
        ('F', 'お気に入りトグル'),
        ('Esc / BS', 'ステージ一覧へ'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String get _resultEmoji {
    if (widget.stars == 3) return '🎉';
    if (widget.stars == 2) return '😊';
    if (widget.stars == 1) return '🙂';
    return '😢';
  }

  String get _resultTitle {
    if (widget.stars == 3) return '完璧！';
    if (widget.stars == 2) return 'よくできました！';
    if (widget.stars == 1) return 'もう少し！';
    return 'もう一度チャレンジ！';
  }

  String get _resultSubtitle {
    if (widget.stars == 3) return 'すべて正解しました！';
    if (widget.stars == 2) return 'あと少しで満点です！';
    if (widget.stars == 1) return '復習してみましょう';
    return '次は頑張ろう！';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // シンプルなナビゲーションバー
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home_outlined,
                            color: kTextSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.challenge.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // シェアボタン
                      IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: kTextSecondary, size: 20),
                        tooltip: '結果をシェア (S)',
                        onPressed: () => _shareResult(context),
                      ),
                      // お気に入りトグルボタン
                      Consumer(builder: (context, ref, _) {
                        final isFav = ref.watch(favoritesProvider)
                            .isFavorite(widget.challenge.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.pink : kTextSecondary,
                            size: 20,
                          ),
                          tooltip: isFav ? 'お気に入りから削除' : 'お気に入りに追加',
                          onPressed: () {
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
                        );
                      }),
                    ],
                  ),
                ),
                // スクロールコンテンツ
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // 結果絵文字（バウンスアニメーション）
                        ScaleTransition(
                          scale: _bounceAnimation,
                          child: Text(
                            _resultEmoji,
                            style: const TextStyle(fontSize: 64),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _resultTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _resultSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                          ),
                        ),
                        // スコア改善インジケーター（再挑戦かつ改善した場合）
                        if (!widget.isFirstComplete && widget.stars > widget.previousStars) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🚀', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  'スコア改善！ ${'⭐' * widget.previousStars} → ${'⭐' * widget.stars}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(
                            begin: const Offset(0.7, 0.7),
                            curve: Curves.elasticOut,
                            duration: 600.ms,
                            delay: 300.ms,
                          ).fadeIn(duration: 200.ms, delay: 300.ms),
                        ],
                        // レベルアップバナー
                        if (_levelUpVisible) ...[
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _levelUpController,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _levelUpSlide.value),
                              child: Opacity(
                                opacity: _levelUpOpacity.value,
                                child: child,
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF39C12).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('⬆️', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'レベルアップ！ Lv.${widget.newLevel} になった！',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // スコアボックス（グラデーション）
                        _buildScoreBox()
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
                        const SizedBox(height: 16),
                        // 詳細カード
                        _buildDetailsCard()
                            .animate(delay: 120.ms)
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
                        // フラッシュカード提案（不正解がある場合）
                        if (widget.answers.any((a) => !a.isCorrect)) ...[
                          const SizedBox(height: 16),
                          _buildFlashcardSuggestionCard()
                              .animate(delay: 170.ms)
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
                        ],
                        const SizedBox(height: 16),
                        // 問題ごとの結果
                        _buildQuestionsCard()
                            .animate(delay: 220.ms)
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // ボタンエリア
                _buildButtons(context),
              ],
            ),
          ),
          // 紙吹雪（RepaintBoundary: パーティクル毎フレーム描画を親から分離）
          Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                colors: const [
                  kPrimaryColor,
                  Color(0xFFFFC107),
                  Color(0xFFE91E63),
                  Color(0xFF2196F3),
                  Color(0xFF4CAF50),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildScoreBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 正解数（カウントアップアニメーション）
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: widget.correctCount),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${widget.totalCount}問',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 星
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < widget.stars ? Icons.star : Icons.star_border,
                  color: i < widget.stars
                      ? const Color(0xFFFFC107)
                      : Colors.white38,
                  size: 36,
                ),
              ).animate(
                delay: Duration(milliseconds: 500 + i * 250),
              ).scale(
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
                duration: 500.ms,
              ),
            ),
          ),
          // 全問正解パーフェクトバナー
          if (widget.stars == 3) ...[
            const SizedBox(height: 10),
            _buildPerfectRunBanner(),
          ],
          // 正答率
          if (widget.totalCount > 0) ...[
            const SizedBox(height: 10),
            TweenAnimationBuilder<int>(
              tween: IntTween(
                begin: 0,
                end: (widget.correctCount / widget.totalCount * 100).round(),
              ),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, _) => Text(
                '正答率 $value%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerfectRunBanner() {
    final totalPerfectRuns = ref.read(progressProvider.notifier).totalPerfectRuns;
    final noPenalty = widget.answers.every((a) => !a.hintUsed);
    final label = totalPerfectRuns <= 1
        ? '初めての全問正解！'
        : '$totalPerfectRuns回目の全問正解！';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: noPenalty ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: noPenalty ? 0.55 : 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            noPenalty ? '💯' : '🌟',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
          if (noPenalty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ノーヒント',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: 1300.ms)
        .scale(
          begin: const Offset(0.4, 0.4),
          curve: Curves.elasticOut,
          duration: 600.ms,
        )
        .fadeIn(duration: 250.ms, delay: 1300.ms);
  }

  Widget _buildDetailsCard() {
    final wrongCount = widget.answers.where((a) => !a.isCorrect).length;
    final hintCount = widget.answers.where((a) => a.hintUsed).length;
    final earnedPoints = widget.stars * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: kPrimaryColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: '✅',
            label: '正解数',
            numValue: widget.correctCount,
            numSuffix: '問',
            valueColor: kPrimaryColor,
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: '❌',
            label: '不正解数',
            numValue: wrongCount,
            numSuffix: '問',
            valueColor: wrongCount > 0 ? Colors.red : kTextSecondary,
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: '⭐',
            label: '獲得ポイント',
            numValue: earnedPoints,
            numPrefix: '+',
            numSuffix: ' pt',
            valueColor: const Color(0xFFD68910),
          ),
          if (widget.maxCombo >= 2) ...[
            const Divider(height: 20),
            _DetailRow(
              icon: '🔥',
              label: '最大コンボ',
              numValue: widget.maxCombo,
              numSuffix: '連続',
              valueColor: const Color(0xFFE67E22),
            ),
          ],
          if (widget.resolvedWrongCount > 0) ...[
            const Divider(height: 20),
            _DetailRow(
              icon: '🎯',
              label: '苦手問題克服',
              numValue: widget.resolvedWrongCount,
              numSuffix: '問',
              valueColor: const Color(0xFF27AE60),
            ),
          ],
          if (widget.speedBonusCount > 0) ...[
            const Divider(height: 20),
            _DetailRow(
              icon: '⚡',
              label: 'スピードボーナス',
              numValue: widget.speedBonusCount,
              numSuffix: '回',
              valueColor: const Color(0xFF2980B9),
            ),
          ],
          if (widget.coinsEarned > 0) ...[
            const Divider(height: 20),
            _DetailRow(
              icon: '🪙',
              label: 'コイン獲得',
              numValue: widget.coinsEarned,
              numPrefix: '+',
              numSuffix: ' コイン',
              valueColor: const Color(0xFF8B6914),
            ),
          ],
          if (hintCount > 0) ...[
            const Divider(height: 20),
            _DetailRow(
              icon: '💡',
              label: 'ヒント使用',
              numValue: hintCount,
              numSuffix: '問',
              valueColor: const Color(0xFFF39C12),
            ),
          ],
          if (widget.sessionSeconds > 0) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('⏱️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      '所要時間',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.sessionSeconds >= 60
                      ? '${widget.sessionSeconds ~/ 60}分 ${widget.sessionSeconds % 60}秒'
                      : '${widget.sessionSeconds}秒',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
            // 平均回答時間/問
            if (widget.totalCount > 0) ...[
              const Divider(height: 20),
              _DetailRow(
                icon: '📊',
                label: '平均回答時間',
                numValue: (widget.sessionSeconds / widget.totalCount).round(),
                numSuffix: '秒/問',
                valueColor: Colors.blueGrey,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardSuggestionCard() {
    final wrongAnswers = widget.answers.where((a) => !a.isCorrect).toList();

    // 間違えた問題のテキストをもとに関連フラッシュカードを探す
    final wrongTexts = wrongAnswers.map((a) => a.questionText.toLowerCase()).join(' ');
    final relatedCards = kFlashcards.where((fc) {
      final front = fc.front.toLowerCase().replaceAll('()', '').replaceAll('(', '').replaceAll(')', '').trim();
      // 前面テキスト or カテゴリが問題文中に含まれるかチェック
      return front.length >= 2 && (wrongTexts.contains(front) || wrongTexts.contains(fc.category.toLowerCase()));
    }).take(2).toList();

    final suggestedCards = relatedCards.isNotEmpty ? relatedCards : kFlashcards.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF2A1133) : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              const Text('📚', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'フラッシュカードで復習しよう',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '間違えた問題に関連するカードを確認しよう',
            style: TextStyle(
              fontSize: 11,
              color: context.isDark ? const Color(0xFFBA68C8) : const Color(0xFF8E24AA),
            ),
          ),
          const SizedBox(height: 12),
          // 関連フラッシュカードチップ
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: suggestedCards.map((fc) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9C27B0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      fc.front,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticService.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FlashcardScreen()),
                );
              },
              icon: const Text('🃏', style: TextStyle(fontSize: 14)),
              label: const Text('フラッシュカードを開く'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '問題ごとの結果',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Builder(builder: (context) {
            final wrongState = ref.read(wrongAnswersProvider);
            return Column(
              children: widget.answers.asMap().entries.map((entry) {
                final index = entry.key;
                final answer = entry.value;
                return _QuestionResultItem(
                  index: index + 1,
                  question: answer.questionText,
                  isCorrect: answer.isCorrect,
                  selectedAnswer: answer.selectedAnswer,
                  correctAnswer: answer.correctAnswer,
                  hintUsed: answer.hintUsed,
                  wrongCount: wrongState.wrongCountFor(answer.questionText),
                  explanation: answer.explanation,
                  codeSnippet: answer.codeSnippet,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 次のステージへ（優先表示）
          if (widget.nextStage != null && widget.stars >= 1) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          QuizScreen(challenge: widget.nextStage!),
                    ),
                  );
                },
                icon: const Text('🚀', style: TextStyle(fontSize: 16)),
                label: Text(
                  '次へ: ${widget.nextStage!.title}',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 復習ボタン + 間違いだけ再挑戦
          if (widget.answers.any((a) => !a.isCorrect)) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final wrong =
                      widget.answers.where((a) => !a.isCorrect).toList();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizReviewScreen(wrongAnswers: wrong),
                    ),
                  );
                },
                icon: const Text('📖', style: TextStyle(fontSize: 14)),
                label: Text(
                  '間違えた問題を復習 (${widget.answers.where((a) => !a.isCorrect).length}問)',
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
            const SizedBox(height: 8),
            // 間違いだけ再挑戦
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticService.lightImpact();
                  final questions = widget.challenge.questions ?? [];
                  final wrongQuestions = widget.answers
                      .where((a) => !a.isCorrect)
                      .map((a) => questions.firstWhere(
                            (q) => q.text == a.questionText,
                            orElse: () => questions.isNotEmpty ? questions.first : null,
                          ))
                      .whereType<Question>()
                      .toList();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        challenge: widget.challenge,
                        overrideQuestions: wrongQuestions,
                      ),
                    ),
                  );
                },
                icon: const Text('🔁', style: TextStyle(fontSize: 14)),
                label: Text(
                  '間違いだけ再挑戦 (${widget.answers.where((a) => !a.isCorrect).length}問)',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 結果シェアボタン
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _shareResult(context),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('結果をシェア'),
              style: TextButton.styleFrom(
                foregroundColor: kTextSecondary,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          // もう一度 / ステージ一覧
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _retry(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('もう一度'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: context.subCardBg,
                    foregroundColor: context.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ステージ一覧へ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 詳細行
class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final int? numValue;          // アニメーション用数値
  final String numPrefix;
  final String numSuffix;
  final Color valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.numValue,
    this.numPrefix = '',
    this.numSuffix = '',
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: kTextSecondary),
        ),
        const Spacer(),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: numValue ?? 0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, v, _) => Text(
            '$numPrefix$v$numSuffix',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionResultItem extends StatefulWidget {
  final int index;
  final String question;
  final bool isCorrect;
  final String selectedAnswer;
  final String correctAnswer;
  final bool hintUsed;
  final int wrongCount;
  final String explanation;
  final String? codeSnippet;

  const _QuestionResultItem({
    required this.index,
    required this.question,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.correctAnswer,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.explanation = '',
    this.codeSnippet,
  });

  @override
  State<_QuestionResultItem> createState() => _QuestionResultItemState();
}

class _QuestionResultItemState extends State<_QuestionResultItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasDetail = widget.explanation.isNotEmpty || widget.codeSnippet != null;
    return GestureDetector(
      onTap: hasDetail ? () => setState(() => _expanded = !_expanded) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _expanded
              ? (context.isDark
                  ? const Color(0xFF1E2A1E)
                  : const Color(0xFFF0FAF0))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: context.borderColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 正誤アイコン
                  Text(
                    widget.isCorrect ? '✅' : '❌',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '第${widget.index}問: ${widget.question}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimary,
                                ),
                                maxLines: _expanded ? null : 2,
                                overflow: _expanded ? null : TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.hintUsed) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Text(
                                  '💡ヒント',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFE67E00),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (!widget.isCorrect && widget.wrongCount >= 2) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  '🔥×${widget.wrongCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFE64A00),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!widget.isCorrect) ...[
                          const SizedBox(height: 4),
                          Text(
                            '正解: ${widget.correctAnswer}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasDetail) ...[
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 18,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 展開時の解説
            if (_expanded && hasDetail) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.isCorrect
                      ? kPrimaryColor.withValues(alpha: 0.06)
                      : const Color(0xFFE74C3C).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isCorrect
                        ? kPrimaryColor.withValues(alpha: 0.2)
                        : const Color(0xFFE74C3C).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.explanation.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.explanation,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.codeSnippet != null && widget.codeSnippet!.isNotEmpty) ...[
                      if (widget.explanation.isNotEmpty) const SizedBox(height: 8),
                      CodeHighlightWidget(code: widget.codeSnippet!),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 回答記録データクラス
class QuizAnswer {
  final String questionText;
  final bool isCorrect;
  final String selectedAnswer;
  final String correctAnswer;
  final String explanation;
  final String? codeSnippet;
  final bool hintUsed;

  const QuizAnswer({
    required this.questionText,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.correctAnswer,
    this.explanation = '',
    this.codeSnippet,
    this.hintUsed = false,
  });
}
