import 'package:flutter_test/flutter_test.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';
import '../../test_helpers/mock_data_helper.dart';

void main() {
  group('Statistics Functions', () {
    group('getAverage', () {
      test('calculates average for steps correctly', () {
        final data = [
          createMockDailySummary(steps: 8000),
          createMockDailySummary(steps: 10000),
          createMockDailySummary(steps: 6000),
        ];

        final result = getAverage(data, 'steps');

        expect(result, equals(8000));
      });

      test('calculates average for sleepMinutes correctly', () {
        final data = [
          createMockDailySummary(sleepMinutes: 420), // 7 hours
          createMockDailySummary(sleepMinutes: 480), // 8 hours
          createMockDailySummary(sleepMinutes: 360), // 6 hours
        ];

        final result = getAverage(data, 'sleepMinutes');

        expect(result, equals(420));
      });

      test('calculates average for workoutMinutes correctly', () {
        final data = [
          createMockDailySummary(workoutMinutes: 30),
          createMockDailySummary(workoutMinutes: 60),
          createMockDailySummary(workoutMinutes: 0),
        ];

        final result = getAverage(data, 'workoutMinutes');

        expect(result, equals(30));
      });

      test('calculates average for activeEnergy correctly', () {
        final data = [
          createMockDailySummary(activeEnergy: 400),
          createMockDailySummary(activeEnergy: 600),
          createMockDailySummary(activeEnergy: 500),
        ];

        final result = getAverage(data, 'activeEnergy');

        expect(result, equals(500));
      });

      test('calculates average for totalScreenTime correctly', () {
        final data = [
          createMockDailySummary(totalScreenTime: 240),
          createMockDailySummary(totalScreenTime: 360),
          createMockDailySummary(totalScreenTime: 300),
        ];

        final result = getAverage(data, 'totalScreenTime');

        expect(result, equals(300));
      });

      test('calculates average for spotifyMinutes correctly', () {
        final data = [
          createMockDailySummary(spotifyMinutes: 30),
          createMockDailySummary(spotifyMinutes: 60),
          createMockDailySummary(spotifyMinutes: 90),
        ];

        final result = getAverage(data, 'spotifyMinutes');

        expect(result, equals(60));
      });

      test('calculates average for productivityMinutes correctly', () {
        final data = [
          createMockDailySummary(productivityMinutes: 60),
          createMockDailySummary(productivityMinutes: 90),
          createMockDailySummary(productivityMinutes: 120),
        ];

        final result = getAverage(data, 'productivityMinutes');

        expect(result, equals(90));
      });

      test('calculates average for entertainmentMinutes correctly', () {
        final data = [
          createMockDailySummary(entertainmentMinutes: 100),
          createMockDailySummary(entertainmentMinutes: 150),
          createMockDailySummary(entertainmentMinutes: 200),
        ];

        final result = getAverage(data, 'entertainmentMinutes');

        expect(result, equals(150));
      });

      test('returns 0 for empty data', () {
        final result = getAverage([], 'steps');

        expect(result, equals(0));
      });

      test('returns 0 for unknown key', () {
        final data = [createMockDailySummary()];
        final result = getAverage(data, 'unknownKey');

        expect(result, equals(0));
      });

      test('rounds to nearest integer', () {
        final data = [
          createMockDailySummary(steps: 8333),
          createMockDailySummary(steps: 8334),
          createMockDailySummary(steps: 8333),
        ];

        final result = getAverage(data, 'steps');

        // Average is 8333.33, should round to 8333
        expect(result, equals(8333));
      });

      test('handles single data point', () {
        final data = [createMockDailySummary(steps: 10000)];
        final result = getAverage(data, 'steps');

        expect(result, equals(10000));
      });
    });

    group('getCategoryBreakdown', () {
      test('aggregates screen time by category correctly', () {
        final data = [
          createMockDailySummary(
            screenTimeByCategory: {
              'Social': 100,
              'Entertainment': 50,
              'Productivity & Finance': 30,
            },
          ),
          createMockDailySummary(
            screenTimeByCategory: {
              'Social': 120,
              'Entertainment': 60,
              'Productivity & Finance': 40,
            },
          ),
        ];

        final result = getCategoryBreakdown(data);

        expect(result.length, equals(3));
        expect(result[0].name, equals('Social'));
        expect(result[0].value, equals(220));
        expect(result[1].name, equals('Entertainment'));
        expect(result[1].value, equals(110));
        expect(result[2].name, equals('Productivity & Finance'));
        expect(result[2].value, equals(70));
      });

      test('sorts categories by total usage descending', () {
        final data = [
          createMockDailySummary(
            screenTimeByCategory: {
              'Productivity & Finance': 200,
              'Social': 50,
              'Entertainment': 100,
            },
          ),
        ];

        final result = getCategoryBreakdown(data);

        expect(result[0].name, equals('Productivity & Finance'));
        expect(result[0].value, equals(200));
        expect(result[1].name, equals('Entertainment'));
        expect(result[1].value, equals(100));
        expect(result[2].name, equals('Social'));
        expect(result[2].value, equals(50));
      });

      test('handles empty data', () {
        final result = getCategoryBreakdown([]);

        expect(result, isEmpty);
      });

      test('handles missing categories in some days', () {
        final data = [
          createMockDailySummary(
            screenTimeByCategory: {
              'Social': 100,
            },
          ),
          createMockDailySummary(
            screenTimeByCategory: {
              'Entertainment': 150,
            },
          ),
        ];

        final result = getCategoryBreakdown(data);

        expect(result.length, equals(2));
        expect(result[0].value, equals(150)); // Entertainment
        expect(result[1].value, equals(100)); // Social
      });

      test('handles single day data', () {
        final data = [
          createMockDailySummary(
            screenTimeByCategory: {
              'Social': 100,
              'Entertainment': 50,
            },
          ),
        ];

        final result = getCategoryBreakdown(data);

        expect(result.length, equals(2));
        expect(result[0].name, equals('Social'));
        expect(result[0].value, equals(100));
      });
    });
  });
}
