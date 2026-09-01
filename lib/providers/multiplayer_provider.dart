/// マルチプレイヤー状態管理プロバイダ
library multiplayer_provider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/multiplayer.dart';
import '../models/learning_analytics.dart';

/// マルチプレイヤー状態
class MultiplayerState {
  final MultiplayerUserProfile? currentUserProfile;
  final List<Friend> friendsList;
  final List<Friend> friendRequests;
  final MultiplayerMatch? activeMatch;
  final List<MultiplayerMatch> matchHistory;
  final List<LiveNotification> notifications;
  final List<LeaderboardEntry> globalLeaderboard;
  final List<LeaderboardEntry> friendsLeaderboard;
  final DateTime? lastUpdatedAt;
  final bool isLoading;
  final bool isSearching;

  MultiplayerState({
    this.currentUserProfile,
    this.friendsList = const [],
    this.friendRequests = const [],
    this.activeMatch,
    this.matchHistory = const [],
    this.notifications = const [],
    this.globalLeaderboard = const [],
    this.friendsLeaderboard = const [],
    this.lastUpdatedAt,
    this.isLoading = false,
    this.isSearching = false,
  });

  MultiplayerState copyWith({
    MultiplayerUserProfile? currentUserProfile,
    List<Friend>? friendsList,
    List<Friend>? friendRequests,
    MultiplayerMatch? activeMatch,
    List<MultiplayerMatch>? matchHistory,
    List<LiveNotification>? notifications,
    List<LeaderboardEntry>? globalLeaderboard,
    List<LeaderboardEntry>? friendsLeaderboard,
    DateTime? lastUpdatedAt,
    bool? isLoading,
    bool? isSearching,
  }) {
    return MultiplayerState(
      currentUserProfile: currentUserProfile ?? this.currentUserProfile,
      friendsList: friendsList ?? this.friendsList,
      friendRequests: friendRequests ?? this.friendRequests,
      activeMatch: activeMatch ?? this.activeMatch,
      matchHistory: matchHistory ?? this.matchHistory,
      notifications: notifications ?? this.notifications,
      globalLeaderboard: globalLeaderboard ?? this.globalLeaderboard,
      friendsLeaderboard: friendsLeaderboard ?? this.friendsLeaderboard,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// マルチプレイヤー状態管理クラス
class MultiplayerNotifier extends StateNotifier<MultiplayerState> {
  MultiplayerNotifier() : super(MultiplayerState());

  /// ユーザープロファイルを初期化
  Future<void> initializeUserProfile(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final userProfile = MultiplayerUserProfile(
        userId: userId,
        username: 'Player_$userId',
        displayName: 'Player ${userId.substring(0, 4)}',
        level: 1,
        totalXp: 0,
        averageAccuracy: 0.0,
        matchesWon: 0,
        matchesPlayed: 0,
        currentStreak: 0,
        longestStreak: 0,
        createdAt: DateTime.now(),
        isOnline: true,
      );

      state = state.copyWith(
        currentUserProfile: userProfile,
        isLoading: false,
        lastUpdatedAt: DateTime.now(),
      );

      await _saveUserProfile(userProfile);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// プロフィール情報を更新
  Future<void> updateUserProfile(
    String displayName,
    String? profileImageUrl,
  ) async {
    if (state.currentUserProfile == null) return;

    final updatedProfile = MultiplayerUserProfile(
      userId: state.currentUserProfile!.userId,
      username: state.currentUserProfile!.username,
      displayName: displayName,
      profileImageUrl: profileImageUrl,
      level: state.currentUserProfile!.level,
      totalXp: state.currentUserProfile!.totalXp,
      averageAccuracy: state.currentUserProfile!.averageAccuracy,
      matchesWon: state.currentUserProfile!.matchesWon,
      matchesPlayed: state.currentUserProfile!.matchesPlayed,
      currentStreak: state.currentUserProfile!.currentStreak,
      longestStreak: state.currentUserProfile!.longestStreak,
      createdAt: state.currentUserProfile!.createdAt,
      lastActiveAt: DateTime.now(),
      isOnline: true,
    );

    state = state.copyWith(currentUserProfile: updatedProfile);
    await _saveUserProfile(updatedProfile);
  }

  /// フレンドリクエストを送信
  Future<void> sendFriendRequest(MultiplayerUserProfile targetUser) async {
    if (state.currentUserProfile == null) return;

    final friendRequest = Friend(
      friendId: _generateId('friend'),
      userId: state.currentUserProfile!.userId,
      friendUserId: targetUser.userId,
      friendProfile: targetUser,
      status: FriendshipStatus.pending,
      createdAt: DateTime.now(),
    );

    await _saveFriend(friendRequest);
  }

  /// フレンドリクエストを承認
  Future<void> acceptFriendRequest(String friendId) async {
    final updatedRequests = state.friendRequests.map((req) {
      if (req.friendId == friendId) {
        return Friend(
          friendId: req.friendId,
          userId: req.userId,
          friendUserId: req.friendUserId,
          friendProfile: req.friendProfile,
          status: FriendshipStatus.confirmed,
          createdAt: req.createdAt,
          acceptedAt: DateTime.now(),
        );
      }
      return req;
    }).toList();

    // リクエストをフレンドリストに移動
    final acceptedFriend = updatedRequests.firstWhere((r) => r.friendId == friendId);
    final updatedFriends = [...state.friendsList, acceptedFriend];

    state = state.copyWith(
      friendsList: updatedFriends,
      friendRequests: updatedRequests.where((r) => r.friendId != friendId).toList(),
    );

    await _saveFriends(updatedFriends);
  }

  /// フレンドをブロック
  Future<void> blockFriend(String friendUserId) async {
    final updatedFriends = state.friendsList.map((friend) {
      if (friend.friendUserId == friendUserId) {
        return Friend(
          friendId: friend.friendId,
          userId: friend.userId,
          friendUserId: friend.friendUserId,
          friendProfile: friend.friendProfile.copyWith(isBlocked: true),
          status: FriendshipStatus.blocked,
          createdAt: friend.createdAt,
          acceptedAt: friend.acceptedAt,
        );
      }
      return friend;
    }).toList();

    state = state.copyWith(friendsList: updatedFriends);
    await _saveFriends(updatedFriends);
  }

  /// マッチを作成
  Future<void> createMatch(
    MultiplayerGameMode gameMode,
    LearningCategory category,
    int totalQuestions,
  ) async {
    if (state.currentUserProfile == null) return;

    final match = MultiplayerMatch(
      matchId: _generateId('match'),
      hostUserId: state.currentUserProfile!.userId,
      playerUserIds: [state.currentUserProfile!.userId],
      gameMode: gameMode,
      status: MatchStatus.waitingForPlayers,
      category: category,
      totalQuestions: totalQuestions,
      playerScores: {state.currentUserProfile!.userId: 0},
      createdAt: DateTime.now(),
    );

    state = state.copyWith(activeMatch: match);
    await _saveActiveMatch(match);
  }

  /// マッチに参加
  Future<void> joinMatch(String matchId, MultiplayerUserProfile playerProfile) async {
    if (state.activeMatch == null || state.activeMatch!.matchId != matchId) return;

    final updatedPlayers = [...state.activeMatch!.playerUserIds];
    if (!updatedPlayers.contains(playerProfile.userId)) {
      updatedPlayers.add(playerProfile.userId);
    }

    final updatedScores = {...state.activeMatch!.playerScores};
    updatedScores[playerProfile.userId] = 0;

    final updatedMatch = MultiplayerMatch(
      matchId: state.activeMatch!.matchId,
      hostUserId: state.activeMatch!.hostUserId,
      playerUserIds: updatedPlayers,
      gameMode: state.activeMatch!.gameMode,
      status: state.activeMatch!.status,
      category: state.activeMatch!.category,
      totalQuestions: state.activeMatch!.totalQuestions,
      questionIndex: state.activeMatch!.questionIndex,
      playerScores: updatedScores,
      createdAt: state.activeMatch!.createdAt,
    );

    state = state.copyWith(activeMatch: updatedMatch);
    await _saveActiveMatch(updatedMatch);
  }

  /// マッチを開始
  Future<void> startMatch() async {
    if (state.activeMatch == null) return;

    final updatedMatch = MultiplayerMatch(
      matchId: state.activeMatch!.matchId,
      hostUserId: state.activeMatch!.hostUserId,
      playerUserIds: state.activeMatch!.playerUserIds,
      gameMode: state.activeMatch!.gameMode,
      status: MatchStatus.inProgress,
      category: state.activeMatch!.category,
      totalQuestions: state.activeMatch!.totalQuestions,
      questionIndex: state.activeMatch!.questionIndex,
      playerScores: state.activeMatch!.playerScores,
      createdAt: state.activeMatch!.createdAt,
      startedAt: DateTime.now(),
    );

    state = state.copyWith(activeMatch: updatedMatch);
    await _saveActiveMatch(updatedMatch);
  }

  /// スコアを更新
  Future<void> updateScore(String playerId, int points) async {
    if (state.activeMatch == null) return;

    final updatedScores = {...state.activeMatch!.playerScores};
    updatedScores[playerId] = (updatedScores[playerId] ?? 0) + points;

    final updatedMatch = MultiplayerMatch(
      matchId: state.activeMatch!.matchId,
      hostUserId: state.activeMatch!.hostUserId,
      playerUserIds: state.activeMatch!.playerUserIds,
      gameMode: state.activeMatch!.gameMode,
      status: state.activeMatch!.status,
      category: state.activeMatch!.category,
      totalQuestions: state.activeMatch!.totalQuestions,
      questionIndex: state.activeMatch!.questionIndex + 1,
      playerScores: updatedScores,
      createdAt: state.activeMatch!.createdAt,
      startedAt: state.activeMatch!.startedAt,
    );

    state = state.copyWith(activeMatch: updatedMatch);
    await _saveActiveMatch(updatedMatch);
  }

  /// マッチを完了
  Future<void> completeMatch(Map<String, MatchResult> results) async {
    if (state.activeMatch == null) return;

    final updatedMatch = MultiplayerMatch(
      matchId: state.activeMatch!.matchId,
      hostUserId: state.activeMatch!.hostUserId,
      playerUserIds: state.activeMatch!.playerUserIds,
      gameMode: state.activeMatch!.gameMode,
      status: MatchStatus.completed,
      category: state.activeMatch!.category,
      totalQuestions: state.activeMatch!.totalQuestions,
      questionIndex: state.activeMatch!.totalQuestions,
      playerScores: state.activeMatch!.playerScores,
      results: results,
      createdAt: state.activeMatch!.createdAt,
      startedAt: state.activeMatch!.startedAt,
      endedAt: DateTime.now(),
    );

    // プロファイルを更新
    if (state.currentUserProfile != null && results.containsKey(state.currentUserProfile!.userId)) {
      final result = results[state.currentUserProfile!.userId]!;
      await _updateProfileAfterMatch(result);
    }

    final updatedHistory = [updatedMatch, ...state.matchHistory];
    state = state.copyWith(
      activeMatch: null,
      matchHistory: updatedHistory.take(100).toList(),
    );

    await _saveMatchHistory(updatedHistory);
  }

  /// プロファイルをマッチ後に更新
  Future<void> _updateProfileAfterMatch(MatchResult result) async {
    if (state.currentUserProfile == null) return;

    final currentProfile = state.currentUserProfile!;
    final newMatchesPlayed = currentProfile.matchesPlayed + 1;
    final newMatchesWon = currentProfile.matchesWon + (result.isWinner ? 1 : 0);

    final updatedProfile = MultiplayerUserProfile(
      userId: currentProfile.userId,
      username: currentProfile.username,
      displayName: currentProfile.displayName,
      profileImageUrl: currentProfile.profileImageUrl,
      level: currentProfile.level + (result.xpEarned ~/ 100),
      totalXp: currentProfile.totalXp + result.xpEarned,
      averageAccuracy: result.accuracy,
      matchesWon: newMatchesWon,
      matchesPlayed: newMatchesPlayed,
      currentStreak: result.isWinner ? currentProfile.currentStreak + 1 : 0,
      longestStreak: result.isWinner
          ? max(currentProfile.longestStreak, currentProfile.currentStreak + 1)
          : currentProfile.longestStreak,
      createdAt: currentProfile.createdAt,
      lastActiveAt: DateTime.now(),
      isOnline: true,
    );

    state = state.copyWith(currentUserProfile: updatedProfile);
    await _saveUserProfile(updatedProfile);
  }

  /// グローバルリーダーボードを生成
  Future<void> generateGlobalLeaderboard() async {
    // 実装例：ダミーリーダーボード生成
    final leaderboard = <LeaderboardEntry>[];
    // 実際の実装では、サーバーから取得
    state = state.copyWith(globalLeaderboard: leaderboard);
  }

  /// フレンドリーダーボードを生成
  Future<void> generateFriendsLeaderboard() async {
    if (state.currentUserProfile == null) return;

    final friendsLeaderboard = <LeaderboardEntry>[];
    // 実装例：フレンドのプロファイルからリーダーボード生成

    state = state.copyWith(friendsLeaderboard: friendsLeaderboard);
  }

  /// ライブ通知を追加
  Future<void> addNotification(LiveNotification notification) async {
    final updatedNotifications = [notification, ...state.notifications];
    final limitedNotifications = updatedNotifications.take(100).toList();

    state = state.copyWith(notifications: limitedNotifications);
    await _saveNotifications(limitedNotifications);
  }

  /// 通知を既読にマーク
  Future<void> markNotificationAsRead(String notificationId) async {
    final updatedNotifications = state.notifications.map((notif) {
      if (notif.notificationId == notificationId) {
        return LiveNotification(
          notificationId: notif.notificationId,
          userId: notif.userId,
          type: notif.type,
          title: notif.title,
          message: notif.message,
          data: notif.data,
          createdAt: notif.createdAt,
          isRead: true,
          readAt: DateTime.now(),
        );
      }
      return notif;
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
    await _saveNotifications(updatedNotifications);
  }

  /// ユーザーを検索
  Future<List<MultiplayerUserProfile>> searchUsers(String query) async {
    state = state.copyWith(isSearching: true);

    try {
      // 実装例：ダミー検索結果
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isSearching: false);
      return [];
    } catch (e) {
      state = state.copyWith(isSearching: false);
      rethrow;
    }
  }

  /// ローカルに保存
  Future<void> _saveUserProfile(MultiplayerUserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'multiplayer_user_profile',
        jsonEncode(profile.toJson()),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// フレンドをローカルに保存
  Future<void> _saveFriends(List<Friend> friends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'multiplayer_friends',
        friends.map((f) => jsonEncode(f.toJson())).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// フレンドをローカルに保存（1件）
  Future<void> _saveFriend(Friend friend) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('multiplayer_friends') ?? [];
      existing.add(jsonEncode(friend.toJson()));
      await prefs.setStringList('multiplayer_friends', existing);
    } catch (e) {
      rethrow;
    }
  }

  /// アクティブマッチをローカルに保存
  Future<void> _saveActiveMatch(MultiplayerMatch match) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'multiplayer_active_match',
        jsonEncode(match.toJson()),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// マッチ履歴をローカルに保存
  Future<void> _saveMatchHistory(List<MultiplayerMatch> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'multiplayer_match_history',
        history.map((m) => jsonEncode(m.toJson())).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 通知をローカルに保存
  Future<void> _saveNotifications(List<LiveNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'multiplayer_notifications',
        notifications.map((n) => jsonEncode(n.toJson())).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ローカルデータを読み込み
  Future<void> loadLocalData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ユーザープロファイルを読み込み
      final profileJson = prefs.getString('multiplayer_user_profile');
      final userProfile = profileJson != null
          ? MultiplayerUserProfile.fromJson(jsonDecode(profileJson))
          : null;

      // フレンドを読み込み
      final friendsJson = prefs.getStringList('multiplayer_friends') ?? [];
      final friends =
          friendsJson.map((f) => Friend.fromJson(jsonDecode(f))).toList();

      // マッチ履歴を読み込み
      final historyJson = prefs.getStringList('multiplayer_match_history') ?? [];
      final matchHistory =
          historyJson.map((m) => MultiplayerMatch.fromJson(jsonDecode(m))).toList();

      // 通知を読み込み
      final notifJson = prefs.getStringList('multiplayer_notifications') ?? [];
      final notifications =
          notifJson.map((n) => LiveNotification.fromJson(jsonDecode(n))).toList();

      state = state.copyWith(
        currentUserProfile: userProfile,
        friendsList: friends.where((f) => f.status == FriendshipStatus.confirmed).toList(),
        friendRequests: friends.where((f) => f.status == FriendshipStatus.pending).toList(),
        matchHistory: matchHistory,
        notifications: notifications,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ユニークなIDを生成
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return '${prefix}_${timestamp}_$random';
  }
}

/// マルチプレイヤー状態プロバイダ
final multiplayerProvider =
    StateNotifierProvider<MultiplayerNotifier, MultiplayerState>(
  (ref) => MultiplayerNotifier(),
);

/// 現在のユーザープロファイルプロバイダ
final currentUserProfileProvider = FutureProvider<MultiplayerUserProfile?>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.currentUserProfile;
  },
);

/// フレンドリストプロバイダ
final friendsListProvider = FutureProvider<List<Friend>>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.friendsList;
  },
);

/// フレンドリクエストプロバイダ
final friendRequestsProvider = FutureProvider<List<Friend>>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.friendRequests;
  },
);

/// アクティブマッチプロバイダ
final activeMatchProvider = FutureProvider<MultiplayerMatch?>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.activeMatch;
  },
);

/// マッチ履歴プロバイダ
final matchHistoryProvider = FutureProvider<List<MultiplayerMatch>>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.matchHistory;
  },
);

/// ライブ通知プロバイダ
final liveNotificationsProvider = FutureProvider<List<LiveNotification>>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.notifications;
  },
);

/// 未読通知数プロバイダ
final unreadNotificationsCountProvider = FutureProvider<int>(
  (ref) async {
    final notifications = await ref.watch(liveNotificationsProvider.future);
    return notifications.where((n) => !n.isRead).length;
  },
);

/// グローバルリーダーボードプロバイダ
final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.globalLeaderboard;
  },
);

/// フレンドリーダーボードプロバイダ
final friendsLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>(
  (ref) async {
    final state = ref.watch(multiplayerProvider);
    return state.friendsLeaderboard;
  },
);
