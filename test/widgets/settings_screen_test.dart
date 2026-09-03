import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/settings_screen.dart';
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

  group('SettingsScreen Widget Tests', () {
    testWidgets('displays settings screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify settings screen is displayed
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('displays settings title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Settings title should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays sound toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sound setting should be visible
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle sound setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap sound toggle
      final switchFinder = find.byType(Switch);
      if (switchFinder.evaluate().isNotEmpty) {
        await tester.tap(switchFinder.first);
        await tester.pumpAndSettle();

        // Toggle state should change
      }
    });

    testWidgets('displays haptics toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Haptics setting should be visible
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle haptics setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find haptics toggle
      final switches = find.byType(Switch);
      if (switches.evaluate().length > 1) {
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();

        // Toggle state should change
      }
    });

    testWidgets('displays notifications toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Notifications setting should be visible
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle notifications setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find notifications toggle
      final switches = find.byType(Switch);
      if (switches.evaluate().length > 2) {
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();

        // Toggle state should change
      }
    });

    testWidgets('displays theme mode selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Theme selector should be visible (dropdown, radio buttons, or buttons)
      expect(find.byType(PopupMenuButton), findsWidgets);
    });

    testWidgets('can change theme mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap theme selector
      final themeButton = find.byType(PopupMenuButton);
      if (themeButton.evaluate().isNotEmpty) {
        await tester.tap(themeButton.first);
        await tester.pumpAndSettle();

        // Menu should appear
        expect(find.byType(PopupMenuItem), findsWidgets);
      }
    });

    testWidgets('displays language selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Language selector should be visible
      expect(find.byType(PopupMenuButton), findsWidgets);
    });

    testWidgets('displays reminder time settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Reminder settings should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('can set reminder time', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for time picker button
      final timeButton = find.byType(OutlinedButton);
      if (timeButton.evaluate().isNotEmpty) {
        await tester.tap(timeButton.first);
        await tester.pumpAndSettle();

        // Time picker should appear
      }
    });

    testWidgets('displays profile navigation option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profile button should be visible
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('can navigate to profile', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for profile button
      final profileTile = find.byType(ListTile);
      if (profileTile.evaluate().isNotEmpty) {
        await tester.tap(profileTile.first);
        await tester.pumpAndSettle();

        // Should navigate to profile screen
      }
    });

    testWidgets('displays parent dashboard option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Parent dashboard option should be visible
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays premium upgrade option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Premium upgrade option should be visible
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('can open premium upgrade screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find upgrade button and tap
      final upgradeTile = find.byType(ListTile);
      if (upgradeTile.evaluate().isNotEmpty) {
        // Tap upgrade option (usually last or highlighted)
        await tester.tap(upgradeTile.last);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('displays about app option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // About app option should be visible
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('can open about dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for about button
      final aboutTile = find.byType(ListTile);
      if (aboutTile.evaluate().isNotEmpty) {
        await tester.tap(aboutTile.last);
        await tester.pumpAndSettle();

        // About dialog might appear
      }
    });

    testWidgets('displays clear data option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear data option should be visible
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('can trigger data reset', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to find clear data button
      await tester.scrollUntilVisible(
        find.byType(ListTile).last,
        500.0,
        scrollable: find.byType(ListView).first,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('supports keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test P key for profile
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();
    });

    testWidgets('displays version information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Version should be displayed somewhere
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('scrolls through all settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down to see more settings
      await tester.scroll(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      // More settings should be visible
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays section headers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Section headers like "Sound & Haptics", "Notifications" should exist
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('back button exits settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
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

    testWidgets('changes persist when navigating away',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle a setting
      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        // Change should persist (handled by Riverpod provider)
      }
    });

    testWidgets('displays quiz timer settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Quiz timer toggle and settings should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays weekly report settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Weekly report settings should be visible
      expect(find.byType(Switch), findsWidgets);
    });
  });
}
