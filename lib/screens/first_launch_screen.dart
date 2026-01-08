import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/core/app_durations.dart';
import 'package:still/screens/still_screen.dart';

/// First Launch Screen
/// Shown ONCE EVER. Never again.
/// 
/// Purpose: Set expectation without instruction.
/// 
/// UI:
/// - Full screen neutral dark background
/// - Centered single word: "STILL"
/// - Medium weight, wide letter spacing, ~90% opacity
/// - Appears after 1s, stays 2-3s, fades out slowly
class FirstLaunchScreen extends StatefulWidget {
  const FirstLaunchScreen({super.key});

  @override
  State<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends State<FirstLaunchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: AppDurations.firstLaunchFadeIn,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Wait 1 second of nothing
    await Future.delayed(AppDurations.firstLaunchDelay);
    
    if (!mounted) return;
    
    // Show text
    setState(() => _showText = true);
    _fadeController.forward();

    // Stay visible for 2.5 seconds
    await Future.delayed(AppDurations.firstLaunchDisplay);
    
    if (!mounted) return;

    // Fade out slowly
    await _fadeController.animateTo(
      0.0,
      duration: AppDurations.firstLaunchFadeOut,
      curve: Curves.easeInOut,
    );

    if (!mounted) return;

    // Mark first launch complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch_complete', true);

    if (!mounted) return;

    // Navigate to still screen - no animation, just replace
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const StillScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Center(
        child: _showText
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'STILL',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6, // Wide letter spacing (+4-6%)
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
