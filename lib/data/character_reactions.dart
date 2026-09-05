/// キャラクターの反応セリフ（親しみやすい言い回し）
/// 正解時はテンション高め、不正解時は責めずに励ますトーンに統一
const List<String> kCorrectReactions = [
  'やったね！その調子！',
  'さすが！バッチリだよ！',
  'ナイス！よくできました！',
  'すごい！どんどん強くなってる！',
  'ピッタリ正解！かっこいい！',
  '完璧！センスあるね！',
];

const List<String> kWrongReactions = [
  'おしい！次はできるよ！',
  'だいじょうぶ、ここが難しいところなんだ',
  'まちがえるのも勉強のうち！一緒に見てみよう',
  'ドンマイ！解説を読んでみよう',
  '惜しい！コツをつかめばすぐできるよ',
  'ここでつまずく子は多いよ、焦らなくて大丈夫！',
];

/// index を使って毎回違うセリフを選ぶ（決定的・乱数不使用）
String pickReaction({required bool isCorrect, required int index}) {
  final pool = isCorrect ? kCorrectReactions : kWrongReactions;
  return pool[index % pool.length];
}
