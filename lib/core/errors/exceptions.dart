/// Custom exceptions for the application.
///
/// This file contains application-specific exception classes
/// that extend [Exception] for better error handling.
class AppException implements Exception {
  /// Creates an [AppException] with the given [message] and optional [code].
  const AppException(this.message, [this.code]);

  /// Error message
  final String message;

  /// Optional error code
  final String? code;

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when a network request fails.
class NetworkException extends AppException {
  /// Creates a [NetworkException] with the given [message] and optional [code].
  const NetworkException(super.message, [super.code]);
}

/// Exception thrown when data parsing fails.
class ParseException extends AppException {
  /// Creates a [ParseException] with the given [message] and optional [code].
  const ParseException(super.message, [super.code]);
}

/// Exception thrown when a cache operation fails.
class CacheException extends AppException {
  /// Creates a [CacheException] with the given [message] and optional [code].
  const CacheException(super.message, [super.code]);
}
