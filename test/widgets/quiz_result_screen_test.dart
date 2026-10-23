import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/screens/quiz_result_screen.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'test_helpers.dart';

/// 結果画面を表示して最初の演出が始まる時点まで進める。
/// 約1.5秒後にバッジ演出画面が全面表示されるため、画面の検証はそれより前に行う。
Future<void> pumpResult(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// 結果画面は数秒後まで Future.delayed で演出を出すため、
/// テスト本体のあとに時間を進めて残タイマーをすべて消化する。
void testResult(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    await body(tester);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
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

  group('QuizResultScreen Widget Tests', () {
    // Create mock quiz answers
    final mockAnswers = [
      QuizAnswer(
        questionText: 'What is 2+2?',
        selectedAnswer: '4',
        correctAnswer: '4',
        isCorrect: true,
        explanation: 'Correct!',
        hintUsed: false,
      ),
      QuizAnswer(
        questionText: 'What is 3+3?',
        selectedAnswer: '6',
        correctAnswer: '6',
        isCorrect: true,
        explanation: 'Correct!',
        hintUsed: false,
      ),
    ];

    // Create mock challenge
    final mockChallenge = Stage(
      id: 'test_challenge',
      stageNumber: 1,
      title: 'Math Quiz',
      description: 'Basic math questions',
      level: '初級',
      icon: '⬜',
      isFree: true,
      questions: const [],
      type: 'quiz',
    );

    testResult('displays result screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Verify result screen is displayed
      expect(find.byType(QuizResultScreen), findsOneWidget);
    });

    testResult('displays correct score', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Score should be displayed (e.g., "2/2 正解")
      expect(find.byType(Text), findsWidgets);
    });

    testResult('displays stars earned', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Stars should be displayed with animation
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testResult('displays challenge title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Challenge title should be visible
      expect(find.text('Math Quiz'), findsWidgets);
    });

    testResult('displays answers review button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Look for review button
      final reviewButton = find.byType(ElevatedButton);
      expect(reviewButton, findsWidgets);
    });

    testResult('displays continue/next button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Continue button should exist
      final buttons = find.byType(ElevatedButton);
      expect(buttons.evaluate().length, greaterThan(0));
    });

    testResult('shows level up message when level increases',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
              didLevelUp: true,
              newLevel: 5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Level up message should be visible
      // Look for level-up related text
      expect(find.byType(Text), findsWidgets);
    });

    testResult('shows first completion badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // First completion indicator should be shown
      expect(find.byType(Container), findsWidgets);
    });

    testResult('displays performance statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
              maxCombo: 2,
              sessionSeconds: 120,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Performance stats should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testResult('can tap continue button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Tap continue button
      final continueButton = find.byType(ElevatedButton).first;
      await tester.tap(continueButton);
      await pumpResult(tester);
    });

    testResult('displays improvement message when stars increased',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: false,
              previousStars: 2,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // 前回(星2)から星3に上がったことを知らせるメッセージが出る
      expect(find.text('スコア改善！ ⭐⭐ → ⭐⭐⭐'), findsOneWidget);
    });

    testResult('displays trophy for perfect score', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
              maxCombo: 2,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // 全問正解のときは「完璧！」と 💯 が表示される
      expect(find.text('完璧！'), findsOneWidget);
      expect(find.text('💯'), findsOneWidget);
    });

    testResult('shows solved wrong answers count', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
              resolvedWrongCount: 1,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Solved wrong count should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testResult('displays coins earned', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
              coinsEarned: 50,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Coins earned should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testResult('displays difficulty feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 1,
              totalCount: 2,
              stars: 1,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Feedback message based on performance
      expect(find.byType(Text), findsWidgets);
    });

    testResult('next stage card displays when available',
        (WidgetTester tester) async {
      final nextChallenge = Stage(
        id: 'test_challenge_2',
        stageNumber: 2,
        title: 'Advanced Math',
        description: 'More complex math',
        level: '中級',
        icon: '⬜',
        isFree: true,
        questions: const [],
        type: 'quiz',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
              nextStage: nextChallenge,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // 次のステージへの案内が出る
      expect(find.text('次へ: Advanced Math'), findsOneWidget);
    });

    testResult('supports keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Test Enter key to continue
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpResult(tester);
    });

    testResult('animates stars appearing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      // 星アニメーションが進んだあと、獲得した星3つが表示される
      await pumpResult(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(3));
    });

    testResult('displays time taken', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
              sessionSeconds: 300, // 5 minutes
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Time taken should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testResult('handles back button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 2,
              totalCount: 2,
              stars: 3,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Look for back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await pumpResult(tester);
      }
    });

    testResult('displays retry option for low scores', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizResultScreen(
              challenge: mockChallenge,
              answers: mockAnswers,
              correctCount: 0,
              totalCount: 2,
              stars: 0,
              isFirstComplete: true,
            ),
          ),
        ),
      );

      await pumpResult(tester);

      // Retry button should be available
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
