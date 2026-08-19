import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShogakuKoreProgrammingApp()),
    );
    expect(find.byType(ShogakuKoreProgrammingApp), findsOneWidget);

    // SplashScreen が起動する Future.delayed(2000ms) の遅延ナビゲーション
    // タイマーと、その後の画面遷移トランジション(500ms)を消化してから
    // テストを終える。消化しないまま終了すると、Flutter のテストバインディングが
    // 「ウィジェットツリー破棄後もタイマーが残っている」として失敗させる。
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 600));
  });
}
