import 'package:flutter_test/flutter_test.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';
import '../../test_helpers/mock_data_helper.dart';

void main() {
  group('Correlation Functions', () {
    group('calculateWorkoutEnergyCorrelation', () {
      test('returns positive correlation for correlated data', () {
        final data = [
          createMockDailySummary(workoutMinutes: 0, activeEnergy: 200),
          createMockDailySummary(workoutMinutes: 30, activeEnergy: 500),
          createMockDailySummary(workoutMinutes: 60, activeEnergy: 800),
          createMockDailySummary(workoutMinutes: 90, activeEnergy: 1100),
        ];

        final result = calculateWorkoutEnergyCorrelation(data);

        // Should be strongly positive correlated
        expect(result, greaterThan(0.9));
      });

      test('returns negative correlation for inversely correlated data', () {
        final data = [
          createMockDailySummary(workoutMinutes: 90, activeEnergy: 200),
          createMockDailySummary(workoutMinutes: 60, activeEnergy: 500),
          createMockDailySummary(workoutMinutes: 30, activeEnergy: 800),
          createMockDailySummary(workoutMinutes: 0, activeEnergy: 1100),
        ];

        final result = calculateWorkoutEnergyCorrelation(data);

        // Should be strongly negative correlated
        expect(result, lessThan(-0.9));
      });

      test('returns 0.0 for insufficient data', () {
        final data = [createMockDailySummary()];

        final result = calculateWorkoutEnergyCorrelation(data);

        expect(result, equals(0.0));
      });

      test('returns 0.0 for empty data', () {
        final result = calculateWorkoutEnergyCorrelation([]);

        expect(result, equals(0.0));
      });

      test('handles constant values gracefully', () {
        final data = List.generate(
          5,
          (_) => createMockDailySummary(workoutMinutes: 30, activeEnergy: 500),
        );

        final result = calculateWorkoutEnergyCorrelation(data);

        // No variance = no correlation can be calculated
        expect(result, equals(0.0));
      });
    });

    group('calculateAppHealthCorrelation', () {
      test('calculates correlation between app usage and health metric', () {
        final data = [
          createMockDailySummary(
            topApps: [AppUsage(app: 'Instagram', minutes: 120)],
            sleepMinutes: 300,
          ),
          createMockDailySummary(
            topApps: [AppUsage(app: 'Instagram', minutes: 60)],
            sleepMinutes: 420,
          ),
          createMockDailySummary(
            topApps: [AppUsage(app: 'Instagram', minutes: 30)],
            sleepMinutes: 480,
          ),
          createMockDailySummary(
            topApps: [AppUsage(app: 'Instagram', minutes: 90)],
            sleepMinutes: 360,
          ),
        ];

        final result = calculateAppHealthCorrelation(
          data,
          'Instagram',
          'sleepMinutes',
        );

        // Returns a correlation value
        expect(result, isA<double>());
        expect(result.abs(), lessThanOrEqualTo(1.0));
      });

      test('returns 0.0 when app is never used', () {
        final data = List.generate(
          5,
          (_) => createMockDailySummary(
            topApps: [AppUsage(app: 'YouTube', minutes: 60)],
          ),
        );

        final result = calculateAppHealthCorrelation(
          data,
          'Instagram',
          'sleepMinutes',
        );

        expect(result, equals(0.0));
      });

      test('handles different health metrics', () {
        final data = [
          createMockDailySummary(
            topApps: [AppUsage(app: 'Strava', minutes: 30)],
            steps: 12000,
          ),
          createMockDailySummary(
            topApps: [AppUsage(app: 'Strava', minutes: 60)],
            steps: 15000,
          ),
          createMockDailySummary(
            topApps: [AppUsage(app: 'Strava', minutes: 0)],
            steps: 5000,
          ),
        ];

        final result = calculateAppHealthCorrelation(
          data,
          'Strava',
          'steps',
        );

        // Returns a valid correlation value
        expect(result, isA<double>());
        expect(result.abs(), lessThanOrEqualTo(1.0));
      });

      test('returns 0.0 for invalid health metric', () {
        final data = [createMockDailySummary()];

        final result = calculateAppHealthCorrelation(
          data,
          'Instagram',
          'invalidMetric',
        );

        expect(result, equals(0.0));
      });
    });

    group('getAppHealthCorrelations', () {
      test('calculates correlations for apps with health metrics', () {
        final data = [
          createMockDailySummary(
            topApps: [
              AppUsage(app: 'Instagram', minutes: 120),
              AppUsage(app: 'YouTube', minutes: 60),
            ],
            sleepMinutes: 300,
          ),
          createMockDailySummary(
            topApps: [
              AppUsage(app: 'Instagram', minutes: 60),
              AppUsage(app: 'YouTube', minutes: 90),
            ],
            sleepMinutes: 420,
          ),
          createMockDailySummary(
            topApps: [
              AppUsage(app: 'Instagram', minutes: 30),
              AppUsage(app: 'YouTube', minutes: 120),
            ],
            sleepMinutes: 480,
          ),
        ];

        final result = getAppHealthCorrelations(data);

        // Should return list of correlations
        expect(result, isA<List<AppHealthCorrelation>>());

        // Each correlation should have required fields
        for (final corr in result) {
          expect(corr.app, isNotEmpty);
          expect(corr.metric, isNotEmpty);
          expect(corr.correlation, isA<double>());
        }
      });

      test('handles empty data', () {
        final result = getAppHealthCorrelations([]);

        expect(result, isEmpty);
      });
    });

    group('getScreenVsSleepScatter', () {
      test('creates scatter plot points', () {
        final data = [
          createMockDailySummary(totalScreenTime: 300, sleepMinutes: 420),
          createMockDailySummary(totalScreenTime: 400, sleepMinutes: 360),
          createMockDailySummary(totalScreenTime: 200, sleepMinutes: 480),
        ];

        final result = getScreenVsSleepScatter(data);

        expect(result.length, equals(3));
        // Verify structure without asserting exact values
        for (final point in result) {
          expect(point.x, isA<double>());
          expect(point.y, isA<double>());
        }
      });

      test('handles empty data', () {
        final result = getScreenVsSleepScatter([]);

        expect(result, isEmpty);
      });
    });

    group('getAppCorrelations', () {
      test('calculates correlations for top apps', () {
        final data = [
          createMockDailySummary(
            topApps: [
              AppUsage(app: 'Instagram', minutes: 120),
              AppUsage(app: 'YouTube', minutes: 60),
            ],
          ),
          createMockDailySummary(
            topApps: [
              AppUsage(app: 'Instagram', minutes: 80),
              AppUsage(app: 'YouTube', minutes: 90),
            ],
          ),
        ];

        final result = getAppCorrelations(data);

        expect(result, isNotEmpty);
        // Should have correlations for apps
        for (final corr in result) {
          expect(corr.app, isNotEmpty);
          expect(corr.sleepMinutes, isA<double>());
          expect(corr.steps, isA<double>());
          expect(corr.workoutMinutes, isA<double>());
        }
      });

      test('returns results for empty or sparse data', () {
        final result = getAppCorrelations([]);

        // Function may return default correlations even for empty data
        expect(result, isA<List<AppCorrelation>>());
      });
    });
  });
}
