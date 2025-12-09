import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Steps overview area chart.
///
/// Displays step count over time with a gradient fill.
class StepsAreaChart extends StatelessWidget {
  const StepsAreaChart({
    super.key,
    required this.data,
    required this.range,
  });

  final List<DailySummary> data;
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.steps.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
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
              interval: _getInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final date = DateTime.parse(data[index].date);
                final format = range == DateRange.week
                    ? DateFormat.E()
                    : DateFormat.MMMd();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    format.format(date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slate400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.brand500,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brand500.withValues(alpha: 0.2),
                  AppColors.brand500.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipRoundedRadius: 12,
            tooltipBorder: const BorderSide(color: AppColors.slate100),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  _formatNumber(spot.y.toInt()),
                  const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(
                      text: ' steps',
                      style: TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  double _getInterval() {
    switch (range) {
      case DateRange.week:
        return 1;
      case DateRange.month:
        // Show only 4 labels to avoid overlap
        return (data.length / 4).ceilToDouble();
      case DateRange.all:
        // Show only 4 labels for all time to avoid overlap
        return (data.length / 4).ceilToDouble();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

/// Sleep trend area chart with moving average overlay.
class SleepTrendAreaChart extends StatelessWidget {
  const SleepTrendAreaChart({
    super.key,
    required this.data,
  });

  final List<SleepTrendData> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final dailySpots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.sleepHours);
    }).toList();

    final maSpots = data.asMap().entries
        .where((e) => e.value.ma != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.ma!))
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Daily values (light line)
          LineChartBarData(
            spots: dailySpots,
            isCurved: true,
            color: AppColors.slate300,
            barWidth: 1,
            dotData: const FlDotData(show: false),
          ),
          // Moving average (bold blue line)
          if (maSpots.isNotEmpty)
            LineChartBarData(
              spots: maSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.blue500,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.blue500.withValues(alpha: 0.1),
                    AppColors.blue500.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}h',
                  const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// Wellness score area chart with amber color.
class WellnessScoreChart extends StatelessWidget {
  const WellnessScoreChart({
    super.key,
    required this.data,
  });

  final List<GoalDay> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalScore.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.amber500,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.amber400.withValues(alpha: 0.3),
                  AppColors.amber100.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipRoundedRadius: 8,
            tooltipBorder: const BorderSide(color: AppColors.amber200),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final dayIndex = spot.x.toInt();
                final goalDay = dayIndex < data.length ? data[dayIndex] : null;
                final goals = goalDay?.goalsMet ?? 0;
                return LineTooltipItem(
                  '${spot.y.toInt()} pts\n$goals/3 goals',
                  const TextStyle(
                    color: AppColors.amber600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

