import 'package:flutter/material.dart';

/// School grades in Japan (1-6 elementary school)
enum SchoolGrade {
  firstGrade('1年生', 1),
  secondGrade('2年生', 2),
  thirdGrade('3年生', 3),
  fourthGrade('4年生', 4),
  fifthGrade('5年生', 5),
  sixthGrade('6年生', 6);

  final String displayName;
  final int gradeLevel;

  const SchoolGrade(this.displayName, this.gradeLevel);

  /// Get next grade (returns same grade if already at 6年生)
  SchoolGrade getNextGrade() {
    switch (this) {
      case SchoolGrade.firstGrade:
        return SchoolGrade.secondGrade;
      case SchoolGrade.secondGrade:
        return SchoolGrade.thirdGrade;
      case SchoolGrade.thirdGrade:
        return SchoolGrade.fourthGrade;
      case SchoolGrade.fourthGrade:
        return SchoolGrade.fifthGrade;
      case SchoolGrade.fifthGrade:
        return SchoolGrade.sixthGrade;
      case SchoolGrade.sixthGrade:
        return SchoolGrade.sixthGrade;
    }
  }

  /// Calculate grade from birth year (Japanese school year: April-March)
  static SchoolGrade fromBirthYear(int birthYear) {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    // In Japan, school year changes in April
    // So if current month is April or later, use current year
    // Otherwise use previous year for age calculation
    final schoolYear = currentMonth >= 4 ? currentYear : currentYear - 1;
    final age = schoolYear - birthYear;

    if (age <= 1) return SchoolGrade.firstGrade;
    if (age == 2) return SchoolGrade.secondGrade;
    if (age == 3) return SchoolGrade.thirdGrade;
    if (age == 4) return SchoolGrade.fourthGrade;
    if (age == 5) return SchoolGrade.fifthGrade;
    return SchoolGrade.sixthGrade;
  }
}

/// Ranking metrics
enum RankingMetric {
  totalCoins('総ポイント'),
  activityCompletions('アクティビティ完了数'),
  compositeScore('複合スコア');

  final String displayName;
  const RankingMetric(this.displayName);
}

/// Grouping option for rankings
enum RankingGrouping {
  overall('全体ランキング'),
  byGrade('学年別'),
  byStartMonth('開始月別'),
  combined('複合グループ化');

  final String displayName;
  const RankingGrouping(this.displayName);
}

/// User's current grade and related information
class UserGrade {
  final String userId;
  final SchoolGrade currentGrade;
  final int birthYear;
  final DateTime lastGradeChangeAt;
  final DateTime firstEnrolledAt;
  final bool autoPromoteEnabled;

  const UserGrade({
    required this.userId,
    required this.currentGrade,
    required this.birthYear,
    required this.lastGradeChangeAt,
    required this.firstEnrolledAt,
    this.autoPromoteEnabled = true,
  });

  /// Check if user should be promoted to next grade (April 1st)
  bool shouldPromoteToNextGrade() {
    if (!autoPromoteEnabled || currentGrade == SchoolGrade.sixthGrade) {
      return false;
    }

    final now = DateTime.now();
    final isAprilOrLater = now.month >= 4;

    if (!isAprilOrLater) {
      return false;
    }

    // Check if promotion already happened this year
    final lastPromotionYear = lastGradeChangeAt.year;
    return lastPromotionYear < now.year;
  }

  /// Get promoted grade (returns same grade if already at maximum)
  UserGrade promoteToNextGrade() {
    return UserGrade(
      userId: userId,
      currentGrade: currentGrade.getNextGrade(),
      birthYear: birthYear,
      lastGradeChangeAt: DateTime.now(),
      firstEnrolledAt: firstEnrolledAt,
      autoPromoteEnabled: autoPromoteEnabled,
    );
  }

  UserGrade copyWith({
    String? userId,
    SchoolGrade? currentGrade,
    int? birthYear,
    DateTime? lastGradeChangeAt,
    DateTime? firstEnrolledAt,
    bool? autoPromoteEnabled,
  }) {
    return UserGrade(
      userId: userId ?? this.userId,
      currentGrade: currentGrade ?? this.currentGrade,
      birthYear: birthYear ?? this.birthYear,
      lastGradeChangeAt: lastGradeChangeAt ?? this.lastGradeChangeAt,
      firstEnrolledAt: firstEnrolledAt ?? this.firstEnrolledAt,
      autoPromoteEnabled: autoPromoteEnabled ?? this.autoPromoteEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentGrade': currentGrade.name,
      'birthYear': birthYear,
      'lastGradeChangeAt': lastGradeChangeAt.toIso8601String(),
      'firstEnrolledAt': firstEnrolledAt.toIso8601String(),
      'autoPromoteEnabled': autoPromoteEnabled,
    };
  }

  factory UserGrade.fromJson(Map<String, dynamic> json) {
    return UserGrade(
      userId: json['userId'] as String,
      currentGrade: SchoolGrade.values.byName(json['currentGrade'] as String),
      birthYear: json['birthYear'] as int,
      lastGradeChangeAt: DateTime.parse(json['lastGradeChangeAt'] as String),
      firstEnrolledAt: DateTime.parse(json['firstEnrolledAt'] as String),
      autoPromoteEnabled: json['autoPromoteEnabled'] as bool? ?? true,
    );
  }
}

/// Single ranking entry for a user
class RankingEntry {
  final String rankingEntryId;
  final String userId;
  final String userName;
  final RankingMetric metric;
  final double score;
  final int rankPosition;
  final String tier;
  final DateTime calculatedAt;

  const RankingEntry({
    required this.rankingEntryId,
    required this.userId,
    required this.userName,
    required this.metric,
    required this.score,
    required this.rankPosition,
    required this.tier,
    required this.calculatedAt,
  });

  /// Get tier name based on rank position (日本語)
  static String getTierFromRank(int rank) {
    if (rank == 1) return 'チャンピオン';
    if (rank <= 3) return 'プラチナ';
    if (rank <= 10) return 'ゴールド';
    if (rank <= 50) return 'シルバー';
    if (rank <= 100) return 'ブロンズ';
    return 'ビギナー';
  }

  RankingEntry copyWith({
    String? rankingEntryId,
    String? userId,
    String? userName,
    RankingMetric? metric,
    double? score,
    int? rankPosition,
    String? tier,
    DateTime? calculatedAt,
  }) {
    return RankingEntry(
      rankingEntryId: rankingEntryId ?? this.rankingEntryId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      metric: metric ?? this.metric,
      score: score ?? this.score,
      rankPosition: rankPosition ?? this.rankPosition,
      tier: tier ?? this.tier,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rankingEntryId': rankingEntryId,
      'userId': userId,
      'userName': userName,
      'metric': metric.name,
      'score': score,
      'rankPosition': rankPosition,
      'tier': tier,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rankingEntryId: json['rankingEntryId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      metric: RankingMetric.values.byName(json['metric'] as String),
      score: (json['score'] as num).toDouble(),
      rankPosition: json['rankPosition'] as int,
      tier: json['tier'] as String,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }
}

/// Leaderboard for a specific metric and grouping
class Leaderboard {
  final String leaderboardId;
  final RankingMetric metric;
  final RankingGrouping grouping;
  final String? groupValue; // e.g., "4年生" for byGrade, "2026年1月" for byStartMonth
  final List<RankingEntry> entries;
  final DateTime calculatedAt;
  final DateTime lastUpdatedAt;

  const Leaderboard({
    required this.leaderboardId,
    required this.metric,
    required this.grouping,
    this.groupValue,
    required this.entries,
    required this.calculatedAt,
    required this.lastUpdatedAt,
  });

  /// Get top N entries
  List<RankingEntry> getTopEntries(int count) {
    return entries.take(count).toList();
  }

  /// Find user's rank in this leaderboard
  RankingEntry? getUserRank(String userId) {
    try {
      return entries.firstWhere((e) => e.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Total participants in this leaderboard
  int get totalParticipants => entries.length;

  Leaderboard copyWith({
    String? leaderboardId,
    RankingMetric? metric,
    RankingGrouping? grouping,
    String? groupValue,
    List<RankingEntry>? entries,
    DateTime? calculatedAt,
    DateTime? lastUpdatedAt,
  }) {
    return Leaderboard(
      leaderboardId: leaderboardId ?? this.leaderboardId,
      metric: metric ?? this.metric,
      grouping: grouping ?? this.grouping,
      groupValue: groupValue ?? this.groupValue,
      entries: entries ?? this.entries,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaderboardId': leaderboardId,
      'metric': metric.name,
      'grouping': grouping.name,
      'groupValue': groupValue,
      'entries': entries.map((e) => e.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      leaderboardId: json['leaderboardId'] as String,
      metric: RankingMetric.values.byName(json['metric'] as String),
      grouping: RankingGrouping.values.byName(json['grouping'] as String),
      groupValue: json['groupValue'] as String?,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }
}

/// User's ranking statistics across all metrics
class RankingStatistics {
  final String userId;
  final String userName;
  final SchoolGrade currentGrade;
  final Map<RankingMetric, int> rankPositions; // Rank for each metric
  final Map<RankingMetric, double> scores; // Score for each metric
  final Map<RankingMetric, String> tiers; // Tier for each metric
  final int totalCoinsEarned;
  final int totalActivitiesCompleted;
  final double compositeScore;
  final DateTime firstRankedAt;
  final DateTime lastUpdatedAt;

  const RankingStatistics({
    required this.userId,
    required this.userName,
    required this.currentGrade,
    required this.rankPositions,
    required this.scores,
    required this.tiers,
    required this.totalCoinsEarned,
    required this.totalActivitiesCompleted,
    required this.compositeScore,
    required this.firstRankedAt,
    required this.lastUpdatedAt,
  });

  /// Get best tier across all metrics
  String getBestTier() {
    final tierOrder = {
      'チャンピオン': 1,
      'プラチナ': 2,
      'ゴールド': 3,
      'シルバー': 4,
      'ブロンズ': 5,
      'ビギナー': 6,
    };

    String bestTier = 'ビギナー';
    int bestRank = 7;

    for (final tier in tiers.values) {
      final tierRank = tierOrder[tier] ?? 7;
      if (tierRank < bestRank) {
        bestRank = tierRank;
        bestTier = tier;
      }
    }

    return bestTier;
  }

  /// Get rank across all metrics
  int get overallRank {
    // Average rank across all metrics
    final validRanks = rankPositions.values.where((r) => r > 0);
    if (validRanks.isEmpty) return 0;
    return (validRanks.reduce((a, b) => a + b) / validRanks.length).toInt();
  }

  RankingStatistics copyWith({
    String? userId,
    String? userName,
    SchoolGrade? currentGrade,
    Map<RankingMetric, int>? rankPositions,
    Map<RankingMetric, double>? scores,
    Map<RankingMetric, String>? tiers,
    int? totalCoinsEarned,
    int? totalActivitiesCompleted,
    double? compositeScore,
    DateTime? firstRankedAt,
    DateTime? lastUpdatedAt,
  }) {
    return RankingStatistics(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      currentGrade: currentGrade ?? this.currentGrade,
      rankPositions: rankPositions ?? this.rankPositions,
      scores: scores ?? this.scores,
      tiers: tiers ?? this.tiers,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalActivitiesCompleted: totalActivitiesCompleted ?? this.totalActivitiesCompleted,
      compositeScore: compositeScore ?? this.compositeScore,
      firstRankedAt: firstRankedAt ?? this.firstRankedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'currentGrade': currentGrade.name,
      'rankPositions': {
        for (final entry in rankPositions.entries)
          entry.key.name: entry.value,
      },
      'scores': {
        for (final entry in scores.entries)
          entry.key.name: entry.value,
      },
      'tiers': {
        for (final entry in tiers.entries)
          entry.key.name: entry.value,
      },
      'totalCoinsEarned': totalCoinsEarned,
      'totalActivitiesCompleted': totalActivitiesCompleted,
      'compositeScore': compositeScore,
      'firstRankedAt': firstRankedAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory RankingStatistics.fromJson(Map<String, dynamic> json) {
    return RankingStatistics(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      currentGrade: SchoolGrade.values.byName(json['currentGrade'] as String),
      rankPositions: {
        for (final entry in (json['rankPositions'] as Map<String, dynamic>).entries)
          RankingMetric.values.byName(entry.key): entry.value as int,
      },
      scores: {
        for (final entry in (json['scores'] as Map<String, dynamic>).entries)
          RankingMetric.values.byName(entry.key): (entry.value as num).toDouble(),
      },
      tiers: {
        for (final entry in (json['tiers'] as Map<String, dynamic>).entries)
          RankingMetric.values.byName(entry.key): entry.value as String,
      },
      totalCoinsEarned: json['totalCoinsEarned'] as int,
      totalActivitiesCompleted: json['totalActivitiesCompleted'] as int,
      compositeScore: (json['compositeScore'] as num).toDouble(),
      firstRankedAt: DateTime.parse(json['firstRankedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }
}

/// Master collection of all leaderboards and rankings
class LeaderboardCollection {
  final String userId;
  final UserGrade? userGrade;
  final RankingStatistics? statistics;
  final List<Leaderboard> allLeaderboards; // All rankings for all metrics and groupings
  final List<RankingEntry> userRankings; // User's rankings across all metrics
  final DateTime generatedAt;

  const LeaderboardCollection({
    required this.userId,
    this.userGrade,
    this.statistics,
    required this.allLeaderboards,
    required this.userRankings,
    required this.generatedAt,
  });

  /// Get leaderboard for specific metric and grouping
  Leaderboard? getLeaderboard(RankingMetric metric, RankingGrouping grouping,
      [String? groupValue]) {
    try {
      return allLeaderboards.firstWhere(
        (l) =>
            l.metric == metric &&
            l.grouping == grouping &&
            (groupValue == null || l.groupValue == groupValue),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all leaderboards for a specific metric
  List<Leaderboard> getLeaderboardsByMetric(RankingMetric metric) {
    return allLeaderboards.where((l) => l.metric == metric).toList();
  }

  /// Get user's ranking for specific metric
  RankingEntry? getUserRankingForMetric(RankingMetric metric) {
    try {
      return userRankings.firstWhere((r) => r.metric == metric);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userGrade': userGrade?.toJson(),
      'statistics': statistics?.toJson(),
      'allLeaderboards': allLeaderboards.map((l) => l.toJson()).toList(),
      'userRankings': userRankings.map((r) => r.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory LeaderboardCollection.fromJson(Map<String, dynamic> json) {
    return LeaderboardCollection(
      userId: json['userId'] as String,
      userGrade: json['userGrade'] != null
          ? UserGrade.fromJson(json['userGrade'] as Map<String, dynamic>)
          : null,
      statistics: json['statistics'] != null
          ? RankingStatistics.fromJson(json['statistics'] as Map<String, dynamic>)
          : null,
      allLeaderboards: (json['allLeaderboards'] as List<dynamic>)
          .map((l) => Leaderboard.fromJson(l as Map<String, dynamic>))
          .toList(),
      userRankings: (json['userRankings'] as List<dynamic>)
          .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}
