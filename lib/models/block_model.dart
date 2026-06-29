enum BlockCategory {
  motion,    // 動き
  control,   // 制御
  variable,  // 変数
  function,  // 関数
}

class Block {
  final String id;
  final String name;
  final String icon;
  final BlockCategory category;
  final Map<String, dynamic> params;
  final String description; // ブロックの説明文

  Block({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    Map<String, dynamic>? params,
    this.description = '',
  }) : params = params ?? {};

  Block copyWith({Map<String, dynamic>? params}) {
    return Block(
      id: id,
      name: name,
      icon: icon,
      category: category,
      description: description,
      params: params ?? this.params,
    );
  }

  String get _baseId => id.split('@').first;

  String get displayText {
    switch (_baseId) {
      case 'move_forward':
        return '📍 前に${params['steps'] ?? 100}歩進む';
      case 'turn_right':
        return '🔄 右に${params['degrees'] ?? 90}°回転';
      case 'turn_left':
        return '🔄 左に${params['degrees'] ?? 90}°回転';
      case 'repeat':
        return '🔁 ${params['times'] ?? 3}回繰り返す';
      case 'if_wall':
        return '❓ もし壁があれば';
      case 'stop':
        return '🏁 止まる';
      case 'set_variable':
        return '📦 変数 count = ${params['value'] ?? 0}';
      case 'add_variable':
        return '➕ count に1を足す';
      case 'if_condition':
        return '🔀 もし〜ならば';
      case 'while_loop':
        return '🔄 whileループ ${params['times'] ?? 3}回';
      case 'print_block':
        return '📢 こんにちは！と表示';
      default:
        return name;
    }
  }
}

// 使用可能なブロック一覧
final List<Block> kAvailableBlocks = [
  Block(
    id: 'move_forward',
    name: '前に進む',
    icon: '📍',
    category: BlockCategory.motion,
    params: {'steps': 100},
    description: 'ロボットを指定した歩数だけ前に進めるよ。タップして歩数を変えられるよ。',
  ),
  Block(
    id: 'turn_right',
    name: '右に回転',
    icon: '🔄',
    category: BlockCategory.motion,
    params: {'degrees': 90},
    description: 'ロボットを右（時計回り）に回転させるよ。90°で直角に曲がれるよ。',
  ),
  Block(
    id: 'turn_left',
    name: '左に回転',
    icon: '🔄',
    category: BlockCategory.motion,
    params: {'degrees': 90},
    description: 'ロボットを左（反時計回り）に回転させるよ。90°で直角に曲がれるよ。',
  ),
  Block(
    id: 'repeat',
    name: '繰り返す',
    icon: '🔁',
    category: BlockCategory.control,
    params: {'times': 3},
    description: '同じ処理を指定した回数だけ繰り返すよ。for ループと同じ仕組みだよ。',
  ),
  Block(
    id: 'if_wall',
    name: 'もし〜なら',
    icon: '❓',
    category: BlockCategory.control,
    description: '条件が成り立つときだけ処理を実行するよ。if 文と同じ仕組みだよ。',
  ),
  Block(
    id: 'stop',
    name: '止まる',
    icon: '🏁',
    category: BlockCategory.control,
    description: 'ロボットをその場で止めるよ。目標の場所に着いたら使おう。',
  ),
  Block(
    id: 'set_variable',
    name: '変数を使う',
    icon: '📦',
    category: BlockCategory.variable,
    params: {'value': 0},
    description: '数を入れておく箱（変数）を作るよ。あとで取り出して使えるよ。',
  ),
  Block(
    id: 'add_variable',
    name: '変数に足す',
    icon: '➕',
    category: BlockCategory.variable,
    description: '変数の中の数に1を足すよ。「カウント」したいときに使うよ。',
  ),
  Block(
    id: 'if_condition',
    name: 'もし〜ならば',
    icon: '🔀',
    category: BlockCategory.control,
    description: '条件を数値で比べて、成り立つときだけ処理するよ。',
  ),
  Block(
    id: 'while_loop',
    name: 'whileループ',
    icon: '🔄',
    category: BlockCategory.control,
    params: {'times': 3},
    description: '条件が続く限り同じ処理を繰り返すよ。while ループと同じ仕組みだよ。',
  ),
  Block(
    id: 'print_block',
    name: '表示する',
    icon: '📢',
    category: BlockCategory.function,
    description: 'メッセージを画面に表示するよ。Python の print() と同じだよ。',
  ),
];
