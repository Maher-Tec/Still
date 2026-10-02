import 'dart:math';
import 'package:flutter/material.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/core/app_durations.dart';
class PresenceGlow extends StatefulWidget {
  final double stillness;

  const PresenceGlow({super.key, this.stillness = 0.0});

  @override
  State<PresenceGlow> createState() => _PresenceGlowState();
}

class _PresenceGlowState extends State<PresenceGlow>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _driftController;
  final Random _random = Random();
  double _currentNoise = 0.0;
  double _targetNoise = 0.0;
  double _noiseVelocity = 0.0;

  @override
  void initState() {
    super.initState();
    final baseDuration = AppDurations.presenceGlowCycle.inMilliseconds;
    final variance = (_random.nextDouble() - 0.5) * 4000;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: baseDuration + variance.toInt()),
    )..addStatusListener(_onCycleComplete);

    _controller.forward();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _driftController.addListener(_updateNoise);
  }

  void _onCycleComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final baseDuration = AppDurations.presenceGlowCycle.inMilliseconds;
      final variance = (_random.nextDouble() - 0.5) * 4000;
      _controller.duration = Duration(
        milliseconds: baseDuration + variance.toInt(),
      );
      _controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      final baseDuration = AppDurations.presenceGlowCycle.inMilliseconds;
      final variance = (_random.nextDouble() - 0.5) * 4000;
      _controller.duration = Duration(
        milliseconds: baseDuration + variance.toInt(),
      );
      _controller.forward();
    }
  }

  void _updateNoise() {
    if (_random.nextDouble() < 0.02) {
      _targetNoise = (_random.nextDouble() - 0.5) * 0.3;
    }
    final spring = (_targetNoise - _currentNoise) * 0.01;
    _noiseVelocity = _noiseVelocity * 0.98 + spring;
    _currentNoise += _noiseVelocity;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowPainter(
            progress: _controller.value,
            noise: _currentNoise * (1 - widget.stillness),
            stillness: widget.stillness,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double progress;
  final double noise;
  final double stillness;

  _GlowPainter({
    required this.progress,
    required this.noise,
    required this.stillness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2 + (noise * size.width * 0.02);
    final centerY = size.height / 2 + (noise * size.height * 0.01);
    final center = Offset(centerX, centerY);
    final baseRadius = size.width * 0.15;
    final easedProgress = _organicEase(progress);
    final noiseInfluence = noise * 0.005;
    final radius =
        baseRadius *
        (1.0 + easedProgress * 0.02 * (1 - stillness) + noiseInfluence);
    final highlightColor = AppColors.getAdaptiveHighlight();
    final depthColor = AppColors.getAdaptiveDepthOverlay();
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          highlightColor.withValues(alpha: 0.08),
          depthColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2));

    canvas.drawCircle(center, radius * 2, paint);
  }
  double _organicEase(double t) {
    final base = -(cos(pi * t) - 1) / 2;
    final harmonic = sin(t * pi * 2.7) * 0.1;
    return (base + harmonic).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.noise != noise ||
        oldDelegate.stillness != stillness;
  }
}
