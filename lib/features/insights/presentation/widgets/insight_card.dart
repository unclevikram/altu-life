import 'package:altu_life/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A card for displaying insights with optional icon, chart, and footer.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    required this.description,
    this.chart,
    this.footer,
  });

  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String description;
  final Widget? chart;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? AppColors.brand100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.brand700,
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
          if (chart != null) ...[
            const SizedBox(height: 16),
            chart!,
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

