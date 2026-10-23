import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/screens/editor_screen.dart';
import 'test_helpers.dart';

final _squareStage = Stage(
  id: 'stage_hint_test',
  stageNumber: 3,
  title: '四角を描こう',
  description: '四角を描こう',
  level: '初級',
  icon: '⬜',
  isFree: true,
  type: 'visual',
  expectedOutput: 'repeat(4):\n  move_forward(100)\n  turn_right(90)',
  hints: ['辺は4本だよ', '回転は90度だよ'],
  availableBlocks: const [
    BlockTemplate(
        id: 'move_forward',
        name: '前に進む',
        icon: '📍',
        category: 'motion',
        description: '前に進む'),
    BlockTemplate(
        id: 'turn_right',
        name: '右に回転',
        icon: '↪️',
        category: 'motion',
        description: '右に回転'),
  ],
  goalCondition: {'shape': 'square'},
);

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useReducedMotion();
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: EditorScreen(challenge: _squareStage)),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> submitWrong(WidgetTester tester) async {
    await tester.tap(find.text('前に進む').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('回答する'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> retry(WidgetTester tester) async {
    await tester.tap(find.text('もう一度'));
    await tester.pumpAndSettle();
  }

  Future<void> submitSquare(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('前に進む').first);
      await tester.pump();
      await tester.tap(find.text('右に回転').first);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('回答する'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('1回目の不正解は具体的なヒントだけで、お手本はまだ出ない', (tester) async {
    await open(tester);
    await submitWrong(tester);

    expect(find.byKey(const Key('editorHintCard')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('editorHintCard')),
            matching: find.textContaining('辺が4本')),
        findsOneWidget);
    expect(find.byKey(const Key('viewModelButton')), findsNothing);
    await finish(tester);
  });

  testWidgets('2回目の不正解でヒント欄が開き、3回目でお手本が出る', (tester) async {
    await open(tester);
    expect(find.text('辺は4本だよ'), findsNothing);

    await submitWrong(tester);
    await retry(tester);
    expect(find.text('辺は4本だよ'), findsNothing); // 1回目ではまだ開かない

    await submitWrong(tester);
    expect(find.byKey(const Key('viewModelButton')), findsNothing);
    await retry(tester);
    expect(find.text('辺は4本だよ'), findsOneWidget); // 2回目で自動で開く

    await submitWrong(tester);
    expect(find.byKey(const Key('viewModelButton')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('お手本を見てクリアすると星が2つになる', (tester) async {
    await open(tester);
    for (var i = 0; i < 2; i++) {
      await submitWrong(tester);
      await retry(tester);
    }
    await submitWrong(tester);
    await tester.tap(find.byKey(const Key('viewModelButton')));
    await tester.pumpAndSettle();
    expect(find.text('繰り返す 4回'), findsOneWidget);
    expect(find.text('  前に進む 100歩'), findsOneWidget);
    await tester.tap(find.text('とじる'));
    await tester.pumpAndSettle();
    await retry(tester);

    await submitSquare(tester);

    expect(container.read(progressProvider)['stage_hint_test']!.starsEarned, 2);
    expect(container.read(progressProvider.notifier).noHintClearCount, 0);
    await finish(tester);
  });

  testWidgets('一発でヒントなしクリアすると星3つで、ノーヒントとして数える', (tester) async {
    await open(tester);
    await submitSquare(tester);

    expect(container.read(progressProvider)['stage_hint_test']!.starsEarned, 3);
    expect(container.read(progressProvider.notifier).noHintClearCount, 1);
    await finish(tester);
  });

  testWidgets('ヒント欄を開いてからクリアすると、星は3つでもノーヒントにならない', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('ヒント'));
    await tester.pumpAndSettle();
    await submitSquare(tester);

    expect(container.read(progressProvider)['stage_hint_test']!.starsEarned, 3);
    expect(container.read(progressProvider.notifier).noHintClearCount, 0);
    await finish(tester);
  });
}
