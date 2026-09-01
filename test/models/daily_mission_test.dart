import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/daily_mission.dart';

void main() {
  group('DailyMission Model Tests', () {
    test('DailyMission creation with required parameters', () {
      final mission = DailyMission(
        id: 'test_mission',
        title: 'Test Mission',
        description: 'A test mission',
        emoji: '🎯',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.normal,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      expect(mission.id, 'test_mission');
      expect(mission.title, 'Test Mission');
      expect(mission.description, 'A test mission');
      expect(mission.emoji, '🎯');
      expect(mission.type, MissionType.quiz);
      expect(mission.difficulty, MissionDifficulty.normal);
      expect(mission.targetValue, 10);
      expect(mission.rewardCoins, 100);
      expect(mission.rewardXp, 50);
      expect(mission.rewardBadgeId, null);
      expect(mission.completedAt, null);
    });

    test('DailyMission isCompleted getter', () {
      final incompleteMission = DailyMission(
        id: 'incomplete',
        title: 'Incomplete',
        description: 'Not done',
        emoji: '❌',
        type: MissionType.lesson,
        difficulty: MissionDifficulty.easy,
        targetValue: 5,
        rewardCoins: 50,
        rewardXp: 25,
      );

      final completedMission = DailyMission(
        id: 'completed',
        title: 'Completed',
        description: 'Done',
        emoji: '✅',
        type: MissionType.lesson,
        difficulty: MissionDifficulty.easy,
        targetValue: 5,
        rewardCoins: 50,
        rewardXp: 25,
        completedAt: DateTime.now(),
      );

      expect(incompleteMission.isCompleted, false);
      expect(completedMission.isCompleted, true);
    });

    test('DailyMission copyWith', () {
      final original = DailyMission(
        id: 'original',
        title: 'Original',
        description: 'Original description',
        emoji: '⭐',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.easy,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      final now = DateTime.now();
      final copied = original.copyWith(
        title: 'Modified',
        difficulty: MissionDifficulty.hard,
        completedAt: now,
      );

      expect(copied.id, 'original');
      expect(copied.title, 'Modified');
      expect(copied.description, 'Original description');
      expect(copied.emoji, '⭐');
      expect(copied.type, MissionType.quiz);
      expect(copied.difficulty, MissionDifficulty.hard);
      expect(copied.targetValue, 10);
      expect(copied.rewardCoins, 100);
      expect(copied.rewardXp, 50);
      expect(copied.completedAt, now);
    });

    test('DailyMission JSON serialization', () {
      final mission = DailyMission(
        id: 'json_test',
        title: 'JSON Test',
        description: 'Testing JSON serialization',
        emoji: '📝',
        type: MissionType.accuracy,
        difficulty: MissionDifficulty.hard,
        targetValue: 25,
        rewardCoins: 250,
        rewardXp: 100,
        rewardBadgeId: 'accuracy_badge',
      );

      final json = mission.toJson();

      expect(json['id'], 'json_test');
      expect(json['title'], 'JSON Test');
      expect(json['description'], 'Testing JSON serialization');
      expect(json['emoji'], '📝');
      expect(json['type'], 'accuracy');
      expect(json['difficulty'], 'hard');
      expect(json['targetValue'], 25);
      expect(json['rewardCoins'], 250);
      expect(json['rewardXp'], 100);
      expect(json['rewardBadgeId'], 'accuracy_badge');
      expect(json['completedAt'], null);
    });

    test('DailyMission JSON deserialization', () {
      final json = {
        'id': 'deserialized',
        'title': 'Deserialized Mission',
        'description': 'Deserialized from JSON',
        'emoji': '🎉',
        'type': 'quiz',
        'difficulty': 'extreme',
        'targetValue': 50,
        'rewardCoins': 500,
        'rewardXp': 250,
        'rewardBadgeId': null,
        'completedAt': null,
      };

      final mission = DailyMission.fromJson(json);

      expect(mission.id, 'deserialized');
      expect(mission.title, 'Deserialized Mission');
      expect(mission.description, 'Deserialized from JSON');
      expect(mission.emoji, '🎉');
      expect(mission.type, MissionType.quiz);
      expect(mission.difficulty, MissionDifficulty.extreme);
      expect(mission.targetValue, 50);
      expect(mission.rewardCoins, 500);
      expect(mission.rewardXp, 250);
      expect(mission.rewardBadgeId, null);
      expect(mission.completedAt, null);
    });

    test('DailyMission equality', () {
      final mission1 = DailyMission(
        id: 'same_id',
        title: 'Mission 1',
        description: 'Description 1',
        emoji: '⭐',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.easy,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      final mission2 = DailyMission(
        id: 'same_id',
        title: 'Mission 2',
        description: 'Description 2',
        emoji: '✨',
        type: MissionType.lesson,
        difficulty: MissionDifficulty.hard,
        targetValue: 20,
        rewardCoins: 200,
        rewardXp: 100,
      );

      final mission3 = DailyMission(
        id: 'different_id',
        title: 'Mission 1',
        description: 'Description 1',
        emoji: '⭐',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.easy,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      expect(mission1, mission2); // Same ID
      expect(mission1, isNot(mission3)); // Different ID
    });
  });

  group('MissionType Enum Tests', () {
    test('MissionType values', () {
      expect(MissionType.values.length, 6);
      expect(MissionType.values, contains(MissionType.quiz));
      expect(MissionType.values, contains(MissionType.lesson));
      expect(MissionType.values, contains(MissionType.streak));
      expect(MissionType.values, contains(MissionType.accuracy));
      expect(MissionType.values, contains(MissionType.timeSpent));
      expect(MissionType.values, contains(MissionType.socialShare));
    });

    test('MissionType name property', () {
      expect(MissionType.quiz.name, 'quiz');
      expect(MissionType.lesson.name, 'lesson');
      expect(MissionType.streak.name, 'streak');
    });
  });

  group('MissionDifficulty Enum Tests', () {
    test('MissionDifficulty values', () {
      expect(MissionDifficulty.values.length, 4);
      expect(MissionDifficulty.values, contains(MissionDifficulty.easy));
      expect(MissionDifficulty.values, contains(MissionDifficulty.normal));
      expect(MissionDifficulty.values, contains(MissionDifficulty.hard));
      expect(MissionDifficulty.values, contains(MissionDifficulty.extreme));
    });
  });

  group('DailyMissionProgress Tests', () {
    test('DailyMissionProgress creation', () {
      final mission = DailyMission(
        id: 'test',
        title: 'Test',
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

      expect(progress.mission.id, 'test');
      expect(progress.currentValue, 7);
      expect(progress.progress, 70.0);
    });

    test('DailyMissionProgress remainingValue', () {
      final mission = DailyMission(
        id: 'test',
        title: 'Test',
        description: 'Test',
        emoji: '🎯',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.normal,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      final progress1 = DailyMissionProgress(
        mission: mission,
        currentValue: 7,
        progress: 70.0,
      );

      final progress2 = DailyMissionProgress(
        mission: mission,
        currentValue: 12,
        progress: 100.0,
      );

      expect(progress1.remainingValue, 3);
      expect(progress2.remainingValue, 2);
    });

    test('DailyMissionProgress canComplete', () {
      final mission = DailyMission(
        id: 'test',
        title: 'Test',
        description: 'Test',
        emoji: '🎯',
        type: MissionType.quiz,
        difficulty: MissionDifficulty.normal,
        targetValue: 10,
        rewardCoins: 100,
        rewardXp: 50,
      );

      final notReady = DailyMissionProgress(
        mission: mission,
        currentValue: 5,
        progress: 50.0,
      );

      final ready = DailyMissionProgress(
        mission: mission,
        currentValue: 10,
        progress: 100.0,
      );

      final completed = DailyMissionProgress(
        mission: mission.copyWith(completedAt: DateTime.now()),
        currentValue: 10,
        progress: 100.0,
      );

      expect(notReady.canComplete, false);
      expect(ready.canComplete, true);
      expect(completed.canComplete, false);
    });
  });

  group('DailyMissionSet Tests', () {
    test('DailyMissionSet creation', () {
      final missions = [
        DailyMission(
          id: 'mission1',
          title: 'Mission 1',
          description: 'Test',
          emoji: '🎯',
          type: MissionType.quiz,
          difficulty: MissionDifficulty.easy,
          targetValue: 5,
          rewardCoins: 50,
          rewardXp: 25,
        ),
        DailyMission(
          id: 'mission2',
          title: 'Mission 2',
          description: 'Test',
          emoji: '✅',
          type: MissionType.lesson,
          difficulty: MissionDifficulty.normal,
          targetValue: 3,
          rewardCoins: 75,
          rewardXp: 40,
          completedAt: DateTime.now(),
        ),
      ];

      final missionSet = DailyMissionSet(
        date: DateTime.now(),
        missions: missions,
        totalRewardCoins: 125,
        totalRewardXp: 65,
      );

      expect(missionSet.missions.length, 2);
      expect(missionSet.totalRewardCoins, 125);
      expect(missionSet.totalRewardXp, 65);
      expect(missionSet.completedCount, 1);
      expect(missionSet.completionRate, 0.5);
      expect(missionSet.isAllCompleted, false);
    });

    test('DailyMissionSet isToday', () {
      final today = DateTime.now();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final todaySet = DailyMissionSet(
        date: today,
        missions: [],
        totalRewardCoins: 0,
        totalRewardXp: 0,
      );

      final yesterdaySet = DailyMissionSet(
        date: yesterday,
        missions: [],
        totalRewardCoins: 0,
        totalRewardXp: 0,
      );

      expect(todaySet.isToday, true);
      expect(yesterdaySet.isToday, false);
    });
  });
}
