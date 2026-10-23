import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/achievements_screen.dart';
import '../widgets/test_helpers.dart';
void main() {
  testWidgets('p', (t) async {
    useReducedMotion();
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const ProviderScope(child: MaterialApp(home: AchievementsScreen())));
    await t.pumpAndSettle();
    String types(Finder f) => f.evaluate().length.toString();
    print('TEXTS: ${t.widgetList<Text>(find.byType(Text)).map((e) => e.data).whereType<String>().take(60).toList()}');
    print('ICONS: ${t.widgetList<Icon>(find.byType(Icon)).map((e) => e.icon).toSet().toList()}');
    print('COUNTS: appbar=${types(find.byType(AppBar))} listview=${types(find.byType(ListView))} scrollable=${types(find.byType(Scrollable))} tab=${types(find.byType(Tab))} tabbar=${types(find.byType(TabBar))} sliver=${types(find.byType(CustomScrollView))} scroll=${types(find.byType(SingleChildScrollView))} card=${types(find.byType(Card))}');
  });
}
