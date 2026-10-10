import 'package:flutter/material.dart';

import '../streak_dates.dart';

const _frame = 'assets/reward/calendar_frame.webp';
const _ring = 'assets/reward/stamp_ring_rainbow.webp';
const _coin = 'assets/reward/stamp_coin.webp';

/// 連続学習カレンダー（1か月分）。学習した日にスタンプ、連続7/14/30日目にコイン。
class StreakCalendar extends StatelessWidget {
  final Set<DateTime> studiedDays;
  final DateTime month;

  const StreakCalendar({super.key, required this.studiedDays, required this.month});

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7; // 日曜始まり
    final rows = ((lead + daysInMonth) / 7).ceil();
    final runs = streakRunLengths(studiedDays);
    const wd = ['日', '月', '火', '水', '木', '金', '土'];

    return AspectRatio(
      aspectRatio: 140 / 188,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final l = w * 0.10, r = w * 0.10, t = h * 0.16, b = h * 0.09;
        final iw = w - l - r, ih = h - t - b;
        final cellW = iw / 7;
        final headH = ih * 0.12;
        final cellH = (ih - headH * 2) / rows;
        final fs = (cellW * 0.38).clamp(6.0, 16.0);
        return Stack(children: [
          Positioned(
            left: l, top: t, right: r, bottom: b,
            child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFFFFBF2))),
          ),
          Positioned.fill(
            child: Image.asset(_frame, fit: BoxFit.fill,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
          Positioned(
            left: l, top: t, width: iw, height: ih,
            child: Column(children: [
              SizedBox(
                height: headH,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${month.year}年${month.month}月',
                        style: TextStyle(
                            fontSize: fs * 1.2,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4037))),
                  ),
                ),
              ),
              SizedBox(
                height: headH,
                child: Row(children: [
                  for (final s in wd)
                    SizedBox(
                      width: cellW,
                      child: Center(
                        child: Text(s,
                            style: TextStyle(
                                fontSize: fs * 0.8,
                                color: s == '日'
                                    ? Colors.red.shade400
                                    : s == '土'
                                        ? Colors.blue.shade400
                                        : Colors.brown.shade400)),
                      ),
                    ),
                ]),
              ),
              for (var row = 0; row < rows; row++)
                SizedBox(
                  height: cellH,
                  child: Row(children: [
                    for (var col = 0; col < 7; col++)
                      SizedBox(
                        width: cellW,
                        child: _cell(row * 7 + col - lead + 1, daysInMonth, runs, fs, cellW, cellH),
                      ),
                  ]),
                ),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _cell(int day, int daysInMonth, Map<DateTime, int> runs, double fs,
      double cw, double ch) {
    if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
    final d = DateTime(month.year, month.month, day);
    final run = runs[d];
    final studied = run != null;
    final isCoin = studied && kStreakCoinDays.contains(run);
    final size = (cw < ch ? cw : ch) * 0.95;
    return Center(
      child: SizedBox(
        width: size, height: size,
        child: Stack(alignment: Alignment.center, children: [
          if (studied)
            Image.asset(isCoin ? _coin : _ring,
                width: size, height: size, fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          Text('$day',
              style: TextStyle(
                  fontSize: fs,
                  fontWeight: studied ? FontWeight.bold : FontWeight.normal,
                  color: studied ? const Color(0xFF3E2723) : Colors.brown.shade300)),
        ]),
      ),
    );
  }
}

/// 連続学習カレンダーのダイアログを表示する。
Future<void> showStreakCalendar(BuildContext context, Set<DateTime> days) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StreakCalendarDialog(days: days),
  );
}

class _StreakCalendarDialog extends StatefulWidget {
  final Set<DateTime> days;
  const _StreakCalendarDialog({required this.days});

  @override
  State<_StreakCalendarDialog> createState() => _StreakCalendarDialogState();
}

class _StreakCalendarDialogState extends State<_StreakCalendarDialog> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month, 1);
  }

  void _move(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta, 1));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              IconButton(
                  tooltip: '前の月',
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.chevron_left)),
              const Expanded(
                child: Text('れんぞく がくしゅう カレンダー',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                  tooltip: '次の月',
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.chevron_right)),
            ]),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: StreakCalendar(studiedDays: widget.days, month: _month),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('とじる')),
            ),
          ]),
        ),
      ),
    );
  }
}
