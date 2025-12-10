import 'dart:math' as math;

import 'package:altu_life/app/config/health_constants.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/data/processing/statistics.dart';

/// Activity analysis utilities.
///
/// This module handles all activity-related calculations including personal bests,
/// best day comparisons, workout momentum, and activity patterns.

// ─────────────────────────────────────────────────────────────────────────────
// PERSONAL BESTS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets personal best records across all metrics.
///
/// Finds the days with:
/// - Most steps
/// - Longest workout
/// - Most sleep
/// - Highest active energy
/// - Best overall day (composite score)
///
/// Returns null if no data is available.
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
// BEST DAY ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets best day stats comparing top days vs average.
///
/// Calculates a composite score for each day based on:
/// - Steps (relative to goal)
/// - Sleep (relative to optimal)
/// - Workout duration
/// - Entertainment time (penalty)
///
/// Compares the top 10% of days against the overall average.
/// Returns null if there are fewer than 5 days of data.
BestDayStats? getBestDayStats(List<DailySummary> data) {
  if (data.length < 5) return null;

  final scoredDays = data.map((d) {
    final score = (d.steps / kStepsGoal) +
        (d.sleepMinutes / kSleepOptimalMinutes) +
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

/// Helper class for day scoring.
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

// ─────────────────────────────────────────────────────────────────────────────
// WORKOUT MOMENTUM
// ─────────────────────────────────────────────────────────────────────────────

/// Gets workout momentum (how workouts affect the next day).
///
/// Analyzes the impact of working out on next-day performance:
/// - Compares next-day steps and sleep after workout days vs rest days
/// - Requires at least 3 workout days for statistical significance
///
/// A workout day is defined as having 30+ minutes of workout.
/// Returns null if there are fewer than 3 workout days.
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

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY PATTERNS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets activity momentum stats (steps on workout days vs rest days).
///
/// Compares step counts on:
/// - Days with workouts (workoutMinutes > 0)
/// - Days without workouts (workoutMinutes = 0)
///
/// Helps identify if workouts boost or drain daily activity.
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

// ─────────────────────────────────────────────────────────────────────────────
// LOW VS HIGH STEP ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets stats comparing low step days vs high step days.
///
/// Compares screen time and active energy between:
/// - Low step days (< 5000 steps)
/// - High step days (>= 5000 steps)
///
/// Helps identify if low activity correlates with increased screen time.
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

/// Low vs high step day comparison stats.
class LowStepStats {
  const LowStepStats({required this.low, required this.high});
  final StepDayStats low;
  final StepDayStats high;
}

/// Stats for a group of step days.
class StepDayStats {
  const StepDayStats({required this.screen, required this.activeEnergy});
  final int screen;
  final int activeEnergy;
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKOUT STREAKS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets workout streak statistics.
///
/// Tracks workout streaks (consecutive days with workouts):
/// - Average streak length
/// - Maximum streak achieved
/// - Total number of streaks
///
/// Useful for understanding workout consistency and habit formation.
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
