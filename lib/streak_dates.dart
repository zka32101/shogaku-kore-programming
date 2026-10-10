/// 連続学習カレンダー用の純関数（学習日の管理）。
const int kStudyDatesKeepDays = 180;

String studyDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseStudyDate(String s) {
  final p = s.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// 'yyyy-MM-dd' の文字列を重複なし・直近 [kStudyDatesKeepDays] 日に整えて返す（昇順）。
List<String> normalizeStudyDates(Iterable<String> raw, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  final oldest = DateTime(t.year, t.month, t.day - (kStudyDatesKeepDays - 1));
  final set = <String>{};
  for (final s in raw) {
    final d = parseStudyDate(s);
    if (d == null) continue;
    if (d.isBefore(oldest) || d.isAfter(t)) continue;
    set.add(studyDateKey(d));
  }
  return set.toList()..sort();
}

/// [today] を追加した学習日リスト。
List<String> addStudyDate(Iterable<String> raw, DateTime today) =>
    normalizeStudyDates([...raw, studyDateKey(today)], today);

/// 現在の連続日数 [streak] と最終学習日 [last] から、最終日までの [streak] 日分を作る（バックフィル）。
List<String> backfillStudyDates(int streak, DateTime last) {
  if (streak <= 0) return const [];
  final l = DateTime(last.year, last.month, last.day);
  return [
    for (var i = streak - 1; i >= 0; i--)
      studyDateKey(DateTime(l.year, l.month, l.day - i)),
  ];
}

Set<DateTime> studyDatesToSet(Iterable<String> raw) => {
      for (final s in raw)
        ?parseStudyDate(s),
    };

/// 各学習日が「連続何日目か」を返す。
Map<DateTime, int> streakRunLengths(Set<DateTime> days) {
  final norm = {for (final d in days) DateTime(d.year, d.month, d.day)};
  final sorted = norm.toList()..sort();
  final out = <DateTime, int>{};
  for (final d in sorted) {
    final prev = DateTime(d.year, d.month, d.day - 1);
    out[d] = (out[prev] ?? 0) + 1;
  }
  return out;
}

const Set<int> kStreakCoinDays = {7, 14, 30};
