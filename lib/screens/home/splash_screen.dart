import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../main/main_screen.dart';

/// Splash Screen - First Screen Displayed When Application Launches
/// Handles Initial Animation And Navigation Based On Authentication Status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  Timer? _navigationTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller For Smooth Fade-In Effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Configure Fade Animation From Transparent To Opaque
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start Fade Animation Immediately
    _animationController.forward();

    // Initialize Navigation Timer
    _startNavigationTimer();
  }

  @override
  void dispose() {
    // Clean Up Resources To Prevent Memory Leaks
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Start Timer For Automatic Navigation After Specified Delay
  void _startNavigationTimer() {
    _navigationTimer = Timer(
      const Duration(milliseconds: 3500),
      _navigateBasedOnAuthStatus,
    );
  }

  /// Determine Navigation Destination Based On User Authentication Status
  void _navigateBasedOnAuthStatus() {
    if (_authService.isLoggedIn) {
      // User Is Authenticated - Navigate To Main Application Screen
      Get.off(() => const MainScreen());
    } else {
      // User Is Not Authenticated - Navigate To Login Screen
      Get.off(() => LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Dark Blue Gradient Background For Premium Look
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000814),
              Color(0xFF001D3D),
              Color(0xFF003566),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 180,
              height: 180,
              // Circular Container With Thin White Border
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 0.4,
                ),
              ),
              child: Center(
                // Lottie Animation Asset For Smooth Visual Experience
                child: Lottie.asset(
                  'assets/images/smart_room.json',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  repeat: true,
                  frameRate: FrameRate.max,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}