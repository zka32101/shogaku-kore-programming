import '../models/stage.dart';
import '../providers/progress_provider.dart';
import '../providers/wrong_answers_provider.dart';

/// 保護者向けメッセージの材料（直近の数日間の学習のまとめ）。
class ParentWeekSummary {
  final String childName;
  final int days;
  final List<String> clearedTitles; // 新しい順
  final int perfectCount;
  final int streakDays;
  final List<String> struggledTitles; // まちがいが多い順
  final List<String> hintTitles; // ヒントを使った回数が多い順

  const ParentWeekSummary({
    required this.childName,
    this.days = 7,
    this.clearedTitles = const [],
    this.perfectCount = 0,
    this.streakDays = 0,
    this.struggledTitles = const [],
    this.hintTitles = const [],
  });
}

/// 保護者に見せる文章。通信は使わず、端末内のデータだけで作る。
class ParentMessage {
  final String headline;
  final List<String> good;
  final List<String> concerns;
  final String advice;

  const ParentMessage({
    required this.headline,
    required this.good,
    required this.concerns,
    required this.advice,
  });

  /// コピーして家族に送れる形のテキスト。
  String toPlainText() {
    final b = StringBuffer(headline);
    if (good.isNotEmpty) {
      b.write('\n\n【がんばったこと】');
      for (final g in good) {
        b.write('\n・$g');
      }
    }
    if (concerns.isNotEmpty) {
      b.write('\n\n【つまずいたところ】');
      for (final c in concerns) {
        b.write('\n・$c');
      }
    }
    b.write('\n\n【声かけのヒント】\n$advice');
    return b.toString();
  }
}

String _quoteList(List<String> titles, {int max = 3}) {
  final shown = titles.take(max).map((t) => '「$t」').join('');
  final rest = titles.length - max;
  return rest > 0 ? '$shownほか$restステージ' : shown;
}

/// まとめから、保護者向けのメッセージを作る。
ParentMessage buildParentMessage(ParentWeekSummary s) {
  final name = s.childName.isEmpty ? 'お子さん' : '${s.childName}さん';
  final cleared = s.clearedTitles.length;

  final headline = cleared > 0
      ? '$nameは、この${s.days}日間で$clearedステージをクリアしました！'
      : '$nameは、この${s.days}日間はお休みでした。';

  final good = <String>[
    if (cleared > 0) '${_quoteList(s.clearedTitles)}をクリア',
    if (s.perfectCount > 0) '3つ星でクリアしたステージが${s.perfectCount}つ',
    if (s.streakDays >= 2) '${s.streakDays}日つづけて取り組んでいます',
  ];

  final concerns = <String>[
    if (s.struggledTitles.isNotEmpty)
      '${_quoteList(s.struggledTitles, max: 2)}の問題で、まちがいが多めでした',
    if (s.hintTitles.isNotEmpty)
      '${_quoteList(s.hintTitles, max: 2)}では、ヒントを使いながら進めました',
  ];

  final String advice;
  if (concerns.isNotEmpty) {
    final focus = s.struggledTitles.isNotEmpty
        ? s.struggledTitles.first
        : s.hintTitles.first;
    advice = '「$focus」について「どこがむずかしかった？」と聞いてみてください。'
        'うまく説明できなくても、考えたことをほめてあげましょう。'
        'ヒントを使うのは悪いことではなく、自分で進める力になります。';
  } else if (cleared > 0) {
    advice = '順調です。「どんなものを作ったの？」と聞いて、お話を聞いてあげてください。';
  } else {
    advice = '1日5分でも大丈夫です。「今日はどのステージをやってみる？」と、'
        '気軽に声をかけてみてください。';
  }

  return ParentMessage(
    headline: headline,
    good: good,
    concerns: concerns,
    advice: advice,
  );
}

/// アプリ内のデータから、直近 [days] 日間のまとめを作る。
ParentWeekSummary buildParentWeekSummary({
  required String childName,
  required DateTime now,
  required List<Stage> stages,
  required Map<String, UserProgress> progress,
  required WrongAnswersState wrong,
  required List<String> hintStageIds,
  required int streakDays,
  int days = 7,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: days - 1));
  final titleById = {for (final s in stages) s.id: s.title};

  // 期間内にクリアしたステージ（新しい順）
  final clearedEntries = progress.values
      .where((p) =>
          p.isCompleted &&
          p.completedAt != null &&
          !p.completedAt!.isBefore(start) &&
          titleById.containsKey(p.challengeId))
      .toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

  // 期間内にまちがえた問題を、ステージごとに数える
  final stageByQuestion = <String, String>{};
  for (final s in stages) {
    for (final q in s.questions ?? const <Question>[]) {
      stageByQuestion[q.text] = s.title;
    }
  }
  final struggle = <String, int>{};
  for (final a in wrong.answers) {
    final at = wrong.timestamps[a.questionText];
    if (at == null || at.isBefore(start)) continue;
    final title = stageByQuestion[a.questionText];
    if (title == null) continue;
    struggle[title] = (struggle[title] ?? 0) + 1;
  }
  final struggled = struggle.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return ParentWeekSummary(
    childName: childName,
    days: days,
    clearedTitles: [for (final p in clearedEntries) titleById[p.challengeId]!],
    perfectCount: clearedEntries.where((p) => p.starsEarned >= 3).length,
    streakDays: streakDays,
    struggledTitles: [for (final e in struggled) e.key],
    hintTitles: [
      for (final id in hintStageIds)
        if (titleById[id] != null) titleById[id]!,
    ],
  );
}
