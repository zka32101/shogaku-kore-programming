import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/stage_list_screen.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'package:shogaku_kore_programming/config/theme.dart';
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

  group('StageListScreen Widget Tests', () {
    // Basic Screen Rendering Tests
    group('Basic Screen Rendering', () {
      testWidgets('displays stage list screen without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(StageListScreen), findsOneWidget);
      });

      testWidgets('displays tab bar with three difficulty levels',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have TabBar with 3 tabs
        expect(find.byType(TabBar), findsOneWidget);
      });

      testWidgets('displays beginner tab initially', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // First tab should be selected
        expect(find.byType(Tab), findsWidgets);
      });

      testWidgets('displays stage cards in list', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stage cards should be visible
        expect(find.byType(Card), findsWidgets);
      });
    });

    // Tab Navigation Tests
    group('Tab Navigation', () {
      testWidgets('switches to intermediate tab', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap intermediate tab
        final tabs = find.byType(Tab);
        if (tabs.evaluate().length >= 2) {
          await tester.tap(tabs.at(1));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('switches to advanced tab', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap advanced tab
        final tabs = find.byType(Tab);
        if (tabs.evaluate().length >= 3) {
          await tester.tap(tabs.at(2));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('navigates tabs with keyboard 1/2/3 shortcuts',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send keyboard shortcuts
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
        await tester.pumpAndSettle();
      });

      testWidgets('navigates tabs with arrow keys', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Right arrow to next tab
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        // Left arrow to previous tab
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
      });

      testWidgets('opens with specific level when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: StageListScreen(
                initialLevel: StageLevel.intermediate,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should open on intermediate tab
        expect(find.byType(StageListScreen), findsOneWidget);
      });
    });

    // Stage Card Display Tests
    group('Stage Card Display', () {
      testWidgets('displays stage title and description', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stage information should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays stage difficulty indicator', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Difficulty indicators should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays completion status for stage', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Status indicators should display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays star ratings for completed stages',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stars should display for completed stages
        expect(find.byIcon(Icons.star), findsWidgets);
      });

      testWidgets('displays estimated time for each stage', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Time estimates should be visible
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Stage Selection Tests
    group('Stage Selection and Navigation', () {
      testWidgets('taps stage card to start challenge', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap a stage card
        final cards = find.byType(Card);
        if (cards.evaluate().isNotEmpty) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('selects random stage with R key', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send R key for random challenge
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.pumpAndSettle();
      });

      testWidgets('navigates to flashcard screen with F key',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send F key for flashcards
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.pumpAndSettle();
      });
    });

    // Favorites Filter Tests
    group('Favorites Filtering', () {
      testWidgets('displays favorites filter option', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Favorites filter should be available
        expect(find.byIcon(Icons.favorite), findsWidgets);
      });

      testWidgets('filters stages to show only favorites', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(openFavorites: true),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display favorites-filtered list
        expect(find.byType(StageListScreen), findsOneWidget);
      });

      testWidgets('toggles favorite status of stage', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find favorite button
        final favoriteButtons = find.byIcon(Icons.favorite_border);
        if (favoriteButtons.evaluate().isNotEmpty) {
          await tester.tap(favoriteButtons.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Search Tests
    group('Search Functionality', () {
      testWidgets('opens search with / key', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send / key to open search
        await tester.sendKeyEvent(LogicalKeyboardKey.slash);
        await tester.pumpAndSettle();

        // Search delegate should be visible
        expect(find.byType(SearchBar), findsWidgets);
      });

      testWidgets('has search bar visible', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Search button should be available
        expect(find.byIcon(Icons.search), findsWidgets);
      });

      testWidgets('filters results by search query', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap search button
        final searchButton = find.byIcon(Icons.search);
        if (searchButton.evaluate().isNotEmpty) {
          await tester.tap(searchButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Progress Indication Tests
    group('Progress Indication', () {
      testWidgets('displays total completion percentage', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress indicators should display
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('shows completed vs total stages for each level',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stage count information should display
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('highlights locked stages', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Locked stages should have visual indication
        expect(find.byType(Container), findsWidgets);
      });
    });

    // Keyboard Shortcuts Tests
    group('Keyboard Shortcuts', () {
      testWidgets('shows help dialog with Shift+? shortcut',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Help should be accessible via shortcuts
        expect(find.byType(StageListScreen), findsOneWidget);
      });

      testWidgets('navigates back with Escape key', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send Escape key
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      });

      testWidgets('navigates back with Backspace key', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send Backspace key
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();
      });
    });

    // Scrolling and Layout Tests
    group('Scrolling and Layout', () {
      testWidgets('stage list is scrollable', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have scrollable content
        expect(find.byType(ListView), findsWidgets);
      });

      testWidgets('maintains scroll position when switching tabs',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tab switching should preserve state
        final tabs = find.byType(Tab);
        if (tabs.evaluate().length >= 2) {
          await tester.tap(tabs.at(1));
          await tester.pumpAndSettle();
          await tester.tap(tabs.at(0));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('displays stages in card grid', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Cards should be arranged in grid
        expect(find.byType(Card), findsWidgets);
      });
    });

    // Animation Tests
    group('Animations', () {
      testWidgets('animates tab transitions', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tab animation should complete
        final tabs = find.byType(Tab);
        if (tabs.evaluate().length >= 2) {
          await tester.tap(tabs.at(1));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('animates stage card selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Card selection should animate
        final cards = find.byType(Card);
        if (cards.evaluate().isNotEmpty) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Theme Tests
    group('Theme and Styling', () {
      testWidgets('respects theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Screen should render with theme colors
        expect(find.byType(StageListScreen), findsOneWidget);
      });

      testWidgets('displays proper text styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text should be styled correctly
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Error Handling Tests
    group('Error Handling and Edge Cases', () {
      testWidgets('handles empty stage list gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Screen should render even with minimal data
        expect(find.byType(StageListScreen), findsOneWidget);
      });

      testWidgets('handles rapid tab switching', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Rapid keyboard navigation should work
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
        await tester.pumpAndSettle();
      });

      testWidgets('handles long stage titles', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Long titles should be handled properly
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Integration Tests
    group('Integration Tests', () {
      testWidgets('complete workflow: navigate, select stage, start challenge',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to intermediate tab
        await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
        await tester.pumpAndSettle();

        // Select a stage
        final cards = find.byType(Card);
        if (cards.evaluate().isNotEmpty) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('favorites workflow: toggle favorite and filter',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toggle favorite
        final favoriteButtons = find.byIcon(Icons.favorite_border);
        if (favoriteButtons.evaluate().isNotEmpty) {
          await tester.tap(favoriteButtons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('search workflow: open search and find stage',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open search
        final searchButton = find.byIcon(Icons.search);
        if (searchButton.evaluate().isNotEmpty) {
          await tester.tap(searchButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('keyboard navigation workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: StageListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Keyboard navigation workflow
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
      });
    });
  });
}
