import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Quadrant scatter chart showing sleep vs screen time correlation.
class QuadrantScatterChart extends StatelessWidget {
  const QuadrantScatterChart({
    super.key,
    required this.data,
  });

  final List<ScatterPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return Stack(
      children: [
        // Quadrant labels
        const Positioned(
          top: 8,
          left: 8,
          child: Text(
            'IDEAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald600,
            ),
          ),
        ),
        const Positioned(
          top: 8,
          right: 8,
          child: Text(
            'WEEKEND',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.amber500,
            ),
          ),
        ),
        const Positioned(
          bottom: 28,
          left: 8,
          child: Text(
            'PRODUCTIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.blue500,
            ),
          ),
        ),
        const Positioned(
          bottom: 28,
          right: 8,
          child: Text(
            'WARNING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.rose500,
            ),
          ),
        ),

        // Chart
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: ScatterChart(
            ScatterChartData(
              minX: 0,
              maxX: 8,
              minY: 4,
              maxY: 10,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: value == 7.5
                      ? AppColors.slate300
                      : AppColors.slate100,
                  strokeWidth: value == 7.5 ? 1.5 : 1,
                  dashArray: value == 7.5 ? [4, 4] : null,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: value == 3
                      ? AppColors.slate300
                      : AppColors.slate100,
                  strokeWidth: value == 3 ? 1.5 : 1,
                  dashArray: value == 3 ? [4, 4] : null,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}h',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.slate400,
                        ),
                      );
                    },
                  ),
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
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${value.toInt()}h',
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
              scatterSpots: data.map((point) {
                return ScatterSpot(
                  point.x,
                  point.y,
                  dotPainter: FlDotCirclePainter(
                    color: _getColor(point),
                    radius: 6,
                  ),
                );
              }).toList(),
              scatterTouchData: ScatterTouchData(
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  getTooltipItems: (spot) {
                    return ScatterTooltipItem(
                      'Screen: ${spot.x}h\nSleep: ${spot.y}h',
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate700,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColor(ScatterPoint point) {
    if (point.y > 7.5) {
      return point.x < 3 ? AppColors.brand500 : AppColors.amber500;
    } else {
      return point.x < 3 ? AppColors.blue500 : AppColors.rose500;
    }
  }
}

