/// API endpoints for the application.
///
/// This file contains all API endpoint paths used throughout the application.
/// TODO: Update endpoints as API is implemented.
class ApiEndpoints {
  /// Private constructor to prevent instantiation
  ApiEndpoints._();

  /// Base API path
  static const String base = '/api/v1';

  /// Authentication endpoints
  /// Login endpoint
  static const String login = '$base/auth/login';

  /// Logout endpoint
  static const String logout = '$base/auth/logout';

  /// Register endpoint
  static const String register = '$base/auth/register';

  /// User endpoints
  static const String users = '$base/users';

  /// Get user by ID endpoint
  static String userById(String id) => '$users/$id';
}
