/// Health and activity goal constants used throughout the application.
///
/// This file centralizes all magic numbers and thresholds to improve
/// maintainability and make it easy to adjust goals and thresholds.

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// Target sleep duration in minutes (7 hours).
const int kSleepGoalMinutes = 420;

/// Minimum recommended sleep in minutes (6 hours).
const int kSleepMinimumMinutes = 360;

/// Optimal sleep duration in minutes (8 hours).
const int kSleepOptimalMinutes = 480;

/// Threshold for considering sleep as "short" (< 7 hours).
const int kSleepShortThreshold = 420;

/// Threshold for considering sleep as "long" (> 8 hours).
const int kSleepLongThreshold = 480;

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY & STEPS CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// Daily step goal.
const int kStepsGoal = 10000;

/// Minimum daily steps threshold.
const int kStepsMinimum = 5000;

/// Low activity threshold for steps.
const int kStepsLowActivityThreshold = 5000;

// ─────────────────────────────────────────────────────────────────────────────
// WORKOUT CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// Minimum workout duration in minutes to count as a workout day.
const int kWorkoutMinimumMinutes = 30;

/// Target workout duration in minutes.
const int kWorkoutGoalMinutes = 30;

// ─────────────────────────────────────────────────────────────────────────────
// CORRELATION CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// Minimum correlation coefficient to be considered significant.
const double kCorrelationSignificanceThreshold = 0.3;

/// Threshold for weak correlation.
const double kCorrelationWeakThreshold = 0.3;

/// Threshold for moderate correlation.
const double kCorrelationModerateThreshold = 0.5;

/// Threshold for strong correlation.
const double kCorrelationStrongThreshold = 0.7;

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR & TIME CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// Number of days in a week.
const int kDaysInWeek = 7;

/// Number of weeks typically shown in monthly view.
const int kWeeksInMonth = 4;

/// Minutes in an hour (for conversions).
const int kMinutesInHour = 60;

// ─────────────────────────────────────────────────────────────────────────────
// MOVING AVERAGE CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// Window size for 7-day moving average.
const int kMovingAverageWindow7Day = 7;

/// Window size for 30-day moving average.
const int kMovingAverageWindow30Day = 30;

// ─────────────────────────────────────────────────────────────────────────────
// SCORE & GOAL CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// Number of health goals to track daily.
const int kTotalHealthGoals = 3;

// ─────────────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the correlation strength label for a given correlation coefficient.
String getCorrelationStrength(double correlation) {
  final absCorr = correlation.abs();

  if (absCorr >= kCorrelationStrongThreshold) {
    return 'Strong';
  } else if (absCorr >= kCorrelationModerateThreshold) {
    return 'Moderate';
  } else if (absCorr >= kCorrelationWeakThreshold) {
    return 'Weak';
  } else {
    return 'None';
  }
}

/// Returns true if the correlation is considered significant.
bool isCorrelationSignificant(double correlation) {
  return correlation.abs() >= kCorrelationSignificanceThreshold;
}

/// Converts minutes to hours as a double.
double minutesToHours(int minutes) {
  return minutes / kMinutesInHour;
}

/// Returns the sleep quality category based on duration.
String getSleepQualityCategory(int sleepMinutes) {
  if (sleepMinutes < kSleepShortThreshold) {
    return '< 7h';
  } else if (sleepMinutes <= kSleepLongThreshold) {
    return '7-8h';
  } else {
    return '> 8h';
  }
}

/// Returns true if steps count is considered low activity.
bool isLowActivity(int steps) {
  return steps < kStepsLowActivityThreshold;
}

/// Returns true if it's a workout day (has workout minutes).
bool isWorkoutDay(int workoutMinutes) {
  return workoutMinutes >= kWorkoutMinimumMinutes;
}
