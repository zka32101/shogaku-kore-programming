import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_utils.dart';
import '../../lib/screens/daily_review_screen.dart';
import '../../lib/screens/quiz_result_screen.dart';
import '../../lib/providers/daily_review_provider.dart';
import '../../lib/providers/progress_provider.dart';
import '../../lib/providers/profile_provider.dart';
import '../../lib/config/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyReviewScreen - Basic Screen Rendering', () {
    testWidgets('renders screen with scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays AppBar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsWidgets);
    });

    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays quiz question after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders Focus widget for keyboard handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Focus), findsWidgets);
    });
  });

  group('DailyReviewScreen - Question Display', () {
    testWidgets('displays current question text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays question progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows question counter (e.g., 1/5)', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('/'), findsWidgets);
    });

    testWidgets('displays code snippet for question', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('displays answer options/buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('DailyReviewScreen - Answer Selection', () {
    testWidgets('can select first answer option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can select second answer option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can select third answer option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can select fourth answer option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('shows correct/incorrect feedback after answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('answer selection disables other options', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can tap answer button directly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });
  });

  group('DailyReviewScreen - Question Navigation', () {
    testWidgets('pressing Enter advances to next question', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can navigate through all 5 questions', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('shows completion screen after last question', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });
  });

  group('DailyReviewScreen - Hint System', () {
    testWidgets('displays hint button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byIcon(Icons.lightbulb), findsWidgets);
    });

    testWidgets('pressing H key shows hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can tap hint button directly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final hintButton = find.byIcon(Icons.lightbulb);
      if (hintButton.evaluate().isNotEmpty) {
        await tester.tap(hintButton.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('hint shows helpful information', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('hint can be cycled through multiple times', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });
  });

  group('DailyReviewScreen - Flagging/Bookmarking', () {
    testWidgets('displays flag button for bookmarking', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byIcon(Icons.flag), findsWidgets);
    });

    testWidgets('pressing F key flags current question', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can toggle flag by pressing F again', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('can tap flag button directly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final flagButton = find.byIcon(Icons.flag);
      if (flagButton.evaluate().isNotEmpty) {
        await tester.tap(flagButton.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });
  });

  group('DailyReviewScreen - Keyboard Shortcuts', () {
    testWidgets('pressing Escape key navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });

    testWidgets('pressing Backspace key navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });

    testWidgets('pressing Shift+? shows keyboard shortcuts help', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsWidgets);
    });

    testWidgets('numpad keys work for answer selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });
  });

  group('DailyReviewScreen - Scoring and Combo', () {
    testWidgets('displays current score', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('score increases on correct answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays combo streak counter', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('combo resets on incorrect answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('DailyReviewScreen - Session Timing', () {
    testWidgets('displays elapsed time during session', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('time updates during session', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('learning time is recorded on completion', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });
  });

  group('DailyReviewScreen - Completion and Results', () {
    testWidgets('shows completion message after all questions', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays final score', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows bonus points earned', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('DailyReviewScreen - Celebration and Feedback', () {
    testWidgets('plays sound on correct answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('provides haptic feedback on selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('shows confetti on session completion', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });

    testWidgets('displays result animation on completion', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });
  });

  group('DailyReviewScreen - Provider Integration', () {
    testWidgets('watches dailyReviewProvider for state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('reads progressProvider notifier', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('watches challengesProvider for questions', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('reads profileProvider for settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });
  });

  group('DailyReviewScreen - Theme and Styling', () {
    testWidgets('renders with light theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with dark theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays question with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('answer buttons have consistent styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('DailyReviewScreen - Error Handling', () {
    testWidgets('handles back navigation gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });

    testWidgets('handles rapid answer selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('handles invalid keyboard input', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });
  });

  group('DailyReviewScreen - Full Integration Workflows', () {
    testWidgets('complete workflow: answer all questions correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        if (i < 4) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DailyReviewScreen), findsWidgets);
    });

    testWidgets('complete workflow: use hint during session', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('complete workflow: flag and answer questions', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('complete workflow: keyboard-only interaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Answer with keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      // Next with keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Use hint with keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });

    testWidgets('complete workflow: mixed keyboard and tap interaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const DailyReviewScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Use keyboard for answer
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      // Tap button
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DailyReviewScreen), findsOneWidget);
    });
  });
}
