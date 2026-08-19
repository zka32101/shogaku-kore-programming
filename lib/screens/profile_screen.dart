import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/learning_calendar.dart';
import '../widgets/weekly_chart.dart';
import '../providers/wrong_answers_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/daily_review_provider.dart';
import '../models/challenge.dart';
import '../providers/challenges_provider.dart';
import '../config/constants.dart';
import '../widgets/shortcut_help.dart';
import 'flashcard_screen.dart' show kFlashcards;
import '../providers/ai_programming_coach_provider.dart';

// アバターとして使える絵文字
const _kAvatarEmojis = [
  '🧑‍💻', '👦', '👧', '🧒', '🧑', '🙋', '🤓', '😎',
  '🦸', '🧙', '🤖', '🦊', '🐧', '🐱', '🐸', '🦁',
  '🚀', '⭐', '💎', '🏆', '🎮', '🎯', '🔥', '✨',
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _editing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.nickname);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (_editing) {
      if (key == LogicalKeyboardKey.escape) {
        setState(() => _editing = false);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored; // let TextField handle other keys
    }
    if (key == LogicalKeyboardKey.keyE) {
      HapticService.lightImpact();
      setState(() => _editing = true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      _shareProfile(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('E', '名前を編集'),
        ('S', '学習記録をシェア'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _shareProfile(BuildContext context) {
    HapticService.lightImpact();
    final notifier = ref.read(progressProvider.notifier);
    final profile = ref.read(profileProvider);
    final streak = notifier.streakDays;
    final level = notifier.currentLevel;
    final completed = notifier.completedCount;
    final total = AppConstants.totalStages;
    final stars = notifier.totalStarsEarned;
    final perfect = notifier.perfectStagesCount;
    final totalSeconds = notifier.totalLearningSeconds;
    final totalMinutes = totalSeconds ~/ 60;
    final masteredCount = ref.read(flashcardProvider).masteredIds.length;
    final reviewStreak = ref.read(dailyReviewProvider).reviewStreak;
    final taState = ref.read(timeAttackProvider);
    final wrongState = ref.read(wrongAnswersProvider);
    final timeLine = totalSeconds > 0
        ? '⏱ 学習時間: ${totalMinutes >= 60 ? '${totalMinutes ~/ 60}時間${totalMinutes % 60}分' : '$totalMinutes分'}\n'
        : '';
    final masteredLine = masteredCount > 0
        ? '🃏 フラッシュカード: $masteredCount/${kFlashcards.length}枚習得\n'
        : '';
    final reviewLine = reviewStreak >= 2
        ? '📖 復習連続: $reviewStreak日\n'
        : '';
    final taLine = taState.playCount > 0
        ? '⚡ タイムアタック: ベスト${taState.bestScore}pt\n'
        : '';
    final resolvedLine = wrongState.totalResolvedCount > 0
        ? '🎯 苦手克服: ${wrongState.totalResolvedCount}件\n'
        : '';
    final text =
        '${profile.avatarEmoji} ${profile.nickname} の学習記録\n'
        '📚 クリア: $completed/$total ステージ\n'
        '🎯 レベル: $level\n'
        '⭐ ポイント: $stars pt\n'
        '💎 3つ星: $perfect ステージ\n'
        '🔥 連続学習: $streak 日\n'
        '$timeLine'
        '$masteredLine'
        '$reviewLine'
        '$taLine'
        '$resolvedLine'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 学習記録をコピーしました！'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final progressMap = ref.watch(progressProvider);
    final progressNotifier = ref.read(progressProvider.notifier);
    final timeAttack = ref.watch(timeAttackProvider);
    final allChallenges = ref.watch(allChallengesProvider);
    final reviewState = ref.watch(dailyReviewProvider);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: Column(
        children: [
          // ヘッダー
          _buildHeader(context, profile, progressNotifier.currentLevel),
          // コンテンツ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ニックネーム編集
                  _buildNicknameCard(profile)
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // アバター選択
                  _buildAvatarPicker(profile)
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 統計
                  _buildStatsCard(progressNotifier)
                      .animate(delay: 160.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 10),
                  // 今日の復習ストリーク
                  if (reviewState.reviewStreak >= 1)
                    _buildReviewStreakRow(reviewState)
                        .animate(delay: 170.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  if (reviewState.reviewStreak >= 1)
                    const SizedBox(height: 12),
                  // レベル別進捗
                  _buildLevelProgressCard(allChallenges, progressMap)
                      .animate(delay: 185.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 12),
                  // 学習品質
                  _buildLearningQualityRow()
                      .animate(delay: 215.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 週次グラフ
                  _buildWeeklyChart(progressNotifier)
                      .animate(delay: 240.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 学習カレンダー
                  _buildCalendarCard(progressNotifier)
                      .animate(delay: 320.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 継続率カード
                  _buildConsistencyCard(progressNotifier)
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 📚 学習パス提案
                  _buildAILearningPathCard(allChallenges, progressMap, progressNotifier.currentLevel)
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 学習時間帯分析
                  _buildStudyTimeCard(progressMap)
                      .animate(delay: 390.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // タイムアタック記録
                  _buildTimeAttackCard(timeAttack)
                      .animate(delay: 430.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 最近クリアしたステージ
                  _buildRecentlyCompletedCard(allChallenges, progressMap)
                      .animate(delay: 450.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // シェアボタン
                  _buildShareCard(profile, progressNotifier)
                      .animate(delay: 470.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
      ),  // closes Scaffold (child of Focus)
    );    // closes Focus return
  }

  String _levelTitle(int level) {
    if (level >= 20) return '🏆 レジェンドコーダー';
    if (level >= 15) return '👑 エキスパートプログラマー';
    if (level >= 10) return '🔥 上級コードハンター';
    if (level >= 7)  return '💎 中級プログラマー';
    if (level >= 4)  return '⭐ 見習いコーダー';
    if (level >= 2)  return '🌱 成長中のプログラマー';
    return '🚀 コード探険家';
  }

  Widget _buildHeader(BuildContext context, ProfileState profile, int level) {
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
        24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'プロフィール',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          // アバター大表示
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Text(
                profile.avatarEmoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profile.nickname,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _levelTitle(level),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameCard(ProfileState profile) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ニックネーム',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (_editing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    maxLength: 12,
                    decoration: InputDecoration(
                      hintText: 'ニックネームを入力',
                      counterText: '',
                      filled: true,
                      fillColor: context.subCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onSubmitted: (_) => _saveName(),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: _saveName,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('保存'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.nickname,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _editing = true;
                    _nameController.text = profile.nickname;
                  }),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('変更'),
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _saveName() {
    HapticService.lightImpact();
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前が空だったので「たんけんか」にしたよ')),
      );
    }
    ref.read(profileProvider.notifier).setNickname(_nameController.text);
    setState(() => _editing = false);
    FocusScope.of(context).unfocus();
  }

  Widget _buildAvatarPicker(ProfileState profile) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アバターを選ぼう',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _kAvatarEmojis.length,
            itemBuilder: (context, index) {
              final emoji = _kAvatarEmojis[index];
              final isSelected = emoji == profile.avatarEmoji;
              return GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  ref.read(profileProvider.notifier).setAvatar(emoji);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? kPrimaryColor.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.08),
                    border: isSelected
                        ? Border.all(color: kPrimaryColor, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgressCard(
    List<Challenge> allChallenges,
    Map<String, UserProgress> progressMap,
  ) {
    final levels = [
      (StageLevel.beginner, '🌱 初級', const Color(0xFF27AE60)),
      (StageLevel.intermediate, '🔥 中級', const Color(0xFF9B59B6)),
      (StageLevel.advanced, '⚡ 上級', const Color(0xFFE67E22)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                'レベル別進捗',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 各レベルの進捗バー
          ...levels.map((entry) {
            final (levelKey, label, color) = entry;
            final total = allChallenges.where((c) => c.level == levelKey).length;
            final cleared = allChallenges
                .where((c) => c.level == levelKey && (progressMap[c.id]?.isCompleted ?? false))
                .length;
            final perfect = allChallenges
                .where((c) => c.level == levelKey && (progressMap[c.id]?.starsEarned ?? 0) >= 3)
                .length;
            final pct = total > 0 ? cleared / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$cleared / $total クリア',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⭐$perfect',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD68910),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: pct),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLevelProgressBar(ProgressNotifier notifier) {
    final level = notifier.currentLevel;
    final starsToNext = notifier.starsToNextLevel;
    final progress = notifier.levelProgress;

    if (starsToNext == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Lv.$level 最高レベル到達！',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: context.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lv.$level',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              Text(
                'あと ${starsToNext}pt で Lv.${level + 1}',
                style: const TextStyle(fontSize: 11, color: kTextSecondary),
              ),
              Text(
                'Lv.${level + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: context.isDark ? kDarkSurface2 : Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ProgressNotifier notifier) {
    final streak = notifier.streakDays;
    final longest = notifier.longestStreak;
    // ストリーク目標: 3, 7, 14, 30日
    final streakGoal = streak < 3
        ? 3
        : streak < 7
            ? 7
            : streak < 14
                ? 14
                : 30;
    final streakProgress = (streak / streakGoal).clamp(0.0, 1.0);
    final perfect = notifier.perfectStagesCount;
    final today = notifier.todayClearedCount;
    final totalAnswered = notifier.totalQuestionsAnswered;
    final activeDays = notifier.activityByDate.length;
    final totalSeconds = notifier.totalLearningSeconds;
    final totalMinutes = totalSeconds ~/ 60;
    final learningTimeLabel = totalSeconds == 0
        ? '—'
        : totalMinutes >= 60
            ? '${totalMinutes ~/ 60}時間${totalMinutes % 60}分'
            : '$totalMinutes分';

    return Column(
      children: [
        // メイン統計行
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kPrimaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: '🏆',
                value: '${notifier.completedCount}',
                label: 'クリア',
              ),
              _StatItem(
                icon: '⭐',
                value: '${notifier.totalStarsEarned}',
                label: 'ポイント',
              ),
              _StatItem(
                icon: '🎯',
                value: 'Lv.${notifier.currentLevel}',
                label: 'レベル',
              ),
              _StatItem(
                icon: '💎',
                value: '$perfect',
                label: '3つ星',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // レベル進捗バー
        _buildLevelProgressBar(notifier),
        const SizedBox(height: 10),
        // 累計統計行（累計回答数・学習日数・学習時間）
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                emoji: '📝',
                value: totalAnswered > 0 ? '$totalAnswered問' : '—',
                label: '累計回答数',
                color: const Color(0xFF2980B9),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStatCard(
                emoji: '📅',
                value: activeDays > 0 ? '$activeDays日' : '—',
                label: '学習した日',
                color: const Color(0xFF27AE60),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStatCard(
                emoji: '⏱',
                value: learningTimeLabel,
                label: '累計学習時間',
                color: const Color(0xFF8E44AD),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ストリークカード
        Container(
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
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '$streak日連続学習',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (today > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '今日 $today クリア',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: streakProgress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: context.isDark ? kDarkSurface2 : Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$streak日',
                    style: const TextStyle(
                        fontSize: 12, color: kTextSecondary),
                  ),
                  Text(
                    '目標: $streakGoal日',
                    style: const TextStyle(
                        fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
              // 達成まで残り日数メッセージ
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  streak >= streakGoal
                      ? '🏆 $streakGoal日連続達成！次の目標は${_nextStreakGoal(streak)}日！'
                      : '🔥 あと${streakGoal - streak}日で$streakGoal日連続達成！',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B35),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // 最長ストリーク表示
              if (longest > 1) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏅', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '最長ストリーク: $longest日',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  int _nextStreakGoal(int streak) {
    const milestones = [3, 7, 14, 30, 60, 100];
    return milestones.firstWhere((m) => m > streak, orElse: () => streak + 30);
  }

  Widget _buildReviewStreakRow(DailyReviewState reviewState) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            emoji: '📖',
            value: '${reviewState.reviewStreak}日',
            label: '復習連続',
            color: const Color(0xFF8E44AD),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            emoji: '🏅',
            value: reviewState.longestReviewStreak > 0
                ? '${reviewState.longestReviewStreak}日'
                : '—',
            label: '最長復習',
            color: const Color(0xFF8E44AD),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            emoji: '✅',
            value: reviewState.totalReviewsCompleted > 0
                ? '${reviewState.totalReviewsCompleted}回'
                : '—',
            label: '累計復習',
            color: const Color(0xFF27AE60),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningQualityRow() {
    final wrongState = ref.watch(wrongAnswersProvider);
    final wrongCount = wrongState.count;
    final resolvedCount = wrongState.totalResolvedCount;
    final masteredCount = ref.watch(flashcardProvider).masteredIds.length;
    final favCount = ref.watch(favoritesProvider).count;
    final kTotal = kFlashcards.length;

    return Row(
      children: [
        Expanded(
          child: _QualityMiniCard(
            emoji: '🃏',
            value: '$masteredCount / $kTotal',
            label: 'カード習得',
            color: const Color(0xFF2980B9),
            progress: masteredCount / kTotal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QualityMiniCard(
            emoji: wrongCount == 0
                ? (resolvedCount > 0 ? '🏆' : '✅')
                : '🔥',
            value: '$wrongCount 件',
            label: resolvedCount > 0
                ? '苦手問題（克服 $resolvedCount 件）'
                : '苦手問題',
            color: wrongCount == 0
                ? const Color(0xFF27AE60)
                : const Color(0xFFE74C3C),
            progress: wrongCount == 0
                ? 1.0
                : (1.0 - (wrongCount / 30).clamp(0.0, 1.0)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QualityMiniCard(
            emoji: '❤️',
            value: '$favCount 件',
            label: 'お気に入り',
            color: Colors.pink.shade400,
            progress: favCount == 0 ? 0.0 : (favCount / 10).clamp(0.0, 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(ProgressNotifier notifier) {
    final data = notifier.weeklyActivity(weeks: 4);
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '週次学習グラフ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WeeklyChartWidget(weeklyData: data),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(ProgressNotifier notifier) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '学習カレンダー',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LearningCalendarWidget(
            activityByDate: notifier.activityByDate,
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyCard(ProgressNotifier notifier) {
    final activityByDate = notifier.activityByDate;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // 過去30日間のアクティブ日数を計算
    int activeDays = 0;
    for (int i = 0; i < 30; i++) {
      final d = todayNorm.subtract(Duration(days: i));
      if ((activityByDate[d] ?? 0) > 0) activeDays++;
    }
    final pct = (activeDays / 30 * 100).round();

    // 週ごとの日別アクティブ状態（過去4週、各週7日、days[0] = 最新日）
    final weekDayActivity = List.generate(4, (week) {
      return List.generate(7, (d) {
        final date = todayNorm.subtract(Duration(days: week * 7 + d));
        return (activityByDate[date] ?? 0) > 0;
      });
    }).reversed.toList();

    // 週ごとのアクティブ日数（バッジ・集計用）
    final weekActivity = weekDayActivity
        .map((days) => days.where((b) => b).length)
        .toList();

    // 充実していた週（アクティブ日が3日以上の週）の数
    final consistentWeeks = weekActivity.where((w) => w >= 3).length;

    String rating;
    Color ratingColor;
    String advice;
    if (pct >= 90) {
      rating = '🏆 パーフェクト';
      ratingColor = const Color(0xFFE74C3C);
      advice = '完璧な継続力！この調子で続けよう';
    } else if (pct >= 70) {
      rating = '🔥 とても良い';
      ratingColor = const Color(0xFFE67E22);
      advice = 'すばらしい！毎日少しずつ積み上げてる';
    } else if (pct >= 50) {
      rating = '⭐ 良い';
      ratingColor = const Color(0xFFF1C40F);
      advice = '半分以上学習できてる！もう少し頑張ろう';
    } else if (pct >= 30) {
      rating = '🌱 普通';
      ratingColor = const Color(0xFF27AE60);
      advice = '毎日少しでも開いてみよう';
    } else {
      rating = '💤 頑張ろう';
      ratingColor = const Color(0xFF95A5A6);
      advice = '1日5分だけでも学習してみよう！';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '継続率（過去30日）',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ratingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rating,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ratingColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 大きな数値表示
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$activeDays',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: ratingColor,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ 30日',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ratingColor,
                    ),
                  ),
                  Text(
                    '$consistentWeeks/4週が充実',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activeDays / 30,
              minHeight: 8,
              backgroundColor: context.shadowColor,
              valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
            ),
          ),
          const SizedBox(height: 10),
          // 週ごとのドット表示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...List.generate(4, (weekIdx) {
                final days = weekDayActivity[weekIdx];
                final weekLabel = weekIdx == 3 ? '今週' : '${3 - weekIdx}週前';
                return Column(
                  children: [
                    Row(
                      children: List.generate(7, (dayIdx) {
                        final filled = days[dayIdx];
                        return Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? ratingColor
                                : ratingColor.withValues(alpha: 0.15),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      weekLabel,
                      style: TextStyle(
                        fontSize: 8,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          // アドバイス
          Text(
            '💡 $advice',
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAILearningPathCard(
      List<Challenge> allChallenges, Map<String, UserProgress> progressMap, int level) {
    // 学習パスデータの集計
    final masterTopics = <String>[];
    final struggleTopics = <String>[];
    int totalScore = 0;

    for (final entry in progressMap.entries) {
      final progress = entry.value;
      totalScore += progress.starsEarned;

      // テーマ別分析：進捗率で分類
      if (progress.isCompleted) {
        masterTopics.add(entry.key);
      } else if (progress.starsEarned == 0) {
        struggleTopics.add(entry.key);
      }
    }

    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📚 学習パス提案',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI があなたの学習データから、次のステップをおすすめします！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // AI ボタン
            Consumer(
              builder: (ctx, ref, _) {
                ref.watch(aiProgrammingCoachProvider); // AI状態変化で再描画

                return GestureDetector(
                  onTap: () async {
                    await ref.read(aiProgrammingCoachProvider.notifier)
                        .getNextLearningPath(
                      completedLevel: level,
                      masterTopics: masterTopics,
                      struggleTopics: struggleTopics,
                      totalScore: totalScore,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '🤖 AI に学習パスを提案してもらう',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // AI レスポンス表示
            Consumer(
              builder: (ctx, ref2, _) {
                final aiState = ref2.watch(aiProgrammingCoachProvider);
                if (aiState.coachType == 'learning_path' &&
                    (aiState.content != null || aiState.isLoading)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: aiState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : aiState.error != null
                              ? Text(aiState.error!, style: const TextStyle(color: Colors.red))
                              : Text(aiState.content ?? '', style: const TextStyle(fontSize: 13)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyTimeCard(Map<String, UserProgress> progressMap) {
    // 時間帯別クリア数を集計
    final slots = [0, 0, 0, 0]; // 朝, 昼, 夕, 夜
    for (final p in progressMap.values) {
      if (!p.isCompleted || p.completedAt == null) continue;
      final h = p.completedAt!.hour;
      if (h >= 5 && h < 10) {
        slots[0]++;
      } else if (h >= 10 && h < 15) {
        slots[1]++;
      } else if (h >= 15 && h < 20) {
        slots[2]++;
      } else {
        slots[3]++;
      }
    }
    final total = slots.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    const labels = ['☀️ 朝', '🌤️ 昼', '🌇 夕方', '🌙 夜'];
    const colors = [
      Color(0xFFE67E22),
      Color(0xFF2ECC71),
      Color(0xFF9B59B6),
      Color(0xFF3498DB),
    ];
    final maxSlot = slots.reduce((a, b) => a > b ? a : b);
    final peakIndex = slots.indexOf(maxSlot);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🕐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '学習時間帯',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors[peakIndex].withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${labels[peakIndex].split(' ')[1]}が一番多い',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors[peakIndex],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(4, (i) {
            final count = slots[i];
            final ratio = maxSlot > 0 ? count / maxSlot : 0.0;
            final pct = total > 0 ? (count / total * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      labels[i],
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: Duration(milliseconds: 700 + i * 80),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: colors[i].withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(colors[i]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$count回 ($pct%)',
                      style: const TextStyle(fontSize: 10, color: kTextSecondary),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentlyCompletedCard(
    List<Challenge> allChallenges,
    Map<String, UserProgress> progressMap,
  ) {
    // 完了済みかつcompletedAtがあるものを新しい順に最大5件取得
    final recent = allChallenges
        .where((c) =>
            (progressMap[c.id]?.isCompleted ?? false) &&
            progressMap[c.id]?.completedAt != null)
        .toList()
      ..sort((a, b) => progressMap[b.id]!.completedAt!
          .compareTo(progressMap[a.id]!.completedAt!));
    final display = recent.take(5).toList();

    if (display.isEmpty) return const SizedBox.shrink();

    return Container(
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
              const Text('🕐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '最近クリアしたステージ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...display.map((c) {
            final progress = progressMap[c.id]!;
            final completedAt = progress.completedAt!;
            final days = DateTime.now().difference(completedAt).inDays;
            final dateLabel = days == 0
                ? '今日'
                : days == 1
                    ? '昨日'
                    : '$days日前';
            final levelColor = switch (c.level) {
              StageLevel.intermediate => const Color(0xFF9B59B6),
              StageLevel.advanced => const Color(0xFFE67E22),
              _ => kPrimaryColor,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(c.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: levelColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < progress.starsEarned
                            ? Icons.star
                            : Icons.star_border,
                        size: 13,
                        color: i < progress.starsEarned
                            ? kStarColor
                            : Colors.grey.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeAttackCard(TimeAttackState ta) {
    const diffLabels = ['🟢 やさしい', '🟡 ふつう', '🔴 むずかしい'];
    const diffColors = [Color(0xFF43A047), Color(0xFFFF8F00), Color(0xFFE53935)];

    // 全体ベストを最大値として進捗バー計算
    final maxScore = ta.bestScoreByDifficulty.fold<int>(1, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー行
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'タイムアタック記録',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${ta.playCount}回プレイ',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8F00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 全体ベストスコア
          if (ta.bestScore > 0) ...[
            Row(
              children: [
                Text(
                  '全体ベスト: ${ta.bestScore} pt  (正解 ${ta.bestCorrect}問)',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
                if (ta.bestMaxCombo >= 2) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔥${ta.bestMaxCombo}連続',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE67E22),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          // 難易度別
          ...List.generate(3, (i) {
            final score = ta.bestScoreByDifficulty[i];
            final correct = ta.bestCorrectByDifficulty[i];
            final ratio = score > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
            final played = score > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      diffLabels[i],
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: Duration(milliseconds: 700 + i * 80),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: diffColors[i].withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(diffColors[i]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      played ? '$score pt ($correct問)' : '未プレイ',
                      style: TextStyle(
                        fontSize: 10,
                        color: played ? kTextSecondary : kTextSecondary.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          // 未プレイ時メッセージ
          if (ta.playCount == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'タイムアタックに挑戦してみよう！',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextSecondary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShareCard(ProfileState profile, ProgressNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _shareProfile(context),
        icon: const Icon(Icons.share_outlined, size: 16),
        label: const Text('学習記録をシェア (S)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimaryColor,
          side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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

class _MiniStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _MiniStatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityMiniCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final double progress;

  const _QualityMiniCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, val, _) => LinearProgressIndicator(
                value: val,
                backgroundColor:
                    context.isDark ? kDarkSurface2 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}
