import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kReviewKey        = 'daily_review_last_date';
const _kStreakKey         = 'daily_review_streak';
const _kLongestStreakKey  = 'daily_review_longest_streak';
const _kTotalReviewsKey   = 'daily_review_total_count';

class DailyReviewState {
  final bool doneToday;
  final int reviewStreak;       // 現在の連続日数
  final int longestReviewStreak; // 最長連続日数
  final int totalReviewsCompleted; // 累計完了数

  const DailyReviewState({
    this.doneToday = false,
    this.reviewStreak = 0,
    this.longestReviewStreak = 0,
    this.totalReviewsCompleted = 0,
  });
}

class DailyReviewNotifier extends StateNotifier<DailyReviewState> {
  DailyReviewNotifier() : super(const DailyReviewState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate     = prefs.getString(_kReviewKey);
    final streak       = prefs.getInt(_kStreakKey) ?? 0;
    final longestStreak = prefs.getInt(_kLongestStreakKey) ?? streak;
    final totalReviews = prefs.getInt(_kTotalReviewsKey) ?? 0;
    if (lastDate == null) {
      state = DailyReviewState(
        doneToday: false,
        reviewStreak: 0,
        longestReviewStreak: longestStreak,
        totalReviewsCompleted: totalReviews,
      );
      return;
    }
    final today     = _dateStr(DateTime.now());
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final doneToday = lastDate == today;
    // ストリークが有効かどうか: 今日か昨日が最後に完了した日
    final validStreak = (lastDate == today || lastDate == yesterday) ? streak : 0;
    state = DailyReviewState(
      doneToday: doneToday,
      reviewStreak: validStreak,
      longestReviewStreak: longestStreak,
      totalReviewsCompleted: totalReviews,
    );
  }

  Future<void> markDoneToday() async {
    final prefs     = await SharedPreferences.getInstance();
    final lastDate  = prefs.getString(_kReviewKey);
    final today     = _dateStr(DateTime.now());
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));

    // すでに今日完了済みなら何もしない
    if (lastDate == today) return;

    // 昨日完了していればストリーク継続、それ以外はリセット
    final prevStreak = prefs.getInt(_kStreakKey) ?? 0;
    final newStreak  = lastDate == yesterday ? prevStreak + 1 : 1;

    // 最長ストリーク更新
    final prevLongest = prefs.getInt(_kLongestStreakKey) ?? 0;
    final newLongest  = newStreak > prevLongest ? newStreak : prevLongest;

    // 累計回数
    final prevTotal = prefs.getInt(_kTotalReviewsKey) ?? 0;
    final newTotal  = prevTotal + 1;

    await prefs.setString(_kReviewKey, today);
    await prefs.setInt(_kStreakKey, newStreak);
    await prefs.setInt(_kLongestStreakKey, newLongest);
    await prefs.setInt(_kTotalReviewsKey, newTotal);

    state = DailyReviewState(
      doneToday: true,
      reviewStreak: newStreak,
      longestReviewStreak: newLongest,
      totalReviewsCompleted: newTotal,
    );
  }

  String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> resetAll() async {
    state = const DailyReviewState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kReviewKey);
    await prefs.remove(_kStreakKey);
    await prefs.remove(_kLongestStreakKey);
    await prefs.remove(_kTotalReviewsKey);
  }
}

final dailyReviewProvider =
    StateNotifierProvider<DailyReviewNotifier, DailyReviewState>(
  (ref) => DailyReviewNotifier(),
);
