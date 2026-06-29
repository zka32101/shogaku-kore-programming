import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShogakuKoreProgrammingApp()),
    );
    expect(find.byType(ShogakuKoreProgrammingApp), findsOneWidget);
  });
}
