import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/screens/editor_screen.dart';
import 'test_helpers.dart';

final _stage = Stage(
  id: 'stage_playback_test',
  stageNumber: 2,
  title: '再生テスト',
  description: 'desc',
  level: '初級',
  icon: '🤖',
  isFree: true,
  type: 'visual',
  expectedOutput: 'move_forward(100)\nturn_right(90)',
  availableBlocks: const [
    BlockTemplate(
        id: 'move_forward',
        name: '前に進む',
        icon: '📍',
        category: 'motion',
        description: ''),
    BlockTemplate(
        id: 'turn_right',
        name: '右に回転',
        icon: '↪️',
        category: 'motion',
        description: ''),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: EditorScreen(challenge: _stage)),
    ));
    await tester.pumpAndSettle();
  }

  /// 画面を破棄して時間を進め、キャラクター反応などの遅延タイマーを消化する。
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  }

  Future<void> addBlocks(WidgetTester tester) async {
    await tester.tap(find.text('前に進む').first);
    await tester.pump();
    await tester.tap(find.text('右に回転').first);
    await tester.pump();
    await tester.tap(find.text('前に進む').first);
    await tester.pumpAndSettle();
  }

  testWidgets('実行すると1ブロックずつ再生され、終わると「実行」にもどる', (tester) async {
    await open(tester);
    await addBlocks(tester);

    await tester.tap(find.text('実行'));
    await tester.pump();
    expect(find.text('スキップ'), findsOneWidget);
    expect(find.text('実行'), findsNothing);

    // 3ブロック = 450ms間隔で2回進んだら終了
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('スキップ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('実行'), findsOneWidget);
    expect(find.text('スキップ'), findsNothing);
    await finish(tester);
  });

  testWidgets('再生中にスキップすると、すぐ結果の表示にもどる', (tester) async {
    await open(tester);
    await addBlocks(tester);

    await tester.tap(find.text('実行'));
    await tester.pump();
    await tester.tap(find.text('スキップ'));
    await tester.pump();

    expect(find.text('実行'), findsOneWidget);
    expect(find.text('スキップ'), findsNothing);
    // 再生のタイマーが残っていないこと（残っていれば以降のpumpで状態が変わる）
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('実行'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('再生中にブロックを編集すると、そこで再生を止める', (tester) async {
    await open(tester);
    await addBlocks(tester);

    await tester.tap(find.text('実行'));
    await tester.pump();
    await tester.tap(find.text('右に回転').first); // ブロックを追加
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('実行'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('「アニメーションを減らす」設定では、再生せず結果をすぐ表示する', (tester) async {
    useReducedMotion();
    await open(tester);
    await addBlocks(tester);

    await tester.tap(find.text('実行'));
    await tester.pump();

    expect(find.text('スキップ'), findsNothing);
    expect(find.text('実行'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('画面を閉じても再生のタイマーが残らない', (tester) async {
    await open(tester);
    await addBlocks(tester);
    await tester.tap(find.text('実行'));
    await tester.pump();

    await finish(tester); // 画面を閉じても、再生のタイマーでエラーにならない
  });
}
