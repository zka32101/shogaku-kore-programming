import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/wrong_answers_provider.dart';
import '../widgets/code_highlight.dart';
import '../widgets/shortcut_help.dart';
import 'quiz_result_screen.dart' show QuizAnswer;
import 'quiz_review_screen.dart';
import 'time_attack_screen.dart';

// 並び替え基準
enum _SortMode { wrongCount, dateAdded, alphabetical }

/// 苦手問題一覧画面
/// 間違えた問題を一覧表示し、フィルター・並び替え・復習開始ができる。
class WrongAnswersListScreen extends ConsumerStatefulWidget {
  const WrongAnswersListScreen({super.key});

  @override
  ConsumerState<WrongAnswersListScreen> createState() =>
      _WrongAnswersListScreenState();
}

class _WrongAnswersListScreenState
    extends ConsumerState<WrongAnswersListScreen> {
  _SortMode _sortMode = _SortMode.wrongCount;
  bool _showDetails = false; // 個別カードの解説を展開するか
  int? _expandedIndex;       // 展開中のカードインデックス
  String _searchQuery = '';  // キーワード検索クエリ
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      if (_searchQuery.isNotEmpty) {
        // 検索クリア
        HapticService.selectionClick();
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });
        return KeyEventResult.handled;
      }
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    // S → 検索欄にフォーカス
    if (key == LogicalKeyboardKey.keyS) {
      HapticService.selectionClick();
      _searchFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    // 1/2/3 → 並び替え切替
    if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      HapticService.selectionClick();
      setState(() => _sortMode = _SortMode.wrongCount);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      HapticService.selectionClick();
      setState(() => _sortMode = _SortMode.dateAdded);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      HapticService.selectionClick();
      setState(() => _sortMode = _SortMode.alphabetical);
      return KeyEventResult.handled;
    }
    // D → 詳細表示トグル
    if (key == LogicalKeyboardKey.keyD) {
      HapticService.selectionClick();
      setState(() => _showDetails = !_showDetails);
      return KeyEventResult.handled;
    }
    // ? → ショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('1', '間違い回数順'),
        ('2', '追加日時順'),
        ('3', '五十音順'),
        ('D', '解説の展開/折りたたみ'),
        ('S', '検索欄にフォーカス'),
        ('Esc / BS', '検索クリア / 戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<QuizAnswer> _sorted(WrongAnswersState ws) {
    final q = _searchQuery.trim().toLowerCase();
    final list = q.isEmpty
        ? List<QuizAnswer>.from(ws.answers)
        : ws.answers
            .where((a) =>
                a.questionText.toLowerCase().contains(q) ||
                a.correctAnswer.toLowerCase().contains(q))
            .toList();
    switch (_sortMode) {
      case _SortMode.wrongCount:
        list.sort((a, b) => ws.wrongCountFor(b.questionText)
            .compareTo(ws.wrongCountFor(a.questionText)));
      case _SortMode.dateAdded:
        list.sort((a, b) {
          final ta = ws.timestamps[a.questionText];
          final tb = ws.timestamps[b.questionText];
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta); // 新しい順
        });
      case _SortMode.alphabetical:
        list.sort((a, b) => a.questionText.compareTo(b.questionText));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(wrongAnswersProvider);
    final sorted = _sorted(ws);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context, ws),
            if (ws.isEmpty)
              const Expanded(child: _EmptyView())
            else ...[
              _buildSortBar(context),
              _buildSearchBar(context),
              if (sorted.isEmpty && _searchQuery.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          '「$_searchQuery」は見つかりませんでした',
                          style: const TextStyle(
                              fontSize: 13, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final answer = sorted[i];
                    final wrongCount = ws.wrongCountFor(answer.questionText);
                    final addedAt = ws.timestamps[answer.questionText];
                    return _WrongAnswerCard(
                      answer: answer,
                      wrongCount: wrongCount,
                      addedAt: addedAt,
                      isExpanded: _showDetails || _expandedIndex == i,
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() {
                          _expandedIndex = _expandedIndex == i ? null : i;
                        });
                      },
                      onResolve: () async {
                        HapticService.lightImpact();
                        await ref
                            .read(wrongAnswersProvider.notifier)
                            .resolveAnswer(answer.questionText);
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 苦手リストから削除しました'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    )
                        .animate(delay: Duration(milliseconds: 40 * i))
                        .fadeIn(duration: 250.ms)
                        .slideX(
                            begin: 0.04,
                            curve: Curves.easeOut,
                            duration: 250.ms);
                  },
                ),
              ),
            ],
            if (!ws.isEmpty) _buildBottomBar(context, sorted, ws),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WrongAnswersState ws) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔥 苦手問題一覧',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!ws.isEmpty)
                  Text(
                    '${ws.count}問 · 克服済み ${ws.totalResolvedCount}問',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
              ],
            ),
          ),
          if (!ws.isEmpty) ...[
            // 詳細展開トグル
            IconButton(
              icon: Icon(
                _showDetails ? Icons.unfold_less : Icons.unfold_more,
                color: Colors.white,
                size: 20,
              ),
              tooltip: _showDetails ? '解説を折りたたむ' : '解説をすべて展開',
              onPressed: () {
                HapticService.selectionClick();
                setState(() {
                  _showDetails = !_showDetails;
                  if (_showDetails) _expandedIndex = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortBar(BuildContext context) {
    const modes = [
      (_SortMode.wrongCount, '🔥 回数順'),
      (_SortMode.dateAdded, '📅 日時順'),
      (_SortMode.alphabetical, '🔤 五十音順'),
    ];
    return Container(
      height: 40,
      color: context.cardBg,
      child: Row(
        children: [
          const SizedBox(width: 12),
          ...modes.map((m) {
            final (mode, label) = m;
            final selected = _sortMode == mode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _sortMode = mode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE74C3C)
                        : const Color(0xFFE74C3C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFFE74C3C),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: context.cardBg,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (v) => setState(() {
          _searchQuery = v;
          _expandedIndex = null;
        }),
        style: TextStyle(fontSize: 13, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: '問題を検索...',
          hintStyle: const TextStyle(fontSize: 13, color: kTextSecondary),
          prefixIcon: const Icon(Icons.search, size: 18, color: kTextSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: kTextSecondary),
                  onPressed: () {
                    HapticService.selectionClick();
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _expandedIndex = null;
                    });
                  },
                )
              : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          filled: true,
          fillColor: context.isDark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFFE74C3C), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, List<QuizAnswer> sorted, WrongAnswersState ws) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
              color: context.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticService.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QuizReviewScreen(wrongAnswers: sorted),
                  ),
                );
              },
              icon: const Text('📖', style: TextStyle(fontSize: 13)),
              label: const Text('カード復習', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE74C3C),
                side: const BorderSide(
                    color: Color(0xFFE74C3C), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                HapticService.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TimeAttackScreen(initialWeakMode: true),
                  ),
                );
              },
              icon: const Text('⚡', style: TextStyle(fontSize: 13)),
              label: const Text('苦手特訓', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 苦手問題カード ─────────────────────────────────────────────────────────────

class _WrongAnswerCard extends StatelessWidget {
  final QuizAnswer answer;
  final int wrongCount;
  final DateTime? addedAt;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onResolve;

  const _WrongAnswerCard({
    required this.answer,
    required this.wrongCount,
    required this.addedAt,
    required this.isExpanded,
    required this.onTap,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = addedAt != null
        ? '${addedAt!.month}/${addedAt!.day} 追加'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE74C3C).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 間違い回数バッジ
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: wrongCount >= 3
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFFE74C3C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🔥×$wrongCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: wrongCount >= 3
                            ? Colors.white
                            : const Color(0xFFE74C3C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      answer.questionText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                        height: 1.4,
                      ),
                      maxLines: isExpanded ? null : 2,
                      overflow:
                          isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: kTextSecondary,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Divider(
                  height: 1,
                  color: context.borderColor),
              // 正解
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ ',
                        style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '正解',
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            answer.correctAnswer,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // コードスニペット
              if (answer.codeSnippet != null &&
                  answer.codeSnippet!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: CodeHighlightWidget(code: answer.codeSnippet!),
                ),
              ],
              // 解説
              if (answer.explanation.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      answer.explanation,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              // アクション行
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 10, color: kTextSecondary),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onResolve,
                      icon: const Text('🎉',
                          style: TextStyle(fontSize: 12)),
                      label: const Text('克服済みにする',
                          style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF27AE60),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (dateStr.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 10, color: kTextSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 空状態 ────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64))
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  curve: Curves.elasticOut,
                  duration: 600.ms)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          Text(
            '苦手問題はありません！',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 8),
          const Text(
            'クイズで間違えた問題が\nここに追加されます',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.5),
          ).animate(delay: 400.ms).fadeIn(duration: 350.ms),
        ],
      ),
    );
  }
}
