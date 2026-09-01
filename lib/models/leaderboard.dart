import 'learning_analytics.dart';

/// ランキングの時間単位
enum LeaderboardTimeUnit {
  allTime,    // 全期間
  monthly,    // 月間
  weekly,     // 週間
  daily,      // 日間
}

/// ランキング層
enum RankingTier {
  bronze,     // ブロンズ (順位 1000位以下)
  silver,     // シルバー (順位 100～1000位)
  gold,       // ゴールド (順位 10～100位)
  platinum,   // プラチナ (順位 1～10位)
}

/// ランキング地域
enum LeaderboardRegion {
  global,     // グローバル
  japan,      // 日本
  asia,       // アジア
  other,      // その他
}

/// グローバルランキングエントリ
class GlobalLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final int level;
  final int totalXp;
  final double averageAccuracy;
  final int matchesWon;
  final int matchesPlayed;
  final double winRate;
  final int currentStreak;
  final int longestStreak;
  final RankingTier tier;
  final DateTime lastUpdatedAt;

  GlobalLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    required this.level,
    required this.totalXp,
    required this.averageAccuracy,
    required this.matchesWon,
    required this.matchesPlayed,
    required this.winRate,
    required this.currentStreak,
    required this.longestStreak,
    required this.tier,
    required this.lastUpdatedAt,
  });

  /// ランキング層を計算
  static RankingTier calculateTier(int rank) {
    if (rank <= 10) return RankingTier.platinum;
    if (rank <= 100) return RankingTier.gold;
    if (rank <= 1000) return RankingTier.silver;
    return RankingTier.bronze;
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'userId': userId,
    'username': username,
    'displayName': displayName,
    'profileImageUrl': profileImageUrl,
    'level': level,
    'totalXp': totalXp,
    'averageAccuracy': averageAccuracy,
    'matchesWon': matchesWon,
    'matchesPlayed': matchesPlayed,
    'winRate': winRate,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'tier': tier.name,
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
  };

  factory GlobalLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      GlobalLeaderboardEntry(
        rank: json['rank'] as int,
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        level: json['level'] as int,
        totalXp: json['totalXp'] as int,
        averageAccuracy: (json['averageAccuracy'] as num).toDouble(),
        matchesWon: json['matchesWon'] as int,
        matchesPlayed: json['matchesPlayed'] as int,
        winRate: (json['winRate'] as num).toDouble(),
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        tier: RankingTier.values.byName(json['tier'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// カテゴリ別ランキングエントリ
class CategoryLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final LearningCategory category;
  final double accuracy;
  final int quizzesCompleted;
  final int correctAnswers;
  final DateTime lastUpdatedAt;

  CategoryLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.category,
    required this.accuracy,
    required this.quizzesCompleted,
    required this.correctAnswers,
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'userId': userId,
    'username': username,
    'displayName': displayName,
    'category': category.name,
    'accuracy': accuracy,
    'quizzesCompleted': quizzesCompleted,
    'correctAnswers': correctAnswers,
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
  };

  factory CategoryLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      CategoryLeaderboardEntry(
        rank: json['rank'] as int,
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        category: LearningCategory.values.byName(json['category'] as String),
        accuracy: (json['accuracy'] as num).toDouble(),
        quizzesCompleted: json['quizzesCompleted'] as int,
        correctAnswers: json['correctAnswers'] as int,
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// ランキング変動通知
class RankingChangeNotification {
  final String notificationId;
  final String userId;
  final LeaderboardTimeUnit timeUnit;
  final int previousRank;
  final int currentRank;
  final RankingTier previousTier;
  final RankingTier currentTier;
  final bool isPromotion; // ランクアップ判定
  final DateTime createdAt;
  final bool isRead;

  RankingChangeNotification({
    required this.notificationId,
    required this.userId,
    required this.timeUnit,
    required this.previousRank,
    required this.currentRank,
    required this.previousTier,
    required this.currentTier,
    required this.isPromotion,
    required this.createdAt,
    this.isRead = false,
  });

  /// ランクの変動を計算
  int get rankChange => previousRank - currentRank; // 負の値=下降

  /// 昇進/降格を判定
  bool get isTierPromotion => currentTier.index > previousTier.index;
  bool get isTierDemotion => currentTier.index < previousTier.index;

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'userId': userId,
    'timeUnit': timeUnit.name,
    'previousRank': previousRank,
    'currentRank': currentRank,
    'previousTier': previousTier.name,
    'currentTier': currentTier.name,
    'isPromotion': isPromotion,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  factory RankingChangeNotification.fromJson(Map<String, dynamic> json) =>
      RankingChangeNotification(
        notificationId: json['notificationId'] as String,
        userId: json['userId'] as String,
        timeUnit: LeaderboardTimeUnit.values.byName(json['timeUnit'] as String),
        previousRank: json['previousRank'] as int,
        currentRank: json['currentRank'] as int,
        previousTier: RankingTier.values.byName(json['previousTier'] as String),
        currentTier: RankingTier.values.byName(json['currentTier'] as String),
        isPromotion: json['isPromotion'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}

/// ランキング情報
class LeaderboardData {
  final LeaderboardTimeUnit timeUnit;
  final DateTime generatedAt;
  final List<GlobalLeaderboardEntry> globalRankings;
  final Map<LearningCategory, List<CategoryLeaderboardEntry>> categoryRankings;
  final List<RankingChangeNotification> recentChanges;

  LeaderboardData({
    required this.timeUnit,
    required this.generatedAt,
    required this.globalRankings,
    required this.categoryRankings,
    required this.recentChanges,
  });

  Map<String, dynamic> toJson() => {
    'timeUnit': timeUnit.name,
    'generatedAt': generatedAt.toIso8601String(),
    'globalRankings': globalRankings.map((e) => e.toJson()).toList(),
    'categoryRankings': categoryRankings.map(
      (k, v) => MapEntry(k.name, v.map((e) => e.toJson()).toList()),
    ),
    'recentChanges': recentChanges.map((e) => e.toJson()).toList(),
  };

  factory LeaderboardData.fromJson(Map<String, dynamic> json) =>
      LeaderboardData(
        timeUnit: LeaderboardTimeUnit.values.byName(json['timeUnit'] as String),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        globalRankings: ((json['globalRankings'] as List?) ?? [])
            .map((e) => GlobalLeaderboardEntry.fromJson(
              e as Map<String, dynamic>,
            ))
            .toList(),
        categoryRankings:
            ((json['categoryRankings'] as Map<String, dynamic>?) ?? {})
                .map(
              (k, v) => MapEntry(
                LearningCategory.values.byName(k),
                ((v as List?) ?? [])
                    .map((e) => CategoryLeaderboardEntry.fromJson(
                      e as Map<String, dynamic>,
                    ))
                    .toList(),
              ),
            ),
        recentChanges: ((json['recentChanges'] as List?) ?? [])
            .map((e) => RankingChangeNotification.fromJson(
              e as Map<String, dynamic>,
            ))
            .toList(),
      );
}

/// ユーザーのランキング位置情報
class UserRankingPosition {
  final String userId;
  final int globalRank;
  final RankingTier tier;
  final Map<LearningCategory, int> categoryRanks;
  final int previousGlobalRank;
  final DateTime lastUpdatedAt;

  UserRankingPosition({
    required this.userId,
    required this.globalRank,
    required this.tier,
    required this.categoryRanks,
    required this.previousGlobalRank,
    required this.lastUpdatedAt,
  });

  /// ランク上昇判定
  bool get isRankImproved => globalRank < previousGlobalRank;

  /// ランク下降判定
  bool get isRankDeclined => globalRank > previousGlobalRank;

  /// ランク変動なし判定
  bool get isRankUnchanged => globalRank == previousGlobalRank;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'globalRank': globalRank,
    'tier': tier.name,
    'categoryRanks': categoryRanks.map(
      (k, v) => MapEntry(k.name, v),
    ),
    'previousGlobalRank': previousGlobalRank,
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
  };

  factory UserRankingPosition.fromJson(Map<String, dynamic> json) =>
      UserRankingPosition(
        userId: json['userId'] as String,
        globalRank: json['globalRank'] as int,
        tier: RankingTier.values.byName(json['tier'] as String),
        categoryRanks: ((json['categoryRanks'] as Map<String, dynamic>?) ?? {})
            .map(
              (k, v) => MapEntry(
                LearningCategory.values.byName(k),
                v as int,
              ),
            ),
        previousGlobalRank: json['previousGlobalRank'] as int,
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}
