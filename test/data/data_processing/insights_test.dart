import 'package:flutter_test/flutter_test.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';
import '../../test_helpers/mock_data_helper.dart';

void main() {
  group('Insights Functions', () {
    group('getSpotifyWorkoutStats', () {
      test('compares Spotify usage on workout vs rest days', () {
        final data = [
          createWorkoutDay(date: '2025-11-24', workoutMinutes: 60),
          createWorkoutDay(date: '2025-11-25', workoutMinutes: 45),
          createRestDay(date: '2025-11-26', workoutMinutes: 0),
          createRestDay(date: '2025-11-27', workoutMinutes: 0),
        ];

        final result = getSpotifyWorkoutStats(data);

        expect(result.workoutAvg, isA<int>());
        expect(result.restAvg, isA<int>());
      });

      test('handles no workout days', () {
        final data = List.generate(
          5,
          (i) => createRestDay(date: '2025-11-${24 + i}'),
        );

        final result = getSpotifyWorkoutStats(data);

        expect(result.workoutAvg, equals(0));
        expect(result.restAvg, greaterThanOrEqualTo(0));
      });
    });

    group('getProductivityVsSleepData', () {
      test('creates productivity vs sleep data points', () {
        final data = [
          createMockDailySummary(productivityMinutes: 120, sleepMinutes: 480),
          createMockDailySummary(productivityMinutes: 60, sleepMinutes: 360),
          createMockDailySummary(productivityMinutes: 180, sleepMinutes: 420),
        ];

        final result = getProductivityVsSleepData(data);

        expect(result.length, equals(3));
        expect(result[0].productivity, equals(120));
        expect(result[0].sleepHours, equals(8.0));
      });

      test('handles empty data', () {
        final result = getProductivityVsSleepData([]);

        expect(result, isEmpty);
      });
    });

    group('getWeekdayVsWeekend', () {
      test('compares weekday vs weekend metrics', () {
        final data = [
          createMockDailySummary(date: '2025-11-24', steps: 8000), // Mon
          createMockDailySummary(date: '2025-11-29', steps: 12000), // Sat
        ];

        final result = getWeekdayVsWeekend(data);

        expect(result, isNotEmpty);
        expect(result[0].metric, isNotEmpty);
        expect(result[0].weekday, isA<num>());
        expect(result[0].weekend, isA<num>());
      });
    });

    group('getWeeklyRhythm', () {
      test('calculates average metrics by day of week', () {
        final data = List.generate(
          14,
          (i) => createMockDailySummary(
            date: '2025-11-${17 + i}',
            steps: 8000 + i * 100,
          ),
        );

        final result = getWeeklyRhythm(data);

        expect(result.length, equals(7)); // 7 days of week
        for (final day in result) {
          expect(day.day, isNotEmpty);
          expect(day.steps, greaterThanOrEqualTo(0));
          expect(day.sleep, greaterThanOrEqualTo(0));
        }
      });

      test('handles single week of data', () {
        final data = [
          createMockDailySummary(date: '2025-11-24', steps: 8000),
        ];

        final result = getWeeklyRhythm(data);

        expect(result, isNotEmpty);
      });
    });

    group('getRecoverySleepStats', () {
      test('calculates recovery sleep after activity', () {
        final data = [
          createMockDailySummary(
            date: '2025-11-24',
            workoutMinutes: 90,
            steps: 15000,
          ),
          createMockDailySummary(date: '2025-11-25', sleepMinutes: 540),
          createMockDailySummary(
            date: '2025-11-26',
            workoutMinutes: 30,
            steps: 8000,
          ),
          createMockDailySummary(date: '2025-11-27', sleepMinutes: 420),
        ];

        final result = getRecoverySleepStats(data);

        expect(result.afterHighExertion, isA<int>());
        expect(result.afterLowExertion, isA<int>());
      });
    });

    group('getWeeklyStats', () {
      test('calculates weekly statistics', () {
        final data = List.generate(
          14,
          (i) => createMockDailySummary(
            date: '2025-11-${17 + i}',
            steps: 8000,
            sleepMinutes: 420,
            workoutMinutes: 30,
          ),
        );

        final result = getWeeklyStats(data);

        expect(result, isNotEmpty);
        for (final week in result) {
          expect(week.name, isNotEmpty);
          expect(week.steps, greaterThanOrEqualTo(0));
          expect(week.sleep, greaterThanOrEqualTo(0.0));
        }
      });
    });

    group('getLowStepStats', () {
      test('identifies low vs high activity days', () {
        final data = [
          createMockDailySummary(date: '2025-11-24', steps: 3000),
          createMockDailySummary(date: '2025-11-25', steps: 12000),
        ];

        final result = getLowStepStats(data);

        expect(result.low, isA<StepDayStats>());
        expect(result.high, isA<StepDayStats>());
      });
    });

    group('getGoalsAndScore', () {
      test('calculates daily goal completion', () {
        final data = [
          createMockDailySummary(
            steps: 10000,
            sleepMinutes: 480,
            workoutMinutes: 30,
          ),
          createMockDailySummary(
            steps: 5000,
            sleepMinutes: 360,
            workoutMinutes: 0,
          ),
        ];

        final result = getGoalsAndScore(data);

        expect(result, isNotEmpty);
        for (final day in result) {
          expect(day.date, isNotEmpty);
          expect(day.goalsMet, isA<int>());
        }
      });
    });

    group('getEnergyCalendarData', () {
      test('creates calendar heatmap data', () {
        final data = List.generate(
          30,
          (i) => createMockDailySummary(
            date: '2025-11-${(i % 30) + 1}'.padLeft(10, '0'),
            activeEnergy: 500 + i * 10,
          ),
        );

        final result = getEnergyCalendarData(data, DateRange.month);

        expect(result, isNotEmpty);
        for (final day in result) {
          expect(day.date, isNotEmpty);
          expect(day.score, greaterThanOrEqualTo(-1));
        }
      });
    });
  });
}
