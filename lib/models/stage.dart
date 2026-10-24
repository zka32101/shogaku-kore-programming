/// Programming stage question
class Question {
  final String id;
  final String text;
  final String? codeSnippet;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? hint;

  /// バグハンター形式。true のとき [codeSnippet] の各行が選択肢になり、
  /// [correctIndex] がバグのある行（0始まり）を指す。
  final bool bugHunt;

  const Question({
    required this.id,
    required this.text,
    this.codeSnippet,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.hint,
    this.bugHunt = false,
  });

  /// バグハンター形式の問題。[bugLine] は 1 始まりの行番号（子どもに見える番号）。
  /// 各行を選択肢にするので、採点・星・復習など既存のクイズの仕組みをそのまま使える。
  factory Question.bugHunt({
    required String id,
    required String code,
    required int bugLine,
    required String explanation,
    String text = 'バグ（まちがい）がある行をタップしよう！',
    String? hint,
  }) {
    final lines = code.split('\n');
    assert(bugLine >= 1 && bugLine <= lines.length, 'bugLine is out of range');
    return Question(
      id: id,
      text: text,
      codeSnippet: code,
      options: lines,
      correctIndex: bugLine - 1,
      explanation: explanation,
      hint: hint,
      bugHunt: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'codeSnippet': codeSnippet,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'hint': hint,
        'bugHunt': bugHunt,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        text: json['text'] as String,
        codeSnippet: json['codeSnippet'] as String?,
        options: List<String>.from(json['options'] as List),
        correctIndex: json['correctIndex'] as int,
        explanation: json['explanation'] as String,
        hint: json['hint'] as String?,
        bugHunt: json['bugHunt'] as bool? ?? false,
      );
}

/// Block template for visual programming
class BlockTemplate {
  final String id;
  final String name;
  final String icon;
  final String category;
  final String description;
  final Map<String, dynamic>? properties;

  const BlockTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.description,
    this.properties,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'category': category,
        'description': description,
        'properties': properties,
      };

  factory BlockTemplate.fromJson(Map<String, dynamic> json) => BlockTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        properties: json['properties'] as Map<String, dynamic>?,
      );
}

/// Programming stage/challenge
class Stage {
  final String id;
  final int stageNumber;
  final String title;
  final String description;
  final String type; // 'visual' or 'quiz'
  final String level; // '初級', '中級', '上級'
  final String icon;
  final bool isFree;
  final String? expectedOutput;
  final String? conceptExplanation;
  final List<String>? hints;
  final List<BlockTemplate>? availableBlocks;
  final List<Question>? questions;
  final Map<String, dynamic>? goalCondition;

  const Stage({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.description,
    required this.type,
    required this.level,
    required this.icon,
    required this.isFree,
    this.expectedOutput,
    this.conceptExplanation,
    this.hints,
    this.availableBlocks,
    this.questions,
    this.goalCondition,
  });

  /// Get the maximum number of stars achievable for this stage
  int get maxStars {
    if (type == 'quiz') {
      return questions?.length ?? 0;
    }
    // Visual programming stages typically have 3 stars
    return 3;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageNumber': stageNumber,
        'title': title,
        'description': description,
        'type': type,
        'level': level,
        'icon': icon,
        'isFree': isFree,
        'expectedOutput': expectedOutput,
        'conceptExplanation': conceptExplanation,
        'hints': hints,
        'availableBlocks':
            availableBlocks?.map((e) => e.toJson()).toList(),
        'questions': questions?.map((e) => e.toJson()).toList(),
        'goalCondition': goalCondition,
      };

  factory Stage.fromJson(Map<String, dynamic> json) => Stage(
        id: json['id'] as String,
        stageNumber: json['stageNumber'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        type: json['type'] as String,
        level: json['level'] as String,
        icon: json['icon'] as String,
        isFree: json['isFree'] as bool,
        expectedOutput: json['expectedOutput'] as String?,
        conceptExplanation: json['conceptExplanation'] as String?,
        hints: (json['hints'] as List?)?.cast<String>(),
        availableBlocks: ((json['availableBlocks'] as List?) ?? [])
            .map((e) => BlockTemplate.fromJson(e as Map<String, dynamic>))
            .toList(),
        questions: ((json['questions'] as List?) ?? [])
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
        goalCondition: json['goalCondition'] as Map<String, dynamic>?,
      );
}
