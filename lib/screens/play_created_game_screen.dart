import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/user_work.dart';
import '../utils/robot_simulator.dart';
import '../widgets/robot_canvas.dart';

/// ギャラリーに保存した作品（ブロックの組み合わせ）を実際に再生して
/// 動きを見られる画面。
class PlayCreatedGameScreen extends StatefulWidget {
  final UserWork work;

  const PlayCreatedGameScreen({super.key, required this.work});

  @override
  State<PlayCreatedGameScreen> createState() => _PlayCreatedGameScreenState();
}

class _PlayCreatedGameScreenState extends State<PlayCreatedGameScreen> {
  late List<Offset> _path;
  late double _angle;
  int _replayCount = 0;

  @override
  void initState() {
    super.initState();
    _simulate();
  }

  void _simulate() {
    final (path, angle) = simulateRobot(widget.work.blocks);
    _path = path;
    _angle = angle;
  }

  void _replay() {
    setState(() {
      // path の参照を変えて RobotCanvasWidget のアニメーションを再トリガーする
      _path = [..._path];
      _replayCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.work.blocks;

    return Scaffold(
      backgroundColor: context.cardBg,
      appBar: AppBar(
        title: Text(widget.work.challengeTitle),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: blocks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'この作品は古い形式で保存されていて\n再生できません😢',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            )
          : Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: RobotCanvasWidget(
                      key: ValueKey(_replayCount),
                      path: _path,
                      finalAngle: _angle,
                      hasSubmitted: false,
                      isCorrect: false,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _replay,
                    icon: const Icon(Icons.replay),
                    label: const Text('もう一度さいせい'),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: blocks.length,
                    itemBuilder: (context, index) {
                      final block = blocks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text('${index + 1}.',
                                style:
                                    TextStyle(color: context.textSecondary)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                block.displayText,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
