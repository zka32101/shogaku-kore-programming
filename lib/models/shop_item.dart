/// ショップアイテムカテゴリー
enum ShopCategory {
  character,   // キャラクタースキン
  background,  // 背景テーマ
  frame,       // アイコンのフレーム
  effect,      // 画面エフェクト
  sound,       // 効果音セット
  hint,        // ヒント（消耗品）
}

extension ShopCategoryLabel on ShopCategory {
  String get label {
    switch (this) {
      case ShopCategory.character:  return '🥷 キャラ';
      case ShopCategory.background: return '🖼️ 背景';
      case ShopCategory.frame:      return '🪞 フレーム';
      case ShopCategory.effect:     return '✨ エフェクト';
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
  final String? imageAsset; // 一覧に出す画像（きせかえのサムネイル）。null なら絵文字

  const ShopItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isConsumable = false,
    this.imageAsset,
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

  // 背景・フレーム・エフェクトは features/shop/decor/decor_items.dart（きせかえ）から追加される

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
