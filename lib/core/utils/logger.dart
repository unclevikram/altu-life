/// Logger utility for the application.
///
/// This file provides a centralized logging mechanism for the application.
/// TODO: Implement a proper logging solution (e.g., logger package or Firebase Crashlytics).
class Logger {
  /// Logs a debug message.
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[DEBUG] $message');
    if (error != null) {
      // ignore: avoid_print
      print('[ERROR] $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('[STACKTRACE] $stackTrace');
    }
  }

  /// Logs an info message.
  static void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  /// Logs a warning message.
  static void warning(String message, [Object? error]) {
    // ignore: avoid_print
    print('[WARNING] $message');
    if (error != null) {
      // ignore: avoid_print
      print('[ERROR] $error');
    }
  }

  /// Logs an error message.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) {
      // ignore: avoid_print
      print('[ERROR DETAILS] $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('[STACKTRACE] $stackTrace');
    }
  }
}
