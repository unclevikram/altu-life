import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Sleep quality bar chart comparing steps and screen time by sleep bucket.
/// Uses normalized values (0-100%) for fair visual comparison.
class SleepQualityBarChart extends StatelessWidget {
  const SleepQualityBarChart({
    super.key,
    required this.data,
  });

  final List<SleepQualityStat> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((d) => d.count == 0)) {
      return const Center(
        child: Text(
          'Not enough data for this period',
          style: TextStyle(color: AppColors.slate400, fontSize: 12),
        ),
      );
    }

    // Get max values for normalization
    final maxSteps = data.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final maxScreen = data.map((d) => d.screen).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  tooltipRoundedRadius: 8,
                  tooltipBorder: const BorderSide(color: AppColors.slate200),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stat = data[groupIndex];
                    if (rodIndex == 0) {
                      return BarTooltipItem(
                        '${_formatNumber(stat.steps)} steps\n(${stat.count} days)',
                        const TextStyle(
                          color: AppColors.violet600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    } else {
                      final hours = stat.screen ~/ 60;
                      final mins = stat.screen % 60;
                      return BarTooltipItem(
                        '${hours}h ${mins}m screen\n(${stat.count} days)',
                        const TextStyle(
                          color: AppColors.rose500,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final stat = data[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              stat.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate700,
                              ),
                            ),
                            Text(
                              '${stat.count} days',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.slate100,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final stat = entry.value;
                // Normalize to 0-100 scale
                final normalizedSteps = maxSteps > 0 
                    ? (stat.steps / maxSteps) * 100 
                    : 0.0;
                final normalizedScreen = maxScreen > 0 
                    ? (stat.screen / maxScreen) * 100 
                    : 0.0;
                
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: normalizedSteps,
                      color: AppColors.violet500,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: normalizedScreen,
                      color: AppColors.rose400,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  barsSpace: 4,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Avg Steps', AppColors.violet500),
            const SizedBox(width: 20),
            _buildLegendItem('Avg Screen Time', AppColors.rose400),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.slate600,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

