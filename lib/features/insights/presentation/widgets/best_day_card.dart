import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Card highlighting the user's best day.
class BestDayCard extends StatelessWidget {
  const BestDayCard({
    super.key,
    required this.bestDay,
  });

  final DailySummary bestDay;

  String get _formattedDate {
    try {
      final date = DateTime.parse(bestDay.date);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return bestDay.date;
    }
  }

  String get _dayOfWeek {
    try {
      final date = DateTime.parse(bestDay.date);
      return DateFormat('EEEE').format(date);
    } catch (e) {
      return 'day';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.amber100,
            AppColors.orange50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background decoration
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.trophy,
                    size: 20,
                    color: AppColors.amber600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_formattedDate was incredible!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.amber900.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'You crushed a '),
                    TextSpan(
                      text: '${bestDay.workoutMinutes} min',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' workout, burned '),
                    TextSpan(
                      text: '${bestDay.activeEnergy} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ', walked '),
                    TextSpan(
                      text: '${_formatNumber(bestDay.steps)} steps',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' AND got '),
                    TextSpan(
                      text: '${(bestDay.sleepMinutes / 60).toStringAsFixed(1)} hrs',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' of sleep.'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is your template for a perfect $_dayOfWeek!',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber900,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      LucideIcons.battery,
                      AppColors.emerald600,
                      '${bestDay.activeEnergy}',
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      LucideIcons.footprints,
                      AppColors.blue600,
                      '${bestDay.steps}',
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      LucideIcons.moon,
                      AppColors.violet600,
                      '${(bestDay.sleepMinutes / 60).toStringAsFixed(1)}h',
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

  Widget _buildStatItem(IconData icon, Color color, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.black.withValues(alpha: 0.05),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}

