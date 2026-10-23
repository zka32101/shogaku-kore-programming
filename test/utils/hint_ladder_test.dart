import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/utils/hint_ladder.dart';

void main() {
  group('HintLadder', () {
    test('最初は星3・ヒントなしクリア扱い', () {
      final l = HintLadder();
      expect(l.stars, 3);
      expect(l.isNoHintClear, isTrue);
      expect(l.shouldOpenHintBar, isFalse);
      expect(l.canViewModel, isFalse);
    });

    test('2回目の不正解でヒント欄を開き、3回目でお手本が出る', () {
      final l = HintLadder();
      l.recordWrong();
      expect(l.shouldOpenHintBar, isFalse);
      expect(l.canViewModel, isFalse);
      l.recordWrong();
      expect(l.shouldOpenHintBar, isTrue);
      expect(l.canViewModel, isFalse);
      l.recordWrong();
      expect(l.canViewModel, isTrue);
    });

    test('不正解があるとノーヒントではないが、星はへらない', () {
      final l = HintLadder()..recordWrong();
      expect(l.isNoHintClear, isFalse);
      expect(l.stars, 3);
    });

    test('ヒント欄を開くとノーヒントではないが、星はへらない', () {
      final l = HintLadder()..openHint();
      expect(l.isNoHintClear, isFalse);
      expect(l.stars, 3);
    });

    test('お手本を見ると星が1つへる', () {
      final l = HintLadder()..viewModel();
      expect(l.stars, 2);
      expect(l.isNoHintClear, isFalse);
    });
  });

  group('modelSteps', () {
    test('ブロックを子ども向けの名前と単位に直す', () {
      expect(modelSteps('move_forward(100)\nturn_right(90)'),
          ['前に進む 100歩', '右に回転 90°']);
    });

    test('繰り返しとインデントを保つ', () {
      expect(modelSteps('repeat(4):\n  move_forward(100)\n  turn_right(90)'),
          ['繰り返す 4回', '  前に進む 100歩', '  右に回転 90°']);
    });

    test('引数のないブロックと、分からない行はそのまま使う', () {
      expect(modelSteps('print_block\nsomething_else(1)'),
          ['表示する', 'something_else(1)']);
    });

    test('空の入力は空', () {
      expect(modelSteps(''), isEmpty);
    });
  });
}
