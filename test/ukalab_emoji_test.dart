import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/widgets/ukalab_emoji.dart';

void main() {
  test('対応する絵文字は画像名に変換され、異体字セレクタは無視される', () {
    expect(UkalabEmoji.assetNameFor('⭐'), 'star');
    expect(UkalabEmoji.assetNameFor('🎖️'), 'medal_lv4');
    expect(UkalabEmoji.assetNameFor('⚠️'), 'warn');
    expect(UkalabEmoji.assetNameFor('🙂'), isNull);
    expect(UkalabEmoji.assetNameFor('⚡⚡'), isNull);
  });

  test('対応表の画像ファイルがすべて存在する', () {
    for (final e in ['⭐', '✨', '🏆', '🔥', '📚', '👑', '🎯', '📝', '🥇', '🥈', '🥉', '🎖', '🎉', '✅', '⚠', '📈', '📅', '🎓']) {
      final n = UkalabEmoji.assetNameFor(e)!;
      expect(File('assets/icons_common/$n.webp').existsSync(), true, reason: n);
    }
  });
}
