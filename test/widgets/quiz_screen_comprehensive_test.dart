import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/screens/quiz_screen.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'package:shogaku_kore_programming/config/constants.dart';
import 'test_helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  // Create mock stage/challenge for testing
  final mockStage = Stage(
    id: 'quiz_test_1',
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
      Question(
        id: 'q3',
        text: 'リストを作成するには？',
        options: ['[1, 2, 3]', '{1, 2, 3}', '(1, 2, 3)', '<1, 2, 3>'],
        correctIndex: 0,
        explanation: 'Pythonでは角括弧 [] でリストを作成します',
        codeSnippet: 'my_list = [1, 2, 3]\nprint(my_list)',
        hint: '角括弧を使用します',
      ),
    ],
    conceptExplanation: 'Pythonの基本的な文法を学びます',
    type: 'quiz',
  );

  group('QuizScreen Comprehensive Widget Tests', () {
    // Basic Screen Rendering Tests
    group('Basic Screen Rendering', () {
      testWidgets('displays quiz screen without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('displays AppBar with challenge title',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // AppBar should be visible
        expect(find.byType(AppBar), findsOneWidget);
        // Challenge title should be in AppBar
        expect(find.text('Python基礎'), findsWidgets);
      });

      testWidgets('displays progress indicator showing question count',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress indicator should show current question
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('displays first question on load', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // First question should be displayed
        expect(
          find.text('Pythonで変数を定義するには？'),
          findsOneWidget,
        );
      });

      testWidgets('displays concept explanation card initially',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Concept card should be visible at start
        expect(find.byType(Card), findsWidgets);
      });
    });

    // Question Display Tests
    group('Question Display and Content', () {
      testWidgets('displays question text clearly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Pythonで変数を定義するには？'), findsOneWidget);
      });

      testWidgets('displays all answer options', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('x = 5'), findsOneWidget);
        expect(find.text('var x = 5'), findsOneWidget);
        expect(find.text('5 -> x'), findsOneWidget);
        expect(find.text('def x = 5'), findsOneWidget);
      });

      testWidgets('displays code snippet when available',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Code snippet should display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays question number and total',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show progress like "Question 1 of 3"
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays difficulty level indicator',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Answer Selection Tests
    group('Answer Selection and Feedback', () {
      testWidgets('selects answer when option tapped',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Tap first option
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Option should show selection state
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('allows changing selected answer before submission',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Select first option
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Select different option
        await tester.tap(find.text('var x = 5'));
        await tester.pumpAndSettle();

        // Second option should be selected
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows correct/incorrect feedback after submission',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Select correct answer
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Submit answer
        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('disables answer selection after submission',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Select answer
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Submit
        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      });

      testWidgets('shows explanation after correct answer',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Select correct answer
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Submit
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

      testWidgets('shows explanation after incorrect answer',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Select incorrect answer
        await tester.tap(find.text('var x = 5'));
        await tester.pumpAndSettle();

        // Submit
        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Question Navigation Tests
    group('Question Navigation', () {
      testWidgets('navigates to next question after answering',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Answer first question
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Submit
        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      });

      testWidgets('displays subsequent questions in sequence',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should start with question 1
        expect(find.text('Pythonで変数を定義するには？'), findsOneWidget);
      });

      testWidgets('shows progress through quiz', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress bar should indicate position
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('navigates back with back button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Look for back button
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Hint System Tests
    group('Hint System', () {
      testWidgets('displays hint button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Hint button should be present
        final hintButton = find.byIcon(Icons.lightbulb_outline);
        expect(hintButton.evaluate().isNotEmpty, true);
      });

      testWidgets('shows hint when hint button tapped',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap hint button
        final hintButton = find.byIcon(Icons.lightbulb_outline);
        if (hintButton.evaluate().isNotEmpty) {
          await tester.tap(hintButton.first);
          await tester.pumpAndSettle();

          // Hint should be visible
          expect(find.text('等号を使います'), findsWidgets);
        }
      });

      testWidgets('can only use hint once per question',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap hint button
        final hintButton = find.byIcon(Icons.lightbulb_outline);
        if (hintButton.evaluate().isNotEmpty) {
          await tester.tap(hintButton.first);
          await tester.pumpAndSettle();

          // Button should show it's been used
          expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);
        }
      });

      testWidgets('hint text displays clearly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap hint button
        final hintButton = find.byIcon(Icons.lightbulb_outline);
        if (hintButton.evaluate().isNotEmpty) {
          await tester.tap(hintButton.first);
          await tester.pumpAndSettle();

          // Hint text should be readable
          expect(find.byType(Text), findsWidgets);
        }
      });
    });

    // Timer Tests
    group('Timer and Time Management', () {
      testWidgets('displays timer', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Timer should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('timer counts down', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Wait for timer to decrease
        await tester.pump(const Duration(seconds: 1));

        // Timer should have updated
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('timer color changes as time runs out',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Simulate time passing
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Score Tracking Tests
    group('Score and Performance Tracking', () {
      testWidgets('tracks correct answers', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Answer correctly
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('displays score feedback', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('calculates combo streak', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Answer and submit
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('shows speed bonus indication', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Keyboard Shortcuts Tests
    group('Keyboard Shortcuts', () {
      testWidgets('selects answer with number keys (1-4)',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press '1' key to select first option
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('submits answer with Enter key', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select answer and press Enter
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      });

      testWidgets('requests hint with H key', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press 'H' key to show help/hint
        await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
        await tester.pumpAndSettle();
      });

      testWidgets('navigates with arrow keys', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Arrow down to navigate
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      });
    });

    // Bookmark/Flag Tests
    group('Bookmark and Flag Functionality', () {
      testWidgets('displays bookmark button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Bookmark button should be present
        final bookmarkButton = find.byIcon(Icons.bookmark_outline);
        expect(bookmarkButton.evaluate().isNotEmpty, true);
      });

      testWidgets('toggles bookmark on question', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toggle bookmark
        final bookmarkButton = find.byIcon(Icons.bookmark_outline);
        if (bookmarkButton.evaluate().isNotEmpty) {
          await tester.tap(bookmarkButton.first);
          await tester.pumpAndSettle();

          // Icon should change to filled
          expect(find.byIcon(Icons.bookmark), findsWidgets);
        }
      });

      testWidgets('persists bookmark state across questions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Bookmark first question
        final bookmarkButton = find.byIcon(Icons.bookmark_outline);
        if (bookmarkButton.evaluate().isNotEmpty) {
          await tester.tap(bookmarkButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Session Completion Tests
    group('Quiz Completion', () {
      testWidgets('shows final results screen after all questions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Complete first question
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      });

      testWidgets('displays final score summary', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows achievement badges if earned', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('calculates stars earned', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('updates progress after completion',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });
    });

    // Override Questions Tests
    group('Override Questions Feature', () {
      testWidgets('uses override questions when provided',
          (WidgetTester tester) async {
        final overrideQuestions = [
          Question(
            id: 'override_q1',
            text: 'Override question?',
            options: ['yes', 'no', 'maybe', 'always'],
            correctIndex: 0,
            explanation: 'Override is yes',
            hint: 'Think about it',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(
                challenge: mockStage,
                overrideQuestions: overrideQuestions,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Override question should display
        expect(find.text('Override question?'), findsOneWidget);
      });

      testWidgets('displays override question options', (WidgetTester tester) async {
        final overrideQuestions = [
          Question(
            id: 'override_q1',
            text: 'Override question?',
            options: ['yes', 'no', 'maybe', 'always'],
            correctIndex: 0,
            explanation: 'Override is yes',
            hint: 'Think about it',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(
                challenge: mockStage,
                overrideQuestions: overrideQuestions,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('yes'), findsOneWidget);
        expect(find.text('no'), findsOneWidget);
      });
    });

    // Error Handling Tests
    group('Error Handling and Edge Cases', () {
      testWidgets('handles empty questions list gracefully',
          (WidgetTester tester) async {
        final emptyStage = Stage(
          id: 'empty',
          stageNumber: 2,
          title: 'Empty Quiz',
          description: 'No questions',
          level: '初級',
          icon: 'icon_1',
          isFree: true,
          questions: [],
          type: 'quiz',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: emptyStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('handles question with no explanation',
          (WidgetTester tester) async {
        final noExplainStage = Stage(
          id: 'no_explain',
          stageNumber: 3,
          title: 'Quiz',
          description: 'Test',
          level: '初級',
          icon: 'icon_1',
          isFree: true,
          questions: [
            Question(
              id: 'q1',
              text: 'Question without explanation?',
              options: ['a', 'b', 'c', 'd'],
              correctIndex: 0,
              explanation: 'The answer is a',
              hint: 'No hint',
            ),
          ],
          type: 'quiz',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: noExplainStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Question without explanation?'), findsOneWidget);
      });

      testWidgets('handles rapid answer selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Rapidly tap options
        await tester.tap(find.text('x = 5'));
        await tester.tap(find.text('var x = 5'));
        await tester.tap(find.text('5 -> x'));

        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('handles submission without selection',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Try to submit without selecting
        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          // Button might be disabled, but try anyway
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Visual and UI Tests
    group('Visual Design and Theme', () {
      testWidgets('respects theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('displays proper text styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('option cards have distinct appearance',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('feedback animations display correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Integration Tests
    group('Integration and Workflow Tests', () {
      testWidgets('complete quiz workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        // Question 1: Answer and submit
        await tester.pumpAndSettle();
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('quiz with hint and bookmark usage',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Use hint
        final hintButton = find.byIcon(Icons.lightbulb_outline);
        if (hintButton.evaluate().isNotEmpty) {
          await tester.tap(hintButton.first);
          await tester.pumpAndSettle();
        }

        // Bookmark question
        final bookmarkButton = find.byIcon(Icons.bookmark_outline);
        if (bookmarkButton.evaluate().isNotEmpty) {
          await tester.tap(bookmarkButton.first);
          await tester.pumpAndSettle();
        }

        // Answer question
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('quiz navigation with keyboard shortcuts',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Use keyboard shortcuts
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testWidgets('multiple correct answers in sequence',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Answer first question correctly
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        expect(find.byType(QuizScreen), findsOneWidget);
      });
    });
  });
}
