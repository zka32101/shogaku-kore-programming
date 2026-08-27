import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block_model.dart';

const double _kGridSize = 7.0;
const double _kStepsPerCell = 50.0;

// ─── ステップ実行状態 ──────────────────────────────────────────────────────

class ExecutionState {
  // 実行制御
  final bool isRunning;
  final bool isPaused;
  final int currentStepIndex; // 次に実行するブロックのインデックス
  final int executionSpeed; // 1（遅い）〜 5（速い）

  // ロボット状態
  final double robotX;
  final double robotY;
  final double robotAngle;
  final List<Offset> robotPath;

  // UI フィードバック
  final String outputMessage;
  final bool lastExecutionSuccess;
  final String? currentBlockId; // ハイライト用

  // ループ管理
  final int currentLoopIteration; // 0 = ループ外
  final int totalLoopIterations;

  // 変数管理
  final Map<String, dynamic> variables;

  // ブレークポイント管理
  final Set<int> breakpoints; // ブレークポイントを設定したブロックのインデックス

  const ExecutionState({
    this.isRunning = false,
    this.isPaused = false,
    this.currentStepIndex = 0,
    this.executionSpeed = 3,
    this.robotX = _kGridSize / 2,
    this.robotY = _kGridSize / 2,
    this.robotAngle = 0,
    this.robotPath = const [Offset(_kGridSize / 2, _kGridSize / 2)],
    this.outputMessage = '',
    this.lastExecutionSuccess = true,
    this.currentBlockId,
    this.currentLoopIteration = 0,
    this.totalLoopIterations = 0,
    this.variables = const {},
    this.breakpoints = const {},
  });

  ExecutionState copyWith({
    bool? isRunning,
    bool? isPaused,
    int? currentStepIndex,
    int? executionSpeed,
    double? robotX,
    double? robotY,
    double? robotAngle,
    List<Offset>? robotPath,
    String? outputMessage,
    bool? lastExecutionSuccess,
    String? currentBlockId,
    int? currentLoopIteration,
    int? totalLoopIterations,
    Map<String, dynamic>? variables,
    Set<int>? breakpoints,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      executionSpeed: executionSpeed ?? this.executionSpeed,
      robotX: robotX ?? this.robotX,
      robotY: robotY ?? this.robotY,
      robotAngle: robotAngle ?? this.robotAngle,
      robotPath: robotPath ?? this.robotPath,
      outputMessage: outputMessage ?? this.outputMessage,
      lastExecutionSuccess: lastExecutionSuccess ?? this.lastExecutionSuccess,
      currentBlockId: currentBlockId ?? this.currentBlockId,
      currentLoopIteration: currentLoopIteration ?? this.currentLoopIteration,
      totalLoopIterations: totalLoopIterations ?? this.totalLoopIterations,
      variables: variables ?? this.variables,
      breakpoints: breakpoints ?? this.breakpoints,
    );
  }
}

// ─── ステップ実行ノティファイア ────────────────────────────────────────────

class StepExecutor extends StateNotifier<ExecutionState> {
  List<Block> _scriptBlocks = [];
  int _loopStartIndex = -1;
  int _loopEndIndex = -1;

  StepExecutor() : super(const ExecutionState());

  // ─── 初期化 ────────────────────────────────────────────────────────────

  void initializeExecution(List<Block> blocks) {
    _scriptBlocks = blocks;
    _findLoopBoundaries();

    state = ExecutionState(
      isRunning: false,
      isPaused: false,
      currentStepIndex: 0,
      robotX: _kGridSize / 2,
      robotY: _kGridSize / 2,
      robotAngle: 0,
      robotPath: const [Offset(_kGridSize / 2, _kGridSize / 2)],
      outputMessage: 'ステップ実行の準備ができました',
      currentBlockId: _scriptBlocks.isNotEmpty ? _scriptBlocks[0].id : null,
      variables: {},
    );
  }

  void _findLoopBoundaries() {
    for (int i = 0; i < _scriptBlocks.length; i++) {
      final baseId = _scriptBlocks[i].id.split('@').first;
      if (baseId == 'repeat' || baseId == 'while_loop') {
        _loopStartIndex = i;
        _loopEndIndex = _scriptBlocks.length - 1;
        break;
      }
    }
  }

  // ─── 実行制御 ────────────────────────────────────────────────────────────

  void play() {
    state = state.copyWith(isRunning: true, isPaused: false);
  }

  void pause() {
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    state = state.copyWith(isPaused: false);
  }

  void reset() {
    state = const ExecutionState();
    initializeExecution(_scriptBlocks);
  }

  void setExecutionSpeed(int speed) {
    if (speed >= 1 && speed <= 5) {
      state = state.copyWith(executionSpeed: speed);
    }
  }

  void toggleBreakpoint(int blockIndex) {
    final newBreakpoints = Set<int>.from(state.breakpoints);
    if (newBreakpoints.contains(blockIndex)) {
      newBreakpoints.remove(blockIndex);
    } else {
      newBreakpoints.add(blockIndex);
    }
    state = state.copyWith(breakpoints: newBreakpoints);
  }

  bool hasBreakpoint(int blockIndex) {
    return state.breakpoints.contains(blockIndex);
  }

  /// ステップ実行：1ブロック前に進む
  Future<void> stepForward() async {
    if (_scriptBlocks.isEmpty || state.currentStepIndex >= _scriptBlocks.length) {
      return;
    }

    final currentBlock = _scriptBlocks[state.currentStepIndex];
    await _executeBlock(currentBlock);

    // 次のステップへ
    int nextIndex = state.currentStepIndex + 1;
    String? nextBlockId;

    if (nextIndex < _scriptBlocks.length) {
      nextBlockId = _scriptBlocks[nextIndex].id;
    }

    // ブレークポイントをチェック
    bool hasBreakpointOnNext = state.breakpoints.contains(nextIndex);

    state = state.copyWith(
      currentStepIndex: nextIndex,
      currentBlockId: nextBlockId,
      outputMessage: _getExecutionMessage(currentBlock),
      isPaused: hasBreakpointOnNext, // ブレークポイントで一時停止
    );
  }

  /// ステップ実行：1ステップ前に戻す（シミュレーション再実行）
  void stepBackward() {
    if (state.currentStepIndex <= 0) return;

    // 最初から再実行して目的のステップまで戻す
    _reexecuteToStep(state.currentStepIndex - 1);
  }

  void _reexecuteToStep(int targetStep) {
    double x = _kGridSize / 2;
    double y = _kGridSize / 2;
    double angle = 0;
    final path = <Offset>[Offset(x, y)];
    final variables = <String, dynamic>{};

    // 初期ステップまでのすべてのブロックを実行
    for (int i = 0; i < targetStep && i < _scriptBlocks.length; i++) {
      _simulateBlock(_scriptBlocks[i], path, (nx, ny, na) {
        x = nx;
        y = ny;
        angle = na;
      }, x, y, angle, variables);
    }

    x = path.last.dx;
    y = path.last.dy;

    String? nextBlockId;
    if (targetStep < _scriptBlocks.length) {
      nextBlockId = _scriptBlocks[targetStep].id;
    }

    state = state.copyWith(
      currentStepIndex: targetStep,
      robotX: x,
      robotY: y,
      robotAngle: angle,
      robotPath: path,
      currentBlockId: nextBlockId,
      variables: variables,
    );
  }

  // ─── ブロック実行 ──────────────────────────────────────────────────────

  Future<void> _executeBlock(Block block) async {
    final path = List<Offset>.from(state.robotPath);
    double x = state.robotX;
    double y = state.robotY;
    double angle = state.robotAngle;
    final variables = Map<String, dynamic>.from(state.variables);

    _simulateBlock(block, path, (nx, ny, na) {
      x = nx;
      y = ny;
      angle = na;
    }, x, y, angle, variables);

    x = path.last.dx;
    y = path.last.dy;

    state = state.copyWith(
      robotX: x,
      robotY: y,
      robotAngle: angle,
      robotPath: path,
      lastExecutionSuccess: true,
      variables: variables,
    );
  }

  void _simulateBlock(
    Block block,
    List<Offset> path,
    void Function(double x, double y, double angle) update,
    double x,
    double y,
    double angle,
    Map<String, dynamic> variables,
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
      case 'set_variable':
        final value = block.params['value'] ?? 0;
        variables['count'] = value;
      case 'add_variable':
        variables['count'] = ((variables['count'] as num?) ?? 0) + 1;
      default:
        break;
    }
  }

  String _getExecutionMessage(Block block) {
    final baseId = block.id.split('@').first;
    switch (baseId) {
      case 'move_forward':
        final steps = block.params['steps'] ?? 100;
        return '▶ $steps歩進めました';
      case 'turn_right':
        final deg = block.params['degrees'] ?? 90;
        return '▶ 右に$deg°回転しました';
      case 'turn_left':
        final deg = block.params['degrees'] ?? 90;
        return '▶ 左に$deg°回転しました';
      case 'print_block':
        return '▶ メッセージを表示しました';
      default:
        return '▶ ブロックを実行しました';
    }
  }

  int getExecutionDuration(int speedLevel) {
    // 速度レベルに応じた実行時間（ミリ秒）
    // 遅い（1）: 1000ms、速い（5）: 200ms
    return 1200 - (speedLevel - 1) * 200;
  }
}

final stepExecutorProvider =
    StateNotifierProvider.autoDispose<StepExecutor, ExecutionState>(
        (ref) => StepExecutor());
