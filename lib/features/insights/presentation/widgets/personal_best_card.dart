import 'package:altu_life/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card displaying a personal best record.
class PersonalBestCard extends StatelessWidget {
  const PersonalBestCard({
    super.key,
    required this.label,
    required this.value,
    required this.date,
  });

  final String label;
  final String value;
  final String date;

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(date);

    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slate400,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.slate800,
            ),
          ),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.brand600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.MMMd().format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

