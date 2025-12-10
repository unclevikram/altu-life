import 'package:altu_life/app/config/health_constants.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/data/processing/statistics.dart';

/// Health insights and pattern analysis utilities.
///
/// This module generates actionable insights from health data including
/// Spotify workout patterns, sleep after workouts, productivity-sleep
/// correlations, weekly rhythms, and goal tracking.

// ─────────────────────────────────────────────────────────────────────────────
// SPOTIFY & WORKOUT INSIGHTS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets Spotify usage stats comparing workout vs rest days.
///
/// Analyzes if Spotify usage is higher on workout days vs rest days,
/// which can indicate music-driven workout habits.
SpotifyWorkoutStats getSpotifyWorkoutStats(List<DailySummary> data) {
  final workoutDays = data.where((d) => d.workoutMinutes > 0).toList();
  final restDays = data.where((d) => d.workoutMinutes == 0).toList();

  return SpotifyWorkoutStats(
    workoutAvg: getAverage(workoutDays, 'spotifyMinutes'),
    restAvg: getAverage(restDays, 'spotifyMinutes'),
  );
}

/// Spotify usage comparison between workout and rest days.
class SpotifyWorkoutStats {
  const SpotifyWorkoutStats({required this.workoutAvg, required this.restAvg});
  final int workoutAvg;
  final int restAvg;
}

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP & WORKOUT RELATIONSHIP
// ─────────────────────────────────────────────────────────────────────────────

/// Gets sleep duration comparing nights after workout vs rest days.
///
/// Analyzes how workouts affect the next night's sleep. Useful for
/// understanding if workouts improve or disrupt sleep quality.
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

/// Sleep duration after workout vs rest days.
class SleepAfterWorkoutStats {
  const SleepAfterWorkoutStats({
    required this.afterWorkout,
    required this.afterRest,
  });
  final int afterWorkout;
  final int afterRest;
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTIVITY & SLEEP CORRELATION
// ─────────────────────────────────────────────────────────────────────────────

/// Gets productivity vs sleep data for correlation analysis.
///
/// Maps daily productivity app usage against sleep duration to identify
/// if productivity habits affect sleep quality.
List<ProductivitySleepData> getProductivityVsSleepData(List<DailySummary> data) {
  return data.map((d) => ProductivitySleepData(
    date: d.date,
    productivity: d.productivityMinutes,
    sleepHours: double.parse((d.sleepMinutes / 60).toStringAsFixed(1)),
  )).toList();
}

/// Data point for productivity-sleep correlation.
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

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY RHYTHMS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekly rhythm data for radar chart.
///
/// Aggregates health metrics by day of week to identify weekly patterns:
/// - Which days have the most steps/workouts/energy
/// - Sleep patterns across the week
/// - Weekend vs weekday differences
List<WeeklyRhythm> getWeeklyRhythm(List<DailySummary> data) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final grouped = List.generate(7, (_) => _RhythmAccumulator());

  for (final d in data) {
    grouped[d.dayOfWeek].count++;
    grouped[d.dayOfWeek].steps += d.steps;
    grouped[d.dayOfWeek].sleep += d.sleepMinutes;
    grouped[d.dayOfWeek].workout += d.workoutMinutes;
    grouped[d.dayOfWeek].energy += d.activeEnergy;
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
      energy: (g.energy / count).round(),
    );
  }).toList();
}

/// Helper class for accumulating weekly rhythm data.
class _RhythmAccumulator {
  int count = 0;
  int steps = 0;
  int sleep = 0;
  int workout = 0;
  int energy = 0;
}

/// Weekly rhythm averages by day of week.
class WeeklyRhythm {
  const WeeklyRhythm({
    required this.day,
    required this.steps,
    required this.sleep,
    required this.workout,
    required this.energy,
  });
  final String day;
  final int steps;
  final int sleep;
  final int workout;
  final int energy;
}

// ─────────────────────────────────────────────────────────────────────────────
// APP USAGE PATTERNS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets app usage by day of week.
///
/// Analyzes usage patterns of key apps across the week to identify:
/// - Weekend vs weekday app usage
/// - Work apps (Slack, Gmail) usage patterns
/// - Entertainment apps (Netflix, YouTube, TikTok) patterns
/// - Social apps (Instagram, Spotify) patterns
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

/// App usage averages by day of week.
class AppUsageByDay {
  const AppUsageByDay({required this.day, required this.appMinutes});
  final String day;
  final Map<String, int> appMinutes;
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL TRACKING
// ─────────────────────────────────────────────────────────────────────────────

/// Gets goals and score history.
///
/// Tracks daily goal completion and cumulative score:
/// - Steps goal: 8000 steps (5 points)
/// - Sleep goal: 7 hours (5 points)
/// - Workout goal: Any workout (10 points)
///
/// Returns daily progress and running total score.
List<GoalDay> getGoalsAndScore(List<DailySummary> data) {
  var score = 0;

  return data.map((d) {
    final goals = {
      'steps': d.steps >= 8000,
      'sleep': d.sleepMinutes >= kSleepGoalMinutes, // 7h
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

/// Daily goal completion and score tracking.
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
// WEEKDAY VS WEEKEND COMPARISON
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekday vs weekend comparison for key metrics.
///
/// Compares average values between weekdays and weekends for:
/// - Steps
/// - Sleep duration
/// - Entertainment screen time
/// - Productivity screen time
///
/// Helps identify lifestyle differences between work days and weekends.
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
