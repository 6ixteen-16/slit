import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smart_light/utils/constants.dart';

class RadialMenu extends StatefulWidget {
  final List<RadialMenuItem> items;
  final IconData openIcon;
  final IconData closeIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const RadialMenu({
    super.key,
    required this.items,
    this.openIcon = Icons.menu,
    this.closeIcon = Icons.close,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _translation;
  late Animation<double> _scale;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translation = Tween<double>(begin: 0.0, end: 120.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _handleItemTap(VoidCallback onTap) {
    _toggleMenu();
    // Small delay to let the menu start closing before navigating
    Future.delayed(const Duration(milliseconds: 150), onTap);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppColors.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The items
          ...List.generate(widget.items.length, (index) {
            // Angles from PI (left) to 0 (right)
            // If 3 items: 180, 90, 0. If 4 items: 180, 120, 60, 0
            double angle = math.pi;
            if (widget.items.length > 1) {
              angle = math.pi - (math.pi / (widget.items.length - 1) * index);
            }
            return _buildRadialItem(widget.items[index], angle);
          }),
          // The main toggle button
          Transform.translate(
            offset: const Offset(0, -20),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotation.value * math.pi,
                  child: FloatingActionButton(
                    heroTag: 'radial_menu_main',
                    onPressed: _toggleMenu,
                    backgroundColor: bgColor,
                    foregroundColor: fgColor,
                    elevation: 8,
                    child: Icon(_isOpen ? widget.closeIcon : widget.openIcon),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialItem(RadialMenuItem item, double angle) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double x = math.cos(angle) * _translation.value;
        final double y = -math.sin(angle) * _translation.value;

        return Transform.translate(
          offset: Offset(x, y - 20), // -20 to match the main button's offset
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _scale.value.clamp(0.0, 1.0),
              child: FloatingActionButton.small(
                heroTag: 'radial_menu_item_${item.label}',
                onPressed: () => _handleItemTap(item.onTap),
                backgroundColor: item.backgroundColor ?? AppColors.surface,
                foregroundColor: item.foregroundColor ?? AppColors.primary,
                elevation: 4,
                tooltip: item.label,
                child: Icon(item.icon),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RadialMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  RadialMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });
}
