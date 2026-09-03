import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper widget that provides necessary dependencies for screen tests
class TestApp extends StatelessWidget {
  final Widget home;
  final List<Override> overrides;

  const TestApp({
    required this.home,
    this.overrides = const [],
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: home,
        localizationsDelegates: const [],
      ),
    );
  }
}

/// Test fixture for screens that need Riverpod providers
void setupTestEnvironment({
  Map<String, dynamic> sharedPrefsValues = const {},
}) {
  SharedPreferences.setMockInitialValues(sharedPrefsValues);
}

/// Helper to pump a widget with all required dependencies
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    TestApp(
      home: widget,
      overrides: overrides,
    ),
  );
}

/// Helper to pump and settle (wait for animations)
Future<void> pumpAndSettle(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 500),
}) async {
  await tester.pumpAndSettle(duration);
}

/// Common text finder helpers
Finder findText(String text) => find.text(text);
Finder findByType<T extends Widget>() => find.byType(T);
Finder findByKey(String key) => find.byKey(ValueKey(key));

/// Helper to tap a button or widget
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Helper to enter text in a text field
Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Helper to verify widget exists
void expectExists<T extends Widget>() {
  expect(find.byType(T), findsOneWidget);
}

/// Helper to verify widget doesn't exist
void expectNotExists<T extends Widget>() {
  expect(find.byType(T), findsNothing);
}

/// Helper to verify text exists
void expectText(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Helper to verify text doesn't exist
void expectNoText(String text) {
  expect(find.text(text), findsNothing);
}
