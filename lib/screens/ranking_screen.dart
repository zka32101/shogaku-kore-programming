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

// ランキングデータモデル
class RankEntry {
  final int rank;
  final String name;
  final int points;
  final String icon;
  final bool isMe;

  const RankEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.icon,
    this.isMe = false,
  });
}

// ランキングタブ
enum RankingPeriod { weekly, monthly, allTime }

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  RankingPeriod _period = RankingPeriod.weekly;
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
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      HapticService.selectionClick();
      setState(() => _period = RankingPeriod.weekly);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      HapticService.selectionClick();
      setState(() => _period = RankingPeriod.monthly);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      HapticService.selectionClick();
      setState(() => _period = RankingPeriod.allTime);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      HapticService.selectionClick();
      setState(() {
        if (_period == RankingPeriod.monthly) {
          _period = RankingPeriod.weekly;
        } else if (_period == RankingPeriod.allTime) {
          _period = RankingPeriod.monthly;
        }
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      HapticService.selectionClick();
      setState(() {
        if (_period == RankingPeriod.weekly) {
          _period = RankingPeriod.monthly;
        } else if (_period == RankingPeriod.monthly) {
          _period = RankingPeriod.allTime;
        }
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      final rankings = _buildRankings();
      final myEntry = rankings.firstWhere((e) => e.isMe);
      _shareRanking(context, myEntry);
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
        ('1', '週間ランキング'),
        ('2', '月間ランキング'),
        ('3', '全期間ランキング'),
        ('← / →', '前/次の期間'),
        ('S', '順位をシェア'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ダミーランキングデータ
  List<RankEntry> _buildRankings() {
    final myPoints = ref.read(progressProvider.notifier).totalStarsEarned * 50;
    final profile = ref.read(profileProvider);
    final base = _period == RankingPeriod.weekly
        ? [
            const RankEntry(rank: 1, name: 'コード探偵まさき', points: 4850, icon: '🏆'),
            const RankEntry(rank: 2, name: 'プログラマーゆき', points: 4200, icon: '🥈'),
            const RankEntry(rank: 3, name: 'Python名人りく', points: 3780, icon: '🥉'),
            const RankEntry(rank: 4, name: 'ブロック達人はな', points: 3100, icon: '🎯'),
            const RankEntry(rank: 5, name: 'コードマスターそら', points: 2850, icon: '⭐'),
            const RankEntry(rank: 6, name: 'アルゴリズムけん', points: 2400, icon: '💡'),
            const RankEntry(rank: 7, name: 'デバッガーあかり', points: 2100, icon: '🔧'),
          ]
        : _period == RankingPeriod.monthly
            ? [
                const RankEntry(rank: 1, name: 'プログラマーゆき', points: 18500, icon: '🏆'),
                const RankEntry(rank: 2, name: 'コード探偵まさき', points: 17200, icon: '🥈'),
                const RankEntry(rank: 3, name: 'アルゴリズムけん', points: 15800, icon: '🥉'),
                const RankEntry(rank: 4, name: 'Python名人りく', points: 14200, icon: '🎯'),
                const RankEntry(rank: 5, name: 'ブロック達人はな', points: 12900, icon: '⭐'),
              ]
            : [
                const RankEntry(rank: 1, name: 'Python名人りく', points: 95000, icon: '🏆'),
                const RankEntry(rank: 2, name: 'コード探偵まさき', points: 88500, icon: '🥈'),
                const RankEntry(rank: 3, name: 'プログラマーゆき', points: 82100, icon: '🥉'),
                const RankEntry(rank: 4, name: 'ブロック達人はな', points: 76400, icon: '🎯'),
                const RankEntry(rank: 5, name: 'デバッガーあかり', points: 68200, icon: '⭐'),
                const RankEntry(rank: 6, name: 'アルゴリズムけん', points: 61500, icon: '💡'),
                const RankEntry(rank: 7, name: 'コードマスターそら', points: 55000, icon: '🔧'),
                const RankEntry(rank: 8, name: 'バグハンターみお', points: 48300, icon: '🐛'),
              ];

    // 自分のランクを挿入
    final myRank = _calculateMyRank(myPoints, base);
    return [
      ...base,
      RankEntry(
        rank: myRank,
        name: profile.nickname,
        points: myPoints,
        icon: profile.avatarEmoji,
        isMe: true,
      ),
    ]..sort((a, b) => a.rank.compareTo(b.rank));
  }

  int _calculateMyRank(int myPoints, List<RankEntry> entries) {
    int rank = entries.length + 1;
    for (final e in entries) {
      if (myPoints > e.points) {
        rank = e.rank;
        break;
      }
    }
    return rank;
  }

  @override
  Widget build(BuildContext context) {
    final rankings = _buildRankings();
    final myEntry = rankings.firstWhere((e) => e.isMe);
    final showChallenges = _period == RankingPeriod.weekly;

    // Build flat list with gap separators (null = separator)
    final List<RankEntry?> flatItems = [];
    for (int i = 0; i < rankings.length; i++) {
      if (i > 0) {
        final prev = rankings[i - 1];
        final curr = rankings[i];
        if (curr.rank > prev.rank + 1) flatItems.add(null);
      }
      flatItems.add(rankings[i]);
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // ヘッダー
            _buildHeader(context, myEntry, rankings),
            // ランキングリスト（＋週間チャレンジ）
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: flatItems.length + (showChallenges ? 1 : 0),
                itemBuilder: (context, index) {
                  // 週間チャレンジカード（先頭）
                  if (showChallenges && index == 0) {
                    return _WeeklyChallengesCard()
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms);
                  }
                  final actualIndex = showChallenges ? index - 1 : index;
                  final item = flatItems[actualIndex];
                  // ギャップセパレーター
                  if (item == null) {
                    return _RankGapSeparator()
                        .animate(delay: Duration(milliseconds: 60 * actualIndex))
                        .fadeIn(duration: 200.ms);
                  }
                  final isTop3 = item.rank <= 3;
                  return _RankItem(entry: item)
                      .animate(delay: Duration(milliseconds: 60 * actualIndex))
                      .fadeIn(duration: 300.ms)
                      .then()
                      .custom(
                        duration: isTop3 ? 400.ms : 300.ms,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(isTop3 ? 0 : (1 - value) * 24, 0),
                          child: isTop3
                              ? Transform.scale(
                                  scale: 0.85 + value * 0.15,
                                  child: child,
                                )
                              : child,
                        ),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareRanking(BuildContext context, RankEntry myEntry) {
    HapticService.lightImpact();
    final periodLabel = switch (_period) {
      RankingPeriod.weekly  => '今週',
      RankingPeriod.monthly => '今月',
      RankingPeriod.allTime => '全期間',
    };
    final text =
        '🏆 しょうがくプログラミング ランキング\n'
        '【$periodLabel】${myEntry.rank}位\n'
        '${myEntry.icon} ${myEntry.name}\n'
        '${myEntry.points} pt\n'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 ランキングをコピーしました！'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RankEntry myEntry, List<RankEntry> rankings) {
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
                tooltip: '順位をシェア (S)',
                onPressed: () => _shareRanking(context, myEntry),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // タブボタン
          Row(
            children: [
              _TabButton(
                label: '今週',
                isActive: _period == RankingPeriod.weekly,
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _period = RankingPeriod.weekly);
                },
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: '今月',
                isActive: _period == RankingPeriod.monthly,
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _period = RankingPeriod.monthly);
                },
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: '全期間',
                isActive: _period == RankingPeriod.allTime,
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _period = RankingPeriod.allTime);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 自分のランク
          _MyRankCard(entry: myEntry)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 8),
          // 次のランクまでの距離
          _buildNextRankBanner(rankings, myEntry)
              .animate(delay: 200.ms)
              .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildNextRankBanner(List<RankEntry> rankings, RankEntry myEntry) {
    if (myEntry.rank <= 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          '🏆 あなたは1位です！おめでとう！',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    // 1つ上のランクのエントリーを探す
    final above = rankings
        .where((e) => !e.isMe && e.rank < myEntry.rank)
        .toList()
      ..sort((a, b) => b.rank.compareTo(a.rank));
    if (above.isEmpty) return const SizedBox.shrink();
    final target = above.first;
    final gap = target.points - myEntry.points;
    if (gap <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🚀', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            'あと ${gap}pt で ${target.rank}位！',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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

// ─── ランクギャップセパレーター ────────────────────────────────────────────────
class _RankGapSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: kTextSecondary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white
              : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? kPrimaryColor : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  final RankEntry entry;

  const _MyRankCard({required this.entry});

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
          // ランクバッジ
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kPrimaryDark],
              ),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(entry.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'あなたの順位',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD68910),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${entry.rank}位  ${entry.name}',
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
            tween: IntTween(begin: 0, end: entry.points),
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

class _RankItem extends StatelessWidget {
  final RankEntry entry;

  const _RankItem({required this.entry});

  Color get _medalBg1 {
    switch (entry.rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return kPrimaryColor;
    }
  }

  Color get _medalBg2 {
    switch (entry.rank) {
      case 1: return const Color(0xFFFFC700);
      case 2: return const Color(0xFFA9A9A9);
      case 3: return const Color(0xFFB87333);
      default: return kPrimaryDark;
    }
  }

  Color? get _borderColor {
    switch (entry.rank) {
      case 1: return const Color(0xFFDAA520);
      case 2: return const Color(0xFF808080);
      case 3: return const Color(0xFF8B4513);
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: entry.isMe
            ? kPrimaryColor.withValues(alpha: 0.06)
            : context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: entry.isMe
            ? Border.all(color: kPrimaryColor, width: 2)
            : _borderColor != null
                ? Border.all(color: _borderColor!, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: entry.isMe
                ? kPrimaryColor.withValues(alpha: 0.15)
                : isTop3
                    ? _medalBg1.withValues(alpha: 0.2)
                    : context.shadowColor,
            blurRadius: entry.isMe ? 10 : isTop3 ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ランクバッジ
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_medalBg1, _medalBg2],
                ),
              ),
              child: Center(
                child: Text(
                  entry.rank <= 3
                      ? ['🥇', '🥈', '🥉'][entry.rank - 1]
                      : '${entry.rank}',
                  style: TextStyle(
                    fontSize: entry.rank <= 3 ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // アイコン
            Text(entry.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            // 名前
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.isMe)
                    const Text(
                      'あなた',
                      style: TextStyle(
                        fontSize: 9,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // ポイント（入場アニメーション）
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: entry.points),
              duration: const Duration(milliseconds: 900),
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
      ),
    );
  }
}
