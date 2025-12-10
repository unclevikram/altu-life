import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Weekday vs weekend comparison widget.
class WeekdayVsWeekendWidget extends StatelessWidget {
  const WeekdayVsWeekendWidget({
    super.key,
    required this.data,
  });

  final List<WeekdayVsWeekend> data;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      title: 'Weekday vs Weekend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem('Weekday', AppColors.blue500),
              const SizedBox(width: 12),
              _buildLegendItem('Weekend', AppColors.purple500),
            ],
          ),
          const SizedBox(height: 12),
          // Data bars
          ...data.map((stat) {
            final total = stat.weekday + stat.weekend;
            final weekdayPercent = total > 0 ? stat.weekday / total : 0.5;
            final weekendPercent = total > 0 ? stat.weekend / total : 0.5;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.metric,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        // Weekday bar
                        Flexible(
                          flex: (weekdayPercent * 100).round(),
                          child: Container(
                            color: AppColors.blue500,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _formatValue(stat.weekday),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Weekend bar
                        Flexible(
                          flex: (weekendPercent * 100).round(),
                          child: Container(
                            color: AppColors.purple500,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _formatValue(stat.weekend),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
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
            color: AppColors.slate600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatValue(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}

