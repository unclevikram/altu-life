import 'package:flutter_test/flutter_test.dart';
import 'package:altu_life/data/data_processing.dart';
import '../../test_helpers/mock_data_helper.dart';

void main() {
  group('Sleep Analysis Functions', () {
    group('getSleepQualityStats', () {
      test('categorizes sleep into 3 buckets', () {
        final data = [
          createMockDailySummary(sleepMinutes: 300), // < 7h
          createMockDailySummary(sleepMinutes: 450), // 7-8h
          createMockDailySummary(sleepMinutes: 540), // > 8h
        ];

        final result = getSleepQualityStats(data);

        expect(result.length, equals(3));
        expect(result[0].name, equals('< 7h'));
        expect(result[1].name, equals('7-8h'));
        expect(result[2].name, equals('> 8h'));
      });

      test('counts days in each bucket correctly', () {
        final data = [
          createMockDailySummary(sleepMinutes: 360), // < 7h
          createMockDailySummary(sleepMinutes: 390), // < 7h
          createMockDailySummary(sleepMinutes: 450), // 7-8h
          createMockDailySummary(sleepMinutes: 480), // 7-8h
          createMockDailySummary(sleepMinutes: 500), // > 8h
        ];

        final result = getSleepQualityStats(data);

        expect(result[0].count, equals(2)); // < 7h
        expect(result[1].count, equals(2)); // 7-8h
        expect(result[2].count, equals(1)); // > 8h
      });

      test('calculates average steps for each bucket', () {
        final data = [
          createMockDailySummary(sleepMinutes: 300, steps: 8000),
          createMockDailySummary(sleepMinutes: 350, steps: 9000),
          createMockDailySummary(sleepMinutes: 450, steps: 12000),
        ];

        final result = getSleepQualityStats(data);

        expect(result[0].steps, equals(8500)); // (8000+9000)/2
        expect(result[1].steps, equals(12000)); // Only one day
      });

      test('handles empty data', () {
        final result = getSleepQualityStats([]);

        expect(result.length, equals(3));
        for (final stat in result) {
          expect(stat.count, equals(0));
          expect(stat.steps, equals(0));
        }
      });
    });

    group('getSleepConsistencyStats', () {
      test('calculates sleep consistency metrics', () {
        final data = List.generate(
          7,
          (i) => createMockDailySummary(sleepMinutes: 420 + (i % 2) * 20),
        );

        final result = getSleepConsistencyStats(data);

        expect(result.avgSleep, greaterThan(0));
        expect(result.stdDev, isA<int>());
        expect(result.consistencyScore, isA<int>());
      });

      test('handles single data point', () {
        final data = [createMockDailySummary(sleepMinutes: 420)];

        final result = getSleepConsistencyStats(data);

        expect(result.avgSleep, greaterThan(0));
        expect(result.stdDev, greaterThanOrEqualTo(0));
      });
    });

    group('getWeekendSleepStats', () {
      test('calculates weekend vs weekday sleep', () {
        final data = [
          createMockDailySummary(date: '2025-11-24', sleepMinutes: 400), // Mon
          createMockDailySummary(date: '2025-11-29', sleepMinutes: 540), // Sat
          createMockDailySummary(date: '2025-11-30', sleepMinutes: 500), // Sun
        ];

        final result = getWeekendSleepStats(data);

        expect(result.weekdayAvg, greaterThan(0));
        expect(result.weekendAvg, greaterThan(0));
      });

      test('handles no weekend data', () {
        final data = [
          createMockDailySummary(date: '2025-11-24', sleepMinutes: 420),
        ];

        final result = getWeekendSleepStats(data);

        expect(result.weekdayAvg, greaterThan(0));
      });
    });

    group('getSleepAfterWorkoutStats', () {
      test('calculates sleep after workout vs rest', () {
        final data = [
          createWorkoutDay(date: '2025-11-24', workoutMinutes: 60),
          createMockDailySummary(date: '2025-11-25', sleepMinutes: 500),
          createRestDay(date: '2025-11-26'),
          createMockDailySummary(date: '2025-11-27', sleepMinutes: 420),
        ];

        final result = getSleepAfterWorkoutStats(data);

        expect(result.afterWorkout, isA<int>());
        expect(result.afterRest, isA<int>());
      });
    });

    group('getSleepTrendMA', () {
      test('calculates sleep trend with moving average', () {
        final data = List.generate(
          14,
          (i) => createMockDailySummary(
            date: '2025-11-${17 + i}',
            sleepMinutes: 420 + i * 5,
          ),
        );

        final result = getSleepTrendMA(data);

        expect(result, isNotEmpty);
        for (final point in result) {
          expect(point.sleepHours, greaterThan(0));
          expect(point.date, isNotEmpty);
        }
      });
    });
  });
}
