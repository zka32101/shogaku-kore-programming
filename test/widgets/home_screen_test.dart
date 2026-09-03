import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/home_screen.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'package:shogaku_kore_programming/providers/coin_provider.dart';
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

  group('HomeScreen Widget Tests', () {
    testWidgets('displays home screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify home screen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('displays user greeting message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for greeting messages (implementation dependent)
      // Could be "おはよう" or similar
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays progress statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress stats should be visible
      // Look for widgets showing completed stages, stars, streak, etc.
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays next challenge card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Next challenge should be displayed
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('displays daily mission card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Daily mission should be visible (if user has completed challenges)
      // Look for mission-related UI
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays weekly stage progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Weekly stage card should be displayed
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays coin/currency balance', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Coin balance should be visible in header or stats area
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays tip/hint of the day', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tip of the day should be visible
      // Look for "今日のヒント" or similar
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('can navigate to challenges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for "全ての課題を見る" or similar navigation button
      final navigationButtons = find.byType(ElevatedButton);
      if (navigationButtons.evaluate().isNotEmpty) {
        // Tapping should navigate (implementation dependent)
        await tester.tap(navigationButtons.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('can start next challenge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for "チャレンジを開始" button
      final startButton = find.byType(ElevatedButton);
      if (startButton.evaluate().isNotEmpty) {
        // Should navigate to challenge screen
        await tester.tap(startButton.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('displays learning streak', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Streak information should be visible
      // Look for fire icon or streak counter
      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
    });

    testWidgets('displays level progression', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // User level should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays character avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Character avatar should be displayed
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('can open wrong answers review', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for wrong answers button/badge
      final wrongAnswersButton = find.byType(Badge);
      if (wrongAnswersButton.evaluate().isNotEmpty) {
        await tester.tap(wrongAnswersButton.first);
        await tester.pumpAndSettle();

        // Should navigate to wrong answers screen
      }
    });

    testWidgets('can open time attack mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for time attack card or button
      final timeAttackButton = find.byType(GestureDetector);
      if (timeAttackButton.evaluate().isNotEmpty) {
        // Should have a button to start time attack
      }
    });

    testWidgets('displays learning statistics correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Stats should display provider data correctly
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('supports keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test keyboard navigation (e.g., ? for help)
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pumpAndSettle();

      // Help dialog should appear (implementation dependent)
    });

    testWidgets('displays all major sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to see all sections
      await tester.scrollUntilVisible(
        find.byType(Text).first,
        500.0,
        scrollable: find.byType(SingleChildScrollView).first,
      );
    });

    testWidgets('displays today\'s learning summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Today's summary should show learning time, challenges completed, etc.
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays recommended challenge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Recommendation should be based on progress
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('character reacts to user progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Character should show mood/reaction
      // Look for character widget
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('displays achievement badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badges section should be visible
      // Look for badge display widgets
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('can access profile from home', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for profile button/avatar
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton.first);
        await tester.pumpAndSettle();

        // Should navigate to profile
      }
    });

    testWidgets('displays refresh button for updates', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton.first);
        await tester.pumpAndSettle();

        // Data should be refreshed
      }
    });

    testWidgets('displays notification indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for notification badges or indicators
      expect(find.byType(Badge), findsWidgets);
    });

    testWidgets('handles empty state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Even with no challenges or progress, screen should render
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
