import 'dart:math';

import '../models/stage.dart';

/// 選択肢をシャッフルした結果（選択肢と、付け替え後の正解インデックス）。
class ShuffledChoices {
  final List<String> choices;
  final int correctIndex;
  const ShuffledChoices(this.choices, this.correctIndex);
}

/// 「上記のすべて」「どれでもない」など、位置が意味を持つ選択肢は末尾に固定する。
bool isPinnedLastChoice(String s) {
  return s.contains('上記のすべて') ||
      s.contains('上のすべて') ||
      s.contains('どれでもない') ||
      s.contains('どれもあてはまらない') ||
      s.contains('すべて正しい') ||
      s.contains('全部正しい');
}

/// 選択肢をシャッフルし、正解の位置を付け替えて返す。
/// 値ではなくインデックスを並べ替えるので、重複する選択肢があっても正解を見失わない。
/// 元データは正解位置が偏っている(先頭に約半数)ので、出題時に必ず通す。
ShuffledChoices shuffleChoices(List<String> choices, int correctIndex,
    [Random? rng]) {
  if (choices.length < 2 || correctIndex < 0 || correctIndex >= choices.length) {
    return ShuffledChoices(List<String>.of(choices), correctIndex);
  }
  final movable = <int>[];
  final pinned = <int>[];
  for (var i = 0; i < choices.length; i++) {
    (isPinnedLastChoice(choices[i]) ? pinned : movable).add(i);
  }
  movable.shuffle(rng ?? Random());
  final order = [...movable, ...pinned];
  return ShuffledChoices(
    [for (final i in order) choices[i]],
    order.indexOf(correctIndex),
  );
}

extension QuestionShuffle on Question {
  /// 選択肢をシャッフルし正解インデックスを付け替えた Question を返す。
  Question shuffled([Random? rng]) {
    final r = shuffleChoices(options, correctIndex, rng);
    return Question(
      id: id,
      text: text,
      codeSnippet: codeSnippet,
      options: r.choices,
      correctIndex: r.correctIndex,
      explanation: explanation,
      hint: hint,
    );
  }
}
