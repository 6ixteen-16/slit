/// State Indicator Widget
/// 
/// A visual indicator widget for displaying system state with
/// color-coded status and animations.
/// 
/// Purpose: Provide a clear visual representation of system state
/// with appropriate colors and animations.

import 'package:flutter/material.dart';
import 'package:smart_light/utils/constants.dart';

/// State Indicator
/// 
/// A widget that displays the current system state with a
/// color-coded indicator and label.
/// 
/// Parameters:
/// - [state]: Current system state string
/// - [label]: Optional custom label (defaults to state)
/// - [showIcon]: Whether to show an icon (default: true)
/// - [size]: Size of the indicator (default: medium)
class StateIndicator extends StatelessWidget {
  final String state;
  final String? label;
  final bool showIcon;
  final StateIndicatorSize size;

  const StateIndicator({
    super.key,
    required this.state,
    this.label,
    this.showIcon = true,
    this.size = StateIndicatorSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? state;
    final stateInfo = _getStateInfo(state);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final indicatorSize = switch (size) {
      StateIndicatorSize.small => 12.0,
      StateIndicatorSize.medium => 16.0,
      StateIndicatorSize.large => 24.0,
    };

    final iconSize = switch (size) {
      StateIndicatorSize.small => 16.0,
      StateIndicatorSize.medium => 20.0,
      StateIndicatorSize.large => 28.0,
    };

    final fontSize = switch (size) {
      StateIndicatorSize.small => 12.0,
      StateIndicatorSize.medium => 14.0,
      StateIndicatorSize.large => 16.0,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated indicator
        _AnimatedIndicator(
          color: stateInfo.color,
          size: indicatorSize,
        ),
        if (showIcon) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            stateInfo.icon,
            color: stateInfo.color,
            size: iconSize,
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        // Label
        Text(
          displayLabel,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Get state information (color and icon)
  _StateInfo _getStateInfo(String state) {
    switch (state.toLowerCase()) {
      case SystemState.active:
        return _StateInfo(
          color: AppColors.accent,  // Electric Cyan for ACTIVE
          icon: Icons.check_circle,
        );
      case SystemState.dim1:
        return _StateInfo(
          color: AppColors.secondary,  // Light Blue for DIM LEVEL 1
          icon: Icons.trending_down,
        );
      case SystemState.dim2:
        return _StateInfo(
          color: AppColors.warning,  // Orange for DIM LEVEL 2
          icon: Icons.trending_down,
        );
      case SystemState.sleep:
        return _StateInfo(
          color: AppColors.textDisabled,  // Grey for SLEEP
          icon: Icons.bedtime,
        );
      case SystemState.off:
        return _StateInfo(
          color: AppColors.error,  // Red for ERROR/OFF
          icon: Icons.power_off,
        );
      default:
        return _StateInfo(
          color: AppColors.textSecondary,
          icon: Icons.help,
        );
    }
  }
}

/// State Indicator Size
/// 
/// Enumeration of available indicator sizes.
enum StateIndicatorSize {
  small,
  medium,
  large,
}

/// Internal class for state information
class _StateInfo {
  final Color color;
  final IconData icon;

  _StateInfo({required this.color, required this.icon});
}

/// Animated Indicator
/// 
/// Internal widget for the pulsing indicator animation.
class _AnimatedIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedIndicator({
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedIndicator> createState() => _AnimatedIndicatorState();
}

class _AnimatedIndicatorState extends State<_AnimatedIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
