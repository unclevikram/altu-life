import 'dart:convert';
import 'dart:developer' as developer;

import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';

/// Builds comprehensive health data context for AI services.
///
/// This utility class extracts and formats health data insights into a
/// structured context string optimized for AI consumption. It's used by
/// both GeminiService and OpenAIService to avoid code duplication.
class AIContextBuilder {
  AIContextBuilder._();

  /// Builds a comprehensive data context string from health data.
  ///
  /// This method:
  /// - Calculates all relevant insights and correlations
  /// - Formats recent 30 days of detailed data
  /// - Structures correlation summaries
  /// - Returns a markdown-formatted context string
  ///
  /// The [serviceName] parameter is used for logging purposes.
  static String buildDataContext(
    List<DailySummary> data, {
    required String serviceName,
  }) {
    developer.log(
      '🔨 Building comprehensive data context (${data.length} days)',
      name: serviceName,
    );

    // Calculate all insights and correlations
    final bests = getPersonalBests(data);
    final bestDay = getBestDayStats(data);
    final sleepAfterWorkout = getSleepAfterWorkoutStats(data);
    final sleepConsistency = getSleepConsistencyStats(data);
    final recoveryStats = getRecoverySleepStats(data);
    final workoutStreaks = getWorkoutStreakStats(data);
    final weekendSleep = getWeekendSleepStats(data);
    final appCorrelations = getAppHealthCorrelations(data);

    // Get recent 30 days for detailed queries
    final recent30Days = data
        .skip(data.length > 30 ? data.length - 30 : 0)
        .map((d) => {
              'date': d.date,
              'steps': d.steps,
              'sleep': d.sleepMinutes,
              'workout': d.workoutMinutes,
              'energy': d.activeEnergy,
              'entertainment': d.entertainmentMinutes,
              'productivity': d.productivityMinutes,
              'screenTime': d.totalScreenTime,
              'topApps': d.topApps
                  .take(3)
                  .map((a) => '${a.app}:${a.minutes}min')
                  .join(', '),
            })
        .toList();

    // Build correlation summary
    final correlationSummary = _buildCorrelationSummary(appCorrelations);

    final context = '''
📊 **COMPREHENSIVE HEALTH DATA SUMMARY**

**Personal Bests:**
- Highest Steps: ${bests?.steps.steps ?? 'N/A'} on ${bests?.steps.date ?? 'N/A'}
- Longest Workout: ${bests?.workout.workoutMinutes ?? 'N/A'} min on ${bests?.workout.date ?? 'N/A'}
- Best Sleep: ${((bests?.sleep.sleepMinutes ?? 0) / 60).toStringAsFixed(1)} hrs on ${bests?.sleep.date ?? 'N/A'}
- Max Energy: ${bests?.energy.activeEnergy ?? 'N/A'} kcal on ${bests?.energy.date ?? 'N/A'}

**Sleep Patterns:**
- Sleep After Workout: ${sleepAfterWorkout.afterWorkout} min (vs ${sleepAfterWorkout.afterRest} min normal)
- Sleep Consistency Score: ${sleepConsistency.consistencyScore}/100 (±${sleepConsistency.stdDev} min variation)
- Weekend Sleep: ${weekendSleep.weekendAvg} min (vs ${weekendSleep.weekdayAvg} min weekday)
- Recovery Sleep (high exertion): ${recoveryStats.afterHighExertion} min (vs ${recoveryStats.afterLowExertion} min low exertion)

**Workout & Activity:**
- Max Workout Streak: ${workoutStreaks.maxStreak} days
- Total Streaks: ${workoutStreaks.totalStreaks} streaks
- Average Streak Length: ${workoutStreaks.avgStreak.toStringAsFixed(1)} days

**Best Day Pattern:**
- Best Days Average: ${bestDay?.best.steps ?? 'N/A'} steps, ${bestDay?.best.sleep ?? 'N/A'} min sleep, ${bestDay?.best.workout ?? 'N/A'} min workout
- Normal Days Average: ${bestDay?.avg.steps ?? 'N/A'} steps, ${bestDay?.avg.sleep ?? 'N/A'} min sleep, ${bestDay?.avg.workout ?? 'N/A'} min workout

**App-Health Correlations:**$correlationSummary

**Recent 30 Days Detailed Data:**
${jsonEncode(recent30Days)}

**Data Period:** ${data.first.date} to ${data.last.date} (${data.length} days)
''';

    developer.log(
      '✅ Data context built',
      name: serviceName,
      error: 'Context size: ${context.length} characters\n'
          'Sleep correlations: ${appCorrelations.where((c) => c.metric == 'sleep').length}\n'
          'Energy correlations: ${appCorrelations.where((c) => c.metric == 'energy').length}',
    );

    return context;
  }

  /// Builds a formatted correlation summary from app-health correlations.
  static String _buildCorrelationSummary(
    List<AppHealthCorrelation> appCorrelations,
  ) {
    final correlationSummary = StringBuffer();
    final sleepCorrelations =
        appCorrelations.where((c) => c.metric == 'sleep');
    final energyCorrelations =
        appCorrelations.where((c) => c.metric == 'energy');

    if (sleepCorrelations.isNotEmpty) {
      correlationSummary.writeln('\n**Sleep Correlations:**');
      for (final corr in sleepCorrelations.take(5)) {
        final impact = corr.correlation > 0 ? 'improves' : 'reduces';
        correlationSummary.writeln(
          '- ${corr.app}: ${corr.correlation.toStringAsFixed(2)} ($impact sleep)',
        );
      }
    }

    if (energyCorrelations.isNotEmpty) {
      correlationSummary.writeln('\n**Energy Correlations:**');
      for (final corr in energyCorrelations.take(3)) {
        final impact = corr.correlation > 0 ? 'increases' : 'decreases';
        correlationSummary.writeln(
          '- ${corr.app}: ${corr.correlation.toStringAsFixed(2)} ($impact energy burn)',
        );
      }
    }

    return correlationSummary.toString();
  }
}
