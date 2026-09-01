import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_mission.dart';

/// 毎日ミッションの状態
class DailyMissionState {
  final DailyMissionSet? todayMissions;     // 本日のミッションセット
  final Map<String, int> missionProgress;   // ミッションID -> 現在の進捗値
  final Map<String, DateTime> lastUpdated;  // ミッションID -> 最終更新日時
  final DateTime? lastGeneratedDate;        // ミッション生成日

  const DailyMissionState({
    this.todayMissions,
    this.missionProgress = const {},
    this.lastUpdated = const {},
    this.lastGeneratedDate,
  });

  /// コピーメソッド
  DailyMissionState copyWith({
    DailyMissionSet? todayMissions,
    Map<String, int>? missionProgress,
    Map<String, DateTime>? lastUpdated,
    DateTime? lastGeneratedDate,
  }) =>
      DailyMissionState(
        todayMissions: todayMissions ?? this.todayMissions,
        missionProgress: missionProgress ?? this.missionProgress,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      );

  @override
  String toString() =>
      'DailyMissionState(todayMissions: ${todayMissions?.missions.length ?? 0})';
}

/// 毎日ミッション管理プロバイダ
class DailyMissionNotifier extends StateNotifier<DailyMissionState> {
  DailyMissionNotifier() : super(const DailyMissionState()) {
    _initializeMissions();
  }

  static const String _missionsKey = 'daily_missions';
  static const String _progressKey = 'mission_progress';
  static const String _lastGeneratedKey = 'last_generated_date';

  /// ミッションの初期化
  Future<void> _initializeMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';

    // 保存されたミッションを読み込む
    final savedMissionsJson = prefs.getStringList(_missionsKey) ?? [];
    final savedProgress = prefs.getStringList(_progressKey) ?? [];
    final lastGeneratedStr = prefs.getString(_lastGeneratedKey);

    DateTime? lastGenerated;
    if (lastGeneratedStr != null) {
      lastGenerated = DateTime.parse(lastGeneratedStr);
    }

    // 新しい日付の場合はミッションを再生成
    if (lastGenerated == null ||
        lastGenerated.year != now.year ||
        lastGenerated.month != now.month ||
        lastGenerated.day != now.day) {
      // 新しいミッションセットを生成
      final missions = _generateDailyMissions();
      final missionSet = DailyMissionSet(
        date: now,
        missions: missions,
        totalRewardCoins: missions.fold(0, (sum, m) => sum + m.rewardCoins),
        totalRewardXp: missions.fold(0, (sum, m) => sum + m.rewardXp),
      );

      // 進捗をリセット
      Map<String, int> newProgress = {};
      for (final mission in missions) {
        newProgress[mission.id] = 0;
      }

      // 保存
      final missionsListJson = missions
          .map((m) => jsonEncode(m.toJson()))
          .toList();
      await prefs.setStringList(_missionsKey, missionsListJson);
      await prefs.setStringList(_progressKey, []);
      await prefs.setString(_lastGeneratedKey, now.toIso8601String());

      state = DailyMissionState(
        todayMissions: missionSet,
        missionProgress: newProgress,
        lastGeneratedDate: now,
      );
    } else {
      // 既存のミッションを復元
      List<DailyMission> missions = [];
      if (savedMissionsJson.isNotEmpty) {
        missions = savedMissionsJson
            .map((json) => DailyMission.fromJson(jsonDecode(json)))
            .toList();
      }

      Map<String, int> progress = {};
      for (final progressJson in savedProgress) {
        final decoded = jsonDecode(progressJson) as Map<String, dynamic>;
        progress[decoded['id'] as String] = decoded['value'] as int;
      }

      final missionSet = DailyMissionSet(
        date: now,
        missions: missions,
        totalRewardCoins: missions.fold(0, (sum, m) => sum + m.rewardCoins),
        totalRewardXp: missions.fold(0, (sum, m) => sum + m.rewardXp),
      );

      state = DailyMissionState(
        todayMissions: missionSet,
        missionProgress: progress,
        lastGeneratedDate: lastGenerated,
      );
    }
  }

  /// デフォルトミッションを生成
  static List<DailyMission> _generateDailyMissions() => [
    DailyMission(
      id: 'daily_quiz_5',
      title: 'クイズに5回挑戦',
      description: '5問のクイズを解こう',
      emoji: '🎯',
      type: MissionType.quiz,
      difficulty: MissionDifficulty.easy,
      targetValue: 5,
      rewardCoins: 50,
      rewardXp: 25,
    ),
    DailyMission(
      id: 'daily_correct_10',
      title: '正解を10個獲得',
      description: 'クイズで10問正解しよう',
      emoji: '⭐',
      type: MissionType.accuracy,
      difficulty: MissionDifficulty.normal,
      targetValue: 10,
      rewardCoins: 100,
      rewardXp: 50,
      rewardBadgeId: 'daily_10correct',
    ),
    DailyMission(
      id: 'daily_lesson_1',
      title: 'レッスンを1つ完了',
      description: 'レッスンを1つ完了しよう',
      emoji: '✅',
      type: MissionType.lesson,
      difficulty: MissionDifficulty.normal,
      targetValue: 1,
      rewardCoins: 75,
      rewardXp: 40,
    ),
    DailyMission(
      id: 'daily_study_30min',
      title: '30分学習',
      description: '30分以上学習しよう',
      emoji: '⏱️',
      type: MissionType.timeSpent,
      difficulty: MissionDifficulty.hard,
      targetValue: 30,
      rewardCoins: 150,
      rewardXp: 75,
    ),
  ];

  /// ミッションの進捗を更新
  Future<void> updateMissionProgress(String missionId, int newValue) async {
    final prefs = await SharedPreferences.getInstance();

    if (state.todayMissions == null) {
      return;
    }

    final mission = state.todayMissions!.missions
        .firstWhere((m) => m.id == missionId);

    final updatedProgress = Map<String, int>.from(state.missionProgress);
    updatedProgress[missionId] = newValue;

    // ミッション完了をチェック
    List<DailyMission> updatedMissions = List.from(state.todayMissions!.missions);
    if (newValue >= mission.targetValue && !mission.isCompleted) {
      final missionIndex = updatedMissions.indexWhere((m) => m.id == missionId);
      updatedMissions[missionIndex] = mission.copyWith(
        completedAt: DateTime.now(),
      );
    }

    // SharedPreferences に保存
    final missionsJson = updatedMissions
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    final progressList = updatedProgress.entries
        .map((e) => jsonEncode({'id': e.key, 'value': e.value}))
        .toList();

    await prefs.setStringList(_missionsKey, missionsJson);
    await prefs.setStringList(_progressKey, progressList);

    final updatedSet = DailyMissionSet(
      date: state.todayMissions!.date,
      missions: updatedMissions,
      totalRewardCoins: state.todayMissions!.totalRewardCoins,
      totalRewardXp: state.todayMissions!.totalRewardXp,
    );

    state = state.copyWith(
      todayMissions: updatedSet,
      missionProgress: updatedProgress,
    );
  }

  /// ミッションを完了
  Future<void> completeMission(String missionId) async {
    if (state.todayMissions == null) {
      return;
    }

    final mission = state.todayMissions!.missions
        .firstWhere((m) => m.id == missionId);

    if (!mission.isCompleted) {
      final prefs = await SharedPreferences.getInstance();
      final completedMission = mission.copyWith(completedAt: DateTime.now());

      final updatedMissions = state.todayMissions!.missions
          .map((m) => m.id == missionId ? completedMission : m)
          .toList();

      final missionsJson = updatedMissions
          .map((m) => jsonEncode(m.toJson()))
          .toList();
      await prefs.setStringList(_missionsKey, missionsJson);

      final updatedSet = DailyMissionSet(
        date: state.todayMissions!.date,
        missions: updatedMissions,
        totalRewardCoins: state.todayMissions!.totalRewardCoins,
        totalRewardXp: state.todayMissions!.totalRewardXp,
      );

      state = state.copyWith(todayMissions: updatedSet);
    }
  }

  /// ミッション進捗情報を取得
  DailyMissionProgress getMissionProgress(String missionId) {
    if (state.todayMissions == null) {
      throw Exception('No missions available');
    }

    final mission = state.todayMissions!.missions
        .firstWhere((m) => m.id == missionId);
    final currentValue = state.missionProgress[missionId] ?? 0;
    final remainingValue = (mission.targetValue - currentValue).abs();
    final progressPercentage =
        (currentValue / mission.targetValue * 100).clamp(0.0, 100.0);

    return DailyMissionProgress(
      mission: mission,
      currentValue: currentValue,
      progress: progressPercentage,
    );
  }

  /// 未完了のミッションを取得
  List<DailyMissionProgress> getIncompleteMissions() {
    if (state.todayMissions == null) {
      return [];
    }

    return state.todayMissions!.missions
        .where((m) => !m.isCompleted)
        .map((m) => getMissionProgress(m.id))
        .toList();
  }

  /// 完了したミッションを取得
  List<DailyMissionProgress> getCompletedMissions() {
    if (state.todayMissions == null) {
      return [];
    }

    return state.todayMissions!.missions
        .where((m) => m.isCompleted)
        .map((m) => getMissionProgress(m.id))
        .toList();
  }
}

/// 毎日ミッションプロバイダ
final dailyMissionProvider = StateNotifierProvider<DailyMissionNotifier, DailyMissionState>(
  (ref) => DailyMissionNotifier(),
);

/// ミッション進捗情報を取得するプロバイダ
final missionProgressProvider =
    FutureProvider.family<DailyMissionProgress, String>((ref, missionId) async {
  final notifier = ref.watch(dailyMissionProvider.notifier);
  return notifier.getMissionProgress(missionId);
});

/// 未完了のミッションを取得するプロバイダ
final incompleteMissionsProvider =
    FutureProvider<List<DailyMissionProgress>>((ref) async {
  final notifier = ref.watch(dailyMissionProvider.notifier);
  return notifier.getIncompleteMissions();
});

/// 完了したミッションを取得するプロバイダ
final completedMissionsProvider =
    FutureProvider<List<DailyMissionProgress>>((ref) async {
  final notifier = ref.watch(dailyMissionProvider.notifier);
  return notifier.getCompletedMissions();
});
