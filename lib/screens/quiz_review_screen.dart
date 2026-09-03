import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/progress_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../widgets/code_highlight.dart';
import 'quiz_result_screen.dart';
import '../widgets/shortcut_help.dart';
import 'badge_unlock_screen.dart';

/// 間違えた問題を一問ずつ復習するスクリーン
class QuizReviewScreen extends ConsumerStatefulWidget {
  /// 不正解だった QuizAnswer のみを渡す
  final List<QuizAnswer> wrongAnswers;

  const QuizReviewScreen({super.key, required this.wrongAnswers});

  @override
  ConsumerState<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends ConsumerState<QuizReviewScreen> {
  int _index = 0;
  bool _slideForward = true;
  late List<QuizAnswer> _localAnswers;
  final FocusNode _focusNode = FocusNode();
  int _resolvedCount = 0; // このセッションで解決した問題数
  late int _initialTotal;  // セッション開始時の問題数
  DateTime? _sessionStart;
  bool _timeRecorded = false;       // 学習時間を記録済みかのフラグ
  bool _questionsRecorded = false;  // 累計回答数を記録済みかのフラグ

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _localAnswers = List<QuizAnswer>.from(widget.wrongAnswers);
    _initialTotal = _localAnswers.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    // _showFinishDialog で記録済みでなければ記録（中途終了パス）
    if (!_timeRecorded && _sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
      if (elapsed > 0) {
        ref.read(progressProvider.notifier).recordLearningSeconds(elapsed);
      }
    }
    _focusNode.dispose();
    super.dispose();
  }

  QuizAnswer get _current => _localAnswers[_index];
  bool get _isLast => _index == _localAnswers.length - 1;

  Future<void> _showFinishDialog() async {
    HapticService.mediumImpact();
    final elapsed = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inSeconds
        : 0;

    // 累計回答数を記録（マイルストーン判定用に前後を保存）
    final notifier = ref.read(progressProvider.notifier);
    final prevAnswered = notifier.totalQuestionsAnswered;
    if (_initialTotal > 0 && !_questionsRecorded) {
      _questionsRecorded = true;
      await notifier.recordQuestionsAnswered(_initialTotal);
    }
    final newAnswered = notifier.totalQuestionsAnswered;

    // 学習時間を記録し、バッジ結果を取得
    (String, String, String, String)? learningBadge;
    if (!_timeRecorded && elapsed > 0) {
      _timeRecorded = true;
      learningBadge = await notifier.recordLearningSeconds(elapsed);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📖 復習完了！', style: TextStyle(fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_initialTotal問をすべて復習しました',
              style: const TextStyle(fontSize: 14),
            ),
            if (elapsed > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    elapsed >= 60
                        ? '${elapsed ~/ 60}分${elapsed % 60}秒'
                        : '$elapsed秒',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _initialTotal > 0
                        ? '（平均${(elapsed / _initialTotal).round()}秒/問）'
                        : '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ],
            if (_resolvedCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '$_resolvedCount問を苦手リストから削除！',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              HapticService.lightImpact();
              final timeStr = elapsed >= 60
                  ? '${elapsed ~/ 60}分${elapsed % 60}秒'
                  : '$elapsed秒';
              final resolvedLine = _resolvedCount > 0
                  ? '✅ $_resolvedCount問を苦手リストから削除！\n'
                  : '';
              final timeLine = elapsed > 0 ? '⏱ $timeStr\n' : '';
              final text =
                  '📖 苦手問題の復習完了！\n'
                  '$_initialTotal問をすべて復習\n'
                  '$timeLine'
                  '$resolvedLine'
                  '#しょうがくプログラミング';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 クリップボードにコピーしました'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('シェア'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // 苦手克服バッジ（全ての苦手問題を解消した場合）
    final allCleared = _resolvedCount > 0 && ref.read(wrongAnswersProvider).isEmpty;

    // 累計回答数マイルストーンバッジ
    (String, String, String, String)? qBadge;
    const qMilestones = [
      (100,  '📝', '100問挑戦！',      '累計100問に回答達成！',                    '次は500問を目指そう！'),
      (500,  '📚', '500問達成！',      '累計500問に回答！本格的なコーダー！',       '次は1000問を目指そう！'),
      (1000, '🧠', '1000問マスター！', '累計1000問に回答！あなたはコードマスター！', '実績画面で確認しよう！'),
    ];
    for (final (target, icon, name, message, goal) in qMilestones) {
      if (prevAnswered < target && newAnswered >= target) {
        qBadge = (icon, name, message, goal);
        break;
      }
    }

    // バッジ表示チェーン: 苦手克服 → 学習時間 → 累計回答数 → 閉じる
    final lb = learningBadge; // null-promotion works on final locals in closures
    final qb = qBadge;
    void showNextBadge() {
      if (lb != null && mounted) {
        showBadgeUnlock(
          context, // ignore: use_build_context_synchronously
          icon: lb.$1,
          name: lb.$2,
          message: lb.$3,
          points: 30,
          nextGoal: lb.$4,
          onContinue: () {
            if (qb != null && mounted) {
              // ignore: use_build_context_synchronously
              showBadgeUnlock(context, icon: qb.$1, name: qb.$2,
                message: qb.$3, points: 100, nextGoal: qb.$4,
                onContinue: () { if (Navigator.of(context).canPop()) Navigator.of(context).pop(); });
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      } else if (qb != null && mounted) {
        showBadgeUnlock(
          context, // ignore: use_build_context_synchronously
          icon: qb.$1,
          name: qb.$2,
          message: qb.$3,
          points: 100,
          nextGoal: qb.$4,
          onContinue: () { if (Navigator.of(context).canPop()) Navigator.of(context).pop(); },
        );
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    // 苦手克服バッジ（全問クリア）
    if (allCleared && mounted) {
      showBadgeUnlock(
        context, // ignore: use_build_context_synchronously
        icon: '🏆',
        name: '苦手克服マスター！',
        message: '苦手問題を全て解消しました！すごい！',
        points: 200,
        nextGoal: '引き続き新しいステージに挑戦しよう！',
        onContinue: showNextBadge,
      );
    } else {
      showNextBadge();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // → / Enter: 次の問題 or 完了
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.enter) {
      if (_isLast) {
        _showFinishDialog();
      } else {
        HapticService.lightImpact();
        SoundService().playTap();
        setState(() { _slideForward = true; _index++; });
      }
      return KeyEventResult.handled;
    }

    // ←: 前の問題
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_index > 0) {
        HapticService.lightImpact();
        SoundService().playTap();
        setState(() { _slideForward = false; _index--; });
        return KeyEventResult.handled;
      }
    }

    // Esc / Backspace: 戻る
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }

    // O → 頻度順ソート（多く間違えた順）
    if (key == LogicalKeyboardKey.keyO) {
      _sortByFrequency();
      return KeyEventResult.handled;
    }

    // S → シャッフル
    if (key == LogicalKeyboardKey.keyS) {
      HapticService.mediumImpact();
      SoundService().playTap();
      setState(() {
        _localAnswers.shuffle(Random());
        _index = 0;
        _slideForward = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔀 問題をシャッフルしました'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return KeyEventResult.handled;
    }
    // D / Delete: 苦手リストから削除
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.delete) {
      HapticService.mediumImpact();
      SoundService().playCorrect();
      final questionText = _current.questionText;
      // ignore: unawaited_futures
      ref.read(wrongAnswersProvider.notifier).resolveAnswer(questionText);
      ref.read(progressProvider.notifier).addBonusPoints(5);
      final remaining = ref.read(wrongAnswersProvider).count;
      setState(() {
        _localAnswers.removeAt(_index);
        _resolvedCount++;
        if (_localAnswers.isEmpty) {
          // 苦手リストが空になった！
          if (remaining == 0) {
            final ctx = context;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              showBadgeUnlock(
                ctx, // ignore: use_build_context_synchronously
                icon: '💪',
                name: '苦手克服！',
                message: '苦手リストをすべて解決！',
                points: 50,
                nextGoal: '新しいステージに挑戦しよう！',
                onContinue: () {
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop();
                  }
                },
              );
            });
          } else {
            Navigator.pop(context);
          }
          return;
        }
        if (_index >= _localAnswers.length) {
          _index = _localAnswers.length - 1;
        }
      });
      if (_localAnswers.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 苦手リストから削除しました'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return KeyEventResult.handled;
    }

    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('→ / Enter', '次の問題'),
        ('←', '前の問題'),
        ('S', 'シャッフル'),
        ('O', '頻度順ソート（多く間違えた順）'),
        ('D / Delete', '苦手リストから削除'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // 最後の1問を解決した直後、pop()遷移が完了するまでの間に再ビルドが
    // 走ることがある。_localAnswersが空の状態でインデックス/除算を
    // 行うとクラッシュするため、安全なプレースホルダーを返す。
    if (_localAnswers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -300 && !_isLast) {
            // 左スワイプ → 次へ
            HapticService.lightImpact();
            SoundService().playTap();
            setState(() { _slideForward = true; _index++; });
          } else if (v > 300 && _index > 0) {
            // 右スワイプ → 前へ
            HapticService.lightImpact();
            SoundService().playTap();
            setState(() { _slideForward = false; _index--; });
          }
        },
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCard()
                    .animate(key: ValueKey(_index))
                    .fadeIn(duration: 250.ms)
                    .slideX(
                      begin: _slideForward ? 0.06 : -0.06,
                      curve: Curves.easeOut,
                      duration: 250.ms,
                    ),
              ),
            ),
            _buildNavBar(context),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (_localAnswers.isEmpty) {
      return const SizedBox.shrink();
    }
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
                  '間違えた問題の復習',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.white70, size: 20),
                tooltip: '頻度順（多く間違えた順）',
                onPressed: _sortByFrequency,
              ),
              IconButton(
                icon: const Icon(Icons.shuffle, color: Colors.white70, size: 20),
                tooltip: 'シャッフル',
                onPressed: () {
                  HapticService.mediumImpact();
                  setState(() {
                    _localAnswers.shuffle(Random());
                    _index = 0;
                    _slideForward = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔀 問題をシャッフルしました'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (_resolvedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '✅ $_resolvedCount/$_initialTotal 解決',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1} / ${_localAnswers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: (_index + 1) / _localAnswers.length),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(dtDay).inDays;
    if (diff == 0) return '🕐 今日間違えた';
    if (diff == 1) return '🕐 昨日間違えた';
    return '🕐 $diff日前に間違えた';
  }

  void _sortByFrequency() {
    HapticService.mediumImpact();
    SoundService().playTap();
    final counts = ref.read(wrongAnswersProvider).wrongCounts;
    setState(() {
      _localAnswers.sort((a, b) {
        final ca = counts[a.questionText] ?? 0;
        final cb = counts[b.questionText] ?? 0;
        return cb.compareTo(ca); // 多い順
      });
      _index = 0;
      _slideForward = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 頻度順（多く間違えた順）に並べました'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCard() {
    if (_localAnswers.isEmpty) {
      return const SizedBox.shrink();
    }
    final answer = _current;
    final wrongState = ref.read(wrongAnswersProvider);
    final ts = wrongState.timestampFor(answer.questionText);
    final dateLabel = ts == null ? null : _formatRelativeDate(ts);
    final wrongCount = wrongState.wrongCountFor(answer.questionText);

    return Column(
      key: ValueKey(_index),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 問題番号バッジ
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '問題 ${_index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE74C3C),
                ),
              ),
            ),
            if (wrongCount >= 2) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '🔥 ×$wrongCount回間違えた',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ],
            if (answer.hintUsed) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '💡 ヒント使用',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
            if (dateLabel != null) ...[
              const Spacer(),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: context.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // 問題文
        Text(
          answer.questionText,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // コードスニペット（行番号付きで表示）
        if (answer.codeSnippet != null) ...[
          CodeHighlightWidget(code: answer.codeSnippet!, showLineNumbers: true),
          const SizedBox(height: 16),
        ],

        // あなたの回答（不正解）
        _AnswerTile(
          label: 'あなたの回答',
          text: answer.selectedAnswer,
          icon: Icons.close,
          color: Colors.red,
        ).animate(delay: 60.ms).fadeIn(duration: 200.ms).slideX(begin: 0.04, curve: Curves.easeOut, duration: 200.ms),
        const SizedBox(height: 8),

        // 正解
        _AnswerTile(
          label: '正解',
          text: answer.correctAnswer,
          icon: Icons.check,
          color: kPrimaryColor,
        ).animate(delay: 120.ms).fadeIn(duration: 200.ms).slideX(begin: 0.04, curve: Curves.easeOut, duration: 200.ms),
        const SizedBox(height: 20),

        // 解説
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.isDark ? context.subCardBg : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFCC02).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '解説',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF39C12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                answer.explanation.isNotEmpty
                    ? answer.explanation
                    : 'もう一度問題を確認してみよう！',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ).animate(delay: 180.ms).fadeIn(duration: 250.ms).slideY(begin: 0.05, curve: Curves.easeOut, duration: 250.ms),
      ],
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
              color: context.shadowColor, blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 解決した（苦手リストから削除）
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticService.mediumImpact();
                SoundService().playCorrect();
                final questionText = _current.questionText;
                // ignore: unawaited_futures
                ref.read(wrongAnswersProvider.notifier).resolveAnswer(questionText);
                ref.read(progressProvider.notifier).addBonusPoints(5);
                final remaining = ref.read(wrongAnswersProvider).count;
                setState(() {
                  _localAnswers.removeAt(_index);
                  _resolvedCount++;
                  if (_localAnswers.isEmpty) {
                    if (remaining == 0) {
                      final ctx = context;
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        showBadgeUnlock(
                          ctx, // ignore: use_build_context_synchronously
                          icon: '💪',
                          name: '苦手克服！',
                          message: '苦手リストをすべて解決！',
                          points: 50,
                          nextGoal: '新しいステージに挑戦しよう！',
                          onContinue: () {
                            if (Navigator.of(ctx).canPop()) {
                              Navigator.of(ctx).pop();
                            }
                          },
                        );
                      });
                    } else {
                      Navigator.pop(context);
                    }
                    return;
                  }
                  if (_index >= _localAnswers.length) {
                    _index = _localAnswers.length - 1;
                  }
                });
                if (_localAnswers.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 苦手リストから削除しました'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('解決した！（リストから削除）'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: Color(0xFF27AE60)),
                foregroundColor: const Color(0xFF27AE60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
          // 前へ
          if (_index > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  setState(() {
                    _slideForward = false;
                    _index--;
                  });
                },
                icon: const Icon(Icons.arrow_back_ios, size: 14),
                label: const Text('前へ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 12),
          // 次へ / 完了
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLast
                  ? _showFinishDialog
                  : () {
                      HapticService.lightImpact();
                      SoundService().playTap();
                      setState(() {
                        _slideForward = true;
                        _index++;
                      });
                    },
              icon: Text(
                _isLast ? '✅' : '',
                style: const TextStyle(fontSize: 14),
              ),
              label: Text(_isLast ? '復習完了！' : '次の問題へ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor:
                    _isLast ? kPrimaryColor : const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
          ),  // Row

        ],
      ),
    );
  }
}

// ─── 回答タイル ───────────────────────────────────────────────────────────────

class _AnswerTile extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final Color color;

  const _AnswerTile({
    required this.label,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
