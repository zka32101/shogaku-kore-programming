import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/providers/coin_provider.dart';

void main() {
  group('coinPerCorrect()', () {
    test('初級は1コイン', () {
      expect(coinPerCorrect('初級'), 1);
    });

    test('中級は2コイン', () {
      expect(coinPerCorrect('中級'), 2);
    });

    test('上級は3コイン', () {
      expect(coinPerCorrect('上級'), 3);
    });

    test('未知の難易度は1コインにフォールバック', () {
      expect(coinPerCorrect('不明'), 1);
    });
  });

  group('calcQuizCoins()', () {
    test('初級5問全問正解: base=5, comboBonus=0, perfectBonus=10', () {
      final (total, combo, perfect) = calcQuizCoins(
        level: '初級',
        correctCount: 5,
        totalCount: 5,
        maxCombo: 2, // 3未満なのでcomboBonus=0
      );
      expect(total, 15);   // 5*1 + 0 + 10
      expect(combo, 0);
      expect(perfect, 10);
    });

    test('中級5問中3問正解: base=6, comboBonus=0, perfectBonus=0', () {
      final (total, combo, perfect) = calcQuizCoins(
        level: '中級',
        correctCount: 3,
        totalCount: 5,
        maxCombo: 2,
      );
      expect(total, 6);    // 3*2
      expect(combo, 0);
      expect(perfect, 0);
    });

    test('上級3問全問正解 + 3連続コンボ: base=9, comboBonus=5, perfectBonus=10', () {
      final (total, combo, perfect) = calcQuizCoins(
        level: '上級',
        correctCount: 3,
        totalCount: 3,
        maxCombo: 3,
      );
      expect(total, 24);   // 3*3 + 5 + 10
      expect(combo, 5);
      expect(perfect, 10);
    });

    test('0問正解: 全ボーナス0', () {
      final (total, combo, perfect) = calcQuizCoins(
        level: '初級',
        correctCount: 0,
        totalCount: 5,
        maxCombo: 0,
      );
      expect(total, 0);
      expect(combo, 0);
      expect(perfect, 0);
    });

    test('3連続コンボボーナス: maxCombo>=3 のみ付与', () {
      final (_, combo2, _) = calcQuizCoins(
        level: '初級',
        correctCount: 2,
        totalCount: 5,
        maxCombo: 2,
      );
      final (_, combo3, _) = calcQuizCoins(
        level: '初級',
        correctCount: 3,
        totalCount: 5,
        maxCombo: 3,
      );
      expect(combo2, 0);
      expect(combo3, 5);
    });

    test('全問正解でもtotalCount==0の場合はperfectBonus=0', () {
      final (_, _, perfect) = calcQuizCoins(
        level: '初級',
        correctCount: 0,
        totalCount: 0,
        maxCombo: 0,
      );
      expect(perfect, 0);
    });
  });

  group('calcEditorCoins()', () {
    test('初級ビジュアル: 難易度×2 = 2コイン', () {
      expect(calcEditorCoins('初級'), 2);
    });

    test('中級ビジュアル: 難易度×2 = 4コイン', () {
      expect(calcEditorCoins('中級'), 4);
    });

    test('上級ビジュアル: 難易度×2 = 6コイン', () {
      expect(calcEditorCoins('上級'), 6);
    });
  });
}
