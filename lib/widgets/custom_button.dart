/// Custom Button Widget
///
/// A reusable button widget with consistent styling and
/// support for different variants.
///
/// Purpose: Provide a consistent button component across the
/// application with Material 3 design.

import 'package:flutter/material.dart';
import 'package:smart_light/utils/constants.dart';

/// Button Variant
///
/// Enumeration of available button styles.
enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
  success,
}

/// Custom Button
///
/// A customizable button widget with support for different variants,
/// loading states, and icons.
///
/// Parameters:
/// - [text]: Button text
/// - [onPressed]: Callback when button is pressed
/// - [variant]: Button style variant (default: primary)
/// - [icon]: Optional icon to display
/// - [isLoading]: Whether to show loading indicator (default: false)
/// - [isDisabled]: Whether button is disabled (default: false)
/// - [fullWidth]: Whether button should take full width (default: false)
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !isDisabled && !isLoading;

    final buttonStyle = _getButtonStyle(variant, isDark);
    final textStyle = _getTextStyle(variant, isDark, enabled);

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(variant, isDark),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: _getTextColor(variant, isDark),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          text,
          style: textStyle,
        ),
      ],
    );

    if (fullWidth) {
      buttonChild = SizedBox(
        width: double.infinity,
        child: buttonChild,
      );
    }

    switch (variant) {
      case ButtonVariant.text:
        return TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: _getTextColor(variant, isDark),
            disabledForegroundColor: AppColors.textDisabled,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          child: buttonChild,
        );
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: _getTextColor(variant, isDark),
            side: BorderSide(
              color: enabled
                  ? _getBorderColor(variant, isDark)
                  : AppColors.textDisabled,
              width: 1.5,
            ),
            disabledForegroundColor: AppColors.textDisabled,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
            ),
          ),
          child: buttonChild,
        );
      default:
        return ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonStyle.backgroundColor,
            foregroundColor: buttonStyle.foregroundColor,
            disabledBackgroundColor: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            disabledForegroundColor: AppColors.textDisabled,
            elevation: buttonStyle.elevation,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
            ),
          ),
          child: buttonChild,
        );
    }
  }

  /// Get button style based on variant
  _ButtonStyle _getButtonStyle(ButtonVariant variant, bool isDark) {
    switch (variant) {
      case ButtonVariant.primary:
        return _ButtonStyle(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
        );
      case ButtonVariant.secondary:
        return _ButtonStyle(
          backgroundColor:
              AppColors.accent, // Electric Cyan for secondary buttons
          foregroundColor: AppColors.primaryDark, // Dark text for contrast
          elevation: 1,
        );
      case ButtonVariant.danger:
        return _ButtonStyle(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 2,
        );
      case ButtonVariant.success:
        return _ButtonStyle(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          elevation: 2,
        );
      default:
        return _ButtonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          elevation: 0,
        );
    }
  }

  /// Get text style based on variant
  TextStyle _getTextStyle(ButtonVariant variant, bool isDark, bool enabled) {
    final color = _getTextColor(variant, isDark);
    return AppTextStyles.button.copyWith(
      color: enabled ? color : AppColors.textDisabled,
    );
  }

  /// Get text color based on variant
  Color _getTextColor(ButtonVariant variant, bool isDark) {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.danger:
      case ButtonVariant.success:
        return Colors.white;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
      case ButtonVariant.outline:
        return AppColors.primary;
      case ButtonVariant.text:
        return AppColors.primary;
    }
  }

  /// Get border color based on variant
  Color _getBorderColor(ButtonVariant variant, bool isDark) {
    switch (variant) {
      case ButtonVariant.outline:
        return AppColors.primary;
      default:
        return Colors.transparent;
    }
  }
}

/// Internal class for button style
class _ButtonStyle {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  _ButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    required this.elevation,
  });
}
