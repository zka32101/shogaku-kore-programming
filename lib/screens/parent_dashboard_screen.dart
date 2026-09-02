import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/progress_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/challenges_provider.dart';
import '../models/challenge.dart';
import '../models/stage.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/learning_calendar.dart';
import '../providers/wrong_answers_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/daily_review_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/shortcut_help.dart';
import 'flashcard_screen.dart' show kFlashcards;

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.keyS) {
      _shareReport(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(
        context,
        shortcuts: const [
          ('S', '学習レポートをシェア'),
          ('Esc / BS', '前の画面に戻る'),
          ('?', 'このヘルプを表示'),
        ],
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _shareReport(BuildContext context) {
    HapticService.lightImpact();
    final notifier = ref.read(progressProvider.notifier);
    final profile = ref.read(profileProvider);
    final completed = notifier.completedCount;
    final total = AppConstants.totalStages;
    final stars = notifier.totalStarsEarned;
    final level = notifier.currentLevel;
    final streak = notifier.streakDays;
    final totalSeconds = notifier.totalLearningSeconds;
    final totalMinutes = totalSeconds ~/ 60;
    final masteredCount = ref.read(flashcardProvider).masteredIds.length;
    final reviewStreak = ref.read(dailyReviewProvider).reviewStreak;
    final timeLine = totalSeconds > 0
        ? '⏱ 学習時間: ${totalMinutes >= 60 ? '${totalMinutes ~/ 60}時間${totalMinutes % 60}分' : '$totalMinutes分'}\n'
        : '';
    final masteredLine = masteredCount > 0
        ? '🃏 フラッシュカード: $masteredCount/${kFlashcards.length}枚習得\n'
        : '';
    final reviewLine = reviewStreak >= 2
        ? '📖 復習連続: $reviewStreak日\n'
        : '';
    final text =
        '👨‍👩‍👧 ${profile.nickname} の学習レポート\n'
        '📚 クリア: $completed/$total ステージ\n'
        '🎯 レベル: $level | ⭐ $stars pt\n'
        '🔥 連続学習: $streak 日\n'
        '$timeLine'
        '$masteredLine'
        '$reviewLine'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 学習レポートをコピーしました'),
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
    final notifier = ref.read(progressProvider.notifier);
    final profile = ref.watch(profileProvider);

    final completed = notifier.completedCount;
    final total = AppConstants.totalStages;
    final stars = notifier.totalStarsEarned;
    final level = notifier.currentLevel;
    final streak = notifier.streakDays;
    final longestStreak = notifier.longestStreak;
    final progressMap = ref.watch(progressProvider);
    final allChallenges = ref.watch(allChallengesProvider);

    // 正答率（完了済みステージのみ）
    final completedEntries = progressMap.values
        .where((p) => p.isCompleted)
        .toList();
    final avgStars = completedEntries.isEmpty
        ? 0.0
        : completedEntries
                .map((p) => p.starsEarned)
                .reduce((a, b) => a + b) /
            completedEntries.length;

    // 苦手問題・フラッシュカード習得数・タイムアタック・お気に入り
    final wrongState = ref.watch(wrongAnswersProvider);
    final wrongCount = wrongState.count;
    final resolvedCount = wrongState.totalResolvedCount;
    final masteredCount = ref.watch(flashcardProvider).masteredIds.length;
    final taState = ref.watch(timeAttackProvider);
    final favCount = ref.watch(favoritesProvider).count;
    final reviewState = ref.watch(dailyReviewProvider);

    // 最近クリアしたステージ（completedAt降順、最大5件）
    final recentlyCompleted = allChallenges
        .where((c) => progressMap[c.id]?.isCompleted == true &&
            progressMap[c.id]?.completedAt != null)
        .toList()
      ..sort((a, b) => progressMap[b.id]!.completedAt!
          .compareTo(progressMap[a.id]!.completedAt!));
    final recentStages = recentlyCompleted.take(5).toList();

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 子供の情報カード
                  _buildChildCard(profile, level, streak, longestStreak, reviewState)
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 学習サマリー
                  _buildSummarySection(
                          context, completed, total, stars, avgStars,
                          notifier.totalQuestionsAnswered,
                          notifier.totalLearningSeconds)
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 学習品質カード（苦手問題・フラッシュカード）
                  _buildQualitySection(context, wrongCount, resolvedCount, masteredCount, taState, favCount, reviewState)
                      .animate(delay: 120.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 週次グラフ
                  _buildWeeklyChartSection(context, notifier)
                      .animate(delay: 160.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 学習カレンダー
                  _buildCalendarSection(context, notifier)
                      .animate(delay: 240.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 継続率（30日）
                  _buildConsistencySection(context, notifier)
                      .animate(delay: 280.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 学習時間帯分析
                  _buildStudyTimeSection(context, progressMap)
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // ユニット別進捗
                  _buildUnitProgress(context, progressMap)
                      .animate(delay: 340.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 16),
                  // 最近クリアしたステージ
                  if (recentStages.isNotEmpty) ...[
                    _buildRecentlyCompleted(context, recentStages, progressMap)
                        .animate(delay: 420.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                    const SizedBox(height: 16),
                  ],
                  // 学習アドバイス
                  _buildAdviceSection(completed, total, streak, avgStars, reviewState, wrongCount, resolvedCount, masteredCount)
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    ),   // closes Scaffold
    );   // closes Focus
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5D6D7E), Color(0xFF2C3E50)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              '👨‍👩‍👧 保護者ダッシュボード',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: '学習レポートをシェア (S)',
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(ProfileState profile, int level, int streak, int longestStreak, DailyReviewState reviewState) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          // アバター
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                profile.avatarEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nickname,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _StatChip(label: 'Lv.$level'),
                    _StatChip(label: '🔥 $streak日連続'),
                    if (longestStreak > streak)
                      _StatChip(label: '🏅 最長$longestStreak日'),
                    _StatChip(
                      label: reviewState.doneToday ? '📖 復習済み' : '📖 未復習',
                      color: reviewState.doneToday
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.orange.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
      BuildContext context, int completed, int total, int stars, double avgStars,
      int totalAnswered, int totalSeconds) {
    final percent = total > 0 ? (completed / total * 100).round() : 0;
    final totalMinutes = totalSeconds ~/ 60;
    final learningTimeLabel = totalSeconds == 0
        ? '—'
        : totalMinutes >= 60
            ? '${totalMinutes ~/ 60}時間${totalMinutes % 60}分'
            : '$totalMinutes分';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '📊 学習サマリー'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                emoji: '✅',
                value: '$completed / $total',
                label: 'クリア済み',
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                emoji: '⭐',
                value: '$stars',
                label: '獲得ポイント',
                color: const Color(0xFFF39C12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                emoji: '🎯',
                value: '$percent%',
                label: '進捗率',
                color: const Color(0xFF9B59B6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 平均スター
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              const Text('平均スター', style: TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                fontWeight: FontWeight.w500,
              )),
              const Spacer(),
              Row(
                children: List.generate(3, (i) {
                  return Icon(
                    i < avgStars.round() ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 6),
              Text(
                avgStars.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 累計学習時間・回答数
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                emoji: '⏱',
                value: learningTimeLabel,
                label: '累計学習時間',
                color: const Color(0xFF8E44AD),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                emoji: '📝',
                value: totalAnswered > 0 ? '$totalAnswered問' : '—',
                label: '累計回答数',
                color: const Color(0xFF2980B9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualitySection(
      BuildContext context, int wrongCount, int resolvedCount, int masteredCount, TimeAttackState taState, int favCount,
      DailyReviewState reviewState) {
    final kFlashcardTotal = kFlashcards.length;
    final masteredPercent =
        (masteredCount / kFlashcardTotal * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '🔍 学習品質'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                emoji: wrongCount == 0
                    ? (resolvedCount > 0 ? '🏆' : '✅')
                    : '🔥',
                value: '$wrongCount',
                label: resolvedCount > 0
                    ? '苦手問題（克服 $resolvedCount 件）'
                    : '苦手問題',
                color: wrongCount == 0
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFE74C3C),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                emoji: '🃏',
                value: '$masteredCount / $kFlashcardTotal',
                label: 'カード習得済み',
                color: const Color(0xFF2980B9),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                emoji: '❤️',
                value: '$favCount',
                label: 'お気に入り',
                color: Colors.pink.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          emoji: '📈',
          value: '$masteredPercent%',
          label: 'フラッシュカード習得率',
          color: const Color(0xFF16A085),
        ),
        if (taState.playCount > 0) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: context.shadowColor, blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'タイムアタック',
                            style: TextStyle(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '総合ベスト ${taState.bestScore}pt（正解 ${taState.bestCorrect}/10問）${taState.bestMaxCombo >= 2 ? "  🔥最高${taState.bestMaxCombo}連続" : ""}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${taState.playCount}回',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ),
                  ],
                ),
                // 難易度別ベスト（プレイあり難易度のみ表示）
                if (taState.bestScoreByDifficulty.any((s) => s > 0)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int di = 0; di < 3; di++)
                        if (taState.bestScoreByDifficulty[di] > 0)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: di < 2 ? 8 : 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE67E22).withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE67E22)
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      ['やさしい', 'ふつう', 'むずかしい'][di],
                                      style: const TextStyle(
                                          fontSize: 9, color: kTextSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${taState.bestScoreByDifficulty[di]}pt',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE67E22),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (reviewState.totalReviewsCompleted > 0) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: context.shadowColor, blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '毎日の復習',
                        style: TextStyle(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '累計${reviewState.totalReviewsCompleted}回完了'
                        '${reviewState.reviewStreak >= 2 ? "  🔥${reviewState.reviewStreak}日連続" : ""}'
                        '${reviewState.longestReviewStreak > reviewState.reviewStreak && reviewState.longestReviewStreak >= 3 ? "  🏅最長${reviewState.longestReviewStreak}日" : ""}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (reviewState.doneToday
                            ? const Color(0xFF27AE60)
                            : const Color(0xFF95A5A6))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reviewState.doneToday ? '今日済み' : '未完了',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: reviewState.doneToday
                          ? const Color(0xFF27AE60)
                          : const Color(0xFF95A5A6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (wrongCount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFE74C3C), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '苦手問題が $wrongCount 件あります。'
                    '「苦手復習」で繰り返し練習しましょう。',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // 🔥 よく間違える問題 TOP3
        Builder(builder: (context) {
          final ws = ref.read(wrongAnswersProvider);
          if (ws.maxWrongCount < 2) return const SizedBox.shrink();
          final sorted = [...ws.answers]
            ..sort((a, b) => ws.wrongCountFor(b.questionText)
                .compareTo(ws.wrongCountFor(a.questionText)));
          final top3 = sorted
              .where((a) => ws.wrongCountFor(a.questionText) >= 2)
              .take(3)
              .toList();
          if (top3.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: context.shadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔥 よく間違える問題 TOP3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE64A00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...top3.asMap().entries.map((e) {
                    final idx = e.key;
                    final a = e.value;
                    final cnt = ws.wrongCountFor(a.questionText);
                    final qShort = a.questionText.length > 28
                        ? '${a.questionText.substring(0, 28)}…'
                        : a.questionText;
                    return Padding(
                      padding: EdgeInsets.only(top: idx > 0 ? 6 : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '×$cnt',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE64A00),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              qShort,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeeklyChartSection(BuildContext context, ProgressNotifier notifier) {
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
                '週ごとの学習量',
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

  Widget _buildCalendarSection(BuildContext context, ProgressNotifier notifier) {
    final activityByDate = notifier.activityByDate;
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
            activityByDate: activityByDate,
            weeksToShow: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitProgress(BuildContext context, Map<String, UserProgress> progressMap) {
    // ステージIDのハードコードは60ステージ全体とズレやすいため、
    // 実際のチャレンジデータからレベル別に動的に算出する。
    final allChallenges = ref.watch(allChallengesProvider);
    List<String> idsForLevel(String level) => allChallenges
        .where((c) => c.level == level)
        .map((c) => c.id)
        .toList();

    final units = [
      _UnitProgress(
        name: 'Unit 1 · 初級',
        subtitle: 'ブロックプログラミング基礎',
        emoji: '🧩',
        color: kPrimaryColor,
        stageIds: idsForLevel(StageLevel.beginner),
      ),
      _UnitProgress(
        name: 'Unit 2 · 中級',
        subtitle: 'Pythonプログラミング入門',
        emoji: '🐍',
        color: const Color(0xFF9B59B6),
        stageIds: idsForLevel(StageLevel.intermediate),
      ),
      _UnitProgress(
        name: 'Unit 3 · 上級',
        subtitle: 'Python応用・自動化',
        emoji: '🚀',
        color: const Color(0xFFE67E22),
        stageIds: idsForLevel(StageLevel.advanced),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '📚 ユニット別進捗'),
        const SizedBox(height: 10),
        ...units.map((unit) {
          final done = unit.stageIds
              .where((id) => progressMap[id]?.isCompleted == true)
              .length;
          final pct = unit.stageIds.isEmpty
              ? 0.0
              : done / unit.stageIds.length;
          return _UnitProgressCard(
            unit: unit,
            completedCount: done,
            total: unit.stageIds.length,
            progress: pct,
          );
        }),
      ],
    );
  }

  Widget _buildRecentlyCompleted(
    BuildContext context,
    List<Stage> stages,
    Map<String, UserProgress> progressMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '🕐 最近クリアしたステージ'),
        const SizedBox(height: 10),
        ...stages.asMap().entries.map((e) {
          final c = e.value;
          final progress = progressMap[c.id]!;
          final at = progress.completedAt!;
          final dateStr = '${at.month}/${at.day} クリア';
          final levelColor = c.level == StageLevel.beginner
              ? kPrimaryColor
              : c.level == StageLevel.intermediate
                  ? const Color(0xFF9B59B6)
                  : const Color(0xFFE67E22);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: levelColor, width: 3)),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 20)),
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
                      ),
                      Text(
                        'Stage ${c.stageNumber} · $dateStr',
                        style: const TextStyle(fontSize: 10, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    c.maxStars,
                    (i) => Icon(
                      i < progress.starsEarned ? Icons.star : Icons.star_border,
                      size: 14,
                      color: i < progress.starsEarned
                          ? kStarColor
                          : context.borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: 40 * e.key))
           .fadeIn(duration: 250.ms)
           .slideX(begin: 0.06, curve: Curves.easeOut, duration: 250.ms);
        }),
      ],
    );
  }

  Widget _buildConsistencySection(BuildContext context, ProgressNotifier notifier) {
    final activityByDate = notifier.activityByDate;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // 過去30日間のアクティブ日数
    int activeDays = 0;
    int totalClears = 0;
    for (int i = 0; i < 30; i++) {
      final d = todayNorm.subtract(Duration(days: i));
      final count = activityByDate[d] ?? 0;
      if (count > 0) activeDays++;
      totalClears += count;
    }
    final pct = (activeDays / 30 * 100).round();

    // 週ごとのアクティブ日（過去4週）
    final weekData = List.generate(4, (weekIdx) {
      int active = 0;
      for (int d = 0; d < 7; d++) {
        final date = todayNorm.subtract(Duration(days: weekIdx * 7 + d));
        if ((activityByDate[date] ?? 0) > 0) active++;
      }
      return active;
    }).reversed.toList();

    Color barColor;
    String rating;
    if (pct >= 80) {
      barColor = const Color(0xFF27AE60);
      rating = '優秀';
    } else if (pct >= 50) {
      barColor = const Color(0xFFF39C12);
      rating = '良好';
    } else if (pct >= 30) {
      barColor = const Color(0xFFE67E22);
      rating = '普通';
    } else {
      barColor = const Color(0xFF95A5A6);
      rating = '要サポート';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '📊 継続率（過去30日）'),
        const SizedBox(height: 10),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$activeDays',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      '/ 30日  ($pct%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: activeDays / 30,
                  minHeight: 8,
                  backgroundColor: context.shadowColor,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 12),
              // 週ごとのバー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekData.asMap().entries.map((e) {
                  final weekIdx = e.key;
                  final days = e.value;
                  final height = 4.0 + (days / 7) * 36.0;
                  final label = weekIdx == 3 ? '今週' : '${3 - weekIdx}週前';
                  return Column(
                    children: [
                      Text(
                        '$days日',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: days >= 5 ? barColor : context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400 + weekIdx * 80),
                        width: 36,
                        height: height,
                        decoration: BoxDecoration(
                          color: days >= 5
                              ? barColor
                              : days >= 3
                                  ? barColor.withValues(alpha: 0.5)
                                  : barColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '30日間で合計$totalClearsステージクリア',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudyTimeSection(BuildContext context, Map<String, UserProgress> progressMap) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '🕐 学習時間帯'),
        const SizedBox(height: 10),
        Container(
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
                  Expanded(
                    child: Text(
                      'よく学習する時間帯',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors[peakIndex].withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${labels[peakIndex].split(' ')[1]}が多い',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors[peakIndex],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(4, (i) {
                final count = slots[i];
                final ratio = maxSlot > 0 ? count / maxSlot : 0.0;
                final pct = total > 0 ? (count / total * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: ratio),
                            duration: Duration(milliseconds: 600 + i * 80),
                            curve: Curves.easeOut,
                            builder: (context, value, _) => LinearProgressIndicator(
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
                        width: 44,
                        child: Text(
                          '$count回 ($pct%)',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceSection(
      int completed, int total, int streak, double avgStars,
      DailyReviewState reviewState, int wrongCount, int resolvedCount, int masteredCount) {
    final List<_AdviceItem> advices = [];

    if (streak >= 7) {
      advices.add(const _AdviceItem(
        emoji: '🔥',
        text: '7日以上連続学習中！素晴らしい習慣が身についています。',
        color: Color(0xFFFF6B35),
      ));
    } else if (streak >= 3) {
      advices.add(const _AdviceItem(
        emoji: '💪',
        text: '3日以上連続！継続は力なり。このまま続けよう。',
        color: Color(0xFF27AE60),
      ));
    } else {
      advices.add(const _AdviceItem(
        emoji: '📅',
        text: '毎日少しずつ学習するとストリークが伸びます。一緒に応援しましょう！',
        color: Color(0xFF3498DB),
      ));
    }

    if (avgStars >= 2.5) {
      advices.add(const _AdviceItem(
        emoji: '⭐',
        text: '高いスター評価を維持中！理解度が高い証拠です。',
        color: Color(0xFFF39C12),
      ));
    } else if (avgStars >= 1.5) {
      advices.add(const _AdviceItem(
        emoji: '📖',
        text: 'ミスした問題を一緒に復習すると、さらに理解が深まります。',
        color: Color(0xFF9B59B6),
      ));
    }

    // 苦手問題克服のアドバイス
    if (resolvedCount >= 10) {
      advices.add(_AdviceItem(
        emoji: '🎯',
        text: '苦手問題を$resolvedCount件克服しました！粘り強く取り組んでいる証拠です。素晴らしい！',
        color: const Color(0xFF27AE60),
      ));
    } else if (resolvedCount >= 3) {
      advices.add(_AdviceItem(
        emoji: '💪',
        text: '苦手問題を$resolvedCount件克服しました！この調子で続けよう！',
        color: const Color(0xFF1ABC9C),
      ));
    }

    // 苦手問題が多いときのアドバイス
    if (wrongCount >= 10) {
      advices.add(_AdviceItem(
        emoji: '⚠️',
        text: '苦手問題が$wrongCount件あります。「苦手問題の復習」で一緒に取り組んでみましょう！',
        color: const Color(0xFFE74C3C),
      ));
    } else if (wrongCount >= 3) {
      advices.add(_AdviceItem(
        emoji: '📝',
        text: '苦手問題が$wrongCount件たまっています。定期的な復習で苦手を克服しましょう。',
        color: const Color(0xFFE67E22),
      ));
    }

    if (completed >= total ~/ 2) {
      advices.add(const _AdviceItem(
        emoji: '🎉',
        text: '半分以上クリア！上級ステージでPythonプログラミングに挑戦しよう。',
        color: Color(0xFF1ABC9C),
      ));
    }

    if (reviewState.reviewStreak >= 7) {
      advices.add(const _AdviceItem(
        emoji: '📖',
        text: '7日以上毎日復習を続けています！知識の定着に非常に効果的です。',
        color: Color(0xFF2980B9),
      ));
    } else if (!reviewState.doneToday && reviewState.totalReviewsCompleted > 0) {
      advices.add(const _AdviceItem(
        emoji: '⏰',
        text: '今日の復習がまだです。毎日の復習が記憶の定着に一番効果的です。',
        color: Color(0xFFE67E22),
      ));
    }

    // フラッシュカード習得が少ない・進んでいるときのアドバイス
    if (masteredCount == 0 && completed >= 3) {
      advices.add(const _AdviceItem(
        emoji: '🃏',
        text: 'フラッシュカードをまだ試していません。用語の暗記にとても役立ちます！',
        color: Color(0xFF2980B9),
      ));
    } else if (masteredCount >= 20) {
      advices.add(_AdviceItem(
        emoji: '🧠',
        text: 'フラッシュカード$masteredCount枚を習得中！語彙力がしっかりついています。',
        color: const Color(0xFF8E44AD),
      ));
    }

    if (advices.isEmpty) {
      advices.add(const _AdviceItem(
        emoji: '🚀',
        text: '学習を開始しよう！最初のステージからプログラミングを体験できます。',
        color: Color(0xFF1ABC9C),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '💡 保護者へのアドバイス'),
        const SizedBox(height: 10),
        ...advices.map((advice) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: advice.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: advice.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(advice.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        advice.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: advice.color,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ── データクラス ──────────────────────────────────────────────────────────────

class _UnitProgress {
  final String name;
  final String subtitle;
  final String emoji;
  final Color color;
  final List<String> stageIds;

  const _UnitProgress({
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.stageIds,
  });
}

class _AdviceItem {
  final String emoji;
  final String text;
  final Color color;

  const _AdviceItem({
    required this.emoji,
    required this.text,
    required this.color,
  });
}

// ── ウィジェット ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color? color;
  const _StatChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: kTextSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _UnitProgressCard extends StatelessWidget {
  final _UnitProgress unit;
  final int completedCount;
  final int total;
  final double progress;

  const _UnitProgressCard({
    required this.unit,
    required this.completedCount,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: unit.color, width: 4)),
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
              Text(unit.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: unit.color,
                      ),
                    ),
                    Text(
                      unit.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completedCount / $total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: unit.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: context.subCardBg,
                valueColor: AlwaysStoppedAnimation<Color>(unit.color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
