import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/widgets/branded_splash.dart';

void main() {
  testWidgets('起動画面: 白背景・アイコン/シリーズロゴ/組織ロゴの3つが縦に並ぶ', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BrandedSplash()));
    await tester.pump();
    final icon = find.byKey(const ValueKey('splash_app_icon'));
    final series = find.byKey(const ValueKey('splash_series_logo'));
    final company = find.byKey(const ValueKey('splash_company_logo'));
    expect(icon, findsOneWidget);
    expect(series, findsOneWidget);
    expect(company, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        const Color(0xFFFFFFFF));
    expect(tester.getCenter(series).dy, greaterThan(tester.getCenter(icon).dy));
    expect(tester.getCenter(company).dy,
        greaterThan(tester.getCenter(series).dy));
    expect(tester.getSize(company).width,
        lessThan(tester.getSize(series).width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('起動画面: 小画面(360x600)でも溢れず、ロゴが大きい', (tester) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: BrandedSplash()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const ValueKey('splash_app_icon'))).width, 168);
    expect(tester.getSize(find.byKey(const ValueKey('splash_series_logo'))).width, 260);
    expect(tester.getSize(find.byKey(const ValueKey('splash_company_logo'))).height, 84);
  });
}
