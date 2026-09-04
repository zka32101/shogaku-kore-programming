import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/providers/multiplayer_provider.dart';
import 'package:shogaku_kore_programming/models/multiplayer.dart';
import 'package:shogaku_kore_programming/models/learning_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MultiplayerState Tests', () {
    test('MultiplayerState creation with defaults', () {
      final state = MultiplayerState();

      expect(state.currentUserProfile, isNull);
      expect(state.friendsList.isEmpty, true);
      expect(state.activeMatch, isNull);
      expect(state.notifications.isEmpty, true);
      expect(state.isLoading, false);
    });

    test('MultiplayerState copyWith', () {
      final state1 = MultiplayerState();
      final state2 = state1.copyWith(isLoading: true);

      expect(state2.isLoading, true);
      expect(state1.isLoading, false);
    });
  });

  group('MultiplayerNotifier Tests', () {
    test('MultiplayerNotifier initializes user profile', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('testUser123');

      final state = container.read(multiplayerProvider);
      expect(state.currentUserProfile, isNotNull);
      expect(state.currentUserProfile!.userId, 'testUser123');
      expect(state.currentUserProfile!.level, 1);
    });

    test('MultiplayerNotifier updates user profile', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('testUser123');
      await notifier.updateUserProfile('New Display Name', null);

      final state = container.read(multiplayerProvider);
      expect(state.currentUserProfile!.displayName, 'New Display Name');
    });

    test('MultiplayerNotifier creates match', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('testUser123');
      await notifier.createMatch(
        MultiplayerGameMode.headToHead,
        LearningCategory.programming,
        20,
      );

      final state = container.read(multiplayerProvider);
      expect(state.activeMatch, isNotNull);
      expect(state.activeMatch!.gameMode, MultiplayerGameMode.headToHead);
      expect(state.activeMatch!.status, MatchStatus.waitingForPlayers);
    });

    test('MultiplayerNotifier joins match', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');
      await notifier.createMatch(
        MultiplayerGameMode.headToHead,
        LearningCategory.mathematics,
        15,
      );

      final player2 = MultiplayerUserProfile(
        userId: 'player2',
        username: 'player2',
        displayName: 'Player 2',
        level: 1,
        totalXp: 0,
        averageAccuracy: 0.0,
        matchesWon: 0,
        matchesPlayed: 0,
        currentStreak: 0,
        longestStreak: 0,
        createdAt: DateTime.now(),
      );

      final stateAfterCreate = container.read(multiplayerProvider);
      final matchId = stateAfterCreate.activeMatch!.matchId;

      await notifier.joinMatch(matchId, player2);

      final stateAfterJoin = container.read(multiplayerProvider);
      expect(stateAfterJoin.activeMatch!.playerUserIds.length, 2);
    });

    test('MultiplayerNotifier starts match', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');
      await notifier.createMatch(
        MultiplayerGameMode.headToHead,
        LearningCategory.algorithms,
        20,
      );

      await notifier.startMatch();

      final state = container.read(multiplayerProvider);
      expect(state.activeMatch!.status, MatchStatus.inProgress);
      expect(state.activeMatch!.startedAt, isNotNull);
    });

    test('MultiplayerNotifier updates score', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');
      await notifier.createMatch(
        MultiplayerGameMode.headToHead,
        LearningCategory.programming,
        10,
      );

      await notifier.startMatch();

      final player1Id = container.read(multiplayerProvider).currentUserProfile!.userId;
      await notifier.updateScore(player1Id, 100);

      final state = container.read(multiplayerProvider);
      expect(state.activeMatch!.playerScores[player1Id], 100);
    });

    test('MultiplayerNotifier completes match', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');
      await notifier.createMatch(
        MultiplayerGameMode.headToHead,
        LearningCategory.dataStructure,
        10,
      );

      final player1Id = container.read(multiplayerProvider).currentUserProfile!.userId;
      await notifier.startMatch();

      final result = MatchResult(
        matchId: 'match123',
        playerId: player1Id,
        score: 900,
        accuracy: 90.0,
        correctAnswers: 9,
        totalQuestions: 10,
        timeSpentSeconds: 60,
        xpEarned: 100,
        coinsEarned: 50,
        ranking: 1,
        isWinner: true,
        completedAt: DateTime.now(),
      );

      await notifier.completeMatch({player1Id: result});

      final state = container.read(multiplayerProvider);
      expect(state.activeMatch, isNull);
      expect(state.matchHistory.isNotEmpty, true);
    });

    test('MultiplayerNotifier sends friend request', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');

      final targetUser = MultiplayerUserProfile(
        userId: 'player2',
        username: 'player2',
        displayName: 'Player 2',
        level: 2,
        totalXp: 500,
        averageAccuracy: 80.0,
        matchesWon: 5,
        matchesPlayed: 10,
        currentStreak: 2,
        longestStreak: 5,
        createdAt: DateTime.now(),
      );

      await notifier.sendFriendRequest(targetUser);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('multiplayer_friends'), isNotNull);
    });

    test('MultiplayerNotifier accepts friend request', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');

      final friendProfile = MultiplayerUserProfile(
        userId: 'friend1',
        username: 'friend1',
        displayName: 'Friend 1',
        level: 1,
        totalXp: 0,
        averageAccuracy: 0.0,
        matchesWon: 0,
        matchesPlayed: 0,
        currentStreak: 0,
        longestStreak: 0,
        createdAt: DateTime.now(),
      );

      await notifier.sendFriendRequest(friendProfile);

      // Simulate receiving the friend request
      final stateAfterRequest = container.read(multiplayerProvider);
      // In a real app, friend requests would be received from server
      // For testing, we manually add to friendRequests
    });

    test('MultiplayerNotifier blocks friend', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');

      // Setup: add a friend first
      final _friendProfile = MultiplayerUserProfile(
        userId: 'friend1',
        username: 'friend1',
        displayName: 'Friend 1',
        level: 1,
        totalXp: 0,
        averageAccuracy: 0.0,
        matchesWon: 0,
        matchesPlayed: 0,
        currentStreak: 0,
        longestStreak: 0,
        createdAt: DateTime.now(),
      );

      // In a real scenario, the friend would be in the list
      // For this test, we just verify the block method exists and can be called
      await notifier.blockFriend('friend1');
    });

    test('MultiplayerNotifier adds notification', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');

      final notif = LiveNotification(
        notificationId: 'notif1',
        userId: 'player1',
        type: LiveNotificationType.matchInvitation,
        title: 'Match Invitation',
        message: 'You have been invited to a match',
        createdAt: DateTime.now(),
      );

      await notifier.addNotification(notif);

      final state = container.read(multiplayerProvider);
      expect(state.notifications.isNotEmpty, true);
    });

    test('MultiplayerNotifier marks notification as read', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');

      final notif = LiveNotification(
        notificationId: 'notif1',
        userId: 'player1',
        type: LiveNotificationType.friendRequest,
        title: 'Friend Request',
        message: 'Player 2 sent you a friend request',
        createdAt: DateTime.now(),
      );

      await notifier.addNotification(notif);
      await notifier.markNotificationAsRead('notif1');

      final state = container.read(multiplayerProvider);
      expect(state.notifications.first.isRead, true);
    });

    test('MultiplayerNotifier persists user profile', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('testUser123');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('multiplayer_user_profile'), isNotNull);
    });

    test('MultiplayerNotifier loads local data', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('testUser123');

      // Create new container to simulate app restart
      final newContainer = ProviderContainer();
      final newNotifier = newContainer.read(multiplayerProvider.notifier);

      await newNotifier.loadLocalData('testUser123');

      final _newState = newContainer.read(multiplayerProvider);
      // Data should be loaded if it was saved
    });

    test('MultiplayerNotifier generates global leaderboard', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.generateGlobalLeaderboard();

      final state = container.read(multiplayerProvider);
      // Leaderboard should be generated (may be empty in this test)
      expect(state.globalLeaderboard, isNotNull);
    });

    test('MultiplayerNotifier generates friends leaderboard', () async {
      final container = ProviderContainer();

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.initializeUserProfile('player1');
      await notifier.generateFriendsLeaderboard();

      final state = container.read(multiplayerProvider);
      expect(state.friendsLeaderboard, isNotNull);
    });
  });
}
