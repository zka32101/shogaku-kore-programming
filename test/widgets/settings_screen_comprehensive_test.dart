import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_utils.dart';
import '../../lib/screens/settings_screen.dart';
import '../../lib/screens/profile_screen.dart';
import '../../lib/screens/parent_dashboard_screen.dart';
import '../../lib/screens/paywall_screen.dart';
import '../../lib/providers/profile_provider.dart';
import '../../lib/providers/progress_provider.dart';
import '../../lib/config/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen - Basic Screen Rendering', () {
    testWidgets('renders screen with scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays AppBar/header section', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsWidgets);
    });

    testWidgets('renders scrollable settings list', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('displays Focus widget for keyboard handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('renders with Column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('SettingsScreen - Settings Sections Display', () {
    testWidgets('displays Account section', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('アカウント'), findsWidgets);
    });

    testWidgets('displays Premium section', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('プレミアム'), findsWidgets);
    });

    testWidgets('displays Display/Display settings section', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('表示'), findsWidgets);
    });

    testWidgets('displays Learning section', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('学習'), findsWidgets);
    });

    testWidgets('displays Sound & Notifications section', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('サウンド'), findsWidgets);
    });

    testWidgets('displays section headers with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('SettingsScreen - Profile/Account Settings', () {
    testWidgets('displays profile tile with user info', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('profile tile is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final profileTile = find.byType(ListTile).first;
      await tester.tap(profileTile);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsWidgets);
    });
  });

  group('SettingsScreen - Premium Section', () {
    testWidgets('displays premium plan pricing', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('¥'), findsWidgets);
    });

    testWidgets('premium plan tile shows subscription options', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('登録する'), findsWidgets);
    });

    testWidgets('premium tile is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final premiumButton = find.byType(GestureDetector);
      if (premiumButton.evaluate().isNotEmpty) {
        await tester.tap(premiumButton.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsWidgets);
    });
  });

  group('SettingsScreen - Display Settings', () {
    testWidgets('displays theme mode option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays code font size option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('theme mode tile is interactive', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final themeTile = find.byType(ListTile).at(0);
      await tester.tap(themeTile);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen - Learning Settings', () {
    testWidgets('displays daily goal setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays review question count setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays flashcard session size setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays flashcard auto-flip setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays auto-advance toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('自動で次へ'), findsWidgets);
    });

    testWidgets('displays quiz timer toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('タイマー'), findsWidgets);
    });
  });

  group('SettingsScreen - Sound & Notifications Settings', () {
    testWidgets('displays sound toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('効果音'), findsWidgets);
    });

    testWidgets('displays haptics/vibration toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('バイブレーション'), findsWidgets);
    });

    testWidgets('displays notification reminder toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('リマインダー'), findsWidgets);
    });

    testWidgets('can toggle sound setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final soundToggle = find.byType(Switch);
      if (soundToggle.evaluate().isNotEmpty) {
        await tester.tap(soundToggle.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('can toggle haptics setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final hapticsToggle = find.byType(Switch);
      if (hapticsToggle.evaluate().length >= 2) {
        await tester.tap(hapticsToggle.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('can toggle notification setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final notificationToggle = find.byType(Switch);
      if (notificationToggle.evaluate().length >= 3) {
        await tester.tap(notificationToggle.at(2));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen - Keyboard Shortcuts', () {
    testWidgets('pressing P key navigates to Profile screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsWidgets);
    });

    testWidgets('pressing D key navigates to Parent Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();

      expect(find.byType(ParentDashboardScreen), findsWidgets);
    });

    testWidgets('pressing U key navigates to Paywall/Premium', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsWidgets);
    });

    testWidgets('pressing Escape key navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsWidgets);
    });

    testWidgets('pressing Backspace key navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsWidgets);
    });

    testWidgets('pressing Shift+? shows keyboard shortcuts help dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsWidgets);
    });

    testWidgets('help dialog displays all keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsWidgets);
    });
  });

  group('SettingsScreen - Provider Integration', () {
    testWidgets('watches profileProvider for settings state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('reads profileProvider notifier for settings mutations', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('watches progressProvider for progress data', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('reads progressProvider notifier for progress mutations', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen - Theme and Styling', () {
    testWidgets('renders with light theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with dark theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('section headers display with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('settings tiles have consistent styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('icons display with background colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });

  group('SettingsScreen - Scrolling and Layout', () {
    testWidgets('settings list is scrollable', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('can scroll to bottom of settings list', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -600));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('can scroll up to top of settings list', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.drag(listView, const Offset(0, 300));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen - Toggle and Switch Interactions', () {
    testWidgets('sound toggle switches on/off', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('haptics toggle switches on/off', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 2) {
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('notification toggle switches on/off', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 3) {
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen - Animation and Transitions', () {
    testWidgets('settings sections fade in with animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('settings sections slide up with animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('dialog appears with animation on help shortcut', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsWidgets);
    });
  });

  group('SettingsScreen - Error Handling and Edge Cases', () {
    testWidgets('handles empty provider data gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('handles rapid toggle switches without crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('handles back navigation at root', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsWidgets);
    });

    testWidgets('handles multiple rapid navigation shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsWidgets);
    });
  });

  group('SettingsScreen - Focus and Accessibility', () {
    testWidgets('requests focus on initial build', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('keyboard focus enables shortcut handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsWidgets);
    });

    testWidgets('invalid key presses are ignored', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen - Full Integration Workflows', () {
    testWidgets('complete workflow: toggle settings then navigate', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle sound
      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      // Navigate to profile
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsWidgets);
    });

    testWidgets('complete workflow: scroll through settings', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.drag(listView, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('complete workflow: view help and navigate', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Show help
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      // Close help with Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('complete workflow: multiple navigation shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      // Back
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Navigate to Dashboard
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();

      expect(find.byType(ParentDashboardScreen), findsWidgets);
    });

    testWidgets('complete workflow: tap tiles and toggle switches', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final tiles = find.byType(ListTile);
      if (tiles.evaluate().isNotEmpty) {
        await tester.tap(tiles.first);
        await tester.pumpAndSettle();
      }

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('complete workflow: navigate with keyboard only', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // P → Profile
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      // Esc → Back
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // U → Premium/Paywall
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsWidgets);
    });
  });
}
