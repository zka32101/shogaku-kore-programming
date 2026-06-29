/// ショップアイテムカテゴリー
enum ShopCategory {
  character,   // キャラクタースキン
  background,  // 背景テーマ
  sound,       // 効果音セット
  hint,        // ヒント（消耗品）
}

extension ShopCategoryLabel on ShopCategory {
  String get label {
    switch (this) {
      case ShopCategory.character:  return '🥷 キャラ';
      case ShopCategory.background: return '🖼️ 背景';
      case ShopCategory.sound:      return '🎵 サウンド';
      case ShopCategory.hint:       return '💡 ヒント';
    }
  }
}

class ShopItem {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final int price;
  final ShopCategory category;
  final bool isConsumable; // 消耗品（ヒントなど）

  const ShopItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isConsumable = false,
  });
}

/// 全ショップアイテム一覧
const List<ShopItem> kShopItems = [
  // ─── キャラクタースキン ───
  ShopItem(
    id: 'char_ninja',
    emoji: '🥷',
    name: 'ニンジャロボ',
    description: 'すばやく動くニンジャスタイルのロボット！',
    price: 200,
    category: ShopCategory.character,
  ),
  ShopItem(
    id: 'char_gold',
    emoji: '🤖',
    name: 'ゴールドロボ',
    description: 'ピカピカのゴールドでかっこいい！',
    price: 300,
    category: ShopCategory.character,
  ),
  ShopItem(
    id: 'char_alien',
    emoji: '👾',
    name: 'エイリアンロボ',
    description: '宇宙からやってきた謎のロボット！',
    price: 400,
    category: ShopCategory.character,
  ),
  ShopItem(
    id: 'char_dragon',
    emoji: '🐉',
    name: 'ドラゴンロボ',
    description: 'ドラゴンの力を持つ最強ロボット！',
    price: 500,
    category: ShopCategory.character,
  ),

  // ─── 背景テーマ ───
  ShopItem(
    id: 'bg_space',
    emoji: '🌌',
    name: '宇宙テーマ',
    description: '星がきらめく宇宙の世界！',
    price: 150,
    category: ShopCategory.background,
  ),
  ShopItem(
    id: 'bg_ocean',
    emoji: '🌊',
    name: '海テーマ',
    description: '深い海の底のような世界！',
    price: 200,
    category: ShopCategory.background,
  ),
  ShopItem(
    id: 'bg_forest',
    emoji: '🌲',
    name: '森テーマ',
    description: '緑あふれる森の世界！',
    price: 250,
    category: ShopCategory.background,
  ),

  // ─── 効果音セット ───
  ShopItem(
    id: 'sound_retro',
    emoji: '🎮',
    name: 'レトロゲームサウンド',
    description: '昔のゲームみたいな8ビットサウンド！',
    price: 100,
    category: ShopCategory.sound,
  ),
  ShopItem(
    id: 'sound_nature',
    emoji: '🎵',
    name: 'ネイチャーサウンド',
    description: '自然をモチーフにした心地よいサウンド！',
    price: 150,
    category: ShopCategory.sound,
  ),

  // ─── ヒント（消耗品）───
  ShopItem(
    id: 'hint_x1',
    emoji: '💡',
    name: 'ヒント × 1',
    description: 'むずかしい問題に使えるヒントが1回分！',
    price: 50,
    category: ShopCategory.hint,
    isConsumable: true,
  ),
  ShopItem(
    id: 'hint_x3',
    emoji: '💡💡💡',
    name: 'ヒント × 3（おトク）',
    description: 'ヒントが3回分！1回あたり40コイン！',
    price: 120,
    category: ShopCategory.hint,
    isConsumable: true,
  ),
];
