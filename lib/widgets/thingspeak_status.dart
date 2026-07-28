/// ThingSpeak Status Widget
/// 
/// Displays ThingSpeak cloud connection status with visual indicators.
/// 
/// Purpose: Provide users with clear feedback on ThingSpeak connectivity
/// and data source status.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';

/// ThingSpeak Status Widget
/// 
/// Shows ThingSpeak connection status with icon, color, and label.
class ThingSpeakStatusWidget extends StatelessWidget {
  final bool compact;

  const ThingSpeakStatusWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SystemProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isThingSpeakConnected = provider.isThingSpeakConnected;
    final isOffline = provider.isOffline;
    final useThingSpeak = provider.useThingSpeak;

    if (compact) {
      return _buildCompactIndicator(
        isThingSpeakConnected,
        isOffline,
        useThingSpeak,
      );
    }

    return Card(
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
            _buildIcon(isThingSpeakConnected, isOffline, useThingSpeak),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ThingSpeak Cloud',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _getStatusText(isThingSpeakConnected, isOffline, useThingSpeak),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusIndicator(
              isThingSpeakConnected,
              isOffline,
              useThingSpeak,
            ),
          ],
        ),
      ),
    );
  }

  /// Build compact indicator
  Widget _buildCompactIndicator(
    bool isConnected,
    bool isOffline,
    bool useThingSpeak,
  ) {
    if (!useThingSpeak) {
      return const Tooltip(
        message: 'ThingSpeak disabled',
        child: Icon(
          Icons.cloud_off,
          color: AppColors.textSecondary,
          size: 20,
        ),
      );
    }

    if (isOffline) {
      return const Tooltip(
        message: 'Offline',
        child: Icon(
          Icons.wifi_off,
          color: AppColors.error,
          size: 20,
        ),
      );
    }

    if (isConnected) {
      return const Tooltip(
        message: 'Connected to ThingSpeak',
        child: Icon(
          Icons.cloud_done,
          color: AppColors.success,
          size: 20,
        ),
      );
    }

    return const Tooltip(
      message: 'Connecting to ThingSpeak...',
      child: Icon(
        Icons.cloud_sync,
        color: AppColors.warning,
        size: 20,
      ),
    );
  }

  /// Build status icon
  Widget _buildIcon(
    bool isConnected,
    bool isOffline,
    bool useThingSpeak,
  ) {
    if (!useThingSpeak) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
        ),
        child: const Icon(
          Icons.cloud_off,
          color: AppColors.textSecondary,
        ),
      );
    }

    if (isOffline) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: const Icon(
          Icons.wifi_off,
          color: AppColors.error,
        ),
      );
    }

    if (isConnected) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: const Icon(
          Icons.cloud_done,
          color: AppColors.success,
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: const Icon(
        Icons.cloud_sync,
        color: AppColors.warning,
      ),
    );
  }

  /// Build status indicator
  Widget _buildStatusIndicator(
    bool isConnected,
    bool isOffline,
    bool useThingSpeak,
  ) {
    Color color;
    String text;

    if (!useThingSpeak) {
      color = AppColors.textSecondary;
      text = 'Disabled';
    } else if (isOffline) {
      color = AppColors.error;
      text = 'Offline';
    } else if (isConnected) {
      color = AppColors.success;
      text = 'Connected';
    } else {
      color = AppColors.warning;
      text = 'Connecting';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get status text
  String _getStatusText(
    bool isConnected,
    bool isOffline,
    bool useThingSpeak,
  ) {
    if (!useThingSpeak) {
      return 'Using direct ESP32 connection';
    }
    if (isOffline) {
      return 'No internet connection';
    }
    if (isConnected) {
      return 'Receiving live data from cloud';
    }
    return 'Attempting to connect...';
  }
}
