import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/utils/shuffle_choices.dart';

void main() {
  test('正解の文字列が付け替え後のインデックスでも同じ', () {
    final rng = Random(1);
    for (var n = 0; n < 200; n++) {
      const choices = ['A', 'B', 'C', 'D'];
      final c = n % 4;
      final r = shuffleChoices(choices, c, rng);
      expect(r.choices.toSet(), choices.toSet());
      expect(r.choices[r.correctIndex], choices[c]);
    }
  });

  test('3択・2択でも動く', () {
    final r = shuffleChoices(['x', 'y', 'z'], 2, Random(3));
    expect(r.choices[r.correctIndex], 'z');
    final r2 = shuffleChoices(['はい', 'いいえ'], 0, Random(5));
    expect(r2.choices[r2.correctIndex], 'はい');
  });

  test('重複する選択肢があっても正解の元位置を追従する', () {
    final choices = ['同じ', '同じ', 'ちがう', 'べつ'];
    for (var seed = 0; seed < 50; seed++) {
      final r = shuffleChoices(choices, 1, Random(seed));
      expect(r.choices[r.correctIndex], '同じ');
      expect(r.choices.length, 4);
    }
  });

  test('「上記のすべて」「どれでもない」は末尾に固定', () {
    for (var seed = 0; seed < 50; seed++) {
      final r = shuffleChoices(['あ', 'い', 'う', '上記のすべて'], 3, Random(seed));
      expect(r.choices.last, '上記のすべて');
      expect(r.correctIndex, 3);
      final r2 = shuffleChoices(['あ', 'い', 'う', 'どれでもない'], 1, Random(seed));
      expect(r2.choices.last, 'どれでもない');
      expect(r2.choices[r2.correctIndex], 'い');
    }
  });

  test('不正な入力はそのまま返す', () {
    expect(shuffleChoices(['a'], 0).correctIndex, 0);
    expect(shuffleChoices(['a', 'b'], 5).correctIndex, 5);
  });

  test('正解が常に先頭の問題でも、位置が各選択肢に散らばる', () {
    final rng = Random(42);
    final counts = List<int>.filled(4, 0);
    for (var i = 0; i < 4000; i++) {
      counts[shuffleChoices(['a', 'b', 'c', 'd'], 0, rng).correctIndex]++;
    }
    for (final c in counts) {
      expect(c, inInclusiveRange(800, 1200));
    }
  });

  test('Question.shuffled は他のフィールドを保ち正解を追従する', () {
    const q = Question(
      id: 'q1',
      text: 'print(1+1) の結果は？',
      codeSnippet: 'print(1+1)',
      options: ['2', '11', 'エラー', '0'],
      correctIndex: 0,
      explanation: 'e',
      hint: 'h',
    );
    for (var seed = 0; seed < 30; seed++) {
      final s = q.shuffled(Random(seed));
      expect(s.options[s.correctIndex], '2');
      expect(s.options.toSet(), q.options.toSet());
      expect(s.id, 'q1');
      expect(s.codeSnippet, 'print(1+1)');
      expect(s.hint, 'h');
      expect(s.explanation, 'e');
    }
    expect(q.options, ['2', '11', 'エラー', '0']);
  });
}
