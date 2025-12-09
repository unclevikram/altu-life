import 'dart:convert';

import 'package:altu_life/data/models/models.dart';
import 'package:flutter/services.dart';

/// Data loader for health and screen time data.
///
/// This class handles loading data from JSON asset files.
/// In production, this would be replaced with HealthKit and Screen Time API calls.
class DataLoader {
  DataLoader._();

  static DataLoader? _instance;
  static DataLoader get instance => _instance ??= DataLoader._();

  List<HealthDay>? _healthData;
  List<ScreenTimeEntry>? _screenTimeData;
  bool _isLoaded = false;

  /// Whether the data has been loaded.
  bool get isLoaded => _isLoaded;

  /// The loaded health data.
  List<HealthDay> get healthData => _healthData ?? [];

  /// The loaded screen time data.
  List<ScreenTimeEntry> get screenTimeData => _screenTimeData ?? [];

  /// Loads data from JSON asset files.
  ///
  /// This should be called during app initialization.
  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      // Load health data
      final healthJson = await rootBundle.loadString(
        'health_daily_L90D_ending_2025-11-30.json',
      );
      final healthList = jsonDecode(healthJson) as List<dynamic>;
      _healthData = healthList
          .map((e) => HealthDay.fromJson(e as Map<String, dynamic>))
          .toList();

      // Load screen time data
      final screenTimeJson = await rootBundle.loadString(
        'screentime_L90D_ending_2025-11-30.json',
      );
      final screenTimeList = jsonDecode(screenTimeJson) as List<dynamic>;
      _screenTimeData = screenTimeList
          .map((e) => ScreenTimeEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
    } catch (e) {
      // If loading fails, use fallback data
      _healthData = _fallbackHealthData;
      _screenTimeData = _fallbackScreenTimeData;
      _isLoaded = true;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FALLBACK DATA (used if JSON files fail to load)
// ─────────────────────────────────────────────────────────────────────────────

/// Fallback health data if JSON loading fails.
final List<HealthDay> _fallbackHealthData = [
  const HealthDay(date: '2025-09-02', steps: 8294, sleepMinutes: 410, activeEnergyKcal: 834, workoutMinutes: 31),
  const HealthDay(date: '2025-09-03', steps: 10732, sleepMinutes: 423, activeEnergyKcal: 1024, workoutMinutes: 47),
  const HealthDay(date: '2025-09-04', steps: 9511, sleepMinutes: 419, activeEnergyKcal: 567, workoutMinutes: 0),
  const HealthDay(date: '2025-09-05', steps: 9406, sleepMinutes: 429, activeEnergyKcal: 545, workoutMinutes: 0),
  const HealthDay(date: '2025-09-06', steps: 7417, sleepMinutes: 494, activeEnergyKcal: 948, workoutMinutes: 55),
  const HealthDay(date: '2025-09-07', steps: 4869, sleepMinutes: 496, activeEnergyKcal: 800, workoutMinutes: 59),
  const HealthDay(date: '2025-09-08', steps: 2245, sleepMinutes: 455, activeEnergyKcal: 277, workoutMinutes: 0),
  const HealthDay(date: '2025-10-25', steps: 8911, sleepMinutes: 458, activeEnergyKcal: 1366, workoutMinutes: 92),
];

/// Fallback screen time data if JSON loading fails.
final List<ScreenTimeEntry> _fallbackScreenTimeData = [
  const ScreenTimeEntry(date: '2025-09-02', app: 'YouTube', minutes: 27, category: 'Entertainment'),
  const ScreenTimeEntry(date: '2025-09-02', app: 'Spotify', minutes: 38, category: 'Entertainment'),
  const ScreenTimeEntry(date: '2025-09-02', app: 'Instagram', minutes: 14, category: 'Social'),
  const ScreenTimeEntry(date: '2025-09-02', app: 'Slack', minutes: 57, category: 'Productivity & Finance'),
];

// ─────────────────────────────────────────────────────────────────────────────
// CONVENIENCE GETTERS (for backward compatibility)
// ─────────────────────────────────────────────────────────────────────────────

/// Parsed health data as [HealthDay] objects.
List<HealthDay> get healthData => DataLoader.instance.healthData;

/// Parsed screen time data as [ScreenTimeEntry] objects.
List<ScreenTimeEntry> get screenTimeData => DataLoader.instance.screenTimeData;
