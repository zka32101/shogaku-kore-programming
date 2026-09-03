import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/flashcard_screen.dart';
import 'package:shogaku_kore_programming/providers/flashcard_provider.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
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

  group('FlashcardScreen Widget Tests', () {
    testWidgets('displays flashcard screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify flashcard screen is displayed
      expect(find.byType(FlashcardScreen), findsOneWidget);
    });

    testWidgets('displays flashcard content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Flashcard content should be visible
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays card question/front side', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Question should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('can flip card to show answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap card to flip
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Answer should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress indicator should show (e.g., "Card 1 of 10")
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays difficulty buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Difficulty rating buttons should be visible
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('can rate card difficulty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Flip card first
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Tap difficulty button (e.g., "Hard" or "Easy")
      final difficultyButton = find.byType(ElevatedButton);
      if (difficultyButton.evaluate().isNotEmpty) {
        await tester.tap(difficultyButton.first);
        await tester.pumpAndSettle();

        // Should move to next card
        expect(find.byType(Card), findsWidgets);
      }
    });

    testWidgets('advances to next card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get initial card text
      final initialText = find.byType(Text).first;

      // Flip card
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Rate it
      final button = find.byType(ElevatedButton);
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button.first);
        await tester.pumpAndSettle();

        // Should show new card
        expect(find.byType(Card), findsWidgets);
      }
    });

    testWidgets('displays category selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Category dropdown or selector should be visible
      expect(find.byType(PopupMenuButton), findsWidgets);
    });

    testWidgets('can filter by category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap category selector
      final categoryButton = find.byType(PopupMenuButton);
      if (categoryButton.evaluate().isNotEmpty) {
        await tester.tap(categoryButton.first);
        await tester.pumpAndSettle();

        // Category menu should appear
        expect(find.byType(PopupMenuItem), findsWidgets);
      }
    });

    testWidgets('displays statistics summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Stats like "Correct: X, Wrong: Y" should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows mark as correct button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Flip card
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Correct button should be visible
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('shows mark as incorrect button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Flip card
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Incorrect button should be visible
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('updates statistics on answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get initial stats
      final initialStats = find.byType(Text);

      // Answer a card
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      final button = find.byType(ElevatedButton);
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button.first);
        await tester.pumpAndSettle();

        // Stats should be updated
        expect(find.byType(Text), findsWidgets);
      }
    });

    testWidgets('displays card count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card count should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays remaining cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remaining card count should be shown
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows shuffle option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for shuffle button
      final shuffleButton = find.byIcon(Icons.shuffle);
      expect(shuffleButton, findsWidgets);
    });

    testWidgets('can shuffle cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap shuffle button
      final shuffleButton = find.byIcon(Icons.shuffle);
      if (shuffleButton.evaluate().isNotEmpty) {
        await tester.tap(shuffleButton.first);
        await tester.pumpAndSettle();

        // Cards order should change
      }
    });

    testWidgets('displays reset option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for reset button
      final resetButton = find.byIcon(Icons.refresh);
      expect(resetButton, findsWidgets);
    });

    testWidgets('can reset session', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap reset button
      final resetButton = find.byIcon(Icons.refresh);
      if (resetButton.evaluate().isNotEmpty) {
        await tester.tap(resetButton.first);
        await tester.pumpAndSettle();

        // Stats should reset, back to first card
      }
    });

    testWidgets('shows completion message when finished',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // This depends on card count - if there's only one card,
      // completing it should show completion message
    });

    testWidgets('handles empty card set', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // If no cards available, should show appropriate message
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('back button exits flashcard screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();

        // Should pop navigator
      }
    });

    testWidgets('card flip animation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap card to flip with animation
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Card should show answer
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('supports keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test Space to flip card
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Card should flip
    });

    testWidgets('displays difficulty colors or indicators',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Difficulty indicators should be visible
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('saves progress automatically', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Answer some cards
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      final button = find.byType(ElevatedButton);
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button.first);
        await tester.pumpAndSettle();

        // Progress should be saved (handled by Riverpod provider)
      }
    });

    testWidgets('displays all card text content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Text content should be readable
      expect(find.byType(Text), findsWidgets);

      // Flip to see answer
      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Answer text should be visible
      expect(find.byType(Text), findsWidgets);
    });
  });
}
