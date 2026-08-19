import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/challenge.dart';
import '../providers/challenges_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/wrong_answers_provider.dart';
import 'quiz_screen.dart';
import 'editor_screen.dart';
import 'paywall_screen.dart';
import 'flashcard_screen.dart';
import 'badge_unlock_screen.dart';
import '../widgets/shortcut_help.dart';

class StageListScreen extends ConsumerStatefulWidget {
  final String? initialLevel;
  /// true にすると全タブをお気に入りフィルターで開く
  final bool openFavorites;

  const StageListScreen({super.key, this.initialLevel, this.openFavorites = false});

  @override
  ConsumerState<StageListScreen> createState() => _StageListScreenState();
}

class _StageListScreenState extends ConsumerState<StageListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _getInitialIndex(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int _getInitialIndex() {
    switch (widget.initialLevel) {
      case StageLevel.intermediate:
        return 1;
      case StageLevel.advanced:
        return 2;
      default:
        return 0;
    }
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
      if (_tabController.index > 0) {
        _tabController.animateTo(_tabController.index - 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      HapticService.selectionClick();
      if (_tabController.index < 2) {
        _tabController.animateTo(_tabController.index + 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      HapticService.lightImpact();
      SoundService().playTap();
      _openRandomChallenge(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FlashcardScreen()),
      );
      return KeyEventResult.handled;
    }
    // / (スラッシュ) → 検索を開く（? = Shift+/ は除外）
    if (key == LogicalKeyboardKey.slash &&
        !HardwareKeyboard.instance.isShiftPressed) {
      HapticService.lightImpact();
      final allChallenges = ref.read(allChallengesProvider);
      final progressMap = ref.read(progressProvider);
      showSearch(
        context: context,
        delegate: _StageSearchDelegate(
          allChallenges: allChallenges,
          progressMap: progressMap,
          favoriteIds: ref.read(favoritesProvider).favoriteIds,
          wrongAnswerStageIds: _computeWrongStageIds(allChallenges),
        ),
      );
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('1 / 2 / 3', 'タブ切り替え（初級/中級/上級）'),
        ('← / →', '前/次のタブ'),
        ('R', 'ランダムチャレンジ'),
        ('F', 'フラッシュカード'),
        ('/', '検索'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // グラデーションヘッダー + タブバー
            _PathHeader(tabController: _tabController),
            // パスビュー
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _StagePathTab(level: StageLevel.beginner, openFavorites: widget.openFavorites),
                  _StagePathTab(level: StageLevel.intermediate, openFavorites: widget.openFavorites),
                  _StagePathTab(level: StageLevel.advanced, openFavorites: widget.openFavorites),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            HapticService.lightImpact();
            SoundService().playTap();
            _openRandomChallenge(context);
          },
          backgroundColor: kPrimaryColor,
          icon: const Text('🎲', style: TextStyle(fontSize: 18)),
          label: const Text(
            'ランダム',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),   // closes Scaffold (child of Focus)
    );    // closes Focus return
  }

  void _openRandomChallenge(BuildContext context) {
    HapticService.mediumImpact();
    final allChallenges = ref.read(allChallengesProvider);
    final progressMap = ref.read(progressProvider);

    // 現在開いているタブ（初級/中級/上級）のレベルに絞り込む
    const levels = [
      StageLevel.beginner,
      StageLevel.intermediate,
      StageLevel.advanced,
    ];
    final currentLevel = levels[_tabController.index];
    final levelChallenges =
        allChallenges.where((c) => c.level == currentLevel).toList();

    // 未完了の無料チャレンジから選ぶ
    final pool = levelChallenges
        .where((c) => c.isFree && !(progressMap[c.id]?.isCompleted ?? false))
        .toList();

    // 未完了がなければ現在レベルの全無料から選ぶ
    final source = pool.isNotEmpty
        ? pool
        : levelChallenges.where((c) => c.isFree).toList();

    if (source.isEmpty) return;
    final pick = source[math.Random().nextInt(source.length)];
    final stars = progressMap[pick.id]?.starsEarned ?? 0;
    final isCompleted = progressMap[pick.id]?.isCompleted ?? false;
    final completedAt = progressMap[pick.id]?.completedAt;

    _showRandomSheet(context, pick, stars, isCompleted, completedAt);
  }

  /// 苦手問題を持つステージIDのセットを返す（検索デリゲートへの受け渡し用）
  Set<String> _computeWrongStageIds(List<Challenge> challenges) {
    final wrongTexts =
        ref.read(wrongAnswersProvider).answers.map((a) => a.questionText).toSet();
    return challenges
        .where((c) => c.questions.any((q) => wrongTexts.contains(q.text)))
        .map((c) => c.id)
        .toSet();
  }

  void _showRandomSheet(
    BuildContext context,
    Challenge challenge,
    int starsEarned,
    bool isCompleted,
    DateTime? completedAt,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => _ChallengeInfoSheet(
        challenge: challenge,
        starsEarned: starsEarned,
        isCompleted: isCompleted,
        completedAt: completedAt,
        onStart: () {
          Navigator.pop(ctx);
          if (challenge.type == ChallengeType.quiz) {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => QuizScreen(challenge: challenge)),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => EditorScreen(challenge: challenge)),
            );
          }
        },
      ),
    );
  }

}

// ─── ヘッダー ──────────────────────────────────────────────────────────────

class _PathHeader extends ConsumerWidget {
  final TabController tabController;
  const _PathHeader({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressNotifier = ref.read(progressProvider.notifier);
    final progressMap = ref.watch(progressProvider);
    final allChallenges = ref.watch(allChallengesProvider);
    final completedCount = progressNotifier.completedCount;
    final totalStars = progressNotifier.totalStarsEarned;
    final level = progressNotifier.currentLevel;

    int unitDone(String lvl) => allChallenges
        .where((c) => c.level == lvl && (progressMap[c.id]?.isCompleted ?? false))
        .length;
    int unitTotal(String lvl) =>
        allChallenges.where((c) => c.level == lvl).length;

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
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 戻るボタン (BottomNavから開いた場合は不要なので条件付き)
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'ステージ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // 検索ボタン
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  final allChallenges = ref.read(allChallengesProvider);
                  final progressMap = ref.read(progressProvider);
                  showSearch(
                    context: context,
                    delegate: _StageSearchDelegate(
                      allChallenges: allChallenges,
                      progressMap: progressMap,
                      favoriteIds: ref.read(favoritesProvider).favoriteIds,
                    ),
                  );
                },
                tooltip: 'ステージを検索',
              ),
              // フラッシュカードボタン
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FlashcardScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text('🃏', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 4),
                      Text(
                        '単語帳',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '✅ $completedCount / ${AppConstants.totalStages}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '⭐ ${totalStars}pt  Lv.$level',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: tabController,
            tabs: [
              Tab(text: '🧩 初級 ${unitDone(StageLevel.beginner)}/${unitTotal(StageLevel.beginner)}'),
              Tab(text: '🐍 中級 ${unitDone(StageLevel.intermediate)}/${unitTotal(StageLevel.intermediate)}'),
              Tab(text: '🚀 上級 ${unitDone(StageLevel.advanced)}/${unitTotal(StageLevel.advanced)}'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
          ),
        ],
      ),
    );
  }
}

// ─── ステージパスタブ ─────────────────────────────────────────────────────────

enum _CompletionFilter { all, incomplete, completed, notPerfect, favorites, wrongAnswers }

class _StagePathTab extends ConsumerStatefulWidget {
  final String level;
  final bool openFavorites;

  const _StagePathTab({required this.level, this.openFavorites = false});

  @override
  ConsumerState<_StagePathTab> createState() => _StagePathTabState();
}

class _StagePathTabState extends ConsumerState<_StagePathTab> {
  _CompletionFilter _filter = _CompletionFilter.all;

  @override
  void initState() {
    super.initState();
    if (widget.openFavorites) {
      _filter = _CompletionFilter.favorites;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Challenge> allChallenges;
    switch (widget.level) {
      case StageLevel.beginner:
        allChallenges = ref.watch(beginnerChallengesProvider);
        break;
      case StageLevel.intermediate:
        allChallenges = ref.watch(intermediateChallengesProvider);
        break;
      default:
        allChallenges = ref.watch(advancedChallengesProvider);
    }

    final progressMap = ref.watch(progressProvider);
    final favorites = ref.watch(favoritesProvider);
    // wrongAnswersProvider は苦手問題フィルター用のみ必要。
    // 苦手テキストセットは answers 変化時のみ再計算（select で最適化）
    final wrongAnswers = ref.watch(
      wrongAnswersProvider.select((s) => s.answers),
    );

    // 苦手問題を持つステージIDのセットを構築（answers 変化時のみ再計算）
    final wrongTexts = wrongAnswers.map((a) => a.questionText).toSet();
    final wrongStageIds = wrongTexts.isEmpty
        ? const <String>{}
        : allChallenges
            .where((c) => c.questions.any((q) => wrongTexts.contains(q.text)))
            .map((c) => c.id)
            .toSet();

    // フィルター適用
    final challenges = switch (_filter) {
      _CompletionFilter.incomplete =>
        allChallenges.where((c) => !(progressMap[c.id]?.isCompleted ?? false)).toList(),
      _CompletionFilter.completed =>
        allChallenges.where((c) => progressMap[c.id]?.isCompleted ?? false).toList(),
      _CompletionFilter.notPerfect =>
        allChallenges.where((c) => (progressMap[c.id]?.starsEarned ?? 0) < 3).toList(),
      _CompletionFilter.favorites =>
        allChallenges.where((c) => favorites.isFavorite(c.id)).toList(),
      _CompletionFilter.wrongAnswers =>
        allChallenges.where((c) => wrongStageIds.contains(c.id)).toList(),
      _CompletionFilter.all => allChallenges,
    };

    // 3つ星未取得のステージ数
    final notPerfectCount = allChallenges
        .where((c) => (progressMap[c.id]?.starsEarned ?? 0) < 3)
        .length;

    // お気に入りステージ数（このユニット内）
    final favCount = allChallenges
        .where((c) => favorites.isFavorite(c.id))
        .length;

    // 現在のステージ（最初の未完了かつ未ロックのステージ）
    final currentIndex = allChallenges.indexWhere(
      (c) => !(progressMap[c.id]?.isCompleted ?? false) && c.isFree,
    );

    final completedInLevel = allChallenges.where((c) => progressMap[c.id]?.isCompleted ?? false).length;
    final totalInLevel = allChallenges.length;

    return Column(
      children: [
        // フィルターチップ行
        Container(
          color: context.cardBg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: '全て ($totalInLevel)',
                      isSelected: _filter == _CompletionFilter.all,
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() => _filter = _CompletionFilter.all);
                      },
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '未完了 (${totalInLevel - completedInLevel})',
                      isSelected: _filter == _CompletionFilter.incomplete,
                      color: const Color(0xFFE67E22),
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() => _filter = _CompletionFilter.incomplete);
                      },
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'クリア ($completedInLevel)',
                      isSelected: _filter == _CompletionFilter.completed,
                      color: const Color(0xFF27AE60),
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() => _filter = _CompletionFilter.completed);
                      },
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '★3未満 ($notPerfectCount)',
                      isSelected: _filter == _CompletionFilter.notPerfect,
                      color: const Color(0xFFF39C12),
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() => _filter = _CompletionFilter.notPerfect);
                      },
                    ),
                    if (favCount > 0) ...[
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '⭐ お気に入り ($favCount)',
                        isSelected: _filter == _CompletionFilter.favorites,
                        color: Colors.pink.shade400,
                        onTap: () {
                          HapticService.selectionClick();
                          setState(() => _filter = _CompletionFilter.favorites);
                        },
                      ),
                    ],
                    if (wrongStageIds.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '🔥 苦手 (${wrongStageIds.length})',
                        isSelected: _filter == _CompletionFilter.wrongAnswers,
                        color: const Color(0xFFFF6B35),
                        onTap: () {
                          HapticService.selectionClick();
                          setState(() => _filter = _CompletionFilter.wrongAnswers);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              // 右端フェード：横スクロールできることを示すヒント
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          context.cardBg.withValues(alpha: 0),
                          context.cardBg,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _LevelProgressBanner(
          completedInLevel: completedInLevel,
          totalInLevel: totalInLevel,
          level: widget.level,
        ),
        _LevelGoalCard(level: widget.level),
        if (challenges.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    switch (_filter) {
                      _CompletionFilter.incomplete => '🎉',
                      _CompletionFilter.notPerfect => '🌟',
                      _CompletionFilter.favorites => '⭐',
                      _CompletionFilter.wrongAnswers => '🔥',
                      _ => '📖',
                    },
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    switch (_filter) {
                      _CompletionFilter.incomplete => 'このユニットは全てクリア済み！',
                      _CompletionFilter.notPerfect => '全ステージ3つ星達成！完璧です！🌟',
                      _CompletionFilter.favorites => 'このユニットにお気に入りがありません',
                      _CompletionFilter.wrongAnswers => 'このユニットに苦手問題はありません！',
                      _ => 'まだクリアしたステージがありません',
                    },
                    style: const TextStyle(fontSize: 14, color: kTextSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: _StagePathView(
              challenges: challenges,
              progressMap: progressMap,
              currentIndex: _filter == _CompletionFilter.all ? currentIndex : -1,
              level: widget.level,
              favoriteIds: favorites.favoriteIds,
              wrongAnswerStageIds: wrongStageIds,
              onFavoriteToggle: (id) async {
                final (wasAdded, newCount) = await ref.read(favoritesProvider.notifier).toggle(id);
                if (!mounted) return;
                checkFavoriteMilestoneBadge(context, wasAdded: wasAdded, newCount: newCount); // ignore: use_build_context_synchronously
              },
              onStageTap: (ctx, challenge) {
                final stars = progressMap[challenge.id]?.starsEarned ?? 0;
                final isCompleted = progressMap[challenge.id]?.isCompleted ?? false;
                final completedAt = progressMap[challenge.id]?.completedAt;
                _openChallenge(ctx, challenge, stars, isCompleted, completedAt);
              },
            ),
          ),
      ],
    );
  }

  void _openChallenge(
    BuildContext context,
    Challenge challenge,
    int starsEarned,
    bool isCompleted,
    DateTime? completedAt,
  ) {
    HapticService.lightImpact();
    SoundService().playTap();
    if (!challenge.isFree) {
      _showPremiumModal(context, challenge);
      return;
    }
    _showChallengeInfoSheet(context, challenge, starsEarned, isCompleted, completedAt);
  }

  void _showChallengeInfoSheet(
    BuildContext context,
    Challenge challenge,
    int starsEarned,
    bool isCompleted,
    DateTime? completedAt,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => _ChallengeInfoSheet(
        challenge: challenge,
        starsEarned: starsEarned,
        isCompleted: isCompleted,
        completedAt: completedAt,
        onStart: () {
          Navigator.pop(ctx);
          if (challenge.type == ChallengeType.quiz) {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => QuizScreen(challenge: challenge)),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => EditorScreen(challenge: challenge)),
            );
          }
        },
      ),
    );
  }

  void _showPremiumModal(BuildContext context, Challenge challenge) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => _PremiumGateSheet(
        challenge: challenge,
        onUpgrade: () {
          Navigator.pop(ctx);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        },
      ),
    );
  }
}

// ─── パスビュー（メイン実装） ──────────────────────────────────────────────────

class _StagePathView extends StatelessWidget {
  final List<Challenge> challenges;
  final Map<String, UserProgress> progressMap;
  final int currentIndex;
  final String level;
  final Set<String> favoriteIds;
  final Set<String> wrongAnswerStageIds;
  final void Function(String id) onFavoriteToggle;
  final void Function(BuildContext, Challenge) onStageTap;

  const _StagePathView({
    required this.challenges,
    required this.progressMap,
    required this.currentIndex,
    required this.level,
    required this.favoriteIds,
    this.wrongAnswerStageIds = const {},
    required this.onFavoriteToggle,
    required this.onStageTap,
  });

  static const double _nodeSize = 76.0;
  static const double _rowHeight = 130.0;
  static const double _topPadding = 24.0;

  Color get _levelColor {
    switch (level) {
      case StageLevel.intermediate:
        return const Color(0xFF9B59B6);
      case StageLevel.advanced:
        return const Color(0xFFE67E22);
      default:
        return kPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const Center(child: Text('ステージがありません'));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final leftX = w * 0.28;
      final rightX = w * 0.72;

      final totalHeight = challenges.length * _rowHeight + _topPadding * 2 + 60;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        child: SizedBox(
          width: w,
          height: totalHeight,
          child: Stack(
            children: [
              // パス（背景線）
              CustomPaint(
                size: Size(w, totalHeight),
                painter: _PathPainter(
                  challenges: challenges,
                  progressMap: progressMap,
                  leftX: leftX,
                  rightX: rightX,
                  rowHeight: _rowHeight,
                  topPadding: _topPadding,
                  completedColor: _levelColor,
                  nodeSize: _nodeSize,
                ),
              ),
              // ノード
              ...challenges.asMap().entries.map((entry) {
                final i = entry.key;
                final challenge = entry.value;
                final isLeft = i.isEven;
                final x = isLeft ? leftX : rightX;
                final y = _topPadding + i * _rowHeight + _nodeSize / 2;
                final progress = progressMap[challenge.id];
                final isCompleted = progress?.isCompleted ?? false;
                final starsEarned = progress?.starsEarned ?? 0;
                final completedAt = progress?.completedAt;
                final isCurrent = i == currentIndex;
                final isLocked = !challenge.isFree;

                return Positioned(
                  left: x - _nodeSize / 2,
                  top: y - _nodeSize / 2,
                  child: _StageNode(
                    challenge: challenge,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isLocked: isLocked,
                    starsEarned: starsEarned,
                    completedAt: completedAt,
                    levelColor: _levelColor,
                    size: _nodeSize,
                    labelOnRight: !isLeft,
                    isFavorite: favoriteIds.contains(challenge.id),
                    hasWrongAnswers: wrongAnswerStageIds.contains(challenge.id),
                    onFavoriteToggle: () => onFavoriteToggle(challenge.id),
                    onTap: () => onStageTap(context, challenge),
                  )
                      .animate(
                        delay: Duration(milliseconds: 40 * i),
                      )
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        curve: Curves.easeOut,
                        duration: 300.ms,
                      ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}

// ─── CustomPainter: パス線 ─────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  final List<Challenge> challenges;
  final Map<String, UserProgress> progressMap;
  final double leftX;
  final double rightX;
  final double rowHeight;
  final double topPadding;
  final Color completedColor;
  final double nodeSize;

  const _PathPainter({
    required this.challenges,
    required this.progressMap,
    required this.leftX,
    required this.rightX,
    required this.rowHeight,
    required this.topPadding,
    required this.completedColor,
    required this.nodeSize,
  });

  Offset _nodeCenter(int index) {
    final x = index.isEven ? leftX : rightX;
    final y = topPadding + index * rowHeight + nodeSize / 2;
    return Offset(x, y);
  }

  bool _isCompleted(int index) {
    if (index >= challenges.length) return false;
    return progressMap[challenges[index].id]?.isCompleted ?? false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < challenges.length - 1; i++) {
      final from = _nodeCenter(i);
      final to = _nodeCenter(i + 1);

      // 線の色（現在ステージまでは色付き、以降はグレー）
      final segmentCompleted = _isCompleted(i);
      final paint = Paint()
        ..color = segmentCompleted
            ? completedColor.withValues(alpha: 0.6)
            : Colors.grey.withValues(alpha: 0.25)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // 破線パターン（未完了区間）
      if (!segmentCompleted) {
        _drawDashedCurve(canvas, from, to, paint);
      } else {
        _drawSolidCurve(canvas, from, to, paint);
      }
    }
  }

  void _drawSolidCurve(Canvas canvas, Offset from, Offset to, Paint paint) {
    final path = Path();
    path.moveTo(from.dx, from.dy + nodeSize / 2 - 4);

    // 三次ベジェ曲線でなめらかに接続
    final cp1 = Offset(from.dx, from.dy + nodeSize / 2 + (to.dy - from.dy) * 0.4);
    final cp2 = Offset(to.dx, to.dy - nodeSize / 2 - (to.dy - from.dy) * 0.4);
    path.cubicTo(
      cp1.dx, cp1.dy,
      cp2.dx, cp2.dy,
      to.dx, to.dy - nodeSize / 2 + 4,
    );

    canvas.drawPath(path, paint);
  }

  void _drawDashedCurve(Canvas canvas, Offset from, Offset to, Paint paint) {
    // 破線: 区間を小さなセグメントに分割して描画
    const dashCount = 12;
    final path = Path();
    path.moveTo(from.dx, from.dy + nodeSize / 2 - 4);
    final cp1 = Offset(from.dx, from.dy + nodeSize / 2 + (to.dy - from.dy) * 0.4);
    final cp2 = Offset(to.dx, to.dy - nodeSize / 2 - (to.dy - from.dy) * 0.4);
    path.cubicTo(
      cp1.dx, cp1.dy, cp2.dx, cp2.dy,
      to.dx, to.dy - nodeSize / 2 + 4,
    );

    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    final dashLength = totalLength / dashCount;
    bool draw = true;
    double start = 0;

    while (start < totalLength) {
      final end = math.min(start + dashLength * 0.5, totalLength);
      if (draw) {
        final seg = metrics.extractPath(start, end);
        canvas.drawPath(seg, paint);
      }
      start += dashLength * (draw ? 0.5 : 0.5);
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.progressMap != progressMap ||
      old.completedColor != completedColor;
}

// ─── ステージノード ────────────────────────────────────────────────────────────

class _StageNode extends StatefulWidget {
  final Challenge challenge;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final int starsEarned;
  final DateTime? completedAt;
  final Color levelColor;
  final double size;
  final bool labelOnRight;
  final bool isFavorite;
  final bool hasWrongAnswers;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const _StageNode({
    required this.challenge,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.starsEarned,
    this.completedAt,
    required this.levelColor,
    required this.size,
    required this.labelOnRight,
    required this.isFavorite,
    this.hasWrongAnswers = false,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  State<_StageNode> createState() => _StageNodeState();
}

class _StageNodeState extends State<_StageNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulse);

    if (widget.isCurrent) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StageNode old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !old.isCurrent) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isCurrent && old.isCurrent) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  void _showContextMenu(BuildContext context) {
    final c = widget.challenge;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      if (widget.starsEarned > 0)
                        Row(
                          children: List.generate(
                            3,
                            (i) => Icon(
                              i < widget.starsEarned
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: i < widget.starsEarned
                                  ? const Color(0xFFFFC107)
                                  : kTextSecondary,
                            ),
                          ),
                        ),
                      if (widget.isCompleted && widget.completedAt != null) ...[
                        const SizedBox(height: 2),
                        Builder(builder: (_) {
                          final days = DateTime.now()
                              .difference(widget.completedAt!)
                              .inDays;
                          final label = days == 0
                              ? '今日クリア'
                              : days == 1
                                  ? '昨日クリア'
                                  : '$days日前にクリア';
                          return Text(
                            '✅ $label',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kTextSecondary,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // チャレンジ開始
            ListTile(
              leading: const Text('🚀', style: TextStyle(fontSize: 22)),
              title: const Text('チャレンジ開始'),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                widget.onTap();
              },
            ),
            // お気に入り切り替え
            ListTile(
              leading: Text(
                widget.isFavorite ? '💛' : '🤍',
                style: const TextStyle(fontSize: 22),
              ),
              title: Text(widget.isFavorite ? 'お気に入りから削除' : 'お気に入りに追加'),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                widget.onFavoriteToggle();
              },
            ),
            // 説明を見る
            ListTile(
              leading: const Text('ℹ️', style: TextStyle(fontSize: 22)),
              title: const Text('説明を見る'),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Text(c.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.title,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      c.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ノード幅（ラベル含む）
    const labelWidth = 90.0;
    final nodeSize = widget.size;

    return SizedBox(
      width: nodeSize + labelWidth + 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.labelOnRight
            ? [_buildCircle(nodeSize, context), const SizedBox(width: 8), _buildLabel(context)]
            : [_buildLabel(context), const SizedBox(width: 8), _buildCircle(nodeSize, context)],
      ),
    );
  }

  Widget _buildCircle(double size, BuildContext context) {
    // ミニプロジェクト判定（stageNumber 46-50）
    final bool isProject = widget.challenge.stageNumber >= 46 && widget.challenge.stageNumber <= 50;
    final Color bg;
    final Color border;

    if (isProject && !widget.isLocked) {
      bg = widget.isCompleted
          ? const Color(0xFFD4AF37)
          : context.isDark
              ? const Color(0xFF2D2400)
              : const Color(0xFFFFF9E6);
      border = const Color(0xFFD4AF37);
    } else if (widget.isLocked) {
      bg = context.isDark ? kDarkSurface2 : Colors.grey[200]!;
      border = context.isDark ? Colors.white12 : Colors.grey[300]!;
    } else if (widget.isCompleted) {
      bg = widget.levelColor;
      border = widget.levelColor;
    } else if (widget.isCurrent) {
      bg = context.cardBg;
      border = widget.levelColor;
    } else {
      bg = context.isDark ? kDarkSurface2 : Colors.grey[100]!;
      border = context.isDark ? Colors.white12 : Colors.grey[300]!;
    }

    final typeEmoji = widget.challenge.type == ChallengeType.quiz ? '🐍' : '🧩';

    Widget circle = GestureDetector(
      onTap: widget.onTap,
      onLongPress: !widget.isLocked ? () {
        HapticService.mediumImpact();
        _showContextMenu(context);
      } : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border, width: 3),
              boxShadow: widget.isCurrent || widget.isCompleted
                  ? [
                      BoxShadow(
                        color: widget.levelColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLocked
                  ? const Text('🔒', style: TextStyle(fontSize: 24))
                  : widget.isCompleted
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.challenge.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                            // ミニ星
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                3,
                                (i) => Icon(
                                  i < widget.starsEarned
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 10,
                                  color: i < widget.starsEarned
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.challenge.icon,
                          style: TextStyle(
                            fontSize: 26,
                            color: widget.isCurrent ? null : Colors.grey,
                          ),
                        ),
            ),
          ),
          // タイプバッジ（右下）
          if (!widget.isLocked)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.challenge.type == ChallengeType.quiz
                      ? const Color(0xFF8E44AD)
                      : kPrimaryColor,
                  border: Border.all(color: context.cardBg, width: 1.5),
                ),
                child: Center(
                  child: Text(typeEmoji, style: const TextStyle(fontSize: 9)),
                ),
              ),
            ),
          // お気に入りバッジ（左上）
          if (widget.isFavorite)
            Positioned(
              left: -2,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE74C3C),
                  border: Border.all(color: context.cardBg, width: 1.5),
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 8)),
                ),
              ),
            ),
          // 苦手バッジ（右上）
          if (widget.hasWrongAnswers && !widget.isLocked)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B35),
                  border: Border.all(color: context.cardBg, width: 1.5),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 8)),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.isCurrent) {
      circle = ScaleTransition(scale: _scale, child: circle);
    }

    return circle;
  }

  Widget _buildLabel(BuildContext context) {
    final isLocked = widget.isLocked;
    final isCurrent = widget.isCurrent;

    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.labelOnRight
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            'Stage ${widget.challenge.stageNumber}',
            style: TextStyle(
              fontSize: 10,
              color: isLocked
                  ? kTextSecondary
                  : isCurrent
                      ? widget.levelColor
                      : widget.isCompleted
                          ? widget.levelColor.withValues(alpha: 0.8)
                          : kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.challenge.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isLocked
                  ? kTextSecondary
                  : isCurrent
                      ? context.textPrimary
                      : widget.isCompleted
                          ? context.textPrimary
                          : kTextSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.levelColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'いまここ！',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (widget.isCompleted && widget.completedAt != null && !isCurrent) ...[
            const SizedBox(height: 2),
            () {
              final days = DateTime.now()
                  .difference(widget.completedAt!)
                  .inDays;
              final label = days == 0
                  ? '今日クリア'
                  : days == 1
                      ? '昨日クリア'
                      : '$days日前';
              return Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: widget.levelColor.withValues(alpha: 0.7),
                ),
              );
            }(),
          ],
          if (!isLocked && widget.challenge.stageNumber >= 46 && widget.challenge.stageNumber <= 50)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '🎮 プロジェクト',
                style: TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isLocked)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'プレミアム',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── チャレンジ情報シート ──────────────────────────────────────────────────────

class _ChallengeInfoSheet extends ConsumerWidget {
  final Challenge challenge;
  final int starsEarned;
  final bool isCompleted;
  final DateTime? completedAt;
  final VoidCallback onStart;

  const _ChallengeInfoSheet({
    required this.challenge,
    required this.starsEarned,
    required this.isCompleted,
    this.completedAt,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisual = challenge.type == ChallengeType.visual;
    final typeColor = isVisual ? kPrimaryColor : const Color(0xFF8E44AD);
    final typeLabel = isVisual ? '🧩 ブロックプログラミング' : '🐍 Pythonクイズ';
    final isFavorite = ref.watch(favoritesProvider).isFavorite(challenge.id);
    // この challenge の苦手問題数を計算
    final wrongTexts = ref.watch(wrongAnswersProvider).answers
        .map((a) => a.questionText)
        .toSet();
    final wrongCount = challenge.questions
        .where((q) => wrongTexts.contains(q.text))
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ハンドル
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // アイコン + タイトル
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    challenge.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stage ${challenge.stageNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, curve: Curves.easeOut),
          const SizedBox(height: 16),
          // タイプバッジ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: typeColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                fontSize: 12,
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 250.ms),
          const SizedBox(height: 12),
          // 説明文
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimary,
              height: 1.5,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 250.ms),
          const SizedBox(height: 10),
          // メタ情報（問題数・ヒント数・スター）
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (!isVisual && challenge.questions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 14, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.questions.length}問',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_outline, size: 14, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '最大${challenge.maxStars}スター',
                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
              if (challenge.hints.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFFF39C12)),
                    const SizedBox(width: 4),
                    Text(
                      'ヒント ${challenge.hints.length}個',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFF39C12)),
                    ),
                  ],
                ),
              if (wrongCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '苦手 $wrongCount問',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE64A00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ).animate(delay: 120.ms).fadeIn(duration: 250.ms),
          // 以前のスター（クリア済みの場合）
          if (isCompleted) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kStarColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kStarColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('前回のスコア: ', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                        ...List.generate(
                          3,
                          (i) => Icon(
                            i < starsEarned ? Icons.star : Icons.star_border,
                            size: 18,
                            color: kStarColor,
                          ),
                        ),
                        if (starsEarned < 3) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '再挑戦で満点を狙おう！',
                            style: TextStyle(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (completedAt != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available, size: 14, color: kPrimaryColor),
                        const SizedBox(height: 2),
                        Text(
                          () {
                            final days = DateTime.now().difference(completedAt!).inDays;
                            if (days == 0) return '今日';
                            if (days == 1) return '昨日';
                            return '$days日前';
                          }(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ).animate(delay: 140.ms).fadeIn(duration: 250.ms),
          ],
          const SizedBox(height: 16),
          // お気に入りボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticService.lightImpact();
                final (wasAdded, newCount) = await ref.read(favoritesProvider.notifier).toggle(challenge.id);
                if (!context.mounted) return;
                checkFavoriteMilestoneBadge(context, wasAdded: wasAdded, newCount: newCount); // ignore: use_build_context_synchronously
              },
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                size: 18,
                color: isFavorite
                    ? const Color(0xFFE67E22)
                    : null,
              ),
              label: Text(
                isFavorite ? 'お気に入り解除' : 'お気に入りに追加',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(
                  color: isFavorite
                      ? const Color(0xFFE67E22)
                      : Colors.grey.shade400,
                ),
                foregroundColor: isFavorite
                    ? const Color(0xFFE67E22)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 250.ms),
          const SizedBox(height: 10),
          // 開始ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isCompleted ? '再挑戦する' : '挑戦する！',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ).animate(delay: 180.ms).fadeIn(duration: 300.ms).slideY(
                begin: 0.1,
                curve: Curves.easeOut,
                duration: 300.ms,
              ),
        ],
      ),
    );
  }
}

// ─── プレミアムゲートシート ────────────────────────────────────────────────────

class _PremiumGateSheet extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onUpgrade;

  const _PremiumGateSheet({
    required this.challenge,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ドラッグハンドル
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ロックアイコン
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF39C12).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🔒', style: TextStyle(fontSize: 32)),
              ),
            ).animate()
              .scale(begin: const Offset(0.4, 0.4), curve: Curves.elasticOut, duration: 600.ms)
              .fadeIn(duration: 200.ms),
            const SizedBox(height: 16),
            Text(
              'プレミアムステージです',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut, duration: 300.ms),
            const SizedBox(height: 6),
            Text(
              '「${challenge.title}」はプレミアムプランで\nご利用いただけます',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                height: 1.5,
              ),
            ).animate(delay: 270.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            // 特典リスト
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.isDark ? context.subCardBg : const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF39C12).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _BenefitRow(text: '全${AppConstants.totalStages}ステージ解放')
                      .animate(delay: 340.ms).fadeIn(duration: 250.ms).slideX(begin: 0.05, curve: Curves.easeOut, duration: 250.ms),
                  const SizedBox(height: 6),
                  _BenefitRow(text: '上級Pythonコース')
                      .animate(delay: 390.ms).fadeIn(duration: 250.ms).slideX(begin: 0.05, curve: Curves.easeOut, duration: 250.ms),
                  const SizedBox(height: 6),
                  _BenefitRow(text: '広告なしで快適に学習')
                      .animate(delay: 440.ms).fadeIn(duration: 250.ms).slideX(begin: 0.05, curve: Curves.easeOut, duration: 250.ms),
                ],
              ),
            ).animate(delay: 320.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39C12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '🚀 プレミアムを見る',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '閉じる',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('✅', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: context.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── レベル進捗バナー ─────────────────────────────────────────────────────────

class _LevelProgressBanner extends StatelessWidget {
  final int completedInLevel;
  final int totalInLevel;
  final String level;

  const _LevelProgressBanner({
    required this.completedInLevel,
    required this.totalInLevel,
    required this.level,
  });

  Color get _levelColor {
    switch (level) {
      case StageLevel.intermediate:
        return const Color(0xFF9B59B6);
      case StageLevel.advanced:
        return const Color(0xFFE67E22);
      default:
        return kPrimaryColor;
    }
  }

  String get _motivationText {
    if (totalInLevel == 0) return '';
    final rate = completedInLevel / totalInLevel;
    if (completedInLevel == 0) return 'さあ始めよう！最初の一歩を踏み出そう 🚀';
    if (rate < 0.25) return 'いいスタート！このまま続けよう 💪';
    if (rate < 0.5) return '順調に進んでいるよ！もう半分まであと少し ⭐';
    if (rate < 0.75) return 'すごい！半分以上クリアしたよ 🎉';
    if (rate < 1.0) return 'あと少し！ゴールが見えてきたよ 🏁';
    return '全ステージクリア！完璧です！🌟';
  }

  @override
  Widget build(BuildContext context) {
    if (totalInLevel == 0) return const SizedBox.shrink();
    final rate = totalInLevel > 0 ? completedInLevel / totalInLevel : 0.0;
    final remaining = totalInLevel - completedInLevel;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _levelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _motivationText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _levelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$completedInLevel / $totalInLevel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _levelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: _levelColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
              minHeight: 6,
            ),
          ),
          if (remaining > 0 && completedInLevel > 0) ...[
            const SizedBox(height: 4),
            Text(
              'あと $remaining ステージ',
              style: TextStyle(
                fontSize: 10,
                color: _levelColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, curve: Curves.easeOut);
  }
}

// ─── レベルゴールカード ─────────────────────────────────────────────────────────

class _LevelGoalCard extends StatefulWidget {
  final String level;
  const _LevelGoalCard({required this.level});

  @override
  State<_LevelGoalCard> createState() => _LevelGoalCardState();
}

class _LevelGoalCardState extends State<_LevelGoalCard> {
  bool _expanded = false;

  Color get _color {
    switch (widget.level) {
      case StageLevel.intermediate:
        return const Color(0xFF9B59B6);
      case StageLevel.advanced:
        return const Color(0xFFE67E22);
      default:
        return kPrimaryColor;
    }
  }

  String get _headerEmoji {
    switch (widget.level) {
      case StageLevel.intermediate:
        return '🐍';
      case StageLevel.advanced:
        return '🚀';
      default:
        return '🧩';
    }
  }

  String get _title {
    switch (widget.level) {
      case StageLevel.intermediate:
        return '中きゅうをクリアするとできること';
      case StageLevel.advanced:
        return '上きゅうをクリアするとできること';
      default:
        return '初きゅうをクリアするとできること';
    }
  }

  List<(String, String)> get _skills {
    switch (widget.level) {
      case StageLevel.intermediate:
        return [
          ('🐍', 'Pythonでスコア計算やリストが使える'),
          ('🔄', 'forループ・if文・while文が書ける'),
          ('⚙️', '自分だけの関数（def）が作れる'),
          ('🗂️', '辞書でキャラクターのデータを管理できる'),
          ('🐛', 'エラーメッセージを読んでバグが直せる'),
        ];
      case StageLevel.advanced:
        return [
          ('✊', 'じゃんけん・数当てゲームが作れる'),
          ('🏗️', 'クラスを使って自分だけのキャラクターが作れる'),
          ('⚡', 'リスト内包表記などPythonicな書き方ができる'),
          ('🔁', '再帰・ソート・二分探索などのアルゴリズムがわかる'),
          ('📊', 'まとめ・ぶんせきプログラムが作れる'),
        ];
      default:
        return [
          ('🤖', 'ロボットに命令してゴールまで動かせる'),
          ('🔁', '「じゅんばん・くり返し・もし〜なら」がわかる'),
          ('🧩', 'ビジュアルブロックでプログラムが作れる'),
          ('🐍', 'Pythonのprint・変数・入力の基本がわかる'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final skills = _skills;

    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Text(_headerEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: color.withValues(alpha: 0.15)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: skills.map((skill) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(skill.$1, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              skill.$2,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── ステージ検索デリゲート ─────────────────────────────────────────────────────

// ─── フィルターチップ ─────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color = kPrimaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : context.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : kTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _StageSearchDelegate extends SearchDelegate<Challenge?> {
  final List<Challenge> allChallenges;
  final Map<String, UserProgress> progressMap;
  final Set<String> favoriteIds;
  final Set<String> wrongAnswerStageIds;

  _StageSearchDelegate({
    required this.allChallenges,
    required this.progressMap,
    this.favoriteIds = const {},
    this.wrongAnswerStageIds = const {},
  }) : super(searchFieldLabel: 'ステージを検索...');

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        toolbarTextStyle: const TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white60),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  List<Challenge> get _filtered {
    if (query.isEmpty) return allChallenges;
    final q = query.toLowerCase().trim();
    // Allow searching by stage number (e.g. "1", "10")
    final stageNum = int.tryParse(q);
    return allChallenges.where((c) =>
      c.title.toLowerCase().contains(q) ||
      c.description.toLowerCase().contains(q) ||
      (stageNum != null && c.stageNumber == stageNum)
    ).toList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _filtered;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              '「$query」は見つかりませんでした',
              style: const TextStyle(fontSize: 14, color: kTextSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final c = results[i];
        final progress = progressMap[c.id];
        final isCompleted = progress?.isCompleted ?? false;
        final stars = progress?.starsEarned ?? 0;
        final isFavorite = favoriteIds.contains(c.id);
        final hasWrong = wrongAnswerStageIds.contains(c.id);
        final levelColor = switch (c.level) {
          StageLevel.intermediate => const Color(0xFF9B59B6),
          StageLevel.advanced => const Color(0xFFE67E22),
          _ => kPrimaryColor,
        };
        final levelLabel = switch (c.level) {
          StageLevel.intermediate => '中級',
          StageLevel.advanced => '上級',
          _ => '初級',
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: ctx.cardBg,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticService.lightImpact();
              close(context, c);
              if (!c.isFree) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
                return;
              }
              if (c.type == ChallengeType.quiz) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => QuizScreen(challenge: c)),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditorScreen(challenge: c)),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(c.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                levelLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: levelColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (c.type == ChallengeType.quiz
                                        ? const Color(0xFF8E44AD)
                                        : kPrimaryColor)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.type == ChallengeType.quiz ? '🐍 クイズ' : '🧩 ブロック',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: c.type == ChallengeType.quiz
                                      ? const Color(0xFF8E44AD)
                                      : kPrimaryColor,
                                ),
                              ),
                            ),
                            if (!c.isFree) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.lock, size: 12, color: kTextSecondary),
                            ],
                            const Spacer(),
                            if (isCompleted)
                              Row(
                                children: List.generate(3, (si) => Icon(
                                  si < stars ? Icons.star : Icons.star_border,
                                  size: 12,
                                  color: si < stars
                                      ? const Color(0xFFFFC107)
                                      : kTextSecondary,
                                )),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ctx.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasWrong) ...[
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                  ],
                  if (isFavorite) ...[
                    Icon(
                      Icons.favorite,
                      color: Colors.pink.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.play_circle_outline,
                    color: isCompleted ? kPrimaryColor : kTextSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

