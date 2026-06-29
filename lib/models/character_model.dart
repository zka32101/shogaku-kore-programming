/// キャラクターの成長段階
enum CharacterStage { egg, baby, child, teen, adult, master }

/// キャラクターのステータス（コード学習で成長）
class CharacterStats {
  final int strength;   // 順序問題の正解数で成長
  final int wisdom;     // if文・ループ問題で成長
  final int speed;      // タイムアタック成績で成長
  final int creativity; // ブロック操作完成で成長

  const CharacterStats({
    this.strength = 0,
    this.wisdom = 0,
    this.speed = 0,
    this.creativity = 0,
  });

  int get total => strength + wisdom + speed + creativity;

  CharacterStats copyWith({
    int? strength,
    int? wisdom,
    int? speed,
    int? creativity,
  }) {
    return CharacterStats(
      strength: strength ?? this.strength,
      wisdom: wisdom ?? this.wisdom,
      speed: speed ?? this.speed,
      creativity: creativity ?? this.creativity,
    );
  }

  Map<String, dynamic> toMap() => {
    'strength': strength,
    'wisdom': wisdom,
    'speed': speed,
    'creativity': creativity,
  };

  factory CharacterStats.fromMap(Map<String, dynamic> map) => CharacterStats(
    strength: (map['strength'] ?? 0) as int,
    wisdom: (map['wisdom'] ?? 0) as int,
    speed: (map['speed'] ?? 0) as int,
    creativity: (map['creativity'] ?? 0) as int,
  );
}

/// キャラクター定義
class CharacterDefinition {
  final String id;
  final String name;
  final String description;
  final Map<CharacterStage, String> stageEmojis;
  final String growthFocus; // 'strength', 'wisdom', 'speed', 'creativity'

  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.stageEmojis,
    required this.growthFocus,
  });
}

/// ユーザーのキャラクター状態
class UserCharacter {
  final String characterId;
  final CharacterStage stage;
  final CharacterStats stats;
  final String name;
  final List<String> unlockedSkills;
  final int totalXp;

  const UserCharacter({
    required this.characterId,
    this.stage = CharacterStage.egg,
    this.stats = const CharacterStats(),
    this.name = 'マイキャラ',
    this.unlockedSkills = const [],
    this.totalXp = 0,
  });

  UserCharacter copyWith({
    String? characterId,
    CharacterStage? stage,
    CharacterStats? stats,
    String? name,
    List<String>? unlockedSkills,
    int? totalXp,
  }) {
    return UserCharacter(
      characterId: characterId ?? this.characterId,
      stage: stage ?? this.stage,
      stats: stats ?? this.stats,
      name: name ?? this.name,
      unlockedSkills: unlockedSkills ?? this.unlockedSkills,
      totalXp: totalXp ?? this.totalXp,
    );
  }

  Map<String, dynamic> toMap() => {
    'characterId': characterId,
    'stage': stage.index,
    'stats': stats.toMap(),
    'name': name,
    'unlockedSkills': unlockedSkills,
    'totalXp': totalXp,
  };

  factory UserCharacter.fromMap(Map<String, dynamic> map) => UserCharacter(
    characterId: map['characterId'] as String? ?? 'coder_cat',
    stage: CharacterStage.values[map['stage'] as int? ?? 0],
    stats: CharacterStats.fromMap(Map<String, dynamic>.from(map['stats'] as Map? ?? {})),
    name: map['name'] as String? ?? 'マイキャラ',
    unlockedSkills: List<String>.from(map['unlockedSkills'] as List? ?? []),
    totalXp: map['totalXp'] as int? ?? 0,
  );
}

/// 利用可能なキャラクター一覧
const kAvailableCharacters = [
  CharacterDefinition(
    id: 'coder_cat',
    name: 'コーダーキャット',
    description: 'プログラミングが大好きな猫。論理的思考が得意！',
    stageEmojis: {
      CharacterStage.egg:    '🥚',
      CharacterStage.baby:   '🐱',
      CharacterStage.child:  '😺',
      CharacterStage.teen:   '🐱‍💻',
      CharacterStage.adult:  '😎',
      CharacterStage.master: '🦁',
    },
    growthFocus: 'wisdom',
  ),
  CharacterDefinition(
    id: 'robot_buddy',
    name: 'ロボットくん',
    description: 'スピードが自慢の機械系キャラ。タイムアタックが得意！',
    stageEmojis: {
      CharacterStage.egg:    '📦',
      CharacterStage.baby:   '🤖',
      CharacterStage.child:  '⚙️',
      CharacterStage.teen:   '🦾',
      CharacterStage.adult:  '🚀',
      CharacterStage.master: '💫',
    },
    growthFocus: 'speed',
  ),
  CharacterDefinition(
    id: 'wizard',
    name: 'コード魔法使い',
    description: 'ブロック操作が魔法のように上手。創造力が高い！',
    stageEmojis: {
      CharacterStage.egg:    '🥚',
      CharacterStage.baby:   '🧙',
      CharacterStage.child:  '✨',
      CharacterStage.teen:   '🌟',
      CharacterStage.adult:  '🔮',
      CharacterStage.master: '🌈',
    },
    growthFocus: 'creativity',
  ),
];

/// ステージごとのXP閾値
const kStageThresholds = {
  CharacterStage.egg:    0,
  CharacterStage.baby:   10,
  CharacterStage.child:  30,
  CharacterStage.teen:   70,
  CharacterStage.adult:  150,
  CharacterStage.master: 300,
};

/// XPに基づくステージを計算
CharacterStage calcStage(int xp) {
  if (xp >= 300) return CharacterStage.master;
  if (xp >= 150) return CharacterStage.adult;
  if (xp >= 70)  return CharacterStage.teen;
  if (xp >= 30)  return CharacterStage.child;
  if (xp >= 10)  return CharacterStage.baby;
  return CharacterStage.egg;
}

/// ステージ名（日本語）
const kStageNames = {
  CharacterStage.egg:    'たまご',
  CharacterStage.baby:   'よちよち',
  CharacterStage.child:  'そだち',
  CharacterStage.teen:   'かんせい',
  CharacterStage.adult:  'ぷろ',
  CharacterStage.master: '伝説',
};
