import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App usage heatmap by day of week with tap interaction.
class AppUsageHeatmapGrid extends StatefulWidget {
  const AppUsageHeatmapGrid({
    super.key,
    required this.data,
  });

  final List<AppUsageByDay> data;

  @override
  State<AppUsageHeatmapGrid> createState() => _AppUsageHeatmapGridState();
}

class _AppUsageHeatmapGridState extends State<AppUsageHeatmapGrid> {
  static const _appShortNames = ['Slack', 'Gmail', 'Nflx', 'Tube', 'Spot', 'Inst', 'Tik'];
  static const _appFullNames = ['Slack', 'Gmail', 'Netflix', 'YouTube', 'Spotify', 'Instagram', 'TikTok'];
  static const _dayFullNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        const Text(
          'Tap any cell to see details. Darker = more usage.',
          style: TextStyle(fontSize: 11, color: AppColors.slate400),
        ),
        const SizedBox(height: 12),
        // Header row with app names
        Row(
          children: [
            const SizedBox(width: 36), // Space for day names
            ...List.generate(_appShortNames.length, (i) {
              return Expanded(
                child: Center(
                  child: Text(
                    _appShortNames[i],
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4),
        // Data rows for each day
        ...widget.data.asMap().entries.map((dayEntry) {
          final dayIndex = dayEntry.key;
          final row = dayEntry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    row.day,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...List.generate(_appFullNames.length, (appIndex) {
                  final appName = _appFullNames[appIndex];
                  final val = row.appMinutes[appName] ?? 0;
                  // Cap opacity at 60 mins for max
                  final opacity = (val / 60).clamp(0.15, 1.0);
                  return Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onTap: () => _showCellDetails(context, row.day, appName, val, dayIndex),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: AppColors.blue600.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: val > 10
                              ? Text(
                                  '$val',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showCellDetails(BuildContext context, String day, String app, int minutes, int dayIndex) {
    HapticFeedback.lightImpact();
    
    // Find the full day name
    final fullDayName = dayIndex < _dayFullNames.length ? _dayFullNames[dayIndex] : day;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                children: [
                  // App icon and name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.blue100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.apps,
                          color: AppColors.blue600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              'Average on ${fullDayName}s',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Usage stat
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatTime(minutes),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.blue600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'average daily usage',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blue500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Context
                  Text(
                    _getUsageContext(minutes, app),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

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

  String _getUsageContext(int minutes, String app) {
    if (minutes > 60) {
      return 'Heavy usage day! Consider setting a limit for $app.';
    } else if (minutes > 30) {
      return 'Moderate usage. $app is part of your routine.';
    } else if (minutes > 10) {
      return 'Light usage. You\'re using $app sparingly.';
    } else {
      return 'Minimal usage on this day.';
    }
  }
}
