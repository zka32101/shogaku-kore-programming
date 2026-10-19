import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/providers/subscription_provider.dart';
import 'package:shogaku_kore_programming/screens/paywall_screen.dart';

/// 購入処理(プラン取得)が始まった回数だけを数える偽物。
/// ゲートを通る前は、プランの取得を含む購入処理に進まないことを確認する。
class _FakeSubscription extends SubscriptionNotifier {
  int refreshCalls = 0;

  @override
  Future<void> refreshSubscriptionStatus() async {
    refreshCalls++;
  }
}

/// 保護者ゲート(足し算・引き算)の答えを画面から読み取る。
int _answer(WidgetTester tester) {
  final q = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((d) => RegExp(r'^\d+ [+-] \d+ = \?$').hasMatch(d));
  final m = RegExp(r'(\d+) ([+-]) (\d+)').firstMatch(q)!;
  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(3)!);
  return m.group(2) == '+' ? a + b : a - b;
}

void main() {
  late _FakeSubscription fake;

  setUp(() {
    fake = _FakeSubscription();
  });

  Future<void> pump(WidgetTester tester) async {
    // 購入ボタンが画面内に入る縦長の画面にする。
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 3200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [subscriptionProvider.overrideWith((ref) => fake)],
      child: const MaterialApp(home: PaywallScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('購入ボタンを押すと保護者ゲートが出て、「やめる」では購入処理に進まない', (tester) async {
    await pump(tester);
    final before = fake.refreshCalls; // 画面を開いたときのプラン取得

    await tester.tap(find.text('プレミアムに登録する'));
    await tester.pumpAndSettle();
    expect(find.text('保護者の方へ確認'), findsOneWidget);
    expect(fake.refreshCalls, before);

    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(fake.refreshCalls, before, reason: 'やめたのに購入処理が始まっている');
    expect(find.text('保護者の方へ確認'), findsNothing);
  });

  testWidgets('間違えると購入処理に進まない', (tester) async {
    await pump(tester);
    final before = fake.refreshCalls;

    await tester.tap(find.text('プレミアムに登録する'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '${_answer(tester) + 1}');
    await tester.tap(find.text('つぎへ'));
    await tester.pumpAndSettle();
    expect(find.text('答えが違います'), findsOneWidget);
    expect(fake.refreshCalls, before);
  });

  testWidgets('ゲートに正解すると、購入処理(プラン取得)に進む', (tester) async {
    await pump(tester);
    final before = fake.refreshCalls;

    await tester.tap(find.text('プレミアムに登録する'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '${_answer(tester)}');
    await tester.tap(find.text('つぎへ'));
    await tester.pumpAndSettle();
    expect(find.text('保護者の方へ確認'), findsNothing);
    expect(fake.refreshCalls, greaterThan(before), reason: 'ゲートを通っても購入処理が始まらない');
  });
}
