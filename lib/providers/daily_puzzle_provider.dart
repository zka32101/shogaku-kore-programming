import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_programming_coach_service.dart';

const _kPuzzleKey = 'daily_puzzle_date';
const _kPuzzleSolvedKey = 'daily_puzzle_solved_today';
const _kPuzzleStreakKey = 'daily_puzzle_streak';

class DailyPuzzleState {
  final bool isLoading;
  final Map<String, dynamic>? puzzle;
  final bool solvedToday;
  final int streak;
  final String? error;

  const DailyPuzzleState({
    this.isLoading = true,
    this.puzzle,
    this.solvedToday = false,
    this.streak = 0,
    this.error,
  });
}

class DailyPuzzleNotifier extends StateNotifier<DailyPuzzleState> {
  final AIProgrammingCoachService _aiService = AIProgrammingCoachService();

  DailyPuzzleNotifier() : super(const DailyPuzzleState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadPuzzle();
  }

  String _dateStr(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _getDayNumber(DateTime date) {
    // 2026-01-01 からの通算日数（日替わりシード用）
    final epoch = DateTime(2026, 1, 1);
    return date.difference(epoch).inDays;
  }

  Future<void> _loadPuzzle() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPuzzleDate = prefs.getString(_kPuzzleKey);
    final today = _dateStr(DateTime.now());
    final solvedToday = prefs.getBool(_kPuzzleSolvedKey) ?? false;
    final streak = prefs.getInt(_kPuzzleStreakKey) ?? 0;

    // 昨日の詰め問を解いていた場合、ストリーク継続
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final validStreak = (lastPuzzleDate == today || lastPuzzleDate == yesterday) ? streak : 0;

    // 今日の詰め問がまだ生成されていない場合
    if (lastPuzzleDate != today) {
      await _generateTodayPuzzle(validStreak);
    } else {
      state = DailyPuzzleState(
        isLoading: false,
        puzzle: null, // キャッシュから読む処理は省略（本来は SharedPrefs に保存）
        solvedToday: solvedToday,
        streak: validStreak,
      );
    }
  }

  Future<void> _generateTodayPuzzle(int currentStreak) async {
    try {
      state = const DailyPuzzleState(isLoading: true);

      final dayNum = _getDayNumber(DateTime.now());
      final difficulty = _getDifficultyByDay(dayNum);

      final puzzle = await _aiService.generateDailyPuzzle(
        difficulty: difficulty,
        dayNumber: dayNum,
      );

      if (puzzle.containsKey('error')) {
        state = DailyPuzzleState(
          isLoading: false,
          error: puzzle['error'] as String?,
          streak: currentStreak,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final today = _dateStr(DateTime.now());
      await prefs.setString(_kPuzzleKey, today);
      await prefs.setBool(_kPuzzleSolvedKey, false);

      state = DailyPuzzleState(
        isLoading: false,
        puzzle: puzzle,
        solvedToday: false,
        streak: currentStreak,
      );
    } catch (e) {
      state = DailyPuzzleState(
        isLoading: false,
        error: 'エラー: $e',
        streak: state.streak,
      );
    }
  }

  String _getDifficultyByDay(int dayNum) {
    final mod = dayNum % 3;
    if (mod == 0) return '初級';
    if (mod == 1) return '中級';
    return '上級';
  }

  Future<void> markSolvedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = (state.streak) + 1;

    await prefs.setBool(_kPuzzleSolvedKey, true);
    await prefs.setInt(_kPuzzleStreakKey, streak);

    state = DailyPuzzleState(
      isLoading: false,
      puzzle: state.puzzle,
      solvedToday: true,
      streak: streak,
    );
  }
}

final dailyPuzzleProvider =
    StateNotifierProvider<DailyPuzzleNotifier, DailyPuzzleState>((ref) {
  return DailyPuzzleNotifier();
});
