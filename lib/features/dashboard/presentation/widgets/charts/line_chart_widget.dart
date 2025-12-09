import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Weekly health summary line chart showing steps and workouts.
class WeeklyLineChart extends StatelessWidget {
  const WeeklyLineChart({
    super.key,
    required this.data,
  });

  final List<WeeklyStats> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final stepsSpots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.steps.toDouble());
    }).toList();

    final workoutSpots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.workout.toDouble());
    }).toList();

    // Find max values for scaling
    final maxSteps = data.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final maxWorkout =
        data.map((d) => d.workout).reduce((a, b) => a > b ? a : b);

    // Scale workouts to match steps range for visual comparison
    final scale = maxWorkout > 0 ? maxSteps / maxWorkout : 1.0;
    final scaledWorkoutSpots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.workout * scale);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxSteps / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.slate100,
            strokeWidth: 1,
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
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index].name,
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
          // Steps line
          LineChartBarData(
            spots: stepsSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.brand500,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.brand500,
                  strokeWidth: 0,
                );
              },
            ),
          ),
          // Workouts line (scaled)
          LineChartBarData(
            spots: scaledWorkoutSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.amber500,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.amber500,
                  strokeWidth: 0,
                );
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final i = entry.key;
                final spot = entry.value;
                final isSteps = i == 0;
                final value = isSteps
                    ? spot.y.toInt()
                    : (spot.y / scale).toInt();
                return LineTooltipItem(
                  isSteps ? '${_formatNumber(value)} steps' : '${value}min',
                  TextStyle(
                    color: isSteps ? AppColors.brand600 : AppColors.amber600,
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

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

