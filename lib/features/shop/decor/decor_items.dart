import '../../../models/shop_item.dart';

/// きせかえの種類。
enum DecorKind {
  background('背景'),
  frame('フレーム'),
  effect('エフェクト');

  const DecorKind(this.label);
  final String label;
}

/// コインで買えるきせかえ（背景・フレーム・エフェクト）。見た目だけで、学習には影響しない。
///
/// 画像は `assets/shop/<id>.webp`、一覧用のサムネイルは `assets/shop/thumb/<id>.webp`。
class DecorItem {
  const DecorItem({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.coinCost,
    this.season,
  });

  final String id;
  final String name;
  final String description;
  final DecorKind kind;
  final int coinCost;

  /// null なら常設。spring / summer / autumn / winter は季節もの。
  final String? season;

  String get asset => 'assets/shop/$id.webp';
  String get thumb => 'assets/shop/thumb/$id.webp';

  String get emoji {
    switch (kind) {
      case DecorKind.background:
        return '🖼️';
      case DecorKind.frame:
        return '🪞';
      case DecorKind.effect:
        return '✨';
    }
  }

  ShopCategory get category {
    switch (kind) {
      case DecorKind.background:
        return ShopCategory.background;
      case DecorKind.frame:
        return ShopCategory.frame;
      case DecorKind.effect:
        return ShopCategory.effect;
    }
  }

  /// ショップ画面に並べるための形。
  ShopItem toShopItem() => ShopItem(
        id: id,
        emoji: emoji,
        name: name,
        description: description,
        price: coinCost,
        category: category,
        imageAsset: thumb,
      );
}

const List<DecorItem> kDecorItems = [
  // ── 背景（常設） ──
  DecorItem(id: 'bg_programming', name: 'プログラミングのせかい', description: 'むらさきのデジタルな背景', kind: DecorKind.background, coinCost: 200),
  DecorItem(id: 'bg_space', name: '宇宙の背景', description: '星と銀河のきれいな背景', kind: DecorKind.background, coinCost: 200),
  DecorItem(id: 'bg_ocean', name: '深海の背景', description: '海の中のような青い背景', kind: DecorKind.background, coinCost: 200),
  DecorItem(id: 'bg_forest', name: '森の背景', description: '光がさす緑の森の背景', kind: DecorKind.background, coinCost: 200),
  DecorItem(id: 'bg_sky', name: '空の背景', description: '虹と気球の青い空の背景', kind: DecorKind.background, coinCost: 200),
  // ── 背景（季節） ──
  DecorItem(id: 'bg_sakura', name: '桜の背景', description: '桜の花びらがまう春の背景', kind: DecorKind.background, coinCost: 300, season: 'spring'),
  DecorItem(id: 'bg_fireworks', name: '花火の背景', description: '夏まつりの花火の背景', kind: DecorKind.background, coinCost: 300, season: 'summer'),
  DecorItem(id: 'bg_leaves', name: '紅葉の背景', description: '赤や黄色の葉っぱの秋の背景', kind: DecorKind.background, coinCost: 300, season: 'autumn'),
  DecorItem(id: 'bg_snow', name: '雪の背景', description: '雪がふる冬の村の背景', kind: DecorKind.background, coinCost: 300, season: 'winter'),
  // ── フレーム（常設） ──
  DecorItem(id: 'frame_rainbow', name: '虹色フレーム', description: 'アイコンに虹色のふち', kind: DecorKind.frame, coinCost: 250),
  DecorItem(id: 'frame_ribbon', name: 'リボンフレーム', description: 'かわいいリボンのふち', kind: DecorKind.frame, coinCost: 250),
  DecorItem(id: 'frame_star', name: 'スターフレーム', description: 'キラキラ星のふち', kind: DecorKind.frame, coinCost: 250),
  DecorItem(id: 'frame_party', name: 'お祝いフレーム', description: '風船とはたのふち', kind: DecorKind.frame, coinCost: 250),
  // ── フレーム（季節） ──
  DecorItem(id: 'frame_entrance', name: '入学式フレーム', description: '桜とランドセルのふち', kind: DecorKind.frame, coinCost: 200, season: 'spring'),
  DecorItem(id: 'frame_book', name: '読書フレーム', description: '本と紅葉のふち', kind: DecorKind.frame, coinCost: 200, season: 'autumn'),
  DecorItem(id: 'frame_newyear', name: 'お正月フレーム', description: '松と梅のお正月のふち', kind: DecorKind.frame, coinCost: 200, season: 'winter'),
  // ── エフェクト（季節） ──
  DecorItem(id: 'effect_waves', name: '波エフェクト', description: '画面の下にさざ波が広がる', kind: DecorKind.effect, coinCost: 250, season: 'summer'),
  DecorItem(id: 'effect_snow', name: '雪エフェクト', description: '画面に雪の結晶がふる', kind: DecorKind.effect, coinCost: 200, season: 'winter'),
];

DecorItem? decorItemById(String? id) {
  if (id == null) return null;
  for (final i in kDecorItems) {
    if (i.id == id) return i;
  }
  return null;
}

/// ショップに並べるきせかえ（ShopItem 形式）。
List<ShopItem> decorShopItems() => [for (final i in kDecorItems) i.toShopItem()];
