import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/screens/first_launch_screen.dart';
import 'package:still/screens/still_screen.dart';

/// The STILL App
/// A space with no demand. Nothing to do. Nothing to complete. Nothing to end.
class StillApp extends StatelessWidget {
  final bool isFirstLaunch;

  const StillApp({
    super.key,
    required this.isFirstLaunch,
  });

  @override
  Widget build(BuildContext context) {
    // Set system UI to immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.backgroundBase,
      ),
    );

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
      home: isFirstLaunch ? const FirstLaunchScreen() : const StillScreen(),
    );
  }
}
