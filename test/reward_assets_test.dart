import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/reward_assets.dart';

void main() {
  test('streakFlameAsset boundaries', () {
    expect(streakFlameAsset(0), isNull);
    expect(streakFlameAsset(1), contains('flame_lv1_small'));
    expect(streakFlameAsset(2), contains('flame_lv1_small'));
    expect(streakFlameAsset(3), contains('flame_lv2'));
    expect(streakFlameAsset(7), contains('flame_lv3_bold'));
    expect(streakFlameAsset(14), contains('flame_lv4_gold'));
    expect(streakFlameAsset(21), contains('flame_lv5_blue'));
    expect(streakFlameAsset(30), contains('flame_lv6_violet'));
    expect(streakFlameAsset(60), contains('flame_lv7_rainbow'));
    expect(streakFlameAsset(100), contains('flame_lv8_rainbow_smile'));
  });

  test('rewardStickerAsset by score', () {
    expect(rewardStickerAsset(10, 10), contains('rosette'));
    expect(rewardStickerAsset(8, 10), contains('sticker_star'));
    expect(rewardStickerAsset(6, 10), contains('flower'));
  });

  testWidgets('sticker and flame assets load without overflow', (tester) async {
    for (final a in [
      streakFlameAsset(1), streakFlameAsset(100),
      rewardStickerAsset(10, 10), rewardStickerAsset(8, 10), rewardStickerAsset(6, 10),
    ]) {
      await rootBundle.load(a!);
    }
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          Image.asset(rewardStickerAsset(10, 10), width: 72),
          Image.asset(streakFlameAsset(7)!, height: 28),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
