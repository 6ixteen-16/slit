/// Monitoring Screen
///
/// A real-time monitoring screen that displays current system metrics
/// sourced directly from the SystemProvider (ThingSpeak or ESP32).
///
/// Purpose: Provide continuous real-time monitoring of all system
/// metrics without requiring manual refresh.
library;

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

/// Monitoring Screen
///
/// Displays current system metrics at the firmware telemetry cadence.
class LiveMonitorScreen extends StatelessWidget {
  const LiveMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LiveMonitorView();
  }
}

class _LiveMonitorView extends StatelessWidget {
  const _LiveMonitorView();

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
        return state.isEmpty ? '--' : state;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SystemProvider>(
      builder: (context, provider, child) {
        final status = provider.systemStatus;
        final isPaused = provider.isPaused;
        final isConnected = status.isConnected;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Monitoring'),
            elevation: 0,
            actions: [
              // Dark/light mode toggle — visible on all screens
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => provider.toggleTheme(),
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              ),
              // Connection status chip
              ConnectionStatusWidget(
                status: provider.connectionStatus,
                compact: true,
              ),
              const SizedBox(width: AppSpacing.xs),
              // Pause / Resume button — uses provider-level isPaused
              IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () {
                  if (isPaused) {
                    provider.resumePolling();
                  } else {
                    provider.pausePolling();
                  }
                },
                tooltip: isPaused ? 'Resume Updates' : 'Pause Updates',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live / Paused indicator row
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPaused
                            ? AppColors.warning
                            : (isConnected
                                ? AppColors.success
                                : AppColors.error),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isPaused
                          ? 'Updates Paused'
                          : (isConnected ? 'Live Updates' : 'No Connection'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Every ${ThingSpeakConfig.updateInterval ~/ 1000}s',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Animated Light + System Status card ─────────────────
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedLight(
                          brightness: isConnected ? status.brightness : 0,
                          size: 80,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Presence row
                              Row(
                                children: [
                                  Icon(
                                    isConnected
                                        ? (status.presence
                                            ? Icons.person
                                            : Icons.person_outline)
                                        : Icons.person_off_outlined,
                                    color: isConnected
                                        ? (status.presence
                                            ? AppColors.success
                                            : AppColors.error)
                                        : AppColors.textDisabled,
                                    size: 22,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      isConnected
                                          ? (status.presence
                                              ? 'Presence Detected'
                                              : 'No Presence')
                                          : 'Unknown',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Mode
                              StateIndicator(
                                state: isConnected ? status.mode : 'unknown',
                                label: isConnected
                                    ? (status.mode == OperatingMode.auto
                                        ? 'Auto Mode'
                                        : 'Manual Mode')
                                    : 'Disconnected',
                                showIcon: true,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // State machine state
                              StateIndicator(
                                state: isConnected ? status.state : 'off',
                                label: isConnected
                                    ? _formatState(status.state)
                                    : 'Offline',
                                showIcon: true,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Timestamp
                              Text(
                                isConnected
                                    ? 'Updated: ${DateFormat('HH:mm:ss').format(status.lastUpdated)}'
                                    : 'No data',
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

                // ── Sensor Metrics ──────────────────────────────────────
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
                    SensorCard(
                      icon: Icons.light_mode,
                      label: 'Ambient Light',
                      value: isConnected
                          ? status.ambientLight.toStringAsFixed(1)
                          : '--',
                      unit: 'lux',
                      color: AppColors.warning,
                    ),
                    SensorCard(
                      icon: Icons.brightness_6,
                      label: 'Brightness',
                      value: isConnected ? status.brightness.toString() : '--',
                      unit: '%',
                      color: AppColors.accent,
                    ),
                    // PWM card — #ADDFF1 icon in dark mode
                    SensorCard(
                      icon: Icons.tune,
                      label: 'PWM Value',
                      value: isConnected ? status.pwmValue.toString() : '--',
                      color: isDark ? AppColors.secondary : AppColors.primary,
                    ),
                    // Connection card — FittedBox prevents overflow
                    _ConnectionCard(isConnected: isConnected),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Current Brightness progress bar ─────────────────────
                BrightnessCard(
                  brightness: isConnected ? status.brightness : 0,
                  label: isConnected
                      ? 'Current Brightness'
                      : 'Brightness (Disconnected)',
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── System Information ───────────────────────────────────
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
                          value: isConnected
                              ? status.mode.toUpperCase()
                              : '--',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'System State',
                          value: isConnected
                              ? _formatState(status.state)
                              : '--',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Presence',
                          value: isConnected
                              ? (status.presence ? 'Detected' : 'Not Detected')
                              : '--',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Ambient Light',
                          value: isConnected
                              ? '${status.ambientLight.toStringAsFixed(1)} lux'
                              : '--',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Brightness',
                          value: isConnected
                              ? '${status.brightness}%'
                              : '--',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'PWM',
                          value: isConnected
                              ? status.pwmValue.toString()
                              : '--',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Connection',
                          value: status.connectionStatus.toUpperCase(),
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Last Update',
                          value: isConnected
                              ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                  .format(status.lastUpdated)
                              : '--',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Connection Card ─────────────────────────────────────────────────────────

/// Renders the Connection status sensor card with FittedBox to
/// prevent the "Disconnected" text from overflowing.
class _ConnectionCard extends StatelessWidget {
  final bool isConnected;
  const _ConnectionCard({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isConnected ? AppColors.success : AppColors.error;

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Connection',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: AppTextStyles.headline3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Information Row ──────────────────────────────────────────────────────────

/// Internal widget for displaying labelled information rows.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
