/// Dashboard Screen
/// 
/// The main home screen of the application displaying an overview
/// of the intelligent lighting system status with large modern cards.
/// 
/// Purpose: Provide a comprehensive at-a-glance view of system status
/// including connection, presence, ambient light, brightness, and operating mode.
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
import 'package:smart_light/widgets/thingspeak_status.dart';
import 'package:intl/intl.dart';

/// Dashboard Screen
/// 
/// Displays system status cards and navigation to other screens.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start polling when dashboard is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SystemProvider>(context, listen: false);
      provider.startPolling();
    });
  }

  @override
  void dispose() {
    // Stop polling when dashboard is disposed
    final provider = Provider.of<SystemProvider>(context, listen: false);
    provider.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        elevation: 0,
        actions: [
          Consumer<SystemProvider>(
            builder: (context, provider, child) {
              return const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: ThingSpeakStatusWidget(compact: true),
              );
            },
          ),
          Consumer<SystemProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: ConnectionStatusWidget(
                  status: provider.connectionStatus,
                  compact: true,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingStatus) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final status = provider.systemStatus;

          return RefreshIndicator(
            onRefresh: () => provider.refreshAll(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Light and Presence Indicator
                  Row(
                    children: [
                      // Animated Light
                      AnimatedLight(
                        brightness: status.brightness,
                        size: 100,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Presence Indicator
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: status.presence
                                        ? AppColors.accent
                                        : AppColors.textDisabled,
                                    shape: BoxShape.circle,
                                    boxShadow: status.presence
                                        ? [
                                            BoxShadow(
                                              color: AppColors.accent.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
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
                            // Operating Mode
                            StateIndicator(
                              state: status.mode,
                              label: status.mode == OperatingMode.auto
                                  ? 'Auto Mode'
                                  : 'Manual Mode',
                              showIcon: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Last Updated
                            Text(
                              'Updated: ${_formatTime(status.lastUpdated)}',
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
                  const SizedBox(height: AppSpacing.lg),

                  // ThingSpeak Status Card
                  const ThingSpeakStatusWidget(),
                  const SizedBox(height: AppSpacing.lg),

                  // Sensor Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.2,
                    children: [
                      // Ambient Light Card
                      SensorCard(
                        icon: Icons.light_mode,
                        label: 'Ambient Light',
                        value: status.ambientLight.toStringAsFixed(1),
                        unit: 'lux',
                        color: AppColors.warning,
                      ),
                      // Brightness Card
                      SensorCard(
                        icon: Icons.brightness_6,
                        label: 'Brightness',
                        value: status.brightness.toString(),
                        unit: '%',
                        color: AppColors.accent,
                      ),
                      // PWM Card
                      SensorCard(
                        icon: Icons.tune,
                        label: 'PWM Value',
                        value: status.pwmValue.toString(),
                        color: AppColors.primary,
                      ),
                      // State Card
                      SensorCard(
                        icon: Icons.settings,
                        label: 'System State',
                        value: _formatState(status.state),
                        color: _getStateColor(status.state),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Brightness Progress Card
                  BrightnessCard(
                    brightness: status.brightness,
                    label: 'Current Brightness',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
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
                        child: _QuickActionButton(
                          icon: Icons.monitor_heart,
                          label: 'Live Monitor',
                          onTap: () {
                            Navigator.pushNamed(context, '/monitor');
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.touch_app,
                          label: 'Manual Control',
                          onTap: () {
                            Navigator.pushNamed(context, '/manual');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.bar_chart,
                          label: 'Statistics',
                          onTap: () {
                            Navigator.pushNamed(context, '/statistics');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.history,
                          label: 'Event Logs',
                          onTap: () {
                            Navigator.pushNamed(context, '/logs');
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.refresh,
                          label: 'Refresh',
                          onTap: () {
                            provider.refreshAll();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _navigateToScreen(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Navigate to screen based on index
  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, '/monitor');
        break;
      case 2:
        Navigator.pushNamed(context, '/manual');
        break;
      case 3:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  /// Format state for display
  String _formatState(String state) {
    switch (state.toLowerCase()) {
      case SystemState.active:
        return 'Active';
      case SystemState.dim1:
        return 'Dim 1';
      case SystemState.dim2:
        return 'Dim 2';
      case SystemState.sleep:
        return 'Sleep';
      case SystemState.off:
        return 'Off';
      default:
        return state;
    }
  }

  /// Get state color
  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case SystemState.active:
        return AppColors.accent;  // Electric Cyan for ACTIVE
      case SystemState.dim1:
        return AppColors.secondary;  // Light Blue for DIM LEVEL 1
      case SystemState.dim2:
        return AppColors.warning;  // Orange for DIM LEVEL 2
      case SystemState.sleep:
        return AppColors.textDisabled;  // Grey for SLEEP
      case SystemState.off:
        return AppColors.error;  // Red for ERROR/OFF
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Quick Action Button
/// 
/// Internal widget for quick action buttons on dashboard.
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardBackground
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.secondary,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
