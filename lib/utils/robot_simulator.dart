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
