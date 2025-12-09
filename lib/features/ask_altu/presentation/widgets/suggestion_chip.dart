import 'package:altu_life/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Suggestion chip for quick prompts.
class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    super.key,
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.brand50 : AppColors.slate100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled ? AppColors.brand100 : AppColors.slate200,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isEnabled ? AppColors.brand700 : AppColors.slate400,
          ),
        ),
      ),
    );
  }
}

