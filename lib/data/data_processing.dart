/// Data processing utilities for health and screen time analytics.
///
/// This barrel file re-exports all data processing modules for convenient access.
///
/// ## Modules:
/// - **aggregation**: Core data aggregation and date utilities
/// - **statistics**: Basic statistical calculations
/// - **correlation**: Pearson correlation and health metric relationships
/// - **sleep_analysis**: Sleep quality, trends, and consistency metrics
/// - **activity_analysis**: Personal bests, workout momentum, activity patterns
/// - **insights**: Health insights, goal tracking, and pattern analysis
/// - **calendar_data**: Calendar heatmaps and weekly trend visualization
///
/// ## Migration from monolithic file:
/// The original 1,355-line data_processing.dart has been split into focused
/// modules for better maintainability and testability.

// ─────────────────────────────────────────────────────────────────────────────
// CORE AGGREGATION & UTILITIES
// ─────────────────────────────────────────────────────────────────────────────

export 'processing/aggregation.dart';
export 'processing/statistics.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ANALYSIS MODULES
// ─────────────────────────────────────────────────────────────────────────────

export 'processing/correlation.dart';
export 'processing/sleep_analysis.dart';
export 'processing/activity_analysis.dart';
export 'processing/insights.dart';
export 'processing/calendar_data.dart';
