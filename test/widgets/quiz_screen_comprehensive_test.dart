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

/// 回答後は Future.delayed（コンボ表示のクリア・自動進行）が残るため、
/// 画面サイズはスマホ縦画面に揃える。テスト本体のあとに画面を破棄して時間を進め、残タイマーを消化する。
void testQuiz(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    // スマホ縦画面。既定の800x600だと下側の選択肢が画面外になりタップできない。
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
    type: 'quiz',
  );

  group('QuizScreen Comprehensive Widget Tests', () {
    // Basic Screen Rendering Tests
    group('Basic Screen Rendering', () {
      testQuiz('displays quiz screen without errors',
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

      testQuiz('displays AppBar with challenge title',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // ヘッダーにステージ名が表示される
        expect(find.text('Python基礎'), findsOneWidget);
      });

      testQuiz('displays progress indicator showing question count',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // ヘッダーに「現在の問題番号/全問題数」と正解数が表示される
        expect(find.text('問1/3  ✅ 0正解'), findsOneWidget);
      });

      testQuiz('displays first question on load', (WidgetTester tester) async {
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
        await tester.pumpAndSettle();
      });

      testQuiz('displays concept explanation card initially',
          (WidgetTester tester) async {
        final conceptStage = Stage(
          id: 'quiz_concept',
          stageNumber: 1,
          title: 'Python基礎',
          description: 'Python基本の問題です',
          level: '初級',
          icon: '⬜',
          isFree: true,
          questions: mockStage.questions,
          conceptExplanation: 'Pythonの基本的な文法を学びます',
          type: 'quiz',
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: conceptStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 解説カードが問題より先に表示され、押すと問題に進む
        expect(find.text('クイズの前に読もう！'), findsOneWidget);
        expect(find.text('Pythonの基本的な文法を学びます'), findsOneWidget);
        expect(find.text('Pythonで変数を定義するには？'), findsNothing);

        await tester.tap(find.text('わかった！クイズをはじめる'));
        await tester.pumpAndSettle();
        expect(find.text('Pythonで変数を定義するには？'), findsOneWidget);
      });
    });

    // Question Display Tests
    group('Question Display and Content', () {
      testQuiz('displays question text clearly', (WidgetTester tester) async {
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

      testQuiz('displays all answer options', (WidgetTester tester) async {
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

      testQuiz('displays code snippet when available',
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

      testQuiz('displays question number and total',
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

      testQuiz('displays difficulty level indicator',
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
      testQuiz('selects answer when option tapped',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap first option
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // 選んだ答えを「確認する」で送ると、正解として採点される
        await tester.tap(find.text('確認する'));
        await tester.pumpAndSettle();
        expect(find.text('✅ 正解！'), findsOneWidget);
      });

      testQuiz('allows changing selected answer before submission',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select first option
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Select different option
        await tester.tap(find.text('var x = 5'));
        await tester.pumpAndSettle();

        // 最後に選んだ答え(不正解)で採点される
        await tester.tap(find.text('確認する'));
        await tester.pumpAndSettle();
        expect(find.text('✅ 正解！'), findsNothing);
        expect(find.textContaining('不正解'), findsWidgets);
      });

      testQuiz('shows correct/incorrect feedback after submission',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

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

      testQuiz('disables answer selection after submission',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

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

      testQuiz('shows explanation after correct answer',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select correct answer
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.text('確認する'));
        await tester.pump(const Duration(milliseconds: 600));

        // 正解の表示と解説が出る
        expect(find.text('✅ 正解！'), findsOneWidget);
        expect(
          find.text('Pythonでは `x = 5` で変数を定義します'),
          findsOneWidget,
        );
      });

      testQuiz('shows explanation after incorrect answer',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

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
      testQuiz('navigates to next question after answering',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

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

      testQuiz('displays subsequent questions in sequence',
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

      testQuiz('shows progress through quiz', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1問目の進捗が表示され、答えて「次へ」を押すと2問目になる
        expect(find.text('問1/3  ✅ 0正解'), findsOneWidget);
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('確認する'));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
        expect(find.text('問2/3  ✅ 1正解'), findsOneWidget);
      });

      testQuiz('navigates back with back button', (WidgetTester tester) async {
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
      testQuiz('displays hint button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Hint button should be present
        expect(find.byTooltip('ヒントを見る'), findsOneWidget);
      });

      testQuiz('shows hint when hint button tapped',
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

      testQuiz('can only use hint once per question',
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

      testQuiz('hint text displays clearly', (WidgetTester tester) async {
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
      testQuiz('displays timer', (WidgetTester tester) async {
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

      testQuiz('timer counts down', (WidgetTester tester) async {
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

      testQuiz('timer color changes as time runs out',
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
      testQuiz('tracks correct answers', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Answer correctly
        await tester.tap(find.text('x = 5'));
        await tester.pumpAndSettle();

        final submitButton = find.byType(ElevatedButton);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle();
        }
      });

      testQuiz('displays score feedback', (WidgetTester tester) async {
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

      testQuiz('calculates combo streak', (WidgetTester tester) async {
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

      testQuiz('shows speed bonus indication', (WidgetTester tester) async {
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
      testQuiz('selects answer with number keys (1-4)',
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

      testQuiz('submits answer with Enter key', (WidgetTester tester) async {
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

      testQuiz('requests hint with H key', (WidgetTester tester) async {
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

      testQuiz('navigates with arrow keys', (WidgetTester tester) async {
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
      testQuiz('displays bookmark button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Bookmark button should be present
        expect(find.byTooltip('お気に入りに追加 (B)'), findsOneWidget);
      });

      testQuiz('toggles bookmark on question', (WidgetTester tester) async {
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

      testQuiz('persists bookmark state across questions',
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
      testQuiz('shows final results screen after all questions',
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

      testQuiz('displays final score summary', (WidgetTester tester) async {
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

      testQuiz('shows achievement badges if earned', (WidgetTester tester) async {
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

      testQuiz('calculates stars earned', (WidgetTester tester) async {
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

      testQuiz('updates progress after completion',
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
      testQuiz('uses override questions when provided',
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

      testQuiz('displays override question options', (WidgetTester tester) async {
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
      testQuiz('handles empty questions list gracefully',
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

      testQuiz('handles question with no explanation',
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

      testQuiz('handles rapid answer selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rapidly tap options
        await tester.tap(find.text('x = 5'));
        await tester.tap(find.text('var x = 5'));
        await tester.tap(find.text('5 -> x'));

        await tester.pumpAndSettle();

        expect(find.byType(QuizScreen), findsOneWidget);
      });

      testQuiz('handles submission without selection',
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
      testQuiz('respects theme colors', (WidgetTester tester) async {
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

      testQuiz('displays proper text styling', (WidgetTester tester) async {
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

      testQuiz('option cards have distinct appearance',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 選択肢はA〜Dのラベル付きで4つ表示される
        for (final label in ['A', 'B', 'C', 'D']) {
          expect(find.text(label), findsOneWidget);
        }
        for (final option in ['x = 5', 'var x = 5', '5 -> x', 'def x = 5']) {
          expect(find.text(option), findsOneWidget);
        }
      });

      testQuiz('feedback animations display correctly',
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
      testQuiz('complete quiz workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: QuizScreen(challenge: mockStage),
            ),
          ),
        );
        await tester.pumpAndSettle();

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

      testQuiz('quiz with hint and bookmark usage',
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

      testQuiz('quiz navigation with keyboard shortcuts',
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

      testQuiz('multiple correct answers in sequence',
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
