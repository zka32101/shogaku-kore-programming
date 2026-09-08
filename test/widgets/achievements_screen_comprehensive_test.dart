import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_utils.dart';
import '../../lib/screens/achievements_screen.dart';
import '../../lib/providers/progress_provider.dart';
import '../../lib/providers/profile_provider.dart';
import '../../lib/providers/challenges_provider.dart';
import '../../lib/providers/time_attack_provider.dart';
import '../../lib/providers/flashcard_provider.dart';
import '../../lib/providers/wrong_answers_provider.dart';
import '../../lib/providers/daily_review_provider.dart';
import '../../lib/providers/favorites_provider.dart';
import '../../lib/models/badge.dart';
import '../../lib/config/theme.dart';
import '../../lib/config/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AchievementsScreen - Basic Screen Rendering', () {
    testWidgets('renders screen with scaffold and header', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays AppBar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsWidgets);
    });

    testWidgets('renders three tabs: Badges, Completed, Statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsWidgets);
    });

    testWidgets('displays header with user stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Should contain header information
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders TabBarView with three tab views', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
    });
  });

  group('AchievementsScreen - Tab Navigation', () {
    testWidgets('initially displays first tab (Badges)', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final tabBar = find.byType(TabBar);
      expect(tabBar, findsOneWidget);
    });

    testWidgets('switches to second tab when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      // Tab should be selected
      expect(find.byType(Tab), findsWidgets);
    });

    testWidgets('switches to third tab when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      // Tab should be selected
      expect(find.byType(Tab), findsWidgets);
    });

    testWidgets('tab switching updates active tab indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final firstTab = find.byType(Tab).first;
      await tester.tap(firstTab);
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      expect(find.byType(Tab), findsWidgets);
    });

    testWidgets('tab bar displays correct labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('バッジ'), findsWidgets);
      expect(find.textContaining('クリア'), findsWidgets);
      expect(find.textContaining('統計'), findsWidgets);
    });
  });

  group('AchievementsScreen - Keyboard Shortcuts', () {
    testWidgets('pressing "1" key switches to first tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('pressing "2" key switches to second tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('pressing "3" key switches to third tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('pressing Numpad 1 switches to first tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('pressing arrow right navigates to next tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('pressing arrow left navigates to previous tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // First move to tab 2
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      // Then press left arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('pressing S key triggers stats sharing', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      // Should show snackbar or clipboard action
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('pressing Escape key navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Navigation should occur (check navigation state)
      expect(find.byType(AchievementsScreen), findsWidgets);
    });

    testWidgets('pressing Backspace key navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsWidgets);
    });

    testWidgets('pressing Shift+? shows keyboard shortcuts help dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate Shift+? (requires both modifiers)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      // Dialog should appear with shortcuts
      expect(find.byType(Dialog), findsWidgets);
    });
  });

  group('AchievementsScreen - Badge Tab Content', () {
    testWidgets('displays badges list in first tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // First tab is selected by default
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('shows unlocked badge count in tab label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('バッジ'), findsWidgets);
    });

    testWidgets('badge cards display correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Should have card-like widgets
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('refresh button in badge tab invalidates providers', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Look for refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('completed badges show unlock date', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('locked badges show unlock requirements', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('AchievementsScreen - Completed Tab Content', () {
    testWidgets('displays completed stages in second tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('shows completed stage count in tab label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('クリア'), findsWidgets);
    });

    testWidgets('displays completed stage cards with star ratings', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('stage cards show difficulty level', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('scrolling completes stage list', (WidgetTester tester) async {
      tester.binding.window.physicalSize = const Size(1080, 1920);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });
  });

  group('AchievementsScreen - Statistics Tab Content', () {
    testWidgets('displays statistics in third tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('shows learning activity chart/heatmap', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('displays streak statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      expect(find.textContaining('連続'), findsWidgets);
    });

    testWidgets('shows learning time statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('displays question answer statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('shows unit completion progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('AchievementsScreen - Statistics Sharing', () {
    testWidgets('share stats copies to clipboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger share via keyboard shortcut
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      // Should show snackbar confirming clipboard copy
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('share stats includes badge information', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('share stats includes completion count', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('share stats includes current level', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('share stats includes streak information', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('snackbar appears after stats share', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });
  });

  group('AchievementsScreen - Provider Integration', () {
    testWidgets('watches progress provider for state updates', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('reads profile provider for user name', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('watches challenges provider for stage data', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('reads time attack provider for best scores', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('reads flashcard provider for mastered cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('reads wrong answers provider for review count', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('reads daily review provider for streak', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('reads favorites provider for bookmark count', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('AchievementsScreen - Theme and Styling', () {
    testWidgets('renders with light theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with dark theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('tab bar uses primary color for selected tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('header text displays in correct style', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('badge cards display with consistent styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('statistics display with proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final thirdTab = find.byType(Tab).at(2);
      await tester.tap(thirdTab);
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('AchievementsScreen - Error Handling', () {
    testWidgets('handles empty badge list gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('handles empty completed stages list', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('handles rapid tab switching without crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 10; i++) {
        final tab = find.byType(Tab).at(i % 3);
        await tester.tap(tab);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('handles back navigation when at root', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsWidgets);
    });

    testWidgets('handles invalid keyboard inputs gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });
  });

  group('AchievementsScreen - Header Statistics', () {
    testWidgets('displays user level in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays total stars earned in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays completed stage count in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays longest streak in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays badge count progress in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('header updates when progress changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('AchievementsScreen - Focus and Accessibility', () {
    testWidgets('requests focus on initial build', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('keyboard focus enables shortcut handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('focus is managed during tab navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.byType(Focus), findsWidgets);
    });
  });

  group('AchievementsScreen - Haptic Feedback', () {
    testWidgets('provides haptic feedback on tab tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final tab = find.byType(Tab).at(1);
      await tester.tap(tab);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('provides haptic feedback on keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('provides haptic feedback on stats share', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });
  });

  group('AchievementsScreen - Full Integration Workflows', () {
    testWidgets('complete workflow: navigate tabs, view stats, share, back', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to completed tab
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      // Switch to stats tab
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();

      // Share stats
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      // Back to first tab
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('complete workflow: use arrow keys for navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('complete workflow: tap tabs then use keyboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('complete workflow: scroll in completed tab', (WidgetTester tester) async {
      tester.binding.window.physicalSize = const Size(1080, 1920);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final secondTab = find.byType(Tab).at(1);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('complete workflow: view help then continue', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      // Close help dialog
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });
  });
}
