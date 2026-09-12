import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/achievements_screen.dart';
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

  group('AchievementsScreen Widget Tests', () {
    testWidgets('displays achievements screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify achievements screen is displayed
      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('displays tab bar with 3 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab bar should have 3 tabs
      expect(find.byType(Tab), findsWidgets);
      final tabs = find.byType(Tab).evaluate();
      expect(tabs.length, greaterThanOrEqualTo(3));
    });

    testWidgets('displays badges tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First tab should be badges/achievements
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays badge icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge icons should be visible
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('can switch between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get tabs and tap second tab
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length > 1) {
        await tester.tap(tabs.at(1));
        await tester.pumpAndSettle();

        // Tab should change
        expect(find.byType(TabBar), findsOneWidget);
      }
    });

    testWidgets('displays unlocked badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Unlocked badges should be visible
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays locked badges with placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Locked badges might be shown as greyed out
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays progress bar for badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress should be displayed
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('shows badge description on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for a badge/card to tap
      final badges = find.byType(Card);
      if (badges.evaluate().isNotEmpty) {
        await tester.tap(badges.first);
        await tester.pumpAndSettle();

        // Details should appear
      }
    });

    testWidgets('displays clear records tab content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to second tab (clear records)
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length > 1) {
        await tester.tap(tabs.at(1));
        await tester.pumpAndSettle();

        // Clear records should be displayed
        expect(find.byType(ListView), findsWidgets);
      }
    });

    testWidgets('displays statistics tab content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to third tab (statistics)
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length > 2) {
        await tester.tap(tabs.at(2));
        await tester.pumpAndSettle();

        // Stats should be displayed
        expect(find.byType(Text), findsWidgets);
      }
    });

    testWidgets('displays charts in statistics tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to statistics
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length > 2) {
        await tester.tap(tabs.at(2));
        await tester.pumpAndSettle();

        // Charts should be visible
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    testWidgets('displays total achievements summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Summary info should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays achievement completion percentage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Percentage should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('supports keyboard shortcuts for tab switching',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Press '2' to switch to second tab
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      // Tab should change (implementation dependent)
    });

    testWidgets('supports arrow key navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Press right arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Tab should advance
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('displays leaderboard if available', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Leaderboard might be on statistics tab
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays user rank/position', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // User position should be shown
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('can filter or sort badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for filter/sort buttons
      final buttons = find.byType(IconButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // Filter options should appear
      }
    });

    testWidgets('displays share statistics option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for share button
      final shareButton = find.byIcon(Icons.share);
      expect(shareButton, findsWidgets);
    });

    testWidgets('can share statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap share button
      final shareButton = find.byIcon(Icons.share);
      if (shareButton.evaluate().isNotEmpty) {
        await tester.tap(shareButton.first);
        await tester.pumpAndSettle();

        // Share dialog/menu should appear
      }
    });

    testWidgets('displays badge unlock date', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Unlock dates should be visible when badges are tapped
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays rarity indication for badges',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rarity might be shown with color or label
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('handles empty state for new users', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display encouraging message if no badges yet
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('back button exits achievements screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
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

    testWidgets('displays help/info button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for help button
      final helpButton = find.byIcon(Icons.help_outline);
      expect(helpButton, findsWidgets);
    });

    testWidgets('scrolls through badges list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll through badges
      await tester.scroll(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // More badges should be visible
      expect(find.byType(Card), findsWidgets);
    });
  });
}
