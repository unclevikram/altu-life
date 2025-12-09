/// Represents aggregated daily health and screen time data.
///
/// This is the primary data model used throughout the app, combining
/// health metrics from HealthKit with screen time data.
class DailySummary {
  /// Creates a [DailySummary] instance.
  const DailySummary({
    required this.date,
    required this.dayOfWeek,
    required this.steps,
    required this.sleepMinutes,
    required this.workoutMinutes,
    required this.activeEnergy,
    required this.totalScreenTime,
    required this.screenTimeByCategory,
    required this.productivityMinutes,
    required this.socialMinutes,
    required this.entertainmentMinutes,
    required this.spotifyMinutes,
    required this.topApps,
  });

  /// The date of this summary (YYYY-MM-DD format)
  final String date;

  /// Day of the week (0 = Sunday, 6 = Saturday)
  final int dayOfWeek;

  /// Number of steps taken
  final int steps;

  /// Total sleep duration in minutes
  final int sleepMinutes;

  /// Total workout duration in minutes
  final int workoutMinutes;

  /// Active energy burned in kilocalories
  final int activeEnergy;

  /// Total screen time in minutes
  final int totalScreenTime;

  /// Screen time breakdown by category
  final Map<String, int> screenTimeByCategory;

  /// Productivity app usage in minutes (Slack, Gmail, etc.)
  final int productivityMinutes;

  /// Social media usage in minutes (Instagram, TikTok, etc.)
  final int socialMinutes;

  /// Entertainment usage in minutes (YouTube, Netflix, etc.)
  final int entertainmentMinutes;

  /// Spotify usage in minutes (tracked separately for workout correlation)
  final int spotifyMinutes;

  /// Top apps sorted by usage time
  final List<AppUsage> topApps;

  /// Sleep duration in hours (convenience getter)
  double get sleepHours => sleepMinutes / 60;

  /// Screen time in hours (convenience getter)
  double get screenTimeHours => totalScreenTime / 60;

  /// Whether this is a weekday (Monday-Friday)
  bool get isWeekday => dayOfWeek >= 1 && dayOfWeek <= 5;

  /// Whether this is a weekend (Saturday or Sunday)
  bool get isWeekend => dayOfWeek == 0 || dayOfWeek == 6;

  /// Creates an empty [DailySummary] for a given date.
  factory DailySummary.empty(String date) {
    final dateObj = DateTime.parse(date);
    return DailySummary(
      date: date,
      dayOfWeek: dateObj.weekday % 7,
      steps: 0,
      sleepMinutes: 0,
      workoutMinutes: 0,
      activeEnergy: 0,
      totalScreenTime: 0,
      screenTimeByCategory: const {},
      productivityMinutes: 0,
      socialMinutes: 0,
      entertainmentMinutes: 0,
      spotifyMinutes: 0,
      topApps: const [],
    );
  }

  @override
  String toString() {
    return 'DailySummary(date: $date, steps: $steps, sleep: ${sleepHours.toStringAsFixed(1)}h, '
        'workout: ${workoutMinutes}min, screen: ${screenTimeHours.toStringAsFixed(1)}h)';
  }
}

/// Represents usage of a single app.
class AppUsage {
  /// Creates an [AppUsage] instance.
  const AppUsage({
    required this.app,
    required this.minutes,
  });

  /// The name of the application
  final String app;

  /// Usage duration in minutes
  final int minutes;

  @override
  String toString() => 'AppUsage($app: ${minutes}min)';
}

/// Available date range filters for data aggregation.
enum DateRange {
  /// Last 7 days
  week('7d'),

  /// Last 30 days
  month('30d'),

  /// All available data
  all('all');

  const DateRange(this.value);

  /// The string value used for display and comparison
  final String value;

  /// Display label for UI
  String get label {
    switch (this) {
      case DateRange.week:
        return '7D';
      case DateRange.month:
        return '30D';
      case DateRange.all:
        return 'All Time';
    }
  }
}

