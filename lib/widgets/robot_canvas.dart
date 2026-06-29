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

    // ロボット本体（円 + 方向矢印）
    final robotBg = Paint()
      ..color = hasSubmitted
          ? (isCorrect ? kPrimaryColor : Colors.red)
          : kPrimaryColor;
    canvas.drawCircle(robotPos, 10, robotBg);

    // 方向矢印
    final arrowAngleRad = finalAngle * math.pi / 180.0;
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final arrowEnd = Offset(
      robotPos.dx + math.cos(arrowAngleRad) * 7,
      robotPos.dy + math.sin(arrowAngleRad) * 7,
    );
    canvas.drawLine(robotPos, arrowEnd, arrowPaint);

    // ─── ゴールマーカー（最終位置） ─────────────────────────
    if (progress >= 1.0) {
      final goalPx = _toPx(path.last, cell, offsetX, offsetY);
      if (hasSubmitted && isCorrect) {
        _drawStarAt(canvas, goalPx, 12, Colors.amber);
      }
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
