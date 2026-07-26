/// Application Constants
///
/// This file contains all application-wide constants including
/// UI values, animation durations, and configuration settings.
///
/// Purpose: Centralize constant values to ensure consistency
/// and ease of maintenance across the application.
library;

import 'package:flutter/material.dart';

/// App Information
///
/// Application metadata and version information.

const String appName = 'Smart Light';
const String appVersion = '1.0.0';
const String appDescription =
    'Adaptive Intelligent Energy-Efficient Lighting System';

/// Color Scheme
///
/// Official IoT Dashboard color palette for premium industrial appearance.
///
/// Primary: Deep Navy Blue (#003152) - Trust, intelligence, embedded technology
/// Secondary: Ice Blue (#ADDFF1) - Card backgrounds, clean appearance
/// Accent: Electric Cyan (#00E5FF) - Smart technology, live system activity
/// Success: Green (#22C55E) - Presence detected, connected, normal operation
/// Warning: Orange (#F59E0B) - Low light, waiting, calibration
/// Error: Red (#EF4444) - Disconnected, sensor failure, API error

class AppColors {
  AppColors._();

  // ─── Primary ─────────────────────────────────────────────────────────────
  // Vivid blue – clearly visible on both white and dark card surfaces.
  static const Color primary      = Color(0xFF1A56DB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark  = Color(0xFF1E40AF);

  // ─── Accent ──────────────────────────────────────────────────────────────
  // Warm amber – maximum contrast on light AND dark surfaces; used for
  // OutlinedButton borders, slider thumbs, active indicators.
  static const Color accent      = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark  = Color(0xFFD97706);

  // ─── Secondary ───────────────────────────────────────────────────────────
  static const Color secondary      = Color(0xFF0EA5E9);
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark  = Color(0xFF0284C7);

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successDark  = Color(0xFF16A34A);

  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark  = Color(0xFFD97706);

  static const Color error      = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark  = Color(0xFFDC2626);

  // ─── Light theme surfaces ─────────────────────────────────────────────────
  // Pure-white cards → navy/amber buttons always visible. No more ice-blue clash.
  static const Color background     = Color(0xFFF1F5F9);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ─── Light theme text ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textDisabled  = Color(0xFF94A3B8);

  // ─── Dark theme surfaces ──────────────────────────────────────────────────
  // Each layer is visibly lighter than the previous so cards, inputs, and
  // buttons always have clear contrast separation.
  static const Color darkBackground     = Color(0xFF0B1120);
  static const Color darkSurface        = Color(0xFF111827);
  static const Color darkCardBackground = Color(0xFF1C2B40);

  // ─── Dark theme text ─────────────────────────────────────────────────────
  static const Color darkTextPrimary   = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}

/// Typography
///
/// Text style constants for consistent typography across the app.

class AppTextStyles {
  AppTextStyles._();

  /// Headline Styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  /// Caption Styles
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  /// Button Styles
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

/// Spacing
///
/// Consistent spacing values for UI layout.

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border Radius
///
/// Consistent border radius values for rounded corners.
/// Cards use 18-22px radius for premium IoT dashboard appearance.

class AppBorderRadius {
  AppBorderRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 20.0; // Updated for card design (18-22px)
  static const double xl = 24.0;
  static const double card = 20.0; // Standard card radius
  static const double circle = 999.0;
}

/// Animation Durations
///
/// Standard animation durations for smooth transitions.

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);
}

/// Card Dimensions
///
/// Standard card sizes for consistent UI layout.

class AppCardDimensions {
  AppCardDimensions._();

  static const double minHeight = 120.0;
  static const double preferredHeight = 140.0;
  static const double maxHeight = 160.0;
}

/// Slider Configuration
///
/// Settings for brightness slider control.

class AppSliderConfig {
  AppSliderConfig._();

  static const double min = 0.0;
  static const double max = 100.0;
  static const int divisions = 100;
}

/// Default Settings Values
///
/// Default configuration values for the lighting system.

class DefaultSettings {
  DefaultSettings._();

  // Firmware v6 defaults. Time values are displayed in seconds but sent to
  // the ESP32 as milliseconds.
  static const int darkThreshold = 25;
  static const int brightThreshold = 35;
  static const int dimLevel1Timeout = 10;
  static const int dimLevel2Timeout = 30;
  static const int dimLevel3Timeout = 60;
  static const int sleepTimeout = 120;
  static const int fadeSpeed = 5;
}

/// Operating Modes
///
/// Enumeration of available operating modes.

class OperatingMode {
  static const String auto = 'auto';
  static const String manual = 'manual';
}

/// System States
///
/// Enumeration of possible system states.

class SystemState {
  static const String active = 'active';
  static const String dim1 = 'dim1';
  static const String dim2 = 'dim2';
  static const String sleep = 'sleep';
  static const String off = 'off';
}
