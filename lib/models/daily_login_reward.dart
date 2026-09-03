import 'learning_analytics.dart';

/// ログインリワードのレベル（報酬の段階）
enum RewardLevel {
  day1,      // 1日目
  day3,      // 3日連続
  day7,      // 7日連続
  day14,     // 14日連続
  day30,     // 30日連続
  milestone, // マイルストーン達成
}

/// 日次ログインリワード
class DailyLoginReward {
  final String rewardId;
  final RewardLevel level;
  final int xpAmount;
  final int coinAmount;
  final String? badgeId;
  final String description;
  final bool isStreakBonus; // ストリーク継続ボーナスか

  DailyLoginReward({
    required this.rewardId,
    required this.level,
    required this.xpAmount,
    required this.coinAmount,
    this.badgeId,
    required this.description,
    this.isStreakBonus = false,
  });

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'level': level.name,
        'xpAmount': xpAmount,
        'coinAmount': coinAmount,
        'badgeId': badgeId,
        'description': description,
        'isStreakBonus': isStreakBonus,
      };

  factory DailyLoginReward.fromJson(Map<String, dynamic> json) =>
      DailyLoginReward(
        rewardId: json['rewardId'] as String,
        level: RewardLevel.values.byName(json['level'] as String),
        xpAmount: json['xpAmount'] as int,
        coinAmount: json['coinAmount'] as int,
        badgeId: json['badgeId'] as String?,
        description: json['description'] as String,
        isStreakBonus: json['isStreakBonus'] as bool? ?? false,
      );
}

/// ユーザーのログインストリーク情報
class LoginStreak {
  final String userId;
  final int currentStreak; // 現在のストリーク数
  final int longestStreak; // 最長ストリーク
  final DateTime lastLoginDate; // 最後にログインした日
  final DateTime? streakStartDate; // ストリーク開始日
  final List<DateTime> loginHistory; // ログイン履歴（最大90日間）

  LoginStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastLoginDate,
    this.streakStartDate,
    this.loginHistory = const [],
  });

  /// ストリークが有効か（昨日または今日ログインしているか）
  bool get isStreakActive {
    final now = DateTime.now();
    final lastLogin = lastLoginDate;
    final daysDifference = now.difference(lastLogin).inDays;
    return daysDifference <= 1;
  }

  /// 今日ログイン済みか
  bool get isLoggedInToday {
    final now = DateTime.now();
    final lastLogin = lastLoginDate;
    return now.year == lastLogin.year &&
        now.month == lastLogin.month &&
        now.day == lastLogin.day;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastLoginDate': lastLoginDate.toIso8601String(),
        'streakStartDate': streakStartDate?.toIso8601String(),
        'loginHistory':
            loginHistory.map((d) => d.toIso8601String()).toList(),
      };

  factory LoginStreak.fromJson(Map<String, dynamic> json) => LoginStreak(
        userId: json['userId'] as String,
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        lastLoginDate: DateTime.parse(json['lastLoginDate'] as String),
        streakStartDate: json['streakStartDate'] != null
            ? DateTime.parse(json['streakStartDate'] as String)
            : null,
        loginHistory: ((json['loginHistory'] as List?) ?? [])
            .map((d) => DateTime.parse(d as String))
            .toList(),
      );
}

/// 日次ログインリワード受け取り記録
class LoginRewardClaim {
  final String claimId;
  final String userId;
  final String rewardId;
  final RewardLevel level;
  final int xpEarned;
  final int coinEarned;
  final DateTime claimedAt;
  final int streakDayAtClaim; // クレーム時のストリーク日数

  LoginRewardClaim({
    required this.claimId,
    required this.userId,
    required this.rewardId,
    required this.level,
    required this.xpEarned,
    required this.coinEarned,
    required this.claimedAt,
    required this.streakDayAtClaim,
  });

  Map<String, dynamic> toJson() => {
        'claimId': claimId,
        'userId': userId,
        'rewardId': rewardId,
        'level': level.name,
        'xpEarned': xpEarned,
        'coinEarned': coinEarned,
        'claimedAt': claimedAt.toIso8601String(),
        'streakDayAtClaim': streakDayAtClaim,
      };

  factory LoginRewardClaim.fromJson(Map<String, dynamic> json) =>
      LoginRewardClaim(
        claimId: json['claimId'] as String,
        userId: json['userId'] as String,
        rewardId: json['rewardId'] as String,
        level: RewardLevel.values.byName(json['level'] as String),
        xpEarned: json['xpEarned'] as int,
        coinEarned: json['coinEarned'] as int,
        claimedAt: DateTime.parse(json['claimedAt'] as String),
        streakDayAtClaim: json['streakDayAtClaim'] as int,
      );
}

/// 日次ログインリワード統計
class LoginRewardStats {
  final String userId;
  final int totalRewardsClaimed; // 総報酬獲得数
  final int totalXpEarned; // 合計XP獲得
  final int totalCoinEarned; // 合計コイン獲得
  final DateTime? firstLoginDate; // 初ログイン日
  final DateTime lastResetDate; // 最後にストリークがリセットされた日
  final List<LoginRewardClaim> recentClaims; // 最近の報酬（最大30件）

  LoginRewardStats({
    required this.userId,
    required this.totalRewardsClaimed,
    required this.totalXpEarned,
    required this.totalCoinEarned,
    this.firstLoginDate,
    required this.lastResetDate,
    this.recentClaims = const [],
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalRewardsClaimed': totalRewardsClaimed,
        'totalXpEarned': totalXpEarned,
        'totalCoinEarned': totalCoinEarned,
        'firstLoginDate': firstLoginDate?.toIso8601String(),
        'lastResetDate': lastResetDate.toIso8601String(),
        'recentClaims':
            recentClaims.map((c) => c.toJson()).toList(),
      };

  factory LoginRewardStats.fromJson(Map<String, dynamic> json) =>
      LoginRewardStats(
        userId: json['userId'] as String,
        totalRewardsClaimed: json['totalRewardsClaimed'] as int,
        totalXpEarned: json['totalXpEarned'] as int,
        totalCoinEarned: json['totalCoinEarned'] as int,
        firstLoginDate: json['firstLoginDate'] != null
            ? DateTime.parse(json['firstLoginDate'] as String)
            : null,
        lastResetDate: DateTime.parse(json['lastResetDate'] as String),
        recentClaims: ((json['recentClaims'] as List?) ?? [])
            .map((c) => LoginRewardClaim.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

/// 日次ログインリワード集約
class DailyLoginRewardData {
  final List<DailyLoginReward> availableRewards;
  final LoginStreak userStreak;
  final LoginRewardStats stats;
  final DateTime generatedAt;

  DailyLoginRewardData({
    required this.availableRewards,
    required this.userStreak,
    required this.stats,
    required this.generatedAt,
  });

  /// 次に獲得可能なリワードを取得
  DailyLoginReward? getNextReward() {
    final currentDay = userStreak.currentStreak + 1;
    if (currentDay == 1) {
      return availableRewards
          .firstWhere((r) => r.level == RewardLevel.day1, orElse: () => availableRewards.first);
    } else if (currentDay == 3) {
      return availableRewards
          .firstWhere((r) => r.level == RewardLevel.day3, orElse: () => availableRewards[1]);
    } else if (currentDay == 7) {
      return availableRewards
          .firstWhere((r) => r.level == RewardLevel.day7, orElse: () => availableRewards[2]);
    } else if (currentDay == 14) {
      return availableRewards
          .firstWhere((r) => r.level == RewardLevel.day14, orElse: () => availableRewards[3]);
    } else if (currentDay == 30) {
      return availableRewards
          .firstWhere((r) => r.level == RewardLevel.day30, orElse: () => availableRewards[4]);
    }
    return null;
  }

  /// 本日のリワード獲得可否
  bool canClaimToday() => !userStreak.isLoggedInToday;

  Map<String, dynamic> toJson() => {
        'availableRewards':
            availableRewards.map((r) => r.toJson()).toList(),
        'userStreak': userStreak.toJson(),
        'stats': stats.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DailyLoginRewardData.fromJson(Map<String, dynamic> json) =>
      DailyLoginRewardData(
        availableRewards: ((json['availableRewards'] as List?) ?? [])
            .map((r) => DailyLoginReward.fromJson(r as Map<String, dynamic>))
            .toList(),
        userStreak: LoginStreak.fromJson(
            json['userStreak'] as Map<String, dynamic>),
        stats: LoginRewardStats.fromJson(
            json['stats'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
