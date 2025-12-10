import 'dart:math' as math;

import 'package:altu_life/app/config/health_constants.dart';
import 'package:altu_life/data/models/models.dart';

/// Correlation analysis utilities.
///
/// This module contains functions for calculating Pearson correlation
/// coefficients between various health metrics and behaviors.

// ─────────────────────────────────────────────────────────────────────────────
// CORRELATION CALCULATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Calculates the Pearson correlation between workout minutes and active energy.
///
/// Returns a value between -1 and 1:
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
  final denominator = ((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

  if (denominator <= 0) return 0.0;

  final correlation = numerator / math.sqrt(denominator);
  return double.parse(correlation.toStringAsFixed(2));
}

/// Calculates correlation between app usage and health metric.
///
/// [appName] - The name of the app to analyze
/// [healthMetric] - One of: 'sleep', 'steps', 'energy', 'workout'
///
/// Returns correlation coefficient or 0.0 if insufficient data.
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
      case 'sleepMinutes':
        healthVal = d.sleepMinutes.toDouble();
      case 'steps':
        healthVal = d.steps.toDouble();
      case 'energy':
      case 'activeEnergy':
        healthVal = d.activeEnergy.toDouble();
      case 'workout':
      case 'workoutMinutes':
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

// ─────────────────────────────────────────────────────────────────────────────
// APP-HEALTH CORRELATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Gets app-health correlation insights.
///
/// Analyzes correlations between popular apps and health metrics,
/// returning only statistically significant correlations.
List<AppHealthCorrelation> getAppHealthCorrelations(List<DailySummary> data) {
  const targetApps = [
    'Slack',
    'Gmail',
    'TikTok',
    'Instagram',
    'Netflix',
    'YouTube',
    'Spotify',
    'X'
  ];
  const metrics = ['sleep', 'steps', 'energy', 'workout'];

  final correlations = <AppHealthCorrelation>[];

  for (final app in targetApps) {
    for (final metric in metrics) {
      final corr = calculateAppHealthCorrelation(data, app, metric);

      // Only include significant correlations
      if (corr.abs() >= kCorrelationSignificanceThreshold) {
        correlations.add(AppHealthCorrelation(
          app: app,
          metric: metric,
          correlation: corr,
        ));
      }
    }
  }

  // Sort by absolute correlation strength
  correlations
      .sort((a, b) => b.correlation.abs().compareTo(a.correlation.abs()));

  return correlations;
}

/// Gets app correlations with multiple health metrics.
///
/// Returns correlation data for target apps across all health metrics.
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
      final denominator =
          math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
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

// ─────────────────────────────────────────────────────────────────────────────
// SCATTER PLOT DATA
// ─────────────────────────────────────────────────────────────────────────────

/// Gets screen vs sleep scatter data for quadrant chart.
///
/// Creates scatter plot points with labels based on screen time and sleep quality.
List<ScatterPoint> getScreenVsSleepScatter(List<DailySummary> data) {
  return data.map((d) {
    final screenHours =
        double.parse((d.totalScreenTime / 60).toStringAsFixed(1));
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

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

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

/// App correlation data across multiple health metrics.
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

/// App-health correlation data for a single metric.
class AppHealthCorrelation {
  const AppHealthCorrelation({
    required this.app,
    required this.metric,
    required this.correlation,
  });
  final String app;
  final String metric;
  final double correlation;

  /// Returns a human-readable display name for the metric.
  String get metricDisplay {
    switch (metric) {
      case 'sleep':
        return 'Sleep Quality';
      case 'steps':
        return 'Daily Steps';
      case 'energy':
        return 'Active Energy';
      case 'workout':
        return 'Workout Duration';
      default:
        return metric;
    }
  }
}
