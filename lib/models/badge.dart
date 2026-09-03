/// バッジ（達成・功績）モデル
class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeCategory category;
  final BadgeDifficulty difficulty;
  final int requiredValue;  // 達成に必要な値（例：正解数、学習時間など）
  final String? hint;       // ユーザーへのヒント
  final DateTime? unlockedAt; // アンロック日時

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.difficulty,
    required this.requiredValue,
    this.hint,
    this.unlockedAt,
  });

  /// バッジがアンロックされているか
  bool get isUnlocked => unlockedAt != null;

  /// コピーメソッド
  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    BadgeCategory? category,
    BadgeDifficulty? difficulty,
    int? requiredValue,
    String? hint,
    DateTime? unlockedAt,
  }) =>
      Badge(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        category: category ?? this.category,
        difficulty: difficulty ?? this.difficulty,
        requiredValue: requiredValue ?? this.requiredValue,
        hint: hint ?? this.hint,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  /// JSON シリアライズ
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'category': category.name,
    'difficulty': difficulty.name,
    'requiredValue': requiredValue,
    'hint': hint,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  /// JSON デシリアライズ
  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    emoji: json['emoji'] as String,
    category: BadgeCategory.values.byName(json['category'] as String),
    difficulty: BadgeDifficulty.values.byName(json['difficulty'] as String),
    requiredValue: json['requiredValue'] as int,
    hint: json['hint'] as String?,
    unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'] as String)
        : null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Badge && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Badge(id: $id, name: $name, isUnlocked: $isUnlocked)';
}

/// バッジカテゴリ
enum BadgeCategory {
  quiz,           // クイズ系
  progress,       // 進捗系
  consistency,    // 継続系
  mastery,        // 習熟系
  social,         // ソーシャル系
  special,        // スペシャル系
}

/// バッジ難易度
enum BadgeDifficulty {
  bronze,         // ブロンズ（簡単）
  silver,         // シルバー（普通）
  gold,           // ゴールド（難しい）
  platinum,       // プラチナ（非常に難しい）
}

/// バッジのプログレス情報
class BadgeProgress {
  final Badge badge;
  final int currentValue;  // 現在の進捗値
  final double progress;   // 進捗率（0.0-1.0）

  const BadgeProgress({
    required this.badge,
    required this.currentValue,
    required this.progress,
  });

  /// アンロックまであと何が必要か
  int get remainingValue => (badge.requiredValue - currentValue).abs();

  /// アンロック可能か
  bool get canUnlock => currentValue >= badge.requiredValue && !badge.isUnlocked;

  @override
  String toString() =>
    'BadgeProgress(${badge.name}: $currentValue/${badge.requiredValue}, $progress%)';
}
