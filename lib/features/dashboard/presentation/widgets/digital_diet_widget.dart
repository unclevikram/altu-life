import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/pie_chart_widget.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Digital diet widget showing screen time by category.
class DigitalDietWidget extends StatelessWidget {
  const DigitalDietWidget({
    super.key,
    required this.categoryData,
    required this.avgScreen,
  });

  final List<CategoryData> categoryData;
  final int avgScreen;

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total for proper percentage calculation
    final totalValue = categoryData
        .map((c) => c.value)
        .reduce((a, b) => a + b);
    
    final maxValue = categoryData
        .map((c) => c.value)
        .reduce((a, b) => a > b ? a : b);

    return HealthCard(
      icon: LucideIcons.clock,
      iconColor: AppColors.blue500,
      title: 'Digital Diet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your screen time consumption by category.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.slate500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bars
              Expanded(
                child: Column(
                  children: categoryData.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    // Calculate percentage of total screen time (should sum to 100%)
                    final percentage = totalValue > 0
                        ? ((cat.value / totalValue) * 100).round()
                        : 0;
                    final widthPercent = maxValue > 0
                        ? (cat.value / maxValue)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.chartColors[
                                          i % AppColors.chartColors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_formatTime(cat.value)} ($percentage%)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: widthPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.chartColors[
                                      i % AppColors.chartColors.length],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              // Donut chart
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DigitalDietPieChart(data: categoryData),
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formats minutes into hours and minutes display.
  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}

