import 'package:altu_life/data/models/models.dart';

/// Statistics and basic calculation utilities.
///
/// This module contains fundamental statistical functions used across
/// the health data processing pipeline.

/// Calculates the average of a numeric field across all days.
///
/// Supported keys: 'steps', 'sleepMinutes', 'workoutMinutes', 'activeEnergy',
/// 'totalScreenTime', 'spotifyMinutes', 'productivityMinutes', 'entertainmentMinutes'
int getAverage(List<DailySummary> data, String key) {
  if (data.isEmpty) return 0;

  final sum = data.fold<int>(0, (acc, d) {
    switch (key) {
      case 'steps':
        return acc + d.steps;
      case 'sleepMinutes':
        return acc + d.sleepMinutes;
      case 'workoutMinutes':
        return acc + d.workoutMinutes;
      case 'activeEnergy':
        return acc + d.activeEnergy;
      case 'totalScreenTime':
        return acc + d.totalScreenTime;
      case 'spotifyMinutes':
        return acc + d.spotifyMinutes;
      case 'productivityMinutes':
        return acc + d.productivityMinutes;
      case 'entertainmentMinutes':
        return acc + d.entertainmentMinutes;
      default:
        return acc;
    }
  });

  return (sum / data.length).round();
}

/// Gets the breakdown of screen time by category.
///
/// Returns a list of [CategoryData] sorted by total usage descending.
List<CategoryData> getCategoryBreakdown(List<DailySummary> data) {
  final breakdown = <String, int>{};

  for (final day in data) {
    for (final entry in day.screenTimeByCategory.entries) {
      breakdown[entry.key] = (breakdown[entry.key] ?? 0) + entry.value;
    }
  }

  final result = breakdown.entries
      .map((e) => CategoryData(name: e.key, value: e.value))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return result;
}

/// Category breakdown data point.
class CategoryData {
  const CategoryData({required this.name, required this.value});
  final String name;
  final int value;
}
