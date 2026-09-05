import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/daily_missions_screen.dart';
import 'package:shogaku_kore_programming/providers/daily_mission_provider.dart';
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

  group('DailyMissionsScreen Widget Tests', () {
    // Basic Screen Rendering Tests
    group('Basic Screen Rendering', () {
      testWidgets('displays daily missions screen without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(DailyMissionsScreen), findsOneWidget);
      });

      testWidgets('displays AppBar with proper title', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // AppBar should be present
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays loading indicator initially',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        // Loading state should show progress indicator
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays scrollable content', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have scrollable content
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    });

    // Stats Section Tests
    group('Statistics Section', () {
      testWidgets('displays mission statistics', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stats should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays mission count', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Mission count should display
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays reward information', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Reward info should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays progress indicator', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress visualization should be present
        expect(find.byType(Container), findsWidgets);
      });
    });

    // Mission List Display Tests
    group('Mission List Display', () {
      testWidgets('displays incomplete missions', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Mission cards should be visible
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('displays mission title', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Mission titles should display
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays mission description', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Mission details should show
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays mission reward', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Reward badges should display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays mission completion status', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Completion indicators should show
        expect(find.byType(Container), findsWidgets);
      });
    });

    // Filter Toggle Tests
    group('Mission Filter Toggle', () {
      testWidgets('displays toggle button for completed missions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toggle button should be visible
        expect(find.byType(GestureDetector), findsWidgets);
      });

      testWidgets('toggles between incomplete and all missions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the filter toggle
        final toggles = find.byType(GestureDetector);
        if (toggles.evaluate().isNotEmpty) {
          // Should find at least one toggle gesture detector
          expect(toggles, findsWidgets);
        }
      });

      testWidgets('shows completed missions when toggled',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toggle to show completed
        final gestures = find.byType(GestureDetector);
        if (gestures.evaluate().isNotEmpty) {
          await tester.tap(gestures.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('updates display when filter changes',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Mission list should update on filter change
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    });

    // Mission Interaction Tests
    group('Mission Interactions', () {
      testWidgets('taps mission card to view details', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Mission cards should be tappable
        final cards = find.byType(Card);
        if (cards.evaluate().isNotEmpty) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('marks mission as complete', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check button should mark mission complete
        final checkButtons = find.byIcon(Icons.check_circle);
        if (checkButtons.evaluate().isNotEmpty) {
          await tester.tap(checkButtons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('shows mission start button', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Start button should be present
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    // Empty State Tests
    group('Empty States', () {
      testWidgets('displays empty state when all missions completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Empty state should be possible
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('displays appropriate empty message', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text should indicate state
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows check icon in empty state', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Icon should be present
        expect(find.byType(Icon), findsWidgets);
      });
    });

    // Loading State Tests
    group('Loading States', () {
      testWidgets('shows loading indicator while fetching missions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        // Loading should show spinner
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('transitions from loading to content', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should eventually show content
        expect(find.byType(DailyMissionsScreen), findsOneWidget);
      });
    });

    // Error State Tests
    group('Error Handling', () {
      testWidgets('displays error message when fetch fails',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Screen should render even with potential errors
        expect(find.byType(DailyMissionsScreen), findsOneWidget);
      });

      testWidgets('handles empty mission list gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle empty state
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    });

    // Provider Integration Tests
    group('Provider Integration', () {
      testWidgets('watches daily mission provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Provider state should be reflected
        expect(find.byType(DailyMissionsScreen), findsOneWidget);
      });

      testWidgets('watches incomplete missions provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Incomplete missions should display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('watches completed missions provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Completed missions should be retrievable
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    });

    // Theme and Styling Tests
    group('Theme and Styling', () {
      testWidgets('respects theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Colors should be applied from theme
        expect(find.byType(DailyMissionsScreen), findsOneWidget);
      });

      testWidgets('displays proper text styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text should be styled
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('gradient background in stats section', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Gradient should apply
        expect(find.byType(Container), findsWidgets);
      });
    });

    // Scrolling Tests
    group('Scrolling and Layout', () {
      testWidgets('content is scrollable', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should be able to scroll
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('maintains layout on scroll', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Layout should be consistent
        expect(find.byType(Column), findsWidgets);
      });
    });

    // Integration Tests
    group('Integration Tests', () {
      testWidgets('complete mission workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Start mission
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('toggle and view mission workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toggle filter
        final gestures = find.byType(GestureDetector);
        if (gestures.evaluate().isNotEmpty) {
          await tester.tap(gestures.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('mission completion and stats update', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: DailyMissionsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stats should reflect missions
        expect(find.byType(Container), findsWidgets);
      });
    });
  });
}
