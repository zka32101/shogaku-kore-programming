/// ブロックエディタの「段階ヒント」の状態。
///
/// 1回目の不正解: 具体的なヒントを見せる
/// 2回目の不正解: ステージのヒント欄を開く
/// 3回目以降の不正解: 「お手本を見る」を出す（見たら星が1つへる）
class HintLadder {
  /// お手本を見ると星が1つへる。
  static const int fullStars = 3;
  static const int modelPenalty = 1;

  /// 「お手本を見る」を出す不正解の回数。
  static const int modelAvailableAfter = 3;

  int _wrongAttempts = 0;
  bool _hintOpened = false;
  bool _modelViewed = false;

  int get wrongAttempts => _wrongAttempts;
  bool get hintOpened => _hintOpened;
  bool get modelViewed => _modelViewed;

  void recordWrong() => _wrongAttempts++;
  void openHint() => _hintOpened = true;
  void viewModel() => _modelViewed = true;

  /// 2回目の不正解以降は、ステージのヒント欄を自動で開く。
  bool get shouldOpenHintBar => _wrongAttempts >= 2;

  /// 「お手本を見る」を出すか。
  bool get canViewModel => _wrongAttempts >= modelAvailableAfter;

  /// クリア時の星。お手本を見ていたら1つへる。
  int get stars => _modelViewed ? fullStars - modelPenalty : fullStars;

  /// ヒントなしのクリア（不正解なし・ヒント欄を開かない・お手本を見ない）。
  bool get isNoHintClear => _wrongAttempts == 0 && !_hintOpened && !_modelViewed;
}

const Map<String, String> _blockNames = {
  'move_forward': '前に進む',
  'turn_right': '右に回転',
  'turn_left': '左に回転',
  'repeat': '繰り返す',
  'while_loop': 'くり返し(while)',
  'if_wall': 'もし壁があれば',
  'if_condition': 'もし〜ならば',
  'print_block': '表示する',
  'set_variable': '入れ物を作る',
  'add_variable': '入れ物に足す',
};

/// お手本の `expectedOutput`（例: `repeat(4):\n  move_forward(100)`）を、
/// 子ども向けのブロック名の手順（インデント付き）に直す。分からない行はそのまま返す。
List<String> modelSteps(String expectedOutput) {
  final steps = <String>[];
  for (final raw in expectedOutput.split('\n')) {
    if (raw.trim().isEmpty) continue;
    final indent = raw.length - raw.trimLeft().length;
    final line = raw.trim();
    final m = RegExp(r'^(\w+)(?:\(([^)]*)\))?(:)?$').firstMatch(line);
    String text = line;
    if (m != null && _blockNames.containsKey(m.group(1))) {
      final name = _blockNames[m.group(1)]!;
      final arg = m.group(2);
      final base = m.group(1);
      if (arg == null || arg.isEmpty) {
        text = name;
      } else if (base == 'repeat' || base == 'while_loop') {
        text = '$name $arg回';
      } else if (base == 'move_forward') {
        text = '$name $arg歩';
      } else if (base == 'turn_right' || base == 'turn_left') {
        text = '$name $arg°';
      } else {
        text = '$name ($arg)';
      }
    }
    steps.add('${' ' * indent}$text');
  }
  return steps;
}
