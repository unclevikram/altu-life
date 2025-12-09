/// Represents a single day of health data from HealthKit.
///
/// This model maps to the HealthDay interface in the React app
/// and contains the core health metrics for a given date.
class HealthDay {
  /// Creates a [HealthDay] instance.
  const HealthDay({
    required this.date,
    required this.steps,
    required this.sleepMinutes,
    required this.activeEnergyKcal,
    required this.workoutMinutes,
  });

  /// The date of this health record (YYYY-MM-DD format)
  final String date;

  /// Number of steps taken on this day
  final int steps;

  /// Total sleep duration in minutes
  final int sleepMinutes;

  /// Active energy burned in kilocalories
  final int activeEnergyKcal;

  /// Total workout duration in minutes
  final int workoutMinutes;

  /// Creates a [HealthDay] from a JSON map.
  factory HealthDay.fromJson(Map<String, dynamic> json) {
    return HealthDay(
      date: json['date'] as String,
      steps: json['steps'] as int,
      sleepMinutes: json['sleep_minutes'] as int,
      activeEnergyKcal: json['active_energy_kcal'] as int,
      workoutMinutes: json['workout_minutes'] as int,
    );
  }

  /// Converts this [HealthDay] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'steps': steps,
      'sleep_minutes': sleepMinutes,
      'active_energy_kcal': activeEnergyKcal,
      'workout_minutes': workoutMinutes,
    };
  }

  /// Creates a copy of this [HealthDay] with the given fields replaced.
  HealthDay copyWith({
    String? date,
    int? steps,
    int? sleepMinutes,
    int? activeEnergyKcal,
    int? workoutMinutes,
  }) {
    return HealthDay(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      activeEnergyKcal: activeEnergyKcal ?? this.activeEnergyKcal,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
    );
  }

  @override
  String toString() {
    return 'HealthDay(date: $date, steps: $steps, sleepMinutes: $sleepMinutes, '
        'activeEnergyKcal: $activeEnergyKcal, workoutMinutes: $workoutMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthDay &&
        other.date == date &&
        other.steps == steps &&
        other.sleepMinutes == sleepMinutes &&
        other.activeEnergyKcal == activeEnergyKcal &&
        other.workoutMinutes == workoutMinutes;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      steps,
      sleepMinutes,
      activeEnergyKcal,
      workoutMinutes,
    );
  }
}

