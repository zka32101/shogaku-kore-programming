import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../models/robot_stage.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'robot_stage_editor_screen.dart';
import 'stage_share_screen.dart';

/// ゴール付きロボットゲーム。
///
/// ブロック（すすむ／まがる／くりかえす）を並べてロボットを動かし、
/// かべにぶつからずにコインを集めてゴールをめざす。ブロックが少ないほど星が多い。
/// 内蔵ステージのほか、友だちが作って送ってくれたステージも同じ画面で遊べる。

const int _kGrid = RobotStage.gridSize;
const String _kPrefsKey = 'robot_game_stars_v1';

/// 向き: 0=右 1=下 2=左 3=上（右に回ると +1）
const _dx = [1, 0, -1, 0];
const _dy = [0, 1, 0, -1];

enum _Cmd { forward, left, right, repeat }

const kBuiltInRobotStages = <RobotStage>[
  RobotStage(
    id: 'built_1',
    title: 'まっすぐ',
    hint: '「すすむ」を何回か入れて、🚩まで行こう。「くりかえす」を使うと ブロックが少なくてすむよ！',
    rows: ['.....', '.....', 'S...G', '.....', '.....'],
    par: 2,
  ),
  RobotStage(
    id: 'built_2',
    title: 'まがりかど',
    hint: '右にまがる ブロックを使って、かべをよけよう。',
    rows: ['S.#..', '..#..', '..#..', '....G', '.....'],
    par: 7,
  ),
  RobotStage(
    id: 'built_3',
    title: 'コインあつめ',
    hint: '🪙を ぜんぶ 集めてから、🚩にたどりつこう。',
    rows: ['SCCC.', '.....', '.....', '.....', '....G'],
    par: 7,
  ),
  RobotStage(
    id: 'built_4',
    title: 'ななめに進め',
    hint: '「すすむ→右→すすむ→左」をくりかえすと、ななめに進めるよ。',
    rows: ['S.###', '#..##', '##..#', '###..', '####G'],
    par: 5,
  ),
  RobotStage(
    id: 'built_5',
    title: 'ぐるっと一周',
    hint: '四角をなぞるように動かして、🪙をぜんぶ集めよう。',
    rows: ['.....', '.S.C.', '.....', '.G.C.', '.....'],
    par: 4,
  ),
];

// ─── ステージ選択 ─────────────────────────────────────────────────────────────

class RobotGameScreen extends StatefulWidget {
  const RobotGameScreen({super.key});

  @override
  State<RobotGameScreen> createState() => _RobotGameScreenState();
}

class _RobotGameScreenState extends State<RobotGameScreen> {
  List<int> _stars = List.filled(kBuiltInRobotStages.length, 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<int>();
      final stars = List<int>.filled(kBuiltInRobotStages.length, 0);
      for (var i = 0; i < math.min(list.length, stars.length); i++) {
        stars[i] = list[i];
      }
      if (mounted) setState(() => _stars = stars);
    } catch (_) {
      // 記録が読めなくてもゲームは遊べる
    }
  }

  Future<void> _save(int index, int stars) async {
    if (stars <= _stars[index]) return;
    setState(() => _stars[index] = stars);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefsKey, jsonEncode(_stars));
    } catch (_) {}
  }

  Future<void> _open(int index) async {
    HapticService.lightImpact();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RobotGamePlay(
          stages: kBuiltInRobotStages,
          startIndex: index,
          onCleared: (i, stars, blocks) => _save(i, stars),
        ),
      ),
    );
  }

  void _push(Widget screen) {
    HapticService.lightImpact();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final total = _stars.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 ロボットゲーム'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ブロックでロボットを動かして、🚩ゴールをめざそう！ブロックが少ないほど ⭐がふえるよ。',
            style: TextStyle(fontSize: 14, height: 1.6, color: context.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _friendButton(
                  '🛠️ ステージを作る',
                  () => _push(const RobotStageEditorScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _friendButton(
                  '🤝 ともだちステージ',
                  () => _push(const StageShareScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'あつめた ⭐ $total / ${kBuiltInRobotStages.length * 3}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < kBuiltInRobotStages.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _open(i),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kPrimaryColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: kPrimaryColor,
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kBuiltInRobotStages[i].title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '★' * _stars[i] + '☆' * (3 - _stars[i]),
                        style: const TextStyle(color: Colors.amber, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _friendButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}

// ─── プレイ画面 ───────────────────────────────────────────────────────────────

/// [stages] のうち [startIndex] のステージから遊ぶ。クリアすると次のステージへ進める。
/// クリアするたびに [onCleared] が呼ばれる（ステージ番号・星・使ったブロック数）。
class RobotGamePlay extends StatefulWidget {
  final List<RobotStage> stages;
  final int startIndex;
  final void Function(int index, int stars, int blocks) onCleared;

  /// false のときは星の数や「⭐3つの基準」を表示しない（ステージ作成中の試しあそび用）。
  final bool showStars;

  const RobotGamePlay({
    super.key,
    required this.stages,
    this.startIndex = 0,
    required this.onCleared,
    this.showStars = true,
  });

  @override
  State<RobotGamePlay> createState() => _RobotGamePlayState();
}

class _RobotGamePlayState extends State<RobotGamePlay> {
  late int _index = widget.startIndex;
  final List<_Cmd> _program = [];
  int _repeatCount = 3;

  // 実行状態
  late int _rx, _ry, _rdir;
  late Set<int> _coins; // y * _kGrid + x
  bool _running = false;
  bool _cancel = false;
  String? _message;
  bool? _success;
  int _stars = 0;
  int? _activeIndex; // 実行中のブロック

  RobotStage get _stage => widget.stages[_index];

  bool _isWall(int x, int y) => _stage.rows[y][x] == '#';
  bool _isGoal(int x, int y) => _stage.rows[y][x] == 'G';

  @override
  void initState() {
    super.initState();
    _resetRobot();
  }

  @override
  void dispose() {
    _cancel = true;
    super.dispose();
  }

  void _resetRobot() {
    _coins = {};
    for (var y = 0; y < _kGrid; y++) {
      for (var x = 0; x < _kGrid; x++) {
        final c = _stage.rows[y][x];
        if (c == 'S') {
          _rx = x;
          _ry = y;
        } else if (c == 'C') {
          _coins.add(y * _kGrid + x);
        }
      }
    }
    _rdir = 0;
    _message = null;
    _success = null;
    _activeIndex = null;
  }

  void _add(_Cmd cmd) {
    if (_running) return;
    if (cmd == _Cmd.repeat && _program.contains(_Cmd.repeat)) return;
    if (_program.length >= RobotStage.maxBlocks) return;
    HapticService.lightImpact();
    setState(() {
      _program.add(cmd);
      _resetRobot();
    });
  }

  void _removeAt(int i) {
    if (_running) return;
    setState(() {
      _program.removeAt(i);
      _resetRobot();
    });
  }

  void _clear() {
    if (_running) return;
    setState(() {
      _program.clear();
      _resetRobot();
    });
  }

  /// 実行順に並べた（ブロック番号つき）命令列を作る。
  /// くりかえすブロックより前は1回、後ろは回数ぶん くりかえす。
  List<int> _executionOrder() {
    final rep = _program.indexOf(_Cmd.repeat);
    if (rep < 0) return List.generate(_program.length, (i) => i);
    final order = <int>[for (var i = 0; i < rep; i++) i];
    for (var r = 0; r < _repeatCount; r++) {
      for (var i = rep + 1; i < _program.length; i++) {
        order.add(i);
      }
    }
    return order;
  }

  Future<void> _run() async {
    if (_running || _program.isEmpty) return;
    HapticService.lightImpact();
    setState(() {
      _resetRobot();
      _running = true;
      _cancel = false;
    });

    for (final index in _executionOrder()) {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted || _cancel) return;
      final cmd = _program[index];
      setState(() => _activeIndex = index);
      if (cmd == _Cmd.left) {
        setState(() => _rdir = (_rdir + 3) % 4);
      } else if (cmd == _Cmd.right) {
        setState(() => _rdir = (_rdir + 1) % 4);
      } else if (cmd == _Cmd.forward) {
        final nx = _rx + _dx[_rdir];
        final ny = _ry + _dy[_rdir];
        if (nx < 0 || ny < 0 || nx >= _kGrid || ny >= _kGrid || _isWall(nx, ny)) {
          SoundService().playWrong();
          setState(() {
            _running = false;
            _success = false;
            _message = 'いたっ！ かべにぶつかったよ。ブロックを見直してみよう。';
          });
          return;
        }
        setState(() {
          _rx = nx;
          _ry = ny;
          _coins.remove(ny * _kGrid + nx);
        });
      }
    }

    if (!mounted) return;
    final reached = _isGoal(_rx, _ry);
    if (reached && _coins.isEmpty) {
      final used = _program.length;
      final stars = _stage.starsFor(used);
      SoundService().playCorrect();
      widget.onCleared(_index, stars, used);
      setState(() {
        _running = false;
        _success = true;
        _stars = stars;
        _activeIndex = null;
        _message = 'クリア！ ブロック $used こ';
      });
    } else {
      SoundService().playWrong();
      setState(() {
        _running = false;
        _success = false;
        _activeIndex = null;
        _message = reached
            ? 'ゴールに着いたけど、🪙がのこっているよ。ぜんぶ集めよう！'
            : 'ゴールまで とどかなかったよ。ブロックをふやしてみよう。';
      });
    }
  }

  void _goNext() {
    if (_index + 1 >= widget.stages.length) return;
    setState(() {
      _index++;
      _program.clear();
      _repeatCount = 3;
      _resetRobot();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = _index + 1 < widget.stages.length;
    final showNumber = widget.stages.length > 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(showNumber ? '${_index + 1}. ${_stage.title}' : _stage.title),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_stage.hint.isNotEmpty) ...[
              Text(
                _stage.hint,
                style: TextStyle(fontSize: 13, height: 1.5, color: context.textSecondary),
              ),
              const SizedBox(height: 10),
            ],
            _buildBoard(context),
            const SizedBox(height: 10),
            if (_message != null) _buildResult(context, hasNext),
            _buildPalette(context),
            const SizedBox(height: 10),
            _buildProgram(context),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _running || _program.isEmpty ? null : _clear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ぜんぶ消す'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _running || _program.isEmpty ? null : _run,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('スタート！'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = math.min(c.maxWidth, 340.0);
      final cell = side / _kGrid;
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
              for (var y = 0; y < _kGrid; y++)
                for (var x = 0; x < _kGrid; x++)
                  Positioned(
                    left: x * cell,
                    top: y * cell,
                    width: cell,
                    height: cell,
                    child: _buildCell(context, x, y, cell),
                  ),
              // ロボット（なめらかに動く）
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _rx * cell,
                top: _ry * cell,
                width: cell,
                height: cell,
                child: _buildRobot(cell),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCell(BuildContext context, int x, int y, double cell) {
    final ch = _stage.rows[y][x];
    String? emoji;
    if (ch == '#') {
      emoji = '🧱';
    } else if (ch == 'G') {
      emoji = '🚩';
    } else if (_coins.contains(y * _kGrid + x)) {
      emoji = '🪙';
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
        color: ch == '#' ? Colors.brown.withValues(alpha: 0.12) : null,
      ),
      alignment: Alignment.center,
      child: emoji == null
          ? null
          : Text(emoji, style: TextStyle(fontSize: cell * 0.5)),
    );
  }

  Widget _buildRobot(double cell) {
    const aligns = [
      Alignment.centerRight,
      Alignment.bottomCenter,
      Alignment.centerLeft,
      Alignment.topCenter,
    ];
    return Stack(
      alignment: Alignment.center,
      children: [
        Text('🤖', style: TextStyle(fontSize: cell * 0.55)),
        Align(
          alignment: aligns[_rdir],
          child: Transform.rotate(
            angle: _rdir * math.pi / 2,
            child: Icon(Icons.play_arrow, size: cell * 0.28, color: kPrimaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, bool hasNext) {
    final ok = _success == true;
    final color = ok ? kPrimaryColor : const Color(0xFFE67E22);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ok && widget.showStars)
            Text(
              '${'★' * _stars}${'☆' * (3 - _stars)}',
              style: const TextStyle(color: Colors.amber, fontSize: 26),
            ),
          Text(
            _message ?? '',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          if (ok && widget.showStars && _stars < 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'ブロック ${_stage.par} こ以下で ⭐3つ！ 「くりかえす」を使うとへらせるよ。',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ),
          if (ok && hasNext)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _goNext,
                child: const Text('つぎのステージへ'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paletteButton(String label, _Cmd cmd, {bool enabled = true}) {
    return ElevatedButton(
      onPressed: enabled && !_running ? () => _add(cmd) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor.withValues(alpha: 0.12),
        foregroundColor: context.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildPalette(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _paletteButton('⬆️ すすむ', _Cmd.forward),
        _paletteButton('↩️ 左にまがる', _Cmd.left),
        _paletteButton('↪️ 右にまがる', _Cmd.right),
        _paletteButton(
          '🔁 くりかえす',
          _Cmd.repeat,
          enabled: !_program.contains(_Cmd.repeat),
        ),
      ],
    );
  }

  String _label(_Cmd c) {
    switch (c) {
      case _Cmd.forward:
        return '⬆️ すすむ';
      case _Cmd.left:
        return '↩️ 左にまがる';
      case _Cmd.right:
        return '↪️ 右にまがる';
      case _Cmd.repeat:
        return '🔁 このあとを $_repeatCount 回くりかえす';
    }
  }

  Widget _buildProgram(BuildContext context) {
    if (_program.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
        ),
        child: Text(
          '上のボタンを押して、ブロックをならべよう',
          style: TextStyle(fontSize: 13, color: context.textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.showStars
              ? 'ブロック ${_program.length} こ（⭐3つは ${_stage.par} こ以下）'
              : 'ブロック ${_program.length} こ',
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < _program.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _activeIndex == i
                  ? kPrimaryColor.withValues(alpha: 0.3)
                  : kPrimaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: _program[i] == _Cmd.repeat
                  ? Border.all(color: kPrimaryColor.withValues(alpha: 0.6))
                  : null,
            ),
            child: Row(
              children: [
                Text('${i + 1}.', style: TextStyle(color: context.textSecondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _label(_program[i]),
                    style: TextStyle(fontSize: 13, color: context.textPrimary),
                  ),
                ),
                if (_program[i] == _Cmd.repeat && !_running)
                  GestureDetector(
                    onTap: () => setState(() {
                      _repeatCount = _repeatCount >= 5 ? 2 : _repeatCount + 1;
                      _resetRobot();
                    }),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.autorenew, size: 18, color: kPrimaryColor),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _removeAt(i),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
