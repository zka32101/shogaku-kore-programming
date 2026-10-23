import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/wrong_answers_provider.dart';
import 'package:shogaku_kore_programming/screens/quiz_result_screen.dart';
import 'package:shogaku_kore_programming/utils/parent_message.dart';

Stage _stage(String id, String title, {List<Question> questions = const []}) =>
    Stage(
      id: id,
      stageNumber: 1,
      title: title,
      description: '',
      type: 'quiz',
      level: '初級',
      icon: '🐍',
      isFree: true,
      questions: questions,
    );

Question _q(String text) => Question(
    id: text, text: text, options: const ['a', 'b'], correctIndex: 0, explanation: '');

QuizAnswer _wrong(String text) => QuizAnswer(
    questionText: text, isCorrect: false, selectedAnswer: 'b', correctAnswer: 'a');

void main() {
  final now = DateTime(2026, 10, 23, 12);

  group('buildParentMessage', () {
    test('クリアがあれば、ステージ数とタイトルを伝える', () {
      final m = buildParentMessage(const ParentWeekSummary(
        childName: 'たろう',
        clearedTitles: ['四角を描こう', '三角を描こう'],
        perfectCount: 1,
        streakDays: 3,
      ));
      expect(m.headline, 'たろうさんは、この7日間で2ステージをクリアしました！');
      expect(m.good, contains('「四角を描こう」「三角を描こう」をクリア'));
      expect(m.good, contains('3つ星でクリアしたステージが1つ'));
      expect(m.good, contains('3日つづけて取り組んでいます'));
      expect(m.concerns, isEmpty);
      expect(m.advice, contains('順調'));
    });

    test('4つ以上クリアしたときは「ほか」でまとめる', () {
      final m = buildParentMessage(const ParentWeekSummary(
        childName: '',
        clearedTitles: ['A', 'B', 'C', 'D', 'E'],
      ));
      expect(m.headline, startsWith('お子さんは'));
      expect(m.good.first, '「A」「B」「C」ほか2ステージをクリア');
    });

    test('つまずきがあれば、そのステージに触れた声かけになる', () {
      final m = buildParentMessage(const ParentWeekSummary(
        childName: 'はな',
        clearedTitles: ['A'],
        struggledTitles: ['ループ'],
        hintTitles: ['四角を描こう'],
      ));
      expect(m.concerns.length, 2);
      expect(m.concerns.first, contains('「ループ」'));
      expect(m.concerns.last, contains('ヒントを使いながら'));
      expect(m.advice, contains('「ループ」について'));
    });

    test('ヒントだけ使った場合も、ヒントのステージで声かけする', () {
      final m = buildParentMessage(const ParentWeekSummary(
        childName: 'はな',
        hintTitles: ['四角を描こう'],
      ));
      expect(m.advice, contains('「四角を描こう」について'));
    });

    test('お休みの週は、責めずに気軽な声かけを勧める', () {
      final m = buildParentMessage(
          const ParentWeekSummary(childName: 'はな'));
      expect(m.headline, 'はなさんは、この7日間はお休みでした。');
      expect(m.good, isEmpty);
      expect(m.advice, contains('1日5分でも大丈夫'));
    });

    test('コピー用のテキストに全項目が入る', () {
      final text = buildParentMessage(const ParentWeekSummary(
        childName: 'はな',
        clearedTitles: ['A'],
        struggledTitles: ['B'],
      )).toPlainText();
      expect(text, contains('【がんばったこと】'));
      expect(text, contains('【つまずいたところ】'));
      expect(text, contains('【声かけのヒント】'));
    });
  });

  group('buildParentWeekSummary', () {
    final stages = [
      _stage('s1', '四角を描こう'),
      _stage('s2', '変数', questions: [_q('xの値は？')]),
      _stage('s3', 'ループ', questions: [_q('何回表示される？'), _q('合計は？')]),
    ];

    ParentWeekSummary build({
      Map<String, UserProgress> progress = const {},
      WrongAnswersState wrong = const WrongAnswersState(),
      List<String> hints = const [],
    }) =>
        buildParentWeekSummary(
          childName: 'たろう',
          now: now,
          stages: stages,
          progress: progress,
          wrong: wrong,
          hintStageIds: hints,
          streakDays: 2,
        );

    test('直近7日間にクリアしたものだけを新しい順に数える', () {
      final s = build(progress: {
        's1': UserProgress(
            challengeId: 's1',
            isCompleted: true,
            starsEarned: 3,
            completedAt: DateTime(2026, 10, 22)),
        's2': UserProgress(
            challengeId: 's2',
            isCompleted: true,
            starsEarned: 2,
            completedAt: DateTime(2026, 10, 23)),
        's3': UserProgress(
            challengeId: 's3',
            isCompleted: true,
            starsEarned: 3,
            completedAt: DateTime(2026, 10, 1)), // 7日より前
      });
      expect(s.clearedTitles, ['変数', '四角を描こう']);
      expect(s.perfectCount, 1);
      expect(s.streakDays, 2);
    });

    test('未知のステージidや未クリアは数えない', () {
      final s = build(progress: {
        'unknown': UserProgress(
            challengeId: 'unknown', isCompleted: true, completedAt: now),
        's1': UserProgress(challengeId: 's1', completedAt: now),
      });
      expect(s.clearedTitles, isEmpty);
    });

    test('まちがいは期間内のものだけ、ステージごとに多い順で数える', () {
      final s = build(
        wrong: WrongAnswersState(
          answers: [_wrong('何回表示される？'), _wrong('合計は？'), _wrong('xの値は？'), _wrong('古い問題')],
          timestamps: {
            '何回表示される？': DateTime(2026, 10, 22),
            '合計は？': DateTime(2026, 10, 23),
            'xの値は？': DateTime(2026, 10, 21),
            '古い問題': DateTime(2026, 9, 1),
          },
        ),
      );
      expect(s.struggledTitles, ['ループ', '変数']);
    });

    test('ヒントを使ったステージのタイトルを引き継ぐ（未知idは除く）', () {
      final s = build(hints: ['s1', 'unknown', 's3']);
      expect(s.hintTitles, ['四角を描こう', 'ループ']);
    });
  });
}
