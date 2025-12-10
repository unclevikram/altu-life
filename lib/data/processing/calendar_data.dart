import 'package:altu_life/app/config/health_constants.dart';
import 'package:altu_life/data/models/models.dart';

/// Calendar and weekly trend data utilities.
///
/// This module handles calendar heatmap generation and weekly trend analysis
/// for visualizing health patterns over time.

// ─────────────────────────────────────────────────────────────────────────────
// ENERGY CALENDAR HEATMAP
// ─────────────────────────────────────────────────────────────────────────────

/// Gets energy calendar data for heatmap visualization.
///
/// Generates calendar grid data with health scores for each day:
/// - Score calculation: +1 for each goal met (steps, sleep, workout, low entertainment)
/// - Pads calendar to start on Sunday for proper week alignment
///
/// Date range options:
/// - 7D: Shows exactly 7 days (1 week row)
/// - 30D: Shows 28 days (4 complete weeks)
/// - All: Shows all available data organized in weekly rows
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
    if (d.steps > kStepsGoal) score++;
    if (d.sleepMinutes > kSleepGoalMinutes) score++;
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

/// Calendar day data with health score.
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
// WEEKLY TRENDS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets weekly health summary aggregated by week.
///
/// Aggregates data into weekly buckets starting on Sundays:
/// - Average steps per day
/// - Average sleep hours per day
/// - Total workout minutes for the week
///
/// Returns the last 8 weeks of data for trend visualization.
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

/// Helper function to get month abbreviation.
String _monthAbbr(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}

/// Helper class for accumulating weekly data.
class _WeekAccumulator {
  int steps = 0;
  int sleep = 0;
  int workout = 0;
  int count = 0;
}

/// Weekly aggregated health statistics.
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
