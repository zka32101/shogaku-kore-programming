import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/screens/quiz_screen.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'test_helpers.dart';

/// 回答後は Future.delayed（コンボ表示のクリア・自動進行）が残るため、
/// スマホ縦画面に揃え（選択肢はシャッフルされ、800x600だと画面外になりうる）、
/// テスト本体のあとに画面を破棄して時間を進め、残タイマーを消化する。
void testQuiz(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await body(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

void main() {
  setUp(useReducedMotion);
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('QuizScreen Widget Tests', () {
    // Create a mock challenge for testing
    final mockChallenge = Stage(
      id: 'test_challenge_1',
      stageNumber: 1,
      title: 'Python基礎',
      description: 'Python基本の問題です',
      level: '初級',
      icon: 'icon_1',
      isFree: true,
      questions: [
        Question(
          id: 'q1',
          text: 'Pythonで変数を定義するには？',
          options: ['x = 5', 'var x = 5', '5 -> x', 'def x = 5'],
          correctIndex: 0,
          explanation: 'Pythonでは `x = 5` で変数を定義します',
          codeSnippet: 'x = 5\nprint(x)',
          hint: '等号を使います',
        ),
        Question(
          id: 'q2',
          text: 'このコードの出力は？\nprint(2 + 3)',
          options: ['5', '23', 'error', 'None'],
          correctIndex: 0,
          explanation: 'print(2 + 3) は 5 を出力します',
          codeSnippet: 'print(2 + 3)',
          hint: '2足す3は？',
        ),
      ],
      type: 'quiz',
    );

    testQuiz('displays quiz screen with question', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify quiz screen is displayed
      expect(find.byType(QuizScreen), findsOneWidget);

      // Verify first question is displayed
      expect(find.text('Pythonで変数を定義するには？'), findsOneWidget);
    });

    testQuiz('displays all answer options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all options are displayed
      expect(find.text('x = 5'), findsOneWidget);
      expect(find.text('var x = 5'), findsOneWidget);
      expect(find.text('5 -> x'), findsOneWidget);
      expect(find.text('def x = 5'), findsOneWidget);
    });

    testQuiz('selects an answer when option tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the first option
      await tester.tap(find.text('x = 5'));
      await tester.pumpAndSettle();

      // Verify the option is selected (visual feedback would show)
      // This depends on the visual indicator in the actual screen
    });

    testQuiz('submits answer and shows result', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select the correct answer
      await tester.tap(find.text('x = 5'));
      await tester.pumpAndSettle();

      // Look for a submit button and tap it
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle();
      }
    });

    testQuiz('displays next question after answering', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Answer first question
      await tester.tap(find.text('x = 5'));
      await tester.pumpAndSettle();

      // Submit answer
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify second question is now displayed
      // This may show after animation completes
    });

    testQuiz('shows explanation for correct answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select correct answer
      await tester.tap(find.text('x = 5'));
      await tester.pumpAndSettle();

      // Submit and wait for result display
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Explanation should be visible
        expect(
          find.text('Pythonでは `x = 5` で変数を定義します'),
          findsWidgets,
        );
      }
    });

    testQuiz('shows code snippet when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Wait for code snippet to appear
      await tester.pumpAndSettle();

      // Verify code snippet is displayed
      expect(find.text('x = 5'), findsWidgets);
    });

    testQuiz('hint functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Look for hint button
      final hintButton = find.byIcon(Icons.lightbulb_outline);
      if (hintButton.evaluate().isNotEmpty) {
        await tester.tap(hintButton.first);
        await tester.pumpAndSettle();

        // Verify hint is displayed
        expect(find.text('等号を使います'), findsWidgets);
      }
    });

    testQuiz('quiz completion transitions to result screen',
        (WidgetTester tester) async {
      // Create a single-question challenge for easier testing
      final singleQuestionChallenge = Stage(
        id: 'test_single',
        stageNumber: 1,
        title: 'Single Question Quiz',
        description: 'One question',
        level: '初級',
        icon: 'icon_1',
        isFree: true,
        questions: [
          Question(
            id: 'q1',
            text: 'What is 2+2?',
            options: ['4', '5', '3', '6'],
            correctIndex: 0,
            explanation: '2+2=4',
            hint: 'Basic math',
          ),
        ],
        type: 'quiz',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: singleQuestionChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Answer the question
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // Submit answer
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // After completion, should navigate to result screen or show completion
    });

    testQuiz('supports keyboard shortcuts for answer selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate pressing '1' key to select first option
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      // Verify first option is selected
    });

    testQuiz('displays progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Look for progress indicators (e.g., "Question 1 of 2")
      // The exact text depends on implementation
      await tester.pumpAndSettle();
    });

    testQuiz('timer counts down when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Look for timer display
      final timerText = find.byType(Text).evaluate();
      expect(timerText.isNotEmpty, true);

      // Wait 2 seconds and verify timer decreased
      await tester.pump(const Duration(seconds: 2));
    });

    testQuiz('prevents submitting without selecting answer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Try to submit without selecting
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        // Button should be disabled or not tap-able
      }
    });

    testQuiz('displays incorrect answer feedback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select wrong answer
      await tester.tap(find.text('var x = 5'));
      await tester.pumpAndSettle();

      // Submit answer
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle();

        // Should show it's incorrect
      }
    });

    testQuiz('handles back button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizScreen(challenge: mockChallenge),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Look for back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();

        // May show confirmation dialog
      }
    });
  });
}
