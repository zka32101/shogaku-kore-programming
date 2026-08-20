import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/challenge.dart';
import '../providers/gallery_provider.dart';
import '../models/block_model.dart';
import '../providers/editor_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/challenges_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/robot_canvas.dart';
import '../services/sound_service.dart';
import 'badge_unlock_screen.dart';
import '../widgets/shortcut_help.dart';
import '../widgets/app_dialog.dart';
import '../providers/coin_provider.dart';
import '../providers/character_provider.dart';
import '../widgets/character_reaction_widget.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final Challenge challenge;

  const EditorScreen({super.key, required this.challenge});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _showHint = false;
  int _hintIndex = 0;
  late ConfettiController _confettiController;
  final FocusNode _focusNode = FocusNode();
  DateTime? _sessionStart;
  bool _timeRecorded = false;
  Block? _lastAddedBlock;
  CharacterMood _characterMood = CharacterMood.idle;
  String? _characterMessage;
  int _reactionToken = 0;
  final math.Random _rng = math.Random();

  /// キャラクターのリアクションを一時的に切り替え、しばらくしたらアイドルに戻す
  void _reactCharacter(
    CharacterMood mood, {
    String? message,
    Duration hold = const Duration(milliseconds: 2200),
  }) {
    final token = ++_reactionToken;
    setState(() {
      _characterMood = mood;
      _characterMessage = message;
    });
    Future.delayed(hold, () {
      if (!mounted || token != _reactionToken) return;
      setState(() {
        _characterMood = CharacterMood.idle;
        _characterMessage = null;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).reset();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // クリア時に記録済みでなければ記録（中途終了パス）
    if (!_timeRecorded && _sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
      if (elapsed > 0) {
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
    if (key == LogicalKeyboardKey.keyH) {
      if (widget.challenge.hints.isNotEmpty) {
        HapticService.selectionClick();
        setState(() => _showHint = !_showHint);
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.keyR) {
      HapticService.lightImpact();
      ref.read(editorProvider.notifier).reset();
      return KeyEventResult.handled;
    }
    // Z / Ctrl+Z → アンドゥ（元に戻す）
    if (key == LogicalKeyboardKey.keyZ) {
      final notifier = ref.read(editorProvider.notifier);
      if (notifier.canUndo) {
        HapticService.lightImpact();
        notifier.undo();
        return KeyEventResult.handled;
      }
    }
    // Y / Ctrl+Y → リドゥ（やり直し）
    if (key == LogicalKeyboardKey.keyY) {
      final notifier = ref.read(editorProvider.notifier);
      if (notifier.canRedo) {
        HapticService.lightImpact();
        notifier.redo();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.enter) {
      final editorState = ref.read(editorProvider);
      if (editorState.scriptBlocks.isNotEmpty && !editorState.hasSubmitted) {
        HapticService.lightImpact();
        ref.read(editorProvider.notifier).submitScript(widget.challenge.expectedOutput);
        Future.delayed(const Duration(milliseconds: 100), () {
          final s = ref.read(editorProvider);
          if (s.hasSubmitted) _showResult(s.isCorrect);
        });
        return KeyEventResult.handled;
      }
    }
    // F → お気に入りトグル
    if (key == LogicalKeyboardKey.keyF) {
      HapticService.selectionClick();
      ref.read(favoritesProvider.notifier).toggle(widget.challenge.id).then((result) {
        final (wasAdded, newCount) = result;
        if (!mounted) return;
        checkFavoriteMilestoneBadge(context, wasAdded: wasAdded, newCount: newCount);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      _confirmExit();
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('Enter', '実行（コードを提出）'),
        ('H', 'ヒントを表示'),
        ('Z', '元に戻す（アンドゥ）'),
        ('Y', 'やり直し（リドゥ）'),
        ('R', 'リセット（最初から）'),
        ('F', 'お気に入りトグル'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _confirmExit() async {
    final editorState = ref.read(editorProvider);
    // ブロックが未配置 or 提出済みならそのまま戻る
    if (editorState.scriptBlocks.isEmpty || editorState.hasSubmitted) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final confirmed = await AppDialog.confirm(
      context,
      emoji: '🧩',
      title: 'ブロックを捨てる？',
      message: '配置したブロックは保存されないよ。\nもどってやり直してみよう！',
      okLabel: '離れる',
      cancelLabel: 'つづける',
      danger: true,
    );
    if (confirmed && mounted) {
      Navigator.pop(context);
    }
  }

  void _showParamEditor(BuildContext context, Block block) {
    // パラメータがないブロックはスキップ
    if (block.params.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ParamEditorSheet(
        block: block,
        onUpdate: (key, value) {
          ref.read(editorProvider.notifier).updateBlockParam(block.id, key, value);
        },
      ),
    );
  }

  Future<void> _showResult(bool isCorrect) async {
    final isFirstComplete =
        !(ref.read(progressProvider)[widget.challenge.id]?.isCompleted ?? false);

    if (isCorrect) {
      // キャラクターが喜んでくれる & 育成が進む
      _reactCharacter(
        CharacterMood.celebrating,
        message: kCelebrationMessages[_rng.nextInt(kCelebrationMessages.length)],
        hold: const Duration(seconds: 4),
      );
      await ref.read(characterProvider.notifier).growFromCorrectAnswer(
            challengeType: 'visual',
            difficulty: widget.challenge.level,
          );
      if (!mounted) return;
      final charState = ref.read(characterProvider);
      if (charState.didStageUp && charState.lastGrowthMessage != null) {
        // ステージアップ！ 特別なリアクションで進化の瞬間を演出
        _reactCharacter(
          CharacterMood.celebrating,
          message: charState.lastGrowthMessage!,
          hold: const Duration(seconds: 4),
        );
        ref.read(characterProvider.notifier).clearGrowthMessage();
      }
    } else {
      // 不正解でも責めず、応援する
      _reactCharacter(
        CharacterMood.encouraging,
        message: kEncouragementMessages[_rng.nextInt(kEncouragementMessages.length)],
        hold: const Duration(seconds: 4),
      );
    }

    if (isCorrect) {
      final levelBefore = ref.read(progressProvider.notifier).currentLevel;
      ref.read(progressProvider.notifier).completeChallenge(
            widget.challenge.id,
            3,
          );
      final levelAfter = ref.read(progressProvider.notifier).currentLevel;

      // ギャラリーに作品を保存
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _saveWorkToGallery(ref);
        }
      });
      if (levelAfter > levelBefore) {
        Future.delayed(const Duration(milliseconds: 1200), () {
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

    // 次のビジュアル系ステージを探す
    final allChallenges = ref.read(allChallengesProvider);
    final currentIndex =
        allChallenges.indexWhere((c) => c.id == widget.challenge.id);
    Challenge? nextChallenge;
    if (isCorrect && currentIndex >= 0 && currentIndex < allChallenges.length - 1) {
      for (int i = currentIndex + 1; i < allChallenges.length; i++) {
        final c = allChallenges[i];
        if (c.type == ChallengeType.visual && c.isFree) {
          nextChallenge = c;
          break;
        }
      }
    }

    final elapsedSec = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inSeconds
        : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditorResultSheet(
        isCorrect: isCorrect,
        elapsedSeconds: elapsedSec,
        challengeTitle: widget.challenge.title,
        nextChallenge: nextChallenge,
        onRetry: () {
          Navigator.pop(ctx);
          ref.read(editorProvider.notifier).reset();
        },
        onComplete: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
        onNext: nextChallenge != null
            ? () {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        EditorScreen(challenge: nextChallenge!),
                  ),
                );
              }
            : null,
      ),
    );

    // ─── コイン獲得（正解時のみ）───
    if (isCorrect) {
      final earned = calcEditorCoins(widget.challenge.level);
      ref.read(coinProvider.notifier).earnCoins(earned);
    }

    // 効果音 + ハプティクス + 紙吹雪
    if (isCorrect) {
      HapticService.heavyImpact();
      SoundService().playComplete();
      _confettiController.play();
    } else {
      HapticService.mediumImpact();
      SoundService().playWrong();
    }

    // 正解時に学習時間を記録（バッジ確認用）
    if (isCorrect && !_timeRecorded) {
      _timeRecorded = true;
      ref.read(progressProvider.notifier)
          .recordLearningSeconds(elapsedSec)
          .then((badge) {
        if (badge == null || !mounted) return;
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (!mounted) return;
          showBadgeUnlock(
            context, // ignore: use_build_context_synchronously
            icon: badge.$1,
            name: badge.$2,
            message: badge.$3,
            points: 30,
            nextGoal: badge.$4,
            onContinue: () {},
          );
        });
      });
    }

    // 初クリア時: ユニット全制覇・3つ星マイルストーン・今日の目標達成バッジ
    if (isCorrect && isFirstComplete) {
      final notifier = ref.read(progressProvider.notifier);
      _checkUnitCompleteBadge(widget.challenge.level);
      _checkPerfectStageBadge(notifier.perfectStagesCount);
      final dailyGoal = ref.read(profileProvider).dailyGoal;
      _checkDailyGoalBadge(notifier.todayClearedCount, dailyGoal);
      // 累計獲得ポイント（スター）マイルストーンバッジ（初クリアのみ: +3スター）
      _checkStarBadge(notifier.totalStarsEarned, 3);
    }

    // 初クリア時バッジアンロック
    if (isCorrect && isFirstComplete) {
      final newCompletedCount = ref.read(progressProvider.notifier).completedCount;
      final milestone = switch (newCompletedCount) {
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
        _  => ('', '', '', ''),
      };

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (milestone.$1.isNotEmpty) {
          showBadgeUnlock(
            context,
            icon: milestone.$1,
            name: milestone.$2,
            message: milestone.$3,
            points: newCompletedCount * 10,
            nextGoal: milestone.$4,
            onContinue: () {},
          );
        } else {
          showBadgeUnlock(
            context,
            icon: widget.challenge.icon,
            name: widget.challenge.title,
            message: '${widget.challenge.title}をクリア！',
            points: 100,
            nextGoal: '次のステージに挑戦しよう！',
            onContinue: () {},
          );
        }
      });
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
        Future.delayed(const Duration(milliseconds: 9000), () {
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
        return;
      }
    }
  }

  void _checkUnitCompleteBadge(String level) {
    final allChallenges = ref.read(allChallengesProvider);
    final progressMap = ref.read(progressProvider);
    final unitChallenges = allChallenges.where((c) => c.level == level).toList();
    if (unitChallenges.isEmpty) return;
    final completedInUnit = unitChallenges.where((c) => progressMap[c.id]?.isCompleted ?? false).length;
    if (completedInUnit < unitChallenges.length) return;

    final (icon, name, message, goal) = switch (level) {
      StageLevel.beginner     => ('🧩', '初級ユニット制覇！', 'ブロックプログラミング基礎を完全マスター！', '中級Pythonに挑戦しよう！'),
      StageLevel.intermediate => ('🐍', '中級ユニット制覇！', 'Pythonプログラミング入門を完全マスター！', '上級Python応用に挑戦しよう！'),
      StageLevel.advanced     => ('🚀', '全ユニット制覇！', 'Python応用・自動化まで完全マスター！', '全実績を確認しよう！'),
      _                       => ('', '', '', ''),
    };
    if (icon.isEmpty) return;

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      showBadgeUnlock(context, icon: icon, name: name, message: message,
        points: 200, nextGoal: goal, onContinue: () {});
    });
  }

  void _checkPerfectStageBadge(int perfectCount) {
    final milestones = [
      (3,  '✨', '完璧主義者！',      '3ステージを3つ星でクリア！',               '5ステージ完璧を目指そう！'),
      (5,  '⭐', '5ステージ完璧！',  '5ステージを3つ星でクリア！',              '10ステージ完璧を目指そう！'),
      (10, '🌠', '3つ星コレクター！', '10ステージを3つ星でクリア！すごい！',       '20ステージ完璧を目指そう！'),
      (20, '🎖️', 'パーフェクトマスター！', '20ステージを3つ星でクリア！折り返し地点！', '全${AppConstants.totalStages}ステージ完璧制覇を目指そう！'),
      (AppConstants.totalStages, '👑', '全ステージ完璧！', '全${AppConstants.totalStages}ステージ3つ星クリア！パーフェクトコーダー！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in milestones) {
      if (perfectCount == target) {
        Future.delayed(const Duration(milliseconds: 5000), () {
          if (!mounted) return;
          showBadgeUnlock(context, icon: icon, name: name, message: message,
            points: target * 5, nextGoal: goal, onContinue: () {});
        });
        return;
      }
    }
  }

  void _checkDailyGoalBadge(int todayCleared, int goalTarget) {
    if (todayCleared != goalTarget) return;
    // 重複防止フラグを即座にセット（home_screen SnackBar との二重表示を防ぐ）
    ref.read(progressProvider.notifier).markDailyGoalShownToday();
    Future.delayed(const Duration(milliseconds: 6500), () {
      if (!mounted) return;
      showBadgeUnlock(context, // ignore: use_build_context_synchronously
        icon: '🎯',
        name: '今日の目標達成！',
        message: '今日の目標 $goalTargetステージクリア！',
        points: goalTarget * 10,
        nextGoal: '明日も目標を達成しよう！',
        onContinue: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ヘッダー
                _buildHeader(context),
            // キャラクターのひとこと（見守り役）
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: CharacterReactionWidget(
                  mood: _characterMood,
                  message: _characterMessage,
                ),
              ),
            ),
            // 課題説明
            Container(
              width: double.infinity,
              color: kPrimaryColor.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                widget.challenge.description,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            // ヒント
            if (_showHint && widget.challenge.hints.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                color: kStarColor.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.challenge.hints[_hintIndex % widget.challenge.hints.length],
                        style: TextStyle(fontSize: 13, color: context.textPrimary),
                      ),
                    ),
                    if (widget.challenge.hints.length > 1)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hintIndex = (_hintIndex + 1) % widget.challenge.hints.length;
                          });
                        },
                        child: const Text('次へ', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            // エディタ本体
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ブロックパレット
                  _buildBlockPalette(),
                  // スクリプトエリア
                  Expanded(child: _buildScriptArea(editorState)),
                ],
              ),
            ),
            // リアルタイムロボットプレビュー（ブロック追加時に即時表示）
            if (editorState.robotPath.length > 1)
              _buildRobotPreview(editorState),
            // テキスト出力（実行・回答後のみ）
            if (editorState.previewOutput.isNotEmpty)
              _buildTextPreview(editorState)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOut, duration: 300.ms),
            // アクションボタン
            _buildActionButtons(editorState),
              ],
            ),
          ),
          // 紙吹雪（正解時 / RepaintBoundary でパーティクル描画を分離）
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
      ),  // closes Scaffold (child of Focus)
    );    // closes Focus return
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _confirmExit,
          ),
          Expanded(
            child: Text(
              widget.challenge.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showHint ? kStarColor : Colors.white70,
            ),
            onPressed: () => setState(() => _showHint = !_showHint),
            tooltip: 'ヒント',
          ),
          Consumer(builder: (context, ref, _) {
            final isFav = ref.watch(favoritesProvider)
                .isFavorite(widget.challenge.id);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.pink.shade200 : Colors.white70,
                size: 20,
              ),
              tooltip: isFav ? 'お気に入りから削除' : 'お気に入りに追加',
              onPressed: () async {
                HapticService.selectionClick();
                final (wasAdded, newCount) = await ref.read(favoritesProvider.notifier).toggle(widget.challenge.id);
                if (!mounted) return;
                checkFavoriteMilestoneBadge(context, wasAdded: wasAdded, newCount: newCount); // ignore: use_build_context_synchronously
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.read(editorProvider.notifier).reset(),
            tooltip: 'リセット',
          ),
        ],
      ),
    );
  }

  Widget _buildBlockPalette() {
    // ステージで許可されたブロックのみ表示（空の場合は全ブロック表示）
    final allowedIds = widget.challenge.availableBlocks.map((b) => b.id).toSet();
    final paletteBlocks = allowedIds.isEmpty
        ? kAvailableBlocks
        : kAvailableBlocks.where((b) => allowedIds.contains(b.id)).toList();

    return Container(
      width: 148,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ブロック',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  '👆タップで追加・長押し＝ヘルプ',
                  style: TextStyle(fontSize: 9, color: kTextSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: paletteBlocks.length,
              itemBuilder: (context, index) {
                final block = paletteBlocks[index];
                return _BlockPaletteItem(
                  block: block,
                  onTap: () {
                    HapticService.lightImpact();
                    ref.read(editorProvider.notifier).addBlock(block);
                    setState(() => _lastAddedBlock = block);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _lastAddedBlock = null);
                    });
                    // 最初のブロックを置いたときだけ、そっと応援する
                    if (ref.read(editorProvider).scriptBlocks.length == 1) {
                      _reactCharacter(
                        CharacterMood.thinking,
                        message: kThinkingMessages[_rng.nextInt(kThinkingMessages.length)],
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptArea(EditorState editorState) {
    final notifier = ref.read(editorProvider.notifier);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.borderColor)),
          ),
          child: Row(
            children: [
              const Text(
                'スクリプト',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: kTextSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${editorState.scriptBlocks.length} ブロック',
                style: const TextStyle(fontSize: 11, color: kTextSecondary),
              ),
              const SizedBox(width: 4),
              // アンドゥボタン
              AnimatedOpacity(
                opacity: notifier.canUndo ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.undo, size: 18),
                    color: kTextSecondary,
                    tooltip: '元に戻す (Z)',
                    onPressed: notifier.canUndo
                        ? () {
                            HapticService.lightImpact();
                            notifier.undo();
                          }
                        : null,
                  ),
                ),
              ),
              // リドゥボタン
              AnimatedOpacity(
                opacity: notifier.canRedo ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.redo, size: 18),
                    color: kTextSecondary,
                    tooltip: 'やり直し (Y)',
                    onPressed: notifier.canRedo
                        ? () {
                            HapticService.lightImpact();
                            notifier.redo();
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 追加されたブロックの通知バナー
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _lastAddedBlock != null
              ? Container(
                  key: ValueKey(_lastAddedBlock!.id),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  color: _categoryColor(_lastAddedBlock!.category).withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      Text(_lastAddedBlock!.icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        '➕ ${_lastAddedBlock!.name} を追加！',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _categoryColor(_lastAddedBlock!.category),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 150.ms)
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
        Expanded(
          child: editorState.scriptBlocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🧩', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        '左のパレットから\nブロックを追加してね！',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: editorState.scriptBlocks.length,
                  // onReorderItem migration tracked as follow-up (signature
                  // differs; current onReorder behavior is correct as-is).
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    ref.read(editorProvider.notifier).moveBlock(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final block = editorState.scriptBlocks[index];
                    // NOTE: ReorderableListView.builder は itemBuilder が返す
                    // 一番外側のウィジェットに一意なキーを持つことを要求する。
                    // 以前は .animate() が一番外側になっており、そのラッパーに
                    // キーが付いていなかったため、ブロックの同一性を正しく
                    // 追跡できず、追加したブロックが一瞬表示されてすぐ消える
                    // 不具合が発生していた。.animate(key: ...) で明示的に
                    // 一番外側のウィジェットにもキーを渡すことで修正する。
                    return Dismissible(
                      key: ValueKey('dismiss_${block.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 4),
                            Text('削除', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        HapticService.mediumImpact();
                        return true;
                      },
                      onDismissed: (_) {
                        ref.read(editorProvider.notifier).removeBlock(index);
                      },
                      child: _ScriptBlockItem(
                        key: ValueKey(block.id),
                        block: block,
                        index: index,
                        onDelete: () {
                          HapticService.lightImpact();
                          ref.read(editorProvider.notifier).removeBlock(index);
                        },
                        onTap: () => _showParamEditor(context, block),
                      ),
                    ).animate(key: ValueKey(block.id)).fadeIn(duration: 250.ms).slideX(
                          begin: -0.1,
                          curve: Curves.easeOut,
                          duration: 250.ms,
                        );
                  },
                ),
        ),
      ],
    );
  }

  // ロボットキャンバス: ブロック追加時に即時表示（実行不要）
  Widget _buildRobotPreview(EditorState editorState) {
    final isCorrect = editorState.isCorrect && editorState.hasSubmitted;
    final isWrong = !editorState.isCorrect && editorState.hasSubmitted;

    return Container(
      height: 130,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1A2A2A) : const Color(0xFFF8FFFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? kPrimaryColor.withValues(alpha: 0.4)
              : isWrong
                  ? Colors.red.withValues(alpha: 0.3)
                  : context.borderColor,
          width: 1.5,
        ),
      ),
      // RepaintBoundary: ロボットアニメーション(毎フレーム再描画)を
      // 親ウィジェットツリーから分離し、不要な再描画を防ぐ
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: RobotCanvasWidget(
            path: editorState.robotPath,
            finalAngle: editorState.robotAngle,
            hasSubmitted: editorState.hasSubmitted,
            isCorrect: editorState.isCorrect,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  // テキスト出力: 実行・回答後のみ表示
  Widget _buildTextPreview(EditorState editorState) {
    final isCorrect = editorState.isCorrect && editorState.hasSubmitted;
    final isWrong = !editorState.isCorrect && editorState.hasSubmitted;

    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 60),
          color: isCorrect
              ? kPrimaryColor.withValues(alpha: 0.08)
              : isWrong
                  ? Colors.red.withValues(alpha: 0.07)
                  : context.subCardBg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            child: Text(
              editorState.previewOutput,
              style: TextStyle(
                fontSize: 11,
                color: isCorrect
                    ? kPrimaryColor
                    : isWrong
                        ? Colors.red
                        : context.textPrimary,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ),
        // 期待される出力（不正解かつ期待出力がある場合）
        if (isWrong && widget.challenge.expectedOutput.isNotEmpty)
          Container(
            width: double.infinity,
            color: kPrimaryColor.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ 期待される出力: ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor.withValues(alpha: 0.8),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.challenge.expectedOutput.replaceAll('\n', ' ／ '),
                    style: TextStyle(
                      fontSize: 10,
                      color: kPrimaryColor.withValues(alpha: 0.8),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms),
      ],
    );
  }

  Widget _buildActionButtons(EditorState editorState) {
    return SafeArea(
      top: false,
      child: _buildActionButtonsInner(editorState),
    );
  }

  Widget _buildActionButtonsInner(EditorState editorState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: editorState.scriptBlocks.isEmpty
                  ? null
                  : () {
                      ref.read(editorProvider.notifier).executeScript();
                      _reactCharacter(CharacterMood.excited, message: 'どうなるかな…！');
                    },
              icon: const Text('▶', style: TextStyle(fontSize: 12)),
              label: const Text('実行'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: (editorState.scriptBlocks.isEmpty || editorState.hasSubmitted)
                  ? null
                  : () {
                      ref
                          .read(editorProvider.notifier)
                          .submitScript(widget.challenge.expectedOutput);
                      Future.delayed(const Duration(milliseconds: 100), () {
                        final s = ref.read(editorProvider);
                        if (s.hasSubmitted) _showResult(s.isCorrect);
                      });
                    },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('回答する'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ブロックパレットアイテム ────────────────────────────────────────────────

class _BlockPaletteItem extends StatelessWidget {
  final Block block;
  final VoidCallback onTap;

  const _BlockPaletteItem({required this.block, required this.onTap});

  Color get _color => _categoryColor(block.category);

  void _showHelp(BuildContext context) {
    if (block.description.isEmpty) return;
    HapticService.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(block.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  block.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              block.description,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showHelp(context),
          borderRadius: BorderRadius.circular(8),
          splashColor: _color.withValues(alpha: 0.3),
          highlightColor: _color.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Text(block.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    block.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── スクリプトブロックアイテム ───────────────────────────────────────────────

class _ScriptBlockItem extends StatelessWidget {
  final Block block;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ScriptBlockItem({
    super.key,
    required this.block,
    required this.index,
    required this.onDelete,
    required this.onTap,
  });

  Color get _color => _categoryColor(block.category);

  @override
  Widget build(BuildContext context) {
    final hasParams = block.params.isNotEmpty;

    return GestureDetector(
      onTap: hasParams ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            // 行番号
            Container(
              width: 28,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  bottomLeft: Radius.circular(9),
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(block.icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.displayText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _color,
                    ),
                  ),
                  if (hasParams)
                    Text(
                      'タップして値を変更',
                      style: TextStyle(
                        fontSize: 9,
                        color: _color.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
            // 44x44 タッチエリアの削除ボタン
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: onDelete,
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── パラメータ編集ボトムシート ────────────────────────────────────────────────

class _ParamEditorSheet extends StatefulWidget {
  final Block block;
  final void Function(String key, dynamic value) onUpdate;

  const _ParamEditorSheet({required this.block, required this.onUpdate});

  @override
  State<_ParamEditorSheet> createState() => _ParamEditorSheetState();
}

class _ParamEditorSheetState extends State<_ParamEditorSheet> {
  late Map<String, dynamic> _params;

  @override
  void initState() {
    super.initState();
    _params = Map.from(widget.block.params);
  }

  String _labelFor(String key) {
    switch (key) {
      case 'steps':
        return '歩数';
      case 'degrees':
        return '角度（度）';
      case 'times':
        return '繰り返す回数';
      case 'value':
        return '変数の値';
      default:
        return key;
    }
  }

  int _minFor(String key) {
    switch (key) {
      case 'times':
        return 1;
      case 'steps':
        return 10;
      case 'degrees':
        return 10;
      default:
        return 0;
    }
  }

  int _maxFor(String key) {
    switch (key) {
      case 'times':
        return 20;
      case 'steps':
        return 500;
      case 'degrees':
        return 360;
      default:
        return 100;
    }
  }

  int _stepFor(String key) {
    switch (key) {
      case 'degrees':
        return 10;
      case 'steps':
        return 10;
      default:
        return 1;
    }
  }

  Color get _color => _categoryColor(widget.block.category);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // タイトル
            Row(
              children: [
                Text(widget.block.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(
                  widget.block.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // パラメータスライダー
            ...widget.block.params.keys.map((key) {
              final val = (_params[key] as num).toInt();
              final minVal = _minFor(key).toDouble();
              final maxVal = _maxFor(key).toDouble();
              final step = _stepFor(key);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _labelFor(key),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$val',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // +/- ボタン付きスライダー
                  Row(
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        color: _color,
                        onTap: () {
                          final newVal = (val - step).clamp(
                            minVal.toInt(),
                            maxVal.toInt(),
                          );
                          setState(() => _params[key] = newVal);
                          widget.onUpdate(key, newVal);
                        },
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _color,
                            thumbColor: _color,
                            inactiveTrackColor: _color.withValues(alpha: 0.2),
                            overlayColor: _color.withValues(alpha: 0.1),
                          ),
                          child: Slider(
                            value: val.toDouble().clamp(minVal, maxVal),
                            min: minVal,
                            max: maxVal,
                            divisions: ((maxVal - minVal) / step).round(),
                            onChanged: (v) {
                              final newVal = v.round();
                              setState(() => _params[key] = newVal);
                              widget.onUpdate(key, newVal);
                            },
                          ),
                        ),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        color: _color,
                        onTap: () {
                          final newVal = (val + step).clamp(
                            minVal.toInt(),
                            maxVal.toInt(),
                          );
                          setState(() => _params[key] = newVal);
                          widget.onUpdate(key, newVal);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '決定',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─── 提出結果ボトムシート ─────────────────────────────────────────────────────

class _EditorResultSheet extends StatefulWidget {
  final bool isCorrect;
  final VoidCallback onRetry;
  final VoidCallback onComplete;
  final Challenge? nextChallenge;
  final VoidCallback? onNext;
  final int elapsedSeconds;
  final String challengeTitle;

  const _EditorResultSheet({
    required this.isCorrect,
    required this.onRetry,
    required this.onComplete,
    this.nextChallenge,
    this.onNext,
    this.elapsedSeconds = 0,
    this.challengeTitle = '',
  });

  @override
  State<_EditorResultSheet> createState() => _EditorResultSheetState();
}

class _EditorResultSheetState extends State<_EditorResultSheet> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _shareResult(BuildContext context) {
    if (!widget.isCorrect) return;
    HapticService.lightImpact();
    final title = widget.challengeTitle.isNotEmpty
        ? widget.challengeTitle
        : 'ビジュアルプログラミング';
    final timeStr = widget.elapsedSeconds > 0
        ? '  ⏱ ${widget.elapsedSeconds >= 60 ? '${widget.elapsedSeconds ~/ 60}分${widget.elapsedSeconds % 60}秒' : '${widget.elapsedSeconds}秒'}'
        : '';
    final text =
        '🎉 「$title」をクリア！\n'
        '⭐⭐⭐ 3つ星達成！$timeStr\n'
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // Enter/Space → 次のステージ（あれば）or 完了
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (widget.isCorrect && widget.nextChallenge != null && widget.onNext != null) {
        widget.onNext!();
      } else if (widget.isCorrect) {
        widget.onComplete();
      } else {
        widget.onRetry();
      }
      return KeyEventResult.handled;
    }
    // S → シェア（正解時のみ）
    if (key == LogicalKeyboardKey.keyS && widget.isCorrect) {
      _shareResult(context);
      return KeyEventResult.handled;
    }
    // R → もう一度
    if (key == LogicalKeyboardKey.keyR && !widget.isCorrect) {
      widget.onRetry();
      return KeyEventResult.handled;
    }
    // Esc / Backspace → 一覧へ
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      widget.onComplete();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // 絵文字
          Text(
            widget.isCorrect ? '🎉' : '🤔',
            style: const TextStyle(fontSize: 64),
          ).animate().scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            curve: Curves.elasticOut,
            duration: 600.ms,
          ),
          const SizedBox(height: 12),
          // メッセージ
          Text(
            widget.isCorrect ? '正解！すごい！' : 'もう一度チャレンジ！',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.isCorrect ? kPrimaryColor : context.textPrimary,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut, duration: 300.ms),
          const SizedBox(height: 8),
          Text(
            widget.isCorrect
                ? 'プログラムが正しく組めたよ！'
                : 'ブロックの順番や種類を確認してみよう',
            style: const TextStyle(fontSize: 14, color: kTextSecondary),
            textAlign: TextAlign.center,
          ).animate(delay: 280.ms).fadeIn(duration: 300.ms),
          if (widget.isCorrect) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: kStarColor, size: 36)
                    .animate(delay: 350.ms).scale(begin: const Offset(0.3, 0.3), curve: Curves.elasticOut, duration: 450.ms),
                const Icon(Icons.star, color: kStarColor, size: 36)
                    .animate(delay: 420.ms).scale(begin: const Offset(0.3, 0.3), curve: Curves.elasticOut, duration: 450.ms),
                const Icon(Icons.star, color: kStarColor, size: 36)
                    .animate(delay: 490.ms).scale(begin: const Offset(0.3, 0.3), curve: Curves.elasticOut, duration: 450.ms),
              ],
            ),
            if (widget.elapsedSeconds > 0) ...[
              const SizedBox(height: 10),
              Text(
                '⏱ ${widget.elapsedSeconds >= 60 ? '${widget.elapsedSeconds ~/ 60}分${widget.elapsedSeconds % 60}秒' : '${widget.elapsedSeconds}秒'}',
                style: const TextStyle(fontSize: 13, color: kTextSecondary),
              ).animate(delay: 550.ms).fadeIn(duration: 300.ms),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _shareResult(context),
              icon: const Icon(Icons.share_outlined, size: 15, color: kTextSecondary),
              label: const Text('シェア (S)', style: TextStyle(fontSize: 12, color: kTextSecondary)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ).animate(delay: 600.ms).fadeIn(duration: 300.ms),
          ],
          const SizedBox(height: 20),
          // 次のステージへ（正解かつ次のステージがある）
          if (widget.isCorrect && widget.nextChallenge != null && widget.onNext != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onNext,
                icon: const Text('🚀', style: TextStyle(fontSize: 16)),
                label: Text(
                  '次へ: ${widget.nextChallenge!.title}',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ).animate(delay: 560.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 300.ms),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (!widget.isCorrect) ...[
                // 不正解: [一覧へ] [もう一度]
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onComplete,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('一覧へ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: widget.onRetry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('もう一度'),
                  ),
                ),
              ] else ...[
                // 正解: [一覧へ]
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: context.subCardBg,
                      foregroundColor: context.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('一覧へ'),
                  ),
                ),
              ],
            ],
          ).animate(delay: widget.isCorrect ? 620.ms : 350.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 300.ms),
        ],
      ),
    ),   // closes Container
    );   // closes Focus
  }
}

// ─── ユーティリティ ──────────────────────────────────────────────────────────

void _saveWorkToGallery(WidgetRef ref) async {
  // シンプルな実装: プレースホルダー画像をBase64で保存
  final placeholderImage = _generatePlaceholderImage();

  ref.read(galleryProvider.notifier).addWork(
    challengeId: '', // ここでは簡略化
    challengeTitle: '完成作品',
    blockCode: 'visual_program',
    resultImage: placeholderImage,
    difficulty: '初級',
  );
}

String _generatePlaceholderImage() {
  // 簡単なプレースホルダー画像（実際にはスクリーンショット等）
  const placeholder =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  return 'data:image/png;base64,$placeholder';
}

Color _categoryColor(BlockCategory category) {
  switch (category) {
    case BlockCategory.motion:
      return const Color(0xFF3498DB);
    case BlockCategory.control:
      return const Color(0xFFE67E22);
    case BlockCategory.variable:
      return const Color(0xFF9B59B6);
    case BlockCategory.function:
      return const Color(0xFF2ECC71);
  }
}
