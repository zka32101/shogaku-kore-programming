import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// ロボットの動きを可視化するキャンバスウィジェット
class RobotCanvasWidget extends StatefulWidget {
  final List<Offset> path;       // 正規化座標 (0–gridSize)
  final double finalAngle;       // ロボットの最終向き（度）
  final bool hasSubmitted;
  final bool isCorrect;
  final double gridSize;         // グリッドのセル数（デフォルト 7）

  const RobotCanvasWidget({
    super.key,
    required this.path,
    required this.finalAngle,
    required this.hasSubmitted,
    required this.isCorrect,
    this.gridSize = 7.0,
  });

  @override
  State<RobotCanvasWidget> createState() => _RobotCanvasWidgetState();
}

class _RobotCanvasWidgetState extends State<RobotCanvasWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    if (widget.path.length > 1) {
      _animController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(RobotCanvasWidget old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path && widget.path.length > 1) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        return CustomPaint(
          painter: _RobotPainter(
            path: widget.path,
            finalAngle: widget.finalAngle,
            progress: widget.path.length > 1 ? _progress.value : 1.0,
            hasSubmitted: widget.hasSubmitted,
            isCorrect: widget.isCorrect,
            gridSize: widget.gridSize,
          ),
        );
      },
    );
  }
}

class _RobotPainter extends CustomPainter {
  final List<Offset> path;
  final double finalAngle;
  final double progress;
  final bool hasSubmitted;
  final bool isCorrect;
  final double gridSize;

  const _RobotPainter({
    required this.path,
    required this.finalAngle,
    required this.progress,
    required this.hasSubmitted,
    required this.isCorrect,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 正方形セルにするため短辺を基準にする
    final cell = math.min(size.width, size.height) / gridSize;
    final offsetX = (size.width - cell * gridSize) / 2;
    final offsetY = (size.height - cell * gridSize) / 2;

    // ─── グリッド描画 ───────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= gridSize.toInt(); i++) {
      canvas.drawLine(
        Offset(offsetX + i * cell, offsetY),
        Offset(offsetX + i * cell, offsetY + cell * gridSize),
        gridPaint,
      );
      canvas.drawLine(
        Offset(offsetX, offsetY + i * cell),
        Offset(offsetX + cell * gridSize, offsetY + i * cell),
        gridPaint,
      );
    }

    if (path.isEmpty) return;

    // ─── スタートマーカー ──────────────────────────────────
    final startPx = _toPx(path.first, cell, offsetX, offsetY);
    final startPaint = Paint()..color = kPrimaryColor.withValues(alpha: 0.8);
    canvas.drawCircle(startPx, 6, startPaint);

    if (path.length < 2) return;

    // ─── パス描画（アニメーション付き） ─────────────────────
    final color = hasSubmitted
        ? (isCorrect ? kPrimaryColor : Colors.red)
        : kPrimaryColor;

    final pathPaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // プログレスに応じて描画するパスを切り出す
    final totalSegments = path.length - 1;
    final drawnSegments = (totalSegments * progress).clamp(0, totalSegments);
    final fullSegments = drawnSegments.floor();
    final partialFrac = drawnSegments - fullSegments;

    final drawPath = Path();
    drawPath.moveTo(
      _toPx(path[0], cell, offsetX, offsetY).dx,
      _toPx(path[0], cell, offsetX, offsetY).dy,
    );

    for (int i = 0; i < fullSegments; i++) {
      final p = _toPx(path[i + 1], cell, offsetX, offsetY);
      drawPath.lineTo(p.dx, p.dy);
    }

    // 最後の部分的なセグメント
    if (fullSegments < totalSegments && partialFrac > 0) {
      final from = _toPx(path[fullSegments], cell, offsetX, offsetY);
      final to = _toPx(path[fullSegments + 1], cell, offsetX, offsetY);
      final mid = Offset(
        from.dx + (to.dx - from.dx) * partialFrac,
        from.dy + (to.dy - from.dy) * partialFrac,
      );
      drawPath.lineTo(mid.dx, mid.dy);
    }

    canvas.drawPath(drawPath, pathPaint);

    // ─── 足あと（通過済みの頂点にうっすら残す） ───────────────
    final footPaint = Paint();
    for (int i = 1; i < fullSegments; i++) {
      final p = _toPx(path[i], cell, offsetX, offsetY);
      final recency = fullSegments <= 1 ? 1.0 : i / fullSegments;
      footPaint.color = color.withValues(alpha: 0.10 + 0.18 * recency);
      canvas.drawCircle(p, 2.6, footPaint);
    }

    // ─── ロボット現在位置 ───────────────────────────────────
    final robotSegmentIdx =
        (totalSegments * progress).clamp(0, totalSegments.toDouble()).floor();
    final Offset robotPos;
    if (robotSegmentIdx >= totalSegments) {
      robotPos = _toPx(path.last, cell, offsetX, offsetY);
    } else {
      final from = _toPx(path[robotSegmentIdx], cell, offsetX, offsetY);
      final to = _toPx(path[robotSegmentIdx + 1], cell, offsetX, offsetY);
      final frac = (totalSegments * progress) - robotSegmentIdx;
      robotPos = Offset(
        from.dx + (to.dx - from.dx) * frac,
        from.dy + (to.dy - from.dy) * frac,
      );
    }

    // 移動中は一歩ごとにぴょんと跳ねるアニメーション
    final hopPhase = drawnSegments - drawnSegments.floorToDouble();
    final hop = (!hasSubmitted && progress < 1.0)
        ? math.sin(hopPhase * math.pi) * 2.5
        : 0.0;
    final bodyPos = Offset(robotPos.dx, robotPos.dy - hop);

    // ロボット本体（円 + 顔 + 方向矢印）
    final robotBg = Paint()
      ..color = hasSubmitted
          ? (isCorrect ? kPrimaryColor : Colors.red)
          : kPrimaryColor;
    canvas.drawCircle(bodyPos, 10, robotBg);

    // 方向矢印
    final arrowAngleRad = finalAngle * math.pi / 180.0;
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final arrowEnd = Offset(
      bodyPos.dx + math.cos(arrowAngleRad) * 7,
      bodyPos.dy + math.sin(arrowAngleRad) * 7,
    );
    canvas.drawLine(bodyPos, arrowEnd, arrowPaint);

    // かわいい顔（アンテナ＋目）
    _drawRobotFace(canvas, bodyPos, hasSubmitted, isCorrect);

    // ─── ゴールマーカー（最終位置） ─────────────────────────
    if (progress >= 1.0) {
      final goalPx = _toPx(path.last, cell, offsetX, offsetY);
      if (hasSubmitted && isCorrect) {
        _drawStarAt(canvas, goalPx, 12, Colors.amber);
        _drawSparkles(canvas, goalPx);
      }
    }
  }

  // ─── ロボットの顔 ───────────────────────────────────────────
  void _drawRobotFace(Canvas canvas, Offset pos, bool submitted, bool correct) {
    // アンテナ
    canvas.drawLine(
      Offset(pos.dx, pos.dy - 10),
      Offset(pos.dx, pos.dy - 14),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(Offset(pos.dx, pos.dy - 14), 1.5, Paint()..color = Colors.white);

    final leftEye = pos + const Offset(-3, -1);
    final rightEye = pos + const Offset(3, -1);

    if (submitted && !correct) {
      // 残念そうな ×× の目
      _drawX(canvas, leftEye, 2.0);
      _drawX(canvas, rightEye, 2.0);
      return;
    }

    if (submitted && correct) {
      // うれしそうな ^ ^ の目
      _drawHappyEye(canvas, leftEye);
      _drawHappyEye(canvas, rightEye);
      return;
    }

    // 通常時: まん丸の目
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(leftEye, 1.6, eyePaint);
    canvas.drawCircle(rightEye, 1.6, eyePaint);
  }

  void _drawX(Canvas canvas, Offset center, double r) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + Offset(-r, -r), center + Offset(r, r), p);
    canvas.drawLine(center + Offset(-r, r), center + Offset(r, -r), p);
  }

  void _drawHappyEye(Canvas canvas, Offset center) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromCenter(center: center, width: 4, height: 4);
    // 上向きの弧 (^) を描画
    canvas.drawArc(rect, math.pi, math.pi, false, p);
  }

  // ─── 正解時のキラキラ演出 ────────────────────────────────────
  void _drawSparkles(Canvas canvas, Offset center) {
    const offsets = [
      Offset(-18, -12),
      Offset(18, -10),
      Offset(-14, 14),
      Offset(16, 14),
      Offset(2, -20),
    ];
    for (final o in offsets) {
      _drawStarAt(canvas, center + o, 3, Colors.amber.withValues(alpha: 0.85));
    }
  }

  Offset _toPx(Offset gridPos, double cell, double offsetX, double offsetY) {
    return Offset(offsetX + gridPos.dx * cell, offsetY + gridPos.dy * cell);
  }

  void _drawStarAt(Canvas canvas, Offset center, double radius, Color color) {
    const points = 5;
    final paint = Paint()..color = color;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.4;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.path != path ||
      old.progress != progress ||
      old.hasSubmitted != hasSubmitted ||
      old.isCorrect != isCorrect;
}
