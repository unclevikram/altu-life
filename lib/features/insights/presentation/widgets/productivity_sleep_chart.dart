import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Chart showing productivity vs sleep correlation.
class ProductivitySleepChart extends StatelessWidget {
  const ProductivitySleepChart({
    super.key,
    required this.data,
  });

  final List<ProductivitySleepData> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxProd = data.map((d) => d.productivity).reduce((a, b) => a > b ? a : b);
    final maxSleep = data.map((d) => d.sleepHours).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxProd * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = data[groupIndex];
                return BarTooltipItem(
                  'Work: ${d.productivity}min\nSleep: ${d.sleepHours}h',
                  const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length || index % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  try {
                    final date = DateTime.parse(data[index].date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat.E().format(date),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.slate400,
                        ),
                      ),
                    );
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxProd / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.slate100,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.productivity.toDouble(),
                  color: AppColors.slate400,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          extraLinesData: ExtraLinesData(
            horizontalLines: [],
          ),
        ),
      ),
    );
  }
}

