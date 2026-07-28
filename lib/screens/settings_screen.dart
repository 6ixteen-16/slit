/// Settings Screen
///
/// A screen for configuring system settings including thresholds,
/// timeouts, and calibration options.
///
/// Purpose: Allow users to customize system behavior by adjusting
/// ambient light thresholds, dim timeouts, and other parameters.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:smart_light/models/settings.dart';
import 'package:smart_light/widgets/custom_button.dart';

/// Settings Screen
///
/// Provides configuration options for system settings.
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings _currentSettings;
  bool _isSaving = false;
  bool _isCheckingEsp32 = false;
  bool _useThingSpeak = true;
  String _esp32Host = '';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SystemProvider>(context, listen: false);
    _currentSettings = provider.settings;
    _useThingSpeak = provider.useThingSpeak;
    _esp32Host = provider.esp32Host;
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
              title: const Text('Settings'),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    Provider.of<SystemProvider>(context, listen: false).toggleTheme();
                  },
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                ),
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: _restoreDefaults,
                  tooltip: 'Restore Defaults',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Source Selection
            _SettingsSection(
              title: 'Data Source',
              icon: Icons.cloud,
              children: [
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
                        Icon(
                          Icons.cloud_queue,
                          color: isDark ? AppColors.secondary : AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use ThingSpeak Cloud',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _useThingSpeak
                                    ? 'Receiving data from ThingSpeak cloud'
                                    : 'Using direct ESP32 connection',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _useThingSpeak,
                          onChanged: (value) {
                            setState(() {
                              _useThingSpeak = value;
                            });
                            final provider = Provider.of<SystemProvider>(
                                context,
                                listen: false);
                            provider.toggleThingSpeak(value);
                          },
                          activeColor: isDark ? AppColors.secondary : AppColors.primary,
                          activeTrackColor: isDark ? AppColors.secondary.withOpacity(0.5) : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsTextField(
                  label: 'ESP32 local IP address',
                  value: _esp32Host,
                  onChanged: (value) => setState(() => _esp32Host = value),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Required for Auto/Manual mode, brightness, and settings. Find it in the ESP32 serial monitor after Wi-Fi connects.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isCheckingEsp32 ? null : _saveAndTestEsp32,
                  icon: _isCheckingEsp32
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(_isCheckingEsp32
                      ? 'Checking ESP32…'
                      : 'Save & test ESP32'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Ambient Light Thresholds
            _SettingsSection(
              title: 'Ambient Light Thresholds',
              icon: Icons.light_mode,
              children: [
                _SettingsTextField(
                  label: 'Turn on below (lux)',
                  hintText: '0 - 65535 lux',
                  value: _currentSettings.darkThreshold.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          darkThreshold: intValue,
                        );
                      });
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsTextField(
                  label: 'Turn off above (lux)',
                  hintText: '0 - 65535 lux',
                  value: _currentSettings.brightThreshold.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          brightThreshold: intValue,
                        );
                      });
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Timeout Settings
            _SettingsSection(
              title: 'Timeout Settings',
              icon: Icons.timer,
              children: [
                _SettingsTextField(
                  label: 'First dim after',
                  hintText: '10 - 3600 seconds',
                  value: _currentSettings.dimLevel1Timeout.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          dimLevel1Timeout: intValue,
                        );
                      });
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsTextField(
                  label: 'Second dim after',
                  hintText: '10 - 3600 seconds',
                  value: _currentSettings.dimLevel2Timeout.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          dimLevel2Timeout: intValue,
                        );
                      });
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsTextField(
                  label: 'Third dim after',
                  hintText: '10 - 3600 seconds',
                  value: _currentSettings.dimLevel3Timeout.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          dimLevel3Timeout: intValue,
                        );
                      });
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsTextField(
                  label: 'Switch off after',
                  hintText: '10 - 3600 seconds',
                  value: _currentSettings.sleepTimeout.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          sleepTimeout: intValue,
                        );
                      });
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Transition settings
            _SettingsSection(
              title: 'Light transition',
              icon: Icons.tune,
              children: [
                _SettingsTextField(
                  label: 'Fade Speed',
                  hintText: '1 - 255',
                  value: _currentSettings.fadeSpeed.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          fadeSpeed: intValue,
                        );
                      });
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(height: AppSpacing.lg),

            // Save Button
            CustomButton(
              text: 'Save Settings',
              icon: Icons.save,
              onPressed: _saveSettings,
              variant: ButtonVariant.primary,
              fullWidth: true,
              isLoading: _isSaving,
            ),
            const SizedBox(height: AppSpacing.md),

            // Validation Warning
            if (!_currentSettings.isValid)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                ),
                color: AppColors.error.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Some settings have invalid values. Please check the thresholds and timeouts.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Save settings
  Future<void> _saveSettings() async {
    if (!_currentSettings.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid settings. Please check your values.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<SystemProvider>(context, listen: false);
    final success = await provider.updateSettings(_currentSettings);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: ${provider.errorMessage}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Restore default settings
  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Defaults'),
        content: const Text(
          'Are you sure you want to restore all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.primary,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.primary,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final provider = Provider.of<SystemProvider>(context, listen: false);
      final success = await provider.restoreDefaultSettings();

      if (!mounted) return;

      if (success) {
        setState(() {
          _currentSettings = Settings.defaultSettings();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default settings restored'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to restore defaults: ${provider.errorMessage}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveAndTestEsp32() async {
    setState(() => _isCheckingEsp32 = true);
    final provider = Provider.of<SystemProvider>(context, listen: false);
    final connected = await provider.setEsp32Host(_esp32Host);
    if (!mounted) return;
    setState(() => _isCheckingEsp32 = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(connected
            ? 'ESP32 connected at ${provider.esp32Host}'
            : provider.errorMessage ?? 'Could not reach the ESP32.'),
        backgroundColor: connected ? AppColors.success : AppColors.error,
      ),
    );
  }
}

/// Settings Section
///
/// Internal widget for grouping related settings.
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: isDark ? AppColors.secondary : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.headline3.copyWith(
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings Text Field
///
/// Internal widget for settings input fields.
class _SettingsTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final String? hintText;

  const _SettingsTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.keyboardType,
    this.hintText,
  });

  @override
  State<_SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<_SettingsTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SettingsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.hintText,
        helperStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        filled: true,
        fillColor:
            isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      onChanged: widget.onChanged,
    );
  }
}
