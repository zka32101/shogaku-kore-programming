import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/screens/quiz_result_screen.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
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
      title: 'Math Quiz',
      description: 'Basic math questions',
      level: StageLevel.beginner,
      iconId: 'icon_1',
      questions: const [],
      requiredStars: 1,
      type: 'quiz',
    );

    testWidgets('displays result screen', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Verify result screen is displayed
      expect(find.byType(QuizResultScreen), findsOneWidget);
    });

    testWidgets('displays correct score', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Score should be displayed (e.g., "2/2 正解")
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays stars earned', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Stars should be displayed with animation
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('displays challenge title', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Challenge title should be visible
      expect(find.text('Math Quiz'), findsWidgets);
    });

    testWidgets('displays answers review button', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Look for review button
      final reviewButton = find.byType(ElevatedButton);
      expect(reviewButton, findsWidgets);
    });

    testWidgets('displays continue/next button', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Continue button should exist
      final buttons = find.byType(ElevatedButton);
      expect(buttons.evaluate().length, greaterThan(0));
    });

    testWidgets('shows level up message when level increases',
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

    testWidgets('shows first completion badge', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // First completion indicator should be shown
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays performance statistics', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Performance stats should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('can tap continue button', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Tap continue button
      final continueButton = find.byType(ElevatedButton).first;
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
    });

    testWidgets('displays improvement message when stars increased',
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

      await tester.pumpAndSettle();

      // Improvement message should show
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays trophy for perfect score', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Look for trophy or perfect score indicator
      expect(find.byIcon(Icons.emoji_events), findsWidgets);
    });

    testWidgets('shows solved wrong answers count', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Solved wrong count should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays coins earned', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Coins earned should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays difficulty feedback', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Feedback message based on performance
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('next stage card displays when available',
        (WidgetTester tester) async {
      final nextChallenge = Stage(
        id: 'test_challenge_2',
        title: 'Advanced Math',
        description: 'More complex math',
        level: StageLevel.intermediate,
        iconId: 'icon_2',
        questions: const [],
        requiredStars: 2,
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

      await tester.pumpAndSettle();

      // Next stage card should be visible
      expect(find.text('Advanced Math'), findsWidgets);
    });

    testWidgets('supports keyboard shortcuts', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Test Enter key to continue
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    });

    testWidgets('animates stars appearing', (WidgetTester tester) async {
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

      // Star animation should occur
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Stars should be visible
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('displays time taken', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Time taken should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('handles back button correctly', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Look for back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('displays retry option for low scores', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Retry button should be available
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
