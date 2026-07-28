/// Custom Slider Widget
/// 
/// A reusable slider widget with consistent styling and
/// enhanced visual feedback.
/// 
/// Purpose: Provide a consistent slider component for brightness
/// and other value controls with Material 3 design.
library;

import 'package:flutter/material.dart';
import 'package:smart_light/utils/constants.dart';

/// Custom Slider
/// 
/// A customizable slider widget with enhanced styling and
/// visual feedback.
/// 
/// Parameters:
/// - [value]: Current slider value
/// - [onChanged]: Callback when slider value changes
/// - [min]: Minimum value (default: 0)
/// - [max]: Maximum value (default: 100)
/// - [divisions]: Number of discrete divisions (optional)
/// - [label]: Label to show when dragging (optional)
/// - [color]: Accent color for the slider (optional)
/// - [enabled]: Whether slider is enabled (default: true)
/// - [showValue]: Whether to display current value (default: true)
class CustomSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final Color? color;
  final bool enabled;
  final bool showValue;

  const CustomSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.label,
    this.color,
    this.enabled = true,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? AppColors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showValue)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label ?? 'Value',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                '${value.round()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        if (showValue) const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 20,
            ),
            activeTrackColor: accentColor,
            inactiveTrackColor: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
            valueIndicatorColor: accentColor,
            valueIndicatorTextStyle: AppTextStyles.caption.copyWith(
              color: Colors.white,
            ),
            disabledActiveTrackColor: AppColors.textDisabled.withValues(alpha: 0.5),
            disabledInactiveTrackColor: AppColors.textDisabled.withValues(alpha: 0.2),
            disabledThumbColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label ?? '${value.round()}',
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
