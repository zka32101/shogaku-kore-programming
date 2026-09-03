import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/multiplayer.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';

void main() {
  group('MultiplayerUserProfile Tests', () {
    test('MultiplayerUserProfile creation with defaults', () {
      final profile = MultiplayerUserProfile(
        userId: 'user123',
        username: 'player1',
        displayName: 'Player 1',
        level: 5,
        totalXp: 1000,
        averageAccuracy: 85.0,
        matchesWon: 8,
        matchesPlayed: 10,
        currentStreak: 3,
        longestStreak: 5,
        createdAt: DateTime.now(),
      );

      expect(profile.userId, 'user123');
      expect(profile.level, 5);
      expect(profile.winRate, 80.0);
    });

    test('MultiplayerUserProfile JSON serialization', () {
      final now = DateTime.now();
      final profile = MultiplayerUserProfile(
        userId: 'user123',
        username: 'player1',
        displayName: 'Player 1',
        profileImageUrl: 'https://example.com/avatar.jpg',
        level: 5,
        totalXp: 1000,
        averageAccuracy: 85.0,
        matchesWon: 8,
        matchesPlayed: 10,
        currentStreak: 3,
        longestStreak: 5,
        createdAt: now,
        isOnline: true,
      );

      final json = profile.toJson();
      final restored = MultiplayerUserProfile.fromJson(json);

      expect(restored.userId, profile.userId);
      expect(restored.level, profile.level);
      expect(restored.winRate, profile.winRate);
    });
  });

  group('Friend Tests', () {
    test('Friend creation with pending status', () {
      final targetProfile = MultiplayerUserProfile(
        userId: 'user456',
        username: 'friend1',
        displayName: 'Friend 1',
        level: 3,
        totalXp: 500,
        averageAccuracy: 75.0,
        matchesWon: 2,
        matchesPlayed: 5,
        currentStreak: 1,
        longestStreak: 2,
        createdAt: DateTime.now(),
      );

      final friend = Friend(
        friendId: 'friend123',
        userId: 'user123',
        friendUserId: 'user456',
        friendProfile: targetProfile,
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(friend.isPending, true);
      expect(friend.isConfirmed, false);
    });

    test('Friend JSON serialization', () {
      final now = DateTime.now();
      final targetProfile = MultiplayerUserProfile(
        userId: 'user456',
        username: 'friend1',
        displayName: 'Friend 1',
        level: 3,
        totalXp: 500,
        averageAccuracy: 75.0,
        matchesWon: 2,
        matchesPlayed: 5,
        currentStreak: 1,
        longestStreak: 2,
        createdAt: now,
      );

      final friend = Friend(
        friendId: 'friend123',
        userId: 'user123',
        friendUserId: 'user456',
        friendProfile: targetProfile,
        status: FriendshipStatus.confirmed,
        createdAt: now,
        acceptedAt: now,
      );

      final json = friend.toJson();
      final restored = Friend.fromJson(json);

      expect(restored.isConfirmed, true);
      expect(restored.friendUserId, 'user456');
    });
  });

  group('MatchResult Tests', () {
    test('MatchResult creation', () {
      final result = MatchResult(
        matchId: 'match123',
        playerId: 'user123',
        score: 850,
        accuracy: 85.0,
        correctAnswers: 17,
        totalQuestions: 20,
        timeSpentSeconds: 120,
        xpEarned: 100,
        coinsEarned: 50,
        ranking: 1,
        isWinner: true,
        completedAt: DateTime.now(),
      );

      expect(result.score, 850);
      expect(result.isWinner, true);
      expect(result.accuracy, 85.0);
    });

    test('MatchResult JSON serialization', () {
      final now = DateTime.now();
      final result = MatchResult(
        matchId: 'match123',
        playerId: 'user123',
        score: 750,
        accuracy: 75.0,
        correctAnswers: 15,
        totalQuestions: 20,
        timeSpentSeconds: 150,
        xpEarned: 75,
        coinsEarned: 40,
        ranking: 2,
        isWinner: false,
        completedAt: now,
      );

      final json = result.toJson();
      final restored = MatchResult.fromJson(json);

      expect(restored.score, result.score);
      expect(restored.isWinner, false);
    });
  });

  group('MultiplayerMatch Tests', () {
    test('MultiplayerMatch creation', () {
      final now = DateTime.now();
      final match = MultiplayerMatch(
        matchId: 'match123',
        hostUserId: 'user123',
        playerUserIds: ['user123', 'user456'],
        gameMode: MultiplayerGameMode.headToHead,
        status: MatchStatus.waitingForPlayers,
        category: LearningCategory.programming,
        totalQuestions: 20,
        playerScores: {'user123': 0, 'user456': 0},
        createdAt: now,
      );

      expect(match.playerUserIds.length, 2);
      expect(match.isActive, false);
      expect(match.progressPercentage, 0.0);
    });

    test('MultiplayerMatch progress calculation', () {
      final now = DateTime.now();
      final match = MultiplayerMatch(
        matchId: 'match123',
        hostUserId: 'user123',
        playerUserIds: ['user123'],
        gameMode: MultiplayerGameMode.headToHead,
        status: MatchStatus.inProgress,
        category: LearningCategory.mathematics,
        totalQuestions: 20,
        questionIndex: 10,
        playerScores: {'user123': 500},
        createdAt: now,
        startedAt: now,
      );

      expect(match.isActive, true);
      expect(match.progressPercentage, 50.0);
    });

    test('MultiplayerMatch JSON serialization', () {
      final now = DateTime.now();
      final match = MultiplayerMatch(
        matchId: 'match123',
        hostUserId: 'user123',
        playerUserIds: ['user123', 'user456'],
        gameMode: MultiplayerGameMode.teamBattle,
        status: MatchStatus.inProgress,
        category: LearningCategory.algorithms,
        totalQuestions: 15,
        questionIndex: 5,
        playerScores: {'user123': 300, 'user456': 250},
        createdAt: now,
        startedAt: now,
      );

      final json = match.toJson();
      final restored = MultiplayerMatch.fromJson(json);

      expect(restored.playerUserIds.length, 2);
      expect(restored.totalQuestions, 15);
      expect(restored.status, MatchStatus.inProgress);
    });
  });

  group('LeaderboardEntry Tests', () {
    test('LeaderboardEntry creation', () {
      final profile = MultiplayerUserProfile(
        userId: 'user123',
        username: 'player1',
        displayName: 'Player 1',
        level: 10,
        totalXp: 5000,
        averageAccuracy: 92.0,
        matchesWon: 45,
        matchesPlayed: 50,
        currentStreak: 8,
        longestStreak: 15,
        createdAt: DateTime.now(),
      );

      final entry = LeaderboardEntry(
        rank: 1,
        userProfile: profile,
        score: 4500,
        accuracy: 92.0,
        matchesWon: 45,
        winRate: 90.0,
        currentStreak: 8,
      );

      expect(entry.rank, 1);
      expect(entry.winRate, 90.0);
    });

    test('LeaderboardEntry JSON serialization', () {
      final now = DateTime.now();
      final profile = MultiplayerUserProfile(
        userId: 'user456',
        username: 'player2',
        displayName: 'Player 2',
        level: 8,
        totalXp: 4000,
        averageAccuracy: 88.0,
        matchesWon: 35,
        matchesPlayed: 45,
        currentStreak: 5,
        longestStreak: 12,
        createdAt: now,
      );

      final entry = LeaderboardEntry(
        rank: 2,
        userProfile: profile,
        score: 3500,
        accuracy: 88.0,
        matchesWon: 35,
        winRate: 77.8,
        currentStreak: 5,
      );

      final json = entry.toJson();
      final restored = LeaderboardEntry.fromJson(json);

      expect(restored.rank, 2);
      expect(restored.userProfile.username, 'player2');
    });
  });

  group('LiveNotification Tests', () {
    test('LiveNotification creation', () {
      final notif = LiveNotification(
        notificationId: 'notif123',
        userId: 'user123',
        type: LiveNotificationType.matchInvitation,
        title: 'Match Invitation',
        message: 'Player 2 invited you to a match',
        createdAt: DateTime.now(),
      );

      expect(notif.isRead, false);
      expect(notif.type, LiveNotificationType.matchInvitation);
    });

    test('LiveNotification JSON serialization', () {
      final now = DateTime.now();
      final notif = LiveNotification(
        notificationId: 'notif123',
        userId: 'user123',
        type: LiveNotificationType.friendOnline,
        title: 'Friend Online',
        message: 'Player 1 is now online',
        data: {'userId': 'user456'},
        createdAt: now,
        isRead: true,
        readAt: now,
      );

      final json = notif.toJson();
      final restored = LiveNotification.fromJson(json);

      expect(restored.isRead, true);
      expect(restored.type, LiveNotificationType.friendOnline);
    });
  });

  group('Enum Tests', () {
    test('MultiplayerGameMode values exist', () {
      expect(MultiplayerGameMode.values.length, 5);
      expect(MultiplayerGameMode.values,
          contains(MultiplayerGameMode.headToHead));
    });

    test('MatchStatus values exist', () {
      expect(MatchStatus.values.length, 5);
      expect(MatchStatus.values, contains(MatchStatus.inProgress));
    });

    test('FriendshipStatus values exist', () {
      expect(FriendshipStatus.values.length, 3);
      expect(FriendshipStatus.values, contains(FriendshipStatus.confirmed));
    });

    test('LiveNotificationType values exist', () {
      expect(LiveNotificationType.values.length, 9);
      expect(LiveNotificationType.values,
          contains(LiveNotificationType.friendRequest));
    });
  });
}
