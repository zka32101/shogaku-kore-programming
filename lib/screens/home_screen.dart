import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/challenge.dart';
import '../providers/progress_provider.dart';
import '../providers/challenges_provider.dart';
import '../providers/profile_provider.dart';
import 'achievements_screen.dart';
import 'badge_unlock_screen.dart';
import 'stage_list_screen.dart';
import 'editor_screen.dart';
import 'quiz_screen.dart';
import 'paywall_screen.dart';
import '../widgets/app_dialog.dart';
import 'daily_review_screen.dart';
import 'time_attack_screen.dart';
import 'ranking_screen.dart';
import 'quiz_review_screen.dart';
import 'wrong_answers_list_screen.dart';
import 'quiz_result_screen.dart' show QuizAnswer;
import 'flashcard_screen.dart';
import 'profile_screen.dart';
import '../providers/daily_review_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/shortcut_help.dart';
import '../widgets/code_highlight.dart';
import '../widgets/daily_puzzle_card.dart';
import 'why_programming_screen.dart';
import 'programming_basics_screen.dart';
import 'shop_screen.dart';
import 'reverse_teaching_screen.dart';
import 'gallery_screen.dart';
import 'weekly_report_screen.dart';
import 'character_screen.dart';
import '../providers/coin_provider.dart';
import '../providers/character_provider.dart';
import '../models/character_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _tipIndex;
  int? _prevLevel;
  int? _prevStreak;
  bool _goalCelebrated = false;
  bool _codeKingChecked = false; // セッション内でコード王チェック済みか
  bool _showMoreStats = false; // 「もっと見る」で表示する補助カード群の開閉状態
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _tipIndex = dayOfYear % _tips.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _nextTip() {
    setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // T → タイムアタック
    if (key == LogicalKeyboardKey.keyT) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimeAttackScreen()));
      return KeyEventResult.handled;
    }
    // R → ランキング
    if (key == LogicalKeyboardKey.keyR) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RankingScreen()));
      return KeyEventResult.handled;
    }
    // F → フラッシュカード
    if (key == LogicalKeyboardKey.keyF) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardScreen()));
      return KeyEventResult.handled;
    }
    // S → ステージ一覧
    if (key == LogicalKeyboardKey.keyS) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StageListScreen()));
      return KeyEventResult.handled;
    }
    // D → 今日の復習
    if (key == LogicalKeyboardKey.keyD) {
      final doneToday = ref.read(dailyReviewProvider).doneToday;
      if (!doneToday) {
        HapticService.lightImpact();
        SoundService().playTap();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyReviewScreen()));
        return KeyEventResult.handled;
      }
    }
    // V → 逆転モード
    if (key == LogicalKeyboardKey.keyV) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReverseTeachingScreen()));
      return KeyEventResult.handled;
    }
    // G → ギャラリー
    if (key == LogicalKeyboardKey.keyG) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GalleryScreen()));
      return KeyEventResult.handled;
    }
    // E → 週次レポート
    if (key == LogicalKeyboardKey.keyE) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeeklyReportScreen()));
      return KeyEventResult.handled;
    }
    // C → キャラクター育成
    if (key == LogicalKeyboardKey.keyC) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CharacterScreen()));
      return KeyEventResult.handled;
    }
    // N → 次のTips
    if (key == LogicalKeyboardKey.keyN) {
      _nextTip();
      return KeyEventResult.handled;
    }
    // Q → ランダム1問クイズ
    if (key == LogicalKeyboardKey.keyQ) {
      final allChallenges = ref.read(allChallengesProvider);
      final progressMap = ref.read(progressProvider);
      _showRandomQuickQuiz(context, allChallenges, progressMap);
      return KeyEventResult.handled;
    }
    // A → 実績画面
    if (key == LogicalKeyboardKey.keyA) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AchievementsScreen()));
      return KeyEventResult.handled;
    }
    // W → 苦手問題復習（苦手リストがある場合のみ）
    if (key == LogicalKeyboardKey.keyW) {
      final answers = ref.read(wrongAnswersProvider).answers;
      if (answers.isNotEmpty) {
        HapticService.lightImpact();
        SoundService().playTap();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QuizReviewScreen(wrongAnswers: answers)),
        );
        return KeyEventResult.handled;
      }
    }
    // P → プロフィール
    if (key == LogicalKeyboardKey.keyP) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      _showShortcutsHelp(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showShortcutsHelp(BuildContext context) {
    showShortcutsHelpDialog(context, shortcuts: const [
      ('T', 'タイムアタック'),
      ('R', 'ランキング'),
      ('F', 'フラッシュカード'),
      ('S', 'ステージ一覧'),
      ('A', '実績'),
      ('D', '今日の復習'),
      ('Q', 'ランダム1問クイズ'),
      ('W', '苦手問題復習'),
      ('P', 'プロフィール'),
      ('N', '次のTips'),
      ('?', 'このヘルプを表示'),
    ]);
  }

  void _showLevelUpOverlay(BuildContext context, int newLevel) {
    HapticService.heavyImpact();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'level_up',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: _LevelUpOverlay(newLevel: newLevel),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressMap = ref.watch(progressProvider);
    final progressNotifier = ref.read(progressProvider.notifier);
    final allChallenges = ref.watch(allChallengesProvider);
    final profile = ref.watch(profileProvider);
    // coinProvider は残高のみ select し、購入済みIDリスト変化では再ビルドしない
    final coinBalance = ref.watch(coinProvider.select((s) => s.balance));
    final reviewState = ref.watch(dailyReviewProvider);
    final reviewDoneToday = reviewState.doneToday;
    final reviewStreak = reviewState.reviewStreak; // 今日の表示・進捗トラッキング用（現在値）
    final longestReviewStreak = reviewState.longestReviewStreak; // バッジ判定用（最長）

    final wrongAnswersState = ref.watch(wrongAnswersProvider);
    final favoritesState = ref.watch(favoritesProvider);
    final flashState = ref.watch(flashcardProvider);
    final masteredCards = flashState.masteredIds.length;
    // 今週習得したフラッシュカード数
    final fcWeekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final fcWeekStartDay = DateTime(
      fcWeekStart.year, fcWeekStart.month, fcWeekStart.day,
    );
    final weeklyMasteredCards = flashState.masteredDates.values
        .where((d) => !d.isBefore(fcWeekStartDay))
        .length;
    final taBestMaxCombo  = ref.watch(timeAttackProvider).bestMaxCombo;
    final taPlayCount     = ref.watch(timeAttackProvider).playCount;
    final taBestCorrect   = ref.watch(timeAttackProvider).bestCorrect;
    final completedCount = progressNotifier.completedCount;
    final totalStars = progressNotifier.totalStarsEarned;
    final level = progressNotifier.currentLevel;
    final streakDays = progressNotifier.streakDays;

    // レベルアップ検出（初回非同期ロード時はオーバーレイを表示しない）
    ref.listen<Map<String, dynamic>>(progressProvider.select((_) => {
      'level':  ref.read(progressProvider.notifier).currentLevel,
      'loaded': ref.read(progressProvider.notifier).isLoaded,
    }), (prev, next) {
      final newLevel = next['level'] as int;
      // ロード前 → ロード完了の遷移は初期化のみ（オーバーレイ非表示）
      if ((prev?['loaded'] ?? false) == false) {
        _prevLevel = newLevel;
        return;
      }
      if (_prevLevel != null && newLevel > _prevLevel!) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showLevelUpOverlay(context, newLevel);
        });
      }
      _prevLevel = newLevel;
    });
    // ロード済みの場合はベースラインを即設定（画面戻り時の初回レベルアップを正しく検出）
    if (ref.read(progressProvider.notifier).isLoaded) {
      _prevLevel ??= level;
    }

    // ストリークマイルストーン検出（lastShownStreakMilestone で重複防止）
    ref.listen<Map<String, dynamic>>(progressProvider.select((_) => {
      'streak':      ref.read(progressProvider.notifier).streakDays,
      'lastMilestone': ref.read(progressProvider.notifier).lastShownStreakMilestone,
    }), (prev, next) {
      final newStreak     = next['streak']       as int;
      final lastMilestone = next['lastMilestone'] as int;
      if (_prevStreak != null && newStreak > _prevStreak!) {
        const milestones = [2, 3, 7, 14, 30, 60, 100];
        // 既に表示済みのマイルストーンは再表示しない
        if (milestones.contains(newStreak) && newStreak > lastMilestone) {
          ref.read(progressProvider.notifier).markStreakMilestoneShown(newStreak);
          final (icon, name, message, points, nextGoal) = switch (newStreak) {
            2   => ('💫', '2日連続',    '2日連続でチャレンジ！いいスタート！',            30,  '3日連続で「3日連続」バッジ獲得！'),
            3   => ('🔥', '3日連続',    '3日連続でチャレンジ！習慣になってきた！',         50,  '7日連続で「1週間連続」バッジ獲得！'),
            7   => ('🔥🔥', '1週間連続', '7日連続！1週間の習慣を維持できた！',            100, '14日連続で「2週間連続」バッジ獲得！'),
            14  => ('⚡⚡', '2週間連続', '14日連続！2週間続けるのは本物の努力！',          200, '30日連続で「チャンピオン」バッジ獲得！'),
            30  => ('🏆', 'チャンピオン', '30日連続！1ヶ月の継続は本物のチャンピオン！',   400, '60日連続で「1ヶ月連続」バッジ獲得！'),
            60  => ('🔥🔥🔥', '1ヶ月連続', '60日連続！伝説のコーダーへの道を歩んでいる！', 700, '100日連続で「100日連続！」バッジ獲得！'),
            _   => ('🌟', '100日連続！', '100日連続！あなたは伝説です！おめでとう！',     1000, 'このまま続けて最高記録を更新しよう！'),
          };
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            HapticService.heavyImpact();
            showBadgeUnlock(
              context, // ignore: use_build_context_synchronously
              icon: icon,
              name: name,
              message: message,
              points: points,
              nextGoal: nextGoal,
              onContinue: () {},
            );
          });
        }
      }
      _prevStreak = newStreak;
    });
    _prevStreak ??= streakDays;

    final todayCleared = progressNotifier.todayClearedCount;
    final comebackDays = progressNotifier.comebackDays;
    final progressPercent = completedCount / AppConstants.totalStages;

    // 1日の目標達成検出（result系画面でバッジ済みの場合はスキップ）
    if (!_goalCelebrated &&
        !progressNotifier.isDailyGoalShownToday &&
        todayCleared >= profile.dailyGoal &&
        profile.dailyGoal > 0) {
      _goalCelebrated = true;
      progressNotifier.markDailyGoalShownToday();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          HapticService.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今日の目標達成！',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${profile.dailyGoal}ステージクリアしたよ！',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              backgroundColor: kPrimaryColor,
            ),
          );
        }
      });
    }
    final starsToNext = progressNotifier.starsToNextLevel;
    final levelProgress = progressNotifier.levelProgress;

    // コード王バッジ検出（全ステージ制覇 + 100ポイント + 30日連続 を初めて同時達成）
    if (!_codeKingChecked &&
        !progressNotifier.codeKingBadgeShown &&
        completedCount >= AppConstants.totalStages &&
        totalStars >= 100 &&
        progressNotifier.longestStreak >= 30) {
      _codeKingChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(progressProvider.notifier).markCodeKingShown();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          HapticService.heavyImpact();
          showBadgeUnlock(
            context, // ignore: use_build_context_synchronously
            icon: '👑',
            name: 'コード王',
            message: '全ステージ制覇＋30日連続＋100ポイント達成！あなたは真のコード王！',
            points: 500,
            nextGoal: '全実績を確認しよう！',
            onContinue: () {},
          );
        });
      });
    }

    // ユニット別完了数（次のバッジカード用）
    int unitDone(String level) => allChallenges
        .where((c) => c.level == level && (progressMap[c.id]?.isCompleted ?? false))
        .length;
    int unitTotal(String level) => allChallenges.where((c) => c.level == level).length;
    final unitCounts = (
      unitDone(StageLevel.beginner), unitTotal(StageLevel.beginner),
      unitDone(StageLevel.intermediate), unitTotal(StageLevel.intermediate),
      unitDone(StageLevel.advanced), unitTotal(StageLevel.advanced),
    );

    // 次の未完了ステージを探す
    final nextChallenge = allChallenges.firstWhere(
      (c) => !(progressMap[c.id]?.isCompleted ?? false),
      orElse: () => allChallenges.first,
    );

    // 現在のユニット（最初の未完了ステージのレベル）
    final currentUnitLevel = allChallenges
        .firstWhere(
          (c) => !(progressMap[c.id]?.isCompleted ?? false),
          orElse: () => allChallenges.last,
        )
        .level;

    // 次のユニットレベル
    const levels = [
      StageLevel.beginner,
      StageLevel.intermediate,
      StageLevel.advanced,
    ];
    final currentLevelIndex = levels.indexOf(currentUnitLevel);
    final nextUnitLevel =
        currentLevelIndex < levels.length - 1 ? levels[currentLevelIndex + 1] : null;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      floatingActionButton: completedCount > 0
          ? Builder(builder: (ctx) {
              final hasWrong = !wrongAnswersState.isEmpty;
              return FloatingActionButton.extended(
                heroTag: 'quick_quiz_fab',
                onPressed: () => _showRandomQuickQuiz(context, allChallenges, progressMap),
                backgroundColor: hasWrong ? const Color(0xFFFF6B35) : kPrimaryColor,
                tooltip: hasWrong ? '🔥 苦手問題優先でランダム1問チャレンジ' : 'ランダム1問チャレンジ',
                icon: Text(hasWrong ? '🔥' : '🎲', style: const TextStyle(fontSize: 18)),
                label: Text(hasWrong ? '苦手' : '1問！', style: const TextStyle(fontSize: 11)),
              );
            })
          : null,
      body: Column(
        children: [
          _buildHeader(
              context, level, totalStars, completedCount, progressPercent, streakDays, todayCleared, profile, starsToNext, levelProgress, profile.dailyGoal, coinBalance),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // プログラミングの魅力（初回ユーザー向け）
                  if (completedCount < 3)
                    _buildWhyProgrammingCard(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1, curve: Curves.easeOut),
                  if (completedCount < 3) const SizedBox(height: 16),

                  // カムバックバナー（2日以上ぶりの起動）
                  if (comebackDays >= 2 && completedCount > 0) ...[
                    _buildComebackBanner(context, comebackDays)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.15, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                  ],

                  // ストリーク危機バナー（午後15時以降＆今日未クリア＆1日以上継続中）
                  if (streakDays >= 1 &&
                      todayCleared == 0 &&
                      DateTime.now().hour >= 15) ...[
                    _buildStreakDangerBanner(context)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.1, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                  ],

                  // 今日のチャレンジ（全ステージクリア時は達成カードを表示）
                  if (completedCount >= AppConstants.totalStages)
                    _buildAllClearCard(context)
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut)
                  else
                    _buildDailyMission(context, nextChallenge)
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 12),

                  // 今日の復習（完了済みステージがある場合のみ表示）
                  if (completedCount > 0) ...[
                    _buildDailyReviewCard(context, reviewDoneToday, reviewStreak)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 80.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut),
                    const SizedBox(height: 16),
                  ],

                  // 今日の詰め問（完了済みステージがある場合のみ表示）
                  if (completedCount > 0) ...[
                    const DailyPuzzleCard()
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 85.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut),
                    const SizedBox(height: 16),
                  ],

                  // キャラクターミニ表示
                  _buildCharacterMiniCard(context)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 90.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 16),

                  // 本日の学習サマリー（何か学習したことがある場合のみ表示）
                  ...() {
                    final todaySummary = _getTodayLearningStats(progressNotifier, ref);
                    if (todaySummary.isEmpty) return <Widget>[];
                    return [
                      _buildTodayLearningCard(context, todaySummary)
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 85.ms)
                          .slideY(begin: 0.12, curve: Curves.easeOut),
                      const SizedBox(height: 12),
                    ];
                  }(),

                  // 苦手問題復習カード（過去の間違い問題がある場合のみ）
                  if (!wrongAnswersState.isEmpty) ...[
                    _buildWrongAnswersCard(context, wrongAnswersState.count)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 90.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                  ],

                  // お気に入りステージカード
                  if (favoritesState.count > 0) ...[
                    _buildFavoritesCard(context, favoritesState.count, allChallenges, favoritesState.favoriteIds)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 95.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                  ],

                  // もっと見る（学習ストリーク・週間チャレンジなど詳細統計）
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        HapticService.lightImpact();
                        setState(() => _showMoreStats = !_showMoreStats);
                      },
                      icon: Icon(
                        _showMoreStats ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(
                        _showMoreStats ? 'とじる' : 'もっと見る',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  if (_showMoreStats) ...[
                  // 学習ストリークカード（1日以上の連続記録がある場合のみ表示）
                  if (streakDays > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF6B35).withValues(alpha: 0.08),
                            const Color(0xFFFF8C42).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('🔥', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '学習ストリーク',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      streakDays >= progressNotifier.longestStreak && streakDays > 0
                                          ? '🎯 ベスト記録を更新中！'
                                          : streakDays >= progressNotifier.longestStreak - 2 && progressNotifier.longestStreak > 0
                                              ? '🔥 あと${progressNotifier.longestStreak - streakDays}日でベスト記録！'
                                              : '💪 連続学習を継続中！',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$streakDays',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF6B35),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '日間',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBEBEB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${progressNotifier.longestStreak}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '日（最高記録）',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 87.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                  ],

                  // フラッシュカード復習スケジュール（7日以上前に習得したカテゴリーがある場合）
                  ...() {
                    if (masteredCards == 0) return <Widget>[];
                    final flashcardState = ref.read(flashcardProvider);
                    final reviewNeeded = _getFlashcardsNeedingReview(flashcardState);
                    if (reviewNeeded.isEmpty) return <Widget>[];
                    return [
                      _buildFlashcardReviewScheduleCard(context, reviewNeeded)
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 98.ms)
                          .slideY(begin: 0.12, curve: Curves.easeOut),
                      const SizedBox(height: 12),
                    ];
                  }(),

                  // 弱点ステージ再挑戦カード（3つ星未取得のクリア済みステージ）
                  ...() {
                    final weakStages = allChallenges
                        .where((c) =>
                            (progressMap[c.id]?.isCompleted ?? false) &&
                            (progressMap[c.id]?.starsEarned ?? 3) < 3)
                        .take(3)
                        .toList();
                    if (weakStages.isEmpty) return <Widget>[];
                    return [
                      _buildWeakStagesCard(context, weakStages, progressMap)
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 96.ms)
                          .slideY(begin: 0.12, curve: Curves.easeOut),
                      const SizedBox(height: 12),
                    ];
                  }(),

                  // 今週のチャレンジ
                  if (completedCount > 0) ...[
                    _buildWeeklyChallenge(context, progressNotifier, completedCount, streakDays, favoritesState.count, masteredCards, reviewStreak, reviewState.totalReviewsCompleted, weeklyMasteredCards, wrongAnswersState.totalResolvedCount, wrongAnswersState.count)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 97.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                  ],

                  // 7日間アクティビティ（1回でもクリアしたことがある場合のみ表示）
                  if (completedCount > 0) ...[
                    _buildActivityCalendar(context, progressNotifier.activityByDate)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 100.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 16),
                  ],

                  // 今日のプログラミングTips
                  _buildDailyTip(context)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 120.ms)
                      .slideY(begin: 0.12, curve: Curves.easeOut),
                  const SizedBox(height: 16),

                  ],

                  // ミニゲーム（タイムアタック・ランキング）
                  _buildMiniGames(context)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 160.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut),
                  const SizedBox(height: 12),

                  // コインショップカード
                  _buildShopCard(context, coinBalance)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 175.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOut),
                  const SizedBox(height: 16),

                  // 現在のユニット
                  Text(
                    '現在のユニット',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  const SizedBox(height: 8),
                  _buildUnitCard(context, currentUnitLevel, progressMap, allChallenges)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 220.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOut),

                  // 次のユニット
                  if (nextUnitLevel != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '次のユニット',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 260.ms),
                    const SizedBox(height: 8),
                    _buildUnitCard(context, nextUnitLevel, progressMap, allChallenges)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 280.ms)
                        .slideY(begin: 0.08, curve: Curves.easeOut),
                  ],

                  const SizedBox(height: 16),

                  // 次のバッジ進捗カード
                  _buildNextBadgeCard(context, completedCount, totalStars, streakDays, favoritesState.count, progressNotifier.totalLearningSeconds ~/ 60, longestReviewStreak, reviewState.totalReviewsCompleted, taBestMaxCombo, masteredCards, taPlayCount, unitCounts, progressNotifier.perfectStagesCount, progressNotifier.totalQuestionsAnswered, taBestCorrect, totalResolvedCount: wrongAnswersState.totalResolvedCount, totalPerfectRuns: progressNotifier.totalPerfectRuns)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 300.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // はじめての方向けナビゲーションボタン
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticService.lightImpact();
                            SoundService().playTap();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WhyProgrammingScreen(),
                              ),
                            );
                          },
                          icon: const Text('🎓', style: TextStyle(fontSize: 16)),
                          label: const Text(
                            'はじめに',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticService.lightImpact();
                            SoundService().playTap();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProgrammingBasicsScreen(),
                              ),
                            );
                          },
                          icon: const Text('📚', style: TextStyle(fontSize: 16)),
                          label: const Text(
                            'プログラミング基礎',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 320.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOut),

                  const SizedBox(height: 10),

                  // CTA ボタン（全幅）
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.lightImpact();
                        SoundService().playTap();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StageListScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('チャレンジを開始', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  String _buildGreeting(String nickname) {
    final hour = DateTime.now().hour;
    // ニックネームがあれば末尾に追加（例: "☀️ おはよう、たんけんか！"）
    final String suffix = nickname.isNotEmpty ? '、$nickname！' : '！';
    if (hour < 5) {
      return '🌙 夜ふかし中$suffix';
    } else if (hour < 10) {
      return '☀️ おはよう$suffix';
    } else if (hour < 12) {
      return '🌤️ 今日も学ぼう$suffix';
    } else if (hour < 14) {
      return '🍱 ランチ後にひとゲーム$suffix';
    } else if (hour < 17) {
      return '🎮 午後もがんばれ$suffix';
    } else if (hour < 19) {
      return '🌇 もうひと踏ん張り$suffix';
    } else if (hour < 21) {
      return '🌆 今日の復習しよう$suffix';
    } else {
      return '🌙 今日最後のステージ$suffix';
    }
  }

  Widget _buildHeader(
    BuildContext context,
    int level,
    int totalStars,
    int completedCount,
    double progressPercent,
    int streakDays,
    int todayCleared,
    ProfileState profile,
    int starsToNext,
    double levelProgress,
    int dailyGoal,
    int coinBalance,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 科目ラベル
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'プログラミング',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _buildGreeting(profile.nickname),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // ユーザー情報行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(profile.avatarEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'レベル $level',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              Row(
                children: [
                  if (streakDays >= 2) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Text(
                            '$streakDays日',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '$totalStars pt',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  // コイン残高バッジ（タップでショップ）
                  GestureDetector(
                    onTap: () {
                      HapticService.lightImpact();
                      SoundService().playTap();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ShopScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Text(
                            '$coinBalance',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // レベルXPバー
          Row(
            children: [
              Text(
                'Lv.$level',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: levelProgress),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                starsToNext > 0 ? 'Lv.${level + 1}' : 'MAX',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount / ${AppConstants.totalStages} ステージ完了',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              // 今日の目標インジケーター
              _DailyGoalDots(todayCleared: todayCleared, dailyGoal: dailyGoal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWrongAnswersCard(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('📝', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '苦手問題を復習しよう',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE74C3C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '間違えた問題が $count 件あるよ',
                      style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 最も間違えた問題プレビュー（2回以上ある場合のみ）
          Builder(builder: (ctx) {
            final ws = ref.read(wrongAnswersProvider);
            if (ws.maxWrongCount < 2) return const SizedBox.shrink();
            final top = [...ws.answers]
              ..sort((a, b) => ws.wrongCountFor(b.questionText)
                  .compareTo(ws.wrongCountFor(a.questionText)));
            final worst = top.first;
            final cnt = ws.wrongCountFor(worst.questionText);
            final qShort = worst.questionText.length > 30
                ? '${worst.questionText.substring(0, 30)}…'
                : worst.questionText;
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔥×$cnt',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qShort,
                      style: TextStyle(
                        fontSize: 11,
                        color: ctx.isDark ? Colors.white70 : const Color(0xFF555555),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Text('📋', style: TextStyle(fontSize: 13)),
                  label: const Text('カード復習', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticService.lightImpact();
                    SoundService().playTap();
                    final answers = ref.read(wrongAnswersProvider).answers;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizReviewScreen(wrongAnswers: answers),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE74C3C),
                    side: const BorderSide(color: Color(0xFFE74C3C), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Text('❓', style: TextStyle(fontSize: 13)),
                  label: const Text('クイズ挑戦', style: TextStyle(fontSize: 12)),
                  onPressed: () => _startWrongAnswerQuiz(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          // 一覧リンク
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                HapticService.selectionClick();
                SoundService().playTap();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WrongAnswersListScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE74C3C),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '一覧を見る →',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startWrongAnswerQuiz(BuildContext context) {
    HapticService.mediumImpact();
    SoundService().playTap();
    final wrongState = ref.read(wrongAnswersProvider);
    final answers = wrongState.answers;
    if (answers.isEmpty) return;

    // 間違い回数の多い問題を先頭に並べる（同頻度はランダム）
    final sortedAnswers = [...answers]..shuffle(Random());
    sortedAnswers.sort((a, b) => wrongState.wrongCountFor(b.questionText)
        .compareTo(wrongState.wrongCountFor(a.questionText)));

    final rng = Random();
    // 選択肢のみシャッフル（問題の順序は頻度ソートを保持）
    final questions = sortedAnswers.map((a) {
      // 選択肢を correctAnswer + selectedAnswer から再構成
      final optSet = {a.correctAnswer, a.selectedAnswer}
          .where((s) => s.isNotEmpty)
          .toList();
      if (optSet.length < 2) optSet.add('（別の選択肢）');
      optSet.shuffle(rng);
      final ci = optSet.indexOf(a.correctAnswer);
      return Question(
        id: 'wrong_${a.questionText.hashCode.toRadixString(16)}',
        text: a.questionText,
        codeSnippet: a.codeSnippet,
        options: optSet,
        correctIndex: ci < 0 ? 0 : ci,
        explanation: a.explanation,
      );
    }).toList();

    final challenge = Challenge(
      id: 'wrong_answers_quiz',
      stageNumber: 0,
      title: '苦手問題クイズ',
      description: '間違えた問題をもう一度解こう！',
      type: ChallengeType.quiz,
      level: StageLevel.beginner,
      icon: '📝',
      isFree: true,
      questions: questions,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(challenge: challenge)),
    );
  }

  Widget _buildFavoritesCard(
    BuildContext context,
    int count,
    List<Challenge> allChallenges,
    Set<String> favoriteIds,
  ) {
    final favorites = allChallenges
        .where((c) => favoriteIds.contains(c.id))
        .take(3)
        .toList();

    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        SoundService().playTap();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StageListScreen(openFavorites: true)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE67E22).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('⭐', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'お気に入り ($count)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: favorites.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(c.icon, style: const TextStyle(fontSize: 18)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFE67E22)),
          ],
        ),
      ),
    );
  }

  /// 本日の学習統計を取得（複数の学習活動から集計）
  Map<String, dynamic> _getTodayLearningStats(
    ProgressNotifier progressNotifier,
    WidgetRef ref,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 本日のステージクリア数
    final todayClears = progressNotifier.activityByDate[today] ?? 0;

    // 本日の習得フラッシュカード数
    final flashcardState = ref.read(flashcardProvider);
    int todayMasteredCards = 0;
    for (final card in kFlashcards) {
      final masteredDate = flashcardState.masteredDateFor(card.id);
      if (masteredDate != null) {
        final masteredDay = DateTime(masteredDate.year, masteredDate.month, masteredDate.day);
        if (masteredDay == today) {
          todayMasteredCards++;
        }
      }
    }

    // 本日の復習完了状況
    final reviewState = ref.read(dailyReviewProvider);
    final todayReviewDone = reviewState.doneToday;

    // 本日の学習時間（全体の学習時間を使用）
    // 注：完璧なトラッキングではなく、近似値
    final totalSeconds = progressNotifier.totalLearningSeconds;

    // データがない場合は空マップを返す
    if (todayClears == 0 && todayMasteredCards == 0 && !todayReviewDone) {
      return {};
    }

    return {
      'clears': todayClears,
      'masteredCards': todayMasteredCards,
      'reviewDone': todayReviewDone,
      'totalSeconds': totalSeconds,
    };
  }

  Widget _buildTodayLearningCard(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final clears = stats['clears'] as int? ?? 0;
    final masteredCards = stats['masteredCards'] as int? ?? 0;
    final reviewDone = stats['reviewDone'] as bool? ?? false;
    final totalSeconds = stats['totalSeconds'] as int? ?? 0;
    final totalMinutes = totalSeconds ~/ 60;

    // 成果を数値化（ゲーミフィケーション用）
    int achievementPoints = 0;
    final achievements = <String>[];

    if (clears > 0) {
      achievementPoints += clears * 10;
      achievements.add('$clears ステージクリア');
    }
    if (masteredCards > 0) {
      achievementPoints += masteredCards * 5;
      achievements.add('フラッシュカード $masteredCards 枚習得');
    }
    if (reviewDone) {
      achievementPoints += 20;
      achievements.add('本日の復習完了');
    }

    final emoji = achievementPoints >= 50
        ? '🎉'
        : achievementPoints >= 30
            ? '😊'
            : '✨';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF27AE60).withValues(alpha: 0.08),
            const Color(0xFF2ECC71).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF27AE60).withValues(alpha: 0.3),
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本日の学習成果',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ポイント: $achievementPoints',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: achievements.map((achievement) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  achievement,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27AE60),
                  ),
                ),
              );
            }).toList(),
          ),
          if (totalMinutes > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '⏱ 累計学習時間: ${totalMinutes >= 60 ? '${totalMinutes ~/ 60}時間${totalMinutes % 60}分' : '$totalMinutes分'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// フラッシュカード習得日から、復習が必要なカテゴリーを取得
  /// 7-30日前に習得したカードを"復習中"、30日以上前を"要復習"と分類
  Map<String, ({int count, String status})> _getFlashcardsNeedingReview(FlashcardState flashcardState) {
    final now = DateTime.now();
    final reviewMap = <String, ({int count, String status})>{};

    // flashcard_screen.dartから kFlashcardsをインポートしているので利用可能
    for (final card in kFlashcards) {
      final masteredDate = flashcardState.masteredDateFor(card.id);
      if (masteredDate == null) continue;

      final daysSince = now.difference(masteredDate).inDays;
      // 7-14日前: 復習中, 15日以上: 要復習
      if (daysSince >= 7 && daysSince <= 30) {
        if (!reviewMap.containsKey(card.category)) {
          reviewMap[card.category] = (count: 0, status: daysSince <= 14 ? 'reviewing' : 'needed');
        }
        final current = reviewMap[card.category]!;
        reviewMap[card.category] = (count: current.count + 1, status: current.status);
      }
    }

    // 統計情報を含む場合のみ返す
    return reviewMap.isEmpty ? {} : reviewMap;
  }

  Widget _buildFlashcardReviewScheduleCard(
    BuildContext context,
    Map<String, ({int count, String status})> reviewNeeded,
  ) {
    // ソート: "要復習" → "復習中"、その後にカテゴリ名でソート
    final sorted = reviewNeeded.entries.toList()
      ..sort((a, b) {
        final aStatus = a.value.status == 'needed' ? 0 : 1;
        final bStatus = b.value.status == 'needed' ? 0 : 1;
        if (aStatus != bStatus) return aStatus.compareTo(bStatus);
        return a.key.compareTo(b.key);
      });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8E44AD).withValues(alpha: 0.3),
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8E44AD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('📚', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'フラッシュカード復習スケジュール',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E44AB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '習得後の復習が効果的です',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FlashcardScreen()),
                  );
                },
                child: const Icon(Icons.chevron_right, color: Color(0xFF8E44AB)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sorted.map((entry) {
              final category = entry.key;
              final (:count, :status) = entry.value;
              final isNeeded = status == 'needed';
              return GestureDetector(
                onTap: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  // TODO: Navigate to FlashcardScreen with category pre-selected
                  // For now, just open the flashcard screen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FlashcardScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNeeded
                        ? const Color(0xFFE74C3C).withValues(alpha: 0.1)
                        : const Color(0xFF27AE60).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isNeeded
                          ? const Color(0xFFE74C3C).withValues(alpha: 0.4)
                          : const Color(0xFF27AE60).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNeeded ? '🔥' : '📖',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$category $count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isNeeded
                              ? const Color(0xFFE74C3C)
                              : const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '🔥 = 要復習 (30日以上前)  📖 = 復習中 (7-29日前)',
                style: TextStyle(
                  fontSize: 9,
                  color: context.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeakStagesCard(
    BuildContext context,
    List<Challenge> weakStages,
    Map<String, UserProgress> progressMap,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF39C12).withValues(alpha: 0.35),
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('⬆️', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3つ星を狙え！',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE67E22),
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      '満点でさらにポイントアップ！',
                      style: TextStyle(fontSize: 10, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...weakStages.map((c) {
            final stars = progressMap[c.id]?.starsEarned ?? 0;
            final levelColor = c.level == StageLevel.beginner
                ? kPrimaryColor
                : c.level == StageLevel.intermediate
                    ? const Color(0xFF9B59B6)
                    : const Color(0xFFE67E22);
            // 苦手問題があるか確認
            final wrongState = ref.read(wrongAnswersProvider);
            final wrongCount = c.type == ChallengeType.quiz
                ? c.questions.fold<int>(0, (sum, q) => sum + wrongState.wrongCountFor(q.text))
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => c.type == ChallengeType.visual
                          ? EditorScreen(challenge: c)
                          : QuizScreen(challenge: c),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: levelColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (wrongCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '🔥×$wrongCount',
                            style: const TextStyle(fontSize: 9, color: Color(0xFFE64A00)),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          3,
                          (i) => Icon(
                            i < stars ? Icons.star : Icons.star_border,
                            size: 14,
                            color: i < stars ? kStarColor : context.borderColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 14, color: kTextSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// プレミアム限定ステージなら課金モーダルを表示し、無料ステージなら
  /// エディタ／クイズ画面へ遷移する共通ヘルパー。
  ///
  /// 「今日のチャレンジ」カード・連続記録危機バナー・おかえりバナーの
  /// 3箇所から呼び出され、プレミアムロックの回避（ペイウォールバイパス）を防ぐ。
  void _openChallengeOrShowPaywall(BuildContext context, Challenge challenge) {
    if (!challenge.isFree) {
      HapticService.lightImpact();
      SoundService().playTap();
      AppDialog.confirm(
        context,
        emoji: '🔒',
        title: 'プレミアム限定ステージ',
        message: 'このステージはプレミアム会員限定です。\nアップグレードしてすべてのステージを解放しよう！',
        okLabel: 'アップグレード',
        cancelLabel: 'とじる',
      ).then((upgrade) {
        if (upgrade && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        }
      });
      return;
    }
    HapticService.lightImpact();
    SoundService().playTap();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => challenge.type == ChallengeType.visual
            ? EditorScreen(challenge: challenge)
            : QuizScreen(challenge: challenge),
      ),
    );
  }

  Widget _buildStreakDangerBanner(BuildContext context) {
    final streakDays = ref.read(progressProvider.notifier).streakDays;
    final allChallenges = ref.read(allChallengesProvider);
    final progressMap = ref.read(progressProvider);
    return GestureDetector(
      onTap: () {
        final next = allChallenges.firstWhere(
          (c) => !(progressMap[c.id]?.isCompleted ?? false),
          orElse: () => allChallenges.first,
        );
        _openChallengeOrShowPaywall(context, next);
      },
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.deepOrange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streakDays >= 2 ? '$streakDays日連続が消えそう！' : 'ストリークを始めよう！',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateTime.now().hour >= 20
                      ? '今夜中に1ステージクリアしてストリークを守ろう！'
                      : '今日中に1ステージクリアしてストリークを維持しよう！',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '今すぐ →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildWhyProgrammingCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        SoundService().playTap();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WhyProgrammingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667EEA).withValues(alpha: 0.12),
              const Color(0xFF764BA2).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF667EEA).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              children: [
                const Text(
                  '✨ プログラミングで何ができる？',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667EEA),
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: context.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            // 説明テキスト
            Text(
              '🎮 キミの好きなゲームも、アプリも、ぜんぶプログラミングで作られているよ！\n\nプログラミングを覚えると、キミのアイデアがホンモノになるんだ。なりたいものになろう！',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // アイコン表示
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _CapabilityBadge(emoji: '🎮', label: 'ゲームを作る'),
                _CapabilityBadge(emoji: '🤖', label: 'ロボットを動かす'),
                _CapabilityBadge(emoji: '📱', label: 'アプリを作る'),
                _CapabilityBadge(emoji: '🚀', label: 'AIを作る'),
                _CapabilityBadge(emoji: '🎨', label: '絵やCGをかく'),
                _CapabilityBadge(emoji: '🌍', label: '世界とつながる'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'タップして、もっと知ろう →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF667EEA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComebackBanner(BuildContext context, int days) {
    final (emoji, msg) = switch (days) {
      2 => ('🙂', '2日ぶりの帰還！また一緒に学ぼう！'),
      3 => ('😊', '3日ぶりだね！コードを思い出そう！'),
      4 || 5 || 6 => ('💪', '$days日ぶりの復帰！ここから再スタート！'),
      7 => ('🎉', '1週間ぶり！まずは1問からやってみよう！'),
      _ => ('👋', '$days日ぶり！ウェルカムバック！'),
    };
    final bonusPts = (days * 5).clamp(5, 30);
    final bonusAwarded = ref.read(progressProvider.notifier).comebackBonusAwardedToday;
    final allChallenges = ref.read(allChallengesProvider);
    final progressMap = ref.read(progressProvider);
    return GestureDetector(
      onTap: () {
        final next = allChallenges.firstWhere(
          (c) => !(progressMap[c.id]?.isCompleted ?? false),
          orElse: () => allChallenges.first,
        );
        _openChallengeOrShowPaywall(context, next);
      },
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1ABC9C),
            Color(0xFF16A085),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1ABC9C).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'おかえり！',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (bonusAwarded) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${bonusPts}pt',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  msg,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'スタート 🚀',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildWeeklyChallenge(
    BuildContext context,
    ProgressNotifier notifier,
    int completedCount,
    int streakDays,
    int favCount,
    int masteredCards,
    int reviewStreak,
    int totalReviewsCompleted,
    int weeklyMasteredCards,
    int totalResolvedWrong,
    int wrongCount,
  ) {
    // 週番号をシードに今週のチャレンジを決定
    final now = DateTime.now();
    final weekOfYear = now.difference(DateTime(now.year)).inDays ~/ 7;

    // 今週クリアしたステージ数
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final activityMap = notifier.activityByDate;
    int weeklyClearedCount = 0;
    for (final entry in activityMap.entries) {
      if (!entry.key.isBefore(weekStart)) {
        weeklyClearedCount += entry.value;
      }
    }
    final perfectCount = notifier.perfectStagesCount;
    final taWeekPlayCount = ref.watch(timeAttackProvider).weekPlayCount;

    // チャレンジ定義 (emoji, title, description, current, required)
    final challenges = [
      (
        '📚', '今週の学習チャレンジ', '今週 3 ステージクリア',
        weeklyClearedCount.clamp(0, 3), 3,
      ),
      (
        '⭐', '完璧を目指せ！', '累計 5 ステージで 3つ星を取ろう',
        perfectCount.clamp(0, 5), 5,
      ),
      (
        '🔥', 'ストリーク継続チャレンジ', '5 日以上の連続学習を達成しよう',
        streakDays.clamp(0, 5), 5,
      ),
      (
        '🚀', '猛進チャレンジ', '今週 5 ステージクリア',
        weeklyClearedCount.clamp(0, 5), 5,
      ),
      (
        '💎', '10 連続クリア', '完了ステージを 10 以上にしよう',
        completedCount.clamp(0, 10), 10,
      ),
      (
        '❤️', 'お気に入りチャレンジ', 'ステージを1つお気に入りに追加しよう',
        favCount.clamp(0, 1), 1,
      ),
      (
        '🃏', 'フラッシュカード習得', '今週フラッシュカードを5枚習得しよう',
        weeklyMasteredCards.clamp(0, 5), 5,
      ),
      (
        '📖', '今日の復習チャレンジ', '今日の復習を3日連続で完了しよう',
        reviewStreak.clamp(0, 3), 3,
      ),
      (
        '🧠', '復習マスター', '今日の復習を累計5回完了しよう',
        totalReviewsCompleted.clamp(0, 5), 5,
      ),
      (
        '🌟', '今週の全制覇', '今週 7 ステージクリア',
        weeklyClearedCount.clamp(0, 7), 7,
      ),
      (
        '💫', '今週の3つ星チャレンジ', '累計 3つ星ステージを 3 つ取ろう',
        perfectCount.clamp(0, 3), 3,
      ),
      (
        '⚡', 'タイムアタックチャレンジ', '今週タイムアタックを3回プレイしよう',
        taWeekPlayCount.clamp(0, 3), 3,
      ),
      (
        '🏎️', 'スピードランナー週間', '今週タイムアタックを5回プレイしよう',
        taWeekPlayCount.clamp(0, 5), 5,
      ),
      (
        '🎯', '苦手克服チャレンジ', '苦手問題を累計3問克服しよう',
        totalResolvedWrong.clamp(0, 3), 3,
      ),
      (
        '🔥', '苦手リストをゼロに', '苦手問題を全て克服しよう',
        wrongCount == 0 ? 1 : 0, 1,
      ),
    ];

    final (emoji, title, desc, current, required) = challenges[weekOfYear % challenges.length];
    final progress = required > 0 ? (current / required).clamp(0.0, 1.0) : 1.0;
    final isDone = current >= required;

    // 今週初達成ならボーナス（+20pt）とポップアップ
    if (isDone && !notifier.isHomeWeeklyBonusAwardedThisWeek) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final awarded = notifier.awardHomeWeeklyBonus();
        if (awarded) {
          HapticService.mediumImpact();
          SoundService().playComplete();
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            showBadgeUnlock(
              context, // ignore: use_build_context_synchronously
              icon: emoji,
              name: '週次チャレンジ達成！',
              message: '$title達成！週次チャレンジ完了で+20pt獲得！',
              points: 20,
              nextGoal: '来週の新しいチャレンジに挑戦しよう！',
              onContinue: () {},
            );
          });
        }
      });
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? const Color(0xFFF39C12).withValues(alpha: 0.5)
              : kPrimaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: context.shadowColor, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFF39C12).withValues(alpha: 0.15)
                                : kPrimaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDone ? '🏆 達成！' : '今週',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDone ? const Color(0xFFF39C12) : kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '$current/$required',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDone ? const Color(0xFFF39C12) : kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: isDone
                    ? const Color(0xFFF39C12).withValues(alpha: 0.15)
                    : kPrimaryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? const Color(0xFFF39C12) : kPrimaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 次のバッジ進捗カード（最も近いロック中バッジを表示）
  Widget _buildNextBadgeCard(
      BuildContext context, int completed, int stars, int streak, int favCount,
      int learningMinutes, int reviewStreak, int totalReviewsCompleted, int taBestMaxCombo,
      int masteredFlashcards, int taPlayCount,
      (int, int, int, int, int, int) unitCounts,
      int perfectCount, int totalAnswered, int taBestCorrect,
      {int totalResolvedCount = 0, int totalPerfectRuns = 0}) {
    final (begDone, begTotal, intDone, intTotal, advDone, advTotal) = unitCounts;
    // (icon, name, desc, current, required)
    final candidates = <(String, String, String, int, int)>[
      ('🚀', 'はじめの一歩', '最初のステージをクリア', completed, 1),
      ('🌿', 'コードビギナー', '3ステージクリア', completed, 3),
      ('🌱', '成長中', '5ステージクリア', completed, 5),
      ('🧩', 'ブロック名人', '初級8ステージクリア', completed, 8),
      ('🎯', '1/4制覇', '10ステージクリア', completed, 10),
      ('⭐', '15ステージ通過', '15ステージクリア', completed, 15),
      ('🐍', 'Python入門者', '20ステージクリア', completed, 20),
      ('🏅', '半分制覇', '25ステージクリア', completed, 25),
      ('🔥', '上級者突入', '30ステージクリア', completed, 30),
      ('⚡', 'ゴールが見えた！', '35ステージクリア', completed, 35),
      ('👑', '全ステージ制覇', '${AppConstants.totalStages}ステージクリア', completed, AppConstants.totalStages),
      ('⭐', '星コレクター', 'ポイント50以上', stars, 50),
      ('💎', 'スター収集家', 'ポイント60以上', stars, 60),
      ('🌟', '輝く星', 'ポイント150以上', stars, 150),
      ('💰', 'ポイント長者', 'ポイント300以上', stars, 300),
      ('🌠', 'パーフェクトクリア', '全${AppConstants.totalStages}ステージ3つ星（${AppConstants.totalStages * 3}pt）', stars, AppConstants.totalStages * 3),
      ('💫', '2日連続', '2日連続チャレンジ', streak, 2),
      ('🔥', '3日連続', '3日連続チャレンジ', streak, 3),
      ('🔥🔥', '1週間連続', '7日連続チャレンジ', streak, 7),
      ('⚡⚡', '2週間連続', '14日連続チャレンジ', streak, 14),
      ('🏆', 'チャンピオン', '30日連続チャレンジ', streak, 30),
      ('🔥🔥🔥', '1ヶ月連続', '60日連続チャレンジ', streak, 60),
      ('🌟', '100日連続！', '100日連続チャレンジ', streak, 100),
      ('✨', '完璧主義者', '3ステージで3つ星', perfectCount, 3),
      ('⭐', '5ステージ完璧', '5ステージで3つ星', perfectCount, 5),
      ('🌠', '3つ星コレクター', '10ステージで3つ星', perfectCount, 10),
      ('🎖️', 'パーフェクトマスター', '20ステージで3つ星', perfectCount, 20),
      ('📝', '100問挑戦', '累計100問に回答', totalAnswered, 100),
      ('📚', '500問達成', '累計500問に回答', totalAnswered, 500),
      ('🧠', '1000問マスター', '累計1000問に回答', totalAnswered, 1000),
      ('❤️', 'お気に入り登録', 'ステージを1つお気に入りに追加', favCount, 1),
      ('💝', 'お気に入りコレクター', 'ステージを5つお気に入りに追加', favCount, 5),
      ('💖', 'お気に入りマスター', 'ステージを10つお気に入りに追加', favCount, 10),
      ('⏱', '10分学習', '累計10分学習しよう', learningMinutes, 10),
      ('⏰', '30分学習', '累計30分学習しよう', learningMinutes, 30),
      ('🕐', '1時間学習', '累計1時間学習しよう', learningMinutes, 60),
      ('🕑', '2時間学習', '累計2時間学習しよう', learningMinutes, 120),
      ('🕒', '3時間学習', '累計3時間学習しよう', learningMinutes, 180),
      ('🏆', '10時間学習', '累計10時間学習しよう', learningMinutes, 600),
      ('📖', '復習3日連続', '今日の復習を3日連続で完了', reviewStreak, 3),
      ('📖📖', '復習1週間連続', '今日の復習を7日連続で完了', reviewStreak, 7),
      ('📖📖📖', '復習2週間連続', '今日の復習を14日連続で完了', reviewStreak, 14),
      ('🔖', '復習1ヶ月連続', '今日の復習を30日連続で完了', reviewStreak, 30),
      ('📋', '復習5回達成', '今日の復習を累計5回完了', totalReviewsCompleted, 5),
      ('📒', '復習10回達成', '今日の復習を累計10回完了', totalReviewsCompleted, 10),
      ('📕', '復習30回達成', '今日の復習を累計30回完了', totalReviewsCompleted, 30),
      ('⚡', 'タイムアタック参戦', 'タイムアタックに1回挑戦', taPlayCount, 1),
      ('🏎️', 'スピードランナー', 'タイムアタックに10回挑戦', taPlayCount, 10),
      ('🔥', 'タイムアタック達人', 'タイムアタックで8問以上正解', taBestCorrect, 8),
      ('⚡', 'ライトニングクイズ', 'タイムアタックで全問正解', taBestCorrect, 10),
      ('🔥', 'コンボ5連続', 'タイムアタックで5問連続正解', taBestMaxCombo, 5),
      ('🌟', 'コンボ神業', 'タイムアタックで10問連続正解', taBestMaxCombo, 10),
      ('📚', '単語マスター', 'フラッシュカード5枚習得', masteredFlashcards, 5),
      ('🃏', 'カードビギナー', 'フラッシュカード10枚習得', masteredFlashcards, 10),
      ('🧠', 'Python知識人', 'フラッシュカード20枚習得', masteredFlashcards, 20),
      ('💡', '上級知識人', 'フラッシュカード30枚習得', masteredFlashcards, 30),
      ('🎴', 'カードマスター', 'フラッシュカード全${kFlashcards.length}枚習得', masteredFlashcards, kFlashcards.length),
      if (begTotal > 0) ('🧩', '初級ユニット制覇', '初級の全ステージをクリア', begDone, begTotal),
      if (intTotal > 0) ('🐍', '中級ユニット制覇', '中級の全ステージをクリア', intDone, intTotal),
      if (advTotal > 0) ('🚀', '全ユニット制覇', '上級の全ステージをクリア', advDone, advTotal),
      ('🎯', '苦手克服スタート', '苦手問題を1問克服', totalResolvedCount, 1),
      ('💪', '苦手克服5問', '苦手問題を5問克服', totalResolvedCount, 5),
      ('🏅', '苦手克服マスター', '苦手問題を10問克服', totalResolvedCount, 10),
      ('🏆', '苦手ゼロへの道', '苦手問題を30問克服', totalResolvedCount, 30),
      ('✨', '初めての満点', 'クイズで全問正解を1回達成', totalPerfectRuns, 1),
      ('🌟', '満点5回', 'クイズで全問正解を5回達成', totalPerfectRuns, 5),
      ('🏅', '満点マスター', 'クイズで全問正解を20回達成', totalPerfectRuns, 20),
    ];

    // まだ解除されていない中で進捗率の高い順に最大3件表示
    final locked = candidates.where((c) => c.$4 < c.$5).toList();
    if (locked.isEmpty) return const SizedBox.shrink();

    locked.sort((a, b) {
      final ra = a.$4 / a.$5;
      final rb = b.$4 / b.$5;
      return rb.compareTo(ra); // 降順
    });
    final top = locked.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.25),
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '🏅 次のバッジ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'あと${locked.length}個',
                style: const TextStyle(fontSize: 10, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // バッジ一覧（最大3件）
          ...top.asMap().entries.map((entry) {
            final idx = entry.key;
            final badge = entry.value;
            final progress = (badge.$4 / badge.$5).clamp(0.0, 1.0);
            final isFirst = idx == 0;
            return Padding(
              padding: EdgeInsets.only(bottom: idx < top.length - 1 ? 10 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (idx > 0) ...[
                    Divider(height: 1, color: context.borderColor),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Text(
                        badge.$1,
                        style: TextStyle(fontSize: isFirst ? 20 : 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    badge.$2,
                                    style: TextStyle(
                                      fontSize: isFirst ? 13 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${badge.$4}/${badge.$5}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isFirst ? kPrimaryColor : context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              badge.$3,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: Duration(milliseconds: isFirst ? 900 : 700),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: kPrimaryColor.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFirst ? kPrimaryColor : kPrimaryColor.withValues(alpha: 0.55),
                        ),
                        minHeight: isFirst ? 7 : 5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // フッター: バッジ一覧へのリンク
          const SizedBox(height: 8),
          Divider(height: 1, color: kPrimaryColor.withValues(alpha: 0.15)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              HapticService.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'バッジ一覧を見る',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 14, color: kPrimaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCalendar(
      BuildContext context, Map<DateTime, int> activityByDate) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // 今日を含む過去7日分
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
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
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '7日間の学習記録',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.asMap().entries.map((entry) {
              final day = entry.value;
              final count = activityByDate[day] ?? 0;
              final isToday = day == today;
              final weekdayIndex = (day.weekday - 1) % 7; // Mon=0

              // 達成度に応じた色（0=空, 1=薄, 2=中, 3+=濃）
              final Color cellColor;
              if (count == 0) {
                cellColor = context.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFEEEEEE);
              } else if (count == 1) {
                cellColor = kPrimaryColor.withValues(alpha: 0.4);
              } else if (count == 2) {
                cellColor = kPrimaryColor.withValues(alpha: 0.65);
              } else {
                cellColor = kPrimaryColor;
              }

              return Column(
                children: [
                  Text(
                    weekdayLabels[weekdayIndex],
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? kPrimaryColor : kTextSecondary,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300 + entry.key * 50),
                    curve: Curves.easeOut,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: kPrimaryColor, width: 2)
                          : null,
                    ),
                    child: count > 0
                        ? Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: count >= 2
                                    ? Colors.white
                                    : kPrimaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 週合計サマリー
          Builder(builder: (context) {
            final weekTotal = days.fold<int>(0, (sum, d) => sum + (activityByDate[d] ?? 0));
            final activeDays = days.where((d) => (activityByDate[d] ?? 0) > 0).length;
            // 先週の合計
            final lastWeekDays = List.generate(7, (i) => days.first.subtract(Duration(days: 7 - i)));
            final lastWeekTotal = lastWeekDays.fold<int>(0, (sum, d) => sum + (activityByDate[d] ?? 0));
            final diff = weekTotal - lastWeekTotal;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    '数字は1日のクリアステージ数',
                    style: const TextStyle(fontSize: 10, color: kTextSecondary),
                  ),
                ),
                if (weekTotal > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '今週 $weekTotal ステージ・$activeDays 日',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryColor,
                          ),
                        ),
                        if (lastWeekTotal > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            diff > 0 ? '▲$diff' : diff < 0 ? '▼${-diff}' : '→',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: diff > 0
                                  ? const Color(0xFF27AE60)
                                  : diff < 0
                                      ? const Color(0xFFE74C3C)
                                      : kTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showRandomQuickQuiz(
    BuildContext context,
    List<Challenge> allChallenges,
    Map<String, UserProgress> progressMap,
  ) async {
    HapticService.mediumImpact();
    final rng = Random();
    // 完了済みのクイズ型チャレンジの問題を収集
    final pool = <(Question, String)>[];
    for (final c in allChallenges) {
      if (c.type == ChallengeType.quiz &&
          (progressMap[c.id]?.isCompleted ?? false) &&
          c.questions.isNotEmpty) {
        for (final q in c.questions) {
          pool.add((q, c.title));
        }
      }
    }
    if (pool.isEmpty) {
      // クイズ型ステージをまだクリアしていない場合
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 クイズステージをクリアするとランダム問題が解放されるよ！'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 苦手問題を3倍の重みで追加
    final wrongTexts = ref.read(wrongAnswersProvider).answers
        .map((a) => a.questionText).toSet();
    final weightedPool = <(Question, String)>[];
    for (final item in pool) {
      weightedPool.add(item);
      if (wrongTexts.contains(item.$1.text)) {
        weightedPool.add(item);
        weightedPool.add(item);
      }
    }

    // 苦手問題があれば優先的に出題、なければ重み付きプールからランダム
    final wrongInPool = pool.where((p) => wrongTexts.contains(p.$1.text)).toList();
    final startItem = wrongInPool.isNotEmpty
        ? wrongInPool[rng.nextInt(wrongInPool.length)]
        : weightedPool[rng.nextInt(weightedPool.length)];

    // モーダル表示前に現在の累計を記録（終了後のマイルストーン判定用）
    final notifier = ref.read(progressProvider.notifier);
    final prevAnswered   = notifier.totalQuestionsAnswered;
    final prevLearningMin = notifier.totalLearningSeconds ~/ 60;

    await showModalBottomSheet<void>(
      context: context, // ignore: use_build_context_synchronously
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickQuizSheet(
        question: startItem.$1,
        challengeTitle: startItem.$2,
        pool: weightedPool,
      ),
    );

    // クイッククイズ終了後: マイルストーンバッジ確認
    if (!mounted) return;
    final newAnswered    = notifier.totalQuestionsAnswered;
    final newLearningMin = notifier.totalLearningSeconds ~/ 60;

    // 累計回答数マイルストーン
    const qMilestones = [
      (100,  '📝', '100問挑戦！',      '累計100問に回答達成！',                    '次は500問を目指そう！'),
      (500,  '📚', '500問達成！',      '累計500問に回答！本格的なコーダー！',       '次は1000問を目指そう！'),
      (1000, '🧠', '1000問マスター！', '累計1000問に回答！あなたはコードマスター！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in qMilestones) {
      if (prevAnswered < target && newAnswered >= target) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          showBadgeUnlock(context, icon: icon, name: name, message: message, // ignore: use_build_context_synchronously
            points: 100, nextGoal: goal, onContinue: () {});
        });
        break;
      }
    }

    // 累計学習時間マイルストーン
    const lMilestones = [
      (10,  '⏱',  '10分学習！',   '累計10分学習達成！これからが楽しい！',       '30分学習を目指そう！'),
      (30,  '⏰',  '30分学習！',   '累計30分学習達成！継続は力なり！',           '1時間学習を目指そう！'),
      (60,  '🕐',  '1時間学習！',  '累計1時間学習達成！本気の学習者！',          '2時間学習を目指そう！'),
      (120, '🕑',  '2時間学習！',  '累計2時間学習達成！集中力がすごい！',        '3時間学習を目指そう！'),
      (180, '🕒',  '3時間学習！',  '累計3時間学習達成！素晴らしい集中力！',      '10時間学習を目指そう！'),
      (600, '🏆',  '10時間学習！', '累計10時間学習達成！あなたは本気のコーダー！', 'このまま続けよう！'),
    ];
    for (final (mins, icon, name, message, goal) in lMilestones) {
      if (prevLearningMin < mins && newLearningMin >= mins) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          showBadgeUnlock(context, icon: icon, name: name, message: message, // ignore: use_build_context_synchronously
            points: 50, nextGoal: goal, onContinue: () {});
        });
        break;
      }
    }
  }

  Widget _buildDailyMission(BuildContext context, Challenge challenge) {
    void openChallenge() {
      _openChallengeOrShowPaywall(context, challenge);
    }

    return GestureDetector(
      onTap: openChallenge,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryColor, kPrimaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '今日のチャレンジ',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          challenge.type == ChallengeType.visual ? '🧩 ビジュアル' : '❓ クイズ',
                          style: const TextStyle(fontSize: 9, color: Colors.white70),
                        ),
                      ),
                      // 苦手問題がある場合に🔥バッジを表示
                      Builder(builder: (ctx) {
                        if (challenge.type != ChallengeType.quiz) return const SizedBox.shrink();
                        final wrongState = ref.read(wrongAnswersProvider);
                        final hasWrong = challenge.questions.any(
                          (q) => wrongState.wrongCountFor(q.text) > 0,
                        );
                        if (!hasWrong) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.6)),
                            ),
                            child: const Text(
                              '🔥 苦手あり',
                              style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (!challenge.isFree) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 12, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'プレミアム限定',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '今すぐ挑戦 →',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(
                            duration: 1800.ms,
                            delay: 1200.ms,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        if (challenge.type == ChallengeType.quiz &&
                            challenge.questions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${challenge.questions.length}問',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              challenge.icon,
              style: const TextStyle(fontSize: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllClearCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFF39C12)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF39C12).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎓 全ステージクリア！',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                const Text(
                  'コード探険家・達人',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '全${AppConstants.totalStages}ステージ完全制覇！✨',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .shimmer(duration: 1800.ms, delay: 1200.ms, color: Colors.white.withValues(alpha: 0.4)),
              ],
            ),
          ),
          const Text('👑', style: TextStyle(fontSize: 44))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.0, 1.0),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  static const _tips = [
    ('💡', 'プログラムは「命令の順番」が大切！', '同じ命令でも順番が変わると結果が変わるよ。'),
    ('🔁', '繰り返しを使いこなそう！', 'forやwhileループで同じコードを何度も書かずに済むよ。'),
    ('🐛', 'バグは友達！', 'エラーはプログラマーへのヒント。メッセージをよく読もう。'),
    ('📦', '変数はデータの入れ物！', '変数に名前をつけて、いろんなデータを記憶させよう。'),
    ('🎯', 'まず動かしてみよう！', '完璧じゃなくても大丈夫。小さく試して少しずつ改善しよう。'),
    ('🧩', 'ブロックを組み合わせる！', '大きな問題は小さなブロックに分けると解きやすい。'),
    ('🐍', 'Pythonはシンプルで読みやすい！', '英語が分かれば、コードの意味が想像できるよ。'),
    ('⭐', '毎日少しずつが上達の近道！', '1日1ステージでも続けることが大切。'),
    ('🔍', 'コメントを書く習慣をつけよう！', '#から始まる行はコメント。自分用のメモとして使えるよ。'),
    ('🏆', 'エラーを恐れないで！', 'プロのプログラマーも毎日エラーを解決しているよ。'),
    ('🎮', 'ゲームもプログラムで作られてる！', 'このアプリもFlutterというプログラムで作られているよ。'),
    ('🌟', 'インデントを揃えよう！', 'Pythonはインデント（字下げ）でコードの構造を表すよ。'),
    ('🔢', '数字を計算しよう！', 'Pythonは +, -, *, / で足し算・引き算・掛け算・割り算ができるよ。'),
    ('📝', '文字列はクォートで囲む！', '"Hello"や\'World\'のようにクォートで囲んだものが文字列だよ。'),
    ('🔀', 'if文で条件分岐！', 'もし〇〇なら△△する、という「もし〜なら」の処理がif文だよ。'),
    ('📋', 'リストは複数の値を管理！', '[1, 2, 3]のように[ ]でデータをまとめて管理できるよ。'),
    ('🔑', '辞書型はキーと値のペア！', '{"名前": "太郎", "年齢": 10}のように名前をつけてデータを管理できるよ。'),
    ('🎪', '関数を作ると再利用できる！', 'def greet():のように関数を定義すると、同じ処理を何度でも使えるよ。'),
    ('🌈', 'print()で画面に表示！', 'print("Hello!")とすると、画面にHello!と表示されるよ。'),
    ('🔣', 'len()で長さを調べよう！', 'len("ABC")は3を返す。リストや文字列の長さを調べられるよ。'),
    ('➕', '文字列を足し算できる！', '"Hello" + " " + "World"は"Hello World"になるよ。文字列の連結と呼ぶよ。'),
    ('🎲', 'ランダムを使ってみよう！', 'import randomをすると乱数が使えるよ。ゲームで役立つよ。'),
    ('🗂️', 'ファイルに保存できる！', 'プログラムはファイルにデータを書き込んだり読み込んだりできるよ。'),
    ('🧮', '整数と小数は種類が違う！', 'int（整数）とfloat（小数）は使い方が少し違うので注意しよう。'),
    ('🔄', 'while ループは条件が続く間繰り返す！', 'while条件:で条件が真である間、繰り返し処理が行われるよ。'),
    ('🎯', 'return で値を返す！', '関数の中でreturnを使うと、計算結果を呼び出し元に返せるよ。'),
    ('🧵', '文字列の一部を取り出せる！', '"Python"[0:3]は"Pyt"を返す。スライスという機能だよ。'),
    ('🌀', 'for ループはリストを巡る！', 'for x in [1,2,3]:でリストの要素を一つずつ取り出せるよ。'),
    ('✅', 'True と False は真偽値！', 'プログラムの条件判定はTrue（真）かFalse（偽）で決まるよ。'),
    ('🔧', 'デバッグはコードを直す作業！', 'バグ（不具合）を見つけて直すことをデバッグと呼ぶよ。'),
    ('🚀', 'アルゴリズムは問題解決の手順！', '同じ問題を解くのに、速い方法と遅い方法がある。効率を考えよう！'),
    ('⌨️', 'input()でユーザーの入力を受け取ろう！', 'name = input("名前を入力してください: ")で入力した文字を変数に保存できるよ。'),
    ('🔄', '型変換を使いこなそう！', 'int("10")は文字列"10"を数字10に変換する。str(10)は逆に数字を文字列にするよ。'),
    ('🛡️', 'try/exceptでエラーを防ごう！', 'try:とexcept:でエラーが起きても安全に処理できるよ。プロ必須スキル！'),
    ('📐', 'range()で数列を作ろう！', 'range(5)は0,1,2,3,4を生成する。for i in range(10):で10回ループできるよ。'),
    ('🈳', 'Noneは「何もない」を表す！', 'None は空っぽの意味。変数が初期化されていない場合などによく使うよ。'),
    ('⚖️', '比較演算子で条件チェック！', '== は等しい、!= は等しくない、< や > で大小比較ができるよ。'),
    ('🔗', 'andとorで条件を組み合わせる！', 'if x > 0 and x < 10:のように複数の条件を組み合わせられるよ。'),
    ('📦', 'importでモジュールを使おう！', 'import mathでmath.sqrt(4)が使える。Pythonには便利なモジュールがたくさんあるよ。'),
    ('🏗️', 'クラスはオブジェクトの設計図！', 'class Cat:のようにクラスを定義すると、同じ種類のオブジェクトをたくさん作れるよ。'),
    ('🗑️', 'リストに要素を追加・削除！', 'append()で末尾に追加、remove()で削除、pop()で末尾から取り出せるよ。'),
    ('🔎', 'in演算子で存在確認！', '"a" in "banana"はTrue。リストや文字列に要素が含まれるか確認できるよ。'),
    ('🔗', 'zip()で2つのリストを組み合わせる！', 'for name, score in zip(names, scores):のように複数リストを同時にループできるよ。'),
    ('🔢', 'enumerate()でインデックス付きループ！', 'for i, v in enumerate(list):で番号と値を同時に取得できるよ。'),
    ('⚠️', 'Pythonはインデントがルール！', 'スペースやタブのズレがあるとIndentationErrorになるよ。必ず4スペースで揃えよう。'),
    ('🔑', 'dict.get()でキーエラーを防ごう！', 'd.get("key", デフォルト)は、キーがなくてもエラーにならず安全に取得できるよ。'),
    ('💬', '複数行文字列は三重クォート！', '"""複数行\nの文字列"""やトリプルクォートで複数行にまたがる文字列を書けるよ。'),
    ('🧪', 'assert でプログラムを検証しよう！', 'assert x > 0, "xは正の数であるべき"のように、条件が偽なら即座にエラーを出せるよ。'),
    ('🔄', 'リストのコピーは .copy() を使おう！', 'b = a.copy()にしないと、bとaが同じリストを指すことになるよ。注意しよう！'),
    ('🎩', '関数の引数にデフォルト値を設定できる！', 'def greet(name, lang="日本語"):のようにデフォルト値を設定すると省略可能になるよ。'),
    ('🔽', 'リスト内包表記でスッキリ書こう！', '[x*2 for x in range(5)]は[0,2,4,6,8]を返す。forループより短く書けるよ。'),
    ('🔃', 'sorted()でリストを並び替え！', 'sorted([3,1,4,1,5])は[1,1,3,4,5]を返す。元のリストは変えないよ。'),
    ('🔠', 'upper()とlower()で大文字・小文字変換！', '"hello".upper()は"HELLO"、"WORLD".lower()は"world"になるよ。'),
    ('✂️', 'split()で文字列を分割！', '"a,b,c".split(",")は["a","b","c"]になるよ。CSVデータを扱うときに便利！'),
    ('🔗', 'join()でリストを文字列に結合！', '",".join(["a","b","c"])は"a,b,c"になる。splitの逆操作だよ。'),
    ('🔢', '//は整数の割り算！', '7//2は3（小数点以下切り捨て）。%は余り: 7%2は1。セットで覚えよう！'),
    ('🎭', 'f文字列で変数を埋め込もう！', 'name="太郎"; f"こんにちは、{name}！"は"こんにちは、太郎！"になるよ。'),
    ('💭', 'is と == の違いに注意！', '==は値の比較、isはオブジェクトの同一性の比較。None判定はis Noneを使おう。'),
    ('🔐', 'set()で重複を取り除こう！', 'set([1,2,2,3,3])は{1,2,3}になる。リストの重複削除に便利！'),
    ('⚙️', 'lambda で無名関数を作れる！', 'square = lambda x: x**2のように短い関数を1行で書けるよ。'),
    ('📊', 'max()・min()で最大・最小を取得！', 'max([3,1,4,1,5])は5、min([3,1,4,1,5])は1を返すよ。'),
    ('🔄', '条件付きリスト内包表記！', '[x for x in range(10) if x%2==0]で偶数のみのリスト[0,2,4,6,8]が作れるよ。'),
    ('📌', '__name__ == "__main__" の意味！', 'このブロックの中のコードはファイルを直接実行した時だけ動くよ。練習に使おう！'),
    ('🔎', 'any()とall()で条件一括チェック！', 'any([True,False,True])はTrue。all([True,True,True])はTrue。便利関数だよ。'),
  ];

  Widget _buildDailyTip(BuildContext context) {
    final tip = _tips[_tipIndex];
    return GestureDetector(
      onTap: _nextTip,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -100) {
          // 左スワイプ → 次へ
          _nextTip();
        } else if (details.primaryVelocity! > 100) {
          // 右スワイプ → 前へ
          setState(() => _tipIndex = (_tipIndex - 1 + _tips.length) % _tips.length);
        }
      },
      child: Container(
        key: ValueKey(_tipIndex),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(color: context.shadowColor, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Text(tip.$1, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '今日のTips',
                          style: TextStyle(fontSize: 9, color: kPrimaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_tipIndex + 1} / ${_tips.length}',
                        style: const TextStyle(fontSize: 9, color: kTextSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.swipe, size: 12, color: kTextSecondary),
                      const SizedBox(width: 3),
                      const Text(
                        'スワイプで切替',
                        style: TextStyle(fontSize: 9, color: kTextSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tip.$3,
                    style: const TextStyle(fontSize: 11, color: kTextSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, curve: Curves.easeOut, duration: 200.ms),
    );
  }

  /// コインショップカード
  Widget _buildShopCard(BuildContext context, int coinBalance) {
    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        SoundService().playTap();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShopScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.12),
              const Color(0xFFFFA500).withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🏪', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'コインショップ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'コインでスキンや背景をゲットしよう！',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // コイン残高
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  Text(
                    '$coinBalance',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B6914),
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

  Widget _buildMiniGames(BuildContext context) {
    final taState = ref.watch(timeAttackProvider);
    final taSublabel = taState.bestScore > 0
        ? '🏅 ベスト ${taState.bestScore}pt'
        : '素早く答えよう';
    final masteredCount = ref.watch(flashcardProvider).masteredCount;
    final fcSublabel = masteredCount > 0
        ? '✅ 習得済み $masteredCount / ${kFlashcards.length}枚'
        : '単語・概念を暗記しよう';
    final wrongState = ref.watch(wrongAnswersProvider);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniGameCard(
                emoji: '⚡',
                label: 'タイムアタック',
                sublabel: taSublabel,
                color: const Color(0xFFE67E22),
                onTap: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TimeAttackScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniGameCard(
                emoji: '🏆',
                label: 'ランキング',
                sublabel: 'トップを目指せ',
                color: const Color(0xFF9B59B6),
                onTap: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RankingScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MiniGameCard(
          emoji: '🃏',
          label: 'フラッシュカード',
          sublabel: fcSublabel,
          color: const Color(0xFF8E44AD),
          onTap: () {
            HapticService.lightImpact();
            SoundService().playTap();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FlashcardScreen()),
            );
          },
        ),
        if (!wrongState.isEmpty) ...[
          const SizedBox(height: 10),
          _MiniGameCard(
            emoji: '🔥',
            label: '苦手問題特訓',
            sublabel: '苦手 ${wrongState.count}問をタイムアタックで克服！',
            color: const Color(0xFFE64A00),
            onTap: () {
              HapticService.mediumImpact();
              SoundService().playTap();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TimeAttackScreen(initialWeakMode: true),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCharacterMiniCard(BuildContext context) {
    final charState = ref.watch(characterProvider);
    final character = charState.character;
    if (charState.isLoading || character == null) return const SizedBox.shrink();

    final charDef = kAvailableCharacters.firstWhere(
      (c) => c.id == character.characterId,
      orElse: () => kAvailableCharacters.first,
    );
    final emoji = charDef.stageEmojis[character.stage] ?? '🥚';
    final stageName = kStageNames[character.stage] ?? '';

    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        SoundService().playTap();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CharacterScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '【$stageName】${charDef.name}  XP: ${character.totalXp}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReviewCard(BuildContext context, bool doneToday, int reviewStreak) {
    return GestureDetector(
      onTap: doneToday
          ? null
          : () {
              HapticService.lightImpact();
              SoundService().playTap();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DailyReviewScreen()),
              );
            },
      child: Opacity(
        opacity: doneToday ? 0.65 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1ABC9C).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1ABC9C).withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1ABC9C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    doneToday ? '✅' : '📖',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '今日の復習',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A085),
                          ),
                        ),
                        if (reviewStreak >= 2) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1ABC9C).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '📖 $reviewStreak日連続',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A085),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Builder(builder: (ctx) {
                      final wrongCount = ref.read(wrongAnswersProvider).count;
                      final subtitle = doneToday
                          ? '今日の復習は済んでいます！また明日'
                          : wrongCount > 0
                              ? '🔥 苦手問題$wrongCount件含む・ボーナスポイントあり'
                              : 'クリア済みステージから5問・ボーナスポイントあり';
                      return Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: !doneToday && wrongCount > 0
                              ? const Color(0xFFE64A00)
                              : kTextSecondary,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (!doneToday)
                const Icon(Icons.chevron_right, color: Color(0xFF1ABC9C)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    String level,
    Map<String, UserProgress> progressMap,
    List<Challenge> allChallenges,
  ) {
    final String unitTitle;
    final String unitNumber;
    final String unitIcon;

    switch (level) {
      case StageLevel.beginner:
        unitTitle = 'ブロックプログラミング基礎';
        unitNumber = 'Unit 1 · 初級';
        unitIcon = '🧩';
        break;
      case StageLevel.intermediate:
        unitTitle = 'Pythonプログラミング入門';
        unitNumber = 'Unit 2 · 中級';
        unitIcon = '🐍';
        break;
      default:
        unitTitle = 'Python応用・自動化';
        unitNumber = 'Unit 3 · 上級';
        unitIcon = '🚀';
    }

    final unitChallenges = allChallenges.where((c) => c.level == level).toList();
    final completedInUnit =
        unitChallenges.where((c) => progressMap[c.id]?.isCompleted ?? false).length;
    final totalInUnit = unitChallenges.length;
    final progressText =
        completedInUnit == 0 ? '未開始' : '$completedInUnit/$totalInUnit完了';
    // このユニットの苦手問題数
    final wrongState = ref.read(wrongAnswersProvider);
    final unitWrongCount = unitChallenges
        .where((c) => c.type == ChallengeType.quiz)
        .fold<int>(0, (sum, c) => sum + c.questions.fold<int>(
          0, (s, q) => s + wrongState.wrongCountFor(q.text)));
    final unitWrongStages = unitChallenges
        .where((c) => c.type == ChallengeType.quiz &&
            c.questions.any((q) => wrongState.wrongCountFor(q.text) > 0))
        .length;

    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        SoundService().playTap();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StageListScreen(initialLevel: level),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unitNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unitTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 11,
                          color: completedInUnit == 0 ? kTextSecondary : kPrimaryColor,
                          fontWeight:
                              completedInUnit == 0 ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      if (unitWrongCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '🔥 $unitWrongStages ステージ',
                            style: const TextStyle(fontSize: 9, color: Color(0xFFE64A00)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (completedInUnit > 0) ...[
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0.0,
                        end: totalInUnit > 0 ? completedInUnit / totalInUnit : 0.0,
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: kPrimaryColor.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(unitIcon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: kTextSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── ミニゲームカード ──────────────────────────────────────────────────────────

class _MiniGameCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _MiniGameCard({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── 今日の目標ドット ──────────────────────────────────────────────────────────

class _DailyGoalDots extends StatelessWidget {
  final int todayCleared;
  final int dailyGoal;

  const _DailyGoalDots({
    required this.todayCleared,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final done = todayCleared.clamp(0, dailyGoal);
    final allDone = done >= dailyGoal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '今日',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(dailyGoal, (i) {
          final filled = i < done;
          return Padding(
            padding: const EdgeInsets.only(left: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (allDone ? Colors.yellow : Colors.white)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          );
        }),
        if (allDone) ...[
          const SizedBox(width: 4),
          const Text('🎉', style: TextStyle(fontSize: 10)),
        ],
      ],
    );
  }
}

// ── クイックランダムクイズシート ────────────────────────────────────────────

class _QuickQuizSheet extends ConsumerStatefulWidget {
  final Question question;
  final String challengeTitle;
  // プール: 次の問題へ進むためのランダム問題リスト
  final List<(Question, String)> pool;

  const _QuickQuizSheet({
    required this.question,
    required this.challengeTitle,
    required this.pool,
  });

  @override
  ConsumerState<_QuickQuizSheet> createState() => _QuickQuizSheetState();
}

class _QuickQuizSheetState extends ConsumerState<_QuickQuizSheet> {
  int? _selected;
  bool _answered = false;
  late Question _currentQuestion;
  late String _currentTitle;
  int _answeredCount = 0;   // このセッションで回答した問題数
  int _correctCount  = 0;   // このセッションで正解した問題数
  bool _currentWasWrong = false; // 現在の問題が苦手リストにあったか
  final List<QuizAnswer> _wrongAnswers = []; // 苦手問題記録用
  final FocusNode _focusNode = FocusNode();
  final _rng = Random();
  late DateTime _sessionStart; // 学習時間計測用

  @override
  void initState() {
    super.initState();
    _sessionStart    = DateTime.now();
    _currentQuestion = widget.question;
    _currentTitle    = widget.challengeTitle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // 初期問題が苦手リストにあるか確認
      _currentWasWrong = ref.read(wrongAnswersProvider)
          .wrongCountFor(widget.question.text) > 0;
    });
  }

  @override
  void dispose() {
    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
    if (elapsed > 0) {
      ref.read(progressProvider.notifier).recordLearningSeconds(elapsed);
    }
    if (_answeredCount > 0) {
      ref.read(progressProvider.notifier).recordQuestionsAnswered(_answeredCount);
    }
    if (_wrongAnswers.isNotEmpty) {
      ref.read(wrongAnswersProvider.notifier).addWrongAnswers(_wrongAnswers);
    }
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pick(int index) async {
    if (_answered) return;
    final q = _currentQuestion;
    setState(() {
      _selected = index;
      _answered = true;
      _answeredCount++;
    });
    final correct = index == q.correctIndex;
    if (correct) {
      _correctCount++;
      HapticService.mediumImpact();
      SoundService().playCorrect();
      // 苦手リストにある問題を正解したらカウントを減らす（完全克服でボーナスポイント）
      final resolved = await ref.read(wrongAnswersProvider.notifier).markCorrect(q.text);
      if (resolved) {
        ref.read(progressProvider.notifier).addBonusPoints(5);
        if (_currentWasWrong) {
          setState(() {}); // rebuild して克服バッジを表示
        }
      }
    } else {
      HapticService.heavyImpact();
      SoundService().playWrong();
      // 苦手問題リストに追加
      _wrongAnswers.add(QuizAnswer(
        questionText: q.text,
        isCorrect: false,
        selectedAnswer: q.options[index],
        correctAnswer: q.options[q.correctIndex],
        explanation: q.explanation,
        codeSnippet: q.codeSnippet,
      ));
    }
  }

  // 次のランダム問題に切り替える
  void _nextQuestion() {
    HapticService.lightImpact();
    SoundService().playTap();
    final pick = widget.pool[_rng.nextInt(widget.pool.length)];
    final nextWasWrong = ref.read(wrongAnswersProvider)
        .wrongCountFor(pick.$1.text) > 0;
    setState(() {
      _currentQuestion = pick.$1;
      _currentTitle    = pick.$2;
      _selected        = null;
      _answered        = false;
      _currentWasWrong = nextWasWrong;
    });
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // 1/2/3/4 → 選択肢を即答
    final optionKeys = {
      LogicalKeyboardKey.digit1: 0,
      LogicalKeyboardKey.digit2: 1,
      LogicalKeyboardKey.digit3: 2,
      LogicalKeyboardKey.digit4: 3,
    };
    final idx = optionKeys[key];
    if (idx != null && !_answered && idx < _currentQuestion.options.length) {
      _pick(idx);
      return KeyEventResult.handled;
    }
    // Tab / Shift+Tab で選択肢を順送り / 逆送り（未回答のみ）
    if (key == LogicalKeyboardKey.tab && !_answered) {
      final optCount = _currentQuestion.options.length;
      if (HardwareKeyboard.instance.isShiftPressed) {
        final next = _selected == null
            ? optCount - 1
            : (_selected! - 1 + optCount) % optCount;
        setState(() => _selected = next);
      } else {
        final next = _selected == null
            ? 0
            : (_selected! + 1) % optCount;
        setState(() => _selected = next);
      }
      HapticService.selectionClick();
      return KeyEventResult.handled;
    }
    // Enter / Space → 選択確定 or 回答後は次の問題
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_answered) {
        _nextQuestion();
        return KeyEventResult.handled;
      } else if (_selected != null) {
        _pick(_selected!);
        return KeyEventResult.handled;
      }
    }
    // N → 次の問題（回答後）
    if (key == LogicalKeyboardKey.keyN && _answered) {
      _nextQuestion();
      return KeyEventResult.handled;
    }
    // Esc / Backspace → 閉じる
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    final isCorrect = _answered && _selected == q.correctIndex;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🎲 ランダム1問',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 苦手問題バッジ
                Builder(builder: (ctx) {
                  final wc = ref.read(wrongAnswersProvider).wrongCountFor(_currentQuestion.text);
                  if (wc < 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '🔥 ×$wc',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFFE64A00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                Expanded(
                  child: Text(
                    _currentTitle,
                    style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: kTextSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 問題文
            Text(
              q.text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
            ),
            // コードスニペット
            if (q.codeSnippet != null) ...[
              const SizedBox(height: 10),
              CodeHighlightWidget(code: q.codeSnippet!, fontSize: 12),
            ],
            const SizedBox(height: 14),
            // 選択肢
            ...q.options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              final Color borderColor;
              final Color bgColor;
              if (!_answered) {
                if (i == _selected) {
                  // Tab カーソル or 選択中
                  borderColor = kPrimaryColor.withValues(alpha: 0.75);
                  bgColor = kPrimaryColor.withValues(alpha: 0.08);
                } else {
                  borderColor = kPrimaryColor.withValues(alpha: 0.3);
                  bgColor = Colors.transparent;
                }
              } else if (i == q.correctIndex) {
                borderColor = const Color(0xFF2ECC71);
                bgColor = const Color(0xFF2ECC71).withValues(alpha: 0.1);
              } else if (i == _selected) {
                borderColor = const Color(0xFFE74C3C);
                bgColor = const Color(0xFFE74C3C).withValues(alpha: 0.1);
              } else {
                borderColor = kPrimaryColor.withValues(alpha: 0.15);
                bgColor = Colors.transparent;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _pick(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: borderColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(0x41 + i), // A, B, C, D
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: borderColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(opt, style: const TextStyle(fontSize: 13)),
                        ),
                        if (_answered && i == q.correctIndex)
                          const Text('✅', style: TextStyle(fontSize: 14))
                        else if (_answered && i == _selected && i != q.correctIndex)
                          const Text('❌', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            // 解説（回答後）
            if (_answered) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                      : const Color(0xFFE74C3C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isCorrect ? '🎉 正解！' : '😅 不正解',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCorrect
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFFE74C3C),
                          ),
                        ),
                        // 苦手問題を克服した場合のバッジ
                        if (isCorrect && _currentWasWrong) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              '🎯 苦手克服！',
                              style: TextStyle(fontSize: 9, color: Color(0xFFE64A00), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        // セッション中の正解数表示（2問目以降）
                        if (_answeredCount >= 2) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_correctCount / $_answeredCount 正解',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        q.explanation,
                        style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ボタン行: 次の問題 + 閉じる
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.4)),
                        foregroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('閉じる'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _nextQuestion,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('次の問題 →'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),   // closes Container
    );   // closes Focus
  }
}

// ── レベルアップオーバーレイ ─────────────────────────────────────────────────

class _LevelUpOverlay extends StatelessWidget {
  final int newLevel;
  const _LevelUpOverlay({required this.newLevel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C3483), Color(0xFF9B59B6)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52))
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      curve: Curves.elasticOut,
                      duration: 700.ms,
                    ),
                const SizedBox(height: 12),
                const Text(
                  'レベルアップ！',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  'Lv. $newLevel',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    .animate(delay: 300.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.elasticOut,
                      duration: 600.ms,
                    )
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 16),
                Text(
                  'すごい！どんどんうまくなっているよ！',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('やった！'),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element — 将来利用予定のストリークカードビルダー
  Widget _buildLearningStreakCard(
    BuildContext context,
    int currentStreak,
    int bestStreak,
  ) {
    // モチベーションメッセージ
    final motivationMessage = currentStreak >= bestStreak && currentStreak > 0
        ? '🎯 ベスト記録を更新中！' // ベスト記録を目指している
        : currentStreak >= bestStreak - 2 && bestStreak > 0
            ? '🔥 あと${bestStreak - currentStreak}日でベスト記録！'
            : '💪 連続学習を継続中！';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.08),
            const Color(0xFFFF8C42).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '学習ストリーク',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      motivationMessage,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$currentStreak',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '日連続',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.subCardBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$bestStreak',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '日（最高記録）',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (currentStreak > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: const Color(0xFFFF6B35),
                ),
                const SizedBox(width: 6),
                Text(
                  '毎日の継続が力になります。明日も頑張ろう！',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// プログラミングの能力を示すバッジ
class _CapabilityBadge extends StatelessWidget {
  final String emoji;
  final String label;

  const _CapabilityBadge({
    required this.emoji,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667EEA),
            ),
          ),
        ],
      ),
    );
  }
}

