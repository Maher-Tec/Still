import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/core/app_durations.dart';
import 'package:still/screens/still_screen.dart';
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
  bool _showSoundChoice = false;

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
    await Future.delayed(AppDurations.firstLaunchDelay);

    if (!mounted) return;
    setState(() => _showText = true);
    _fadeController.forward();

    await Future.delayed(AppDurations.firstLaunchDisplay);

    if (!mounted) return;
    await _fadeController.animateTo(
      0.0,
      duration: AppDurations.firstLaunchFadeOut,
      curve: Curves.easeInOut,
    );

    if (!mounted) return;
    setState(() => _showSoundChoice = true);
  }

  Future<void> _finishFirstLaunch({required bool soundEnabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch_complete', true);
    await prefs.setBool('sound_enabled', soundEnabled);
    await prefs.setBool('motion_enabled', true);
    await prefs.setBool('haptics_enabled', true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StillScreen(soundEnabled: soundEnabled, hapticsEnabled: true),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
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
        child: _showSoundChoice
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'STILL',
                      style: TextStyle(
                        color: Color(0xFFF7ECE0),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Would you like a subtle ambient tone?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _choiceButton(
                          title: 'Keep Silent',
                          isPrimary: false,
                          onPressed: () =>
                              _finishFirstLaunch(soundEnabled: false),
                        ),
                        const SizedBox(width: 14),
                        _choiceButton(
                          title: 'Enable Sound',
                          isPrimary: true,
                          onPressed: () =>
                              _finishFirstLaunch(soundEnabled: true),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : _showText
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'STILL',
                  style: TextStyle(
                    color: Color(0xFFF7ECE0),
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 8,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _choiceButton({
    required String title,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: isPrimary
                  ? const Color(0xFF5FF6D1).withValues(alpha: 0.2)
                  : const Color(0xFF141F28).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isPrimary
                    ? const Color(0xFF5FF6D1).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isPrimary
                    ? const Color(0xFF68F9D5)
                    : const Color(0xFFD6E2E4),
                fontSize: 13,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
