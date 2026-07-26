/// Main Application Entry Point
/// 
/// This file initializes the Flutter application, sets up the theme,
/// configures routing, and provides the state management layer.
/// 
/// Purpose: Bootstrap the application with proper configuration
/// and dependency injection.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/screens/splash_screen.dart';
import 'package:smart_light/screens/dashboard_screen.dart';
import 'package:smart_light/screens/live_monitor_screen.dart';
import 'package:smart_light/screens/manual_control_screen.dart';
import 'package:smart_light/screens/settings_screen.dart';
import 'package:smart_light/screens/statistics_screen.dart';
import 'package:smart_light/screens/logs_screen.dart';
import 'package:smart_light/utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartLightApp());
}

/// Smart Light Application
/// 
/// The root widget of the application.
class SmartLightApp extends StatelessWidget {
  const SmartLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SystemProvider(),
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: _buildRoutes(),
      ),
    );
  }

  /// Build light theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.white70,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.accent.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Build dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: AppColors.darkCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.white54,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.darkTextPrimary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }

  /// Build application routes
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => const SplashScreen(),
      '/dashboard': (context) => const DashboardScreen(),
      '/monitor': (context) => const LiveMonitorScreen(),
      '/manual': (context) => const ManualControlScreen(),
      '/settings': (context) => const SettingsScreen(),
      '/statistics': (context) => const StatisticsScreen(),
      '/logs': (context) => const LogsScreen(),
    };
  }
}
