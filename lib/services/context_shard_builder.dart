import 'dart:convert';

import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/data/processing/activity_analysis.dart';
import 'package:altu_life/data/processing/correlation.dart';
import 'package:altu_life/data/processing/insights.dart';
import 'package:altu_life/data/processing/sleep_analysis.dart';

/// Small, reusable context shards to avoid sending one huge blob every turn.
class ContextShards {
  ContextShards({
    required this.persona,
    required this.stats,
    required this.sleep,
    required this.activity,
    required this.correlations,
    required this.recency,
    required this.weekly,
    required this.appUsage,
    required this.recentTable,
    required this.goals,
  });

  final String persona;
  final String stats;
  final String sleep;
  final String activity;
  final String correlations;
  final String recency;
  final String weekly;
  final String appUsage;
  final String recentTable;
  final String goals;
}

/// Builds context shards from health data.
class ContextShardBuilder {
  const ContextShardBuilder();

  ContextShards build(List<DailySummary> data) {
    final persona = _persona();
    final stats = _stats(data);
    final sleep = _sleep(data);
    final activity = _activity(data);
    final correlations = _correlations(data);
    final recency = _recency(data);
    final weekly = _weekly(data);
    final appUsage = _apps(data);
    final recentTable = _recentTable(data);
    final goals = _goals(data);

    return ContextShards(
      persona: persona,
      stats: stats,
      sleep: sleep,
      activity: activity,
      correlations: correlations,
      recency: recency,
      weekly: weekly,
      appUsage: appUsage,
      recentTable: recentTable,
      goals: goals,
    );
  }

  String _persona() {
    return '''
You are Altu, an empathetic, data-driven health assistant who makes personalized insights accessible and actionable. Use plain text (no markdown), concise paragraphs, and end with one actionable tip.''';
  }

  String _stats(List<DailySummary> data) {
    final bests = getPersonalBests(data);
    final bestDay = getBestDayStats(data);
    final productivityBest = data.isEmpty
        ? null
        : data.reduce(
            (a, b) => a.productivityMinutes >= b.productivityMinutes ? a : b,
          );

    return '''
Personal bests:
- Steps: ${bests?.steps.steps ?? 'N/A'} on ${bests?.steps.date ?? 'N/A'}
- Workout: ${bests?.workout.workoutMinutes ?? 'N/A'} min on ${bests?.workout.date ?? 'N/A'}
- Sleep: ${(bests == null ? 0 : bests.sleep.sleepMinutes / 60).toStringAsFixed(1)} hrs on ${bests?.sleep.date ?? 'N/A'}
- Energy: ${bests?.energy.activeEnergy ?? 'N/A'} kcal on ${bests?.energy.date ?? 'N/A'}
- Productivity: ${productivityBest?.productivityMinutes ?? 'N/A'} min on ${productivityBest?.date ?? 'N/A'}
Best-day pattern (avg of top vs overall):
- Best: steps ${bestDay?.best.steps ?? 'N/A'}, sleep ${bestDay?.best.sleep ?? 'N/A'} min, workout ${bestDay?.best.workout ?? 'N/A'} min
- Normal: steps ${bestDay?.avg.steps ?? 'N/A'}, sleep ${bestDay?.avg.sleep ?? 'N/A'} min, workout ${bestDay?.avg.workout ?? 'N/A'} min''';
  }

  String _sleep(List<DailySummary> data) {
    final sleepAfterWorkout = getSleepAfterWorkoutStats(data);
    final sleepConsistency = getSleepConsistencyStats(data);
    final weekendSleep = getWeekendSleepStats(data);
    final recovery = getRecoverySleepStats(data);

    return '''
Sleep signals:
- Sleep after workout: ${sleepAfterWorkout.afterWorkout} min vs rest ${sleepAfterWorkout.afterRest} min
- Consistency: score ${sleepConsistency.consistencyScore}/100 (std dev ${sleepConsistency.stdDev} min)
- Weekend vs weekday: ${weekendSleep.weekendAvg} min vs ${weekendSleep.weekdayAvg} min
- Recovery sleep: ${recovery.afterHighExertion} min after high exertion vs ${recovery.afterLowExertion} min low exertion''';
  }

  String _activity(List<DailySummary> data) {
    final streaks = getWorkoutStreakStats(data);
    final momentum = getWorkoutMomentum(data);
    final activityMomentum = getActivityMomentumStats(data);

    return '''
Activity highlights:
- Workout streak: max ${streaks.maxStreak} days, avg ${streaks.avgStreak}, total ${streaks.totalStreaks}
- Next-day after workout: steps ${momentum?.afterWorkout.steps ?? 'N/A'}, sleep ${momentum?.afterWorkout.sleep ?? 'N/A'} min
- Next-day after rest: steps ${momentum?.afterRest.steps ?? 'N/A'}, sleep ${momentum?.afterRest.sleep ?? 'N/A'} min
- Steps: workout day avg ${activityMomentum.workoutDaySteps} vs rest day ${activityMomentum.restDaySteps}''';
  }

  String _correlations(List<DailySummary> data) {
    final appCorr = getAppHealthCorrelations(data);
    if (appCorr.isEmpty) return 'Correlations: no strong signals yet.';

    final top = appCorr.take(6).map((c) {
      final impact = c.correlation > 0 ? 'improves' : 'reduces';
      return '${c.app} → ${c.correlation.toStringAsFixed(2)} $impact ${c.metricDisplay}';
    }).join('\n- ');

    return 'Correlations (strongest first):\n- $top';
  }

  String _recency(List<DailySummary> data) {
    if (data.isEmpty) return 'Recent days: none.';
    final slice = data.skip(data.length > 3 ? data.length - 3 : 0).toList();
    final lines = slice.map((d) {
      return '${d.date}: steps ${d.steps}, productivity ${d.productivityMinutes} min, sleep ${d.sleepMinutes} min, workout ${d.workoutMinutes} min, screen ${d.totalScreenTime} min';
    }).join('\n- ');
    return 'Latest 3 days:\n- $lines';
  }

  String _weekly(List<DailySummary> data) {
    final rhythm = getWeeklyRhythm(data);
    if (rhythm.isEmpty) return 'Weekly rhythm: none.';
    final parts = rhythm.take(3).map((r) {
      return '${r.day}: steps ${r.steps}, sleep ${r.sleep} min, workout ${r.workout} min';
    }).join(' | ');
    return 'Weekly rhythm (sample): $parts';
  }

  String _apps(List<DailySummary> data) {
    final byDay = getAppUsageByDay(data);
    if (byDay.isEmpty) return 'App usage by day: none.';
    final first = byDay.take(2).map((d) {
      final top = d.appMinutes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top3 = top.take(3).map((e) => '${e.key}:${e.value}m').join(', ');
      return '${d.day}: $top3';
    }).join(' | ');
    return 'App usage by day (avg): $first';
  }

  String _recentTable(List<DailySummary> data) {
    final recent30 = data
        .skip(data.length > 30 ? data.length - 30 : 0)
        .map((d) => {
              'date': d.date,
              'steps': d.steps,
              'productivity': d.productivityMinutes,
              'entertainment': d.entertainmentMinutes,
              'sleep': d.sleepMinutes,
              'workout': d.workoutMinutes,
              'energy': d.activeEnergy,
              'screen': d.totalScreenTime,
              'topApps': d.topApps.take(3).map((a) => '${a.app}:${a.minutes}m').toList(),
            })
        .toList();
    return 'Recent 30d compact table: ${jsonEncode(recent30)}';
  }

  String _goals(List<DailySummary> data) {
    final goals = getGoalsAndScore(data);
    if (goals.isEmpty) return 'Goals: no data yet.';
    final last = goals.last;
    return 'Goals: latest total score ${last.totalScore}, last day goals met ${last.goalsMet}/3 (points ${last.dailyPoints}).';
  }
}

