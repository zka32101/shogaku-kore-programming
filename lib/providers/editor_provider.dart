import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block_model.dart';

// ─── ロボットシミュレーション ──────────────────────────────────────────────────

const double _kGridSize = 7.0;
const double _kStepsPerCell = 50.0; // steps per grid cell

// ─── 状態 ─────────────────────────────────────────────────────────────────────

class EditorState {
  final List<Block> scriptBlocks;
  final String previewOutput;
  final bool isCorrect;
  final bool hasSubmitted;
  // ロボットシミュレーション
  final List<Offset> robotPath;   // 正規化座標 (0–7)
  final double robotAngle;        // 最終角度（度）

  const EditorState({
    this.scriptBlocks = const [],
    this.previewOutput = '',
    this.isCorrect = false,
    this.hasSubmitted = false,
    this.robotPath = const [],
    this.robotAngle = 0,
  });

  EditorState copyWith({
    List<Block>? scriptBlocks,
    String? previewOutput,
    bool? isCorrect,
    bool? hasSubmitted,
    List<Offset>? robotPath,
    double? robotAngle,
  }) {
    return EditorState(
      scriptBlocks: scriptBlocks ?? this.scriptBlocks,
      previewOutput: previewOutput ?? this.previewOutput,
      isCorrect: isCorrect ?? this.isCorrect,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      robotPath: robotPath ?? this.robotPath,
      robotAngle: robotAngle ?? this.robotAngle,
    );
  }
}

// ─── ノティファイア ───────────────────────────────────────────────────────────

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  // アンドゥ / リドゥ履歴（最大20ステップ）
  final List<List<Block>> _undoStack = [];
  final List<List<Block>> _redoStack = [];
  static const int _maxUndoDepth = 20;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushUndo() {
    _undoStack.add(List<Block>.from(state.scriptBlocks));
    if (_undoStack.length > _maxUndoDepth) {
      _undoStack.removeAt(0);
    }
    // 新しい操作でリドゥ履歴をクリア
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    // 現在の状態をリドゥスタックに保存
    _redoStack.add(List<Block>.from(state.scriptBlocks));
    final prev = _undoStack.removeLast();
    final (path, angle) = _simulateRobot(prev);
    state = state.copyWith(
      scriptBlocks: prev,
      hasSubmitted: false,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    // 現在の状態をアンドゥスタックに保存
    _undoStack.add(List<Block>.from(state.scriptBlocks));
    final next = _redoStack.removeLast();
    final (path, angle) = _simulateRobot(next);
    state = state.copyWith(
      scriptBlocks: next,
      hasSubmitted: false,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void addBlock(Block block) {
    _pushUndo();
    final newBlock = Block(
      id: '${block.id}@${DateTime.now().millisecondsSinceEpoch}',
      name: block.name,
      icon: block.icon,
      category: block.category,
      params: Map.from(block.params),
      description: block.description,
    );
    final newBlocks = [...state.scriptBlocks, newBlock];
    final (path, angle) = _simulateRobot(newBlocks);
    state = state.copyWith(
      scriptBlocks: newBlocks,
      hasSubmitted: false,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void removeBlock(int index) {
    _pushUndo();
    final blocks = List<Block>.from(state.scriptBlocks)..removeAt(index);
    final (path, angle) = _simulateRobot(blocks);
    state = state.copyWith(
      scriptBlocks: blocks,
      hasSubmitted: false,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void moveBlock(int oldIndex, int newIndex) {
    _pushUndo();
    final blocks = List<Block>.from(state.scriptBlocks);
    final block = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, block);
    final (path, angle) = _simulateRobot(blocks);
    state = state.copyWith(
      scriptBlocks: blocks,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void updateBlockParam(String blockId, String key, dynamic value) {
    _pushUndo();
    final blocks = state.scriptBlocks.map((b) {
      if (b.id == blockId) {
        final newParams = Map<String, dynamic>.from(b.params);
        newParams[key] = value;
        return b.copyWith(params: newParams);
      }
      return b;
    }).toList();
    final (path, angle) = _simulateRobot(blocks);
    state = state.copyWith(
      scriptBlocks: blocks,
      hasSubmitted: false,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void executeScript() {
    if (state.scriptBlocks.isEmpty) {
      state = state.copyWith(
        previewOutput: '⚠️ ブロックがありません。パレットからブロックを追加してね！',
        isCorrect: false,
        hasSubmitted: false,
        robotPath: [],
      );
      return;
    }

    final output = _generateOutput();
    final (path, angle) = _simulateRobot(state.scriptBlocks);
    state = state.copyWith(
      previewOutput: output,
      hasSubmitted: false,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void submitScript(String expectedOutput) {
    final output = _generateOutput();
    final blockIds = state.scriptBlocks.map((b) => b.id.split('@').first).toList();
    final correct = _checkAnswer(blockIds, expectedOutput);
    final (path, angle) = _simulateRobot(state.scriptBlocks);

    state = state.copyWith(
      previewOutput: correct
          ? '✅ 正解！素晴らしい！\n\n$output'
          : '❌ もう一度試してみよう！\n\nヒント: ${_getHint(expectedOutput)}',
      isCorrect: correct,
      hasSubmitted: true,
      robotPath: path,
      robotAngle: angle,
    );
  }

  void reset() {
    _undoStack.clear();
    _redoStack.clear();
    state = const EditorState();
  }

  // ─── テキスト出力 ─────────────────────────────────────────────────────────

  String _generateOutput() {
    final sb = StringBuffer();
    for (final block in state.scriptBlocks) {
      sb.writeln('▶ ${block.displayText}');
    }
    return sb.toString().trim();
  }

  // ─── ロボットシミュレーション ────────────────────────────────────────────

  /// ブロックリストを実行してロボットのパスと最終角度を返す
  (List<Offset>, double) _simulateRobot(List<Block> blocks) {
    double x = _kGridSize / 2;
    double y = _kGridSize / 2;
    double angle = 0.0; // 0° = right, clockwise positive

    final path = <Offset>[Offset(x, y)];

    // repeat / while_loop ブロックの位置を探す
    final loopIdx = blocks.indexWhere(
      (b) {
        final base = b.id.split('@').first;
        return base == 'repeat' || base == 'while_loop';
      },
    );

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

    // ループより前のブロックを実行
    for (final block in execBlocks) {
      _executeBlock(block, path, (nx, ny, na) {
        x = nx; y = ny; angle = na;
      }, x, y, angle);
      x = path.last.dx;
      y = path.last.dy;
    }

    // ループ内のブロックを n 回実行
    for (int r = 0; r < loopTimes; r++) {
      for (final block in loopBlocks) {
        _executeBlock(block, path, (nx, ny, na) {
          x = nx; y = ny; angle = na;
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
        final nx = (x + math.cos(rad) * dist).clamp(0.0, _kGridSize);
        final ny = (y + math.sin(rad) * dist).clamp(0.0, _kGridSize);
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

  // ─── 採点 ────────────────────────────────────────────────────────────────

  bool _checkAnswer(List<String> blocks, String expectedOutput) {
    if (expectedOutput.contains('move_forward') && !blocks.contains('move_forward')) return false;
    if (expectedOutput.contains('turn_right') && !blocks.contains('turn_right')) return false;
    if (expectedOutput.contains('turn_left') && !blocks.contains('turn_left')) return false;
    if (expectedOutput.contains('repeat') && !blocks.contains('repeat')) return false;
    if (expectedOutput.contains('if_wall') && !blocks.contains('if_wall')) return false;
    if (expectedOutput.contains('if_condition') && !blocks.contains('if_condition')) return false;
    if (expectedOutput.contains('while_loop') && !blocks.contains('while_loop')) return false;
    if (expectedOutput.contains('print_block') && !blocks.contains('print_block')) return false;
    return blocks.isNotEmpty;
  }

  String _getHint(String expectedOutput) {
    if (expectedOutput.contains('while_loop')) return 'whileループブロックを使ってみよう！';
    if (expectedOutput.contains('if_condition')) return '「もし〜ならば」ブロックを使ってみよう！';
    if (expectedOutput.contains('print_block')) return '「表示する」ブロックを使ってみよう！';
    if (expectedOutput.contains('repeat')) return '繰り返しブロックを使ってみよう！';
    if (expectedOutput.contains('turn_right')) return '右に回転するブロックを追加しよう！';
    if (expectedOutput.contains('turn_left')) return '左に回転するブロックを追加しよう！';
    return '必要なブロックをすべて追加してみよう！';
  }
}

final editorProvider =
    StateNotifierProvider.autoDispose<EditorNotifier, EditorState>(
        (ref) => EditorNotifier());
