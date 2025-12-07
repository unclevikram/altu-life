/// Failure classes for functional programming error handling.
///
/// This file contains failure classes that represent error states
/// in a functional programming style, typically used with Either types.
abstract class Failure {
  /// Creates a [Failure] with the given [message].
  const Failure(this.message);

  /// Error message
  final String message;

  @override
  String toString() => 'Failure: $message';
}

/// Failure representing a server error.
class ServerFailure extends Failure {
  /// Creates a [ServerFailure] with the given [message].
  const ServerFailure(super.message);
}

/// Failure representing a network error.
class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure] with the given [message].
  const NetworkFailure(super.message);
}

/// Failure representing a cache error.
class CacheFailure extends Failure {
  /// Creates a [CacheFailure] with the given [message].
  const CacheFailure(super.message);
}

/// Failure representing a validation error.
class ValidationFailure extends Failure {
  /// Creates a [ValidationFailure] with the given [message].
  const ValidationFailure(super.message);
}
