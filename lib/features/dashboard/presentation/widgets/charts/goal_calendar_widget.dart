import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Goal achievement calendar widget.
class GoalCalendarWidget extends StatelessWidget {
  const GoalCalendarWidget({
    super.key,
    required this.calendarGoals,
  });

  final List<GoalDay> calendarGoals;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      title: 'Achievement Streaks',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendDot(AppColors.yellow400, '3/3'),
          const SizedBox(width: 8),
          _buildLegendDot(AppColors.green400, '2/3'),
        ],
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate300,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: calendarGoals.length,
            itemBuilder: (context, index) {
              final day = calendarGoals[index];
              return Container(
                decoration: BoxDecoration(
                  color: _getColor(day.goalsMet),
                  shape: BoxShape.circle,
                  boxShadow: day.goalsMet == 3
                      ? [
                          BoxShadow(
                            color: AppColors.yellow200,
                            blurRadius: 0,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: day.goalsMet > 0
                    ? Text(
                        '${day.goalsMet}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getTextColor(day.goalsMet),
                        ),
                      )
                    : null,
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Goals: 8k Steps, 7h Sleep, Workout',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.slate400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
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
            fontSize: 9,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }

  Color _getColor(int goalsMet) {
    switch (goalsMet) {
      case 3:
        return AppColors.yellow400;
      case 2:
        return AppColors.green400;
      case 1:
        return AppColors.green200;
      default:
        return AppColors.slate100;
    }
  }

  Color _getTextColor(int goalsMet) {
    switch (goalsMet) {
      case 3:
        return AppColors.yellow900;
      case 2:
        return Colors.white;
      case 1:
        return AppColors.green800;
      default:
        return AppColors.slate300;
    }
  }
}

