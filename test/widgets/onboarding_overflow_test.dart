import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/screens/onboarding_screen.dart';

void main() {
  for (final w in [320.0, 360.0, 411.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('onboarding pages do not overflow w=$w scale=$scale',
          (tester) async {
        tester.view.physicalSize = Size(w, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                  textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const OnboardingScreen(),
          ),
        ));
        await tester.pump(const Duration(seconds: 1));
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.text('次へ'));
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }
}
