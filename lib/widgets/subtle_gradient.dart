import 'dart:math';
import 'package:flutter/material.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/core/app_durations.dart';
class SubtleGradient extends StatefulWidget {
  final double parallaxX;
  final double parallaxY;
  final double stillness;

  const SubtleGradient({
    super.key,
    this.parallaxX = 0.0,
    this.parallaxY = 0.0,
    this.stillness = 0.0,
  });

  @override
  State<SubtleGradient> createState() => _SubtleGradientState();
}

class _SubtleGradientState extends State<SubtleGradient>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hueController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.gradientCycle,
    )..repeat();
    _hueController = AnimationController(
      vsync: this,
      duration: AppDurations.hueCycle,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _hueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final angle = progress * 2 * pi;
        final parallaxDx = widget.parallaxX * 0.02;
        final parallaxDy = widget.parallaxY * 0.02;
        final motion = 1 - widget.stillness;
        final dx = (sin(angle) * 0.1 + parallaxDx) * motion;
        final dy = (cos(angle) * 0.05 + parallaxDy) * motion;
        final breathProgress = _hueController.value;
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
  List<Color> _getBreathingColors(double progress) {
    final baseColors = AppColors.getAdaptiveGradientColors();
    final hueShift = sin(progress * 2 * pi) * 3 * (1 - widget.stillness);

    return baseColors.map((color) {
      final hsl = HSLColor.fromColor(color);
      final newHue = (hsl.hue + hueShift) % 360;
      return hsl.withHue(newHue).toColor();
    }).toList();
  }
}
