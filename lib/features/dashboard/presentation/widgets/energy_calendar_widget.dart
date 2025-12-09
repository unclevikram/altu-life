import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Energy calendar heatmap widget.
///
/// Shows a calendar where darker green indicates
/// better days (high activity + good sleep).
/// Adapts to the selected date range.
class EnergyCalendarWidget extends StatefulWidget {
  const EnergyCalendarWidget({
    super.key,
    required this.data,
    required this.range,
  });

  final List<EnergyCalendarDay> data;
  final DateRange range;

  @override
  State<EnergyCalendarWidget> createState() => _EnergyCalendarWidgetState();
}

class _EnergyCalendarWidgetState extends State<EnergyCalendarWidget> {
  int? _selectedIndex;
  bool _isExpanded = false;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const int _collapsedDays = 35; // 5 weeks when collapsed

  /// Gets the display data based on expanded state.
  List<EnergyCalendarDay> get _displayData {
    // Only apply expansion logic for "All Time" range
    if (widget.range != DateRange.all || _isExpanded) {
      return widget.data;
    }
    
    // For collapsed All Time, limit to last 35 days (5 weeks)
    if (widget.data.length <= _collapsedDays) {
      return widget.data;
    }
    
    // Find the actual data days (skip padding days with score == -1)
    final actualDays = widget.data.where((d) => d.score != -1).toList();
    if (actualDays.length <= _collapsedDays) {
      return widget.data;
    }
    
    // Take last 35 actual days and recalculate padding
    final lastDays = actualDays.sublist(actualDays.length - _collapsedDays);
    final result = <EnergyCalendarDay>[];
    
    if (lastDays.isNotEmpty && lastDays.first.date.isNotEmpty) {
      final firstDate = DateTime.parse(lastDays.first.date);
      final startPadding = firstDate.weekday % 7;
      
      for (var i = 0; i < startPadding; i++) {
        result.add(const EnergyCalendarDay(
          date: '',
          score: -1,
          steps: 0,
          sleepMinutes: 0,
          workoutMinutes: 0,
          entertainmentMinutes: 0,
        ));
      }
    }
    
    result.addAll(lastDays);
    return result;
  }

  /// Whether the "Show More" button should be visible.
  bool get _canExpand {
    if (widget.range != DateRange.all) return false;
    final actualDays = widget.data.where((d) => d.score != -1).length;
    return actualDays > _collapsedDays;
  }

  @override
  Widget build(BuildContext context) {
    final displayData = _displayData;
    
    return HealthCard(
      icon: LucideIcons.battery,
      iconColor: AppColors.emerald500,
      title: 'Energy Calendar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tap any day to see details. Hit all 4 goals for the darkest green!',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.slate500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Goals legend - 4 equal columns, text wraps within each
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Expanded(child: _GoalChip(icon: LucideIcons.footprints, label: '10k steps')),
                Expanded(child: _GoalChip(icon: LucideIcons.moon, label: '7+ hrs sleep')),
                Expanded(child: _GoalChip(icon: LucideIcons.dumbbell, label: '30+ min workout')),
                Expanded(child: _GoalChip(icon: LucideIcons.tv, label: '<1hr entertainment')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: displayData.length,
            itemBuilder: (context, index) {
              final day = displayData[index];
              // Handle padding days (score == -1)
              if (day.score == -1) {
                return const SizedBox.shrink();
              }
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => _showDayDetails(context, day, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _getColor(day.score),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.brand600, width: 2)
                        : day.score == 0
                            ? Border.all(color: AppColors.slate100)
                            : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.brand600.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : day.score == 4
                            ? [
                                BoxShadow(
                                  color: AppColors.emerald200,
                                  blurRadius: 0,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      _getDayNumber(day.date),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: day.score >= 3 
                            ? Colors.white 
                            : day.score >= 1 
                                ? AppColors.emerald800 
                                : AppColors.slate400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Show More / Show Less button
          if (_canExpand) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isExpanded ? LucideIcons.chevronsUp : LucideIcons.chevronsDown,
                      size: 16,
                      color: AppColors.slate500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isExpanded ? 'Show Less' : 'Show All ${widget.data.where((d) => d.score != -1).length} Days',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDayNumber(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return date.day.toString();
    } catch (_) {
      return '';
    }
  }

  void _showDayDetails(BuildContext context, EnergyCalendarDay day, int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayDetailsSheet(day: day),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _selectedIndex = null);
      }
    });
  }

  Color _getColor(int score) {
    switch (score) {
      case 0:
        return AppColors.slate50;
      case 1:
        return AppColors.emerald100;
      case 2:
        return AppColors.emerald300;
      case 3:
        return AppColors.emerald400;
      case 4:
        return AppColors.emerald500;
      default:
        return AppColors.slate50;
    }
  }
}

/// Bottom sheet showing day details.
class _DayDetailsSheet extends StatelessWidget {
  const _DayDetailsSheet({required this.day});

  final EnergyCalendarDay day;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(day.date);
    final formattedDate = DateFormat.yMMMMd().format(date);
    final weekday = DateFormat.EEEE().format(date);
    
    // Calculate what contributed to the score (4 goals)
    final hasGoodSteps = day.steps > 10000;
    final hasGoodSleep = day.sleepMinutes > 420;
    final hasWorkout = day.workoutMinutes > 30;
    final hasLowEntertainment = day.entertainmentMinutes < 60;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getScoreColor(day.score).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.calendar,
                        color: _getScoreColor(day.score),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weekday,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Energy score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(day.score),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.zap,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${day.score}/4',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Score breakdown
                const Text(
                  'ENERGY BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate400,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Metric rows
                _MetricRow(
                  icon: LucideIcons.footprints,
                  label: 'Steps',
                  value: '${_formatNumber(day.steps)}',
                  target: '10,000',
                  achieved: hasGoodSteps,
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  icon: LucideIcons.moon,
                  label: 'Sleep',
                  value: '${(day.sleepMinutes / 60).toStringAsFixed(1)} hrs',
                  target: '7+ hrs',
                  achieved: hasGoodSleep,
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  icon: LucideIcons.dumbbell,
                  label: 'Workout',
                  value: '${day.workoutMinutes} min',
                  target: '30+ min',
                  achieved: hasWorkout,
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  icon: LucideIcons.tv,
                  label: 'Entertainment',
                  value: '${day.entertainmentMinutes} min',
                  target: '< 60 min',
                  achieved: hasLowEntertainment,
                  isInverse: true,
                ),
                
                const SizedBox(height: 16),
                
                // Summary text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getScoreColor(day.score).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getScoreColor(day.score).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getScoreIcon(day.score),
                        color: _getScoreColor(day.score),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getScoreMessage(day.score),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _getScoreColor(day.score),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 0:
        return AppColors.slate400;
      case 1:
        return AppColors.amber500;
      case 2:
        return AppColors.emerald400;
      case 3:
        return AppColors.emerald500;
      case 4:
        return AppColors.emerald600;
      default:
        return AppColors.slate400;
    }
  }

  IconData _getScoreIcon(int score) {
    switch (score) {
      case 0:
        return LucideIcons.cloudRain;
      case 1:
        return LucideIcons.cloud;
      case 2:
        return LucideIcons.cloudSun;
      case 3:
        return LucideIcons.sun;
      case 4:
        return LucideIcons.sparkles;
      default:
        return LucideIcons.helpCircle;
    }
  }

  String _getScoreMessage(int score) {
    switch (score) {
      case 0:
        return 'Tough day. Rest up and try again tomorrow!';
      case 1:
        return 'Getting there! One goal met.';
      case 2:
        return 'Solid day! Two goals achieved.';
      case 3:
        return 'Great day! Three out of four goals hit.';
      case 4:
        return 'Perfect day! All goals crushed! 🔥';
      default:
        return 'No data available.';
    }
  }
}

/// Single metric row in the details sheet.
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.target,
    required this.achieved,
    this.isInverse = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String target;
  final bool achieved;
  final bool isInverse; // For metrics where lower is better

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: achieved 
            ? AppColors.emerald50 
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: achieved ? AppColors.emerald600 : AppColors.slate400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: achieved ? AppColors.emerald800 : AppColors.slate600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: achieved ? AppColors.emerald600 : AppColors.slate700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: achieved 
                  ? AppColors.emerald500 
                  : AppColors.slate200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (achieved)
                  const Icon(
                    LucideIcons.check,
                    size: 12,
                    color: Colors.white,
                  )
                else
                  Text(
                    target,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Goal chip for the legend.
/// Displays icon on top, text below with wrapping support.
class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.emerald600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.slate600,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ],
    );
  }
}

