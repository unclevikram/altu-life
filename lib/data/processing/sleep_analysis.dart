import 'dart:math' as math;

import 'package:altu_life/app/config/health_constants.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/data/processing/statistics.dart';

/// Sleep analysis utilities.
///
/// This module handles all sleep-related calculations including quality stats,
/// trends, consistency metrics, and weekend comparisons.

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP QUALITY ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets sleep quality stats bucketed by duration.
///
/// Categorizes days into:
/// - < 7h: Short sleep
/// - 7-8h: Optimal sleep
/// - > 8h: Long sleep
///
/// For each category, calculates average steps and screen time.
List<SleepQualityStat> getSleepQualityStats(List<DailySummary> data) {
  final shortSleep = <DailySummary>[];
  final goodSleep = <DailySummary>[];
  final longSleep = <DailySummary>[];

  for (final d in data) {
    if (d.sleepMinutes < kSleepShortThreshold) {
      shortSleep.add(d);
    } else if (d.sleepMinutes <= kSleepLongThreshold) {
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

/// Sleep quality statistic for a duration category.
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

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP TRENDS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets sleep trend with 7-day moving average.
///
/// Returns daily sleep duration with a smoothed moving average to identify
/// trends over time. Moving average starts after the first 6 days.
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

/// Sleep trend data point with moving average.
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
// WEEKEND VS WEEKDAY ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekend sleep comparison stats.
///
/// Compares average sleep duration between weekdays and weekends to identify
/// if the user catches up on sleep during weekends.
WeekendSleepStats getWeekendSleepStats(List<DailySummary> data) {
  final weekdayDays = data.where((d) => d.isWeekday).toList();
  final weekendDays = data.where((d) => d.isWeekend).toList();

  return WeekendSleepStats(
    weekdayAvg: getAverage(weekdayDays, 'sleepMinutes'),
    weekendAvg: getAverage(weekendDays, 'sleepMinutes'),
  );
}

/// Weekend vs weekday sleep comparison.
class WeekendSleepStats {
  const WeekendSleepStats({
    required this.weekdayAvg,
    required this.weekendAvg,
  });
  final int weekdayAvg;
  final int weekendAvg;
}

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP CONSISTENCY
// ─────────────────────────────────────────────────────────────────────────────

/// Gets sleep consistency metrics.
///
/// Calculates:
/// - Average sleep duration
/// - Standard deviation (variability)
/// - Consistency score (100 = perfect, lower = more variation)
///
/// A consistency score of 100 means perfect regularity.
/// Score decreases by 50 points for every 60 minutes of standard deviation.
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

/// Sleep consistency metrics.
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

// ─────────────────────────────────────────────────────────────────────────────
// RECOVERY SLEEP ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets recovery sleep stats (sleep after high vs low exertion).
///
/// Analyzes sleep duration following days of different exertion levels:
/// - High exertion: exertion score > 2 (based on steps, workouts, energy)
/// - Low exertion: exertion score < 1
///
/// Exertion score = (steps/10000) + (workout_min/60) + (energy/1000)
///
/// Helps identify if the body requires more sleep after high activity days.
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

/// Recovery sleep statistics.
class RecoverySleepStats {
  const RecoverySleepStats({
    required this.afterHighExertion,
    required this.afterLowExertion,
  });
  final int afterHighExertion;
  final int afterLowExertion;
}
