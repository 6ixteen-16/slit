/// Connection Status Widget
/// 
/// A widget for displaying the connection status to the ESP32
/// with visual indicators and status text.
/// 
/// Purpose: Provide a clear visual representation of connection
/// status with appropriate colors and icons.
library;

import 'package:flutter/material.dart';
import 'package:smart_light/utils/constants.dart';

/// Connection Status Widget
/// 
/// Displays the current connection status with an icon and label.
/// 
/// Parameters:
/// - [status]: Connection status string ('connected', 'disconnected', 'connecting', 'error')
/// - [showLabel]: Whether to show the status label (default: true)
/// - [compact]: Whether to show a compact version (default: false)
class ConnectionStatusWidget extends StatelessWidget {
  final String status;
  final bool showLabel;
  final bool compact;

  const ConnectionStatusWidget({
    super.key,
    required this.status,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            color: statusInfo.color,
            size: 16,
          ),
          if (showLabel) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              statusInfo.label,
              style: AppTextStyles.caption.copyWith(
                color: statusInfo.color,
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: statusInfo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            color: statusInfo.color,
            size: 20,
          ),
          if (showLabel) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              statusInfo.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: statusInfo.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get status information (color, icon, label)
  _ConnectionStatusInfo _getStatusInfo(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'connected') {
      return _ConnectionStatusInfo(
        color: AppColors.success,
        icon: Icons.wifi,
        label: 'Connected',
      );
    } else if (statusLower == 'connecting') {
      return _ConnectionStatusInfo(
        color: AppColors.warning,
        icon: Icons.sync,
        label: 'Connecting...',
      );
    } else if (statusLower == 'error') {
      return _ConnectionStatusInfo(
        color: AppColors.error,
        icon: Icons.error_outline,
        label: 'Error',
      );
    } else {
      return _ConnectionStatusInfo(
        color: AppColors.error,
        icon: Icons.wifi_off,
        label: 'Disconnected',
      );
    }
  }
}

/// Internal class for connection status information
class _ConnectionStatusInfo {
  final Color color;
  final IconData icon;
  final String label;

  _ConnectionStatusInfo({
    required this.color,
    required this.icon,
    required this.label,
  });
}
