/// Splash Screen
/// 
/// The initial screen displayed when the application launches.
/// Shows the app logo, title, and loading animation while
/// initializing the connection and fetching initial data.
/// 
/// Purpose: Provide a professional loading experience and
/// initialize the application before navigating to the main dashboard.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:smart_light/widgets/connection_status.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _appearController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final List<String> _loadingMessages = [
    'Connecting to ESP32...',
    'Fetching telemetry data...',
    'Calibrating sensors...',
    'Warming up the lights...',
    'Readying dashboard...'
  ];
  int _loadingMessageIndex = 0;
  bool _isInitFinished = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startDynamicText();
    _initializeApp();
  }

  /// Setup animations
  void _setupAnimations() {
    _appearController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutBack),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Initial slight delay before showing Flutter splash to let native splash fade
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _appearController.forward();
    });
  }

  void _startDynamicText() async {
    while (mounted && !_isInitFinished) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _loadingMessageIndex =
              (_loadingMessageIndex + 1) % _loadingMessages.length;
        });
      }
    }
  }

  /// Initialize application
  Future<void> _initializeApp() async {
    // Wait a bit so user can see the splash screen and animations
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    final provider = Provider.of<SystemProvider>(context, listen: false);

    // Initialize provider with connection
    await provider.initialize(autoPoll: false);

    // Give it a tiny bit more time for the final message
    await Future.delayed(const Duration(seconds: 1));
    _isInitFinished = true;

    // Navigate to dashboard
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  void dispose() {
    _isInitFinished = true;
    _appearController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_appearController, _glowController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon with Glowing Pulse
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(_glowAnimation.value),
                            blurRadius: 30 + (20 * _glowAnimation.value),
                            spreadRadius: 8 + (5 * _glowAnimation.value),
                          ),
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(_glowAnimation.value * 0.5),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.bolt,
                              size: 64,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // App Title
                    Text(
                      appName,
                      style: AppTextStyles.headline2.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Creative Slogan
                    Text(
                      'Illuminating intelligence, effortlessly.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Connection Status
                    Consumer<SystemProvider>(
                      builder: (context, provider, child) {
                        return ConnectionStatusWidget(
                          status: provider.connectionStatus,
                          compact: false,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Loading Indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Dynamic Loading Text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _loadingMessages[_loadingMessageIndex],
                        key: ValueKey<int>(_loadingMessageIndex),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
