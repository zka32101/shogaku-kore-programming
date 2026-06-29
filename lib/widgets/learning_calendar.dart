import 'package:flutter/material.dart';
import '../config/theme.dart';

/// GitHub contributions graph 風の学習カレンダー
/// 過去 N 週間分を横スクロールで表示する
class LearningCalendarWidget extends StatefulWidget {
  final Map<DateTime, int> activityByDate;
  final int weeksToShow;

  const LearningCalendarWidget({
    super.key,
    required this.activityByDate,
    this.weeksToShow = 16,
  });

  @override
  State<LearningCalendarWidget> createState() => _LearningCalendarWidgetState();
}

class _LearningCalendarWidgetState extends State<LearningCalendarWidget> {
  late final ScrollController _scrollController;

  static const _weekLabels = ['日', '月', '火', '水', '木', '金', '土'];
  static const _cellSize = 14.0;
  static const _cellGap = 3.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 初期表示を最新（右端）にスクロール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _cellColor(int count, BuildContext context) {
    if (count == 0) return context.subCardBg;
    if (count == 1) return kPrimaryColor.withValues(alpha: 0.35);
    if (count == 2) return kPrimaryColor.withValues(alpha: 0.60);
    return kPrimaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());

    // 表示開始日（weeksToShow 週前の日曜日）
    final startOfThisWeek =
        today.subtract(Duration(days: today.weekday % 7));
    final startDate =
        startOfThisWeek.subtract(Duration(days: (widget.weeksToShow - 1) * 7));

    // 週ラベル (月の最初の週のみ表示)
    final monthLabels = <int, String>{}; // column index → month label
    for (int col = 0; col < widget.weeksToShow; col++) {
      final sunday = startDate.add(Duration(days: col * 7));
      if (sunday.day <= 7 || col == 0) {
        monthLabels[col] = '${sunday.month}月';
      }
    }

    final gridWidth = widget.weeksToShow * (_cellSize + _cellGap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左固定: 曜日ラベル列 (上部に月ラベル分の空白)
            Column(
              children: [
                const SizedBox(height: 16 + 4), // 月ラベル行 + gap
                ...List.generate(7, (dow) {
                  final show = dow == 1 || dow == 3 || dow == 5; // 月水金
                  return SizedBox(
                    width: 18,
                    height: _cellSize + _cellGap,
                    child: show
                        ? Text(
                            _weekLabels[dow],
                            style: const TextStyle(
                              fontSize: 8,
                              color: kTextSecondary,
                            ),
                          )
                        : null,
                  );
                }),
              ],
            ),
            const SizedBox(width: 4),
            // スクロール可能領域: 月ラベル + グリッド列 (単一 ScrollController で同期)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: gridWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 月ラベル行
                      SizedBox(
                        height: 16,
                        child: Row(
                          children: List.generate(widget.weeksToShow, (col) {
                            return SizedBox(
                              width: _cellSize + _cellGap,
                              child: monthLabels.containsKey(col)
                                  ? Text(
                                      monthLabels[col]!,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: kTextSecondary,
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // グリッド列
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(widget.weeksToShow, (col) {
                          return Column(
                            children: List.generate(7, (dow) {
                              final date =
                                  startDate.add(Duration(days: col * 7 + dow));
                              if (date.isAfter(today)) {
                                return SizedBox(
                                  width: _cellSize + _cellGap,
                                  height: _cellSize + _cellGap,
                                  child: Container(
                                    width: _cellSize,
                                    height: _cellSize,
                                    decoration: BoxDecoration(
                                      color: context.subCardBg,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              }
                              final count =
                                  widget.activityByDate[_dateOnly(date)] ?? 0;
                              final isToday = date == today;
                              return Tooltip(
                                message: count > 0
                                    ? '${date.month}/${date.day}: $countクリア'
                                    : '${date.month}/${date.day}',
                                child: Container(
                                  width: _cellSize + _cellGap,
                                  height: _cellSize + _cellGap,
                                  padding: const EdgeInsets.all(1.5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _cellColor(count, context),
                                      borderRadius: BorderRadius.circular(2),
                                      border: isToday
                                          ? Border.all(
                                              color: kPrimaryDark, width: 1.5)
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 凡例
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('少ない',
                style: TextStyle(fontSize: 9, color: kTextSecondary)),
            const SizedBox(width: 4),
            for (final count in [0, 1, 2, 3])
              Container(
                width: _cellSize,
                height: _cellSize,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: _cellColor(count, context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 4),
            const Text('多い',
                style: TextStyle(fontSize: 9, color: kTextSecondary)),
          ],
        ),
      ],
    );
  }

  DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
