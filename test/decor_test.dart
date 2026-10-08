import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/features/shop/decor/decor_items.dart';
import 'package:shogaku_kore_programming/features/shop/decor/decor_provider.dart';
import 'package:shogaku_kore_programming/features/shop/decor/decor_screen.dart';
import 'package:shogaku_kore_programming/features/shop/decor/decor_scope.dart';
import 'package:shogaku_kore_programming/models/shop_item.dart';
import 'package:shogaku_kore_programming/providers/coin_provider.dart';

/// 所持品を持たせたコンテナ。coinProvider は SharedPreferences('coin_purchased_ids') を読む。
Future<ProviderContainer> _container({Map<String, Object> prefs = const {}, Set<String> owned = const {}}) async {
  SharedPreferences.setMockInitialValues({
    ...prefs,
    if (owned.isNotEmpty) 'coin_purchased_ids': '[${owned.map((e) => '"$e"').join(',')}]',
  });
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(coinProvider);
  c.read(decorProvider);
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return c;
}

void main() {
  test('商品の画像・サムネイルがすべて存在し、IDは重複しない', () {
    final ids = <String>{};
    for (final i in kDecorItems) {
      expect(ids.add(i.id), true, reason: '重複: ${i.id}');
      expect(File(i.asset).existsSync(), true, reason: i.asset);
      expect(File(i.thumb).existsSync(), true, reason: i.thumb);
    }
    expect(kDecorItems.length, 23);
    // 季節の網羅: 春夏秋冬のどれにも商品があり、通年(常設)もある
    for (final s in ['spring', 'summer', 'autumn', 'winter']) {
      expect(kDecorItems.where((i) => i.season == s).isNotEmpty, true, reason: s);
    }
    expect(kDecorItems.any((i) => i.season == null && i.kind == DecorKind.effect), true);
  });

  test('ショップの通常商品ときせかえのIDが重ならない', () {
    final shopIds = {for (final i in kShopItems) i.id};
    for (final d in kDecorItems) {
      expect(shopIds.contains(d.id), false, reason: d.id);
    }
    expect(decorShopItems().every((s) => s.imageAsset != null && s.price >= 200), true);
  });

  test('持っていないきせかえはつけられない', () async {
    final c = await _container();
    final ok = await c.read(decorProvider.notifier).equip(decorItemById('bg_space')!);
    expect(ok, false);
    expect(c.read(decorProvider).background, isNull);
  });

  test('持っているきせかえをつけて、保存され、はずせる', () async {
    final c = await _container(owned: {'bg_space', 'frame_star'});
    final n = c.read(decorProvider.notifier);
    expect(await n.equip(decorItemById('bg_space')!), true);
    expect(await n.equip(decorItemById('frame_star')!), true);
    expect(c.read(activeDecorProvider).background, 'bg_space');
    expect(c.read(activeDecorProvider).frame, 'frame_star');
    final p = await SharedPreferences.getInstance();
    expect(p.getString('decor_background'), 'bg_space');

    await n.unequip(DecorKind.background);
    expect(c.read(activeDecorProvider).background, isNull);
    expect(p.getString('decor_background'), isNull);
    expect(c.read(activeDecorProvider).frame, 'frame_star');
  });

  test('保存されていても、持っていない・種類が違うIDは無視される', () async {
    final c = await _container(prefs: {'decor_background': 'bg_snow', 'decor_frame': 'bg_space', 'decor_effect': 'unknown'});
    final a = c.read(activeDecorProvider);
    expect(a.background, isNull); // 持っていない
    expect(a.frame, isNull); // 種類が違う
    expect(a.effect, isNull); // 知らないID
  });

  testWidgets('背景をつけると、画面の背景色が透明になり、つけていなければ元の色のまま', (tester) async {
    Color? seen;
    Widget probe(bool bg) => MaterialApp(
          home: DecorScope(
            hasBackground: bg,
            child: Builder(builder: (context) {
              seen = DecorScope.pageBg(context, const Color(0xFFF7F9FC));
              return const SizedBox();
            }),
          ),
        );
    await tester.pumpWidget(probe(false));
    expect(seen, const Color(0xFFF7F9FC));
    await tester.pumpWidget(probe(true));
    expect(seen, Colors.transparent);
  });

  testWidgets('きせかえ画面: 何も持っていなければ案内を出し、持っていればえらんでつけられる', (tester) async {
    final c = (await tester.runAsync(() => _container(owned: {'bg_space', 'bg_ocean'})))!;
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: DecorScreen())));
    await tester.pump();
    expect(find.text('背景'), findsOneWidget);
    expect(find.text('宇宙の背景'), findsOneWidget);
    await tester.tap(find.text('宇宙の背景'));
    await tester.pump();
    expect(c.read(activeDecorProvider).background, 'bg_space');
    expect(find.text('✓ 宇宙の背景'), findsOneWidget);
    await tester.tap(find.text('なし').first);
    await tester.pump();
    expect(c.read(activeDecorProvider).background, isNull);

    final empty = (await tester.runAsync(() => _container()))!;
    await tester.pumpWidget(UncontrolledProviderScope(container: empty, child: const MaterialApp(home: DecorScreen())));
    await tester.pump();
    expect(find.textContaining('まだきせかえをもっていないよ'), findsOneWidget);
  });

  testWidgets('DecorBackdrop: 背景つきなら絵と膜を敷き、なければ子だけ', (tester) async {
    final c = (await tester.runAsync(() => _container(owned: {'bg_space'})))!;
    Widget app() => UncontrolledProviderScope(
          container: c,
          child: MaterialApp(builder: (context, child) => DecorBackdrop(child: child!), home: const Scaffold(body: Text('こんにちは'))),
        );
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    await c.read(decorProvider.notifier).equip(decorItemById('bg_space')!);
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('こんにちは'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('波エフェクトは画面高の12%以下・半透明で、タップを通す', (tester) async {
    final c = (await tester.runAsync(() => _container(owned: {'effect_waves'})))!;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(builder: (context, child) => DecorBackdrop(child: child!), home: const Scaffold(body: Text('こんにちは'))),
    ));
    await c.read(decorProvider.notifier).equip(decorItemById('effect_waves')!);
    await tester.pump();
    final op = tester.widget<Opacity>(find.byKey(const ValueKey('decor_waves')));
    expect(op.opacity, lessThanOrEqualTo(0.6));
    final screenH = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getSize(find.byKey(const ValueKey('decor_waves'))).height, lessThanOrEqualTo(screenH * 0.12 + 0.01));
    expect(find.ancestor(of: find.byKey(const ValueKey('decor_waves')), matching: find.byType(IgnorePointer)), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('背景つきのときだけ、上端に暗い帯(ステータスバー用)と見出しの白地が出る', (tester) async {
    final c = (await tester.runAsync(() => _container(owned: {'bg_space'})))!;
    late BuildContext inner;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        builder: (context, child) => DecorBackdrop(child: child!),
        home: Scaffold(body: Builder(builder: (ctx) {
          inner = ctx;
          return const Text('x');
        })),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('decor_status_scrim')), findsNothing);
    expect(DecorScope.chipBg(inner), Colors.transparent);
    await c.read(decorProvider.notifier).equip(decorItemById('bg_space')!);
    await tester.pump();
    expect(find.byKey(const ValueKey('decor_status_scrim')), findsOneWidget);
    expect(DecorScope.chipBg(inner).a > 0.5, true);
  });

  testWidgets('DecorFrame: 28px のアバターにはフレームが出る', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DecorScope(hasBackground: false, frameAsset: 'assets/shop/frame_star.webp', child: DecorFrame(size: 28, child: SizedBox())),
    ));
    expect(find.byType(Image), findsOneWidget);
  });
}
