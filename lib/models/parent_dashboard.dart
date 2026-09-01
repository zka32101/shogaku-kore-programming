/// 保護者ダッシュボードシステムのモデル定義
library parent_dashboard;

import 'learning_analytics.dart';

/// 子どもプロファイル
class ChildProfile {
  final String childId;
  final String childName;
  final int gradeLevel; // 学年
  final DateTime createdAt;
  final String? profileImageUrl;
  final DateTime? lastActiveAt;
  final bool isActive;

  ChildProfile({
    required this.childId,
    required this.childName,
    required this.gradeLevel,
    required this.createdAt,
    this.profileImageUrl,
    this.lastActiveAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'childId': childId,
    'childName': childName,
    'gradeLevel': gradeLevel,
    'createdAt': createdAt.toIso8601String(),
    'profileImageUrl': profileImageUrl,
    'lastActiveAt': lastActiveAt?.toIso8601String(),
    'isActive': isActive,
  };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    childId: json['childId'] as String,
    childName: json['childName'] as String,
    gradeLevel: json['gradeLevel'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    profileImageUrl: json['profileImageUrl'] as String?,
    lastActiveAt: json['lastActiveAt'] != null
        ? DateTime.parse(json['lastActiveAt'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
  );
}

/// 学習の弱点エリア
class WeakArea {
  final LearningCategory category;
  final double accuracy;
  final int attemptCount;
  final String recommendation;

  WeakArea({
    required this.category,
    required this.accuracy,
    required this.attemptCount,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
    'category': category.name,
    'accuracy': accuracy,
    'attemptCount': attemptCount,
    'recommendation': recommendation,
  };

  factory WeakArea.fromJson(Map<String, dynamic> json) => WeakArea(
    category: LearningCategory.values.byName(json['category'] as String),
    accuracy: (json['accuracy'] as num).toDouble(),
    attemptCount: json['attemptCount'] as int,
    recommendation: json['recommendation'] as String,
  );
}

/// 学習時間トレンド
class LearningTimeTrend {
  final DateTime date;
  final Duration timeSpent;
  final int quizzesCompleted;

  LearningTimeTrend({
    required this.date,
    required this.timeSpent,
    required this.quizzesCompleted,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'timeSpent': timeSpent.inSeconds,
    'quizzesCompleted': quizzesCompleted,
  };

  factory LearningTimeTrend.fromJson(Map<String, dynamic> json) => LearningTimeTrend(
    date: DateTime.parse(json['date'] as String),
    timeSpent: Duration(seconds: json['timeSpent'] as int),
    quizzesCompleted: json['quizzesCompleted'] as int,
  );
}

/// 親向けダッシュボード総合データ
class ParentDashboardData {
  final ChildProfile childProfile;
  final OverallLearningProgress learningProgress;
  final List<String> earnedBadgeIds; // バッジID
  final int currentLevel;
  final double levelProgress; // 0.0-100.0
  final int dailyMissionsCompleted;
  final int dailyMissionsTotal;
  final List<WeakArea> weakAreas;
  final List<LearningTimeTrend> recentTrends; // 過去14日間
  final String? generalInsight; // 全体的なインサイト
  final DateTime generatedAt;

  ParentDashboardData({
    required this.childProfile,
    required this.learningProgress,
    required this.earnedBadgeIds,
    required this.currentLevel,
    required this.levelProgress,
    required this.dailyMissionsCompleted,
    required this.dailyMissionsTotal,
    required this.weakAreas,
    required this.recentTrends,
    this.generalInsight,
    required this.generatedAt,
  });

  /// 学習時間（時間単位）
  double get totalLearningHours => learningProgress.totalTimeSpent.inMilliseconds / (1000 * 60 * 60);

  /// 正答率
  double get overallAccuracy => learningProgress.overallAccuracy;

  /// 累積クイズ数
  int get totalQuizzes => learningProgress.totalQuizzesCompleted;

  /// 学習を継続している日数
  int get learningStreak => learningProgress.currentStreak;

  Map<String, dynamic> toJson() => {
    'childProfile': childProfile.toJson(),
    'learningProgress': learningProgress.toJson(),
    'earnedBadgeIds': earnedBadgeIds,
    'currentLevel': currentLevel,
    'levelProgress': levelProgress,
    'dailyMissionsCompleted': dailyMissionsCompleted,
    'dailyMissionsTotal': dailyMissionsTotal,
    'weakAreas': weakAreas.map((w) => w.toJson()).toList(),
    'recentTrends': recentTrends.map((t) => t.toJson()).toList(),
    'generalInsight': generalInsight,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory ParentDashboardData.fromJson(Map<String, dynamic> json) => ParentDashboardData(
    childProfile: ChildProfile.fromJson(json['childProfile'] as Map<String, dynamic>),
    learningProgress: OverallLearningProgress.fromJson(
      json['learningProgress'] as Map<String, dynamic>,
    ),
    earnedBadgeIds: List<String>.from(json['earnedBadgeIds'] as List),
    currentLevel: json['currentLevel'] as int,
    levelProgress: (json['levelProgress'] as num).toDouble(),
    dailyMissionsCompleted: json['dailyMissionsCompleted'] as int,
    dailyMissionsTotal: json['dailyMissionsTotal'] as int,
    weakAreas: ((json['weakAreas'] as List?) ?? [])
        .map((w) => WeakArea.fromJson(w as Map<String, dynamic>))
        .toList(),
    recentTrends: ((json['recentTrends'] as List?) ?? [])
        .map((t) => LearningTimeTrend.fromJson(t as Map<String, dynamic>))
        .toList(),
    generalInsight: json['generalInsight'] as String?,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
  );
}

/// 保護者通知設定
class ParentNotificationSettings {
  final String parentId;
  final String childId;
  final bool dailyReportEnabled;
  final bool weeklyReportEnabled;
  final bool badgeAchievementNotification;
  final bool lowAccuracyAlert; // 正答率低下時のアラート
  final double lowAccuracyThreshold; // 0.0-100.0
  final bool streakBreakAlert; // ストリーク途絶時のアラート
  final bool learningTimeAlert; // 学習時間不足時のアラート
  final int minimumDailyMinutes; // 1日の最小学習時間（分）
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentNotificationSettings({
    required this.parentId,
    required this.childId,
    this.dailyReportEnabled = true,
    this.weeklyReportEnabled = true,
    this.badgeAchievementNotification = true,
    this.lowAccuracyAlert = true,
    this.lowAccuracyThreshold = 70.0,
    this.streakBreakAlert = true,
    this.learningTimeAlert = true,
    this.minimumDailyMinutes = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  ParentNotificationSettings copyWith({
    bool? dailyReportEnabled,
    bool? weeklyReportEnabled,
    bool? badgeAchievementNotification,
    bool? lowAccuracyAlert,
    double? lowAccuracyThreshold,
    bool? streakBreakAlert,
    bool? learningTimeAlert,
    int? minimumDailyMinutes,
  }) {
    return ParentNotificationSettings(
      parentId: parentId,
      childId: childId,
      dailyReportEnabled: dailyReportEnabled ?? this.dailyReportEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      badgeAchievementNotification:
          badgeAchievementNotification ?? this.badgeAchievementNotification,
      lowAccuracyAlert: lowAccuracyAlert ?? this.lowAccuracyAlert,
      lowAccuracyThreshold: lowAccuracyThreshold ?? this.lowAccuracyThreshold,
      streakBreakAlert: streakBreakAlert ?? this.streakBreakAlert,
      learningTimeAlert: learningTimeAlert ?? this.learningTimeAlert,
      minimumDailyMinutes: minimumDailyMinutes ?? this.minimumDailyMinutes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'parentId': parentId,
    'childId': childId,
    'dailyReportEnabled': dailyReportEnabled,
    'weeklyReportEnabled': weeklyReportEnabled,
    'badgeAchievementNotification': badgeAchievementNotification,
    'lowAccuracyAlert': lowAccuracyAlert,
    'lowAccuracyThreshold': lowAccuracyThreshold,
    'streakBreakAlert': streakBreakAlert,
    'learningTimeAlert': learningTimeAlert,
    'minimumDailyMinutes': minimumDailyMinutes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ParentNotificationSettings.fromJson(Map<String, dynamic> json) =>
      ParentNotificationSettings(
        parentId: json['parentId'] as String,
        childId: json['childId'] as String,
        dailyReportEnabled: json['dailyReportEnabled'] as bool? ?? true,
        weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? true,
        badgeAchievementNotification:
            json['badgeAchievementNotification'] as bool? ?? true,
        lowAccuracyAlert: json['lowAccuracyAlert'] as bool? ?? true,
        lowAccuracyThreshold:
            (json['lowAccuracyThreshold'] as num?)?.toDouble() ?? 70.0,
        streakBreakAlert: json['streakBreakAlert'] as bool? ?? true,
        learningTimeAlert: json['learningTimeAlert'] as bool? ?? true,
        minimumDailyMinutes: json['minimumDailyMinutes'] as int? ?? 30,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// 学習目標
class LearningGoal {
  final String goalId;
  final String childId;
  final String title;
  final String description;
  final LearningCategory category;
  final double targetAccuracy; // 0.0-100.0
  final int targetQuizzesCount;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  LearningGoal({
    required this.goalId,
    required this.childId,
    required this.title,
    required this.description,
    required this.category,
    required this.targetAccuracy,
    required this.targetQuizzesCount,
    required this.deadline,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  bool get isOverdue => !isCompleted && DateTime.now().isAfter(deadline);

  int get daysRemaining {
    if (isCompleted) return 0;
    final diff = deadline.difference(DateTime.now());
    return diff.inDays;
  }

  LearningGoal copyWith({
    String? goalId,
    String? childId,
    String? title,
    String? description,
    LearningCategory? category,
    double? targetAccuracy,
    int? targetQuizzesCount,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return LearningGoal(
      goalId: goalId ?? this.goalId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetAccuracy: targetAccuracy ?? this.targetAccuracy,
      targetQuizzesCount: targetQuizzesCount ?? this.targetQuizzesCount,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'childId': childId,
    'title': title,
    'description': description,
    'category': category.name,
    'targetAccuracy': targetAccuracy,
    'targetQuizzesCount': targetQuizzesCount,
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory LearningGoal.fromJson(Map<String, dynamic> json) => LearningGoal(
    goalId: json['goalId'] as String,
    childId: json['childId'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    category: LearningCategory.values.byName(json['category'] as String),
    targetAccuracy: (json['targetAccuracy'] as num).toDouble(),
    targetQuizzesCount: json['targetQuizzesCount'] as int,
    deadline: DateTime.parse(json['deadline'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
}

/// 保護者アラート
class ParentAlert {
  final String alertId;
  final String parentId;
  final String childId;
  final ParentAlertType alertType;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata; // 追加情報

  ParentAlert({
    required this.alertId,
    required this.parentId,
    required this.childId,
    required this.alertType,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'alertId': alertId,
    'parentId': parentId,
    'childId': childId,
    'alertType': alertType.name,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'readAt': readAt?.toIso8601String(),
    'metadata': metadata,
  };

  factory ParentAlert.fromJson(Map<String, dynamic> json) => ParentAlert(
    alertId: json['alertId'] as String,
    parentId: json['parentId'] as String,
    childId: json['childId'] as String,
    alertType:
        ParentAlertType.values.byName(json['alertType'] as String),
    title: json['title'] as String,
    message: json['message'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isRead: json['isRead'] as bool? ?? false,
    readAt: json['readAt'] != null
        ? DateTime.parse(json['readAt'] as String)
        : null,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// 保護者アラートの種類
enum ParentAlertType {
  lowAccuracy, // 正答率低下
  streakBroken, // ストリーク途絶
  goalCompleted, // 目標達成
  badgeEarned, // バッジ獲得
  noActivity, // 学習なし
  levelUp, // レベルアップ
  weeklyReport, // 週間レポート
}
