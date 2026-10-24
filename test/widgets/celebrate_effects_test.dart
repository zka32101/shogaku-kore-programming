import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/screens/badge_unlock_screen.dart';
import 'package:shogaku_kore_programming/screens/quiz_result_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('BadgeUnlockScreen shows starburst and ribbon without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: BadgeUnlockScreen(
        badgeIcon: '🏅',
        badgeName: 'テスト',
        message: 'すごい！',
        pointsEarned: 100,
        nextGoal: 'つぎへ',
        onContinue: () {},
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('badgeStarburst')), findsOneWidget);
    expect(find.byKey(const Key('badgeRibbon')), findsOneWidget);
    expect(find.text('おめでとう！'), findsOneWidget);
    final w = tester.getSize(find.byKey(const Key('badgeStarburst'))).width;
    expect(w, closeTo(360 * 0.8, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('QuizResultScreen level-up banner shows trophy and arrow',
      (tester) async {
    final stage = Stage(
      id: 't',
      stageNumber: 1,
      title: 'T',
      description: 'd',
      level: '初級',
      icon: 'icon_1',
      isFree: true,
      questions: const [],
      type: 'quiz',
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: QuizResultScreen(
          challenge: stage,
          answers: const [],
          correctCount: 1,
          totalCount: 2,
          stars: 1,
          isFirstComplete: false,
          didLevelUp: true,
          newLevel: 5,
        ),
      ),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const Key('levelUpTrophy')), findsOneWidget);
    expect(find.byKey(const Key('levelUpArrow')), findsOneWidget);
    expect(find.text('レベルアップ！ Lv.5 になった！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
