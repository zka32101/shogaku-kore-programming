import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/block_model.dart';
import 'package:shogaku_kore_programming/utils/robot_simulator.dart';

Block _b(String id, [Map<String, dynamic> params = const {}]) => Block(
    id: id,
    name: id,
    icon: '',
    category: id == 'repeat' ? BlockCategory.control : BlockCategory.motion,
    params: {...params});

Block _fwd([num steps = 100]) => _b('move_forward', {'steps': steps});
Block _right([num deg = 90]) => _b('turn_right', {'degrees': deg});
Block _repeat(int times) => _b('repeat', {'times': times});

void main() {
  group('simulateSteps', () {
    test('ブロックがなければ、ステップもない', () {
      expect(simulateSteps(const []), isEmpty);
    });

    test('1ブロックごとに、実行直後の軌跡の長さと向きが分かる', () {
      final steps = simulateSteps([_fwd(), _right(), _fwd()]);
      expect(steps.map((s) => s.blockIndex), [0, 1, 2]);
      expect(steps.map((s) => s.pathLength), [2, 2, 3]); // 曲がるだけでは点が増えない
      expect(steps.map((s) => s.angle), [0, 90, 90]);
    });

    test('繰り返しは、その後ろのブロックを回数ぶん実行する', () {
      final steps = simulateSteps([_fwd(), _repeat(2), _fwd(), _right()]);
      // 0 → 繰り返し(1) → 本体(2,3)を2回
      expect(steps.map((s) => s.blockIndex), [0, 1, 2, 3, 2, 3]);
    });

    test('繰り返しブロック自体は動かず、その時点の状態を保つ', () {
      final steps = simulateSteps([_fwd(), _repeat(3), _right()]);
      expect(steps[1].blockIndex, 1);
      expect(steps[1].pathLength, steps[0].pathLength);
      expect(steps[1].angle, steps[0].angle);
    });

    test('最後のステップは simulateRobot の結果と一致する', () {
      final programs = <List<Block>>[
        [_fwd()],
        [_fwd(), _right(), _fwd(), _right()],
        [_repeat(4), _fwd(), _right()],
        [_fwd(50), _repeat(3), _fwd(), _right(120)],
        [_repeat(5), _fwd(200), _right(45)], // 盤面の端にぶつかる
      ];
      for (final clamp in [true, false]) {
        for (final blocks in programs) {
          final (path, angle) = simulateRobot(blocks, clamp: clamp);
          final steps = simulateSteps(blocks, clamp: clamp);
          expect(steps.last.pathLength, path.length, reason: '$blocks clamp=$clamp');
          expect(steps.last.angle, angle, reason: '$blocks clamp=$clamp');
        }
      }
    });

    test('途中の軌跡の長さは単調に増える', () {
      final steps = simulateSteps([_repeat(4), _fwd(), _right()]);
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i].pathLength, greaterThanOrEqualTo(steps[i - 1].pathLength));
      }
    });
  });
}
