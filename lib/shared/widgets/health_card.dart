import 'package:altu_life/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A styled card matching the React app's card design.
///
/// Features white background, rounded corners, subtle border,
/// and optional header with icon.
class HealthCard extends StatelessWidget {
  const HealthCard({
    super.key,
    required this.child,
    this.padding,
    this.icon,
    this.iconColor,
    this.title,
    this.trailing,
    this.onTap,
  });

  /// The card's content.
  final Widget child;

  /// Custom padding for the card content.
  final EdgeInsetsGeometry? padding;

  /// Optional icon displayed in the header.
  final IconData? icon;

  /// Color for the icon (defaults to brand color).
  final Color? iconColor;

  /// Optional title displayed next to the icon.
  final String? title;

  /// Optional trailing widget in the header (e.g., a badge).
  final Widget? trailing;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasHeader = icon != null || title != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasHeader) ...[
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: iconColor ?? AppColors.brand600,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                        ),
                      ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact stat card for displaying key metrics.
///
/// Used in the top stats row on the Dashboard.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  /// The icon to display.
  final IconData icon;

  /// Color for the icon.
  final Color iconColor;

  /// The main value to display.
  final String value;

  /// The label below the value.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section header with icon and title.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
  });

  final IconData icon;
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final headerColor = color ?? AppColors.slate400;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: headerColor),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: headerColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A badge/chip for displaying labels.
class InfoBadge extends StatelessWidget {
  const InfoBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.slate400,
        ),
      ),
    );
  }
}

