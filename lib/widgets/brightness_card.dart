/// Brightness Card Widget
/// 
/// A specialized card widget for displaying brightness information
/// with a visual progress indicator.
/// 
/// Purpose: Provide a visual representation of current brightness
/// level with a progress bar and percentage display.

import 'package:flutter/material.dart';
import 'package:smart_light/utils/constants.dart';

/// Brightness Card
/// 
/// A card widget that displays brightness information with a
/// progress indicator and percentage.
/// 
/// Parameters:
/// - [brightness]: Current brightness value (0-100)
/// - [label]: Text label for the card (optional)
/// - [color]: Accent color for the progress bar (optional)
class BrightnessCard extends StatelessWidget {
  final int brightness;
  final String? label;
  final Color? color;

  const BrightnessCard({
    super.key,
    required this.brightness,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? AppColors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayLabel = label ?? 'Brightness';

    return Card(
      elevation: 2,
      color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              displayLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Brightness percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$brightness%',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.brightness_6,
                  color: accentColor,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              child: LinearProgressIndicator(
                value: brightness / 100,
                backgroundColor: isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
