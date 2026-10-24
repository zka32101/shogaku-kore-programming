import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/block_model.dart';

const double kRobotGridSize = 7.0;
const double _kStepsPerCell = 50.0; // steps per grid cell

/// ブロックリストを実行してロボットのパス（正規化座標）と最終角度を返す。
/// editor_provider.dart（ステージ課題）と自由制作モードの両方から使われる
/// 共通シミュレーションロジック。
///
/// [clamp] が false のときは盤面の端で止めず、プログラムが描く本来の軌跡を返す
/// （形の判定用。表示用は true のまま盤面内に収める）。
(List<Offset>, double) simulateRobot(List<Block> blocks, {bool clamp = true}) =>
    _run(blocks, clamp, null);

/// 実行した1ブロックぶんの結果。再生（1ブロックずつ動かす表示）に使う。
class SimStep {
  /// スクリプト内でのブロックの位置（繰り返しの中身は、実行のたびに同じ位置が出る）
  final int blockIndex;

  /// このブロックの実行直後に、軌跡のうち何点までが描かれているか
  final int pathLength;

  /// このブロックの実行直後のロボットの向き（度）
  final double angle;

  const SimStep(this.blockIndex, this.pathLength, this.angle);
}

/// [simulateRobot] と同じ順序・結果で、ブロックを1つずつ実行した経過を返す。
/// 最後の [SimStep] の `pathLength` / `angle` は、[simulateRobot] の結果と一致する。
List<SimStep> simulateSteps(List<Block> blocks, {bool clamp = true}) {
  final steps = <SimStep>[];
  _run(blocks, clamp, (i, len, angle) => steps.add(SimStep(i, len, angle)));
  return steps;
}

(List<Offset>, double) _run(
  List<Block> blocks,
  bool clamp,
  void Function(int blockIndex, int pathLength, double angle)? onStep,
) {
  double x = kRobotGridSize / 2;
  double y = kRobotGridSize / 2;
  double angle = 0.0; // 0° = right, clockwise positive

  final path = <Offset>[Offset(x, y)];

  // repeat / while_loop ブロックの位置を探す
  final loopIdx = blocks.indexWhere((b) {
    final base = b.id.split('@').first;
    return base == 'repeat' || base == 'while_loop';
  });

  final int execCount = loopIdx >= 0 ? loopIdx : blocks.length;
  final int loopStart = loopIdx >= 0 ? loopIdx + 1 : blocks.length;
  final int loopTimes =
      loopIdx >= 0 ? ((blocks[loopIdx].params['times'] as num?)?.toInt() ?? 3) : 1;

  void run(int index) {
    _executeBlock(blocks[index], path, (nx, ny, na) {
      x = nx;
      y = ny;
      angle = na;
    }, x, y, angle, clamp);
    x = path.last.dx;
    y = path.last.dy;
    onStep?.call(index, path.length, angle);
  }

  for (var i = 0; i < execCount; i++) {
    run(i);
  }
  if (loopIdx >= 0) {
    // 繰り返しブロック自体は動かないので、その時点の状態のまま1ステップとして数える
    onStep?.call(loopIdx, path.length, angle);
  }
  for (var r = 0; r < loopTimes; r++) {
    for (var i = loopStart; i < blocks.length; i++) {
      run(i);
    }
  }

  return (path, angle);
}

void _executeBlock(
  Block block,
  List<Offset> path,
  void Function(double x, double y, double angle) update,
  double x,
  double y,
  double angle,
  bool clamp,
) {
  final baseId = block.id.split('@').first;
  switch (baseId) {
    case 'move_forward':
      final steps = (block.params['steps'] as num?)?.toDouble() ?? 100;
      final dist = steps / _kStepsPerCell;
      final rad = angle * math.pi / 180.0;
      var nx = x + math.cos(rad) * dist;
      var ny = y + math.sin(rad) * dist;
      if (clamp) {
        nx = nx.clamp(0.0, kRobotGridSize);
        ny = ny.clamp(0.0, kRobotGridSize);
      }
      path.add(Offset(nx, ny));
      update(nx, ny, angle);
    case 'turn_right':
      final deg = (block.params['degrees'] as num?)?.toDouble() ?? 90;
      update(x, y, angle + deg);
    case 'turn_left':
      final deg = (block.params['degrees'] as num?)?.toDouble() ?? 90;
      update(x, y, angle - deg);
    default:
      // stop, if_wall, set_variable, add_variable, if_condition, print_block — no movement
      break;
  }
}

const double _kEps = 0.05;

/// 軌跡から、動いていない点と同一直線上の中間点（50歩を2回など）を除いて
/// 「頂点だけ」の列にする。
List<Offset> _vertices(List<Offset> path) {
  bool same(Offset a, Offset b) => (a - b).distance < _kEps;
  final pts = <Offset>[];
  for (final p in path) {
    if (pts.isEmpty || !same(pts.last, p)) pts.add(p);
  }
  var i = 1;
  while (i < pts.length - 1) {
    final a = pts[i] - pts[i - 1];
    final b = pts[i + 1] - pts[i];
    final cross = a.dx * b.dy - a.dy * b.dx;
    final dot = a.dx * b.dx + a.dy * b.dy;
    if (cross.abs() < _kEps && dot > 0) {
      pts.removeAt(i);
    } else {
      i++;
    }
  }
  return pts;
}

/// ステージの `shape` に応じて、ロボットの軌跡が正解の形かを調べる。
///
/// 使ったブロックの種類（繰り返しの有無など）は問わず、軌跡の形だけで判定する。
/// 正解なら null、そうでなければ子ども向けのヒント文を返す。
String? shapeHint(String shape, List<Offset> path) {
  switch (shape) {
    case 'square':
      return squareHint(path);
    case 'triangle':
      return triangleHint(path);
    case 'zigzag':
      return zigzagHint(path);
    case 'line':
      return lineHint(path);
  }
  return null;
}

/// 100歩（2マス）まっすぐ進めているか。
String? lineHint(List<Offset> path) {
  final pts = _vertices(path);
  if (pts.length < 2) return '「前に進む」ブロックを使ってロボットを動かそう！';
  if (pts.length > 2) return 'まっすぐ進むだけでいいよ。曲がらずに1本の線にしよう！';
  final len = (pts[1] - pts[0]).distance;
  if (len < 2 - _kEps) return 'まだ足りないよ。歩数を100にしよう！';
  if (len > 2 + _kEps) return '進みすぎだよ。歩数を100にしよう！';
  return null;
}

/// 正三角形（3辺が同じ長さで、スタートにもどる）になっているか。
String? triangleHint(List<Offset> path) {
  final pts = _vertices(path);
  if (pts.length < 2) return '「前に進む」ブロックを使ってロボットを動かそう！';
  if (pts.length - 1 < 3) {
    return '三角は辺が3本あるよ。「前に進む」と「回転」を3回ずつ使ってみよう！'
        '（「繰り返す」ブロックを使うと楽だよ）';
  }
  if (pts.length - 1 > 3) {
    return '辺が多すぎるみたい。「前に進む」と「回転」は3回ずつにしよう！';
  }
  final lengths = [for (var k = 0; k < 3; k++) (pts[k + 1] - pts[k]).distance];
  if (lengths.any((l) => (l - lengths.first).abs() > _kEps)) {
    return '3つの辺の長さをそろえよう。すべて同じ歩数にするといいよ！';
  }
  if ((pts.last - pts.first).distance > _kEps) {
    return '三角がとじていないよ。回転は120度にしよう！（右でも左でも同じ向きにそろえてね）';
  }
  return null;
}

/// 右45度のあと左45度（またはその逆）で、同じ長さを3回進んでいるか。
String? zigzagHint(List<Offset> path) {
  final pts = _vertices(path);
  if (pts.length < 2) return '「前に進む」ブロックを使ってロボットを動かそう！';
  if (pts.length - 1 < 3) {
    return 'ジグザグは3回進むよ。進む → 曲がる を使って、3回目も進もう！';
  }
  if (pts.length - 1 > 3) {
    return '進むのは3回でいいよ。曲がるのは2回だけにしよう！';
  }
  final sides = [for (var k = 0; k < 3; k++) pts[k + 1] - pts[k]];
  final first = sides.first.distance;
  if (sides.any((s) => (s.distance - first).abs() > _kEps)) {
    return '3回とも同じ歩数だけ進もう！';
  }
  double turn(Offset a, Offset b) {
    var d = (math.atan2(b.dy, b.dx) - math.atan2(a.dy, a.dx)) * 180 / math.pi;
    while (d > 180) {
      d -= 360;
    }
    while (d <= -180) {
      d += 360;
    }
    return d;
  }

  final t1 = turn(sides[0], sides[1]);
  final t2 = turn(sides[1], sides[2]);
  if ((t1.abs() - 45).abs() > 3 || (t2.abs() - 45).abs() > 3) {
    return '曲がる角度は45度にしよう！';
  }
  if (t1 * t2 > 0) {
    return '右と左を交互に使おう。1回目と2回目で曲がる向きを変えるとジグザグになるよ！';
  }
  return null;
}

/// ロボットの軌跡が正方形になっているかを調べる。
///
/// 使ったブロックの種類（繰り返しの有無など）は問わず、軌跡の形だけで判定する。
/// 正方形なら null、そうでなければ子ども向けのヒント文を返す。
String? squareHint(List<Offset> path) {
  const eps = _kEps;
  bool same(Offset a, Offset b) => (a - b).distance < eps;
  final pts = _vertices(path);

  if (pts.length < 2) return '「前に進む」ブロックを使ってロボットを動かそう！';
  if (pts.length - 1 < 4) {
    return '四角は辺が4本あるよ。「前に進む」と「回転」を4回ずつ使ってみよう！'
        '（「繰り返す」ブロックを使うと楽だよ）';
  }
  if (pts.length - 1 > 4) {
    return '辺が多すぎるみたい。「前に進む」と「回転」は4回ずつにしよう！';
  }

  final sides = [for (var k = 0; k < 4; k++) pts[k + 1] - pts[k]];
  final lengths = sides.map((s) => s.distance).toList();
  final first = lengths.first;

  if (lengths.any((l) => (l - first).abs() > eps)) {
    return '4つの辺の長さをそろえよう。すべて同じ歩数にするといいよ！';
  }
  for (var k = 0; k < 4; k++) {
    final a = sides[k];
    final b = sides[(k + 1) % 4];
    if ((a.dx * b.dx + a.dy * b.dy).abs() > eps * first) {
      return '角がまっすぐ(直角)になっていないよ。回転は90度にしよう！';
    }
  }
  if (!same(pts.last, pts.first)) {
    return '最後にスタート地点にもどれていないよ。'
        '4回目も「前に進む」のあとに回転を入れて、もとの向きにもどそう！';
  }
  return null;
}
