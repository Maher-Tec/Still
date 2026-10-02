import 'package:flutter/material.dart';
class AppColors {
  AppColors._();
  static const Color backgroundBase = Color(0xFF0E0F12);
  static const Color depthOverlay = Color(0xFF14151A);
  static const Color highlight = Color(0xFF1B1C22);
  static const Color textPrimary = Color(0xE6FFFFFF);
  static const Color _warmTint = Color(0xFF1A1512);
  static const Color _coolTint = Color(0xFF0D1014);
  static Color getAdaptiveBackground() {
    final hour = DateTime.now().hour;
    final factor = _getTemperatureFactor(hour);

    if (factor > 0) {
      return Color.lerp(backgroundBase, _warmTint, factor * 0.02)!;
    } else if (factor < 0) {
      return Color.lerp(backgroundBase, _coolTint, factor.abs() * 0.02)!;
    }
    return backgroundBase;
  }
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
  static double _getTemperatureFactor(int hour) {
    if (hour >= 17 && hour <= 20) {
      if (hour == 18) return 1.0;
      if (hour == 17 || hour == 19) return 0.7;
      return 0.4;
    }
    if (hour >= 22 || hour <= 5) {
      if (hour >= 2 && hour <= 3) return -1.0;
      if (hour >= 0 && hour <= 4) return -0.8;
      return -0.5;
    }
    return 0.0;
  }
  static const List<Color> gradientColors = [
    backgroundBase,
    depthOverlay,
    highlight,
    depthOverlay,
    backgroundBase,
  ];
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
