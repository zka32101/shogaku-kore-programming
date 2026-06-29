import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_programming_coach_service.dart';

const _kLastReportDateKey = 'weekly_report_last_date';

class WeeklyReportState {
  final String? report;
  final bool isLoading;
  final String? error;
  final DateTime? lastReportDate;

  const WeeklyReportState({
    this.report,
    this.isLoading = false,
    this.error,
    this.lastReportDate,
  });
}

class WeeklyReportNotifier extends StateNotifier<WeeklyReportState> {
  final AIProgrammingCoachService _aiService = AIProgrammingCoachService();

  WeeklyReportNotifier() : super(const WeeklyReportState()) {
    _loadLastReportDate();
  }

  Future<void> _loadLastReportDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_kLastReportDateKey);
      final lastDate = dateStr != null ? DateTime.parse(dateStr) : null;

      state = WeeklyReportState(
        lastReportDate: lastDate,
      );
    } catch (e) {
      state = WeeklyReportState(error: 'エラー: $e');
    }
  }

  bool shouldShowReport() {
    if (state.lastReportDate == null) return true;

    final now = DateTime.now();
    final lastDate = state.lastReportDate!;
    final daysDiff = now.difference(lastDate).inDays;

    // 7日以上経過していればレポート対象
    return daysDiff >= 7;
  }

  Future<void> generateReport(
    String childName,
    int completedThisWeek,
    int totalCompleted,
    List<String> strongTopics,
    List<String> weakTopics,
    int currentLevel,
    int streakDays,
  ) async {
    try {
      state = const WeeklyReportState(isLoading: true);

      final report = await _aiService.generateWeeklyReport(
        childName: childName,
        completedThisWeek: completedThisWeek,
        totalCompleted: totalCompleted,
        strongTopics: strongTopics,
        weakTopics: weakTopics,
        currentLevel: currentLevel,
        streakDays: streakDays,
      );

      // 生成日時を保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastReportDateKey, DateTime.now().toIso8601String());

      state = WeeklyReportState(
        report: report,
        isLoading: false,
        lastReportDate: DateTime.now(),
      );
    } catch (e) {
      state = WeeklyReportState(
        isLoading: false,
        error: 'エラー: $e',
      );
    }
  }
}

final weeklyReportProvider =
    StateNotifierProvider<WeeklyReportNotifier, WeeklyReportState>((ref) {
  return WeeklyReportNotifier();
});
