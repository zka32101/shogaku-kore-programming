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
}

class BlockTemplate {
  final String id;
  final String name;
  final String icon;
  final String category;
  final String description;

  const BlockTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.description,
  });
}

class Challenge {
  final String id;
  final int stageNumber;
  final String title;
  final String description;
  final String type; // 'visual' or 'quiz'
  final String level; // '初級', '中級', '上級'
  final String icon;
  final bool isFree;
  final int maxStars;

  /// クイズ開始前に表示する概念説明（任意）
  final String? conceptExplanation;

  // Quiz type
  final List<Question> questions;

  // Visual type
  final List<BlockTemplate> availableBlocks;
  final String expectedOutput;
  final List<String> hints;

  // 自動採点用
  final Map<String, dynamic>? goalCondition;
  // goalCondition の例: {
  //   'goalX': 3.5,
  //   'goalY': 3.5,
  //   'tolerance': 0.5,  // 位置の許容誤差
  //   'expectedAngle': 0, // （任意）最終角度
  //   'angleToleranceDeg': 45, // （任意）角度の許容誤差
  // }

  const Challenge({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.description,
    required this.type,
    required this.level,
    required this.icon,
    required this.isFree,
    this.maxStars = 3,
    this.conceptExplanation,
    this.questions = const [],
    this.availableBlocks = const [],
    this.expectedOutput = '',
    this.hints = const [],
    this.goalCondition,
  });
}

// 進捗データ
class UserProgress {
  final String challengeId;
  final bool isCompleted;
  final int starsEarned;
  final DateTime? completedAt;

  const UserProgress({
    required this.challengeId,
    this.isCompleted = false,
    this.starsEarned = 0,
    this.completedAt,
  });

  UserProgress copyWith({
    bool? isCompleted,
    int? starsEarned,
    DateTime? completedAt,
  }) {
    return UserProgress(
      challengeId: challengeId,
      isCompleted: isCompleted ?? this.isCompleted,
      starsEarned: starsEarned ?? this.starsEarned,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
