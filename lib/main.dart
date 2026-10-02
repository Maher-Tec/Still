import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still/app/still_app.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = !(prefs.getBool('first_launch_complete') ?? false);
  final soundEnabled = prefs.getBool('sound_enabled') ?? false;
  final motionEnabled = prefs.getBool('motion_enabled') ?? true;
  final hapticsEnabled = prefs.getBool('haptics_enabled') ?? false;
  final sceneMood = prefs.getInt('scene_mood') ?? 0;

  runApp(
    StillApp(
      isFirstLaunch: isFirstLaunch,
      soundEnabled: soundEnabled,
      motionEnabled: motionEnabled,
      hapticsEnabled: hapticsEnabled,
      initialMoodIndex: sceneMood,
    ),
  );
}
