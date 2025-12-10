import 'package:altu_life/data/mock_data.dart';
import 'package:altu_life/data/models/models.dart';

/// Data aggregation utilities.
///
/// This module handles combining health data and screen time data
/// into unified daily summaries.

// ─────────────────────────────────────────────────────────────────────────────
// DATE UTILITIES
// ─────────────────────────────────────────────────────────────────────────────

/// The reference "current" date for the data.
/// This is dynamically calculated from the actual data.
/// In production, this would be DateTime.now().
DateTime? _currentDate;

/// Gets the current reference date (last date in the data).
DateTime get currentDate {
  if (_currentDate != null) return _currentDate!;

  // Find the last date in the health data
  if (healthData.isNotEmpty) {
    final dates = healthData.map((d) => DateTime.parse(d.date)).toList();
    dates.sort((a, b) => b.compareTo(a)); // Sort descending
    _currentDate = dates.first;
  } else {
    _currentDate = DateTime.now();
  }
  return _currentDate!;
}

/// Checks if a date string is within the last [days] days.
bool _isWithinLastDays(String dateStr, int days) {
  final date = DateTime.parse(dateStr);
  final difference = currentDate.difference(date).inDays;
  return difference <= days && difference >= 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN AGGREGATION
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregates health and screen time data into daily summaries.
///
/// Combines data from HealthKit and Screen Time APIs into a unified
/// [DailySummary] format, filtered by the specified [range].
List<DailySummary> getAggregatedData(DateRange range) {
  // Create a map of health data by date
  final healthMap = <String, HealthDay>{};
  for (final day in healthData) {
    healthMap[day.date] = day;
  }

  // Create a map of screen time data by date
  final screenTimeMap = <String, _ScreenTimeDayData>{};
  for (final entry in screenTimeData) {
    screenTimeMap.putIfAbsent(
      entry.date,
      () => _ScreenTimeDayData(),
    );
    final dayData = screenTimeMap[entry.date]!;
    dayData.total += entry.minutes;
    dayData.byCategory[entry.category] =
        (dayData.byCategory[entry.category] ?? 0) + entry.minutes;
    dayData.apps.add(AppUsage(app: entry.app, minutes: entry.minutes));
    if (entry.app == 'Spotify') {
      dayData.spotify += entry.minutes;
    }
  }

  // Combine into DailySummary objects
  var merged = healthData.map((h) {
    final screen = screenTimeMap[h.date] ?? _ScreenTimeDayData();
    final dateObj = DateTime.parse(h.date);

    final cats = screen.byCategory;
    final productivity = cats['Productivity & Finance'] ?? 0;
    final social = cats['Social'] ?? 0;
    final entertainment = cats['Entertainment'] ?? 0;

    // Sort apps by usage time
    final sortedApps = List<AppUsage>.from(screen.apps)
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    return DailySummary(
      date: h.date,
      dayOfWeek: dateObj.weekday % 7, // Convert to 0=Sun format
      steps: h.steps,
      sleepMinutes: h.sleepMinutes,
      workoutMinutes: h.workoutMinutes,
      activeEnergy: h.activeEnergyKcal,
      totalScreenTime: screen.total,
      screenTimeByCategory: Map<String, int>.from(cats),
      productivityMinutes: productivity,
      socialMinutes: social,
      entertainmentMinutes: entertainment,
      spotifyMinutes: screen.spotify,
      topApps: sortedApps,
    );
  }).toList();

  // Filter by date range
  switch (range) {
    case DateRange.week:
      merged = merged.where((d) => _isWithinLastDays(d.date, 7)).toList();
    case DateRange.month:
      merged = merged.where((d) => _isWithinLastDays(d.date, 30)).toList();
    case DateRange.all:
      break; // No filtering
  }

  // Sort by date ascending
  merged.sort((a, b) => a.date.compareTo(b.date));

  return merged;
}

/// Helper class for screen time aggregation.
class _ScreenTimeDayData {
  int total = 0;
  Map<String, int> byCategory = {};
  List<AppUsage> apps = [];
  int spotify = 0;
}
