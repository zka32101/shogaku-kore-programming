import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../utils/page_transitions.dart';
import 'editor_screen.dart';
import 'quiz_screen.dart';

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
      backgroundColor: context.isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(friendsProvider.notifier).loadFriends();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, profile, progress, coins),
              const SizedBox(height: 20),
              if (nextStage != null)
                _buildNextStageCard(context, nextStage, allCleared),
              const SizedBox(height: 20),
              _buildTodayProgress(context, profile, progress),
              const SizedBox(height: 20),
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
              child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 28)),
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
                child: Text(stage.icon, style: const TextStyle(fontSize: 28)),
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
        Text(emoji, style: const TextStyle(fontSize: 22)),
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
