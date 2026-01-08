import 'dart:math';
import 'package:flutter/material.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/core/app_durations.dart';

/// Breathless Presence Glow with Organic Movement
/// Uses irregular easing and slight randomness to feel like existence, not animation.
/// 
/// CRITICAL: This must NOT feel like breathing guidance.
/// No clear inhale/exhale rhythm. Just: existence pulsing.
class PresenceGlow extends StatefulWidget {
  const PresenceGlow({super.key});

  @override
  State<PresenceGlow> createState() => _PresenceGlowState();
}

class _PresenceGlowState extends State<PresenceGlow>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _driftController;
  final Random _random = Random();
  
  // Organic irregularity
  double _currentNoise = 0.0;
  double _targetNoise = 0.0;
  double _noiseVelocity = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Main glow cycle - slightly randomized duration
    final baseDuration = AppDurations.presenceGlowCycle.inMilliseconds;
    final variance = (_random.nextDouble() - 0.5) * 4000; // ±2 seconds
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: baseDuration + variance.toInt()),
    )..addStatusListener(_onCycleComplete);
    
    _controller.forward();
    
    // Slow drift for organic offset
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    
    _driftController.addListener(_updateNoise);
  }

  void _onCycleComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Randomize next cycle duration slightly
      final baseDuration = AppDurations.presenceGlowCycle.inMilliseconds;
      final variance = (_random.nextDouble() - 0.5) * 4000;
      _controller.duration = Duration(milliseconds: baseDuration + variance.toInt());
      _controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      final baseDuration = AppDurations.presenceGlowCycle.inMilliseconds;
      final variance = (_random.nextDouble() - 0.5) * 4000;
      _controller.duration = Duration(milliseconds: baseDuration + variance.toInt());
      _controller.forward();
    }
  }

  void _updateNoise() {
    // Smooth noise using spring-like interpolation
    if (_random.nextDouble() < 0.02) {
      _targetNoise = (_random.nextDouble() - 0.5) * 0.3;
    }
    
    // Spring dynamics for organic movement
    final spring = (_targetNoise - _currentNoise) * 0.01;
    _noiseVelocity = _noiseVelocity * 0.98 + spring;
    _currentNoise += _noiseVelocity;
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
      animation: Listenable.merge([_controller, _driftController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowPainter(
            progress: _controller.value,
            noise: _currentNoise,
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

  _GlowPainter({
    required this.progress,
    required this.noise,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Slightly offset center with noise for organic feel
    final centerX = size.width / 2 + (noise * size.width * 0.02);
    final centerY = size.height / 2 + (noise * size.height * 0.01);
    final center = Offset(centerX, centerY);
    
    // Base radius - about 15% of screen width
    final baseRadius = size.width * 0.15;
    
    // Very subtle expansion with organic irregularity
    final easedProgress = _organicEase(progress);
    final noiseInfluence = noise * 0.005; // Tiny noise influence
    final radius = baseRadius * (1.0 + easedProgress * 0.02 + noiseInfluence);

    // Adaptive colors
    final highlightColor = AppColors.getAdaptiveHighlight();
    final depthColor = AppColors.getAdaptiveDepthOverlay();

    // Create radial gradient for soft glow
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          highlightColor.withValues(alpha: 0.08),
          depthColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius * 2),
      );

    canvas.drawCircle(center, radius * 2, paint);
  }

  // Organic easing - irregular, not rhythmic
  double _organicEase(double t) {
    // Combine multiple sine waves for organic feel
    final base = -(cos(pi * t) - 1) / 2;
    final harmonic = sin(t * pi * 2.7) * 0.1;
    return (base + harmonic).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.noise != noise;
  }
}
