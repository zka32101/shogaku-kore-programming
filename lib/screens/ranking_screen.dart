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
import '../providers/friends_provider.dart';
import '../widgets/shortcut_help.dart';
import '../utils/page_transitions.dart';
import 'badge_unlock_screen.dart';
import 'friends_list_screen.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(friendsProvider.notifier).loadFriends();
      await ref.read(friendsProvider.notifier).refreshFriendPoints();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _tabController.dispose();
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
    ref.watch(progressProvider);
    final profile = ref.watch(profileProvider);
    final myPoints = ref.read(progressProvider.notifier).totalStarsEarned * 50;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context, myPoints, profile.nickname, profile.avatarEmoji),
            Container(
              color: context.cardBg,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.indigo,
                unselectedLabelColor: context.textSecondary,
                indicatorColor: Colors.indigo,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: '🌍 グローバル'),
                  Tab(text: '📚 プログラミング'),
                  Tab(text: '👫 フレンド'),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: kPrimaryColor,
                onRefresh: () async {
                  ref.invalidate(progressProvider);
                  ref.invalidate(profileProvider);
                  await ref.read(friendsProvider.notifier).loadFriends();
                  await ref.read(friendsProvider.notifier).refreshFriendPoints();
                  await Future.delayed(const Duration(milliseconds: 400));
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _GlobalRankingTab(
                      myPoints: myPoints,
                      myName: profile.nickname,
                      myIcon: profile.avatarEmoji,
                    ),
                    _SubjectRankingTab(
                      myPoints: myPoints,
                      myName: profile.nickname,
                      myIcon: profile.avatarEmoji,
                    ),
                    _FriendRankingTab(
                      myPoints: myPoints,
                      myName: profile.nickname,
                      myIcon: profile.avatarEmoji,
                    ),
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
          _MyStatsCard(name: myName, icon: myIcon, points: myPoints)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
        ],
      ),
    );
  }
}

// ─── グローバルランキングタブ
class _GlobalRankingTab extends StatelessWidget {
  final int myPoints;
  final String myName;
  final String myIcon;

  const _GlobalRankingTab({
    required this.myPoints,
    required this.myName,
    required this.myIcon,
  });

  @override
  Widget build(BuildContext context) {
    final demoEntries = _generateDemoRanking();

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildMyRankCard(context, 42),
        const SizedBox(height: 16),
        _buildRankingList(context, demoEntries),
      ],
    );
  }

  Widget _buildMyRankCard(BuildContext context, int rank) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.indigo, Color(0xFF3F51B5)],
              ),
            ),
            child: Center(
              child: Text(myIcon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'あなたの順位',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  myName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(BuildContext context, List<_RankEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: context.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Text(
              '🌍 全国ランキング TOP 100',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: entries.asMap().entries.map((e) {
                final rank = e.key + 1;
                final entry = e.value;
                return _RankingEntryCard(
                  rank: rank,
                  entry: entry,
                  accentColor: Colors.indigo,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<_RankEntry> _generateDemoRanking() {
    return [
      _RankEntry('太郎', 15000),
      _RankEntry('花子', 14500),
      _RankEntry('次郎', 14200),
      _RankEntry('由美', 13800),
      _RankEntry('健太', 13500),
      _RankEntry('美咲', 13200),
      _RankEntry('翔太', 12900),
      _RankEntry('優子', 12600),
      _RankEntry('拓也', 12300),
      _RankEntry('美優', 12000),
    ];
  }
}

// ─── 教科別ランキングタブ
class _SubjectRankingTab extends StatelessWidget {
  final int myPoints;
  final String myName;
  final String myIcon;

  const _SubjectRankingTab({
    required this.myPoints,
    required this.myName,
    required this.myIcon,
  });

  @override
  Widget build(BuildContext context) {
    final demoEntries = _generateDemoRanking();

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildMyRankCard(context, 38),
        const SizedBox(height: 16),
        _buildRankingList(context, demoEntries),
      ],
    );
  }

  Widget _buildMyRankCard(BuildContext context, int rank) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.indigo, Color(0xFF3F51B5)],
              ),
            ),
            child: Center(
              child: Text(myIcon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'プログラミングでの順位',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  myName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(BuildContext context, List<_RankEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: context.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Text(
              '📚 プログラミング TOP 100',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: entries.asMap().entries.map((e) {
                final rank = e.key + 1;
                final entry = e.value;
                return _RankingEntryCard(
                  rank: rank,
                  entry: entry,
                  accentColor: Colors.indigo,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<_RankEntry> _generateDemoRanking() {
    return [
      _RankEntry('太郎', 8500),
      _RankEntry('花子', 8200),
      _RankEntry('次郎', 7900),
      _RankEntry('由美', 7600),
      _RankEntry('健太', 7300),
      _RankEntry('美咲', 7000),
      _RankEntry('翔太', 6700),
      _RankEntry('優子', 6400),
      _RankEntry('拓也', 6100),
      _RankEntry('美優', 5800),
    ];
  }
}

// ─── フレンドランキングタブ
class _FriendRankingTab extends ConsumerWidget {
  final int myPoints;
  final String myName;
  final String myIcon;

  const _FriendRankingTab({
    required this.myPoints,
    required this.myName,
    required this.myIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendRanking = ref.watch(friendRankingProvider);

    final entries = <(String name, String icon, int points, bool isMe)>[
      (myName, myIcon, myPoints, true),
      for (final f in friendRanking) (f.nickname, f.avatarEmoji, f.points, false),
    ]..sort((a, b) => b.$3.compareTo(a.$3));

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _WeeklyChallengesCard()
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.08, curve: Curves.easeOut, duration: 350.ms),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Text('👫', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'フレンドランキング',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticService.lightImpact();
                        Navigator.of(context)
                            .push(smoothPageRoute(const FriendsListScreen()));
                      },
                      icon: const Icon(Icons.person_add_alt_1,
                          size: 14, color: Colors.white),
                      label: const Text(
                        'フレンド管理',
                        style:
                            TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              if (friendRanking.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'フレンドを追加すると、ここでポイントを競い合えるよ！',
                    style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: entries.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final (name, icon, points, isMe) = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF3498DB).withValues(alpha: 0.1)
                              : context.shadowColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: isMe
                              ? Border.all(
                                  color: const Color(0xFF3498DB)
                                      .withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                            Text(icon,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isMe ? '$name（あなた）' : name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${points}pt',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3498DB),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── ランキング エントリー
class _RankEntry {
  final String name;
  final int score;

  _RankEntry(this.name, this.score);
}

class _RankingEntryCard extends StatelessWidget {
  final int rank;
  final _RankEntry entry;
  final Color accentColor;

  const _RankingEntryCard({
    required this.rank,
    required this.entry,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.shadowColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.score} pt',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (rank <= 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rank == 1
                    ? '🥇'
                    : rank == 2
                        ? '🥈'
                        : '🥉',
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 週間チャレンジカード
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

    final weekdayOffset = (today.weekday - 1) % 7;
    int weekActiveDays = 0;
    int weekStagesCleared = 0;
    for (int i = 0; i <= weekdayOffset; i++) {
      final d = todayNorm.subtract(Duration(days: i));
      final count = activityByDate[d] ?? 0;
      if (count > 0) weekActiveDays++;
      weekStagesCleared += count;
    }

    final flashState = ref.watch(flashcardProvider);
    final weekStart = todayNorm.subtract(Duration(days: weekdayOffset));
    final weekNewMastered = flashState.masteredDates.values
        .where((d) {
          final dNorm = DateTime(d.year, d.month, d.day);
          return !dNorm.isBefore(weekStart) && !dNorm.isAfter(todayNorm);
        })
        .length;

    final reviewDoneToday = reviewState.doneToday;

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
          LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: context.shadowColor,
            valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
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
