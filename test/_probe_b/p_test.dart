import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/flashcard_screen.dart';
import 'package:shogaku_kore_programming/screens/daily_review_screen.dart';
import '../widgets/test_helpers.dart';
void dump(WidgetTester t,String tag){
  print('$tag TEXTS: ${t.widgetList<Text>(find.byType(Text)).map((e) => e.data ?? e.textSpan?.toPlainText()).toList()}');
  print('$tag ICONS: ${t.widgetList<Icon>(find.byType(Icon)).map((e) => e.icon?.codePoint.toRadixString(16)).toList()}');
  print('$tag TYPES: appbar=${find.byType(AppBar).evaluate().length} card=${find.byType(Card).evaluate().length} elev=${find.byType(ElevatedButton).evaluate().length} text=${find.byType(TextButton).evaluate().length} outl=${find.byType(OutlinedButton).evaluate().length} inkwell=${find.byType(InkWell).evaluate().length} gest=${find.byType(GestureDetector).evaluate().length} iconbtn=${find.byType(IconButton).evaluate().length} popup=${find.byType(PopupMenuButton).evaluate().length} lpi=${find.byType(LinearProgressIndicator).evaluate().length} cpi=${find.byType(CircularProgressIndicator).evaluate().length} scaffold=${find.byType(Scaffold).evaluate().length}');
}
void main() {
  testWidgets('flash', (t) async {
    useReducedMotion();
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const ProviderScope(child: MaterialApp(home: FlashcardScreen())));
    await t.pumpAndSettle();
    dump(t,'FRONT');
    await t.tap(find.text('カードをめくる'));
    await t.pumpAndSettle();
    dump(t,'BACK');
  });
  testWidgets('daily', (t) async {
    useReducedMotion();
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const ProviderScope(child: MaterialApp(home: DailyReviewScreen())));
    dump(t,'DR0');
    await t.pumpAndSettle();
    dump(t,'DR1');
  });
}
