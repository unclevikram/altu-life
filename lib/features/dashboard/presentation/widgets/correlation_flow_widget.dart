import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Activity to Energy flow visualization widget.
/// Shows the Pearson correlation between workout and energy.
class CorrelationFlowWidget extends StatelessWidget {
  const CorrelationFlowWidget({
    super.key,
    required this.correlation,
  });

  /// The Pearson correlation coefficient (-1 to 1).
  final double correlation;

  String get _correlationStrength {
    final absCorr = correlation.abs();
    if (absCorr >= 0.7) return 'Strong';
    if (absCorr >= 0.4) return 'Moderate';
    if (absCorr >= 0.2) return 'Weak';
    return 'No';
  }

  String get _correlationMessage {
    if (correlation >= 0.7) {
      return 'Strong link: More workout = more energy burned!';
    } else if (correlation >= 0.4) {
      return 'Moderate link: Workouts contribute to your energy expenditure.';
    } else if (correlation >= 0.2) {
      return 'Weak link: Other factors affect your energy more than workouts.';
    } else if (correlation >= -0.2) {
      return 'No clear pattern between workout and energy.';
    } else {
      return 'Inverse pattern: Rest days may show higher baseline energy.';
    }
  }

  Color get _correlationColor {
    if (correlation >= 0.5) return AppColors.emerald500;
    if (correlation >= 0.2) return AppColors.amber500;
    return AppColors.slate400;
  }

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      title: 'Workout → Energy Correlation',
      child: Column(
        children: [
          // Flow visualization
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Workout box
                  _buildFlowBox(
                    label: 'WORKOUT',
                    value: 'Minutes',
                    backgroundColor: AppColors.amber50,
                    borderColor: AppColors.amber100,
                    labelColor: AppColors.amber600,
                    valueColor: AppColors.amber800,
                  ),
                  // Spacer for center badge
                  const SizedBox(width: 80),
                  // Energy box
                  _buildFlowBox(
                    label: 'ENERGY',
                    value: 'Burned',
                    backgroundColor: AppColors.emerald50,
                    borderColor: AppColors.emerald100,
                    labelColor: AppColors.emerald600,
                    valueColor: AppColors.emerald800,
                  ),
                ],
              ),
              // Connecting line with gradient - positioned behind
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 104),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.amber200,
                          _correlationColor,
                          AppColors.emerald200,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Correlation badge - positioned on top in center
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _correlationColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _correlationColor, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          correlation.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: _correlationColor,
                          ),
                        ),
                        Text(
                          _correlationStrength,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: _correlationColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _correlationMessage,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowBox({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color borderColor,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

