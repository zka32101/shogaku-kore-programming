import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/widgets/badge_emblem.dart';

void main() {
  test('achievements_screen の全67バッジに意匠があり、画像ファイルが存在する', () {
    final src = File('lib/screens/achievements_screen.dart').readAsStringSync();
    final literals = RegExp(r'\n\s+Badge\(\r?\n\s+icon:').allMatches(src).length;
    final designs = RegExp(r"\n\s+design: '(\w+)',")
        .allMatches(src)
        .map((m) => m.group(1)!)
        .toList();
    expect(literals, 67);
    expect(designs.length, literals);
    for (final d in designs.toSet()) {
      expect(File('assets/badges/badge_$d.webp').existsSync(), true, reason: d);
    }
  });

  testWidgets('意匠ありは画像、なしは絵文字で出る', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          BadgeEmblem(design: 'streak', fallbackEmoji: '🔥'),
          BadgeEmblem(design: null, fallbackEmoji: '🔥'),
          BadgeEmblem(design: 'no_such_design', fallbackEmoji: '🔥'),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
