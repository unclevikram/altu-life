import 'package:altu_life/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration.
///
/// Uses the Inter font family and colors extracted from the React
/// Altu Health app for pixel-perfect consistency.
class AppTheme {
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.brand500,
        primaryContainer: AppColors.brand100,
        secondary: AppColors.violet500,
        secondaryContainer: AppColors.violet100,
        surface: AppColors.cardBackground,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: textTheme.copyWith(
        // Display styles
        displayLarge: textTheme.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        // Headline styles
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        // Title styles
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        // Body styles
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppColors.slate600,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.slate600,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
        // Label styles
        labelLarge: textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brand600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppColors.brand500.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        selectedItemColor: AppColors.brand600,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brand50,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.brand700,
        ),
        side: const BorderSide(color: AppColors.brand100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  /// Dark theme configuration (not used in current React app but prepared)
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate900,
      colorScheme: ColorScheme.dark(
        primary: AppColors.brand500,
        primaryContainer: AppColors.brand900,
        secondary: AppColors.violet500,
        secondaryContainer: AppColors.violet700,
        surface: AppColors.slate800,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.slate800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.slate700),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.slate800.withValues(alpha: 0.8),
        selectedItemColor: AppColors.brand500,
        unselectedItemColor: AppColors.slate400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
