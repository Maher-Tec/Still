import 'package:flutter/material.dart';

/// STILL Color Palette with Adaptive Temperature
/// Neutral dark tones with imperceptible time-of-day shifting.
/// Maximum 2% color shift - the user should never consciously notice.
class AppColors {
  AppColors._();

  /// Background base - near-black, neutral (#0E0F12)
  static const Color backgroundBase = Color(0xFF0E0F12);

  /// Depth overlay - slightly lighter for subtle layering (#14151A)
  static const Color depthOverlay = Color(0xFF14151A);

  /// Highlight - very subtle, for gradient edges (#1B1C22)
  static const Color highlight = Color(0xFF1B1C22);

  /// Text color - off-white, not pure white (~90% opacity)
  static const Color textPrimary = Color(0xE6FFFFFF);

  // Adaptive temperature tints (imperceptible)
  static const Color _warmTint = Color(0xFF1A1512); // Dusk warmth
  static const Color _coolTint = Color(0xFF0D1014); // Night coolness

  /// Get adaptive background based on time of day
  /// Shift is imperceptible: maximum 2%
  static Color getAdaptiveBackground() {
    final hour = DateTime.now().hour;
    final factor = _getTemperatureFactor(hour);
    
    if (factor > 0) {
      // Warm shift (dusk: 17-20)
      return Color.lerp(backgroundBase, _warmTint, factor * 0.02)!;
    } else if (factor < 0) {
      // Cool shift (night: 22-5)
      return Color.lerp(backgroundBase, _coolTint, factor.abs() * 0.02)!;
    }
    return backgroundBase;
  }

  /// Get adaptive depth overlay
  static Color getAdaptiveDepthOverlay() {
    final hour = DateTime.now().hour;
    final factor = _getTemperatureFactor(hour);
    
    if (factor > 0) {
      return Color.lerp(depthOverlay, _warmTint, factor * 0.015)!;
    } else if (factor < 0) {
      return Color.lerp(depthOverlay, _coolTint, factor.abs() * 0.015)!;
    }
    return depthOverlay;
  }

  /// Get adaptive highlight
  static Color getAdaptiveHighlight() {
    final hour = DateTime.now().hour;
    final factor = _getTemperatureFactor(hour);
    
    if (factor > 0) {
      return Color.lerp(highlight, _warmTint, factor * 0.01)!;
    } else if (factor < 0) {
      return Color.lerp(highlight, _coolTint, factor.abs() * 0.01)!;
    }
    return highlight;
  }

  /// Temperature factor: -1 to 1
  /// Positive = warm (dusk), Negative = cool (night), Zero = neutral
  static double _getTemperatureFactor(int hour) {
    // Dusk warmth: 17-20 (5pm-8pm)
    if (hour >= 17 && hour <= 20) {
      // Peak warmth at 18:30
      if (hour == 18) return 1.0;
      if (hour == 17 || hour == 19) return 0.7;
      return 0.4;
    }
    
    // Night coolness: 22-5 (10pm-5am)
    if (hour >= 22 || hour <= 5) {
      // Peak coolness at 2-3am
      if (hour >= 2 && hour <= 3) return -1.0;
      if (hour >= 0 && hour <= 4) return -0.8;
      return -0.5;
    }
    
    // Neutral during day
    return 0.0;
  }

  /// Gradient colors for ultra-slow drift (static version for const contexts)
  static const List<Color> gradientColors = [
    backgroundBase,
    depthOverlay,
    highlight,
    depthOverlay,
    backgroundBase,
  ];

  /// Get adaptive gradient colors
  static List<Color> getAdaptiveGradientColors() {
    return [
      getAdaptiveBackground(),
      getAdaptiveDepthOverlay(),
      getAdaptiveHighlight(),
      getAdaptiveDepthOverlay(),
      getAdaptiveBackground(),
    ];
  }
}
