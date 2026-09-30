import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/robot_stage.dart';
import '../services/haptic_service.dart';
import '../services/stage_share_service.dart';
import 'robot_game_screen.dart';

/// 自分だけのロボットステージを作る画面。
///
/// かべ・コイン・スタート・ゴールを置いて、**自分でクリアできたら**登録できる。
/// （解けないステージが友だちに届かないようにするため。ブロック数が「3つ星の基準」になる）
/// ステージ名は自由入力ではなく、用意された名前から選ぶ。
class RobotStageEditorScreen extends StatefulWidget {
  const RobotStageEditorScreen({super.key});

  @override
  State<RobotStageEditorScreen> createState() => _RobotStageEditorScreenState();
}

enum _Tool { start, goal, wall, coin, erase }

const _kTitles = [
  'ぐるぐるめいろ',
  'コインだいすき',
  'かべをよけろ',
  'ちょうせんじょう',
  'ひみつのみち',
  'ジグザグ',
  'いそげ！',
  'ロボのぼうけん',
  'まよいのもり',
  'おたのしみステージ',
];

class _RobotStageEditorScreenState extends State<RobotStageEditorScreen> {
  static const int _n = RobotStage.gridSize;

  late final List<List<String>> _grid = [
    for (var y = 0; y < _n; y++)
      [for (var x = 0; x < _n; x++) y == 2 && x == 0 ? 'S' : (y == 2 && x == _n - 1 ? 'G' : '.')],
  ];
  _Tool _tool = _Tool.wall;
  int? _clearedBlocks; // 自分でクリアできたときの最少ブロック数（盤面を変えると消える）

  List<String> get _rows => [for (final r in _grid) r.join()];

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  void _tap(int x, int y) {
    final cur = _grid[y][x];
    final tool = _tool;
    if (tool == _Tool.start || tool == _Tool.goal) {
      final mark = tool == _Tool.start ? 'S' : 'G';
      final other = tool == _Tool.start ? 'G' : 'S';
      if (cur == other) {
        _snack('そこには ${tool == _Tool.start ? '🚩ゴール' : '🤖スタート'} があるよ');
        return;
      }
      setState(() {
        for (final row in _grid) {
          for (var i = 0; i < _n; i++) {
            if (row[i] == mark) row[i] = '.';
          }
        }
        _grid[y][x] = mark;
        _clearedBlocks = null;
      });
    } else if (tool == _Tool.erase) {
      if (cur == 'S' || cur == 'G') {
        _snack('🤖と🚩は 消せないよ。べつの場所に おきなおしてね');
        return;
      }
      setState(() {
        _grid[y][x] = '.';
        _clearedBlocks = null;
      });
    } else {
      if (cur == 'S' || cur == 'G') {
        _snack('🤖と🚩の上には おけないよ');
        return;
      }
      final mark = tool == _Tool.wall ? '#' : 'C';
      setState(() {
        _grid[y][x] = cur == mark ? '.' : mark;
        _clearedBlocks = null;
      });
    }
    HapticService.lightImpact();
  }

  void _clearAll() {
    setState(() {
      for (var y = 0; y < _n; y++) {
        for (var x = 0; x < _n; x++) {
          if (_grid[y][x] != 'S' && _grid[y][x] != 'G') _grid[y][x] = '.';
        }
      }
      _clearedBlocks = null;
    });
  }

  Future<void> _tryPlay() async {
    final problem = RobotStage.validate(_rows);
    if (problem != null) {
      _snack(problem);
      return;
    }
    final draft = RobotStage(id: 'draft', title: 'ためしにあそぶ', rows: _rows, par: 1);
    final before = _rows.join('/');
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RobotGamePlay(
          stages: [draft],
          showStars: false,
          onCleared: (i, stars, blocks) {
            _clearedBlocks =
                _clearedBlocks == null ? blocks : math.min(_clearedBlocks!, blocks);
          },
        ),
      ),
    );
    if (!mounted) return;
    // プレイ中に盤面が変わることはないが、念のため確認する
    if (before != _rows.join('/')) _clearedBlocks = null;
    setState(() {});
  }

  Future<void> _register() async {
    final blocks = _clearedBlocks;
    if (blocks == null) return;
    String title = _kTitles.first;
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('ステージの名前をえらぼう'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in _kTitles)
                  ChoiceChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    selected: title == t,
                    onSelected: (_) => setLocal(() => title = t),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('やめる')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, title),
              child: const Text('とうろくする'),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    final stage = RobotStage(
      id: 'st_${DateTime.now().microsecondsSinceEpoch}',
      title: chosen,
      rows: _rows,
      par: blocks,
    );
    final ok = await CreatedStageStore().add(stage);
    if (!mounted) return;
    if (!ok) {
      _snack('作れるステージは ${CreatedStageStore.maxStages} こまで。古いのを消してね');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cleared = _clearedBlocks;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ ステージを作る'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'ペンをえらんで、ますをタップ！ 作ったら 自分でクリアしてみよう。クリアできたステージだけ 友だちに送れるよ。',
              style: TextStyle(fontSize: 13, height: 1.6, color: context.textSecondary),
            ),
            const SizedBox(height: 10),
            _buildBoard(context),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _toolChip('🤖 スタート', _Tool.start),
                _toolChip('🚩 ゴール', _Tool.goal),
                _toolChip('🧱 かべ', _Tool.wall),
                _toolChip('🪙 コイン', _Tool.coin),
                _toolChip('🧽 けす', _Tool.erase),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('かべとコインを全部消す'),
              ),
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _tryPlay,
              icon: const Icon(Icons.play_arrow),
              label: const Text('じぶんでクリアしてみる'),
            ),
            const SizedBox(height: 10),
            if (cleared != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'クリアできたよ！ ブロック $cleared こ。これが ⭐3つの きじゅんになるよ。',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
              ),
            ElevatedButton.icon(
              onPressed: cleared == null ? null : _register,
              icon: const Icon(Icons.save_alt),
              label: Text(cleared == null ? 'クリアすると とうろくできるよ' : 'このステージをとうろく'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolChip(String label, _Tool tool) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: _tool == tool,
      onSelected: (_) => setState(() => _tool = tool),
    );
  }

  Widget _buildBoard(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = math.min(c.maxWidth, 340.0);
      final cell = side / _n;
      return Center(
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryColor.withValues(alpha: 0.4), width: 2),
          ),
          child: Stack(
            children: [
              for (var y = 0; y < _n; y++)
                for (var x = 0; x < _n; x++)
                  Positioned(
                    left: x * cell,
                    top: y * cell,
                    width: cell,
                    height: cell,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _tap(x, y),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
                          color: _grid[y][x] == '#' ? Colors.brown.withValues(alpha: 0.12) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          switch (_grid[y][x]) {
                            'S' => '🤖',
                            'G' => '🚩',
                            '#' => '🧱',
                            'C' => '🪙',
                            _ => '',
                          },
                          style: TextStyle(fontSize: cell * 0.5),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    });
  }
}
