import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/features/shop/title/title_items.dart';
import 'package:shogaku_kore_programming/features/shop/title/title_plate.dart';
import 'package:shogaku_kore_programming/features/shop/title/title_provider.dart';
import 'package:shogaku_kore_programming/providers/coin_provider.dart';

void main() {
  test('称号定義: 8個・ID重複なし・購入5/達成3・価格100〜500', () {
    expect(kTitleItems.length, 8);
    expect(kTitleItems.map((t) => t.id).toSet().length, 8);
    expect(kTitleItems.where((t) => t.isPurchasable).length, 5);
    for (final t in kTitleItems.where((t) => t.isPurchasable)) {
      expect(t.coinCost, inInclusiveRange(100, 500));
    }
    for (final t in kTitleItems.where((t) => !t.isPurchasable)) {
      expect(t.condition, isNotEmpty);
    }
    expect(File('assets/title_plate/plate_programming.webp').existsSync(), true);
  });

  test('達成型の判定は境界で切り替わる', () {
    final explorer = titleItemById('title_explorer')!;
    expect(explorer.isUnlocked!(const TitleProgress(clearedStages: 9)), false);
    expect(explorer.isUnlocked!(const TitleProgress(clearedStages: 10)), true);
    final lv = titleItemById('title_levelup')!;
    expect(lv.isUnlocked!(const TitleProgress(level: 9)), false);
    expect(lv.isUnlocked!(const TitleProgress(level: 10)), true);
    final st = titleItemById('title_everyday')!;
    expect(st.isUnlocked!(const TitleProgress(streakDays: 6)), false);
    expect(st.isUnlocked!(const TitleProgress(streakDays: 7)), true);
  });

  test('isTitleAvailable: 購入型は所持、達成型は条件', () {
    final buy = titleItemById('title_tamago')!;
    const p = TitleProgress();
    expect(isTitleAvailable(buy, owned: {}, progress: p), false);
    expect(isTitleAvailable(buy, owned: {'title_tamago'}, progress: p), true);
    expect(isTitleAvailable(titleItemById('title_levelup')!, owned: {}, progress: p), false);
  });

  test('購入して装着でき、未所持は装着できない', () async {
    SharedPreferences.setMockInitialValues({'coin_balance': 150, 'coin_total_earned': 150});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(coinProvider);
    c.read(titleProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final t = titleItemById('title_tamago')!;
    final n = c.read(titleProvider.notifier);
    expect(await n.equip(t), false);
    expect(await n.buy(titleItemById('title_bughunter')!), false); // 200 > 150
    expect(await n.buy(t), true);
    expect(await n.equip(t), true);
    expect(c.read(activeTitleProvider)?.id, 'title_tamago');
    await n.unequip();
    expect(c.read(activeTitleProvider), isNull);
  });

  testWidgets('TitlePlate は幅110で長い名前でもoverflowしない', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: TitlePlate(name: 'コードのまほうつかいコードのまほうつかい'))),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('コードのまほうつかいコードのまほうつかい'), findsOneWidget);
    expect(tester.getSize(find.byType(TitlePlate)).width, 110);
  });
}
