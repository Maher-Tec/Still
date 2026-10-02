import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum WaterMood {
  dusk,
  night,
  eclipse,
  emerald,
  aurora,
  dawn;

  String get displayName {
    switch (this) {
      case WaterMood.dusk:
        return 'Dusk';
      case WaterMood.night:
        return 'Midnight';
      case WaterMood.eclipse:
        return 'Eclipse';
      case WaterMood.emerald:
        return 'Emerald';
      case WaterMood.aurora:
        return 'Aurora';
      case WaterMood.dawn:
        return 'Dawn';
    }
  }

  String get description {
    switch (this) {
      case WaterMood.dusk:
        return 'Warm amber horizon and soft twilight';
      case WaterMood.night:
        return 'Deep celestial velvet and shooting stars';
      case WaterMood.eclipse:
        return 'Ethereal solar corona and obsidian tides';
      case WaterMood.emerald:
        return 'Bioluminescent jade forest lake';
      case WaterMood.aurora:
        return 'Shimmering borealis curtains over icy waters';
      case WaterMood.dawn:
        return 'Gentle morning rose and golden mist';
    }
  }
}
class _AmbientParticle {
  double x;
  double y;
  double size;
  double opacity;
  double speedX;
  double speedY;
  double phase;

  _AmbientParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.phase,
  });
}
class _ShootingStar {
  double startX;
  double startY;
  double endX;
  double endY;
  int startedAt;
  int durationMs;
  double length;

  _ShootingStar({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.startedAt,
    required this.durationMs,
    required this.length,
  });
}
class AmbientWaterScene extends StatefulWidget {
  final double tiltX;
  final double tiltY;
  final double stillness;
  final double moodValue;
  final bool motionEnabled;
  final bool hapticsEnabled;
  final bool breathPacerActive;
  final double breathProgress;
  final String breathPhaseText;

  const AmbientWaterScene({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.stillness,
    required this.moodValue,
    this.motionEnabled = true,
    this.hapticsEnabled = false,
    this.breathPacerActive = false,
    this.breathProgress = 0.0,
    this.breathPhaseText = '',
  });

  @override
  State<AmbientWaterScene> createState() => _AmbientWaterSceneState();
}

class _AmbientWaterSceneState extends State<AmbientWaterScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time;
  final Stopwatch _clock = Stopwatch()..start();
  final List<_Ripple> _ripples = [];
  final List<_AmbientParticle> _particles = [];
  final List<_ShootingStar> _shootingStars = [];
  final math.Random _random = math.Random(101);

  Offset _lightPosition = const Offset(0.52, 0.385);
  bool _draggingLight = false;
  Offset? _lastWaterTouch;
  int _lastRippleAt = 0;
  int _lastMeteorSpawn = 0;

  @override
  void initState() {
    super.initState();
    _time = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 35; i++) {
      _particles.add(
        _AmbientParticle(
          x: _random.nextDouble(),
          y: 0.52 + _random.nextDouble() * 0.46,
          size: 1.2 + _random.nextDouble() * 2.6,
          opacity: 0.15 + _random.nextDouble() * 0.55,
          speedX: (_random.nextDouble() - 0.5) * 0.0003,
          speedY: (_random.nextDouble() - 0.5) * 0.0002,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _time.dispose();
    _clock.stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AmbientWaterScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionEnabled != widget.motionEnabled) {
      if (widget.motionEnabled) {
        _time.repeat();
      } else {
        _time.stop();
      }
    }
  }

  void _addRipple(Offset position) {
    final size = context.size;
    if (size == null) return;
    if (position.dy < size.height * 0.52) return;
    final normalizedX = (position.dx / size.width).clamp(0.0, 1.0);
    _ripples.add(
      _Ripple(
        x: normalizedX,
        y: (position.dy / size.height).clamp(0.0, 1.0),
        startedAt: _clock.elapsedMilliseconds,
      ),
    );
    if (_ripples.length > 8) _ripples.removeAt(0);
    _lastWaterTouch = position;
    _lastRippleAt = _clock.elapsedMilliseconds;
    if (widget.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _startDrag(DragStartDetails details) {
    final size = context.size;
    if (size == null) return;
    final lightCenter = Offset(
      _lightPosition.dx * size.width + widget.tiltX * size.width * 0.045,
      _lightPosition.dy * size.height + widget.tiltY * 14,
    );
    _draggingLight =
        (details.localPosition - lightCenter).distance < size.width * 0.18;
    if (!_draggingLight) {
      _addRipple(details.localPosition);
    } else if (widget.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _updateDrag(DragUpdateDetails details) {
    final size = context.size;
    if (size == null) return;
    final position = details.localPosition;
    if (_draggingLight) {
      _lightPosition = Offset(
        (position.dx / size.width).clamp(0.12, 0.88),
        (position.dy / size.height).clamp(0.14, 0.49),
      );
      return;
    }

    final lastTouch = _lastWaterTouch;
    if (position.dy >= size.height * 0.52 &&
        _clock.elapsedMilliseconds - _lastRippleAt > 110 &&
        (lastTouch == null || (position - lastTouch).distance > 18)) {
      _addRipple(position);
    }
  }

  void _endDrag() {
    _draggingLight = false;
    _lastWaterTouch = null;
  }

  void _updateShootingStars(int now) {
    final currentMoodIndex = widget.moodValue.round();
    final isStarlitMood =
        currentMoodIndex == WaterMood.night.index ||
        currentMoodIndex == WaterMood.aurora.index ||
        currentMoodIndex == WaterMood.eclipse.index;

    if (isStarlitMood &&
        now - _lastMeteorSpawn > 8000 &&
        _random.nextDouble() < 0.03) {
      _lastMeteorSpawn = now;
      final startX = 0.15 + _random.nextDouble() * 0.7;
      final startY = 0.04 + _random.nextDouble() * 0.25;
      final angle = math.pi / 4 + (_random.nextDouble() - 0.5) * 0.3;
      final length = 0.18 + _random.nextDouble() * 0.12;

      _shootingStars.add(
        _ShootingStar(
          startX: startX,
          startY: startY,
          endX: startX + math.cos(angle) * length,
          endY: startY + math.sin(angle) * length * 0.6,
          startedAt: now,
          durationMs: 750 + _random.nextInt(500),
          length: length,
        ),
      );
    }

    _shootingStars.removeWhere(
      (star) => now - star.startedAt > star.durationMs + 200,
    );
  }

  void _updateParticles(double movement) {
    for (final p in _particles) {
      p.x += p.speedX * (0.4 + movement * 0.6);
      p.y += p.speedY * (0.4 + movement * 0.6);
      p.phase += 0.02;

      if (p.x < 0) p.x = 1.0;
      if (p.x > 1.0) p.x = 0;
      if (p.y < 0.52) p.y = 0.98;
      if (p.y > 0.98) p.y = 0.53;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _addRipple(details.localPosition),
      onPanStart: _startDrag,
      onPanUpdate: _updateDrag,
      onPanEnd: (_) => _endDrag(),
      onPanCancel: _endDrag,
      child: AnimatedBuilder(
        animation: _time,
        builder: (context, child) {
          final now = _clock.elapsedMilliseconds;
          _ripples.removeWhere((ripple) => now - ripple.startedAt > 2800);
          _updateShootingStars(now);
          _updateParticles(1.0 - widget.stillness);

          return CustomPaint(
            painter: _WaterPainter(
              phase: widget.motionEnabled ? _time.value * math.pi * 2 : 0,
              tiltX: widget.motionEnabled ? widget.tiltX : 0,
              tiltY: widget.motionEnabled ? widget.tiltY : 0,
              stillness: widget.stillness,
              moodValue: widget.moodValue,
              lightPosition: _lightPosition,
              ripples: _ripples,
              particles: _particles,
              shootingStars: _shootingStars,
              breathPacerActive: widget.breathPacerActive,
              breathProgress: widget.breathProgress,
              breathPhaseText: widget.breathPhaseText,
              now: now,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

List<_Star> _createStars(double width, double height) {
  final random = math.Random(43);
  return List<_Star>.generate(56, (_) {
    return _Star(
      random.nextDouble() * width,
      (0.04 + random.nextDouble() * 0.42) * height,
      0.35 + random.nextDouble() * 0.9,
      0.45 + random.nextDouble() * 0.55,
    );
  }, growable: false);
}

class _Star {
  final double x;
  final double y;
  final double radius;
  final double brightness;
  const _Star(this.x, this.y, this.radius, this.brightness);
}

class _Ripple {
  final double x;
  final double y;
  final int startedAt;

  const _Ripple({required this.x, required this.y, required this.startedAt});
}

class _WaterPainter extends CustomPainter {
  final double phase;
  final double tiltX;
  final double tiltY;
  final double stillness;
  final double moodValue;
  final Offset lightPosition;
  final List<_Ripple> ripples;
  final List<_AmbientParticle> particles;
  final List<_ShootingStar> shootingStars;
  final bool breathPacerActive;
  final double breathProgress;
  final String breathPhaseText;
  final int now;

  static final Map<int, List<_Star>> _starCache = {};

  const _WaterPainter({
    required this.phase,
    required this.tiltX,
    required this.tiltY,
    required this.stillness,
    required this.moodValue,
    required this.lightPosition,
    required this.ripples,
    required this.particles,
    required this.shootingStars,
    required this.breathPacerActive,
    required this.breathProgress,
    required this.breathPhaseText,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final horizon = height * 0.54 + tiltY * 9;
    final lightX = width * (lightPosition.dx + tiltX * 0.045);
    final lightY = height * lightPosition.dy + tiltY * 14;
    final movement = 1 - stillness;

    final colors = _resolvePalette(moodValue);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.skyTop, colors.skyMiddle, colors.skyHorizon],
          stops: const [0, 0.62, 1],
        ).createShader(Rect.fromLTWH(0, 0, width, horizon)),
    );
    if (colors.auroraIntensity > 0.05) {
      _drawAuroraRibbons(canvas, size, horizon, colors.auroraIntensity);
    }
    final cacheKey = Object.hash(width.round(), height.round());
    final stars = _starCache.putIfAbsent(
      cacheKey,
      () => _createStars(width, height),
    );
    final starVisibility = colors.starAlpha;
    if (starVisibility > 0.02) {
      for (var index = 0; index < stars.length; index++) {
        final star = stars[index];
        final twinkle = 0.85 + math.sin(phase * 2.2 + index * 2.7) * 0.15;
        canvas.drawCircle(
          Offset(star.x + tiltX * (2 + star.radius * 2), star.y),
          star.radius,
          Paint()
            ..color = const Color(
              0xFFF2EFE9,
            ).withValues(alpha: starVisibility * star.brightness * twinkle),
        );
      }
    }
    _drawShootingStars(canvas, width, height, colors.light);
    _drawCelestialOrb(
      canvas,
      width,
      height,
      lightX,
      lightY,
      colors.light,
      colors.coronaColor,
      isEclipse: colors.isEclipse,
    );
    if (breathPacerActive) {
      _drawBreathPacer(canvas, width, lightX, lightY, colors.light);
    }
    _drawHorizonHazeAndMist(canvas, width, height, horizon, colors);
    _drawMountains(canvas, width, horizon, colors);
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, width, height - horizon),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.waterTop, colors.waterMiddle, colors.waterBottom],
          stops: const [0, 0.38, 1],
        ).createShader(Rect.fromLTWH(0, horizon, width, height - horizon)),
    );
    final waterHeight = height - horizon;
    final reflectedGlow = Rect.fromCenter(
      center: Offset(lightX, horizon + waterHeight * 0.28),
      width: width * 0.78,
      height: waterHeight * 0.82,
    );
    canvas.drawOval(
      reflectedGlow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors.light.withValues(alpha: 0.13),
            colors.light.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(reflectedGlow),
    );
    for (var band = 0; band < 8; band++) {
      final depth = (band + 0.5) / 8;
      final baseY = horizon + 8 + math.pow(depth, 1.25) * waterHeight * 0.95;
      final amplitude = (2.0 + depth * 4.5) * movement;
      final path = Path();
      for (var step = 0; step <= 24; step++) {
        final x = width * step / 24;
        final broadWave = math.sin(
          x / (width * 0.22) + phase * 0.22 + band * 0.8,
        );
        final secondaryWave =
            math.sin(x / (width * 0.095) - phase * 0.13 + band * 1.7) * 0.22;
        final y = baseY + (broadWave + secondaryWave) * amplitude;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7 + depth * 0.7
          ..strokeCap = StrokeCap.round
          ..color = colors.waterHighlight.withValues(
            alpha: 0.025 + depth * 0.035,
          ),
      );
    }
    for (var row = 0; row < 32; row++) {
      if (row % 7 == 2) continue;
      final depth = (row + 0.5) / 32;
      final y = horizon + 7 + math.pow(depth, 1.15) * waterHeight * 0.94;
      final spread = width * (0.018 + depth * 0.16);
      final waveOffset =
          math.sin(phase * 0.24 + row * 0.73) * spread * 0.10 * movement;
      final center = lightX + waveOffset + math.sin(row * 2.31) * spread * 0.12;
      final length =
          spread *
          (0.18 + 0.30 * (0.5 + 0.5 * math.sin(row * 1.63 + phase * 0.12)));

      canvas.drawLine(
        Offset(center - length / 2, y),
        Offset(center + length / 2, y),
        Paint()
          ..color = colors.light.withValues(
            alpha: (0.14 * (1 - depth) + 0.025) * (0.72 + movement * 0.28),
          )
          ..strokeWidth = 0.7 + depth * 0.9
          ..strokeCap = StrokeCap.round,
      );
    }
    _drawParticles(canvas, width, height, colors.particleColor, movement);
    _drawRipples(canvas, width, height, horizon, colors.light);
  }

  void _drawAuroraRibbons(
    Canvas canvas,
    Size size,
    double horizon,
    double intensity,
  ) {
    final width = size.width;
    final auroraHeight = horizon * 0.85;

    for (int i = 0; i < 2; i++) {
      final ribbonPhase = phase * 0.8 + i * 1.8;
      final path = Path()..moveTo(0, 0);

      for (double x = 0; x <= width; x += 20) {
        final wave =
            math.sin(x * 0.008 + ribbonPhase) * 22 +
            math.cos(x * 0.015 - ribbonPhase * 0.7) * 15;
        final y = auroraHeight * 0.35 + wave + i * 35;
        path.lineTo(x, y);
      }
      path.lineTo(width, 0);
      path.close();

      final ribbonColor = i == 0
          ? const Color(0xFF2BF6C8)
          : const Color(0xFF6A5ACD);

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              ribbonColor.withValues(alpha: 0.12 * intensity),
              ribbonColor.withValues(alpha: 0.03 * intensity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 0.8, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, width, auroraHeight)),
      );
    }
  }

  void _drawShootingStars(
    Canvas canvas,
    double width,
    double height,
    Color lightColor,
  ) {
    for (final star in shootingStars) {
      final progress = ((now - star.startedAt) / star.durationMs).clamp(
        0.0,
        1.0,
      );
      if (progress >= 1.0) continue;

      final currentX =
          (star.startX + (star.endX - star.startX) * progress) * width;
      final currentY =
          (star.startY + (star.endY - star.startY) * progress) * height;
      final tailLength = star.length * width * 0.4;
      final dx = (star.endX - star.startX);
      final dy = (star.endY - star.startY);
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= 0) continue;
      final normX = dx / dist;
      final normY = dy / dist;

      final tailX = currentX - normX * tailLength;
      final tailY = currentY - normY * tailLength;

      final alpha = math.sin(progress * math.pi) * 0.85;

      canvas.drawLine(
        Offset(tailX, tailY),
        Offset(currentX, currentY),
        Paint()
          ..shader =
              LinearGradient(
                colors: [
                  Colors.transparent,
                  lightColor.withValues(alpha: alpha * 0.5),
                  Colors.white.withValues(alpha: alpha),
                ],
                stops: const [0.0, 0.7, 1.0],
              ).createShader(
                Rect.fromPoints(
                  Offset(tailX, tailY),
                  Offset(currentX, currentY),
                ),
              )
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(
        Offset(currentX, currentY),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  void _drawCelestialOrb(
    Canvas canvas,
    double width,
    double height,
    double lightX,
    double lightY,
    Color lightColor,
    Color coronaColor, {
    required bool isEclipse,
  }) {
    canvas.drawCircle(
      Offset(lightX, lightY),
      width * 0.55,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                coronaColor.withValues(alpha: 0.25),
                coronaColor.withValues(alpha: 0.07),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(lightX, lightY),
                radius: width * 0.55,
              ),
            ),
    );

    canvas.drawCircle(
      Offset(lightX, lightY),
      width * 0.17,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                lightColor.withValues(alpha: 0.38),
                coronaColor.withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(lightX, lightY),
                radius: width * 0.17,
              ),
            ),
    );

    if (isEclipse) {
      canvas.drawCircle(
        Offset(lightX, lightY),
        width * 0.085,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.transparent,
                  coronaColor.withValues(alpha: 0.8),
                  Colors.white,
                ],
                stops: const [0.75, 0.92, 1.0],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(lightX, lightY),
                  radius: width * 0.085,
                ),
              ),
      );

      canvas.drawCircle(
        Offset(lightX, lightY),
        width * 0.076,
        Paint()..color = const Color(0xFF07090C),
      );
    } else {
      canvas.drawCircle(
        Offset(lightX, lightY),
        width * 0.078,
        Paint()
          ..shader = RadialGradient(colors: [Colors.white, lightColor])
              .createShader(
                Rect.fromCircle(
                  center: Offset(lightX, lightY),
                  radius: width * 0.078,
                ),
              ),
      );

      canvas.drawCircle(
        Offset(lightX, lightY),
        width * 0.084,
        Paint()
          ..color = lightColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
  }

  void _drawBreathPacer(
    Canvas canvas,
    double width,
    double lightX,
    double lightY,
    Color lightColor,
  ) {
    final baseRadius = width * 0.09;
    final maxRadius = width * 0.22;
    final currentRadius =
        baseRadius + (maxRadius - baseRadius) * breathProgress;

    canvas.drawCircle(
      Offset(lightX, lightY),
      currentRadius,
      Paint()
        ..color = lightColor.withValues(alpha: 0.22 + breathProgress * 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(lightX, lightY),
      currentRadius,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                lightColor.withValues(alpha: 0.1 * breathProgress),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(lightX, lightY),
                radius: currentRadius,
              ),
            ),
    );
  }

  void _drawHorizonHazeAndMist(
    Canvas canvas,
    double width,
    double height,
    double horizon,
    _Palette colors,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - height * 0.16, width, height * 0.16),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colors.light.withValues(alpha: 0.085),
              ],
            ).createShader(
              Rect.fromLTWH(0, horizon - height * 0.16, width, height * 0.16),
            ),
    );
    final mistGlow = Rect.fromLTWH(0, horizon - 28, width, 36);
    canvas.drawRect(
      mistGlow,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colors.skyHorizon.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(mistGlow),
    );
  }

  void _drawMountains(
    Canvas canvas,
    double width,
    double horizon,
    _Palette colors,
  ) {
    final farShore = Path()
      ..moveTo(0, horizon)
      ..lineTo(0, horizon - 38)
      ..cubicTo(
        width * 0.18,
        horizon - 62,
        width * 0.27,
        horizon - 19,
        width * 0.43,
        horizon - 40,
      )
      ..cubicTo(
        width * 0.59,
        horizon - 56,
        width * 0.72,
        horizon - 14,
        width,
        horizon - 44,
      )
      ..lineTo(width, horizon)
      ..close();

    canvas.drawPath(
      farShore,
      Paint()..color = Color.lerp(colors.shore, colors.skyHorizon, 0.38)!,
    );

    final nearShore = Path()
      ..moveTo(0, horizon)
      ..lineTo(0, horizon - 10)
      ..cubicTo(
        width * 0.1,
        horizon - 29,
        width * 0.19,
        horizon - 5,
        width * 0.33,
        horizon - 14,
      )
      ..cubicTo(
        width * 0.5,
        horizon - 30,
        width * 0.58,
        horizon - 5,
        width * 0.72,
        horizon - 12,
      )
      ..cubicTo(
        width * 0.85,
        horizon - 31,
        width * 0.94,
        horizon - 13,
        width,
        horizon - 18,
      )
      ..lineTo(width, horizon)
      ..close();

    canvas.drawPath(nearShore, Paint()..color = colors.shore);
  }

  void _drawParticles(
    Canvas canvas,
    double width,
    double height,
    Color particleColor,
    double movement,
  ) {
    for (final p in particles) {
      final pulse = 0.75 + math.sin(p.phase) * 0.25;
      final px = p.x * width;
      final py = p.y * height;

      canvas.drawCircle(
        Offset(px, py),
        p.size * pulse,
        Paint()
          ..color = particleColor.withValues(
            alpha: p.opacity * pulse * (0.4 + movement * 0.6),
          ),
      );
    }
  }

  void _drawRipples(
    Canvas canvas,
    double width,
    double height,
    double horizon,
    Color lightColor,
  ) {
    for (final ripple in ripples) {
      final age = ((now - ripple.startedAt) / 2800).clamp(0.0, 1.0);
      final center = Offset(
        ripple.x * width,
        math.max(ripple.y * height, horizon + 20),
      );

      for (var ring = 0; ring < 3; ring++) {
        final progress = (age - ring * 0.11).clamp(0.0, 1.0);
        if (progress <= 0) continue;
        final radius = 12 + progress * width * 0.32;
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: radius * 2,
            height: radius * 0.46,
          ),
          Paint()
            ..color = lightColor.withValues(alpha: 0.38 * (1 - progress))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WaterPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.tiltX != tiltX ||
      oldDelegate.tiltY != tiltY ||
      oldDelegate.stillness != stillness ||
      oldDelegate.moodValue != moodValue ||
      oldDelegate.lightPosition != lightPosition ||
      oldDelegate.now != now ||
      oldDelegate.breathProgress != breathProgress ||
      oldDelegate.breathPacerActive != breathPacerActive ||
      oldDelegate.ripples.length != ripples.length ||
      oldDelegate.shootingStars.length != shootingStars.length;
}

class _Palette {
  final Color skyTop;
  final Color skyMiddle;
  final Color skyHorizon;
  final Color light;
  final Color coronaColor;
  final Color shore;
  final Color waterTop;
  final Color waterMiddle;
  final Color waterBottom;
  final Color waterHighlight;
  final Color particleColor;
  final double auroraIntensity;
  final double starAlpha;
  final bool isEclipse;

  const _Palette({
    required this.skyTop,
    required this.skyMiddle,
    required this.skyHorizon,
    required this.light,
    required this.coronaColor,
    required this.shore,
    required this.waterTop,
    required this.waterMiddle,
    required this.waterBottom,
    required this.waterHighlight,
    required this.particleColor,
    required this.auroraIntensity,
    required this.starAlpha,
    required this.isEclipse,
  });
}

_Palette _getStaticPalette(WaterMood mood) {
  switch (mood) {
    case WaterMood.dusk:
      return const _Palette(
        skyTop: Color(0xFF0A121D),
        skyMiddle: Color(0xFF243242),
        skyHorizon: Color(0xFF7D594C),
        light: Color(0xFFFFD4A7),
        coronaColor: Color(0xFFFF9E53),
        shore: Color(0xFF172630),
        waterTop: Color(0xFF334B52),
        waterMiddle: Color(0xFF132B38),
        waterBottom: Color(0xFF08151F),
        waterHighlight: Color(0xFFE5D5C5),
        particleColor: Color(0xFFFFE1C4),
        auroraIntensity: 0.0,
        starAlpha: 0.15,
        isEclipse: false,
      );

    case WaterMood.night:
      return const _Palette(
        skyTop: Color(0xFF030713),
        skyMiddle: Color(0xFF0D172E),
        skyHorizon: Color(0xFF222B52),
        light: Color(0xFFD6E9FF),
        coronaColor: Color(0xFF4C7BBD),
        shore: Color(0xFF0E1528),
        waterTop: Color(0xFF1C2C4E),
        waterMiddle: Color(0xFF0E1A33),
        waterBottom: Color(0xFF050B18),
        waterHighlight: Color(0xFF90B4E2),
        particleColor: Color(0xFFBCE0FD),
        auroraIntensity: 0.35,
        starAlpha: 0.85,
        isEclipse: false,
      );

    case WaterMood.dawn:
      return const _Palette(
        skyTop: Color(0xFF152232),
        skyMiddle: Color(0xFF4A687D),
        skyHorizon: Color(0xFFD68E75),
        light: Color(0xFFFFE8C2),
        coronaColor: Color(0xFFFFB685),
        shore: Color(0xFF223542),
        waterTop: Color(0xFF3D6B77),
        waterMiddle: Color(0xFF1A495C),
        waterBottom: Color(0xFF0B2432),
        waterHighlight: Color(0xFFFFEBD2),
        particleColor: Color(0xFFFFE7C7),
        auroraIntensity: 0.0,
        starAlpha: 0.1,
        isEclipse: false,
      );

    case WaterMood.aurora:
      return const _Palette(
        skyTop: Color(0xFF030D12),
        skyMiddle: Color(0xFF082226),
        skyHorizon: Color(0xFF134542),
        light: Color(0xFF88FEE4),
        coronaColor: Color(0xFF22D9A9),
        shore: Color(0xFF0A1F22),
        waterTop: Color(0xFF124343),
        waterMiddle: Color(0xFF0A292C),
        waterBottom: Color(0xFF031416),
        waterHighlight: Color(0xFF76FCD9),
        particleColor: Color(0xFF5FF6D1),
        auroraIntensity: 1.0,
        starAlpha: 0.7,
        isEclipse: false,
      );

    case WaterMood.eclipse:
      return const _Palette(
        skyTop: Color(0xFF050608),
        skyMiddle: Color(0xFF11141B),
        skyHorizon: Color(0xFF242A36),
        light: Color(0xFFE8EEF5),
        coronaColor: Color(0xFF9CB2CD),
        shore: Color(0xFF10131A),
        waterTop: Color(0xFF222938),
        waterMiddle: Color(0xFF121620),
        waterBottom: Color(0xFF07090D),
        waterHighlight: Color(0xFFD6E4F0),
        particleColor: Color(0xFFCAD8E8),
        auroraIntensity: 0.0,
        starAlpha: 0.95,
        isEclipse: true,
      );

    case WaterMood.emerald:
      return const _Palette(
        skyTop: Color(0xFF05120D),
        skyMiddle: Color(0xFF0E281F),
        skyHorizon: Color(0xFF20483A),
        light: Color(0xFFD0F8DC),
        coronaColor: Color(0xFF4EE299),
        shore: Color(0xFF0D241C),
        waterTop: Color(0xFF1E4C3B),
        waterMiddle: Color(0xFF103326),
        waterBottom: Color(0xFF051811),
        waterHighlight: Color(0xFF97F3C4),
        particleColor: Color(0xFF67F5B1),
        auroraIntensity: 0.25,
        starAlpha: 0.45,
        isEclipse: false,
      );
  }
}

_Palette _resolvePalette(double moodValue) {
  final moods = WaterMood.values;
  final clamped = moodValue.clamp(0.0, moods.length - 1.0);
  final index = clamped.floor();
  final remainder = clamped - index;

  final p1 = _getStaticPalette(moods[index]);
  if (remainder <= 0.001 || index >= moods.length - 1) {
    return p1;
  }
  final p2 = _getStaticPalette(moods[index + 1]);

  return _Palette(
    skyTop: Color.lerp(p1.skyTop, p2.skyTop, remainder)!,
    skyMiddle: Color.lerp(p1.skyMiddle, p2.skyMiddle, remainder)!,
    skyHorizon: Color.lerp(p1.skyHorizon, p2.skyHorizon, remainder)!,
    light: Color.lerp(p1.light, p2.light, remainder)!,
    coronaColor: Color.lerp(p1.coronaColor, p2.coronaColor, remainder)!,
    shore: Color.lerp(p1.shore, p2.shore, remainder)!,
    waterTop: Color.lerp(p1.waterTop, p2.waterTop, remainder)!,
    waterMiddle: Color.lerp(p1.waterMiddle, p2.waterMiddle, remainder)!,
    waterBottom: Color.lerp(p1.waterBottom, p2.waterBottom, remainder)!,
    waterHighlight: Color.lerp(
      p1.waterHighlight,
      p2.waterHighlight,
      remainder,
    )!,
    particleColor: Color.lerp(p1.particleColor, p2.particleColor, remainder)!,
    auroraIntensity:
        p1.auroraIntensity +
        (p2.auroraIntensity - p1.auroraIntensity) * remainder,
    starAlpha: p1.starAlpha + (p2.starAlpha - p1.starAlpha) * remainder,
    isEclipse: remainder > 0.5 ? p2.isEclipse : p1.isEclipse,
  );
}
