import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Donut chart for digital diet visualization.
class DigitalDietPieChart extends StatelessWidget {
  const DigitalDietPieChart({
    super.key,
    required this.data,
  });

  final List<CategoryData> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 30,
        sections: data.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          return PieChartSectionData(
            value: cat.value.toDouble(),
            color: AppColors.chartColors[i % AppColors.chartColors.length],
            radius: 10,
            showTitle: false,
          );
        }).toList(),
      ),
    );
  }
}

