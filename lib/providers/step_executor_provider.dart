import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block_model.dart';

const double _kGridSize = 7.0;
const double _kStepsPerCell = 50.0;

// ─── 実行履歴スナップショット ────────────────────────────────────────────────

class ExecutionSnapshot {
  final int stepIndex;
  final double robotX;
  final double robotY;
  final double robotAngle;
  final List<Offset> robotPath;
  final Map<String, dynamic> variables;
  final String outputMessage;

  const ExecutionSnapshot({
    required this.stepIndex,
    required this.robotX,
    required this.robotY,
    required this.robotAngle,
    required this.robotPath,
    required this.variables,
    required this.outputMessage,
  });
}

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

  // 実行履歴
  final List<ExecutionSnapshot> executionHistory;

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
    this.executionHistory = const [],
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
    List<ExecutionSnapshot>? executionHistory,
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
      executionHistory: executionHistory ?? this.executionHistory,
    );
  }
}

// ─── ステップ実行ノティファイア ────────────────────────────────────────────

class StepExecutor extends StateNotifier<ExecutionState> {
  List<Block> _scriptBlocks = [];

  StepExecutor() : super(const ExecutionState());

  // ─── 初期化 ────────────────────────────────────────────────────────────

  void initializeExecution(List<Block> blocks) {
    _scriptBlocks = blocks;

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
    resetToStart();
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

  // ─── 履歴リプレイ ───────────────────────────────────────────────────────

  /// 履歴内の特定のポイントに移動
  void goToHistoryPoint(int historyIndex) {
    if (historyIndex < 0 || historyIndex >= state.executionHistory.length) {
      return;
    }

    final snapshot = state.executionHistory[historyIndex];

    state = state.copyWith(
      currentStepIndex: snapshot.stepIndex + 1,
      robotX: snapshot.robotX,
      robotY: snapshot.robotY,
      robotAngle: snapshot.robotAngle,
      robotPath: snapshot.robotPath,
      variables: snapshot.variables,
      outputMessage: snapshot.outputMessage,
    );
  }

  /// 最初の状態に戻す
  void resetToStart() {
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
      breakpoints: state.breakpoints,
      executionHistory: [],
    );
  }

  // ─── 採点 ─────────────────────────────────────────────────────────────

  /// チャレンジの目標条件をチェック
  ScoringResult checkGoal(Map<String, dynamic>? goalCondition) {
    if (goalCondition == null) {
      return ScoringResult.noGoal();
    }

    final goalX = (goalCondition['goalX'] as num?)?.toDouble();
    final goalY = (goalCondition['goalY'] as num?)?.toDouble();
    final tolerance = (goalCondition['tolerance'] as num?)?.toDouble() ?? 0.5;
    final expectedAngle = (goalCondition['expectedAngle'] as num?)?.toDouble();
    final angleToleranceDeg = (goalCondition['angleToleranceDeg'] as num?)?.toDouble() ?? 45;

    bool isPositionCorrect = false;
    bool isAngleCorrect = false;

    // 位置チェック
    if (goalX != null && goalY != null) {
      final dist = math.sqrt(
        math.pow(state.robotX - goalX, 2) + math.pow(state.robotY - goalY, 2),
      );
      isPositionCorrect = dist <= tolerance;
    } else {
      isPositionCorrect = true; // 位置指定がない場合は OK
    }

    // 角度チェック
    if (expectedAngle != null) {
      var angleDiff = (state.robotAngle - expectedAngle).abs();
      // 360度ラップアラウンド対応
      if (angleDiff > 180) {
        angleDiff = 360 - angleDiff;
      }
      isAngleCorrect = angleDiff <= angleToleranceDeg;
    } else {
      isAngleCorrect = true; // 角度指定がない場合は OK
    }

    final isAchieved = isPositionCorrect && isAngleCorrect;

    return ScoringResult(
      isAchieved: isAchieved,
      currentX: state.robotX,
      currentY: state.robotY,
      currentAngle: state.robotAngle,
      goalX: goalX,
      goalY: goalY,
      expectedAngle: expectedAngle,
      tolerance: tolerance,
      angleToleranceDeg: angleToleranceDeg,
      isPositionCorrect: isPositionCorrect,
      isAngleCorrect: isAngleCorrect,
    );
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

    // 実行履歴に現在の状態をスナップショットとして記録
    final newHistory = List<ExecutionSnapshot>.from(state.executionHistory);
    newHistory.add(
      ExecutionSnapshot(
        stepIndex: state.currentStepIndex,
        robotX: state.robotX,
        robotY: state.robotY,
        robotAngle: state.robotAngle,
        robotPath: List<Offset>.from(state.robotPath),
        variables: Map<String, dynamic>.from(state.variables),
        outputMessage: _getExecutionMessage(currentBlock),
      ),
    );

    state = state.copyWith(
      currentStepIndex: nextIndex,
      currentBlockId: nextBlockId,
      outputMessage: _getExecutionMessage(currentBlock),
      isPaused: hasBreakpointOnNext,
      executionHistory: newHistory,
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

// ─── 採点結果 ──────────────────────────────────────────────────────────

class ScoringResult {
  final bool isAchieved;
  final double? currentX;
  final double? currentY;
  final double? currentAngle;
  final double? goalX;
  final double? goalY;
  final double? expectedAngle;
  final double? tolerance;
  final double? angleToleranceDeg;
  final bool isPositionCorrect;
  final bool isAngleCorrect;

  const ScoringResult({
    required this.isAchieved,
    this.currentX,
    this.currentY,
    this.currentAngle,
    this.goalX,
    this.goalY,
    this.expectedAngle,
    this.tolerance,
    this.angleToleranceDeg,
    this.isPositionCorrect = true,
    this.isAngleCorrect = true,
  });

  factory ScoringResult.noGoal() {
    return const ScoringResult(
      isAchieved: false,
      isPositionCorrect: true,
      isAngleCorrect: true,
    );
  }

  String getMessage() {
    if (!isPositionCorrect && !isAngleCorrect) {
      return '❌ 位置と角度が異なります';
    } else if (!isPositionCorrect) {
      return '❌ 位置がずれています';
    } else if (!isAngleCorrect) {
      return '❌ 角度が異なります';
    } else if (isAchieved) {
      return '✅ 成功！目標に到達しました！';
    }
    return '';
  }

  String getDetailMessage() {
    if (goalX == null || goalY == null) {
      return '目標条件が設定されていません';
    }
    return '現在位置: ($currentX, $currentY)\n目標位置: ($goalX, $goalY)';
  }
}

final stepExecutorProvider =
    StateNotifierProvider.autoDispose<StepExecutor, ExecutionState>(
        (ref) => StepExecutor());
