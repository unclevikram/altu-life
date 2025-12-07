/// Validation utilities for the application.
///
/// This file contains reusable validation functions for forms and data.
class Validators {
  /// Private constructor to prevent instantiation
  Validators._();

  /// Validates if a string is not empty.
  static String? notEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  /// Validates if a string is a valid email.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates if a string meets minimum length requirement.
  static String? minLength(String? value, int minLength) {
    if (value == null || value.length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }
}
