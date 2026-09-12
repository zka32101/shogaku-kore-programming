import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper widget that provides necessary dependencies for screen tests
class TestApp extends StatelessWidget {
  final Widget home;
  final List<Override> overrides;
  final Brightness? brightness;

  const TestApp({
    required this.home,
    this.overrides = const [],
    this.brightness,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: home,
        localizationsDelegates: const [],
        theme: brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light(),
      ),
    );
  }
}

/// Helper to create a test app with all required dependencies
Widget createTestApp(
  Widget home, {
  List<Override> overrides = const [],
  Brightness? brightness,
}) {
  return TestApp(
    home: home,
    overrides: overrides,
    brightness: brightness,
  );
}
