/// プログラミング専門用語のやさしい解説データ
class GlossaryTerm {
  final String term; // 用語（例: '変数'）
  final String emoji;
  final String friendlyName; // 親しみやすい言い換え
  final String explanation; // やさしい説明
  final String example; // 身近な例え話

  const GlossaryTerm({
    required this.term,
    required this.emoji,
    required this.friendlyName,
    required this.explanation,
    required this.example,
  });
}
