import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/block_model.dart';
import 'package:shogaku_kore_programming/providers/editor_provider.dart';

Block _fwd([num steps = 100]) => Block(
    id: 'move_forward', name: '前に進む', icon: '📍',
    category: BlockCategory.motion, params: {'steps': steps});
Block _right([num deg = 90]) => Block(
    id: 'turn_right', name: '右に回転', icon: '↪️',
    category: BlockCategory.motion, params: {'degrees': deg});
Block _repeat(int times) => Block(
    id: 'repeat', name: '繰り返す', icon: '🔁',
    category: BlockCategory.control, params: {'times': times});

Block _left([num deg = 90]) => Block(
    id: 'turn_left', name: '左に回転', icon: '↩️',
    category: BlockCategory.motion, params: {'degrees': deg});

EditorNotifier _submitShape(String shape, List<Block> blocks) {
  final n = EditorNotifier();
  for (final b in blocks) {
    n.addBlock(b);
  }
  n.submitScript('', shape: shape);
  return n;
}

EditorNotifier _submit(List<Block> blocks) => _submitShape('square', blocks);

void main() {
  group('四角を描こう（結果で判定）', () {
    test('繰り返しを使った場合は正解', () {
      final n = _submit([_repeat(4), _fwd(), _right()]);
      expect(n.state.isCorrect, isTrue);
    });

    test('繰り返しを使わなくても同じ結果なら正解', () {
      final n = _submit([_fwd(), _right(), _fwd(), _right(), _fwd(), _right(), _fwd(), _right()]);
      expect(n.state.isCorrect, isTrue);
    });

    test('別の大きさの四角でも正解', () {
      final n = _submit([_repeat(4), _fwd(50), _right()]);
      expect(n.state.isCorrect, isTrue);
    });

    test('3回だけ繰り返すと不正解でヒントが出る', () {
      final n = _submit([_repeat(3), _fwd(), _right()]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('ヒント'));
      expect(n.state.previewOutput, contains('辺が4本'));
    });

    test('回転が90度でないと角度のヒントが出る', () {
      final n = _submit([_repeat(4), _fwd(), _right(60)]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('90度'));
    });

    test('辺の長さが違うと長さのヒントが出る', () {
      final n = _submit([_fwd(100), _right(), _fwd(50), _right(), _fwd(100), _right(), _fwd(50), _right()]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('長さ'));
    });

    test('前に進むだけだと不正解', () {
      final n = _submit([_fwd()]);
      expect(n.state.isCorrect, isFalse);
    });
  });

  group('三角を描こう', () {
    EditorNotifier tri(List<Block> b) => _submitShape('triangle', b);

    test('繰り返しあり/なしどちらも正解', () {
      expect(tri([_repeat(3), _fwd(), _right(120)]).state.isCorrect, isTrue);
      expect(
          tri([_fwd(), _right(120), _fwd(), _right(120), _fwd(), _right(120)])
              .state
              .isCorrect,
          isTrue);
    });

    test('左回りでも三角なら正解', () {
      expect(tri([_repeat(3), _fwd(), _left(120)]).state.isCorrect, isTrue);
    });

    test('角度が違うと角度のヒント', () {
      final n = tri([_repeat(3), _fwd(), _right(90)]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('120度'));
    });

    test('2回だけだと辺の数のヒント', () {
      final n = tri([_repeat(2), _fwd(), _right(120)]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('辺が3本'));
    });
  });

  group('ジグザグ道を進もう', () {
    EditorNotifier zig(List<Block> b) => _submitShape('zigzag', b);

    test('右45度→左45度で正解', () {
      expect(
          zig([_fwd(), _right(45), _fwd(), _left(45), _fwd()]).state.isCorrect,
          isTrue);
    });

    test('左→右でも正解', () {
      expect(
          zig([_fwd(), _left(45), _fwd(), _right(45), _fwd()]).state.isCorrect,
          isTrue);
    });

    test('同じ向きに曲がるとヒント', () {
      final n = zig([_fwd(), _right(45), _fwd(), _right(45), _fwd()]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('交互'));
    });

    test('角度が違うと角度のヒント', () {
      final n = zig([_fwd(), _right(90), _fwd(), _left(90), _fwd()]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('45度'));
    });
  });

  group('直線を描こう', () {
    EditorNotifier line(List<Block> b) => _submitShape('line', b);

    test('100歩で正解（50歩2回でも同じ）', () {
      expect(line([_fwd(100)]).state.isCorrect, isTrue);
      expect(line([_fwd(50), _fwd(50)]).state.isCorrect, isTrue);
    });

    test('歩数が違うと歩数のヒント', () {
      final n = line([_fwd(50)]);
      expect(n.state.isCorrect, isFalse);
      expect(n.state.previewOutput, contains('100'));
    });

    test('曲がると不正解', () {
      expect(line([_fwd(), _right(), _fwd()]).state.isCorrect, isFalse);
    });
  });
}
