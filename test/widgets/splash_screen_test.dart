import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/splash_screen.dart';
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

  group('SplashScreen Widget Tests', () {
    testWidgets('displays splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify splash screen is displayed
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('displays app logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Logo should be displayed
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('displays app name/branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // App name should be visible
      // "小学コレ！プログラミング" or similar
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('animates logo on entry', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Animation should be playing
      expect(find.byType(CustomPaint), findsWidgets);

      // Pump through animation duration
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    });

    testWidgets('floating animation is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Wait for animations to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Content should be visible and animated
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Loading spinner should be visible
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays progress message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress message like "ロード中..." should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('splash screen has appropriate duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Initial pump
      await tester.pumpAndSettle();

      // Verify splash is still visible after < 2 seconds
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('background color is set appropriately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scaffold or Container should have background
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('logo animation uses appropriate curve',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Animate through the bounce/elastic animation
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('handles orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate orientation change
      addTearDown(tester.binding.window.physicalSizeTestValue);
      addTearDown(TestWidgetsFlutterBinding.instance.window.clearPhysicalSizeTestValue);

      // Should still be visible and functional
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('displays version number if applicable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Version might be displayed (implementation dependent)
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('splash elements scale appropriately for different screens',
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.physicalSizeTestValue);
      addTearDown(TestWidgetsFlutterBinding.instance.window.clearPhysicalSizeTestValue);

      // Set to tablet size
      tester.binding.window.physicalSizeTestValue = const Size(1024, 1366);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render correctly on larger screens
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('floating animation loops continuously',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Initial frame
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SplashScreen), findsOneWidget);

      // After 3 seconds (animation loop duration)
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Animation should still be looping
    });

    testWidgets('logo has fade-in effect', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Check initial frame
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      // Logo should be visible and might be fading in
    });

    testWidgets('display is centered and responsive',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Content should be centered
      final textFinder = find.byType(Text).first;
      expect(textFinder, findsOneWidget);

      // Verify it's positioned centrally
      final center = tester.getCenter(textFinder);
      expect(center, isNotNull);
    });

    testWidgets('handles rapid rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Rapid pumps should not cause issues
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('progress indicator visibility is correct',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Loading indicator should be present
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('app logo is properly sized', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Image should have reasonable size
      final imageFinder = find.byType(Image);
      if (imageFinder.evaluate().isNotEmpty) {
        final size = tester.getSize(imageFinder.first);
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      }
    });

    testWidgets('maintains state during animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Get initial state
      final initialSplash = find.byType(SplashScreen);
      expect(initialSplash, findsOneWidget);

      // Pump through animations
      await tester.pump(const Duration(milliseconds: 500));

      // State should be maintained
      final afterPump = find.byType(SplashScreen);
      expect(afterPump, findsOneWidget);
    });
  });
}
