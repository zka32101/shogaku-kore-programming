import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/config/constants.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/providers/challenges_provider.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/utils/shuffle_choices.dart';
import 'package:shogaku_kore_programming/screens/bug_hunter_screen.dart';
import 'package:shogaku_kore_programming/screens/quiz_screen.dart';
import 'package:shogaku_kore_programming/widgets/bug_hunt_code_view.dart';
import 'test_helpers.dart';

/// 回答後は Future.delayed（自動進行など）が残るため、スマホ縦画面にして、
/// テスト本体のあとに画面を破棄して時間を進め、残タイマーを消化する。
void testBug(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await body(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

Stage _stage() => Stage(
      id: 'bug_test',
      stageNumber: 101,
      title: 'テスト用バグハンター',
      description: 'desc',
      type: 'quiz',
      level: '初級',
      icon: '🐛',
      isFree: true,
      questions: [
        Question.bugHunt(
          id: 'q1',
          code: 'x = 10\ny = 20\nz = x + y\nprint(Z)',
          bugLine: 4,
          explanation: '大文字と小文字はべつの文字だよ',
          hint: '名前をよく見よう',
        ),
      ],
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useReducedMotion();
  });

  group('Question.bugHunt', () {
    test('各行が選択肢になり、bugLine(1始まり)が正解の添字になる', () {
      final q = Question.bugHunt(
          id: 'q', code: 'a\nb\nc', bugLine: 2, explanation: 'e');
      expect(q.bugHunt, isTrue);
      expect(q.options, ['a', 'b', 'c']);
      expect(q.correctIndex, 1);
      expect(q.codeSnippet, 'a\nb\nc');
    });

    test('JSON の往復で bugHunt が保たれ、旧データ(キーなし)は false', () {
      final q = Question.bugHunt(
          id: 'q', code: 'a\nb', bugLine: 1, explanation: 'e');
      expect(Question.fromJson(q.toJson()).bugHunt, isTrue);
      final old = q.toJson()..remove('bugHunt');
      expect(Question.fromJson(old).bugHunt, isFalse);
    });
  });

  test('shuffled() はバグハンターの問題を並べ替えない', () {
    final q = Question.bugHunt(
        id: 'q', code: 'a\nb\nc\nd\ne', bugLine: 3, explanation: 'e');
    for (var i = 0; i < 20; i++) {
      final s = q.shuffled();
      expect(s.options, ['a', 'b', 'c', 'd', 'e']);
      expect(s.correctIndex, 2);
      expect(s.bugHunt, isTrue);
    }
  });

  group('バグハンターのステージデータ', () {
    final stages = buildBugHunterStages();

    test('3ステージ・各3問で、id は接頭辞で始まり重複しない', () {
      expect(stages.length, 3);
      expect(stages.every((s) => s.id.startsWith(kBugHunterIdPrefix)), isTrue);
      expect(stages.map((s) => s.id).toSet().length, stages.length);
      expect(stages.every((s) => s.questions!.length == 3), isTrue);
    });

    test('全問がバグハンター形式で、バグ行が範囲内・説明とヒント付き', () {
      final ids = <String>{};
      for (final s in stages) {
        for (final q in s.questions!) {
          expect(q.bugHunt, isTrue, reason: q.id);
          expect(ids.add(q.id), isTrue, reason: '${q.id} が重複');
          expect(q.options.length, greaterThanOrEqualTo(2), reason: q.id);
          expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
          expect(q.explanation, isNotEmpty);
          expect(q.hint, isNotNull, reason: q.id);
        }
      }
    });

    test('問題文は全ステージの全問で重複しない（間違えた問題リストは問題文で区別する）', () {
      final texts = <String>{};
      final main = ProviderContainer().read(allChallengesProvider);
      for (final s in [...main, ...stages]) {
        for (final q in s.questions ?? const <Question>[]) {
          if (!q.bugHunt) continue;
          expect(texts.add(q.text), isTrue, reason: '${q.id} の問題文が重複: ${q.text}');
        }
      }
    });

    test('本編のステージ一覧(60件)には含めない', () {
      final main = ProviderContainer().read(allChallengesProvider);
      expect(main.length, AppConstants.totalStages);
      expect(main.any((s) => s.id.startsWith(kBugHunterIdPrefix)), isFalse);
    });
  });

  group('進捗の集計', () {
    test('バグハンターのクリアは本編の完了数・パーフェクト数・星に含めない', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(progressProvider.notifier);
      await notifier.completeChallenge('stage_01', 3);
      final starsBefore = notifier.totalStarsEarned;
      await notifier.completeChallenge('bug_01', 3);

      expect(notifier.completedCount, 1);
      expect(notifier.perfectStagesCount, 1);
      expect(notifier.totalStarsEarned, starsBefore);
      expect(notifier.bugHunterCompletedCount, 1);
    });
  });

  group('BugHuntCodeView', () {
    testWidgets('行をタップすると onSelect に行の添字が渡る', (tester) async {
      int? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BugHuntCodeView(
            lines: const ['a = 1', 'b = 2'],
            selectedIndex: null,
            answered: false,
            correctIndex: 1,
            onSelect: (i) => tapped = i,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('bugLine_1')));
      expect(tapped, 1);
    });

    testWidgets('回答後は正解の行に🐛が出て、タップしても反応しない', (tester) async {
      int? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BugHuntCodeView(
            lines: const ['a = 1', 'b = 2'],
            selectedIndex: 0,
            answered: true,
            correctIndex: 1,
            onSelect: (i) => tapped = i,
          ),
        ),
      ));
      expect(find.text('🐛'), findsOneWidget);
      expect(find.text('✖'), findsOneWidget); // 選んだ行(0)はまちがい
      await tester.tap(find.byKey(const Key('bugLine_0')));
      expect(tapped, isNull);
    });
  });

  group('QuizScreen（バグハンター）', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: QuizScreen(challenge: _stage())),
      ));
      await tester.pumpAndSettle();
    }

    testBug('コードの行が表示され、A〜Dの選択肢は出ない', (tester) async {
      await open(tester);
      expect(find.text('print(Z)'), findsOneWidget);
      expect(find.byKey(const Key('bugLine_3')), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });

    testBug('バグの行を選んで確認すると正解になり、解説が出る', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('bugLine_3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('確認する'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('大文字と小文字はべつの文字だよ'), findsOneWidget);
      expect(find.text('🐛'), findsOneWidget);
      expect(find.text('✖'), findsNothing);
    });

    testBug('ちがう行を選ぶと不正解で、正解の行が示される', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('bugLine_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('確認する'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('✖'), findsOneWidget);
      expect(find.text('🐛'), findsOneWidget);
      expect(find.text('大文字と小文字はべつの文字だよ'), findsOneWidget);
    });
  });

  group('BugHunterScreen', () {
    testBug('3つのステージが並び、タップでクイズ画面が開く', (tester) async {
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: BugHunterScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('バグハンター①'), findsOneWidget);
      expect(find.textContaining('バグハンター②'), findsOneWidget);
      expect(find.textContaining('バグハンター③'), findsOneWidget);

      await tester.tap(find.byKey(const Key('bugStage_bug_01')));
      await tester.pumpAndSettle();
      expect(find.byType(QuizScreen), findsOneWidget);
      expect(find.byKey(const Key('bugLine_0')), findsOneWidget);
    });
  });
}
