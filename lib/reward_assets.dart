/// ごほうびシール・連続学習の炎の画像選択（純関数）。
String? streakFlameAsset(int days) {
  if (days <= 0) return null;
  const base = 'assets/reward/';
  if (days >= 100) return '${base}flame_lv8_rainbow_smile.webp';
  if (days >= 60) return '${base}flame_lv7_rainbow.webp';
  if (days >= 30) return '${base}flame_lv6_violet.webp';
  if (days >= 21) return '${base}flame_lv5_blue.webp';
  if (days >= 14) return '${base}flame_lv4_gold.webp';
  if (days >= 7) return '${base}flame_lv3_bold.webp';
  if (days >= 3) return '${base}flame_lv2.webp';
  return '${base}flame_lv1_small.webp';
}

/// 合格時のシール。満点=rosette / 80%以上=star / それ以外=flower。
String rewardStickerAsset(int correct, int total) {
  const base = 'assets/reward/';
  if (total > 0 && correct >= total) return '${base}sticker_rosette.webp';
  if (total > 0 && correct / total >= 0.8) return '${base}sticker_star.webp';
  return '${base}sticker_flower.webp';
}

/// おまけシール(結果画面のメインシールの隣、最大2個)。
/// 優先順: 初挑戦=rocket, 自己ベスト=trophy_blue, 初回満点=rainbow_star。
List<String> bonusStickerAssets({
  required bool firstAttempt,
  required bool personalBest,
  required bool firstPerfect,
}) {
  const base = 'assets/reward/';
  return [
    if (firstAttempt) '${base}sticker_rocket.webp',
    if (personalBest) '${base}sticker_trophy_blue.webp',
    if (firstPerfect) '${base}sticker_rainbow_star.webp',
  ].take(2).toList();
}
