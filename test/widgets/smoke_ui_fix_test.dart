import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/config/challenge_colors.dart';
import 'package:shogaku_kore_programming/models/block_model.dart';
import 'package:shogaku_kore_programming/models/user_work.dart';
import 'package:shogaku_kore_programming/screens/flashcard_screen.dart';
import 'package:shogaku_kore_programming/screens/shop_screen.dart';
import 'package:shogaku_kore_programming/widgets/work_thumbnail.dart';

double _lum(Color c) {
  double f(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('単語帳ヘッダーのタイトルが360dp幅で1行', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: FlashcardScreen())));
    await tester.pump(const Duration(milliseconds: 500));
    final f = find.byKey(const Key('flashcard_header_title'));
    expect(f, findsOneWidget);
    // 1行分の高さ(18pt*約1.5以下)
    expect(tester.getSize(f).height, lessThan(32));
    expect(tester.getSize(f).width, greaterThan(100));
  });

  testWidgets('ショップのタイトルが360dp幅で省略されない', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: ShopScreen())));
    await tester.pump(const Duration(milliseconds: 500));
    final f = find.byKey(const Key('shop_title'));
    expect(f, findsOneWidget);
    final rp = tester.renderObject<RenderParagraph>(find.descendant(
        of: f, matching: find.byType(RichText)));
    expect(rp.didExceedMaxLines, isFalse);
  });

  group('作品サムネイル', () {
    UserWork work(String img) => UserWork(
          id: '1',
          challengeId: 'c1',
          challengeTitle: '迷路を解こう①',
          blockCode: jsonEncode([
            Block(
                    id: 'm',
                    name: '前へ',
                    icon: 'x',
                    category: BlockCategory.motion)
                .toJson()
          ]),
          resultImage: img,
          createdAt: DateTime(2026),
          difficulty: 'e',
        );

    testWidgets('1x1プレースホルダーでも簡易プレビューを出す', (tester) async {
      const ph =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      await tester.pumpWidget(MaterialApp(
          home: SizedBox(
              width: 150, height: 150, child: WorkThumbnail(work: work(ph)))));
      expect(find.byKey(const Key('work_thumbnail_preview')), findsOneWidget);
      expect(find.text('迷'), findsOneWidget);
      expect(find.text('ブロック1こ'), findsOneWidget);
    });

    testWidgets('画像なしでも落ちない', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: SizedBox(
              width: 150, height: 150, child: WorkThumbnail(work: work('')))));
      expect(find.byKey(const Key('work_thumbnail_preview')), findsOneWidget);
    });
  });

  group('今週のチャレンジ配色 WCAG AA', () {
    for (final dark in [false, true]) {
      for (final done in [false, true]) {
        test('dark=$dark done=$done', () {
          final c = ChallengeItemColors.of(dark: dark, done: done);
          expect(contrast(c.title, c.background), greaterThanOrEqualTo(4.5));
          expect(contrast(c.desc, c.background), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });
}
