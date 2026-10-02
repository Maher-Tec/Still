import 'package:flutter/material.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/screens/first_launch_screen.dart';
import 'package:still/screens/still_screen.dart';
class StillApp extends StatelessWidget {
  final bool isFirstLaunch;
  final bool soundEnabled;
  final bool motionEnabled;
  final bool hapticsEnabled;
  final int initialMoodIndex;

  const StillApp({
    super.key,
    required this.isFirstLaunch,
    required this.soundEnabled,
    this.motionEnabled = true,
    this.hapticsEnabled = false,
    this.initialMoodIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STILL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundBase,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.backgroundBase,
          primary: AppColors.depthOverlay,
        ),
      ),
      home: isFirstLaunch
          ? const FirstLaunchScreen()
          : StillScreen(
              soundEnabled: soundEnabled,
              motionEnabled: motionEnabled,
              hapticsEnabled: hapticsEnabled,
              initialMoodIndex: initialMoodIndex,
            ),
    );
  }
}
