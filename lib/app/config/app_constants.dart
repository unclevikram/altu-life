/// Application-wide constants.
///
/// This file contains constants used throughout the application,
/// such as app name, version, timeout durations, etc.
class AppConstants {
  /// Private constructor to prevent instantiation
  AppConstants._();

  /// Application name
  static const String appName = 'Altu Life';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Default API timeout duration in seconds
  static const int apiTimeoutSeconds = 30;

  /// Default animation duration in milliseconds
  static const int defaultAnimationDurationMs = 300;
}
