import 'dart:math' as math;

import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Weekly rhythm radar chart showing steps and sleep patterns by day.
class WeeklyRhythmRadar extends StatelessWidget {
  const WeeklyRhythmRadar({
    super.key,
    required this.data,
  });

  final List<WeeklyRhythm> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Find max values for normalization
    final maxSteps = data.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final maxSleep = data.map((d) => d.sleep).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: const TextStyle(
                color: Colors.transparent,
                fontSize: 10,
              ),
              tickBorderData: BorderSide(
                color: AppColors.slate200,
                width: 1,
              ),
              gridBorderData: BorderSide(
                color: AppColors.slate200,
                width: 1,
              ),
              radarBorderData: const BorderSide(color: Colors.transparent),
              titleTextStyle: const TextStyle(
                fontSize: 10,
                color: AppColors.slate600,
                fontWeight: FontWeight.w500,
              ),
              getTitle: (index, angle) {
                if (index >= data.length) return RadarChartTitle(text: '');
                return RadarChartTitle(
                  text: data[index].day,
                  angle: angle,
                );
              },
              dataSets: [
                // Steps dataset
                RadarDataSet(
                  dataEntries: data.map((d) {
                    // Normalize to 0-1 range and scale
                    final normalized = maxSteps > 0 ? d.steps / maxSteps : 0.0;
                    return RadarEntry(value: normalized * 10000);
                  }).toList(),
                  borderColor: AppColors.brand500,
                  fillColor: AppColors.brand500.withValues(alpha: 0.3),
                  borderWidth: 2,
                  entryRadius: 0,
                ),
                // Sleep dataset
                RadarDataSet(
                  dataEntries: data.map((d) {
                    final normalized = maxSleep > 0 ? d.sleep / maxSleep : 0.0;
                    return RadarEntry(value: normalized * 10000);
                  }).toList(),
                  borderColor: AppColors.violet500,
                  fillColor: AppColors.violet500.withValues(alpha: 0.3),
                  borderWidth: 2,
                  entryRadius: 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Steps', AppColors.brand500),
            const SizedBox(width: 16),
            _buildLegendItem('Sleep', AppColors.violet500),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

