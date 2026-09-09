import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/progress_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/daily_review_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/shortcut_help.dart';
import 'badge_unlock_screen.dart';

// このアプリには他ユーザーのスコアを集計するバックエンド（対戦サーバー）が
// まだ無いため、この画面では「自分の記録」と「今週のチャレンジ」のみを表示する。
// 友だちとのランキング対戦機能は今後実装予定。

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyS) {
      _shareRecord(context);
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
        ('S', '記録をシェア'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // ボーナス付与などで進捗/プロフィールが変化したら再描画されるよう watch する
    ref.watch(progressProvider);
    final profile = ref.watch(profileProvider);
    final myPoints = ref.read(progressProvider.notifier).totalStarsEarned * 50;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // ヘッダー
            _buildHeader(context, myPoints, profile.nickname, profile.avatarEmoji),
            // 今週のチャレンジ + 準備中バナー
            Expanded(
              child: RefreshIndicator(
                color: kPrimaryColor,
                onRefresh: () async {
                  ref.invalidate(progressProvider);
                  ref.invalidate(profileProvider);
                  await Future.delayed(const Duration(milliseconds: 400));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _WeeklyChallengesCard()
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
                    _ComingSoonBanner()
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 300.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareRecord(BuildContext context) {
    HapticService.lightImpact();
    final profile = ref.read(profileProvider);
    final myPoints = ref.read(progressProvider.notifier).totalStarsEarned * 50;
    final text =
        '🏆 しょうがくプログラミング 記録\n'
        '${profile.avatarEmoji} ${profile.nickname}\n'
        '$myPoints pt\n'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 記録をコピーしました！'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int myPoints, String myName, String myIcon) {
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
        16,
      ),
      child: Column(
        children: [
          // タイトル
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  '🏆 ランキング',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 20),
                tooltip: '記録をシェア (S)',
                onPressed: () => _shareRecord(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 自分の記録
          _MyStatsCard(name: myName, icon: myIcon, points: myPoints)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
        ],
      ),
    );
  }
}

// ─── 準備中バナー ────────────────────────────────────────────────────────
class _ComingSoonBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          const Text('🚧', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            'みんなとのランキング対戦は準備中',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '友だちや全国のみんなと点数を競える機能を今後追加予定です。\nそれまでは「今週のチャレンジ」で自分の記録を伸ばそう！',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── 週間チャレンジカード ────────────────────────────────────────────────────
class _WeeklyChallengesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressNotifier = ref.read(progressProvider.notifier);
    final activityByDate = progressNotifier.activityByDate;
    final todayClearedCount = progressNotifier.todayClearedCount;
    final taState = ref.watch(timeAttackProvider);
    final reviewState = ref.watch(dailyReviewProvider);

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // 今週（月曜起点）のアクティブ日数
    final weekdayOffset = (today.weekday - 1) % 7; // 0=月, 6=日
    int weekActiveDays = 0;
    int weekStagesCleared = 0;
    for (int i = 0; i <= weekdayOffset; i++) {
      final d = todayNorm.subtract(Duration(days: i));
      final count = activityByDate[d] ?? 0;
      if (count > 0) weekActiveDays++;
      weekStagesCleared += count;
    }

    // 今週新たに習得したフラッシュカード枚数
    final flashState = ref.watch(flashcardProvider);
    final weekStart = todayNorm.subtract(Duration(days: weekdayOffset));
    final weekNewMastered = flashState.masteredDates.values
        .where((d) {
          final dNorm = DateTime(d.year, d.month, d.day);
          return !dNorm.isBefore(weekStart) && !dNorm.isAfter(todayNorm);
        })
        .length;

    // 今日の復習完了チェック
    final reviewDoneToday = reviewState.doneToday;

    // チャレンジ定義: (emoji, title, desc, done)
    final challenges = [
      (
        '📅',
        '今週3日学習',
        '今週$weekActiveDays/3日',
        weekActiveDays >= 3,
      ),
      (
        '🎯',
        '今週10ステージクリア',
        '今週$weekStagesCleared/10問',
        weekStagesCleared >= 10,
      ),
      (
        '📖',
        '今日の復習を完了',
        reviewDoneToday ? '完了！' : '未完了',
        reviewDoneToday,
      ),
      (
        '⚡',
        '今週タイムアタック3回',
        '今週${taState.weekPlayCount}/3回',
        taState.weekPlayCount >= 3,
      ),
      (
        '🃏',
        '今週単語帳3枚マスター',
        '今週$weekNewMastered/3枚',
        weekNewMastered >= 3,
      ),
      (
        '🔥',
        '今日5ステージクリア',
        '$todayClearedCount/5問',
        todayClearedCount >= 5,
      ),
    ];

    final doneCount = challenges.where((c) => c.$4).length;
    final pct = doneCount / challenges.length;

    // 全達成時に週次ボーナス（100pt）を一度だけ付与
    if (doneCount == challenges.length &&
        !progressNotifier.isWeeklyChallengeBonusAwardedThisWeek) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final prevStars = progressNotifier.totalStarsEarned;
        progressNotifier.awardWeeklyChallengeBonus().then((awarded) {
          if (awarded && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '今週のチャレンジ全達成！+100pt ゲット！',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFFE67E22),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
            // スターマイルストーンバッジチェック（100pt加算後）
            final newStars = progressNotifier.totalStarsEarned;
            const milestones = [
              (50,  '⭐', '星コレクター',   '累計50ポイント達成！',  '60ポイントを目指そう！'),
              (60,  '💎', 'スター収集家',  '累計60ポイント達成！',   '150ポイントを目指そう！'),
              (120, '🌠', 'パーフェクトクリア', '全ステージ3つ星達成！120ポイント！', '150ポイントを目指そう！'),
              (150, '🌟', '輝く星',        '累計150ポイント達成！',  '300ポイントを目指そう！'),
              (300, '💰', 'ポイント長者',   '累計300ポイント達成！',  '全実績を確認しよう！'),
            ];
            for (final (target, icon, name, message, goal) in milestones) {
              if (prevStars < target && newStars >= target) {
                Future.delayed(const Duration(milliseconds: 5000), () {
                  if (!context.mounted) return;
                  showBadgeUnlock(
                    context, // ignore: use_build_context_synchronously
                    icon: icon,
                    name: name,
                    message: message,
                    points: target,
                    nextGoal: goal,
                    onContinue: () {},
                  );
                });
                break;
              }
            }
          }
        });
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '今週のチャレンジ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '$doneCount / ${challenges.length} 達成',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // 進捗バー
          LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: context.shadowColor,
            valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
          // チャレンジリスト
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: challenges.asMap().entries.map((entry) {
                final i = entry.key;
                final (emoji, title, desc, done) = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: done
                        ? kPrimaryColor.withValues(alpha: 0.08)
                        : context.shadowColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: done
                          ? kPrimaryColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                                decoration: done ? TextDecoration.lineThrough : null,
                                decorationColor: context.textSecondary,
                              ),
                            ),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200 + i * 40),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? kPrimaryColor : Colors.transparent,
                          border: Border.all(
                            color: done ? kPrimaryColor : context.borderColor,
                            width: 2,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 50 * i))
                    .fadeIn(duration: 250.ms)
                    .slideX(begin: 0.05, curve: Curves.easeOut, duration: 250.ms);
              }).toList(),
            ),
          ),
          if (doneCount == challenges.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🎉 今週のチャレンジ全達成！ +100pt ボーナス！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MyStatsCard extends StatelessWidget {
  final String name;
  final String icon;
  final int points;

  const _MyStatsCard({
    required this.name,
    required this.icon,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kPrimaryColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryDark],
              ),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'あなたの記録',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD68910),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: points),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(
              '${value}pt',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
