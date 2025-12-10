/// Environment configuration for the application.
///
/// This file contains environment-specific settings such as API endpoints,
/// feature flags, and other configuration values that may vary between
/// development, staging, and production environments.
class Environment {
  /// Current environment name (dev, staging, prod)
  static const String current = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// Whether debug mode is enabled
  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: true);
}
