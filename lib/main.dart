import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still/app/still_app.dart';

/// STILL
/// A space with no demand.
/// Nothing to do. Nothing to complete. Nothing to end.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set immersive mode immediately
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Lock to portrait - rotation breaks stillness
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Check if this is the first launch
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = !(prefs.getBool('first_launch_complete') ?? false);
  
  runApp(StillApp(isFirstLaunch: isFirstLaunch));
}
