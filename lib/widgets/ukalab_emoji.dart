import 'package:flutter/material.dart';

/// 絵文字を、うかラボ共通アイコン画像に置き換えて表示する。
/// 対応表にない文字（顔文字など）や、複数文字を含む文字列は従来どおり Text で表示する。
class UkalabEmoji extends StatelessWidget {
  const UkalabEmoji(this.emoji, {super.key, this.size = 24, this.style});

  final String emoji;
  final double size;
  final TextStyle? style;

  static const _map = <String, String>{
    '⭐': 'star',
    '🌟': 'star',
    '✨': 'sparkle',
    '🌠': 'sparkle',
    '🏆': 'shield_pass',
    '🔥': 'flame',
    '📖': 'books',
    '📚': 'books',
    '👑': 'crown',
    '🎯': 'target',
    '📝': 'note',
    '✍': 'note',
    '🥇': 'medal_lv5',
    '🥈': 'medal_lv3',
    '🥉': 'medal_lv2',
    '🎖': 'medal_lv4',
    '🏅': 'medal_lv4',
    '🎉': 'party',
    '🎊': 'party',
    '✅': 'check',
    '⚠': 'warn',
    '📈': 'chart',
    '📊': 'chart',
    '📅': 'calendar',
    '🎓': 'gradcap',
    '💡': 'bulb',
    '🪙': 'coin',
    '❌': 'batsu',
    '❤': 'heart',
    '🚀': 'rocket',
    '💪': 'muscle',
    '🌱': 'sprout',
    '📌': 'pin',
    '📋': 'clipboard',
  };

  /// 画像名を返す。置き換え対象でなければ null。
  static String? assetNameFor(String emoji) {
    final key = emoji.replaceAll('️', '').trim();
    return _map[key];
  }

  @override
  Widget build(BuildContext context) {
    final name = assetNameFor(emoji);
    if (name == null) {
      return Text(emoji, style: (style ?? const TextStyle()).copyWith(fontSize: size));
    }
    return Image.asset(
      'assets/icons_common/$name.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          Text(emoji, style: (style ?? const TextStyle()).copyWith(fontSize: size)),
    );
  }
}
