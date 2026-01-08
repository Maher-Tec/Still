import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Micro film grain overlay
/// Opacity: 1-2%
/// Prevents digital flatness - makes the screen feel alive without distraction.
class MicroGrain extends StatefulWidget {
  const MicroGrain({super.key});

  @override
  State<MicroGrain> createState() => _MicroGrainState();
}

class _MicroGrainState extends State<MicroGrain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Very slow update - grain barely shifts
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
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
        return CustomPaint(
          painter: _GrainPainter(seed: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GrainPainter extends CustomPainter {
  final double seed;
  final Random _random;

  _GrainPainter({required this.seed}) : _random = Random((seed * 10000).toInt());

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015) // 1.5% opacity
      ..strokeWidth = 1;

    // Sparse grain - not too dense
    final grainCount = (size.width * size.height / 800).toInt();

    for (int i = 0; i < grainCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawPoints(
        ui.PointMode.points,
        [Offset(x, y)],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) => true;
}
