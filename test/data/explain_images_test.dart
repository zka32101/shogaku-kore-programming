import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/data/explain_images.dart';

void main() {
  test('explain image assets exist', () {
    for (final id in kExplainStageIds) {
      expect(File(explainImageForStage(id)!).existsSync(), isTrue, reason: id);
    }
    for (final id in kExplainLessonIds) {
      expect(File(explainImageForLesson(id)!).existsSync(), isTrue, reason: id);
    }
  });

  test('lookup', () {
    expect(explainImageForStage('stage_02'),
        'assets/illustrations/explain_stage_02.webp');
    expect(explainImageForStage('stage_01'), isNull);
    expect(explainImageForLesson('lesson_bug'),
        'assets/illustrations/explain_lesson_bug.webp');
    expect(explainImageForLesson('nope'), isNull);
    expect(kExplainStageIds.length, 23);
    expect(kExplainLessonIds.length, 7);
  });
}
