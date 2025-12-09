/// Represents a single screen time entry for an app on a specific day.
///
/// This model maps to the ScreenTimeEntry interface in the React app
/// and tracks usage of individual applications.
class ScreenTimeEntry {
  /// Creates a [ScreenTimeEntry] instance.
  const ScreenTimeEntry({
    required this.date,
    required this.app,
    required this.minutes,
    required this.category,
  });

  /// The date of this screen time record (YYYY-MM-DD format)
  final String date;

  /// The name of the application
  final String app;

  /// Usage duration in minutes
  final int minutes;

  /// Category of the application (e.g., "Entertainment", "Social", "Productivity & Finance")
  final String category;

  /// Creates a [ScreenTimeEntry] from a JSON map.
  factory ScreenTimeEntry.fromJson(Map<String, dynamic> json) {
    return ScreenTimeEntry(
      date: json['date'] as String,
      app: json['app'] as String,
      minutes: json['minutes'] as int,
      category: json['category'] as String,
    );
  }

  /// Converts this [ScreenTimeEntry] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'app': app,
      'minutes': minutes,
      'category': category,
    };
  }

  @override
  String toString() {
    return 'ScreenTimeEntry(date: $date, app: $app, minutes: $minutes, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenTimeEntry &&
        other.date == date &&
        other.app == app &&
        other.minutes == minutes &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(date, app, minutes, category);
}

