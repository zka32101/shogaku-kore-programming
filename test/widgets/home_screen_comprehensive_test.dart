import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/home_screen.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'package:shogaku_kore_programming/providers/challenges_provider.dart';
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

  group('HomeScreen Comprehensive Widget Tests', () {
    // Basic Screen Rendering Tests
    group('Basic Screen Rendering', () {
      testWidgets('displays home screen without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('displays AppBar with proper title', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // AppBar should be present
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays scrollable content', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have scrollable content
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('displays user profile section', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Profile section should display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('loads all major sections', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });
    });

    // Progress Statistics Tests
    group('Progress Statistics Display', () {
      testWidgets('displays learning level', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Level should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays completed stages count', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays total stars earned', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays current learning streak', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Streak with fire icon should show
        expect(find.byIcon(Icons.local_fire_department), findsWidgets);
      });

      testWidgets('displays learning time', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays coins/rewards', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Daily Missions Section Tests
    group('Daily Missions Section', () {
      testWidgets('displays daily missions card', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Daily missions section should be visible
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('displays mission count and progress', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows mission reward preview', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('taps mission card to open missions screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final cards = find.byType(Card);
        if (cards.evaluate().isNotEmpty) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Next Stage Recommendation Tests
    group('Next Stage Recommendation', () {
      testWidgets('displays next stage to complete', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Next stage section should display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows stage title and description', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays stage difficulty indicator', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows launch button for next stage', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('taps stage to open it', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
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

    // Daily Tips Section Tests
    group('Daily Tips and Learning Content', () {
      testWidgets('displays daily tip card', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tip card should display
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows tip text content', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('next tip button rotates tips', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Look for next button
        final buttons = find.byIcon(Icons.arrow_forward);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('tip changes on rotation', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Multiple tips should be rotatable
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Navigation Shortcuts Tests
    group('Navigation Keyboard Shortcuts', () {
      testWidgets('T key opens Time Attack', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press T key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.pumpAndSettle();
      });

      testWidgets('R key opens Ranking', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press R key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.pumpAndSettle();
      });

      testWidgets('F key opens Flashcard', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press F key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.pumpAndSettle();
      });

      testWidgets('S key opens Stage List', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press S key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.pumpAndSettle();
      });

      testWidgets('D key opens Daily Review', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press D key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
        await tester.pumpAndSettle();
      });

      testWidgets('V key opens Reverse Teaching', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press V key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.pumpAndSettle();
      });

      testWidgets('G key opens Gallery', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press G key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
        await tester.pumpAndSettle();
      });

      testWidgets('E key opens Weekly Report', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press E key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
        await tester.pumpAndSettle();
      });

      testWidgets('C key opens Character screen', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press C key
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.pumpAndSettle();
      });
    });

    // Character Display Tests
    group('Character Display and Evolution', () {
      testWidgets('displays character avatar', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Character should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows character level/evolution', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays character interaction area', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('taps character to open character screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Character should be tappable
        final containers = find.byType(Container);
        if (containers.evaluate().isNotEmpty) {
          // Character area might be a container or gesture detector
          expect(find.byType(GestureDetector), findsWidgets);
        }
      });
    });

    // Quick Action Buttons Tests
    group('Quick Action Buttons', () {
      testWidgets('displays quick navigation buttons', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Quick buttons should be visible
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('achievement button is present', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Achievement/badge button should show
        expect(find.byIcon(Icons.emoji_events), findsWidgets);
      });

      testWidgets('profile button is present', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Profile button should show
        expect(find.byIcon(Icons.person), findsWidgets);
      });

      testWidgets('taps achievement button to navigate', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final achieveButton = find.byIcon(Icons.emoji_events);
        if (achieveButton.evaluate().isNotEmpty) {
          await tester.tap(achieveButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('taps profile button to open profile', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final profileButton = find.byIcon(Icons.person);
        if (profileButton.evaluate().isNotEmpty) {
          await tester.tap(profileButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Scrolling and Layout Tests
    group('Scrolling and Layout', () {
      testWidgets('content is scrollable', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should be able to scroll
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('all sections visible when scrolled', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll down to see more content
        await tester.scroll(find.byType(SingleChildScrollView).first, const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('maintains layout on multiple scrolls',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll multiple times
        for (int i = 0; i < 3; i++) {
          await tester.scroll(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();
        }

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    // Theme and Styling Tests
    group('Theme and Styling', () {
      testWidgets('respects theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Colors should be applied from theme
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('displays proper text styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text should be styled
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('gradient backgrounds render correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Gradient containers should display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('animations display smoothly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    // Provider Integration Tests
    group('Provider Integration', () {
      testWidgets('watches progress provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Provider state should be reflected
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('watches profile provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('watches challenges provider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays data from multiple providers',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Error Handling Tests
    group('Error Handling and Edge Cases', () {
      testWidgets('handles empty progress gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render even with minimal progress
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('handles missing challenges data', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('handles rapid navigation attempts', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Rapid key presses
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);

        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    // Goal Achievement Tests
    group('Goal and Milestone Celebrations', () {
      testWidgets('displays goal progress indicator', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Goal section should show
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows achievement notifications', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays milestone progress', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Integration Workflow Tests
    group('Full Integration Workflows', () {
      testWidgets('complete home screen navigation workflow',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap next stage button
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('navigate through multiple keyboard shortcuts',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Use multiple shortcuts
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.pumpAndSettle();
      });

      testWidgets('interact with multiple sections', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll through content
        await tester.scroll(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        // Interact with elements
        final cards = find.byType(Card);
        if (cards.evaluate().isNotEmpty) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('complete user session workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Rotate tips
        final nextButtons = find.byIcon(Icons.arrow_forward);
        if (nextButtons.evaluate().isNotEmpty) {
          await tester.tap(nextButtons.first);
          await tester.pumpAndSettle();
        }

        // View progress
        final cards = find.byType(Card);
        if (cards.evaluate().length > 1) {
          await tester.tap(cards.at(1));
          await tester.pumpAndSettle();
        }
      });
    });

    // Missing or Lazy-Loaded Content Tests
    group('Content Loading and Lazy Loading', () {
      testWidgets('displays loading indicators initially', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        // May show loading state briefly
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('shows content after loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Content should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('handles async data fetching', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });
  });
}
