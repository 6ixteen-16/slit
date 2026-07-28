/// Animated Light Widget
/// 
/// A widget that displays an animated light bulb that changes
/// brightness based on the current system brightness level.
/// 
/// Purpose: Provide a visual representation of the LED strip's
/// current brightness with smooth animations.

import 'package:flutter/material.dart';
import 'package:smart_light/utils/constants.dart';

/// Animated Light Widget
/// 
/// Displays an animated light bulb with brightness that corresponds
/// to the current system brightness level.
/// 
/// Parameters:
/// - [brightness]: Current brightness value (0-100)
/// - [size]: Size of the light bulb (default: 80)
/// - [color]: Light color (default: amber)
class AnimatedLight extends StatefulWidget {
  final int brightness;
  final double size;
  final Color? color;

  const AnimatedLight({
    super.key,
    required this.brightness,
    this.size = 80,
    this.color,
  });

  @override
  State<AnimatedLight> createState() => _AnimatedLightState();
}

class _AnimatedLightState extends State<AnimatedLight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _brightnessAnimation;
  int? _previousBrightness;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    _previousBrightness = widget.brightness;
    _brightnessAnimation = Tween<double>(
      begin: 0.0,
      end: widget.brightness / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedLight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.brightness != _previousBrightness) {
      _previousBrightness = widget.brightness;
      _brightnessAnimation = Tween<double>(
        begin: _brightnessAnimation.value,
        end: widget.brightness / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightColor = widget.color ?? AppColors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _brightnessAnimation,
      builder: (context, child) {
        final brightnessValue = _brightnessAnimation.value;
        final glowOpacity = brightnessValue * 0.6;
        final bulbOpacity = 0.3 + (brightnessValue * 0.7);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightColor.withOpacity(glowOpacity),
                ),
              ),
              // Light bulb icon
              Icon(
                Icons.lightbulb,
                size: widget.size,
                color: lightColor.withOpacity(bulbOpacity),
              ),
              // Off indicator when brightness is 0
              if (widget.brightness == 0)
                Icon(
                  Icons.power_off,
                  size: widget.size * 0.3,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
            ],
          ),
        );
      },
    );
  }
}
