/// 称号（ホームの名前の下に出す小さなプレート）。見た目だけで、学習には影響しない。
///
/// こうにゅう型はコインで買う。たっせい型は進捗が条件をこえたら自動でひらく。
class TitleProgress {
  const TitleProgress({this.level = 1, this.streakDays = 0, this.clearedStages = 0});

  final int level;
  final int streakDays;
  final int clearedStages;
}

class TitleItem {
  const TitleItem({
    required this.id,
    required this.name,
    required this.description,
    this.coinCost,
    this.condition,
    this.isUnlocked,
  }) : assert((coinCost == null) != (isUnlocked == null));

  final String id;
  final String name;
  final String description;

  /// 非null ならコインで購入する称号。
  final int? coinCost;

  /// たっせい型の、鍵に表示する条件文。
  final String? condition;

  /// たっせい型の判定（純関数）。
  final bool Function(TitleProgress)? isUnlocked;

  bool get isPurchasable => coinCost != null;
}

const String kTitlePrefix = 'title_';

final List<TitleItem> kTitleItems = [
  const TitleItem(id: 'title_tamago', name: 'プログラミングのたまご', description: 'これからそだつよ', coinCost: 100),
  const TitleItem(id: 'title_bughunter', name: 'バグハンター', description: 'まちがいを見つける名人', coinCost: 200),
  const TitleItem(id: 'title_loop', name: 'ループマスター', description: 'くりかえしの達人', coinCost: 300),
  const TitleItem(id: 'title_robot', name: 'ロボットはかせ', description: 'ロボットをあやつる', coinCost: 400),
  const TitleItem(id: 'title_wizard', name: 'コードのまほうつかい', description: 'コードでまほうをかける', coinCost: 500),
  TitleItem(
    id: 'title_explorer',
    name: 'ステージたんけんか',
    description: 'ステージをたくさんクリア',
    condition: 'ステージを10こクリア',
    isUnlocked: (p) => p.clearedStages >= 10,
  ),
  TitleItem(
    id: 'title_levelup',
    name: 'レベルアップめいじん',
    description: 'レベルがぐんぐんあがった',
    condition: 'レベル10にとうたつ',
    isUnlocked: (p) => p.level >= 10,
  ),
  TitleItem(
    id: 'title_everyday',
    name: 'まいにちコーダー',
    description: 'まいにちコツコツ',
    condition: '7日れんぞくでまなぶ',
    isUnlocked: (p) => p.streakDays >= 7,
  ),
];

TitleItem? titleItemById(String? id) {
  if (id == null) return null;
  for (final t in kTitleItems) {
    if (t.id == id) return t;
  }
  return null;
}

/// その称号を今つけられるか（購入済み or 条件達成）。
bool isTitleAvailable(TitleItem t, {required Set<String> owned, required TitleProgress progress}) {
  if (t.isPurchasable) return owned.contains(t.id);
  return t.isUnlocked!(progress);
}
