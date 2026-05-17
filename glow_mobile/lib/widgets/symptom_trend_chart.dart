import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bar chart of top logged symptoms over recent days.
class SymptomTrendChart extends StatelessWidget {
  const SymptomTrendChart({
    super.key,
    required this.symptomCounts,
    this.maxBars = 6,
  });

  final Map<String, int> symptomCounts;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (symptomCounts.isEmpty) {
      return Text(
        'Log symptoms on Health insights to see trends over time.',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      );
    }

    final sorted = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(maxBars).toList();
    final maxY = top.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= top.length) return const SizedBox.shrink();
                  final label = top[i].key;
                  final short = label.length > 8 ? '${label.substring(0, 7)}…' : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      short,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < top.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].value.toDouble(),
                    color: scheme.primary.withValues(alpha: 0.85),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
