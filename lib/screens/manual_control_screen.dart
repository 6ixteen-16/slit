/// Manual Control Screen
/// 
/// A screen for manual control of the lighting system with mode
/// switching and brightness slider control.
/// 
/// Purpose: Allow users to switch between auto and manual modes
/// and manually control LED brightness when in manual mode.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:smart_light/widgets/custom_slider.dart';
import 'package:smart_light/widgets/brightness_card.dart';
import 'package:smart_light/widgets/animated_light.dart';

/// Manual Control Screen
/// 
/// Provides mode switching and manual brightness control.
class ManualControlScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ManualControlScreen({super.key, this.onBack});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  double _brightnessValue = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SystemProvider>(context, listen: false);
    _brightnessValue = provider.systemStatus.brightness.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            child: AppBar(
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                    )
                  : null,
              title: const Text('System Control'),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    Provider.of<SystemProvider>(context, listen: false).toggleTheme();
                  },
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          final status = provider.systemStatus;
          final isConnected = status.isConnected;
          final isManualMode = status.isManualMode;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disconnected banner
                if (!isConnected) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppBorderRadius.card),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'No connection — controls are disabled until the device is reachable.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Mode Selection
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operating Mode',
                          style: AppTextStyles.headline3.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeButton(
                                label: 'Auto Mode',
                                icon: Icons.autorenew,
                                isSelected: !isManualMode,
                                onTap: isConnected ? () => _switchMode(OperatingMode.auto) : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _ModeButton(
                                label: 'Manual Mode',
                                icon: Icons.touch_app,
                                isSelected: isManualMode,
                                onTap: isConnected ? () => _switchMode(OperatingMode.manual) : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Current Brightness Display
                AnimatedLight(
                  brightness: isConnected ? status.brightness : 0,
                  size: 100,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: BrightnessCard(
                    brightness: isConnected ? status.brightness : 0,
                    label: isConnected ? 'Current Brightness' : 'Brightness (Disconnected)',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Manual Control Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Manual Brightness Control',
                                style: AppTextStyles.headline3.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (!isManualMode)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  'Disabled in Auto Mode',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Brightness Slider
                        CustomSlider(
                          value: _brightnessValue,
                          min: AppSliderConfig.min,
                          max: AppSliderConfig.max,
                          divisions: AppSliderConfig.divisions,
                          label: 'Brightness',
                          color: AppColors.accent,
                          enabled: isConnected && isManualMode && !_isSending,
                          showValue: true,
                          onChanged: isConnected && isManualMode
                              ? (value) {
                                  setState(() {
                                    _brightnessValue = value;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Apply Button
                        _GradientButton(
                          text: 'Apply Brightness',
                          icon: Icons.check,
                          onPressed: isConnected && isManualMode
                              ? () => _applyBrightness()
                              : null,
                          isLoading: _isSending,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Quick Presets
                if (isConnected && isManualMode) ...[
                  Text(
                    'Quick Presets',
                    style: AppTextStyles.headline3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _PresetButton(
                          label: '25%',
                          value: 25,
                          onTap: () => _setPreset(25),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PresetButton(
                          label: '50%',
                          value: 50,
                          onTap: () => _setPreset(50),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PresetButton(
                          label: '75%',
                          value: 75,
                          onTap: () => _setPreset(75),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PresetButton(
                          label: '100%',
                          value: 100,
                          onTap: () => _setPreset(100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Info Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  ),
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            !isConnected
                                ? 'No connection to the device. Connect to the same network as the ESP32, or ensure ThingSpeak is enabled and the device is online.'
                                : isManualMode
                                    ? 'In manual mode, you have full control over the LED brightness. Use the slider or quick presets to adjust brightness.'
                                    : 'Switch to manual mode to take control of the LED brightness. In auto mode, the ESP32 controls brightness based on ambient light and presence.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Switch operating mode
  Future<void> _switchMode(String mode) async {
    final provider = Provider.of<SystemProvider>(context, listen: false);
    
    final success = await provider.setMode(mode);
    
    if (!mounted) return;

    if (success) {
      if (mode == OperatingMode.manual) {
        setState(() {
          _brightnessValue = provider.systemStatus.brightness.toDouble();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == OperatingMode.auto
                ? 'Switched to Auto Mode'
                : 'Switched to Manual Mode',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch mode: ${provider.errorMessage}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Apply brightness setting
  Future<void> _applyBrightness() async {
    setState(() {
      _isSending = true;
    });

    final provider = Provider.of<SystemProvider>(context, listen: false);
    final brightness = _brightnessValue.round();

    final success = await provider.setManualBrightness(brightness);

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Brightness set to $brightness%'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set brightness: ${provider.errorMessage}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Set preset brightness
  void _setPreset(int value) {
    setState(() {
      _brightnessValue = value.toDouble();
    });
    _applyBrightness();
  }
}

/// Mode Button
/// 
/// Internal widget for mode selection buttons.
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    BoxDecoration decoration;
    Color textColor;
    Color iconColor;

    if (isSelected) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        color: isDark ? AppColors.secondary : null,
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [AppColors.secondary, AppColors.accent],
              ),
        border: Border.all(color: Colors.transparent, width: 2),
      );
      textColor = AppColors.primaryDark; // Dark text on light cyan
      iconColor = AppColors.primaryDark;
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        color: isDark ? AppColors.primary : AppColors.cardBackground,
        border: Border.all(
          color: isDark ? AppColors.primaryLight : AppColors.textDisabled.withValues(alpha: 0.3),
          width: 2,
        ),
      );
      textColor = isDark ? Colors.white : AppColors.textPrimary;
      iconColor = isDark ? Colors.white : AppColors.primary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: decoration,
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preset Button
/// 
/// Internal widget for quick preset buttons.
class _PresetButton extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      color: isDark ? AppColors.secondary : null,
      gradient: isDark
          ? null
          : const LinearGradient(
              colors: [AppColors.secondary, AppColors.accent],
            ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
        ),
        decoration: decoration,
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient Button
///
/// Internal widget replacing CustomButton for Apply Brightness
/// to support gradients and specialized disabled states.
class _GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !isLoading;

    final decoration = enabled
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            color: isDark ? AppColors.secondary : null,
            gradient: isDark
                ? null
                : const LinearGradient(
                    colors: [AppColors.secondary, AppColors.accent],
                  ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            color: isDark ? Colors.white12 : Colors.black12,
          );

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(AppBorderRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    enabled ? AppColors.primaryDark : AppColors.textDisabled,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: enabled ? AppColors.primaryDark : AppColors.textDisabled,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: enabled ? AppColors.primaryDark : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
