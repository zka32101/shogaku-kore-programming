import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/providers/daily_mission_provider.dart';
import 'package:shogaku_kore_programming/models/daily_mission.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyMissionState Tests', () {
    test('DailyMissionState creation with default values', () {
      const state = DailyMissionState();

      expect(state.todayMissions, null);
      expect(state.missionProgress, isEmpty);
      expect(state.lastUpdated, isEmpty);
      expect(state.lastGeneratedDate, null);
    });

    test('DailyMissionState copyWith', () {
      final mission = DailyMission(
        id: 'test1',
        title: 'Test Mission',
        description: 'Test',
        emoji: '🎯',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.easy,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      final missionSet = DailyMissionSet(
        date: DateTime.now(),
        missions: [mission],
        totalRewardCoins: 100,
        totalRewardXp: 50,
      );

      final state1 = DailyMissionState(
        todayMissions: missionSet,
        missionProgress: {'test1': 5},
      );

      final state2 = state1.copyWith(
        missionProgress: {'test1': 10},
      );

      expect(state2.todayMissions, missionSet);
      expect(state2.missionProgress['test1'], 10);
    });
  });

  group('DailyMissionNotifier Tests', () {
    test('DailyMissionNotifier initializes with missions', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(dailyMissionProvider);
      expect(state.todayMissions, isNotNull);
      expect(state.todayMissions!.missions.isNotEmpty, true);
    });

    test('DailyMissionNotifier updateMissionProgress', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(dailyMissionProvider.notifier).updateMissionProgress(
        'daily_quiz_5',
        3,
      );

      final state = container.read(dailyMissionProvider);
      expect(state.missionProgress['daily_quiz_5'], 3);
    });

    test('DailyMissionNotifier completes mission', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(dailyMissionProvider.notifier).completeMission(
        'daily_quiz_5',
      );

      final state = container.read(dailyMissionProvider);
      final mission = state.todayMissions!.missions
          .firstWhere((m) => m.id == 'daily_quiz_5');

      expect(mission.isCompleted, true);
    });

    test('DailyMissionNotifier getMissionProgress', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(dailyMissionProvider.notifier).updateMissionProgress(
        'daily_quiz_5',
        3,
      );

      final notifier = container.read(dailyMissionProvider.notifier);
      final progress = notifier.getMissionProgress('daily_quiz_5');

      expect(progress.currentValue, 3);
      expect(progress.mission.targetValue, 5);
      expect(progress.remainingValue, 2);
    });

    test('DailyMissionNotifier getIncompleteMissions', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(dailyMissionProvider.notifier).completeMission(
        'daily_quiz_5',
      );

      final notifier = container.read(dailyMissionProvider.notifier);
      final incompleteMissions = notifier.getIncompleteMissions();

      expect(
        incompleteMissions.every((m) => !m.mission.isCompleted),
        true,
      );
      expect(
        incompleteMissions.any((m) => m.mission.id == 'daily_quiz_5'),
        false,
      );
    });

    test('DailyMissionNotifier getCompletedMissions', () async {
      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(dailyMissionProvider.notifier).completeMission(
        'daily_quiz_5',
      );

      final notifier = container.read(dailyMissionProvider.notifier);
      final completedMissions = notifier.getCompletedMissions();

      expect(
        completedMissions.every((m) => m.mission.isCompleted),
        true,
      );
      expect(
        completedMissions.any((m) => m.mission.id == 'daily_quiz_5'),
        true,
      );
    });

    test('DailyMissionNotifier generates new missions on new day', () async {
      SharedPreferences.setMockInitialValues({
        'last_generated_date': '2026-08-31T12:00:00.000Z',
      });

      final container = ProviderContainer();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(dailyMissionProvider);
      expect(state.lastGeneratedDate, isNotNull);
      // Should be today's date
      final now = DateTime.now();
      expect(state.lastGeneratedDate!.year, now.year);
      expect(state.lastGeneratedDate!.month, now.month);
      expect(state.lastGeneratedDate!.day, now.day);
    });
  });

  group('DailyMissionProgress Tests', () {
    test('DailyMissionProgress toString', () {
      final mission = DailyMission(
        id: 'test',
        title: 'Test Mission',
        description: 'Test',
        emoji: '🎯',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.normal,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      final progress = DailyMissionProgress(
        mission: mission,
        currentValue: 7,
        progress: 70.0,
      );

      expect(progress.toString(), contains('Test Mission'));
      expect(progress.toString(), contains('7/10'));
    });
  });
}
