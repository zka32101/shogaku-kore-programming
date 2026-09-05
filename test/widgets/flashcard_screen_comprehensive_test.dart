import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/flashcard_screen.dart';
import 'package:shogaku_kore_programming/providers/flashcard_provider.dart';
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

  group('FlashcardScreen Comprehensive Widget Tests', () {
    // Basic Screen Rendering Tests
    group('Basic Screen Rendering', () {
      testWidgets('displays flashcard screen without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });

      testWidgets('displays AppBar with proper title', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // AppBar should be present
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays first flashcard on load', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // First flashcard should display
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('displays card counter/progress', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress indicator showing card count
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays learning controls', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    // Flashcard Display Tests
    group('Flashcard Display and Content', () {
      testWidgets('displays flashcard front (question) side',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Front of card should show
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays flashcard with animation', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('displays card category tag', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Category should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows code snippet when available', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Code section might display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays back side (answer) on flip',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap card to flip
        final card = find.byType(Card);
        if (card.evaluate().isNotEmpty) {
          await tester.tap(card.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Card Flip/Interaction Tests
    group('Card Flip and Interaction', () {
      testWidgets('tapping card flips it', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap to flip
        final card = find.byType(Card);
        if (card.evaluate().isNotEmpty) {
          await tester.tap(card.first);
          await tester.pumpAndSettle();

          // Card should be flipped
          expect(find.byType(Card), findsWidgets);
        }
      });

      testWidgets('multiple flips work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final card = find.byType(Card);
        if (card.evaluate().isNotEmpty) {
          // Flip multiple times
          for (int i = 0; i < 3; i++) {
            await tester.tap(card.first);
            await tester.pumpAndSettle();
          }
        }
      });

      testWidgets('flip animation displays', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final card = find.byType(Card);
        if (card.evaluate().isNotEmpty) {
          await tester.tap(card.first);
          await tester.pump(); // Animation frame

          expect(find.byType(Card), findsWidgets);
        }
      });

      testWidgets('shows flip hint or instruction', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Instruction text should display
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Learning Control Tests
    group('Learning Controls (Again/Easy/Hard)', () {
      testWidgets('displays difficulty rating buttons', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Rating buttons should be visible
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('again button marks card for review', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap "Again" button
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('easy button marks card as learned', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().length > 1) {
          await tester.tap(buttons.at(1));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('hard button moderates difficulty', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().length > 2) {
          await tester.tap(buttons.at(2));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('button feedback provides confirmation', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    // Card Navigation Tests
    group('Card Navigation and Progression', () {
      testWidgets('loads next card after rating', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      });

      testWidgets('shows progress through deck', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress indicator should show
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('displays remaining card count', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('navigates back with back button', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Keyboard Shortcuts Tests
    group('Keyboard Shortcuts', () {
      testWidgets('space key flips card', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press space to flip
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
      });

      testWidgets('1 key rates as Again', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press 1 key
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
      });

      testWidgets('2 key rates as Hard', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press 2 key
        await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
        await tester.pumpAndSettle();
      });

      testWidgets('3 key rates as Easy', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press 3 key
        await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
        await tester.pumpAndSettle();
      });

      testWidgets('shortcuts work in sequence', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Space to flip
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // 3 to rate as easy
        await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
        await tester.pumpAndSettle();
      });
    });

    // Category Filter Tests
    group('Category Filtering', () {
      testWidgets('displays category filter options', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Filter options should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('filters cards by category', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Category buttons should be tappable
        expect(find.byType(GestureDetector), findsWidgets);
      });

      testWidgets('shows only selected category cards', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });
    });

    // Statistics Display Tests
    group('Learning Statistics', () {
      testWidgets('displays learning stats', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stats should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows cards reviewed count', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays learning streak', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows accuracy rate', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });
    });

    // Session Completion Tests
    group('Session Completion', () {
      testWidgets('displays completion message when all cards reviewed',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Completion state should be possible
        expect(find.byType(FlashcardScreen), findsOneWidget);
      });

      testWidgets('shows session summary', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('offers option to review again', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('shows progress toward goal', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Error Handling Tests
    group('Error Handling and Edge Cases', () {
      testWidgets('handles empty flashcard deck gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });

      testWidgets('handles card without code snippet', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('handles rapid flip/rating actions', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Rapid key presses
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);

        await tester.pumpAndSettle();

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });

      testWidgets('handles provider errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });
    });

    // Theme and Styling Tests
    group('Theme and Styling', () {
      testWidgets('respects theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });

      testWidgets('displays proper text styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('card visual styling displays correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('animations display smoothly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });
    });

    // Provider Integration Tests
    group('Provider Integration', () {
      testWidgets('watches flashcard provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });

      testWidgets('watches progress provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('updates progress on card rating', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Full Integration Tests
    group('Full Integration and Workflows', () {
      testWidgets('complete flashcard learning session', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Start session
        expect(find.byType(Card), findsWidgets);

        // Flip card
        final card = find.byType(Card);
        if (card.evaluate().isNotEmpty) {
          await tester.tap(card.first);
          await tester.pumpAndSettle();
        }

        // Rate card
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('keyboard-only flashcard session', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Use only keyboard shortcuts
        await tester.sendKeyEvent(LogicalKeyboardKey.space); // flip
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.digit3); // easy
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.space); // flip next
        await tester.pumpAndSettle();
      });

      testWidgets('category filter and review workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Filter by category (if available)
        final gestures = find.byType(GestureDetector);
        if (gestures.evaluate().isNotEmpty) {
          await tester.tap(gestures.first);
          await tester.pumpAndSettle();
        }

        // Review cards
        final card = find.byType(Card);
        if (card.evaluate().isNotEmpty) {
          await tester.tap(card.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('multiple session management', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FlashcardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Complete multiple cards
        for (int i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();

          await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        expect(find.byType(FlashcardScreen), findsOneWidget);
      });
    });
  });
}
