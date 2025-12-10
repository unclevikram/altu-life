import 'package:altu_life/data/models/models.dart';

/// Test data helpers for unit and widget tests.
///
/// Provides factory methods to create mock data for testing.

/// Creates a single [DailySummary] with default values.
DailySummary createMockDailySummary({
  String? date,
  int? dayOfWeek,
  int steps = 8000,
  int sleepMinutes = 420,
  int workoutMinutes = 30,
  int activeEnergy = 500,
  int totalScreenTime = 300,
  Map<String, int>? screenTimeByCategory,
  int productivityMinutes = 60,
  int socialMinutes = 120,
  int entertainmentMinutes = 120,
  int spotifyMinutes = 60,
  List<AppUsage>? topApps,
}) {
  final defaultDate = date ?? '2025-11-30';
  final dateObj = DateTime.parse(defaultDate);

  return DailySummary(
    date: defaultDate,
    dayOfWeek: dayOfWeek ?? dateObj.weekday % 7,
    steps: steps,
    sleepMinutes: sleepMinutes,
    workoutMinutes: workoutMinutes,
    activeEnergy: activeEnergy,
    totalScreenTime: totalScreenTime,
    screenTimeByCategory: screenTimeByCategory ?? {
      'Productivity & Finance': productivityMinutes,
      'Social': socialMinutes,
      'Entertainment': entertainmentMinutes,
    },
    productivityMinutes: productivityMinutes,
    socialMinutes: socialMinutes,
    entertainmentMinutes: entertainmentMinutes,
    spotifyMinutes: spotifyMinutes,
    topApps: topApps ?? [
      AppUsage(app: 'Instagram', minutes: 80),
      AppUsage(app: 'YouTube', minutes: 60),
      AppUsage(app: 'Spotify', minutes: spotifyMinutes),
    ],
  );
}

/// Creates a list of [DailySummary] objects for testing.
///
/// [days] - Number of days to create (default: 7)
/// [startDate] - Starting date (default: 2025-11-24)
/// [pattern] - Optional function to customize each day's data
List<DailySummary> createMockDailySummaries({
  int days = 7,
  String? startDate,
  DailySummary Function(int index, DateTime date)? pattern,
}) {
  final start = startDate != null
      ? DateTime.parse(startDate)
      : DateTime(2025, 11, 24);

  return List.generate(days, (index) {
    final date = start.add(Duration(days: index));
    final dateStr = date.toIso8601String().split('T')[0];

    if (pattern != null) {
      return pattern(index, date);
    }

    return createMockDailySummary(
      date: dateStr,
      dayOfWeek: date.weekday % 7,
    );
  });
}

/// Creates a workout day with high activity.
DailySummary createWorkoutDay({
  required String date,
  int workoutMinutes = 60,
  int steps = 12000,
  int activeEnergy = 800,
}) {
  return createMockDailySummary(
    date: date,
    workoutMinutes: workoutMinutes,
    steps: steps,
    activeEnergy: activeEnergy,
  );
}

/// Creates a rest day with low activity.
DailySummary createRestDay({
  required String date,
  int workoutMinutes = 0,
  int steps = 4000,
  int activeEnergy = 200,
}) {
  return createMockDailySummary(
    date: date,
    workoutMinutes: workoutMinutes,
    steps: steps,
    activeEnergy: activeEnergy,
  );
}

/// Creates a day with poor sleep.
DailySummary createPoorSleepDay({
  required String date,
  int sleepMinutes = 300, // 5 hours
}) {
  return createMockDailySummary(
    date: date,
    sleepMinutes: sleepMinutes,
  );
}

/// Creates a day with excellent sleep.
DailySummary createGoodSleepDay({
  required String date,
  int sleepMinutes = 480, // 8 hours
}) {
  return createMockDailySummary(
    date: date,
    sleepMinutes: sleepMinutes,
  );
}

/// Creates a [HealthDay] model for testing.
HealthDay createMockHealthDay({
  String date = '2025-11-30',
  int steps = 8000,
  int sleepMinutes = 420,
  int workoutMinutes = 30,
  int activeEnergyKcal = 500,
}) {
  return HealthDay(
    date: date,
    steps: steps,
    sleepMinutes: sleepMinutes,
    workoutMinutes: workoutMinutes,
    activeEnergyKcal: activeEnergyKcal,
  );
}

/// Creates a [ScreenTimeEntry] model for testing.
ScreenTimeEntry createMockScreenTimeEntry({
  String date = '2025-11-30',
  String app = 'Instagram',
  String category = 'Social',
  int minutes = 60,
}) {
  return ScreenTimeEntry(
    date: date,
    app: app,
    category: category,
    minutes: minutes,
  );
}
