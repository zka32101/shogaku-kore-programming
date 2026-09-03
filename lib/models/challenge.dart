import 'learning_analytics.dart';

/// クイズの質問
class Question {
  final String id;
  final String text;
  final String? codeSnippet;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? hint; // ヒント（任意）

  const Question({
    required this.id,
    required this.text,
    this.codeSnippet,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.hint,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'codeSnippet': codeSnippet,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'hint': hint,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        text: json['text'] as String,
        codeSnippet: json['codeSnippet'] as String?,
        options: List<String>.from(json['options'] as List),
        correctIndex: json['correctIndex'] as int,
        explanation: json['explanation'] as String,
        hint: json['hint'] as String?,
      );
}

/// チャレンジの種類
enum ChallengeType {
  daily,      // 日次チャレンジ
  weekly,     // 週間クエスト
  monthly,    // 月間チャレンジ
  special,    // 特別イベント
}

/// チャレンジの難易度
enum ChallengeDifficulty {
  easy,       // 簡単
  medium,     // 普通
  hard,       // 難しい
  expert,     // エキスパート
}

/// チャレンジの状態
enum ChallengeStatus {
  available,  // 利用可能
  inProgress, // 進行中
  completed,  // 完了
  failed,     // 失敗
  expired,    // 期限切れ
}

/// チャレンジの条件
class ChallengeCondition {
  final String conditionId;
  final String description;
  final int requiredAmount; // 達成に必要な数値
  final LearningCategory? category; // カテゴリ制限
  final String? metadata; // 追加情報（JSON文字列）

  ChallengeCondition({
    required this.conditionId,
    required this.description,
    required this.requiredAmount,
    this.category,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'conditionId': conditionId,
        'description': description,
        'requiredAmount': requiredAmount,
        'category': category?.name,
        'metadata': metadata,
      };

  factory ChallengeCondition.fromJson(Map<String, dynamic> json) =>
      ChallengeCondition(
        conditionId: json['conditionId'] as String,
        description: json['description'] as String,
        requiredAmount: json['requiredAmount'] as int,
        category: json['category'] != null
            ? LearningCategory.values.byName(json['category'] as String)
            : null,
        metadata: json['metadata'] as String?,
      );
}

/// チャレンジの報酬
class ChallengeReward {
  final int xpAmount;
  final int coinAmount;
  final String? badgeId;
  final Map<String, int> categoryBonusXp; // カテゴリ別XPボーナス

  ChallengeReward({
    required this.xpAmount,
    required this.coinAmount,
    this.badgeId,
    this.categoryBonusXp = const {},
  });

  Map<String, dynamic> toJson() => {
        'xpAmount': xpAmount,
        'coinAmount': coinAmount,
        'badgeId': badgeId,
        'categoryBonusXp': categoryBonusXp,
      };

  factory ChallengeReward.fromJson(Map<String, dynamic> json) =>
      ChallengeReward(
        xpAmount: json['xpAmount'] as int,
        coinAmount: json['coinAmount'] as int,
        badgeId: json['badgeId'] as String?,
        categoryBonusXp: ((json['categoryBonusXp'] as Map<String, dynamic>?) ?? {})
            .cast<String, int>(),
      );
}

/// チャレンジ情報
class Challenge {
  final String challengeId;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeCondition condition;
  final ChallengeReward reward;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isActive;
  final bool isFree;

  Challenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.condition,
    required this.reward,
    required this.startedAt,
    required this.expiresAt,
    required this.isActive,
    required this.isFree,
  });

  /// チャレンジが期限切れか判定
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// チャレンジが進行中か判定
  bool get isLive => isActive && !isExpired;

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'title': title,
        'description': description,
        'type': type.name,
        'difficulty': difficulty.name,
        'condition': condition.toJson(),
        'reward': reward.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive,
        'isFree': isFree,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        challengeId: json['challengeId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: ChallengeType.values.byName(json['type'] as String),
        difficulty:
            ChallengeDifficulty.values.byName(json['difficulty'] as String),
        condition: ChallengeCondition.fromJson(
            json['condition'] as Map<String, dynamic>),
        reward:
            ChallengeReward.fromJson(json['reward'] as Map<String, dynamic>),
        startedAt: DateTime.parse(json['startedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isActive: json['isActive'] as bool,
        isFree: json['isFree'] as bool? ?? false,
      );
}

/// ユーザーのチャレンジ進捗
class UserChallengeProgress {
  final String userId;
  final String challengeId;
  final ChallengeStatus status;
  final int currentProgress; // 現在の進捗値
  final DateTime startedAt;
  final DateTime? completedAt;
  final int attemptCount; // 試行回数

  UserChallengeProgress({
    required this.userId,
    required this.challengeId,
    required this.status,
    required this.currentProgress,
    required this.startedAt,
    this.completedAt,
    required this.attemptCount,
  });

  /// 完了率を取得（0.0～1.0）
  double getProgressPercentage(int required) =>
      (currentProgress / required).clamp(0.0, 1.0);

  /// チャレンジが完了したか判定
  bool get isCompleted => status == ChallengeStatus.completed;

  /// チャレンジが失敗したか判定
  bool get isFailed => status == ChallengeStatus.failed;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'challengeId': challengeId,
        'status': status.name,
        'currentProgress': currentProgress,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'attemptCount': attemptCount,
      };

  factory UserChallengeProgress.fromJson(Map<String, dynamic> json) =>
      UserChallengeProgress(
        userId: json['userId'] as String,
        challengeId: json['challengeId'] as String,
        status: ChallengeStatus.values.byName(json['status'] as String),
        currentProgress: json['currentProgress'] as int,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        attemptCount: json['attemptCount'] as int,
      );
}

/// チャレンジの完了報酬
class ChallengeCompletion {
  final String completionId;
  final String userId;
  final String challengeId;
  final int earnedXp;
  final int earnedCoins;
  final DateTime completedAt;
  final bool isBonusUnlocked; // ボーナス達成

  ChallengeCompletion({
    required this.completionId,
    required this.userId,
    required this.challengeId,
    required this.earnedXp,
    required this.earnedCoins,
    required this.completedAt,
    required this.isBonusUnlocked,
  });

  Map<String, dynamic> toJson() => {
        'completionId': completionId,
        'userId': userId,
        'challengeId': challengeId,
        'earnedXp': earnedXp,
        'earnedCoins': earnedCoins,
        'completedAt': completedAt.toIso8601String(),
        'isBonusUnlocked': isBonusUnlocked,
      };

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) =>
      ChallengeCompletion(
        completionId: json['completionId'] as String,
        userId: json['userId'] as String,
        challengeId: json['challengeId'] as String,
        earnedXp: json['earnedXp'] as int,
        earnedCoins: json['earnedCoins'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        isBonusUnlocked: json['isBonusUnlocked'] as bool,
      );
}

/// 連続挑戦ストリーク
class ChallengeStreak {
  final String userId;
  final ChallengeType type;
  final int currentStreak; // 現在のストリーク数
  final int longestStreak; // 最長ストリーク
  final DateTime? lastCompletedDate; // 最後に完了した日時
  final DateTime resetDate; // リセット予定日時

  ChallengeStreak({
    required this.userId,
    required this.type,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
    required this.resetDate,
  });

  /// ストリークが維持されているか判定
  bool get isStreakActive {
    if (lastCompletedDate == null) return false;
    final daysSinceCompletion =
        DateTime.now().difference(lastCompletedDate!).inDays;
    return daysSinceCompletion <= 1;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'type': type.name,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
        'resetDate': resetDate.toIso8601String(),
      };

  factory ChallengeStreak.fromJson(Map<String, dynamic> json) =>
      ChallengeStreak(
        userId: json['userId'] as String,
        type: ChallengeType.values.byName(json['type'] as String),
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.parse(json['lastCompletedDate'] as String)
            : null,
        resetDate: DateTime.parse(json['resetDate'] as String),
      );
}

/// チャレンジデータ集約
class ChallengeData {
  final List<Challenge> availableChallenges;
  final List<UserChallengeProgress> userProgress;
  final Map<ChallengeType, ChallengeStreak> streaks;
  final List<ChallengeCompletion> recentCompletions;
  final DateTime generatedAt;

  ChallengeData({
    required this.availableChallenges,
    required this.userProgress,
    required this.streaks,
    required this.recentCompletions,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'availableChallenges': availableChallenges
            .map((e) => e.toJson())
            .toList(),
        'userProgress': userProgress
            .map((e) => e.toJson())
            .toList(),
        'streaks': streaks.map(
          (k, v) => MapEntry(k.name, v.toJson()),
        ),
        'recentCompletions': recentCompletions
            .map((e) => e.toJson())
            .toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ChallengeData.fromJson(Map<String, dynamic> json) => ChallengeData(
        availableChallenges: ((json['availableChallenges'] as List?) ?? [])
            .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
            .toList(),
        userProgress: ((json['userProgress'] as List?) ?? [])
            .map((e) => UserChallengeProgress.fromJson(
                e as Map<String, dynamic>))
            .toList(),
        streaks: ((json['streaks'] as Map<String, dynamic>?) ?? {})
            .map(
              (k, v) => MapEntry(
                ChallengeType.values.byName(k),
                ChallengeStreak.fromJson(v as Map<String, dynamic>),
              ),
            ),
        recentCompletions: ((json['recentCompletions'] as List?) ?? [])
            .map((e) => ChallengeCompletion.fromJson(
                e as Map<String, dynamic>))
            .toList(),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
