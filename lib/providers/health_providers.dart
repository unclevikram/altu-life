import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the selected date range.
final dateRangeProvider = StateProvider<DateRange>((ref) => DateRange.month);

/// Provider for aggregated health data based on selected date range.
final aggregatedDataProvider = Provider<List<DailySummary>>((ref) {
  final range = ref.watch(dateRangeProvider);
  return getAggregatedData(range);
});

/// Provider for all-time aggregated data (used for insights).
final allTimeDataProvider = Provider<List<DailySummary>>((ref) {
  return getAggregatedData(DateRange.all);
});

/// Provider for average steps.
final avgStepsProvider = Provider<int>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getAverage(data, 'steps');
});

/// Provider for average sleep.
final avgSleepProvider = Provider<int>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getAverage(data, 'sleepMinutes');
});

/// Provider for average screen time.
final avgScreenTimeProvider = Provider<int>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getAverage(data, 'totalScreenTime');
});

/// Provider for category breakdown.
final categoryBreakdownProvider = Provider<List<CategoryData>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getCategoryBreakdown(data).take(4).toList();
});

/// Provider for sleep quality stats - respects date filter.
final sleepQualityStatsProvider = Provider<List<SleepQualityStat>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getSleepQualityStats(data);
});

/// Provider for energy calendar data.
final energyCalendarProvider = Provider<List<EnergyCalendarDay>>((ref) {
  final range = ref.watch(dateRangeProvider);
  final data = ref.watch(aggregatedDataProvider);
  return getEnergyCalendarData(data, range);
});

/// Provider for weekly stats - respects date filter.
final weeklyStatsProvider = Provider<List<WeeklyStats>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getWeeklyStats(data);
});

/// Provider for sleep trend with moving average - respects date filter.
final sleepTrendProvider = Provider<List<SleepTrendData>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getSleepTrendMA(data);
});

/// Provider for weekday vs weekend comparison - respects date filter.
final weekdayVsWeekendProvider = Provider<List<WeekdayVsWeekend>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getWeekdayVsWeekend(data);
});

/// Provider for weekly rhythm (radar chart) - respects date filter.
final weeklyRhythmProvider = Provider<List<WeeklyRhythm>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getWeeklyRhythm(data);
});

/// Provider for app usage by day - respects date filter.
final appUsageByDayProvider = Provider<List<AppUsageByDay>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getAppUsageByDay(data);
});

/// Provider for goals and score data - respects date filter.
final goalsDataProvider = Provider<List<GoalDay>>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return getGoalsAndScore(data);
});

/// Provider for activity flow correlation (uses all data for better accuracy).
/// Returns the Pearson correlation coefficient between workout and energy.
final activityFlowCorrelationProvider = Provider<double>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return calculateWorkoutEnergyCorrelation(data);
});

// ─────────────────────────────────────────────────────────────────────────────
// INSIGHTS PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Provider for Spotify vs workout stats.
final spotifyWorkoutStatsProvider = Provider<SpotifyWorkoutStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getSpotifyWorkoutStats(data);
});

/// Provider for sleep after workout stats.
final sleepAfterWorkoutProvider = Provider<SleepAfterWorkoutStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getSleepAfterWorkoutStats(data);
});

/// Provider for productivity vs sleep data.
final productivityVsSleepProvider = Provider<List<ProductivitySleepData>>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getProductivityVsSleepData(data);
});

/// Provider for low step stats.
final lowStepStatsProvider = Provider<LowStepStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getLowStepStats(data);
});

/// Provider for personal bests.
final personalBestsProvider = Provider<PersonalBests?>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getPersonalBests(data);
});

/// Provider for best day stats.
final bestDayStatsProvider = Provider<BestDayStats?>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getBestDayStats(data);
});

/// Provider for workout momentum.
final workoutMomentumProvider = Provider<WorkoutMomentum?>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getWorkoutMomentum(data);
});

/// Provider for weekend vs weekday sleep stats.
final weekendSleepStatsProvider = Provider<WeekendSleepStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getWeekendSleepStats(data);
});

/// Provider for activity momentum (steps on workout vs rest days).
final activityMomentumStatsProvider = Provider<ActivityMomentumStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getActivityMomentumStats(data);
});

/// Provider for sleep consistency metrics.
final sleepConsistencyStatsProvider = Provider<SleepConsistencyStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getSleepConsistencyStats(data);
});

/// Provider for app-health correlations.
final appHealthCorrelationsProvider = Provider<List<AppHealthCorrelation>>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getAppHealthCorrelations(data);
});

/// Provider for recovery sleep stats.
final recoverySleepStatsProvider = Provider<RecoverySleepStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getRecoverySleepStats(data);
});

/// Provider for workout streak stats.
final workoutStreakStatsProvider = Provider<WorkoutStreakStats>((ref) {
  final data = ref.watch(allTimeDataProvider);
  return getWorkoutStreakStats(data);
});

