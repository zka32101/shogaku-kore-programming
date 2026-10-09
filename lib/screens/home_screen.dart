import '../features/shop/decor/decor_scope.dart';
import '../features/shop/title/title_plate.dart';
import '../features/shop/title/title_provider.dart';
import '../widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/character_model.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_review_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/my_character_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/character_image.dart';
import 'character_screen.dart';
import 'ai_programming_screen.dart';
import 'daily_review_screen.dart';
import 'editor_screen.dart';
import 'flashcard_screen.dart';
import 'free_create_screen.dart';
import 'friends_list_screen.dart';
import 'gallery_screen.dart';
import 'quiz_screen.dart';
import 'ranking_screen.dart';
import 'robot_game_screen.dart';
import 'shop_screen.dart';
import 'stage_share_screen.dart';
import 'time_attack_screen.dart';
import 'wrong_answers_list_screen.dart';
import 'package:shogaku_kore_programming/widgets/ukalab_emoji.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
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

  void _openStage(Stage stage) {
    HapticService.lightImpact();
    SoundService().playTap();
    final route = stage.type == 'visual'
        ? EditorScreen(challenge: stage)
        : QuizScreen(challenge: stage);
    Navigator.of(context).push(smoothPageRoute(route));
  }

  void _push(Widget screen) {
    HapticService.lightImpact();
    SoundService().playTap();
    Navigator.of(context).push(smoothPageRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final progressMap = ref.watch(progressProvider);
    final progress = ref.read(progressProvider.notifier);
    final coins = ref.watch(coinProvider).balance;
    final allStages = ref.watch(allChallengesProvider);

    Stage? nextStage;
    var allCleared = false;
    if (allStages.isNotEmpty) {
      allCleared =
          allStages.every((s) => progressMap[s.id]?.isCompleted ?? false);
      nextStage = allStages.firstWhere(
        (s) => !(progressMap[s.id]?.isCompleted ?? false),
        orElse: () => allStages.first,
      );
    }

    return Scaffold(
      backgroundColor: DecorScope.pageBg(context, context.isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(friendsProvider.notifier).loadFriends();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, profile, progress, coins),
              const SizedBox(height: 16),
              if (nextStage != null)
                _buildNextStageCard(context, nextStage, allCleared),
              const SizedBox(height: 16),
              _buildTodayProgress(context, profile, progress),
              const SizedBox(height: 16),
              _buildMyCharacterCard(context),
              const SizedBox(height: 16),
              _buildDailyReviewCard(context),
              const SizedBox(height: 16),
              _buildAiProgrammingBanner(context),
              const SizedBox(height: 16),
              _buildQuickAccess(context),
              const SizedBox(height: 16),
              _buildStatsRow(context, progress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProfileState profile,
    ProgressNotifier progress,
    int coins,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: ProfileAvatar(profile.avatarEmoji, size: 44),
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'レベル ${progress.currentLevel} ・ 🔥 ${progress.streakDays}日連続',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (ref.watch(activeTitleProvider) case final title?) ...[
                  const SizedBox(height: 6),
                  TitlePlate(name: title.name),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextStageCard(BuildContext context, Stage stage, bool allCleared) {
    return GestureDetector(
      onTap: () => _openStage(stage),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: UkalabEmoji(stage.icon, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allCleared ? '全ステージクリア済み！' : '次のステージ',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stage.level} ・ ${stage.type == 'visual' ? 'ブロック' : 'クイズ'}',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgress(
    BuildContext context,
    ProfileState profile,
    ProgressNotifier progress,
  ) {
    final cleared = progress.todayClearedCount;
    final goal = profile.dailyGoal;
    final ratio = goal > 0 ? (cleared / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日の目標',
                style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              Text(
                '$cleared / $goal ステージ',
                style: const TextStyle(fontSize: 12, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context, {Color? borderColor}) {
    return BoxDecoration(
      color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: borderColor == null
          ? null
          : Border.all(color: borderColor, width: 1.5),
    );
  }

  /// マイキャラ（成長するキャラ）のカード
  Widget _buildMyCharacterCard(BuildContext context) {
    final my = ref.watch(myCharacterProvider);
    final def = my.definition;
    final next = my.nextThreshold;
    return GestureDetector(
      onTap: () => _push(const CharacterScreen()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            CharacterImage(definition: def, stage: my.stage, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${def.name}（${kStageNames[my.stage]}）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: my.progressToNext,
                      minHeight: 8,
                      backgroundColor: kPrimaryColor.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    next == null
                        ? '最強の姿になったよ！'
                        : '進化まで あと ${next - my.totalXp} XP',
                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 今日の復習（1日1回）
  Widget _buildDailyReviewCard(BuildContext context) {
    final review = ref.watch(dailyReviewProvider);
    final done = review.doneToday;
    return GestureDetector(
      onTap: done ? null : () => _push(const DailyReviewScreen()),
      child: Opacity(
        opacity: done ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(
            context,
            borderColor: kPrimaryColor.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? '今日の復習は完了！' : '今日の復習',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.reviewStreak > 0
                          ? '🔥 ${review.reviewStreak}日連続'
                          : '1日1回、まちがえた問題をおさらい',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              if (!done) const Icon(Icons.chevron_right, color: kPrimaryColor),
            ],
          ),
        ),
      ),
    );
  }

  /// AIとプログラミング（解説・試す・注意点・悪い例）への入口
  Widget _buildAiProgrammingBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _push(const AiProgrammingScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF8E7BFF)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AIとプログラミング',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'AIのじょうずな使い方と、気をつけること',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// 主要機能への入口（2列グリッド）
  Widget _buildQuickAccess(BuildContext context) {
    final items = <(String, String, Widget)>[
      ('🤖', 'ロボットゲーム', const RobotGameScreen()),
      ('🤝', 'ステージ交換', const StageShareScreen()),
      ('👥', 'ともだち', const FriendsListScreen()),
      ('🎨', '自由に作る', const FreeCreateScreen()),
      ('⏱️', 'タイムアタック', const TimeAttackScreen()),
      ('🃏', '単語帳', const FlashcardScreen()),
      ('🔁', 'にがて問題', const WrongAnswersListScreen()),
      ('🛒', 'ショップ', const ShopScreen()),
      ('🏅', 'ランキング', const RankingScreen()),
      ('🖼️', 'ギャラリー', const GalleryScreen()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: DecorScope.chipBg(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'いろいろあそぶ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final (emoji, label, screen) in items)
              GestureDetector(
                onTap: () => _push(screen),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: _cardDecoration(context),
                  child: Row(
                    children: [
                      UkalabEmoji(emoji, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, ProgressNotifier progress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(context, '📚', '${progress.completedCount}', 'クリア数'),
          _statItem(context, '⭐', '${progress.totalStarsEarned}', '獲得スター'),
          _statItem(context, '🏆', '${progress.perfectStagesCount}', 'パーフェクト'),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        UkalabEmoji(emoji, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
      ],
    );
  }
}
