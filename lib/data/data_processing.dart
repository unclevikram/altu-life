import 'dart:math' as math;

import 'package:altu_life/data/mock_data.dart';
import 'package:altu_life/data/models/models.dart';

/// Data processing utilities for health and screen time analytics.
///
/// This file contains all the data aggregation and computation functions
/// that mirror the React app's dataProcessing.ts functionality.

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
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

// ─────────────────────────────────────────────────────────────────────────────
// MAIN AGGREGATION
// ─────────────────────────────────────────────────────────────────────────────

/// Checks if a date string is within the last [days] days.
bool _isWithinLastDays(String dateStr, int days) {
  final date = DateTime.parse(dateStr);
  final difference = currentDate.difference(date).inDays;
  return difference <= days && difference >= 0;
}

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
    final screen =
        screenTimeMap[h.date] ?? _ScreenTimeDayData();
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

/// Helper class for screen time aggregation
class _ScreenTimeDayData {
  int total = 0;
  Map<String, int> byCategory = {};
  List<AppUsage> apps = [];
  int spotify = 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// BASIC METRICS
// ─────────────────────────────────────────────────────────────────────────────

/// Calculates the average of a numeric field across all days.
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

// ─────────────────────────────────────────────────────────────────────────────
// INSIGHT HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets Spotify usage stats comparing workout vs rest days.
SpotifyWorkoutStats getSpotifyWorkoutStats(List<DailySummary> data) {
  final workoutDays = data.where((d) => d.workoutMinutes > 0).toList();
  final restDays = data.where((d) => d.workoutMinutes == 0).toList();

  return SpotifyWorkoutStats(
    workoutAvg: getAverage(workoutDays, 'spotifyMinutes'),
    restAvg: getAverage(restDays, 'spotifyMinutes'),
  );
}

/// Spotify vs workout stats.
class SpotifyWorkoutStats {
  const SpotifyWorkoutStats({required this.workoutAvg, required this.restAvg});
  final int workoutAvg;
  final int restAvg;
}

/// Gets sleep duration comparing nights after workout vs rest days.
SleepAfterWorkoutStats getSleepAfterWorkoutStats(List<DailySummary> data) {
  final workoutNextDays = <int>[];
  final restNextDays = <int>[];

  for (var i = 0; i < data.length - 1; i++) {
    final current = data[i];
    final next = data[i + 1];

    if (current.workoutMinutes > 0) {
      workoutNextDays.add(next.sleepMinutes);
    } else {
      restNextDays.add(next.sleepMinutes);
    }
  }

  int avg(List<int> arr) =>
      arr.isEmpty ? 0 : (arr.reduce((a, b) => a + b) / arr.length).round();

  return SleepAfterWorkoutStats(
    afterWorkout: avg(workoutNextDays),
    afterRest: avg(restNextDays),
  );
}

/// Sleep after workout stats.
class SleepAfterWorkoutStats {
  const SleepAfterWorkoutStats({
    required this.afterWorkout,
    required this.afterRest,
  });
  final int afterWorkout;
  final int afterRest;
}

/// Gets productivity vs sleep data for correlation analysis.
List<ProductivitySleepData> getProductivityVsSleepData(List<DailySummary> data) {
  return data.map((d) => ProductivitySleepData(
    date: d.date,
    productivity: d.productivityMinutes,
    sleepHours: double.parse((d.sleepMinutes / 60).toStringAsFixed(1)),
  )).toList();
}

/// Productivity vs sleep data point.
class ProductivitySleepData {
  const ProductivitySleepData({
    required this.date,
    required this.productivity,
    required this.sleepHours,
  });
  final String date;
  final int productivity;
  final double sleepHours;
}

/// Gets stats comparing low step days vs high step days.
LowStepStats getLowStepStats(List<DailySummary> data) {
  final lowStepDays = data.where((d) => d.steps < 5000).toList();
  final highStepDays = data.where((d) => d.steps >= 5000).toList();

  return LowStepStats(
    low: StepDayStats(
      screen: getAverage(lowStepDays, 'totalScreenTime'),
      activeEnergy: getAverage(lowStepDays, 'activeEnergy'),
    ),
    high: StepDayStats(
      screen: getAverage(highStepDays, 'totalScreenTime'),
      activeEnergy: getAverage(highStepDays, 'activeEnergy'),
    ),
  );
}

/// Low vs high step day stats.
class LowStepStats {
  const LowStepStats({required this.low, required this.high});
  final StepDayStats low;
  final StepDayStats high;
}

/// Stats for a group of days.
class StepDayStats {
  const StepDayStats({required this.screen, required this.activeEnergy});
  final int screen;
  final int activeEnergy;
}

/// Gets personal best records.
PersonalBests? getPersonalBests(List<DailySummary> data) {
  if (data.isEmpty) return null;

  DailySummary findMax(int Function(DailySummary) selector) {
    return data.reduce((prev, curr) =>
        selector(curr) > selector(prev) ? curr : prev);
  }

  // Find the best overall day using a composite score
  // Score = steps performance + sleep quality + workout + energy burned
  DailySummary findBestDay() {
    final avgSteps = data.map((d) => d.steps).reduce((a, b) => a + b) / data.length;
    final avgSleep = data.map((d) => d.sleepMinutes).reduce((a, b) => a + b) / data.length;
    final avgEnergy = data.map((d) => d.activeEnergy).reduce((a, b) => a + b) / data.length;

    var bestScore = double.negativeInfinity;
    DailySummary? bestDay;

    for (final d in data) {
      final score = (d.steps / avgSteps) +
          (d.sleepMinutes / avgSleep) +
          (d.workoutMinutes / 60) + // Normalize workout (60 min = 1 point)
          (d.activeEnergy / avgEnergy);

      if (score > bestScore) {
        bestScore = score;
        bestDay = d;
      }
    }

    return bestDay ?? findMax((d) => d.activeEnergy);
  }

  return PersonalBests(
    steps: findMax((d) => d.steps),
    workout: findMax((d) => d.workoutMinutes),
    sleep: findMax((d) => d.sleepMinutes),
    energy: findMax((d) => d.activeEnergy),
    bestDay: findBestDay(),
  );
}

/// Personal best records.
class PersonalBests {
  const PersonalBests({
    required this.steps,
    required this.workout,
    required this.sleep,
    required this.energy,
    required this.bestDay,
  });
  final DailySummary steps;
  final DailySummary workout;
  final DailySummary sleep;
  final DailySummary energy;
  final DailySummary bestDay;
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets best day stats comparing top days vs average.
BestDayStats? getBestDayStats(List<DailySummary> data) {
  if (data.length < 5) return null;

  final scoredDays = data.map((d) {
    final score = (d.steps / 10000) +
        (d.sleepMinutes / 480) +
        (d.workoutMinutes / 45) -
        (d.entertainmentMinutes / 60);
    return _ScoredDay(day: d, score: score);
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final topCount = math.max(5, (data.length * 0.1).floor());
  final bestDays = scoredDays.take(topCount).map((s) => s.day).toList();

  return BestDayStats(
    avg: DayAverages(
      steps: getAverage(data, 'steps'),
      sleep: getAverage(data, 'sleepMinutes'),
      workout: getAverage(data, 'workoutMinutes'),
      screen: getAverage(data, 'totalScreenTime'),
      entertainment: getAverage(data, 'entertainmentMinutes'),
    ),
    best: DayAverages(
      steps: getAverage(bestDays, 'steps'),
      sleep: getAverage(bestDays, 'sleepMinutes'),
      workout: getAverage(bestDays, 'workoutMinutes'),
      screen: getAverage(bestDays, 'totalScreenTime'),
      entertainment: getAverage(bestDays, 'entertainmentMinutes'),
    ),
  );
}

class _ScoredDay {
  _ScoredDay({required this.day, required this.score});
  final DailySummary day;
  final double score;
}

/// Best day comparison stats.
class BestDayStats {
  const BestDayStats({required this.avg, required this.best});
  final DayAverages avg;
  final DayAverages best;
}

/// Averages for a group of days.
class DayAverages {
  const DayAverages({
    required this.steps,
    required this.sleep,
    required this.workout,
    required this.screen,
    required this.entertainment,
  });
  final int steps;
  final int sleep;
  final int workout;
  final int screen;
  final int entertainment;
}

/// Gets workout momentum (how workout affects next day).
WorkoutMomentum? getWorkoutMomentum(List<DailySummary> data) {
  final workoutIndices = <int>[];
  final nonWorkoutIndices = <int>[];

  for (var i = 0; i < data.length - 1; i++) {
    if (data[i].workoutMinutes >= 30) {
      workoutIndices.add(i);
    } else {
      nonWorkoutIndices.add(i);
    }
  }

  if (workoutIndices.length < 3) return null;

  NextDayStats nextDayStats(List<int> indices) {
    var stepsSum = 0;
    var sleepSum = 0;
    for (final i in indices) {
      final nextDay = data[i + 1];
      stepsSum += nextDay.steps;
      sleepSum += nextDay.sleepMinutes;
    }
    return NextDayStats(
      steps: (stepsSum / indices.length).round(),
      sleep: (sleepSum / indices.length).round(),
    );
  }

  return WorkoutMomentum(
    afterWorkout: nextDayStats(workoutIndices),
    afterRest: nextDayStats(nonWorkoutIndices),
  );
}

/// Workout momentum stats.
class WorkoutMomentum {
  const WorkoutMomentum({required this.afterWorkout, required this.afterRest});
  final NextDayStats afterWorkout;
  final NextDayStats afterRest;
}

/// Next day stats.
class NextDayStats {
  const NextDayStats({required this.steps, required this.sleep});
  final int steps;
  final int sleep;
}

/// Gets sleep quality stats bucketed by duration.
List<SleepQualityStat> getSleepQualityStats(List<DailySummary> data) {
  final shortSleep = <DailySummary>[];
  final goodSleep = <DailySummary>[];
  final longSleep = <DailySummary>[];

  for (final d in data) {
    if (d.sleepMinutes < 420) {
      shortSleep.add(d);
    } else if (d.sleepMinutes <= 480) {
      goodSleep.add(d);
    } else {
      longSleep.add(d);
    }
  }

  return [
    SleepQualityStat(
      name: '< 7h',
      steps: getAverage(shortSleep, 'steps'),
      screen: getAverage(shortSleep, 'totalScreenTime'),
      count: shortSleep.length,
    ),
    SleepQualityStat(
      name: '7-8h',
      steps: getAverage(goodSleep, 'steps'),
      screen: getAverage(goodSleep, 'totalScreenTime'),
      count: goodSleep.length,
    ),
    SleepQualityStat(
      name: '> 8h',
      steps: getAverage(longSleep, 'steps'),
      screen: getAverage(longSleep, 'totalScreenTime'),
      count: longSleep.length,
    ),
  ];
}

/// Sleep quality statistic.
class SleepQualityStat {
  const SleepQualityStat({
    required this.name,
    required this.steps,
    required this.screen,
    required this.count,
  });
  final String name;
  final int steps;
  final int screen;
  final int count;
}

/// Gets energy calendar data for heatmap.
/// 
/// For 7D: Shows 7 days (1 week row)
/// For 30D: Shows ~28-35 days (4-5 complete weeks)
/// For All: Shows all available data organized in weekly rows
List<EnergyCalendarDay> getEnergyCalendarData(List<DailySummary> data, DateRange range) {
  if (data.isEmpty) return [];
  
  List<DailySummary> displayData;
  
  switch (range) {
    case DateRange.week:
      // Show exactly 7 days
      displayData = data.length > 7 ? data.sublist(data.length - 7) : data;
    case DateRange.month:
      // Show 28 days (4 weeks) for a nice grid
      displayData = data.length > 28 ? data.sublist(data.length - 28) : data;
    case DateRange.all:
      // Show all data - widget handles expansion logic
      displayData = data;
  }
  
  // For proper calendar alignment, we need to pad the start to begin on Sunday
  final result = <EnergyCalendarDay>[];
  
  if (displayData.isNotEmpty) {
    final firstDate = DateTime.parse(displayData.first.date);
    final startPadding = firstDate.weekday % 7; // Days to pad before first day (0 = Sunday)
    
    // Add empty padding days
    for (var i = 0; i < startPadding; i++) {
      result.add(EnergyCalendarDay(
        date: '',
        score: -1, // -1 indicates empty/padding day
        steps: 0,
        sleepMinutes: 0,
        workoutMinutes: 0,
        entertainmentMinutes: 0,
      ));
    }
  }
  
  // Add actual data days
  for (final d in displayData) {
    var score = 0;
    if (d.steps > 10000) score++;
    if (d.sleepMinutes > 420) score++;
    if (d.workoutMinutes > 30) score++;
    if (d.entertainmentMinutes < 60) score++;
    result.add(EnergyCalendarDay(
      date: d.date,
      score: score,
      steps: d.steps,
      sleepMinutes: d.sleepMinutes,
      workoutMinutes: d.workoutMinutes,
      entertainmentMinutes: d.entertainmentMinutes,
    ));
  }
  
  return result;
}

/// Energy calendar day data.
class EnergyCalendarDay {
  const EnergyCalendarDay({
    required this.date,
    required this.score,
    required this.steps,
    required this.sleepMinutes,
    required this.workoutMinutes,
    required this.entertainmentMinutes,
  });
  final String date;
  final int score;
  final int steps;
  final int sleepMinutes;
  final int workoutMinutes;
  final int entertainmentMinutes;
}

// ─────────────────────────────────────────────────────────────────────────────
// TREND HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekly health summary.
List<WeeklyStats> getWeeklyStats(List<DailySummary> data) {
  final weeks = <String, _WeekAccumulator>{};

  for (final d in data) {
    final date = DateTime.parse(d.date);
    // Get start of week (Sunday)
    final diff = date.weekday % 7;
    final weekStart = date.subtract(Duration(days: diff));
    final weekKey = '${_monthAbbr(weekStart.month)} ${weekStart.day}';

    weeks.putIfAbsent(weekKey, () => _WeekAccumulator());
    final week = weeks[weekKey]!;
    week.steps += d.steps;
    week.sleep += d.sleepMinutes;
    week.workout += d.workoutMinutes;
    week.count++;
  }

  final result = weeks.entries.map((e) => WeeklyStats(
    name: e.key,
    steps: (e.value.steps / e.value.count).round(),
    sleep: double.parse((e.value.sleep / e.value.count / 60).toStringAsFixed(1)),
    workout: e.value.workout,
  )).toList();

  // Return last 8 weeks
  return result.length > 8 ? result.sublist(result.length - 8) : result;
}

String _monthAbbr(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}

class _WeekAccumulator {
  int steps = 0;
  int sleep = 0;
  int workout = 0;
  int count = 0;
}

/// Weekly stats data.
class WeeklyStats {
  const WeeklyStats({
    required this.name,
    required this.steps,
    required this.sleep,
    required this.workout,
  });
  final String name;
  final int steps;
  final double sleep;
  final int workout;
}

/// Gets sleep trend with moving average.
List<SleepTrendData> getSleepTrendMA(List<DailySummary> data) {
  const maPeriod = 7;
  
  return data.asMap().entries.map((entry) {
    final i = entry.key;
    final d = entry.value;
    
    double? ma;
    if (i >= maPeriod - 1) {
      final slice = data.sublist(i - maPeriod + 1, i + 1);
      final sum = slice.fold<int>(0, (a, b) => a + b.sleepMinutes);
      ma = double.parse((sum / maPeriod / 60).toStringAsFixed(1));
    }
    
    return SleepTrendData(
      date: d.date,
      sleepHours: double.parse((d.sleepMinutes / 60).toStringAsFixed(1)),
      ma: ma,
    );
  }).toList();
}

/// Sleep trend data point.
class SleepTrendData {
  const SleepTrendData({
    required this.date,
    required this.sleepHours,
    this.ma,
  });
  final String date;
  final double sleepHours;
  final double? ma;
}

// ─────────────────────────────────────────────────────────────────────────────
// CORRELATION HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Calculates Pearson correlation between workout minutes and active energy.
/// Returns a value between -1 and 1, where:
/// - 1 = perfect positive correlation
/// - 0 = no correlation
/// - -1 = perfect negative correlation
double calculateWorkoutEnergyCorrelation(List<DailySummary> data) {
  if (data.length < 3) return 0.0;
  
  final workouts = data.map((d) => d.workoutMinutes.toDouble()).toList();
  final energy = data.map((d) => d.activeEnergy.toDouble()).toList();
  
  final n = data.length;
  var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0, sumY2 = 0.0;
  
  for (var i = 0; i < n; i++) {
    sumX += workouts[i];
    sumY += energy[i];
    sumXY += workouts[i] * energy[i];
    sumX2 += workouts[i] * workouts[i];
    sumY2 += energy[i] * energy[i];
  }
  
  final numerator = (n * sumXY) - (sumX * sumY);
  final denominator = 
      ((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
  
  if (denominator <= 0) return 0.0;
  
  final correlation = numerator / math.sqrt(denominator);
  return double.parse(correlation.toStringAsFixed(2));
}

/// Gets screen vs sleep scatter data for quadrant chart.
List<ScatterPoint> getScreenVsSleepScatter(List<DailySummary> data) {
  return data.map((d) {
    final screenHours = double.parse((d.totalScreenTime / 60).toStringAsFixed(1));
    final sleepHours = double.parse((d.sleepMinutes / 60).toStringAsFixed(1));
    
    String label;
    if (sleepHours > 7.5) {
      label = screenHours < 3 ? 'Ideal' : 'Weekend Mode';
    } else {
      label = screenHours < 3 ? 'Productive' : 'Warning';
    }
    
    return ScatterPoint(
      x: screenHours,
      y: sleepHours,
      label: label,
    );
  }).toList();
}

/// Scatter plot data point.
class ScatterPoint {
  const ScatterPoint({
    required this.x,
    required this.y,
    required this.label,
  });
  final double x;
  final double y;
  final String label;
}

/// Gets app correlations with health metrics.
List<AppCorrelation> getAppCorrelations(List<DailySummary> data) {
  const targetApps = ['Slack', 'Spotify', 'TikTok', 'Netflix', 'Instagram'];
  const metrics = ['sleepMinutes', 'steps', 'workoutMinutes', 'activeEnergy'];
  
  final results = <AppCorrelation>[];
  
  for (final app in targetApps) {
    final correlations = <String, double>{};
    
    for (final metric in metrics) {
      // Calculate simple Pearson correlation
      var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0, sumY2 = 0.0;
      var n = 0;
      
      for (final d in data) {
        final appEntry = d.topApps.where((a) => a.app == app).firstOrNull;
        final appMins = appEntry?.minutes.toDouble() ?? 0.0;
        
        double val;
        switch (metric) {
          case 'sleepMinutes':
            val = d.sleepMinutes.toDouble();
          case 'steps':
            val = d.steps.toDouble();
          case 'workoutMinutes':
            val = d.workoutMinutes.toDouble();
          case 'activeEnergy':
            val = d.activeEnergy.toDouble();
          default:
            val = 0.0;
        }
        
        sumX += appMins;
        sumY += val;
        sumXY += appMins * val;
        sumX2 += appMins * appMins;
        sumY2 += val * val;
        n++;
      }
      
      final numerator = (n * sumXY) - (sumX * sumY);
      final denominator = math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
      final r = denominator == 0 ? 0.0 : numerator / denominator;
      
      correlations[metric] = double.parse(r.toStringAsFixed(2));
    }
    
    results.add(AppCorrelation(
      app: app,
      sleepMinutes: correlations['sleepMinutes'] ?? 0,
      steps: correlations['steps'] ?? 0,
      workoutMinutes: correlations['workoutMinutes'] ?? 0,
      activeEnergy: correlations['activeEnergy'] ?? 0,
    ));
  }
  
  return results;
}

/// App correlation data.
class AppCorrelation {
  const AppCorrelation({
    required this.app,
    required this.sleepMinutes,
    required this.steps,
    required this.workoutMinutes,
    required this.activeEnergy,
  });
  final String app;
  final double sleepMinutes;
  final double steps;
  final double workoutMinutes;
  final double activeEnergy;
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPARISON HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekday vs weekend comparison.
List<WeekdayVsWeekend> getWeekdayVsWeekend(List<DailySummary> data) {
  final weekdays = data.where((d) => d.isWeekday).toList();
  final weekends = data.where((d) => d.isWeekend).toList();

  return [
    WeekdayVsWeekend(
      metric: 'Steps',
      weekday: getAverage(weekdays, 'steps'),
      weekend: getAverage(weekends, 'steps'),
    ),
    WeekdayVsWeekend(
      metric: 'Sleep (min)',
      weekday: getAverage(weekdays, 'sleepMinutes'),
      weekend: getAverage(weekends, 'sleepMinutes'),
    ),
    WeekdayVsWeekend(
      metric: 'Entertain (min)',
      weekday: getAverage(weekdays, 'entertainmentMinutes'),
      weekend: getAverage(weekends, 'entertainmentMinutes'),
    ),
    WeekdayVsWeekend(
      metric: 'Prod (min)',
      weekday: getAverage(weekdays, 'productivityMinutes'),
      weekend: getAverage(weekends, 'productivityMinutes'),
    ),
  ];
}

/// Weekday vs weekend comparison data.
class WeekdayVsWeekend {
  const WeekdayVsWeekend({
    required this.metric,
    required this.weekday,
    required this.weekend,
  });
  final String metric;
  final int weekday;
  final int weekend;
}

// ─────────────────────────────────────────────────────────────────────────────
// RHYTHM HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekly rhythm data for radar chart.
List<WeeklyRhythm> getWeeklyRhythm(List<DailySummary> data) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final grouped = List.generate(7, (_) => _RhythmAccumulator());

  for (final d in data) {
    grouped[d.dayOfWeek].count++;
    grouped[d.dayOfWeek].steps += d.steps;
    grouped[d.dayOfWeek].sleep += d.sleepMinutes;
    grouped[d.dayOfWeek].workout += d.workoutMinutes;
  }

  return grouped.asMap().entries.map((e) {
    final i = e.key;
    final g = e.value;
    final count = g.count > 0 ? g.count : 1;
    return WeeklyRhythm(
      day: days[i],
      steps: (g.steps / count).round(),
      sleep: (g.sleep / count).round(),
      workout: (g.workout / count).round(),
    );
  }).toList();
}

class _RhythmAccumulator {
  int count = 0;
  int steps = 0;
  int sleep = 0;
  int workout = 0;
}

/// Weekly rhythm data.
class WeeklyRhythm {
  const WeeklyRhythm({
    required this.day,
    required this.steps,
    required this.sleep,
    required this.workout,
  });
  final String day;
  final int steps;
  final int sleep;
  final int workout;
}

/// Gets app usage by day of week.
List<AppUsageByDay> getAppUsageByDay(List<DailySummary> data) {
  const apps = ['Slack', 'Gmail', 'Netflix', 'YouTube', 'Spotify', 'Instagram', 'TikTok'];
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  // Initialize matrix
  final matrix = List.generate(7, (i) => <String, int>{
    for (final app in apps) app: 0,
  });
  final counts = List<int>.filled(7, 0);

  for (final d in data) {
    counts[d.dayOfWeek]++;
    for (final appUsage in d.topApps) {
      if (apps.contains(appUsage.app)) {
        matrix[d.dayOfWeek][appUsage.app] =
            (matrix[d.dayOfWeek][appUsage.app] ?? 0) + appUsage.minutes;
      }
    }
  }

  // Average and build result
  return List.generate(7, (i) {
    final count = counts[i] > 0 ? counts[i] : 1;
    final appMinutes = <String, int>{};
    for (final app in apps) {
      appMinutes[app] = (matrix[i][app]! / count).round();
    }
    return AppUsageByDay(day: days[i], appMinutes: appMinutes);
  });
}

/// App usage by day data.
class AppUsageByDay {
  const AppUsageByDay({required this.day, required this.appMinutes});
  final String day;
  final Map<String, int> appMinutes;
}

// ─────────────────────────────────────────────────────────────────────────────
// GOALS HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets goals and score history.
List<GoalDay> getGoalsAndScore(List<DailySummary> data) {
  var score = 0;
  
  return data.map((d) {
    final goals = {
      'steps': d.steps >= 8000,
      'sleep': d.sleepMinutes >= 420, // 7h
      'workout': d.workoutMinutes > 0,
    };
    final goalsMet = goals.values.where((v) => v).length;
    
    // Points logic
    var dailyPoints = 0;
    if (goals['workout']!) dailyPoints += 10;
    if (goals['steps']!) dailyPoints += 5;
    if (goals['sleep']!) dailyPoints += 5;
    
    score += dailyPoints;
    
    return GoalDay(
      date: d.date,
      goalsMet: goalsMet,
      dailyPoints: dailyPoints,
      totalScore: score,
    );
  }).toList();
}

/// Goal day data.
class GoalDay {
  const GoalDay({
    required this.date,
    required this.goalsMet,
    required this.dailyPoints,
    required this.totalScore,
  });
  final String date;
  final int goalsMet;
  final int dailyPoints;
  final int totalScore;
}

// ─────────────────────────────────────────────────────────────────────────────
// ADDITIONAL INSIGHTS HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekend sleep comparison stats.
WeekendSleepStats getWeekendSleepStats(List<DailySummary> data) {
  final weekdayDays = data.where((d) => d.isWeekday).toList();
  final weekendDays = data.where((d) => d.isWeekend).toList();

  return WeekendSleepStats(
    weekdayAvg: getAverage(weekdayDays, 'sleepMinutes'),
    weekendAvg: getAverage(weekendDays, 'sleepMinutes'),
  );
}

/// Weekend vs weekday sleep stats.
class WeekendSleepStats {
  const WeekendSleepStats({
    required this.weekdayAvg,
    required this.weekendAvg,
  });
  final int weekdayAvg;
  final int weekendAvg;
}

/// Gets activity momentum stats (steps on workout days vs rest days).
ActivityMomentumStats getActivityMomentumStats(List<DailySummary> data) {
  final workoutDays = data.where((d) => d.workoutMinutes > 0).toList();
  final restDays = data.where((d) => d.workoutMinutes == 0).toList();

  return ActivityMomentumStats(
    workoutDaySteps: getAverage(workoutDays, 'steps'),
    restDaySteps: getAverage(restDays, 'steps'),
  );
}

/// Activity momentum stats.
class ActivityMomentumStats {
  const ActivityMomentumStats({
    required this.workoutDaySteps,
    required this.restDaySteps,
  });
  final int workoutDaySteps;
  final int restDaySteps;
}

/// Gets sleep consistency metrics.
SleepConsistencyStats getSleepConsistencyStats(List<DailySummary> data) {
  if (data.length < 2) {
    return const SleepConsistencyStats(
      avgSleep: 0,
      stdDev: 0,
      consistencyScore: 0,
    );
  }

  final sleepValues = data.map((d) => d.sleepMinutes).toList();
  final avg = sleepValues.reduce((a, b) => a + b) / sleepValues.length;

  // Calculate standard deviation
  final variance = sleepValues
      .map((val) => (val - avg) * (val - avg))
      .reduce((a, b) => a + b) / sleepValues.length;
  final stdDev = math.sqrt(variance);

  // Consistency score: 100 = perfect (0 std dev), lower = more variation
  // A std dev of 60 min (1 hour) = 50% score
  final consistencyScore = math.max(0, 100 - (stdDev / 60 * 50)).round();

  return SleepConsistencyStats(
    avgSleep: avg.round(),
    stdDev: stdDev.round(),
    consistencyScore: consistencyScore,
  );
}

/// Sleep consistency stats.
class SleepConsistencyStats {
  const SleepConsistencyStats({
    required this.avgSleep,
    required this.stdDev,
    required this.consistencyScore,
  });
  final int avgSleep;
  final int stdDev;
  final int consistencyScore;
}

/// Calculates correlation between app usage and health metric.
double calculateAppHealthCorrelation(
  List<DailySummary> data,
  String appName,
  String healthMetric,
) {
  if (data.length < 10) return 0.0;

  final appUsage = <double>[];
  final healthValues = <double>[];

  for (final d in data) {
    // Get app usage for this day
    var appMins = 0.0;
    for (final appEntry in d.topApps) {
      if (appEntry.app == appName) {
        appMins = appEntry.minutes.toDouble();
        break;
      }
    }

    // Get health metric value
    double healthVal;
    switch (healthMetric) {
      case 'sleep':
        healthVal = d.sleepMinutes.toDouble();
      case 'steps':
        healthVal = d.steps.toDouble();
      case 'energy':
        healthVal = d.activeEnergy.toDouble();
      case 'workout':
        healthVal = d.workoutMinutes.toDouble();
      default:
        continue;
    }

    appUsage.add(appMins);
    healthValues.add(healthVal);
  }

  if (appUsage.length < 10) return 0.0;

  // Calculate Pearson correlation
  final n = appUsage.length;
  var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0, sumY2 = 0.0;

  for (var i = 0; i < n; i++) {
    sumX += appUsage[i];
    sumY += healthValues[i];
    sumXY += appUsage[i] * healthValues[i];
    sumX2 += appUsage[i] * appUsage[i];
    sumY2 += healthValues[i] * healthValues[i];
  }

  final numerator = (n * sumXY) - (sumX * sumY);
  final denominator =
      math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

  if (denominator == 0) return 0.0;

  final correlation = numerator / denominator;
  return double.parse(correlation.toStringAsFixed(3));
}

/// Gets app-health correlation insights.
List<AppHealthCorrelation> getAppHealthCorrelations(List<DailySummary> data) {
  const targetApps = ['Slack', 'Gmail', 'TikTok', 'Instagram', 'Netflix',
                      'YouTube', 'Spotify', 'X'];
  const metrics = ['sleep', 'steps', 'energy', 'workout'];

  final correlations = <AppHealthCorrelation>[];

  for (final app in targetApps) {
    for (final metric in metrics) {
      final corr = calculateAppHealthCorrelation(data, app, metric);

      // Only include significant correlations
      if (corr.abs() >= 0.3) {
        correlations.add(AppHealthCorrelation(
          app: app,
          metric: metric,
          correlation: corr,
        ));
      }
    }
  }

  // Sort by absolute correlation strength
  correlations.sort((a, b) => b.correlation.abs().compareTo(a.correlation.abs()));

  return correlations;
}

/// App-health correlation data.
class AppHealthCorrelation {
  const AppHealthCorrelation({
    required this.app,
    required this.metric,
    required this.correlation,
  });
  final String app;
  final String metric;
  final double correlation;

  String get metricDisplay {
    switch (metric) {
      case 'sleep':
        return 'Sleep';
      case 'steps':
        return 'Steps';
      case 'energy':
        return 'Energy Burn';
      case 'workout':
        return 'Workouts';
      default:
        return metric;
    }
  }

  String get description {
    final direction = correlation > 0 ? 'more' : 'less';
    final strength = correlation.abs() >= 0.5
        ? 'strongly'
        : correlation.abs() >= 0.4
            ? 'moderately'
            : '';

    if (metric == 'sleep') {
      return '$app usage $strength correlates with $direction sleep';
    } else if (metric == 'steps') {
      final dir2 = correlation > 0 ? 'more' : 'fewer';
      return '$app usage $strength correlates with $dir2 steps';
    } else {
      final dir2 = correlation > 0 ? 'higher' : 'lower';
      return '$app usage $strength correlates with $dir2 $metricDisplay';
    }
  }
}

/// Gets recovery sleep stats (sleep after high vs low exertion).
RecoverySleepStats getRecoverySleepStats(List<DailySummary> data) {
  final highExertionNextSleep = <int>[];
  final lowExertionNextSleep = <int>[];

  for (var i = 0; i < data.length - 1; i++) {
    final day = data[i];
    final nextDay = data[i + 1];

    // Calculate exertion score
    final exertionScore = (day.steps / 10000) +
        (day.workoutMinutes / 60) +
        (day.activeEnergy / 1000);

    if (exertionScore > 2) {
      // High exertion
      highExertionNextSleep.add(nextDay.sleepMinutes);
    } else if (exertionScore < 1) {
      // Low exertion
      lowExertionNextSleep.add(nextDay.sleepMinutes);
    }
  }

  int avg(List<int> list) =>
      list.isEmpty ? 0 : (list.reduce((a, b) => a + b) / list.length).round();

  return RecoverySleepStats(
    afterHighExertion: avg(highExertionNextSleep),
    afterLowExertion: avg(lowExertionNextSleep),
  );
}

/// Recovery sleep stats.
class RecoverySleepStats {
  const RecoverySleepStats({
    required this.afterHighExertion,
    required this.afterLowExertion,
  });
  final int afterHighExertion;
  final int afterLowExertion;
}

/// Gets workout streak statistics.
WorkoutStreakStats getWorkoutStreakStats(List<DailySummary> data) {
  final streaks = <int>[];
  var currentStreak = 0;
  var prevHadWorkout = false;

  for (final day in data) {
    if (day.workoutMinutes > 0) {
      currentStreak++;
      prevHadWorkout = true;
    } else {
      if (prevHadWorkout && currentStreak > 0) {
        streaks.add(currentStreak);
      }
      currentStreak = 0;
      prevHadWorkout = false;
    }
  }

  // Add final streak if exists
  if (currentStreak > 0) {
    streaks.add(currentStreak);
  }

  if (streaks.isEmpty) {
    return const WorkoutStreakStats(
      avgStreak: 0,
      maxStreak: 0,
      totalStreaks: 0,
    );
  }

  final avgStreak = (streaks.reduce((a, b) => a + b) / streaks.length);
  final maxStreak = streaks.reduce((a, b) => a > b ? a : b);

  return WorkoutStreakStats(
    avgStreak: double.parse(avgStreak.toStringAsFixed(1)),
    maxStreak: maxStreak,
    totalStreaks: streaks.length,
  );
}

/// Workout streak statistics.
class WorkoutStreakStats {
  const WorkoutStreakStats({
    required this.avgStreak,
    required this.maxStreak,
    required this.totalStreaks,
  });
  final double avgStreak;
  final int maxStreak;
  final int totalStreaks;
}

