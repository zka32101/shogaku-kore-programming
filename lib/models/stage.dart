/// Programming stage question
class Question {
  final String id;
  final String text;
  final String? codeSnippet;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? hint;

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
