import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show
        FriendsListPage,
        DailyMissionPage,
        WeeklyBonusWidget;

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/character_model.dart';
import '../models/stage.dart';
import '../providers/challenges_provider.dart';
import '../providers/character_provider.dart';
import '../providers/daily_review_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/app_dialog.dart';
import '../widgets/code_highlight.dart';
import '../widgets/daily_puzzle_card.dart';
import '../widgets/shortcut_help.dart';
import '../widgets/tap_scale.dart';
import 'achievements_screen.dart';
import 'badge_unlock_screen.dart';
import 'character_screen.dart';
import 'coaching/views/ai_coaching_dashboard_screen.dart';
import 'coaching/widgets/ai_coaching_card.dart';
import 'daily_review_screen.dart';
import 'editor_screen.dart';
import 'flashcard_screen.dart';
import 'friends_list_screen.dart';
import 'gallery_screen.dart';
import 'lesson_screen.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';
import 'programming_basics_screen.dart';
import 'quiz_result_screen.dart' show QuizAnswer;
import 'quiz_review_screen.dart';
import 'quiz_screen.dart';
import 'ranking_screen.dart';
import 'reverse_teaching_screen.dart';
import 'shop_screen.dart';
import 'stage_list_screen.dart';
import 'time_attack_screen.dart';
import 'weekly_report_screen.dart';
import 'why_programming_screen.dart';
import 'wrong_answers_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _prevLevel;
  int? _prevStreak;
  bool _goalCelebrated = false;
  bool _codeKingChecked = false;
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyT) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const TimeAttackScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const DailyReviewScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyW) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const WrongAnswersListScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const StageListScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const AchievementsScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const FriendsListScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP) {
      HapticService.lightImpact();
      SoundService().playTap();
      Navigator.of(context).push(smoothPageRoute(const ProfileScreen()));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyH) {
      HapticService.lightImpact();
      SoundService().playTap();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('キーボードショートカット: T=時間攻撃, R=復習, W=苦手問題, L=リスト, A=実績, F=友達, P=プロフィール')),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showLevelUpOverlay(BuildContext context, int newLevel) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: _LevelUpOverlay(newLevel: newLevel),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simplified build method during shared_core integration
    // Phase 4 implementation temporarily using placeholders
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: kPrimaryColor,
      ),
      body: const Center(
        child: Text('ホーム画面: 再構築中'),
      ),
    );
  }
}

// QuickQuiz Sheet
class _QuickQuizSheet extends ConsumerStatefulWidget {
  final Question question;
  final String challengeTitle;
  final List<(Question, String)> pool;

  const _QuickQuizSheet({
    required this.question,
    required this.challengeTitle,
    required this.pool,
  });

  @override
  ConsumerState<_QuickQuizSheet> createState() => _QuickQuizSheetState();
}

class _QuickQuizSheetState extends ConsumerState<_QuickQuizSheet> {
  int? _selectedIndex;
  bool _answered = false;
  late Question _currentQuestion;
  late int _questionIndex;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.question;
    _questionIndex = 0;
  }

  void _nextQuestion() {
    if (_questionIndex < 4) {
      final item = widget.pool[_rng.nextInt(widget.pool.length)];
      setState(() {
        _currentQuestion = item.$1;
        _selectedIndex = null;
        _answered = false;
        _questionIndex++;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _answerQuestion() {
    if (_selectedIndex == null) return;

    HapticService.lightImpact();
    final correct = _selectedIndex == _currentQuestion.correctIndex;
    if (correct) {
      SoundService().playCorrect();
      ref.read(progressProvider.notifier).recordQuestionsAnswered(1);
    } else {
      SoundService().playWrong();
      ref.read(wrongAnswersProvider.notifier).addWrongAnswers([
        QuizAnswer(
          questionText: _currentQuestion.text,
          isCorrect: false,
          selectedAnswer: _currentQuestion.options[_selectedIndex!],
          correctAnswer: _currentQuestion.options[_currentQuestion.correctIndex],
        ),
      ]);
    }

    setState(() => _answered = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_questionIndex + 1}/5',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              LinearProgressIndicator(
                value: (_questionIndex + 1) / 5,
              ),
              const SizedBox(height: 20),

              // Question
              Text(
                _currentQuestion.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Options
              ...List.generate(_currentQuestion.options.length, (i) {
                final selected = _selectedIndex == i;
                final isCorrect = i == _currentQuestion.correctIndex;
                final showFeedback = _answered && selected;

                Color bgColor = Colors.grey[200]!;
                if (_answered) {
                  if (isCorrect) {
                    bgColor = Colors.green[100]!;
                  } else if (showFeedback) {
                    bgColor = Colors.red[100]!;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: _answered ? null : () {
                      setState(() => _selectedIndex = i);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? kPrimaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(
                        _currentQuestion.options[i],
                        style: TextStyle(
                          fontSize: 14,
                          color: _answered && !isCorrect && showFeedback
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Submit button
              if (!_answered)
                ElevatedButton(
                  onPressed: _selectedIndex != null ? _answerQuestion : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('答える'),
                )
              else
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(_questionIndex >= 4 ? 'ホームに戻る' : '次の問題へ'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper classes
class _LevelUpOverlay extends StatelessWidget {
  final int newLevel;
  const _LevelUpOverlay({required this.newLevel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'レベルアップ！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'レベル $newLevel',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('続ける'),
            ),
          ],
        ),
      ),
    );
  }
}
