import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/block_model.dart';

const double kRobotGridSize = 7.0;
const double _kStepsPerCell = 50.0; // steps per grid cell

/// ブロックリストを実行してロボットのパス（正規化座標）と最終角度を返す。
/// editor_provider.dart（ステージ課題）と自由制作モードの両方から使われる
/// 共通シミュレーションロジック。
(List<Offset>, double) simulateRobot(List<Block> blocks) {
  double x = kRobotGridSize / 2;
  double y = kRobotGridSize / 2;
  double angle = 0.0; // 0° = right, clockwise positive

  final path = <Offset>[Offset(x, y)];

  // repeat / while_loop ブロックの位置を探す
  final loopIdx = blocks.indexWhere((b) {
    final base = b.id.split('@').first;
    return base == 'repeat' || base == 'while_loop';
  });

  List<Block> execBlocks;
  List<Block> loopBlocks;
  int loopTimes = 1;

  if (loopIdx >= 0) {
    execBlocks = blocks.sublist(0, loopIdx);
    loopBlocks = blocks.sublist(loopIdx + 1);
    loopTimes = (blocks[loopIdx].params['times'] as num?)?.toInt() ?? 3;
  } else {
    execBlocks = blocks;
    loopBlocks = [];
  }

  for (final block in execBlocks) {
    _executeBlock(block, path, (nx, ny, na) {
      x = nx;
      y = ny;
      angle = na;
    }, x, y, angle);
    x = path.last.dx;
    y = path.last.dy;
  }

  for (int r = 0; r < loopTimes; r++) {
    for (final block in loopBlocks) {
      _executeBlock(block, path, (nx, ny, na) {
        x = nx;
        y = ny;
        angle = na;
      }, x, y, angle);
      x = path.last.dx;
      y = path.last.dy;
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
) {
  final baseId = block.id.split('@').first;
  switch (baseId) {
    case 'move_forward':
      final steps = (block.params['steps'] as num?)?.toDouble() ?? 100;
      final dist = steps / _kStepsPerCell;
      final rad = angle * math.pi / 180.0;
      final nx = (x + math.cos(rad) * dist).clamp(0.0, kRobotGridSize);
      final ny = (y + math.sin(rad) * dist).clamp(0.0, kRobotGridSize);
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

/// ロボットの軌跡が正方形になっているかを調べる。
///
/// 使ったブロックの種類（繰り返しの有無など）は問わず、軌跡の形だけで判定する。
/// 正方形なら null、そうでなければ子ども向けのヒント文を返す。
String? squareHint(List<Offset> path) {
  const eps = 0.05;
  bool same(Offset a, Offset b) => (a - b).distance < eps;

  // 動いていない点・同一直線上の中間点（50歩を2回など）をまとめる
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
    if (cross.abs() < eps && dot > 0) {
      pts.removeAt(i);
    } else {
      i++;
    }
  }

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
