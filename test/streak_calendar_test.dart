import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/reward_assets.dart';
import 'package:shogaku_kore_programming/streak_dates.dart';
import 'package:shogaku_kore_programming/widgets/streak_calendar.dart';
import 'dart:io';

void main() {
  test('addStudyDate dedups and prunes to 180 days', () {
    final today = DateTime(2026, 10, 10);
    var l = addStudyDate(['2026-10-09', '2026-10-10', '2026-01-01', 'bad'], today);
    expect(l, ['2026-10-09', '2026-10-10']);
    l = addStudyDate(l, today);
    expect(l.length, 2);
    final edge = studyDateKey(DateTime(2026, 10, 10 - 179));
    final over = studyDateKey(DateTime(2026, 10, 10 - 180));
    expect(normalizeStudyDates([edge, over], today), [edge]);
  });

  test('backfill and run lengths', () {
    expect(backfillStudyDates(0, DateTime(2026, 10, 10)), isEmpty);
    expect(backfillStudyDates(3, DateTime(2026, 10, 10)),
        ['2026-10-08', '2026-10-09', '2026-10-10']);
    final runs = streakRunLengths(studyDatesToSet(
        backfillStudyDates(8, DateTime(2026, 10, 10))..add('2026-09-01')));
    expect(runs[DateTime(2026, 10, 10)], 8);
    expect(runs[DateTime(2026, 9, 1)], 1);
  });

  test('bonusStickerAssets boundaries', () {
    expect(bonusStickerAssets(firstAttempt: false, personalBest: false, firstPerfect: false), isEmpty);
    expect(bonusStickerAssets(firstAttempt: true, personalBest: false, firstPerfect: false).single,
        contains('rocket'));
    expect(bonusStickerAssets(firstAttempt: false, personalBest: true, firstPerfect: false).single,
        contains('trophy_blue'));
    expect(bonusStickerAssets(firstAttempt: false, personalBest: false, firstPerfect: true).single,
        contains('rainbow_star'));
    final all = bonusStickerAssets(firstAttempt: true, personalBest: true, firstPerfect: true);
    expect(all.length, 2);
    expect(all.first, contains('rocket'));
  });

  test('assets exist', () {
    for (final f in [
      'calendar_frame', 'stamp_ring_rainbow', 'stamp_coin',
      'sticker_rocket', 'sticker_trophy_blue', 'sticker_rainbow_star',
    ]) {
      expect(File('assets/reward/$f.webp').existsSync(), isTrue, reason: f);
    }
  });

  testWidgets('StreakCalendar has no overflow at 320px', (tester) async {
    final days = studyDatesToSet(backfillStudyDates(31, DateTime(2026, 10, 31)));
    for (final m in [DateTime(2026, 10, 1), DateTime(2026, 2, 1)]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: StreakCalendar(studiedDays: days, month: m),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('15'), findsOneWidget);
    }
  });

  testWidgets('showStreakCalendar dialog opens', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
            onPressed: () => showStreakCalendar(c, {DateTime.now()}),
            child: const Text('open')),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.byType(StreakCalendar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
