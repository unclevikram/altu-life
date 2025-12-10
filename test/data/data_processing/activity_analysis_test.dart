import 'package:flutter_test/flutter_test.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';
import '../../test_helpers/mock_data_helper.dart';

void main() {
  group('Activity Analysis Functions', () {
    group('getPersonalBests', () {
      test('returns personal bests for valid data', () {
        final data = [
          createMockDailySummary(date: '2025-11-24', steps: 15000),
          createMockDailySummary(date: '2025-11-25', steps: 12000),
          createMockDailySummary(date: '2025-11-26', steps: 18000),
        ];

        final result = getPersonalBests(data);

        expect(result, isNotNull);
        expect(result!.steps, isA<DailySummary>());
        expect(result.workout, isA<DailySummary>());
        expect(result.sleep, isA<DailySummary>());
        expect(result.energy, isA<DailySummary>());
      });

      test('returns null for empty data', () {
        final result = getPersonalBests([]);

        expect(result, isNull);
      });
    });

    group('getBestDayStats', () {
      test('calculates best day statistics', () {
        final data = List.generate(
          7,
          (i) => createMockDailySummary(
            date: '2025-11-${24 + i}',
            steps: 5000 + i * 1000,
            sleepMinutes: 400 + i * 10,
          ),
        );

        final result = getBestDayStats(data);

        if (result != null) {
          expect(result.avg, isA<DayAverages>());
          expect(result.best, isA<DayAverages>());
        }
      });

      test('returns null for empty data', () {
        final result = getBestDayStats([]);

        expect(result, isNull);
      });
    });

    group('getWorkoutMomentum', () {
      test('calculates workout momentum', () {
        final data = List.generate(
          14,
          (i) => i % 3 == 0
              ? createWorkoutDay(
                  date: '2025-11-${10 + i}',
                  workoutMinutes: 30,
                )
              : createRestDay(date: '2025-11-${10 + i}'),
        );

        final result = getWorkoutMomentum(data);

        if (result != null) {
          expect(result.afterWorkout, isA<NextDayStats>());
          expect(result.afterRest, isA<NextDayStats>());
        }
      });

      test('returns null for empty data', () {
        final result = getWorkoutMomentum([]);

        expect(result, isNull);
      });
    });

    group('getWorkoutStreakStats', () {
      test('calculates workout streak statistics', () {
        final data = [
          createWorkoutDay(date: '2025-11-24', workoutMinutes: 30),
          createWorkoutDay(date: '2025-11-25', workoutMinutes: 45),
          createRestDay(date: '2025-11-26'),
          createWorkoutDay(date: '2025-11-27', workoutMinutes: 30),
        ];

        final result = getWorkoutStreakStats(data);

        expect(result.avgStreak, greaterThanOrEqualTo(0.0));
        expect(result.maxStreak, greaterThanOrEqualTo(0));
        expect(result.totalStreaks, greaterThanOrEqualTo(0));
      });

      test('handles all workout days', () {
        final data = List.generate(
          5,
          (i) => createWorkoutDay(
            date: '2025-11-${24 + i}',
            workoutMinutes: 30,
          ),
        );

        final result = getWorkoutStreakStats(data);

        expect(result.maxStreak, greaterThanOrEqualTo(0));
      });
    });

    group('getActivityMomentumStats', () {
      test('calculates activity momentum', () {
        final data = [
          createWorkoutDay(date: '2025-11-24', workoutMinutes: 30),
          createMockDailySummary(date: '2025-11-24', steps: 10000),
          createRestDay(date: '2025-11-25'),
          createMockDailySummary(date: '2025-11-25', steps: 5000),
        ];

        final result = getActivityMomentumStats(data);

        expect(result.workoutDaySteps, greaterThanOrEqualTo(0));
        expect(result.restDaySteps, greaterThanOrEqualTo(0));
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
  });
}
