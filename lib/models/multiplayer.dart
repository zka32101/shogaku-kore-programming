/// マルチプレイヤーシステムのモデル定義
library multiplayer;

import 'learning_analytics.dart';

/// マルチプレイヤーユーザープロファイル
class MultiplayerUserProfile {
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final int level;
  final int totalXp;
  final double averageAccuracy;
  final int matchesWon;
  final int matchesPlayed;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isOnline;
  final bool isBlocked;

  MultiplayerUserProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    required this.level,
    required this.totalXp,
    required this.averageAccuracy,
    required this.matchesWon,
    required this.matchesPlayed,
    required this.currentStreak,
    required this.longestStreak,
    required this.createdAt,
    this.lastActiveAt,
    this.isOnline = false,
    this.isBlocked = false,
  });

  /// 勝率を計算
  double get winRate {
    if (matchesPlayed == 0) return 0.0;
    return (matchesWon / matchesPlayed * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'displayName': displayName,
    'profileImageUrl': profileImageUrl,
    'level': level,
    'totalXp': totalXp,
    'averageAccuracy': averageAccuracy,
    'matchesWon': matchesWon,
    'matchesPlayed': matchesPlayed,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt?.toIso8601String(),
    'isOnline': isOnline,
    'isBlocked': isBlocked,
  };

  factory MultiplayerUserProfile.fromJson(Map<String, dynamic> json) =>
      MultiplayerUserProfile(
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        level: json['level'] as int? ?? 1,
        totalXp: json['totalXp'] as int? ?? 0,
        averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
        matchesWon: json['matchesWon'] as int? ?? 0,
        matchesPlayed: json['matchesPlayed'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'] as String)
            : null,
        isOnline: json['isOnline'] as bool? ?? false,
        isBlocked: json['isBlocked'] as bool? ?? false,
      );
}

/// フレンド関係
class Friend {
  final String friendId;
  final String userId;
  final String friendUserId;
  final MultiplayerUserProfile friendProfile;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  Friend({
    required this.friendId,
    required this.userId,
    required this.friendUserId,
    required this.friendProfile,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  bool get isConfirmed => status == FriendshipStatus.confirmed;
  bool get isPending => status == FriendshipStatus.pending;

  Map<String, dynamic> toJson() => {
    'friendId': friendId,
    'userId': userId,
    'friendUserId': friendUserId,
    'friendProfile': friendProfile.toJson(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'acceptedAt': acceptedAt?.toIso8601String(),
  };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    friendId: json['friendId'] as String,
    userId: json['userId'] as String,
    friendUserId: json['friendUserId'] as String,
    friendProfile: MultiplayerUserProfile.fromJson(
      json['friendProfile'] as Map<String, dynamic>,
    ),
    status: FriendshipStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    acceptedAt: json['acceptedAt'] != null
        ? DateTime.parse(json['acceptedAt'] as String)
        : null,
  );
}

/// マッチ結果
class MatchResult {
  final String matchId;
  final String playerId;
  final int score;
  final double accuracy;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpentSeconds;
  final int xpEarned;
  final int coinsEarned;
  final int ranking; // 順位
  final bool isWinner;
  final DateTime completedAt;

  MatchResult({
    required this.matchId,
    required this.playerId,
    required this.score,
    required this.accuracy,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.xpEarned,
    required this.coinsEarned,
    required this.ranking,
    required this.isWinner,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'playerId': playerId,
    'score': score,
    'accuracy': accuracy,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'timeSpentSeconds': timeSpentSeconds,
    'xpEarned': xpEarned,
    'coinsEarned': coinsEarned,
    'ranking': ranking,
    'isWinner': isWinner,
    'completedAt': completedAt.toIso8601String(),
  };

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
    matchId: json['matchId'] as String,
    playerId: json['playerId'] as String,
    score: json['score'] as int,
    accuracy: (json['accuracy'] as num).toDouble(),
    correctAnswers: json['correctAnswers'] as int,
    totalQuestions: json['totalQuestions'] as int,
    timeSpentSeconds: json['timeSpentSeconds'] as int,
    xpEarned: json['xpEarned'] as int,
    coinsEarned: json['coinsEarned'] as int,
    ranking: json['ranking'] as int,
    isWinner: json['isWinner'] as bool,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}

/// マルチプレイヤーマッチ
class MultiplayerMatch {
  final String matchId;
  final String hostUserId;
  final List<String> playerUserIds;
  final MultiplayerGameMode gameMode;
  final MatchStatus status;
  final LearningCategory category;
  final int totalQuestions;
  final int questionIndex; // 現在の問題番号
  final Map<String, int> playerScores; // 各プレイヤーのスコア
  final Map<String, MatchResult>? results; // マッチ完了後の結果
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int timeoutSeconds; // マッチのタイムアウト時間

  MultiplayerMatch({
    required this.matchId,
    required this.hostUserId,
    required this.playerUserIds,
    required this.gameMode,
    required this.status,
    required this.category,
    required this.totalQuestions,
    this.questionIndex = 0,
    required this.playerScores,
    this.results,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.timeoutSeconds = 3600,
  });

  /// ゲームが進行中か判定
  bool get isActive => status == MatchStatus.inProgress;

  /// ゲームが完了したか判定
  bool get isCompleted => status == MatchStatus.completed;

  /// 進捗率を計算
  double get progressPercentage {
    if (totalQuestions == 0) return 0.0;
    return (questionIndex / totalQuestions * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'hostUserId': hostUserId,
    'playerUserIds': playerUserIds,
    'gameMode': gameMode.name,
    'status': status.name,
    'category': category.name,
    'totalQuestions': totalQuestions,
    'questionIndex': questionIndex,
    'playerScores': playerScores,
    'results': results?.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'timeoutSeconds': timeoutSeconds,
  };

  factory MultiplayerMatch.fromJson(Map<String, dynamic> json) =>
      MultiplayerMatch(
        matchId: json['matchId'] as String,
        hostUserId: json['hostUserId'] as String,
        playerUserIds: List<String>.from(json['playerUserIds'] as List),
        gameMode:
            MultiplayerGameMode.values.byName(json['gameMode'] as String),
        status: MatchStatus.values.byName(json['status'] as String),
        category: LearningCategory.values.byName(json['category'] as String),
        totalQuestions: json['totalQuestions'] as int,
        questionIndex: json['questionIndex'] as int? ?? 0,
        playerScores: Map<String, int>.from(json['playerScores'] as Map),
        results: json['results'] != null
            ? Map<String, MatchResult>.from(
              (json['results'] as Map).map(
                (k, v) => MapEntry(
                  k as String,
                  MatchResult.fromJson(v as Map<String, dynamic>),
                ),
              ),
            )
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        timeoutSeconds: json['timeoutSeconds'] as int? ?? 3600,
      );
}

/// リーダーボードエントリ
class LeaderboardEntry {
  final int rank;
  final MultiplayerUserProfile userProfile;
  final int score;
  final double accuracy;
  final int matchesWon;
  final double winRate;
  final int currentStreak;

  LeaderboardEntry({
    required this.rank,
    required this.userProfile,
    required this.score,
    required this.accuracy,
    required this.matchesWon,
    required this.winRate,
    required this.currentStreak,
  });

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'userProfile': userProfile.toJson(),
    'score': score,
    'accuracy': accuracy,
    'matchesWon': matchesWon,
    'winRate': winRate,
    'currentStreak': currentStreak,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int,
        userProfile: MultiplayerUserProfile.fromJson(
          json['userProfile'] as Map<String, dynamic>,
        ),
        score: json['score'] as int,
        accuracy: (json['accuracy'] as num).toDouble(),
        matchesWon: json['matchesWon'] as int,
        winRate: (json['winRate'] as num).toDouble(),
        currentStreak: json['currentStreak'] as int,
      );
}

/// ライブ通知
class LiveNotification {
  final String notificationId;
  final String userId;
  final LiveNotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // 追加データ
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  LiveNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
  });

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'userId': userId,
    'type': type.name,
    'title': title,
    'message': message,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'readAt': readAt?.toIso8601String(),
  };

  factory LiveNotification.fromJson(Map<String, dynamic> json) =>
      LiveNotification(
        notificationId: json['notificationId'] as String,
        userId: json['userId'] as String,
        type: LiveNotificationType.values
            .byName(json['type'] as String),
        title: json['title'] as String,
        message: json['message'] as String,
        data: json['data'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        readAt: json['readAt'] != null
            ? DateTime.parse(json['readAt'] as String)
            : null,
      );
}

/// マルチプレイヤーゲームモード
enum MultiplayerGameMode {
  headToHead,     // 1対1対戦
  teamBattle,     // チーム対戦
  royalBattle,    // フリーフォーオール
  cooperative,    // 協力プレイ
  challengeMode,  // チャレンジモード
}

/// マッチステータス
enum MatchStatus {
  waitingForPlayers, // プレイヤー待機中
  inProgress,        // 進行中
  completed,         // 完了
  cancelled,         // キャンセル
  paused,            // 一時停止
}

/// フレンドシップステータス
enum FriendshipStatus {
  pending,      // ペンディング
  confirmed,    // 確認済み
  blocked,      // ブロック
}

/// ライブ通知タイプ
enum LiveNotificationType {
  friendRequest,       // フレンドリクエスト
  friendAccepted,      // フレンド承認
  matchInvitation,     // マッチ招待
  matchStarting,       // マッチ開始
  opponentAction,      // 相手のアクション
  matchCompleted,      // マッチ完了
  friendOnline,        // フレンドがオンライン
  achievement,         // アチーブメント
  leaderboardChange,   // ランキング変動
}
