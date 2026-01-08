import 'dart:math';
import 'package:flutter/material.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/core/app_durations.dart';

/// Ultra-slow gradient drift with color breathing
/// 
/// Color breathing: entire screen imperceptibly shifts hue over 5 minutes.
/// Movement so slow it's almost imaginary.
class SubtleGradient extends StatefulWidget {
  final double parallaxX;
  final double parallaxY;

  const SubtleGradient({
    super.key,
    this.parallaxX = 0.0,
    this.parallaxY = 0.0,
  });

  @override
  State<SubtleGradient> createState() => _SubtleGradientState();
}

class _SubtleGradientState extends State<SubtleGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.gradientCycle,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final angle = progress * 2 * pi;

        // Parallax influence (1-2% shift based on device tilt)
        final parallaxDx = widget.parallaxX * 0.02;
        final parallaxDy = widget.parallaxY * 0.02;

        // Ultra-subtle shift in gradient alignment + parallax
        final dx = sin(angle) * 0.1 + parallaxDx;
        final dy = cos(angle) * 0.05 + parallaxDy;

        // Color breathing: 5-minute hue cycle
        final breathProgress = _getBreathProgress();
        final colors = _getBreathingColors(breathProgress);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.5 + dx, -0.5 + dy),
              end: Alignment(0.5 - dx, 0.5 - dy),
              colors: colors,
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
        );
      },
    );
  }

  /// Get breathing progress (0.0 to 1.0) over 5 minutes
  double _getBreathProgress() {
    final now = DateTime.now();
    final totalSeconds = now.minute * 60 + now.second + now.millisecond / 1000;
    // 5-minute cycle (300 seconds)
    return (totalSeconds % 300) / 300;
  }

  /// Shift hue imperceptibly based on breath progress
  List<Color> _getBreathingColors(double progress) {
    final baseColors = AppColors.getAdaptiveGradientColors();
    
    // Very subtle hue shift: max 3 degrees (imperceptible)
    final hueShift = sin(progress * 2 * pi) * 3;
    
    return baseColors.map((color) {
      final hsl = HSLColor.fromColor(color);
      final newHue = (hsl.hue + hueShift) % 360;
      return hsl.withHue(newHue).toColor();
    }).toList();
  }
}
