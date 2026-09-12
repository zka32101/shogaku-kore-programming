import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show
        FriendsListPage,
        DailyMissionPage,
        WeeklyBonusWidget,
        coinProvider,
        NotificationBadge,
        notificationProvider;

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/character_model.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/character_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_review_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/app_dialog.dart';
import '../widgets/code_highlight.dart';
import '../widgets/daily_puzzle_card.dart';
import '../widgets/shortcut_help.dart';
import '../widgets/tap_scale.dart';
import 'achievements_screen.dart';
import 'badge_unlock_screen.dart';
import 'character_screen.dart';
import 'coaching/views/ai_coaching_dashboard_screen.dart';
import 'coaching/widgets/ai_coaching_card.dart';
import 'daily_review_screen.dart';
import 'editor_screen.dart';
import 'flashcard_screen.dart';
import 'friends_list_screen.dart';
import 'gallery_screen.dart';
import 'lesson_screen.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';
import 'programming_basics_screen.dart';
import 'quiz_result_screen.dart' show QuizAnswer;
import 'quiz_review_screen.dart';
import 'quiz_screen.dart';
import 'ranking_screen.dart';
import 'reverse_teaching_screen.dart';
import 'shop_screen.dart';
import 'stage_list_screen.dart';
import 'time_attack_screen.dart';
import 'weekly_report_screen.dart';
import 'why_programming_screen.dart';
import 'wrong_answers_list_screen.dart';

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
  bool _codeKingChecked = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _tipIndex = dayOfYear % _tips.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).loadFriends();
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
    if (key == LogicalKeyboardKey.keyT) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const TimeAttackScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const DailyReviewScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyW) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const WrongAnswersListScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const StageListScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const AchievementsScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const FriendsListScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const ProfileScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyH) {
      HapticService.lightImpact();
      SoundService().playTap();
      showDialog(context: context, builder: (c) => const ShortcutHelp());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showLevelUpOverlay(BuildContext context, int newLevel) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
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
    final coinBalance = ref.watch(coinProvider.select((s) => s.balance));
    final reviewState = ref.watch(dailyReviewProvider);
    final reviewDoneToday = reviewState.doneToday;
    final reviewStreak = reviewState.reviewStreak;

    final wrongAnswersState = ref.watch(wrongAnswersProvider);
    final flashState = ref.watch(flashcardProvider);
    final masteredCards = flashState.masteredIds.length;
    final now = DateTime.now();
    final fcWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final fcWeekStartDay = DateTime(fcWeekStart.year, fcWeekStart.month, fcWeekStart.day);
    final weeklyMasteredCards = flashState.masteredDates.values
        .where((d) => !d.isBefore(fcWeekStartDay))
        .length;
    final taState = ref.watch(
      timeAttackProvider.select((s) => (
        bestMaxCombo: s.bestMaxCombo,
        playCount: s.playCount,
        bestCorrect: s.bestCorrect,
      )),
    );
    final taBestMaxCombo = taState.bestMaxCombo;
    final taPlayCount = taState.playCount;
    final taBestCorrect = taState.bestCorrect;
    final completedCount = progressNotifier.completedCount;
    final totalStars = progressNotifier.totalStarsEarned;
    final level = progressNotifier.currentLevel;
    final streakDays = progressNotifier.streakDays;

    // Listener 1: レベルアップ検出
    ref.listen<Map<String, dynamic>>(progressProvider.select((_) => {
      'level':  ref.read(progressProvider.notifier).currentLevel,
      'loaded': ref.read(progressProvider.notifier).isLoaded,
    }), (prev, next) {
      final newLevel = next['level'] as int;
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
    if (ref.read(progressProvider.notifier).isLoaded) {
      _prevLevel ??= level;
    }

    // Listener 2: ストリークマイルストーン検出
    ref.listen<Map<String, dynamic>>(progressProvider.select((_) => {
      'streak':      ref.read(progressProvider.notifier).streakDays,
      'lastMilestone': ref.read(progressProvider.notifier).lastShownStreakMilestone,
    }), (prev, next) {
      final newStreak     = next['streak']       as int;
      final lastMilestone = next['lastMilestone'] as int;
      if (_prevStreak != null && newStreak > _prevStreak!) {
        const milestones = [2, 3, 7, 14, 30, 60, 100];
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
              context,
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

    // Listener 3: 1日の目標達成検出
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

    // Listener 4: コード王バッジ検出
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
            context,
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

    // ユニット別完了数
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
    final Stage nextStage = allChallenges.firstWhere(
      (c) => !(progressMap[c.id]?.isCompleted ?? false),
      orElse: () => allChallenges.first,
    );

    final currentUnitLevel = allChallenges
        .firstWhere(
          (c) => !(progressMap[c.id]?.isCompleted ?? false),
          orElse: () => allChallenges.last,
        )
        .level;

    const levels = [
      StageLevel.beginner,
      StageLevel.intermediate,
      StageLevel.advanced,
    ];

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
        body: CustomScrollView(
          slivers: [
            // SliverAppBar with gradient header
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryColor,
                        kPrimaryColor.withAlpha(220),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'レベル $level',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '★$totalStars • 🔥$streakDays日',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Phase 4.23: ローカル通知・リマインダーシステム
              actions: [
                Builder(
                  builder: (context) {
                    final notifications = ref.watch(notificationProvider);
                    return NotificationBadge(
                      notificationCount: notifications.length,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('通知: ${notifications.length}件'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            // Main content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Main action cards
                  _buildMainActionCards(
                    context,
                    allChallenges,
                    progressMap,
                    nextStage,
                    profile,
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  _buildStatsRow(
                    completedCount,
                    totalStars,
                    streakDays,
                    profile.dailyGoal,
                    todayCleared,
                  ),
                  const SizedBox(height: 20),

                  // Phase 4.20: 週次ボーナスウィジェット
                  WeeklyBonusWidget(
                    onBonusClaimed: (coins) {
                      ref.read(coinProvider.notifier).addCoins(coins);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('週次ボーナス獲得！ $coins コイン'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phase 4.24: AI コーチング
                  AiCoachingCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiCoachingDashboardScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daily mission card
                  _buildDailyMissionCard(context, profile, todayCleared),
                  const SizedBox(height: 16),

                  // Review card
                  _buildReviewCard(context, reviewDoneToday, reviewStreak),
                  const SizedBox(height: 16),

                  // Wrong answers card
                  if (!wrongAnswersState.isEmpty)
                    _buildWrongAnswersCard(context, wrongAnswersState.count),
                  if (!wrongAnswersState.isEmpty)
                    const SizedBox(height: 16),

                  // Weak stages card
                  _buildWeakStagesCard(context, allChallenges, progressMap),
                  const SizedBox(height: 16),

                  // Badge progress
                  _buildBadgeProgressTracker(unitCounts),
                  const SizedBox(height: 16),

                  // Additional info
                  _buildAdditionalStats(
                    masteredCards,
                    weeklyMasteredCards,
                    taBestMaxCombo,
                    taPlayCount,
                    taBestCorrect,
                    coinBalance,
                  ),
                ]),
              ),
            ),
          ],
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
          // ヘッダー top row: 科目ラベル + アクションボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              // デイリーミッションボタン
              IconButton(
                onPressed: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyMissionPage(
                        primaryColor: kPrimaryColor,
                        appTitle: '小学コレ！プログラミング',
                        filterSubject: 'programming',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment, color: Colors.white, size: 18),
                tooltip: 'デイリーミッション',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: const CircleBorder(),
                  minimumSize: const Size(40, 40),
                ),
              ),
              // アクションボタン（フレンド）
              IconButton(
                onPressed: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendsListPage()),
                  );
                },
                icon: const Icon(Icons.people, color: Colors.white, size: 20),
                tooltip: 'フレンド',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: const CircleBorder(),
                  minimumSize: const Size(40, 40),
                ),
              ),
            ],
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
                        smoothPageRoute(const ShopScreen()),
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

  Widget _buildMainActionCards(
    BuildContext context,
    List<Stage> allChallenges,
    Map<String, dynamic> progressMap,
    Stage nextStage,
    ProfileState profile,
  ) {
    return Column(
      children: [
        // AI Suggested
        _buildActionCard(
          '推奨学習',
          '今のあなたに最適',
          '🤖',
          kPrimaryColor,
          onTap: () => _openNextStage(context, allChallenges, progressMap),
        ),
        const SizedBox(height: 12),
        // Lessons
        _buildActionCard(
          '学ぶ',
          'ステージを選ぶ',
          '📚',
          const Color(0xFF6366F1),
          onTap: () => Navigator.of(context).push(
            smoothPageRoute(const StageListScreen()),
          ),
        ),
        const SizedBox(height: 12),
        // Time Attack
        _buildActionCard(
          'タイムアタック',
          'スピード重視でチャレンジ',
          '⚡',
          const Color(0xFFF59E0B),
          onTap: () => Navigator.of(context).push(
            smoothPageRoute(const TimeAttackScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    String emoji,
    Color color,
    {required VoidCallback onTap},
  ) {
    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withAlpha(200),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(77),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    int completedCount,
    int totalStars,
    int streakDays,
    int dailyGoal,
    int todayCleared,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox('ステージ', '$completedCount'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox('スター', '$totalStars'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox('連続日数', '$streakDays'),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: kPrimaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimaryColor.withAlpha(77)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMissionCard(
    BuildContext context,
    ProfileState profile,
    int todayCleared,
  ) {
    final progress = todayCleared / max(profile.dailyGoal, 1);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        smoothPageRoute(const StageListScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 今日のミッション',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? Colors.green : kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$todayCleared / ${profile.dailyGoal} ステージクリア',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    bool reviewDoneToday,
    int reviewStreak,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        smoothPageRoute(const DailyReviewScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: reviewDoneToday ? Colors.green[50] : Colors.amber[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reviewDoneToday ? Colors.green[300]! : Colors.amber[300]!,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reviewDoneToday ? '✅ 復習済み' : '🔄 復習まだ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '連続：$reviewStreak日',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongAnswersCard(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        smoothPageRoute(const WrongAnswersListScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🔥 苦手問題', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '$count',
                style: const TextStyle(
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

  Widget _buildWeakStagesCard(
    BuildContext context,
    List<Stage> allChallenges,
    Map<String, dynamic> progressMap,
  ) {
    final weakStages = allChallenges
        .where((c) {
          final progress = progressMap[c.id] as Map<String, dynamic>?;
          return progress != null && progress['correctCount'] is int &&
                 (progress['correctCount'] as int) < (progress['totalQuestions'] as int? ?? 3);
        })
        .take(3)
        .toList();

    if (weakStages.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        smoothPageRoute(const StageListScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[300]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 苦手なステージ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...weakStages.map((stage) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                stage.title,
                style: const TextStyle(fontSize: 12),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeProgressTracker(
    (int, int, int, int, int, int) unitCounts,
  ) {
    final (beginnerDone, beginnerTotal, intermediateDone, intermediateTotal, advancedDone, advancedTotal) = unitCounts;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎖️ ユニット進捗',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildUnitProgress('初級', beginnerDone, beginnerTotal, Colors.green),
          const SizedBox(height: 12),
          _buildUnitProgress('中級', intermediateDone, intermediateTotal, Colors.orange),
          const SizedBox(height: 12),
          _buildUnitProgress('上級', advancedDone, advancedTotal, Colors.red),
        ],
      ),
    );
  }

  Widget _buildUnitProgress(String label, int done, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('$done/$total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? done / total : 0,
          minHeight: 6,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  Widget _buildAdditionalStats(
    int masteredCards,
    int weeklyMasteredCards,
    int taBestMaxCombo,
    int taPlayCount,
    int taBestCorrect,
    int coinBalance,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatRow('🎴 フラッシュカード', '$masteredCards習得 / 今週$weeklyMasteredCards'),
          const SizedBox(height: 12),
          _buildStatRow('⚡ タイムアタック', '$taPlayCount回 / 最高$taBestCorrect'),
          const SizedBox(height: 12),
          _buildStatRow('🪙 コイン', '$coinBalance枚'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _openNextStage(
    BuildContext context,
    List<Stage> allChallenges,
    Map<String, dynamic> progressMap,
  ) {
    final nextStage = allChallenges.firstWhere(
      (c) => !(progressMap[c.id]?.isCompleted ?? false),
      orElse: () => allChallenges.first,
    );
    Navigator.of(context).push(
      smoothPageRoute(
        QuizScreen(
          challenge: nextStage,
        ),
      ),
    );
  }

  Future<void> _showRandomQuickQuiz(
    BuildContext context,
    List<Stage> allChallenges,
    Map<String, dynamic> progressMap,
  ) async {
    HapticService.mediumImpact();
    final rng = Random();
    final pool = <(Question, String)>[];
    for (final c in allChallenges) {
      if (c.type == 'quiz' &&
          (progressMap[c.id]?.isCompleted ?? false) &&
          (c.questions?.isNotEmpty ?? false)) {
        for (final q in c.questions ?? []) {
          pool.add((q, c.title));
        }
      }
    }
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 クイズステージをクリアするとランダム問題が解放されるよ！'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    final wrongInPool = pool.where((p) => wrongTexts.contains(p.$1.text)).toList();
    final startItem = wrongInPool.isNotEmpty
        ? wrongInPool[rng.nextInt(wrongInPool.length)]
        : weightedPool[rng.nextInt(weightedPool.length)];

    final notifier = ref.read(progressProvider.notifier);
    final prevAnswered   = notifier.totalQuestionsAnswered;
    final prevLearningMin = notifier.totalLearningSeconds ~/ 60;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickQuizSheet(
        question: startItem.$1,
        challengeTitle: startItem.$2,
        pool: weightedPool,
      ),
    );

    if (!mounted) return;
    final newAnswered    = notifier.totalQuestionsAnswered;
    final newLearningMin = notifier.totalLearningSeconds ~/ 60;

    const qMilestones = [
      (100,  '📝', '100問挑戦！',      '累計100問に回答達成！',                    '次は500問を目指そう！'),
      (500,  '📚', '500問達成！',      '累計500問に回答！本格的なコーダー！',       '次は1000問を目指そう！'),
      (1000, '🧠', '1000問マスター！', '累計1000問に回答！あなたはコードマスター！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in qMilestones) {
      if (prevAnswered < target && newAnswered >= target) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          showBadgeUnlock(context, icon: icon, name: name, message: message,
            points: 100, nextGoal: goal, onContinue: () {});
        });
        break;
      }
    }

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
          showBadgeUnlock(context, icon: icon, name: name, message: message,
            points: 50, nextGoal: goal, onContinue: () {});
        });
        break;
      }
    }
  }

  static const List<String> _tips = [
    'Dart は null safety をサポートしています。',
    'Flutter のホットリロードは開発効率を大幅に向上させます。',
  ];
}

// QuickQuiz Sheet
class _QuickQuizSheet extends ConsumerStatefulWidget {
  final Question question;
  final String challengeTitle;
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
  int? _selectedIndex;
  bool _answered = false;
  late Question _currentQuestion;
  late int _questionIndex;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.question;
    _questionIndex = 0;
  }

  void _nextQuestion() {
    if (_questionIndex < 4) {
      final item = widget.pool[_rng.nextInt(widget.pool.length)];
      setState(() {
        _currentQuestion = item.$1;
        _selectedIndex = null;
        _answered = false;
        _questionIndex++;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _answerQuestion() {
    if (_selectedIndex == null) return;

    HapticService.lightImpact();
    final correct = _selectedIndex == _currentQuestion.correctIndex;
    if (correct) {
      SoundService().playCorrect();
      ref.read(progressProvider.notifier).recordQuestionsAnswered(1);
    } else {
      SoundService().playWrong();
      ref.read(wrongAnswersProvider.notifier).addWrongAnswers([
        QuizAnswer(
          questionText: _currentQuestion.text,
          selectedAnswer: _currentQuestion.options[_selectedIndex!],
          correctAnswer: _currentQuestion.options[_currentQuestion.correctIndex],
        ),
      ]);
    }

    setState(() => _answered = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_questionIndex + 1}/5',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              LinearProgressIndicator(
                value: (_questionIndex + 1) / 5,
              ),
              const SizedBox(height: 20),

              // Question
              Text(
                _currentQuestion.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Options
              ...List.generate(_currentQuestion.options.length, (i) {
                final selected = _selectedIndex == i;
                final isCorrect = i == _currentQuestion.correctIndex;
                final showFeedback = _answered && selected;

                Color bgColor = Colors.grey[200]!;
                if (_answered) {
                  if (isCorrect) {
                    bgColor = Colors.green[100]!;
                  } else if (showFeedback) {
                    bgColor = Colors.red[100]!;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: _answered ? null : () {
                      setState(() => _selectedIndex = i);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? kPrimaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(
                        _currentQuestion.options[i],
                        style: TextStyle(
                          fontSize: 14,
                          color: _answered && !isCorrect && showFeedback
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Submit button
              if (!_answered)
                ElevatedButton(
                  onPressed: _selectedIndex != null ? _answerQuestion : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('答える'),
                )
              else
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(_questionIndex >= 4 ? 'ホームに戻る' : '次の問題へ'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper classes
class _LevelUpOverlay extends StatelessWidget {
  final int newLevel;
  const _LevelUpOverlay({required this.newLevel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'レベルアップ！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'レベル $newLevel',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('続ける'),
            ),
          ],
        ),
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
