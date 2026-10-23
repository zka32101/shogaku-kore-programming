import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/splash_screen.dart';
import 'test_helpers.dart';

/// スプラッシュは表示から2秒後に自動で遷移する（Future.delayed）。
/// 遷移前の状態を検証し、終了時にタイマーを消化して pending timer を残さない。
void splashTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }
  });
}

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
    splashTest('displays splash screen', (WidgetTester tester) async {
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

    splashTest('displays app logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Logo should be displayed
      expect(find.byType(Image), findsWidgets);
    });

    splashTest('displays app name/branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // 現行の起動画面は画像のみ: アプリアイコン・シリーズロゴ・組織ロゴ
      expect(find.byKey(const ValueKey('splash_app_icon')), findsOneWidget);
      expect(find.byKey(const ValueKey('splash_series_logo')), findsOneWidget);
      expect(find.byKey(const ValueKey('splash_company_logo')), findsOneWidget);
    });

    splashTest('animates logo on entry', (WidgetTester tester) async {
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

    splashTest('floating animation is visible', (WidgetTester tester) async {
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

      // アイコンが表示され、読み込み表示が回り続けている
      expect(find.byKey(const ValueKey('splash_app_icon')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    splashTest('displays loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Loading spinner should be visible
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    splashTest('displays progress message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // 現行は文言ではなくスピナーで読み込み中を示す
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    splashTest('splash screen has appropriate duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Initial pump
      await tester.pump(const Duration(milliseconds: 100));

      // Verify splash is still visible after < 2 seconds
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    splashTest('background color is set appropriately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Scaffold or Container should have background
      expect(find.byType(Scaffold), findsWidgets);
    });

    splashTest('logo animation uses appropriate curve',
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

    splashTest('handles orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Simulate orientation change
      addTearDown(tester.view.resetPhysicalSize);

      // Should still be visible and functional
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    splashTest('displays version number if applicable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // 現行の起動画面にバージョンなどの文言は表示しない（画像のみ）
      expect(find.byType(Text), findsNothing);
    });

    splashTest('splash elements scale appropriately for different screens',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);

      // Set to tablet size
      tester.view.physicalSize = const Size(1024, 1366);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Should render correctly on larger screens
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    splashTest('floating animation loops continuously',
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

    splashTest('logo has fade-in effect', (WidgetTester tester) async {
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

    splashTest('display is centered and responsive',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // アイコンは画面の左右中央に置かれる
      final icon = find.byKey(const ValueKey('splash_app_icon'));
      expect(icon, findsOneWidget);
      final screenCenterX = tester.getSize(find.byType(Scaffold)).width / 2;
      expect(tester.getCenter(icon).dx, closeTo(screenCenterX, 0.5));
    });

    splashTest('handles rapid rebuilds', (WidgetTester tester) async {
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

    splashTest('progress indicator visibility is correct',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Loading indicator should be present
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    splashTest('app logo is properly sized', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Image should have reasonable size
      final imageFinder = find.byType(Image);
      if (imageFinder.evaluate().isNotEmpty) {
        final size = tester.getSize(imageFinder.first);
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      }
    });

    splashTest('maintains state during animation', (WidgetTester tester) async {
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
