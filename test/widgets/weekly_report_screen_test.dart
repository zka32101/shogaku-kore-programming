import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/screens/weekly_report_screen.dart';
import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useReducedMotion();
  });

  Future<void> open(WidgetTester tester, ProviderContainer container) async {
    tester.view.physicalSize = const Size(411, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: WeeklyReportScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('データがない週は、お休みの声かけを表示する', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await open(tester, container);

    expect(find.byKey(const Key('parentMessageCard')), findsOneWidget);
    expect(find.textContaining('この7日間はお休みでした'), findsOneWidget);
    expect(find.textContaining('1日5分でも大丈夫'), findsOneWidget);
  });

  testWidgets('クリアしたステージとヒントの使用が反映される', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(progressProvider.notifier);
    await n.completeChallenge('stage_01', 3);
    await n.recordHintUse('stage_03');
    await open(tester, container);

    expect(find.textContaining('1ステージをクリアしました'), findsOneWidget);
    expect(find.textContaining('「直線を描こう」をクリア'), findsOneWidget);
    expect(find.textContaining('「四角を描こう」では、ヒントを使いながら'), findsOneWidget);
  });

  testWidgets('コピーするとクリップボードに全文が入る', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await open(tester, container);

    await tester.tap(find.byKey(const Key('copyParentMessage')));
    await tester.pumpAndSettle();

    expect(copied, contains('この7日間はお休みでした'));
    expect(copied, contains('【声かけのヒント】'));
    expect(find.text('メッセージをコピーしました'), findsOneWidget);
  });
}
