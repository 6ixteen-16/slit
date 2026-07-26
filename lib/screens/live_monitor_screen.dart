/// Live Monitoring Screen
///
/// A real-time monitoring screen that updates every second with
/// the latest system status from the ESP32.
///
/// Purpose: Provide continuous real-time monitoring of all system
/// metrics without requiring manual refresh.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:smart_light/widgets/sensor_card.dart';
import 'package:smart_light/widgets/brightness_card.dart';
import 'package:smart_light/widgets/state_indicator.dart';
import 'package:smart_light/widgets/connection_status.dart';
import 'package:smart_light/widgets/animated_light.dart';
import 'package:intl/intl.dart';
import 'package:smart_light/config/thingspeak_config.dart';

/// Live Monitoring Screen
///
/// Displays current system metrics at the firmware telemetry cadence.
class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  Timer? _pollingTimer;
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  /// Start polling for updates
  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: ThingSpeakConfig.updateInterval),
      (_) => _refreshStatus(),
    );
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh system status
  Future<void> _refreshStatus() async {
    if (!mounted || !_isPolling) return;

    final provider = Provider.of<SystemProvider>(context, listen: false);
    await provider.refreshStatus();
  }

  /// Toggle polling
  void _togglePolling() {
    setState(() {
      _isPolling = !_isPolling;
      if (_isPolling) {
        _startPolling();
      } else {
        _stopPolling();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Monitoring'),
        elevation: 0,
        actions: [
          Consumer<SystemProvider>(
            builder: (context, provider, child) {
              return ConnectionStatusWidget(
                status: provider.connectionStatus,
                compact: true,
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(_isPolling ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePolling,
            tooltip: _isPolling ? 'Pause Updates' : 'Resume Updates',
          ),
        ],
      ),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          final status = provider.systemStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Indicator
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            _isPolling ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _isPolling ? 'Live Updates' : 'Updates Paused',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Updates every ${ThingSpeakConfig.updateInterval / 1000}s',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Animated Light and Status
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        AnimatedLight(
                          brightness: status.brightness,
                          size: 80,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Presence
                              Row(
                                children: [
                                  Icon(
                                    status.presence
                                        ? Icons.person
                                        : Icons.person_outline,
                                    color: status.presence
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    status.presence
                                        ? 'Presence Detected'
                                        : 'No Presence',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Mode and State
                              StateIndicator(
                                state: status.mode,
                                label: status.mode == OperatingMode.auto
                                    ? 'Auto Mode'
                                    : 'Manual Mode',
                                showIcon: true,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              StateIndicator(
                                state: status.state,
                                showIcon: true,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Timestamp
                              Text(
                                'Last Updated: ${DateFormat('HH:mm:ss').format(status.lastUpdated)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Sensor Metrics
                Text(
                  'Sensor Metrics',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.2,
                  children: [
                    // Ambient Light
                    SensorCard(
                      icon: Icons.light_mode,
                      label: 'Ambient Light',
                      value: status.ambientLight.toStringAsFixed(1),
                      unit: 'lux',
                      color: AppColors.warning,
                    ),
                    // Brightness
                    SensorCard(
                      icon: Icons.brightness_6,
                      label: 'Brightness',
                      value: status.brightness.toString(),
                      unit: '%',
                      color: AppColors.accent,
                    ),
                    // PWM
                    SensorCard(
                      icon: Icons.tune,
                      label: 'PWM Value',
                      value: status.pwmValue.toString(),
                      color: AppColors.primary,
                    ),
                    // Connection
                    SensorCard(
                      icon: status.isConnected ? Icons.wifi : Icons.wifi_off,
                      label: 'Connection',
                      value: status.isConnected ? 'Connected' : 'Disconnected',
                      color: status.isConnected
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Brightness Progress
                BrightnessCard(
                  brightness: status.brightness,
                  label: 'Current Brightness',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Detailed Information
                Text(
                  'System Information',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
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
                      children: [
                        _InfoRow(
                          label: 'Operating Mode',
                          value: status.mode.toUpperCase(),
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'System State',
                          value: _formatState(status.state),
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Presence',
                          value: status.presence ? 'Detected' : 'Not Detected',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Connection Status',
                          value: status.connectionStatus.toUpperCase(),
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Last Update',
                          value: DateFormat('yyyy-MM-dd HH:mm:ss')
                              .format(status.lastUpdated),
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

  /// Format state for display
  String _formatState(String state) {
    switch (state.toLowerCase()) {
      case SystemState.active:
        return 'Active';
      case SystemState.dim1:
        return 'Dim Level 1';
      case SystemState.dim2:
        return 'Dim Level 2';
      case SystemState.sleep:
        return 'Sleep Mode';
      case SystemState.off:
        return 'Off';
      default:
        return state;
    }
  }
}

/// Information Row
///
/// Internal widget for displaying information rows.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
