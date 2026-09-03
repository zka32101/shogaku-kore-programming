import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/progress_provider.dart';
import '../providers/profile_provider.dart';
import '../models/challenge.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../providers/daily_review_provider.dart';
import '../providers/favorites_provider.dart';
import 'flashcard_screen.dart' show kFlashcards;
import 'quiz_review_screen.dart';
import 'wrong_answers_list_screen.dart';
import '../widgets/shortcut_help.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusNode _focusNode = FocusNode();
  bool _showDetailedStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      HapticService.selectionClick();
      _tabController.animateTo(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      HapticService.selectionClick();
      _tabController.animateTo(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      HapticService.selectionClick();
      _tabController.animateTo(2);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      HapticService.selectionClick();
      final next = (_tabController.index - 1).clamp(0, 2);
      _tabController.animateTo(next);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      HapticService.selectionClick();
      final next = (_tabController.index + 1).clamp(0, 2);
      _tabController.animateTo(next);
      return KeyEventResult.handled;
    }
    // Esc / Backspace → 戻る
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    // S → 統計をシェア
    if (key == LogicalKeyboardKey.keyS) {
      _shareStats(context);
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('1 / 2 / 3', 'タブ切り替え（バッジ/クリア/統計）'),
        ('← / →', '前/次のタブ'),
        ('S', '統計をシェア'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _shareStats(BuildContext context) {
    HapticService.lightImpact();
    final notifier = ref.read(progressProvider.notifier);
    final profile = ref.read(profileProvider);
    final completedCount = notifier.completedCount;
    final totalStars = notifier.totalStarsEarned;
    final level = notifier.currentLevel;
    final longestStreak = notifier.longestStreak;
    final masteredCards = ref.read(flashcardProvider).masteredIds.length;
    final allChallengesShare = ref.read(allChallengesProvider);
    final progressMapShare = ref.read(progressProvider);
    bool unitDoneShare(String level) {
      final unit = allChallengesShare.where((c) => c.level == level).toList();
      return unit.isNotEmpty && unit.every((c) => progressMapShare[c.id]?.isCompleted ?? false);
    }
    final badges = _getBadges(
      completedCount,
      totalStars,
      longestStreak,
      ref.read(timeAttackProvider).playCount,
      notifier.perfectStagesCount,
      ref.read(timeAttackProvider).bestCorrect,
      masteredCards,
      ref.read(wrongAnswersProvider).count,
      ref.read(wrongAnswersProvider).totalResolvedCount,
      notifier.totalQuestionsAnswered,
      ref.read(dailyReviewProvider).longestReviewStreak,
      ref.read(dailyReviewProvider).totalReviewsCompleted,
      ref.read(favoritesProvider).count,
      notifier.totalLearningSeconds,
      ref.read(timeAttackProvider).bestMaxCombo,
      unitDoneShare(StageLevel.beginner),
      unitDoneShare(StageLevel.intermediate),
      unitDoneShare(StageLevel.advanced),
      totalPerfectRuns: notifier.totalPerfectRuns,
    );
    final unlockedCount = badges.where((b) => b.isUnlocked).length;
    final text =
        '🏅 ${profile.nickname}の実績\n'
        'Lv.$level | ⭐ $totalStars pt\n'
        '✅ $completedCount/${AppConstants.totalStages} クリア\n'
        '🔥 最長連続: $longestStreak日\n'
        '🎖 バッジ: $unlockedCount/${badges.length}\n'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 クリップボードにコピーしました'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressMap = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final allChallenges = ref.watch(allChallengesProvider);
    final profile = ref.watch(profileProvider);

    final completedCount = notifier.completedCount;
    final totalStars = notifier.totalStarsEarned;
    final level = notifier.currentLevel;
    final streak = notifier.streakDays;
    final longestStreak = notifier.longestStreak;

    final taState = ref.watch(timeAttackProvider);
    final perfectCount = notifier.perfectStagesCount;
    final masteredCards = ref.watch(flashcardProvider).masteredIds.length;
    final wrongState = ref.watch(wrongAnswersProvider);
    final wrongCount = wrongState.count;
    final totalResolvedWrong = wrongState.totalResolvedCount;
    final totalAnswered = notifier.totalQuestionsAnswered;
    final reviewState = ref.watch(dailyReviewProvider);
    // バッジ判定は最長記録で行う（一度達成したら永続）
    final reviewStreak = reviewState.longestReviewStreak;
    final totalReviewsCompleted = reviewState.totalReviewsCompleted;
    final favoritesCount = ref.watch(favoritesProvider).count;
    final totalLearningSeconds = notifier.totalLearningSeconds;

    bool unitAllDone(String level) {
      final unit = allChallenges.where((c) => c.level == level).toList();
      return unit.isNotEmpty && unit.every((c) => progressMap[c.id]?.isCompleted ?? false);
    }
    final begUnitComplete = unitAllDone(StageLevel.beginner);
    final intUnitComplete = unitAllDone(StageLevel.intermediate);
    final advUnitComplete = unitAllDone(StageLevel.advanced);

    // ユニット別完了数（次に解除できるバッジのハイライト用の進捗シグナル）
    int unitDone(String level) => allChallenges
        .where((c) => c.level == level && (progressMap[c.id]?.isCompleted ?? false))
        .length;
    int unitTotal(String level) => allChallenges.where((c) => c.level == level).length;
    final begUnitDone = unitDone(StageLevel.beginner);
    final begUnitTotal = unitTotal(StageLevel.beginner);
    final intUnitDone = unitDone(StageLevel.intermediate);
    final intUnitTotal = unitTotal(StageLevel.intermediate);
    final advUnitDone = unitDone(StageLevel.advanced);
    final advUnitTotal = unitTotal(StageLevel.advanced);

    final badges = _getBadges(completedCount, totalStars, longestStreak, taState.playCount, perfectCount, taState.bestCorrect, masteredCards, wrongCount, totalResolvedWrong, totalAnswered, reviewStreak, totalReviewsCompleted, favoritesCount, totalLearningSeconds, taState.bestMaxCombo, begUnitComplete, intUnitComplete, advUnitComplete,
        totalPerfectRuns: notifier.totalPerfectRuns,
        begUnitDone: begUnitDone,
        begUnitTotal: begUnitTotal,
        intUnitDone: intUnitDone,
        intUnitTotal: intUnitTotal,
        advUnitDone: advUnitDone,
        advUnitTotal: advUnitTotal);
    final unlockedCount = badges.where((b) => b.isUnlocked).length;
    final weeklyData = notifier.weeklyActivity(weeks: 4);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // ヘッダー
            _buildHeader(
              context,
              profile,
              completedCount,
              totalStars,
              level,
              longestStreak,
              unlockedCount,
              badges.length,
            ),
            // タブバー
            Container(
              color: context.cardBg,
              child: TabBar(
                controller: _tabController,
                onTap: (_) => HapticService.selectionClick(),
                labelColor: kPrimaryColor,
                unselectedLabelColor: kTextSecondary,
                indicatorColor: kPrimaryColor,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'バッジ ($unlockedCount/${badges.length})'),
                  Tab(text: 'クリア ($completedCount)'),
                  const Tab(text: '📊 統計'),
                ],
              ),
            ),
            // タブコンテンツ
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BadgesTab(
                    badges: badges,
                    onRefresh: () async {
                      ref.invalidate(progressProvider);
                      ref.invalidate(allChallengesProvider);
                      await Future.delayed(const Duration(milliseconds: 400));
                    },
                  ),
                  _CompletedTab(
                    allChallenges: allChallenges,
                    progressMap: progressMap,
                    completedCount: completedCount,
                  ),
                  _StatsTab(
                    weeklyData: weeklyData,
                    allChallenges: allChallenges,
                    progressMap: progressMap,
                    streakDays: streak,
                    longestStreak: longestStreak,
                    completedCount: completedCount,
                    totalStars: totalStars,
                    totalQuestionsAnswered: notifier.totalQuestionsAnswered,
                    totalPerfectRuns: notifier.totalPerfectRuns,
                    showDetailedStats: _showDetailedStats,
                    onToggleDetails: () => setState(() => _showDetailedStats = !_showDetailedStats),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProfileState profile,
    int completedCount,
    int totalStars,
    int level,
    int longestStreak,
    int unlockedBadges,
    int totalBadges,
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
        MediaQuery.of(context).padding.top + 12,
        16,
        20,
      ),
      child: Column(
        children: [
          // タイトル行
          Row(
            children: [
              Text(profile.avatarEmoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${profile.nickname}の実績',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Lv.$level',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                tooltip: '統計をシェア (S)',
                onPressed: () => _shareStats(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4統計
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeaderStat(
                  icon: '✅',
                  value: '$completedCount/${AppConstants.totalStages}',
                  label: 'クリア'),
              _HeaderStat(
                  icon: '⭐', value: '$totalStars', label: 'ポイント'),
              _HeaderStat(
                  icon: '🔥', value: '$longestStreak日', label: '最長連続'),
              _HeaderStat(
                  icon: '🏅',
                  value: '$unlockedBadges/$totalBadges',
                  label: 'バッジ'),
            ],
          ),
        ],
      ),
    );
  }

  List<_Badge> _getBadges(
      int completedCount, int totalStars, int longestStreak, int taPlayCount,
      int perfectCount, int taBestCorrect, int masteredCards, int wrongCount,
      int totalResolvedWrong,
      int totalAnswered, int reviewStreak, int totalReviewsCompleted,
      int favoritesCount, int totalLearningSeconds, int taBestMaxCombo,
      bool begUnitComplete, bool intUnitComplete, bool advUnitComplete,
      {int totalPerfectRuns = 0,
      int begUnitDone = 0,
      int begUnitTotal = 0,
      int intUnitDone = 0,
      int intUnitTotal = 0,
      int advUnitDone = 0,
      int advUnitTotal = 0}) {
    // ストリークバッジは最長記録で判定（一度達成したら保持）
    final streak = longestStreak;
    final totalLearningMinutes = totalLearningSeconds ~/ 60;
    return [
      // 進捗バッジ
      _Badge(
        icon: '🚀',
        name: 'はじめの一歩',
        description: '最初のステージをクリア',
        category: 'progress',
        isUnlocked: completedCount >= 1,
        progressCurrent: completedCount.clamp(0, 1),
        progressTarget: 1,
      ),
      _Badge(
        icon: '🌿',
        name: 'コードビギナー',
        description: '3ステージクリア',
        category: 'progress',
        isUnlocked: completedCount >= 3,
        progressCurrent: completedCount.clamp(0, 3),
        progressTarget: 3,
      ),
      _Badge(
        icon: '🌱',
        name: '成長中',
        description: '5ステージクリア',
        category: 'progress',
        isUnlocked: completedCount >= 5,
        progressCurrent: completedCount.clamp(0, 5),
        progressTarget: 5,
      ),
      _Badge(
        icon: '🧩',
        name: 'ブロック名人',
        description: '8ステージクリア（初級の折り返し）',
        category: 'progress',
        isUnlocked: completedCount >= 8,
        progressCurrent: completedCount.clamp(0, 8),
        progressTarget: 8,
      ),
      _Badge(
        icon: '🎯',
        name: '1/4制覇',
        description: '10ステージクリア',
        category: 'progress',
        isUnlocked: completedCount >= 10,
        progressCurrent: completedCount.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '⭐',
        name: '15ステージ通過',
        description: '15ステージクリア',
        category: 'progress',
        isUnlocked: completedCount >= 15,
        progressCurrent: completedCount.clamp(0, 15),
        progressTarget: 15,
      ),
      _Badge(
        icon: '🐍',
        name: 'Python入門者',
        description: '20ステージクリア',
        category: 'progress',
        isUnlocked: completedCount >= 20,
        progressCurrent: completedCount.clamp(0, 20),
        progressTarget: 20,
      ),
      _Badge(
        icon: '🏅',
        name: '半分制覇',
        description: '25ステージクリア（折り返し地点！）',
        category: 'progress',
        isUnlocked: completedCount >= 25,
        progressCurrent: completedCount.clamp(0, 25),
        progressTarget: 25,
      ),
      _Badge(
        icon: '🔥',
        name: '上級者突入',
        description: '30ステージクリア',
        category: 'progress',
        isUnlocked: completedCount >= 30,
        progressCurrent: completedCount.clamp(0, 30),
        progressTarget: 30,
      ),
      _Badge(
        icon: '⚡',
        name: 'ゴールが見えた！',
        description: '35ステージクリア（あと5ステージ！）',
        category: 'progress',
        isUnlocked: completedCount >= 35,
        progressCurrent: completedCount.clamp(0, 35),
        progressTarget: 35,
      ),
      _Badge(
        icon: '👑',
        name: '全ステージ制覇',
        description: '${AppConstants.totalStages}ステージ全てクリア！',
        category: 'progress',
        isUnlocked: completedCount >= AppConstants.totalStages,
        progressCurrent: completedCount.clamp(0, AppConstants.totalStages),
        progressTarget: AppConstants.totalStages,
      ),
      // ユニット制覇バッジ
      _Badge(
        icon: '🧩',
        name: '初級クリア！',
        description: '初級の全ステージをクリア！',
        category: 'progress',
        isUnlocked: begUnitComplete,
        progressCurrent: begUnitDone,
        progressTarget: begUnitTotal,
      ),
      _Badge(
        icon: '🐍',
        name: '中級クリア！',
        description: '中級の全ステージをクリア！',
        category: 'progress',
        isUnlocked: intUnitComplete,
        progressCurrent: intUnitDone,
        progressTarget: intUnitTotal,
      ),
      _Badge(
        icon: '🚀',
        name: '全部クリア！',
        description: '全ユニット（初・中・上級）をクリア！',
        category: 'progress',
        isUnlocked: advUnitComplete,
        progressCurrent: advUnitDone,
        progressTarget: advUnitTotal,
      ),
      // スターバッジ
      _Badge(
        icon: '⭐',
        name: '星コレクター',
        description: 'ポイント50以上',
        category: 'stars',
        isUnlocked: totalStars >= 50,
        progressCurrent: totalStars.clamp(0, 50),
        progressTarget: 50,
      ),
      _Badge(
        icon: '💎',
        name: 'スター収集家',
        description: 'ポイント60以上',
        category: 'stars',
        isUnlocked: totalStars >= 60,
        progressCurrent: totalStars.clamp(0, 60),
        progressTarget: 60,
      ),
      _Badge(
        icon: '🌟',
        name: '輝く星',
        description: 'ポイント150以上',
        category: 'stars',
        isUnlocked: totalStars >= 150,
        progressCurrent: totalStars.clamp(0, 150),
        progressTarget: 150,
      ),
      _Badge(
        icon: '💰',
        name: 'ポイント長者',
        description: 'ポイント300以上',
        category: 'stars',
        isUnlocked: totalStars >= 300,
        progressCurrent: totalStars.clamp(0, 300),
        progressTarget: 300,
      ),
      _Badge(
        icon: '🌠',
        name: 'パーフェクトクリア',
        description: '全${AppConstants.totalStages}ステージ3つ星（${AppConstants.totalStages * 3}ポイント満点）',
        category: 'stars',
        isUnlocked: totalStars >= AppConstants.totalStages * 3,
        progressCurrent: totalStars.clamp(0, AppConstants.totalStages * 3),
        progressTarget: AppConstants.totalStages * 3,
      ),
      // 3つ星バッジ
      _Badge(
        icon: '✨',
        name: '完璧主義者',
        description: '3ステージで3つ星',
        category: 'stars',
        isUnlocked: perfectCount >= 3,
        progressCurrent: perfectCount.clamp(0, 3),
        progressTarget: 3,
      ),
      _Badge(
        icon: '⭐',
        name: '5ステージ完璧',
        description: '5ステージで3つ星',
        category: 'stars',
        isUnlocked: perfectCount >= 5,
        progressCurrent: perfectCount.clamp(0, 5),
        progressTarget: 5,
      ),
      _Badge(
        icon: '🌠',
        name: '3つ星コレクター',
        description: '10ステージで3つ星',
        category: 'stars',
        isUnlocked: perfectCount >= 10,
        progressCurrent: perfectCount.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '🎖️',
        name: 'パーフェクトマスター',
        description: '20ステージで3つ星満点',
        category: 'stars',
        isUnlocked: perfectCount >= 20,
        progressCurrent: perfectCount.clamp(0, 20),
        progressTarget: 20,
      ),
      // ストリークバッジ
      _Badge(
        icon: '💫',
        name: '2日連続',
        description: '2日連続でチャレンジ',
        category: 'streak',
        isUnlocked: streak >= 2,
        progressCurrent: streak.clamp(0, 2),
        progressTarget: 2,
      ),
      _Badge(
        icon: '🔥',
        name: '3日連続',
        description: '3日連続でチャレンジ',
        category: 'streak',
        isUnlocked: streak >= 3,
        progressCurrent: streak.clamp(0, 3),
        progressTarget: 3,
      ),
      _Badge(
        icon: '🔥🔥',
        name: '1週間連続',
        description: '7日連続でチャレンジ',
        category: 'streak',
        isUnlocked: streak >= 7,
        progressCurrent: streak.clamp(0, 7),
        progressTarget: 7,
      ),
      _Badge(
        icon: '⚡⚡',
        name: '2週間連続',
        description: '14日連続でチャレンジ',
        category: 'streak',
        isUnlocked: streak >= 14,
        progressCurrent: streak.clamp(0, 14),
        progressTarget: 14,
      ),
      _Badge(
        icon: '🏆',
        name: 'チャンピオン',
        description: '30日連続でチャレンジ',
        category: 'streak',
        isUnlocked: streak >= 30,
        progressCurrent: streak.clamp(0, 30),
        progressTarget: 30,
      ),
      _Badge(
        icon: '🔥🔥🔥',
        name: '1ヶ月連続',
        description: '60日連続でチャレンジ',
        category: 'streak',
        isUnlocked: streak >= 60,
        progressCurrent: streak.clamp(0, 60),
        progressTarget: 60,
      ),
      _Badge(
        icon: '🌟',
        name: '100日連続！',
        description: '100日連続でチャレンジ！伝説！',
        category: 'streak',
        isUnlocked: streak >= 100,
        progressCurrent: streak.clamp(0, 100),
        progressTarget: 100,
      ),
      // タイムアタック
      _Badge(
        icon: '⚡',
        name: 'タイムアタック参戦',
        description: 'タイムアタックに1回挑戦',
        category: 'special',
        isUnlocked: taPlayCount >= 1,
        progressCurrent: taPlayCount.clamp(0, 1),
        progressTarget: 1,
      ),
      _Badge(
        icon: '🏎️',
        name: 'スピードランナー',
        description: 'タイムアタックに10回挑戦',
        category: 'special',
        isUnlocked: taPlayCount >= 10,
        progressCurrent: taPlayCount.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '🔥',
        name: 'タイムアタック達人',
        description: 'タイムアタックで8問以上正解',
        category: 'special',
        isUnlocked: taBestCorrect >= 8,
        progressCurrent: taBestCorrect.clamp(0, 8),
        progressTarget: 8,
      ),
      _Badge(
        icon: '⚡',
        name: 'ライトニングクイズ',
        description: 'タイムアタックで全問正解',
        category: 'special',
        isUnlocked: taBestCorrect >= 10,
        progressCurrent: taBestCorrect.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '🔥',
        name: 'コンボ5連続',
        description: 'タイムアタックで5問連続正解',
        category: 'special',
        isUnlocked: taBestMaxCombo >= 5,
        progressCurrent: taBestMaxCombo.clamp(0, 5),
        progressTarget: 5,
      ),
      _Badge(
        icon: '🌟',
        name: 'コンボ神業',
        description: 'タイムアタックで10問連続正解（全問コンボ！）',
        category: 'special',
        isUnlocked: taBestMaxCombo >= 10,
        progressCurrent: taBestMaxCombo.clamp(0, 10),
        progressTarget: 10,
      ),
      // パーフェクトラン
      _Badge(
        icon: '💯',
        name: 'パーフェクトチャレンジャー',
        description: 'クイズを全問正解でクリア',
        category: 'special',
        isUnlocked: totalPerfectRuns >= 1,
        progressCurrent: totalPerfectRuns.clamp(0, 1),
        progressTarget: 1,
      ),
      _Badge(
        icon: '✨',
        name: 'パーフェクトマスター',
        description: 'クイズを全問正解で5回クリア',
        category: 'special',
        isUnlocked: totalPerfectRuns >= 5,
        progressCurrent: totalPerfectRuns.clamp(0, 5),
        progressTarget: 5,
      ),
      _Badge(
        icon: '👑',
        name: 'パーフェクトレジェンド',
        description: 'クイズを全問正解で20回クリア',
        category: 'special',
        isUnlocked: totalPerfectRuns >= 20,
        progressCurrent: totalPerfectRuns.clamp(0, 20),
        progressTarget: 20,
      ),
      // フラッシュカード
      _Badge(
        icon: '📚',
        name: '単語マスター',
        description: 'フラッシュカード5枚習得',
        category: 'special',
        isUnlocked: masteredCards >= 5,
        progressCurrent: masteredCards.clamp(0, 5),
        progressTarget: 5,
      ),
      _Badge(
        icon: '🃏',
        name: 'カードビギナー',
        description: 'フラッシュカード10枚習得',
        category: 'special',
        isUnlocked: masteredCards >= 10,
        progressCurrent: masteredCards.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '🧠',
        name: 'Python知識人',
        description: 'フラッシュカード20枚習得',
        category: 'special',
        isUnlocked: masteredCards >= 20,
        progressCurrent: masteredCards.clamp(0, 20),
        progressTarget: 20,
      ),
      _Badge(
        icon: '💡',
        name: '上級知識人',
        description: 'フラッシュカード30枚習得',
        category: 'special',
        isUnlocked: masteredCards >= 30,
        progressCurrent: masteredCards.clamp(0, 30),
        progressTarget: 30,
      ),
      _Badge(
        icon: '🎴',
        name: 'カードマスター',
        description: 'フラッシュカード全${kFlashcards.length}枚習得！',
        category: 'special',
        isUnlocked: masteredCards >= kFlashcards.length,
        progressCurrent: masteredCards.clamp(0, kFlashcards.length),
        progressTarget: kFlashcards.length,
      ),
      // 苦手問題克服
      _Badge(
        icon: '💪',
        name: '苦手克服',
        description: '苦手リストをゼロにした！',
        category: 'special',
        isUnlocked: wrongCount == 0 && completedCount >= 1,
      ),
      // 苦手問題累計克服マイルストーン
      _Badge(
        icon: '🎯',
        name: '苦手10問克服',
        description: '累計10問の苦手問題を克服した！',
        category: 'special',
        isUnlocked: totalResolvedWrong >= 10,
        progressCurrent: totalResolvedWrong.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '🌟',
        name: '苦手30問克服',
        description: '累計30問の苦手問題を克服した！',
        category: 'special',
        isUnlocked: totalResolvedWrong >= 30,
        progressCurrent: totalResolvedWrong.clamp(0, 30),
        progressTarget: 30,
      ),
      // スペシャル
      _Badge(
        icon: '👑',
        name: 'コード王',
        description: '全${AppConstants.totalStages}ステージクリア＋30日連続',
        category: 'special',
        isUnlocked: completedCount >= AppConstants.totalStages &&
            totalStars >= 100 &&
            streak >= 30,
      ),
      // 累計回答数バッジ
      _Badge(
        icon: '📝',
        name: '100問挑戦',
        description: '累計100問に回答',
        category: 'special',
        isUnlocked: totalAnswered >= 100,
        progressCurrent: totalAnswered.clamp(0, 100),
        progressTarget: 100,
      ),
      _Badge(
        icon: '📚',
        name: '500問達成',
        description: '累計500問に回答',
        category: 'special',
        isUnlocked: totalAnswered >= 500,
        progressCurrent: totalAnswered.clamp(0, 500),
        progressTarget: 500,
      ),
      _Badge(
        icon: '🧠',
        name: '1000問マスター',
        description: '累計1000問に回答',
        category: 'special',
        isUnlocked: totalAnswered >= 1000,
        progressCurrent: totalAnswered.clamp(0, 1000),
        progressTarget: 1000,
      ),
      // 今日の復習連続バッジ
      _Badge(
        icon: '📖',
        name: '復習3日連続',
        description: '今日の復習を3日連続で完了',
        category: 'streak',
        isUnlocked: reviewStreak >= 3,
        progressCurrent: reviewStreak.clamp(0, 3),
        progressTarget: 3,
      ),
      _Badge(
        icon: '📖📖',
        name: '復習1週間連続',
        description: '今日の復習を7日連続で完了',
        category: 'streak',
        isUnlocked: reviewStreak >= 7,
        progressCurrent: reviewStreak.clamp(0, 7),
        progressTarget: 7,
      ),
      _Badge(
        icon: '📖📖📖',
        name: '復習2週間連続',
        description: '今日の復習を14日連続で完了',
        category: 'streak',
        isUnlocked: reviewStreak >= 14,
        progressCurrent: reviewStreak.clamp(0, 14),
        progressTarget: 14,
      ),
      _Badge(
        icon: '🔖',
        name: '復習1ヶ月連続',
        description: '今日の復習を30日連続で完了！すごい！',
        category: 'streak',
        isUnlocked: reviewStreak >= 30,
        progressCurrent: reviewStreak.clamp(0, 30),
        progressTarget: 30,
      ),
      // 累計復習回数バッジ
      _Badge(
        icon: '📋',
        name: '復習5回達成',
        description: '今日の復習を累計5回完了',
        category: 'special',
        isUnlocked: totalReviewsCompleted >= 5,
        progressCurrent: totalReviewsCompleted.clamp(0, 5),
        progressTarget: 5,
      ),
      _Badge(
        icon: '📒',
        name: '復習10回達成',
        description: '今日の復習を累計10回完了',
        category: 'special',
        isUnlocked: totalReviewsCompleted >= 10,
        progressCurrent: totalReviewsCompleted.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '📕',
        name: '復習30回達成！',
        description: '今日の復習を累計30回完了！復習の達人！',
        category: 'special',
        isUnlocked: totalReviewsCompleted >= 30,
        progressCurrent: totalReviewsCompleted.clamp(0, 30),
        progressTarget: 30,
      ),
      // お気に入りバッジ
      _Badge(
        icon: '❤️',
        name: 'お気に入り登録',
        description: 'ステージを1つお気に入りに追加',
        category: 'special',
        isUnlocked: favoritesCount >= 1,
        progressCurrent: favoritesCount.clamp(0, 1),
        progressTarget: 1,
      ),
      _Badge(
        icon: '💝',
        name: 'お気に入りコレクター',
        description: 'ステージを5つお気に入りに追加',
        category: 'special',
        isUnlocked: favoritesCount >= 5,
        progressCurrent: favoritesCount.clamp(0, 5),
        progressTarget: 5,
      ),
      _Badge(
        icon: '💖',
        name: 'お気に入りマスター',
        description: 'ステージを10つお気に入りに追加',
        category: 'special',
        isUnlocked: favoritesCount >= 10,
        progressCurrent: favoritesCount.clamp(0, 10),
        progressTarget: 10,
      ),
      // 累計学習時間バッジ
      _Badge(
        icon: '⏱',
        name: '10分学習',
        description: '累計10分学習した',
        category: 'special',
        isUnlocked: totalLearningMinutes >= 10,
        progressCurrent: totalLearningMinutes.clamp(0, 10),
        progressTarget: 10,
      ),
      _Badge(
        icon: '⏰',
        name: '30分学習',
        description: '累計30分学習した',
        category: 'special',
        isUnlocked: totalLearningMinutes >= 30,
        progressCurrent: totalLearningMinutes.clamp(0, 30),
        progressTarget: 30,
      ),
      _Badge(
        icon: '🕐',
        name: '1時間学習',
        description: '累計1時間学習した',
        category: 'special',
        isUnlocked: totalLearningMinutes >= 60,
        progressCurrent: totalLearningMinutes.clamp(0, 60),
        progressTarget: 60,
      ),
      _Badge(
        icon: '🕑',
        name: '2時間学習',
        description: '累計2時間学習した',
        category: 'special',
        isUnlocked: totalLearningMinutes >= 120,
        progressCurrent: totalLearningMinutes.clamp(0, 120),
        progressTarget: 120,
      ),
      _Badge(
        icon: '🕒',
        name: '3時間学習',
        description: '累計3時間学習した',
        category: 'special',
        isUnlocked: totalLearningMinutes >= 180,
        progressCurrent: totalLearningMinutes.clamp(0, 180),
        progressTarget: 180,
      ),
      _Badge(
        icon: '🏆',
        name: '10時間学習',
        description: '累計10時間学習！本気の学習者！',
        category: 'special',
        isUnlocked: totalLearningMinutes >= 600,
        progressCurrent: totalLearningMinutes.clamp(0, 600),
        progressTarget: 600,
      ),
    ];
  }
}

// ──────────── Tabs ────────────────────────────────────────────────────────────

// フィルター状態
enum _BadgeFilter { all, unlocked, locked }

class _BadgesTab extends StatefulWidget {
  final List<_Badge> badges;
  final Future<void> Function() onRefresh;
  const _BadgesTab({required this.badges, required this.onRefresh});

  @override
  State<_BadgesTab> createState() => _BadgesTabState();
}

class _BadgesTabState extends State<_BadgesTab> {
  _BadgeFilter _filter = _BadgeFilter.all;

  @override
  Widget build(BuildContext context) {
    final categories = {
      'progress': '🎯 進捗',
      'stars': '⭐ スター',
      'streak': '🔥 ストリーク',
      'special': '👑 スペシャル',
    };

    final unlockedCount = widget.badges.where((b) => b.isUnlocked).length;
    final lockedCount = widget.badges.length - unlockedCount;

    // フィルター適用
    final filteredBadges = switch (_filter) {
      _BadgeFilter.unlocked => widget.badges.where((b) => b.isUnlocked).toList(),
      _BadgeFilter.locked   => widget.badges.where((b) => !b.isUnlocked).toList(),
      _BadgeFilter.all      => widget.badges,
    };

    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: widget.onRefresh,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // フィルターチップ
        Row(
          children: [
            _FilterChip(
              label: '全て (${widget.badges.length})',
              selected: _filter == _BadgeFilter.all,
              onTap: () => setState(() => _filter = _BadgeFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: '✅ 解除済み ($unlockedCount)',
              selected: _filter == _BadgeFilter.unlocked,
              onTap: () => setState(() => _filter = _BadgeFilter.unlocked),
              selectedColor: const Color(0xFF27AE60),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: '🔒 未解除 ($lockedCount)',
              selected: _filter == _BadgeFilter.locked,
              onTap: () => setState(() => _filter = _BadgeFilter.locked),
              selectedColor: kTextSecondary,
            ),
          ],
        ).animate().fadeIn(duration: 250.ms),
        const SizedBox(height: 14),

        // 次に解除できるバッジ ハイライトカード
        if (_filter != _BadgeFilter.unlocked) ...[
          Builder(builder: (context) {
            final nextBadge = widget.badges
                .where((b) => !b.isUnlocked && b.progressRatio != null && b.progressRatio! > 0)
                .fold<_Badge?>(null, (best, b) =>
                    best == null || b.progressRatio! > best.progressRatio! ? b : best);
            if (nextBadge == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _NextBadgeCard(badge: nextBadge),
            );
          }),
        ],

        // フィルター済みバッジ表示
        if (_filter == _BadgeFilter.all) ...[
          // カテゴリー別グリッド
          ...categories.entries.map((entry) {
            final catBadges =
                filteredBadges.where((b) => b.category == entry.key).toList();
            if (catBadges.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: catBadges.asMap().entries.map((e) =>
                    _BadgeCard(badge: e.value)
                        .animate()
                        .fadeIn(
                          duration: 300.ms,
                          delay: Duration(milliseconds: 50 * e.key),
                        )
                        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOut),
                  ).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ] else ...[
          // フラットグリッド（フィルター時）
          if (filteredBadges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  _filter == _BadgeFilter.unlocked
                      ? '🔒 まだバッジを解除していません'
                      : '🎉 全バッジを解除済み！',
                  style: const TextStyle(color: kTextSecondary, fontSize: 14),
                ),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: filteredBadges.asMap().entries.map((e) =>
                _BadgeCard(badge: e.value)
                    .animate()
                    .fadeIn(
                      duration: 250.ms,
                      delay: Duration(milliseconds: 30 * e.key),
                    )
                    .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
              ).toList(),
            ),
        ],
      ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? kPrimaryColor;
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : kTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ソート種別
enum _CompletedSort { date, stars, level }

class _CompletedTab extends StatefulWidget {
  final List<Stage> allChallenges;
  final Map<String, UserProgress> progressMap;
  final int completedCount;

  const _CompletedTab({
    required this.allChallenges,
    required this.progressMap,
    required this.completedCount,
  });

  @override
  State<_CompletedTab> createState() => _CompletedTabState();
}

class _CompletedTabState extends State<_CompletedTab> {
  _CompletedSort _sort = _CompletedSort.date;
  String? _levelFilter; // null=全て, StageLevel.beginner/intermediate/advanced

  @override
  Widget build(BuildContext context) {
    if (widget.completedCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎯', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text(
                'まだクリアしたステージがありません。\nチャレンジを始めよう！',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    // 完了済みを取得
    var completed = widget.allChallenges
        .where((c) => widget.progressMap[c.id]?.isCompleted ?? false)
        .toList();

    // レベルフィルター
    if (_levelFilter != null) {
      completed = completed.where((c) => c.level == _levelFilter).toList();
    }

    // ソート
    switch (_sort) {
      case _CompletedSort.date:
        completed.sort((a, b) {
          final ta = widget.progressMap[a.id]?.completedAt;
          final tb = widget.progressMap[b.id]?.completedAt;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta); // 新しい順
        });
      case _CompletedSort.stars:
        completed.sort((a, b) {
          final sa = widget.progressMap[a.id]?.starsEarned ?? 0;
          final sb = widget.progressMap[b.id]?.starsEarned ?? 0;
          return sb.compareTo(sa); // 高い順
        });
      case _CompletedSort.level:
        const order = {StageLevel.beginner: 0, StageLevel.intermediate: 1, StageLevel.advanced: 2};
        completed.sort((a, b) =>
            (order[a.level] ?? 0).compareTo(order[b.level] ?? 0));
    }

    return Column(
      children: [
        // コントロールバー
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // レベルフィルター
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: '全て (${widget.completedCount})',
                      selected: _levelFilter == null,
                      onTap: () => setState(() => _levelFilter = null),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '🧩 初級',
                      selected: _levelFilter == StageLevel.beginner,
                      onTap: () => setState(() => _levelFilter =
                          _levelFilter == StageLevel.beginner ? null : StageLevel.beginner),
                      selectedColor: kPrimaryColor,
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '🐍 中級',
                      selected: _levelFilter == StageLevel.intermediate,
                      onTap: () => setState(() => _levelFilter =
                          _levelFilter == StageLevel.intermediate ? null : StageLevel.intermediate),
                      selectedColor: const Color(0xFF9B59B6),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '🚀 上級',
                      selected: _levelFilter == StageLevel.advanced,
                      onTap: () => setState(() => _levelFilter =
                          _levelFilter == StageLevel.advanced ? null : StageLevel.advanced),
                      selectedColor: const Color(0xFFE67E22),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ソートボタン
              Row(
                children: [
                  Text(
                    '並び替え:',
                    style: const TextStyle(fontSize: 11, color: kTextSecondary),
                  ),
                  const SizedBox(width: 8),
                  _SortButton(
                    label: '🕒 日付',
                    selected: _sort == _CompletedSort.date,
                    onTap: () => setState(() => _sort = _CompletedSort.date),
                  ),
                  const SizedBox(width: 6),
                  _SortButton(
                    label: '⭐ スター',
                    selected: _sort == _CompletedSort.stars,
                    onTap: () => setState(() => _sort = _CompletedSort.stars),
                  ),
                  const SizedBox(width: 6),
                  _SortButton(
                    label: '📚 レベル',
                    selected: _sort == _CompletedSort.level,
                    onTap: () => setState(() => _sort = _CompletedSort.level),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 250.ms),
        const Divider(height: 1),
        // クリア統計サマリー
        if (completed.isNotEmpty)
          _CompletedStatsBar(
            completed: completed,
            progressMap: widget.progressMap,
          ).animate().fadeIn(duration: 200.ms),
        if (completed.isNotEmpty) const Divider(height: 1),
        // リスト
        Expanded(
          child: completed.isEmpty
              ? const Center(
                  child: Text(
                    'このレベルにクリア済みステージはありません',
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: completed.length,
                  itemBuilder: (context, index) {
                    final c = completed[index];
                    final progress = widget.progressMap[c.id]!;
                    return _CompletedStageCard(
                      challenge: c,
                      starsEarned: progress.starsEarned,
                      completedAt: progress.completedAt,
                    ).animate(delay: Duration(milliseconds: 30 * index))
                     .fadeIn(duration: 250.ms)
                     .slideX(begin: 0.06, curve: Curves.easeOut, duration: 250.ms);
                  },
                ),
        ),
      ],
    );
  }
}

// ──────────── クリア統計サマリーバー ─────────────────────────────────────────────

class _CompletedStatsBar extends StatelessWidget {
  final List<Stage> completed;
  final Map<String, UserProgress> progressMap;

  const _CompletedStatsBar({
    required this.completed,
    required this.progressMap,
  });

  @override
  Widget build(BuildContext context) {
    final total = completed.length;
    final perfectCount = completed
        .where((c) => (progressMap[c.id]?.starsEarned ?? 0) >= 3)
        .length;
    final totalStars = completed.fold<int>(
      0,
      (sum, c) => sum + (progressMap[c.id]?.starsEarned ?? 0),
    );
    final avgStars = total > 0 ? totalStars / total : 0.0;
    final improveable = total - perfectCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.subCardBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatMiniCell(label: 'クリア', value: '$total', color: kPrimaryColor),
          Container(width: 1, height: 28, color: context.borderColor),
          _StatMiniCell(
            label: '平均⭐',
            value: avgStars.toStringAsFixed(1),
            color: kStarColor,
          ),
          Container(width: 1, height: 28, color: context.borderColor),
          _StatMiniCell(
            label: '満点',
            value: '$perfectCount',
            color: const Color(0xFF27AE60),
          ),
          Container(width: 1, height: 28, color: context.borderColor),
          _StatMiniCell(
            label: '改善可',
            value: '$improveable',
            color: improveable > 0
                ? const Color(0xFFE67E22)
                : kPrimaryColor,
          ),
        ],
      ),
    );
  }
}

class _StatMiniCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatMiniCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: kTextSecondary),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? kPrimaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kPrimaryColor : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? kPrimaryColor : kTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ──────────── カード ──────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final _Badge badge;
  const _BadgeCard({required this.badge});

  void _showDetails(BuildContext context) {
    HapticService.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge.isUnlocked ? badge.icon : '🔒',
              style: TextStyle(
                fontSize: 56,
                color: badge.isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked ? context.textPrimary : kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: const TextStyle(
                fontSize: 14,
                color: kTextSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? kPrimaryColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge.isUnlocked ? '✅ 達成済み！' : '🔒 未達成',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked ? kPrimaryColor : kTextSecondary,
                ),
              ),
            ),
            // 未達成かつ進捗あり → プログレスバー
            if (!badge.isUnlocked && badge.progressRatio != null && badge.progressRatio! > 0) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '進捗',
                          style: const TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                        Text(
                          '${badge.progressCurrent} / ${badge.progressTarget}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: badge.progressRatio!),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 達成済みのときだけシェアボタンを表示
            if (badge.isUnlocked) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticService.lightImpact();
                    final text =
                        '🎓 小学生向けプログラミングアプリで「${badge.icon} ${badge.name}」バッジを獲得！\n'
                        '${badge.description}\n#しょうがくプログラミング';
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 シェア用テキストをコピーしました！'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('シェアする'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.5)),
                    foregroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = badge.progressRatio;
    final showProgress = !badge.isUnlocked && ratio != null && ratio > 0;

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
      decoration: BoxDecoration(
        color: badge.isUnlocked ? context.cardBg : context.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badge.isUnlocked
              ? kPrimaryColor.withValues(alpha: 0.3)
              : context.borderColor,
        ),
        boxShadow: badge.isUnlocked
            ? [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.isUnlocked ? badge.icon : '🔒',
              style: TextStyle(
                fontSize: 28,
                color: badge.isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked ? context.textPrimary : kTextSecondary,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: ratio),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: context.borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kPrimaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${badge.progressCurrent}/${badge.progressTarget}',
                      style: TextStyle(
                        fontSize: 10,
                        color: kPrimaryColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _CompletedStageCard extends StatelessWidget {
  final Stage challenge;
  final int starsEarned;
  final DateTime? completedAt;

  const _CompletedStageCard({
    required this.challenge,
    required this.starsEarned,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = challenge.level == StageLevel.beginner
        ? kPrimaryColor
        : challenge.level == StageLevel.intermediate
            ? const Color(0xFF9B59B6)
            : const Color(0xFFE67E22);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: levelColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(challenge.icon,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stage ${challenge.stageNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    color: levelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (completedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${completedAt!.year}/${completedAt!.month.toString().padLeft(2, '0')}/${completedAt!.day.toString().padLeft(2, '0')} クリア',
                    style: const TextStyle(
                        fontSize: 10, color: kTextSecondary),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: List.generate(
              challenge.maxStars,
              (i) => Icon(
                i < starsEarned ? Icons.star : Icons.star_border,
                size: 18,
                color: i < starsEarned ? kStarColor : context.borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── ヘッダー統計 ────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

// ──────────── データクラス ────────────────────────────────────────────────────

// ──────────── 次に解除できるバッジ カード ────────────────────────────────────────

class _NextBadgeCard extends StatelessWidget {
  final _Badge badge;
  const _NextBadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final ratio = badge.progressRatio!;
    final pct = (ratio * 100).round();
    final remaining = badge.progressTarget! - badge.progressCurrent!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.10),
            kPrimaryColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー行
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              const Text(
                '次に解除できるバッジ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // バッジ情報行
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor.withValues(alpha: 0.25)),
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 進捗ラベル
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${badge.progressCurrent} / ${badge.progressTarget}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kTextSecondary,
                ),
              ),
              Text(
                'あと$remaining で解除！',
                style: const TextStyle(
                  fontSize: 11,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ratio),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.06, end: 0, curve: Curves.easeOut);
  }
}

// ──────────── バッジデータモデル ───────────────────────────────────────────────

class _Badge {
  final String icon;
  final String name;
  final String description;
  final String category;
  final bool isUnlocked;
  /// 未解放バッジの進捗 (0〜progressTarget)
  final int? progressCurrent;
  final int? progressTarget;

  const _Badge({
    required this.icon,
    required this.name,
    required this.description,
    required this.category,
    required this.isUnlocked,
    this.progressCurrent,
    this.progressTarget,
  });

  double? get progressRatio {
    if (progressCurrent == null || progressTarget == null || progressTarget == 0) return null;
    return (progressCurrent! / progressTarget!).clamp(0.0, 1.0);
  }
}

// ──────────── 統計タブ ────────────────────────────────────────────────────────

class _StatsTab extends ConsumerWidget {
  final List<int> weeklyData;
  final List<Stage> allChallenges;
  final Map<String, UserProgress> progressMap;
  final int streakDays;
  final int longestStreak;
  final int completedCount;
  final int totalStars;
  final int totalQuestionsAnswered;
  final int totalPerfectRuns;
  final bool showDetailedStats;
  final VoidCallback onToggleDetails;

  const _StatsTab({
    required this.weeklyData,
    required this.allChallenges,
    required this.progressMap,
    required this.streakDays,
    required this.completedCount,
    required this.totalStars,
    required this.showDetailedStats,
    required this.onToggleDetails,
    this.longestStreak = 0,
    this.totalQuestionsAnswered = 0,
    this.totalPerfectRuns = 0,
  });

  int _completedInLevel(String level) {
    return allChallenges
        .where((c) => c.level == level && (progressMap[c.id]?.isCompleted ?? false))
        .length;
  }

  int _totalInLevel(String level) {
    return allChallenges.where((c) => c.level == level).length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteredCount = ref.watch(flashcardProvider).masteredIds.length;
    final totalFlashcards = kFlashcards.length;
    final wrongState = ref.watch(wrongAnswersProvider);
    final totalSeconds = ref.watch(
      progressProvider.select((_) => ref.read(progressProvider.notifier).totalLearningSeconds),
    );
    final totalMinutes = totalSeconds ~/ 60;
    final maxBar = weeklyData.isEmpty
        ? 1
        : weeklyData.reduce(math.max).clamp(1, 999);
    final activityByDate = ref.read(progressProvider.notifier).activityByDate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 28日間アクティビティヒートマップ
          _build28DayHeatmap(context, activityByDate)
              .animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 12),
          // ユニット別進捗
          _StatCard(
            title: '📚 ユニット別進捗',
            child: Column(
              children: [
                _UnitProgressRow(
                  icon: '🧩',
                  label: '初級',
                  completed: _completedInLevel(StageLevel.beginner),
                  total: _totalInLevel(StageLevel.beginner),
                  color: kPrimaryColor,
                ),
                const SizedBox(height: 14),
                _UnitProgressRow(
                  icon: '🐍',
                  label: '中級',
                  completed: _completedInLevel(StageLevel.intermediate),
                  total: _totalInLevel(StageLevel.intermediate),
                  color: const Color(0xFF9B59B6),
                ),
                const SizedBox(height: 14),
                _UnitProgressRow(
                  icon: '🚀',
                  label: '上級',
                  completed: _completedInLevel(StageLevel.advanced),
                  total: _totalInLevel(StageLevel.advanced),
                  color: const Color(0xFFE67E22),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 12),
          // サマリー
          _StatCard(
            title: '📊 総合サマリー',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryTile(
                      emoji: '🔥',
                      numValue: streakDays,
                      suffix: '日',
                      label: '連続学習',
                    ),
                    _SummaryTile(
                      emoji: '✅',
                      numValue: completedCount,
                      suffix: '',
                      label: 'クリア済み',
                    ),
                    _SummaryTile(
                      emoji: '⭐',
                      numValue: totalStars,
                      suffix: '',
                      label: '獲得ポイント',
                    ),
                  ],
                ),
                if (longestStreak > streakDays) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: context.borderColor),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏅', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        '最長ストリーク: $longestStreak日',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 8),
          // くわしく見る トグル
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticService.selectionClick();
                onToggleDetails();
              },
              icon: Icon(
                showDetailedStats ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(showDetailedStats ? 'とじる' : 'くわしく見る'),
              style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
            ),
          ),
          if (showDetailedStats) ...[
            const SizedBox(height: 4),
            // 週ごとの学習バーチャート
            _StatCard(
              title: '📅 週ごとの学習（過去4週）',
              child: SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxBar + 2).toDouble(),
                    barGroups: weeklyData.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.toDouble(),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [kPrimaryDark, kPrimaryColor],
                            ),
                            width: 32,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final v = weeklyData[value.toInt()];
                            if (v == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$v',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                            );
                          },
                          reservedSize: 20,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = ['3週前', '2週前', '先週', '今週'];
                            final idx = value.toInt();
                            if (idx < 0 || idx >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[idx],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: kTextSecondary,
                                ),
                              ),
                            );
                          },
                          reservedSize: 26,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: context.borderColor,
                        strokeWidth: 1,
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()}クリア',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
            const SizedBox(height: 12),
            // 累計回答数
            if (totalQuestionsAnswered > 0)
              _StatCard(
                title: '❓ 累計回答数',
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: totalQuestionsAnswered),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOut,
                            builder: (context, value, _) => Text(
                              '$value 問',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            completedCount > 0
                                ? '平均 ${(totalQuestionsAnswered / completedCount).toStringAsFixed(1)} 問/ステージ'
                                : 'クイズの回答が記録されます',
                            style: const TextStyle(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Text('🧠', style: TextStyle(fontSize: 40)),
                  ],
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
            if (totalSeconds > 0) ...[
              const SizedBox(height: 12),
              // 累計学習時間
              _StatCard(
                title: '⏱ 累計学習時間',
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: totalMinutes),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOut,
                            builder: (context, value, _) => Text(
                              value >= 60
                                  ? '${value ~/ 60} 時間 ${value % 60} 分'
                                  : '$value 分',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E44AD),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'クイズ・復習・タイムアタックの合計',
                            style: TextStyle(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Text('⏱', style: TextStyle(fontSize: 40)),
                  ],
                ),
              ).animate(delay: 260.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
            ],
            const SizedBox(height: 12),
            // フラッシュカード習得 & 苦手問題
            _buildLearningToolsCard(context, masteredCount, totalFlashcards, wrongState, ref)
                .animate(delay: 280.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
            const SizedBox(height: 12),
            // タイムアタック成績
            _buildTimeAttackCard(context, ref)
                .animate(delay: 310.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
            const SizedBox(height: 12),
            // 今日の復習成績
            _buildDailyReviewCard(context, ref)
                .animate(delay: 330.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
            const SizedBox(height: 12),
            // 完了予測
            _buildEstimationCard(context),
            const SizedBox(height: 12),
            // 学習品質
            _buildLearningQualityCard(context),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _build28DayHeatmap(BuildContext context, Map<DateTime, int> activityByDate) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // 28日分（4行 × 7列 = 月→日）
    const days = 28;
    final allDays = List.generate(days, (i) => today.subtract(Duration(days: days - 1 - i)));
    const weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

    // 活動のあった日数をカウント
    final activeDays = allDays.where((d) => (activityByDate[d] ?? 0) > 0).length;

    return _StatCard(
      title: '📅 28日間の学習カレンダー',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 曜日ラベル行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdayLabels.map((label) => SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: kTextSecondary),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 4),
          // 4週分のグリッド（各行は1週間、月曜→日曜）
          ...List.generate(4, (week) {
            final weekDays = allDays.sublist(week * 7, week * 7 + 7);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays.map((day) {
                  final count = activityByDate[day] ?? 0;
                  final isToday = day == today;
                  final Color cellColor;
                  if (count == 0) {
                    cellColor = context.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFEEEEEE);
                  } else if (count == 1) {
                    cellColor = kPrimaryColor.withValues(alpha: 0.35);
                  } else if (count <= 3) {
                    cellColor = kPrimaryColor.withValues(alpha: 0.6);
                  } else {
                    cellColor = kPrimaryColor;
                  }
                  return Tooltip(
                    message: '${day.month}/${day.day}: ${count > 0 ? '$count回' : '学習なし'}',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(color: kPrimaryColor, width: 2)
                            : null,
                      ),
                      child: count > 0
                          ? Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: count >= 4 ? Colors.white : kPrimaryColor,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '過去28日間のアクティブ日数: ',
                style: const TextStyle(fontSize: 11, color: kTextSecondary),
              ),
              Text(
                '$activeDays日',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Spacer(),
              // 凡例
              _HeatmapLegend(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAttackCard(BuildContext context, WidgetRef ref) {
    final taState = ref.watch(timeAttackProvider);
    if (taState.playCount == 0) return const SizedBox.shrink();

    const diffLabels = ['やさしい', 'ふつう', 'むずかしい'];
    const diffIcons = ['😊', '🎯', '🔥'];
    const diffColors = [
      Color(0xFF27AE60),
      Color(0xFF2980B9),
      Color(0xFFE67E22),
    ];

    return _StatCard(
      title: '⚡ タイムアタック',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _QualityMiniTile(
                  emoji: '🎮',
                  value: '${taState.playCount}回',
                  label: 'プレイ数',
                ),
              ),
              Expanded(
                child: _QualityMiniTile(
                  emoji: '🏆',
                  value: '${taState.bestScore}pt',
                  label: 'ベストスコア',
                ),
              ),
              Expanded(
                child: _QualityMiniTile(
                  emoji: '✅',
                  value: '${taState.bestCorrect}問',
                  label: '最多正解',
                ),
              ),
              if (taState.bestMaxCombo >= 2)
                Expanded(
                  child: _QualityMiniTile(
                    emoji: '🔥',
                    value: '${taState.bestMaxCombo}連続',
                    label: '最高コンボ',
                  ),
                ),
            ],
          ),
          // 難易度別ベスト
          if (taState.bestScoreByDifficulty.any((s) => s > 0)) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...List.generate(3, (i) {
              final score = taState.bestScoreByDifficulty[i];
              final correct = taState.bestCorrectByDifficulty[i];
              if (score == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Text(diffIcons[i],
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      diffLabels[i],
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecondary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: diffColors[i].withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$correct問  ${score}pt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: diffColors[i],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // 直近スコアトレンド
          if (taState.recentScores.length >= 3) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '📈 直近${taState.recentScores.length}回のトレンド',
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                ),
                const Spacer(),
                Builder(builder: (context) {
                  final trend = taState.scoreTrend;
                  if (trend == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: trend > 0
                          ? const Color(0xFF27AE60).withValues(alpha: 0.12)
                          : const Color(0xFFE74C3C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trend > 0 ? '↑ 上昇中' : '↓ 低下中',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trend > 0
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFE74C3C),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            // ミニスパークライン
            LayoutBuilder(builder: (context, constraints) {
              final scores = taState.recentScores;
              final maxScore = scores.reduce((a, b) => a > b ? a : b);
              final barWidth = (constraints.maxWidth - (scores.length - 1) * 4) / scores.length;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: scores.asMap().entries.map((e) {
                  final ratio = maxScore > 0 ? e.value / maxScore : 0.0;
                  final isLast = e.key == scores.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + e.key * 40),
                          curve: Curves.easeOut,
                          width: barWidth,
                          height: 32 * ratio + 4,
                          decoration: BoxDecoration(
                            color: isLast
                                ? kPrimaryColor
                                : kPrimaryColor.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLearningQualityCard(BuildContext context) {
    final completedEntries = progressMap.entries
        .where((e) => e.value.isCompleted)
        .toList();

    if (completedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final perfectCount = completedEntries.where((e) => e.value.starsEarned >= 3).length;
    final total = completedEntries.length;
    final perfectPct = (perfectCount / total * 100).round();
    final avgStars = completedEntries
            .map((e) => e.value.starsEarned)
            .reduce((a, b) => a + b) /
        total;

    // レベル別の平均スター
    Map<String, double> avgByLevel = {};
    for (final lvl in [StageLevel.beginner, StageLevel.intermediate, StageLevel.advanced]) {
      final lvlEntries = allChallenges
          .where((c) => c.level == lvl && (progressMap[c.id]?.isCompleted ?? false))
          .map((c) => progressMap[c.id]!.starsEarned)
          .toList();
      if (lvlEntries.isNotEmpty) {
        avgByLevel[lvl] = lvlEntries.reduce((a, b) => a + b) / lvlEntries.length;
      }
    }

    return _StatCard(
      title: '✨ 学習品質',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QualityMiniTile(
                  emoji: '⭐',
                  value: avgStars.toStringAsFixed(1),
                  label: '平均スター',
                ),
              ),
              Expanded(
                child: _QualityMiniTile(
                  emoji: '💯',
                  value: '$perfectPct%',
                  label: '満点率',
                ),
              ),
              Expanded(
                child: _QualityMiniTile(
                  emoji: '🏆',
                  value: '$perfectCount',
                  label: '3つ星ステージ',
                ),
              ),
              if (totalPerfectRuns > 0)
                Expanded(
                  child: _QualityMiniTile(
                    emoji: '💯',
                    value: '$totalPerfectRuns回',
                    label: '全問正解',
                  ),
                ),
            ],
          ),
          if (avgByLevel.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...avgByLevel.entries.map((entry) {
              final (icon, label, color) = switch (entry.key) {
                StageLevel.intermediate => ('🐍', '中級', const Color(0xFF9B59B6)),
                StageLevel.advanced => ('🚀', '上級', const Color(0xFFE67E22)),
                _ => ('🧩', '初級', kPrimaryColor),
              };
              final avg = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: avg / 3),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => SizedBox(
                        width: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms);
  }

  Widget _buildLearningToolsCard(
    BuildContext context,
    int masteredCount,
    int totalFlashcards,
    WrongAnswersState wrongState,
    WidgetRef ref,
  ) {
    final flashPct = totalFlashcards > 0 ? masteredCount / totalFlashcards : 0.0;
    final wrongCount = wrongState.count;

    // カテゴリー別習得数
    final masteredIds = ref.watch(flashcardProvider).masteredIds;
    final Map<String, (int, int)> categoryProgress = {}; // {category: (mastered, total)}
    for (final card in kFlashcards) {
      final current = categoryProgress[card.category] ?? (0, 0);
      final mastered = masteredIds.contains(card.id) ? current.$1 + 1 : current.$1;
      categoryProgress[card.category] = (mastered, current.$2 + 1);
    }
    // カテゴリーを掲載順で並べる（基本→制御→データ→関数→応用→クラス）
    const categoryOrder = ['基本', '制御', 'データ', '関数', '応用', 'クラス'];
    final sortedCategories = categoryOrder
        .where((c) => categoryProgress.containsKey(c))
        .toList();

    return _StatCard(
      title: '🛠️ 学習ツール',
      child: Column(
        children: [
          // フラッシュカード習得（合計）
          Row(
            children: [
              const Text('🃏', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('フラッシュカード習得',
                            style: TextStyle(fontSize: 12, color: kTextSecondary)),
                        Text(
                          '$masteredCount / $totalFlashcards',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2980B9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: flashPct),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: context.borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2980B9)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // カテゴリー別内訳
          if (masteredCount > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: sortedCategories.map((cat) {
                final (m, t) = categoryProgress[cat]!;
                final done = m >= t;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF2980B9).withValues(alpha: 0.12)
                        : context.subCardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: done
                          ? const Color(0xFF2980B9).withValues(alpha: 0.4)
                          : context.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (done) ...[
                        const Text('✅', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        '$cat $m/$t',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: done
                              ? const Color(0xFF2980B9)
                              : kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const Divider(height: 20),
          // 苦手問題
          Row(
            children: [
              Text(
                wrongCount == 0
                    ? (wrongState.totalResolvedCount > 0 ? '🏆' : '✅')
                    : '🔥',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('苦手問題',
                            style: TextStyle(fontSize: 12, color: kTextSecondary)),
                        Text(
                          wrongCount == 0 ? 'なし！' : '$wrongCount 件',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: wrongCount == 0
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFE74C3C),
                          ),
                        ),
                      ],
                    ),
                    if (wrongState.totalResolvedCount > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('累計克服',
                              style: TextStyle(fontSize: 11, color: kTextSecondary)),
                          Text(
                            '🎯 ${wrongState.totalResolvedCount} 件',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (wrongCount > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final answers = ref.read(wrongAnswersProvider).answers;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizReviewScreen(wrongAnswers: answers),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      '復習する',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (wrongCount > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WrongAnswersListScreen(),
                    ),
                  );
                },
                child: const Text(
                  '一覧を見る →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
          // 苦手 TOP3（2回以上間違えた問題がある場合のみ表示）
          if (wrongState.maxWrongCount >= 2) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: 8),
            const Text(
              '🔥 よく間違える問題 TOP3',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 6),
            ...() {
              final sorted = [...wrongState.answers]
                ..sort((a, b) => wrongState.wrongCountFor(b.questionText)
                    .compareTo(wrongState.wrongCountFor(a.questionText)));
              return sorted
                  .where((a) => wrongState.wrongCountFor(a.questionText) >= 2)
                  .take(3)
                  .map((a) {
                    final cnt = wrongState.wrongCountFor(a.questionText);
                    final maxLen = 28;
                    final qText = a.questionText.length > maxLen
                        ? '${a.questionText.substring(0, maxLen)}…'
                        : a.questionText;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '×$cnt',
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
                              qText,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList();
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyReviewCard(BuildContext context, WidgetRef ref) {
    final rv = ref.watch(dailyReviewProvider);
    final streak = rv.reviewStreak;
    final longestStreak = rv.longestReviewStreak;
    final total = rv.totalReviewsCompleted;
    if (total == 0) return const SizedBox.shrink();
    return _StatCard(
      title: '📖 今日の復習',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QualityMiniTile(
                  emoji: '📋',
                  value: '$total回',
                  label: '累計完了',
                ),
              ),
              Expanded(
                child: _QualityMiniTile(
                  emoji: '🔥',
                  value: '$streak日',
                  label: '連続中',
                ),
              ),
              if (longestStreak >= 3)
                Expanded(
                  child: _QualityMiniTile(
                    emoji: '🏅',
                    value: '$longestStreak日',
                    label: '最長連続',
                  ),
                ),
            ],
          ),
          if (total >= 5) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📚', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  total >= 30
                      ? '復習の達人！$total回完了！'
                      : total >= 10
                          ? '継続は力なり！$total回達成！'
                          : 'コツコツ復習中... $total回完了！',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimationCard(BuildContext context) {
    final total = allChallenges.length;
    final remaining = total - completedCount;
    if (remaining <= 0) {
      return _StatCard(
        title: '🏁 完了予測',
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Text(
              '全ステージ制覇！おめでとう！',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ).animate(delay: 250.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms);
    }

    // 過去7日間のペース（日別クリア数の平均）
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int totalLast7 = 0;
    for (int d = 0; d < 7; d++) {
      final day = today.subtract(Duration(days: d));
      totalLast7 += progressMap.values.where((p) {
        if (!p.isCompleted || p.completedAt == null) return false;
        final pDate = DateTime(p.completedAt!.year, p.completedAt!.month, p.completedAt!.day);
        return pDate == day;
      }).length;
    }
    final dailyAvg = totalLast7 / 7.0;

    final String estimation;
    if (completedCount == 0) {
      estimation = 'まずは最初のステージに挑戦しよう！';
    } else if (dailyAvg < 0.1) {
      estimation = '毎日1ステージで約$remaining日で完了！';
    } else {
      final daysLeft = (remaining / dailyAvg).ceil();
      estimation = 'このペースで約$daysLeft日後に全クリア！';
    }

    final completionRate = completedCount / total;

    return _StatCard(
      title: '🏁 完了予測',
      child: Column(
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  estimation,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(completionRate * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: completionRate),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: kPrimaryColor.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount / $total ステージ',
                style: const TextStyle(fontSize: 11, color: kTextSecondary),
              ),
              Text(
                'あと $remaining ステージ',
                style: const TextStyle(fontSize: 11, color: kTextSecondary),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms);
  }
}

class _QualityMiniTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _QualityMiniTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: kTextSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// ヒートマップの凡例（薄い→濃いの色見本）
class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('少', style: TextStyle(fontSize: 9, color: kTextSecondary)),
        const SizedBox(width: 2),
        ...List.generate(4, (i) {
          final alphas = [0.08, 0.35, 0.6, 1.0];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: i == 0
                  ? (kPrimaryColor.withValues(alpha: 0.08))
                  : kPrimaryColor.withValues(alpha: alphas[i]),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 2),
        const Text('多', style: TextStyle(fontSize: 9, color: kTextSecondary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _UnitProgressRow extends StatelessWidget {
  final String icon;
  final String label;
  final int completed;
  final int total;
  final Color color;

  const _UnitProgressRow({
    required this.icon,
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : completed / total;

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$completed/$total',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: pct),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String emoji;
  final int numValue;
  final String suffix;
  final String label;

  const _SummaryTile({
    required this.emoji,
    required this.numValue,
    required this.suffix,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: numValue),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, value, _) => Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kTextSecondary),
        ),
      ],
    );
  }
}
