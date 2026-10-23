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

EditorNotifier _submit(List<Block> blocks) {
  final n = EditorNotifier();
  for (final b in blocks) {
    n.addBlock(b);
  }
  n.submitScript('repeat(4):\n  move_forward(100)\n  turn_right(90)',
      shape: 'square');
  return n;
}

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
}
