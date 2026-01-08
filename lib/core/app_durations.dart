/// STILL Duration Constants
/// All timings are intentionally slow and imperceptible.
class AppDurations {
  AppDurations._();

  // First Launch Screen Timings
  /// Delay before "STILL" text appears
  static const Duration firstLaunchDelay = Duration(seconds: 1);

  /// How long "STILL" text stays visible
  static const Duration firstLaunchDisplay = Duration(milliseconds: 2500);

  /// Fade in duration for "STILL" text
  static const Duration firstLaunchFadeIn = Duration(milliseconds: 800);

  /// Fade out duration for "STILL" text
  static const Duration firstLaunchFadeOut = Duration(milliseconds: 1200);

  // Main Screen - Visual Life
  /// Ultra-slow gradient drift cycle (so slow it's almost imaginary)
  static const Duration gradientCycle = Duration(seconds: 60);

  /// Presence glow expansion/contraction cycle
  /// Must NOT feel like breathing guidance
  static const Duration presenceGlowCycle = Duration(seconds: 18);

  // Grain Animation
  /// Micro grain subtle shift
  static const Duration grainShift = Duration(milliseconds: 100);
}
