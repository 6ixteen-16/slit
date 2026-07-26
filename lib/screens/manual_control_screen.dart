/// Manual Control Screen
/// 
/// A screen for manual control of the lighting system with mode
/// switching and brightness slider control.
/// 
/// Purpose: Allow users to switch between auto and manual modes
/// and manually control LED brightness when in manual mode.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:smart_light/widgets/custom_button.dart';
import 'package:smart_light/widgets/custom_slider.dart';
import 'package:smart_light/widgets/brightness_card.dart';
import 'package:smart_light/widgets/animated_light.dart';

/// Manual Control Screen
/// 
/// Provides mode switching and manual brightness control.
class ManualControlScreen extends StatefulWidget {
  const ManualControlScreen({super.key});

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
      appBar: AppBar(
        title: const Text('Manual Control'),
        elevation: 0,
      ),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          final status = provider.systemStatus;
          final isManualMode = status.isManualMode;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                onTap: () => _switchMode(OperatingMode.auto),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _ModeButton(
                                label: 'Manual Mode',
                                icon: Icons.touch_app,
                                isSelected: isManualMode,
                                onTap: () => _switchMode(OperatingMode.manual),
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
                  brightness: status.brightness,
                  size: 100,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: BrightnessCard(
                    brightness: status.brightness,
                    label: 'Current Brightness',
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
                            Text(
                              'Manual Brightness Control',
                              style: AppTextStyles.headline3.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
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
                          enabled: isManualMode && !_isSending,
                          showValue: true,
                          onChanged: isManualMode
                              ? (value) {
                                  setState(() {
                                    _brightnessValue = value;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Apply Button
                        CustomButton(
                          text: 'Apply Brightness',
                          icon: Icons.check,
                          onPressed: isManualMode
                              ? () => _applyBrightness()
                              : null,
                          variant: ButtonVariant.primary,
                          fullWidth: true,
                          isLoading: _isSending,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Quick Presets
                if (isManualMode) ...[
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
                            isManualMode
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
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.darkCardBackground
                  : AppColors.cardBackground),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: AppColors.primary,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
