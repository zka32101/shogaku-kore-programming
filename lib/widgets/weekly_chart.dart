import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 過去N週間のクリア数を棒グラフで表示するウィジェット
class WeeklyChartWidget extends StatelessWidget {
  /// index 0 = 最古, index N-1 = 今週
  final List<int> weeklyData;

  const WeeklyChartWidget({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxY = (weeklyData.reduce((a, b) => a > b ? a : b).toDouble() + 1)
        .clamp(4.0, double.infinity);
    final weeks = weeklyData.length;

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => kPrimaryColor.withValues(alpha: 0.85),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final count = weeklyData[group.x];
                return BarTooltipItem(
                  '$count クリア',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= weeks) return const SizedBox.shrink();
                  final isThisWeek = idx == weeks - 1;
                  final weeksAgo = weeks - 1 - idx;
                  final label = isThisWeek ? '今週' : '$weeksAgo週前';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isThisWeek ? kPrimaryColor : kTextSecondary,
                        fontWeight: isThisWeek
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  if (value == meta.min) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 10, color: kTextSecondary),
                  );
                },
                reservedSize: 24,
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(weeks, (i) {
            final isThisWeek = i == weeks - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weeklyData[i].toDouble(),
                  color: isThisWeek ? kPrimaryColor : kPrimaryColor.withValues(alpha: 0.45),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withValues(alpha: 0.07),
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
