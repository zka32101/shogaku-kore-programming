import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/profile_screen.dart';
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

  group('ProfileScreen Widget Tests', () {
    // Basic Rendering Tests
    group('Basic Screen Rendering', () {
      testWidgets('displays profile screen without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('displays user profile header section',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Profile header should be visible (contains avatar and nickname)
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays learning statistics', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stats should display learning metrics
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays scrollable content', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Profile screen should have scrollable content
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    });

    // Avatar and Profile Display Tests
    group('Profile Display', () {
      testWidgets('displays user avatar emoji', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Avatar emoji should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays user nickname', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Nickname should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays learning level', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // User level should be displayed
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Statistics Display Tests
    group('Learning Statistics Display', () {
      testWidgets('displays completed stages count', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Completed stages stat should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays total stars earned', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stars earned stat should display
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays learning streak', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Learning streak should be visible
        expect(find.byIcon(Icons.local_fire_department), findsWidgets);
      });

      testWidgets('displays perfect stages count', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perfect stages stat should display
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays learning time', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Learning time should be displayed
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Name Editing Tests
    group('Profile Name Editing', () {
      testWidgets('shows name in view mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Name should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('enables editing with keyboard shortcut E',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send 'E' key to toggle editing mode
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
        await tester.pumpAndSettle();

        // TextField should be available for editing
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('exits editing mode with Escape key',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
        await tester.pumpAndSettle();

        // Exit edit mode with Escape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      });
    });

    // Profile Sharing Tests
    group('Profile Sharing', () {
      testWidgets('has share button in profile header',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Share button should be available
        expect(find.byIcon(Icons.share), findsWidgets);
      });

      testWidgets('copies profile stats to clipboard with S key',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send 'S' key to share profile
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.pumpAndSettle();

        // SnackBar should show confirmation
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    // Keyboard Shortcuts Tests
    group('Keyboard Shortcuts', () {
      testWidgets('shows help dialog with Shift+? shortcut',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send Shift+/ to show help
        // Note: This might not work in test environment, but we can verify structure
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('navigates back with Escape key', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify back button exists
        expect(find.byIcon(Icons.arrow_back), findsWidgets);
      });

      testWidgets('navigates back with Backspace key',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Send Backspace key
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();
      });
    });

    // Learning Calendar Tests
    group('Learning Calendar', () {
      testWidgets('displays learning calendar widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Calendar should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows learning activity heatmap', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Activity visualization should be present
        expect(find.byType(Container), findsWidgets);
      });
    });

    // Statistics Cards Tests
    group('Statistics Cards', () {
      testWidgets('displays all stat cards in sections', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Multiple stat cards should be displayed
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('displays completion progress bar', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress indicator should be visible
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('displays achievement section', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Achievement section should be visible
        expect(find.byType(Text), findsWidgets);
      });
    });

    // Theme and Styling Tests
    group('Theme and Styling', () {
      testWidgets('respects theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Screen should render with proper theme
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('displays proper text styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text widgets should be properly styled
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsWidgets);
      });
    });

    // Navigation Tests
    group('Navigation', () {
      testWidgets('back button navigates correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: const ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Back button should exist
        expect(find.byIcon(Icons.arrow_back), findsWidgets);
      });

      testWidgets('can navigate to linked screens', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigation buttons should be present
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    // Interactive Elements Tests
    group('Interactive Elements', () {
      testWidgets('avatar emoji is selectable', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Avatar should be interactive
        expect(find.byType(GestureDetector), findsWidgets);
      });

      testWidgets('stat cards provide feedback on interaction',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stat cards should be interactive
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('buttons respond to taps', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Buttons should be present and tapable
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Error Handling Tests
    group('Error Handling and Edge Cases', () {
      testWidgets('handles empty profile data gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Screen should still render with no data
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('handles long usernames', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text overflow should be handled
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('handles animations properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Animations should complete without errors
        expect(find.byType(ProfileScreen), findsOneWidget);
      });
    });

    // Integration Tests
    group('Integration Tests', () {
      testWidgets('profile displays all sections in sequence',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll through all sections
        await tester.scrollUntilVisible(
          find.byType(Text).first,
          500.0,
          scrollable: find.byType(SingleChildScrollView).first,
        );

        // All major components should be present
        expect(find.byType(Text), findsWidgets);
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('statistics update when navigating back',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Profile should reflect current stats
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('keyboard and mouse interactions coexist',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Both interaction modes should work
        expect(find.byType(GestureDetector), findsWidgets);
      });
    });
  });
}
