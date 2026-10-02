import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:still/widgets/ambient_water_scene.dart';

class ModeDialItem {
  final WaterMood mood;
  final String title;
  final String subtitle;
  final String imagePath;
  final Color primaryColor;
  final Color glowColor;

  const ModeDialItem({
    required this.mood,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.primaryColor,
    required this.glowColor,
  });
}

const List<ModeDialItem> kModeDialItems = [
  ModeDialItem(
    mood: WaterMood.dusk,
    title: 'D U S K',
    subtitle: 'Warm • Atmospheric',
    imagePath: 'assets/images/modes/dusk.png',
    primaryColor: Color(0xFFFF5E1E),
    glowColor: Color(0xFFFF3D00),
  ),
  ModeDialItem(
    mood: WaterMood.night,
    title: 'M I D N I G H T',
    subtitle: 'Quiet • Deep',
    imagePath: 'assets/images/modes/midnight.png',
    primaryColor: Color(0xFF6B9FFF),
    glowColor: Color(0xFF3377FF),
  ),
  ModeDialItem(
    mood: WaterMood.eclipse,
    title: 'E C L I P S E',
    subtitle: 'Deep • Focused',
    imagePath: 'assets/images/modes/eclipse.png',
    primaryColor: Color(0xFFC06AFF),
    glowColor: Color(0xFFA62BFF),
  ),
  ModeDialItem(
    mood: WaterMood.emerald,
    title: 'E M E R A L D',
    subtitle: 'Fresh • Grounded',
    imagePath: 'assets/images/modes/emerald.png',
    primaryColor: Color(0xFF2EEDB0),
    glowColor: Color(0xFF00D692),
  ),
  ModeDialItem(
    mood: WaterMood.aurora,
    title: 'A U R O R A',
    subtitle: 'Calm • Immersive',
    imagePath: 'assets/images/modes/aurora.png',
    primaryColor: Color(0xFF26E6E6),
    glowColor: Color(0xFF00BFBF),
  ),
  ModeDialItem(
    mood: WaterMood.dawn,
    title: 'D A W N',
    subtitle: 'Soft • Energizing',
    imagePath: 'assets/images/modes/dawn.png',
    primaryColor: Color(0xFFFFB338),
    glowColor: Color(0xFFFF9400),
  ),
];
class ModeDial extends StatefulWidget {
  final WaterMood selectedMood;
  final ValueChanged<WaterMood> onMoodChanged;
  final ValueChanged<double>? onProgressChanged;
  final bool hapticsEnabled;

  const ModeDial({
    super.key,
    required this.selectedMood,
    required this.onMoodChanged,
    this.onProgressChanged,
    this.hapticsEnabled = true,
  });

  @override
  State<ModeDial> createState() => _ModeDialState();
}

class _ModeDialState extends State<ModeDial>
    with TickerProviderStateMixin {
  late final AnimationController _snapController;
  late final AnimationController _orbitController;
  Animation<double>? _snapAnimation;
  late double _currentProgress;
  int _lastHapticSegment = 0;
  bool _isDragging = false;
  static const double _startAngleDeg = 165.0;
  static const double _endAngleDeg = 15.0;
  static const double _angleSpanDeg = _startAngleDeg - _endAngleDeg;
  static const double _angleStepDeg = _angleSpanDeg / 5.0;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.selectedMood.index.toDouble();
    _lastHapticSegment = widget.selectedMood.index;

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant ModeDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMood != widget.selectedMood && !_isDragging) {
      final targetProgress = widget.selectedMood.index.toDouble();
      if ((_currentProgress - targetProgress).abs() > 0.05 &&
          !_snapController.isAnimating) {
        _animateToMode(targetProgress);
      }
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _animateToMode(double targetProgress) {
    _snapController.stop();
    final startVal = _currentProgress;
    _snapAnimation = Tween<double>(
      begin: startVal,
      end: targetProgress,
    ).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    )..addListener(() {
        final val = _snapAnimation!.value;
        setState(() {
          _currentProgress = val;
        });
        widget.onProgressChanged?.call(val);
      });

    _snapController.forward(from: 0.0).then((_) {
      if (mounted) {
        final finalIndex =
            _currentProgress.round().clamp(0, kModeDialItems.length - 1);
        widget.onMoodChanged(kModeDialItems[finalIndex].mood);
      }
    });
  }

  double _angleFromProgress(double progress) {
    final deg = _startAngleDeg - progress * _angleStepDeg;
    return deg * math.pi / 180.0;
  }

  double _progressFromAngle(double angleRad) {
    double deg = angleRad * 180.0 / math.pi;
    if (deg < -90) deg += 360;
    final raw = (_startAngleDeg - deg) / _angleStepDeg;
    return raw.clamp(0.0, 5.0);
  }

  Offset _getPivot(Size size) => Offset(size.width * 0.50, size.height * 0.70);
  double _getOrbitRadius(Size size) => size.width * 0.42;

  void _handleTouch(Offset localPos, Size size) {
    final pivot = _getPivot(size);
    final dx = localPos.dx - pivot.dx;
    final dy = pivot.dy - localPos.dy;

    if (dy <= -20) return;

    double angle = math.atan2(dy, dx);
    final newProgress = _progressFromAngle(angle);

    final segment = newProgress.round();
    if (segment != _lastHapticSegment) {
      _lastHapticSegment = segment;
      if (widget.hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
    }

    setState(() {
      _currentProgress = newProgress;
    });
    widget.onProgressChanged?.call(_currentProgress);
  }

  void _onPanStart(DragStartDetails details, Size size) {
    _isDragging = true;
    _snapController.stop();
    _handleTouch(details.localPosition, size);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    _handleTouch(details.localPosition, size);
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    final targetIndex =
        _currentProgress.round().clamp(0, kModeDialItems.length - 1);
    if (widget.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    _animateToMode(targetIndex.toDouble());
  }

  void _onPlanetTapped(int index) {
    if (widget.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _animateToMode(index.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex =
        _currentProgress.round().clamp(0, kModeDialItems.length - 1);
    final activeItem = kModeDialItems[activeIndex];

    final lowerIndex =
        _currentProgress.floor().clamp(0, kModeDialItems.length - 1);
    final upperIndex =
        _currentProgress.ceil().clamp(0, kModeDialItems.length - 1);
    final remainder = _currentProgress - lowerIndex;
    final interpolatedColor = Color.lerp(
      kModeDialItems[lowerIndex].primaryColor,
      kModeDialItems[upperIndex].primaryColor,
      remainder,
    )!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dialWidth = math.min(constraints.maxWidth, 380.0);
        final dialHeight = dialWidth * 0.72;
        final size = Size(dialWidth, dialHeight);

        final pivot = _getPivot(size);
        final orbitRadius = _getOrbitRadius(size);

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _onPanStart(d, size),
                    onPanUpdate: (d) => _onPanUpdate(d, size),
                    onPanEnd: _onPanEnd,
                    child: SizedBox(
                      width: dialWidth,
                      height: dialHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              size: size,
                              painter: _CelestialOrreryPainter(
                                pivot: pivot,
                                orbitRadius: orbitRadius,
                                progress: _currentProgress,
                                interpolatedColor: interpolatedColor,
                                needleAngle:
                                    _angleFromProgress(_currentProgress),
                              ),
                            ),
                          ),
                          for (int i = 0; i < kModeDialItems.length; i++) ...[
                            _buildPlanetOrb(
                              index: i,
                              pivot: pivot,
                              orbitRadius: orbitRadius,
                              item: kModeDialItems[i],
                              progress: _currentProgress,
                              orbitAnimValue: _orbitController.value,
                            ),
                          ],
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                size: size,
                                painter: _CentralCorePainter(
                                  pivot: pivot,
                                  interpolatedColor: interpolatedColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      key: ValueKey(activeItem.title),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeItem.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: activeItem.primaryColor,
                            fontSize: 17.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 5.5,
                            shadows: [
                              Shadow(
                                color: activeItem.primaryColor
                                    .withValues(alpha: 0.9),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeItem.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 28,
                          height: 2.4,
                          decoration: BoxDecoration(
                            color: activeItem.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: activeItem.primaryColor
                                    .withValues(alpha: 0.85),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlanetOrb({
    required int index,
    required Offset pivot,
    required double orbitRadius,
    required ModeDialItem item,
    required double progress,
    required double orbitAnimValue,
  }) {
    final angleRad = _angleFromProgress(index.toDouble());
    final planetX = pivot.dx + math.cos(angleRad) * orbitRadius;
    final planetY = pivot.dy - math.sin(angleRad) * orbitRadius;

    final distance = (progress - index).abs();
    final activeAmount = (1.0 - distance).clamp(0.0, 1.0);

    const double baseDiameter = 52.0;

    return Positioned(
      left: planetX - 44,
      top: planetY - 44,
      width: 88,
      height: 88,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onPlanetTapped(index),
        child: Center(
          child: Transform.scale(
            scale: 1.0 + 0.25 * activeAmount,
            child: SizedBox(
              width: baseDiameter,
              height: baseDiameter,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -20,
                    top: -16,
                    width: baseDiameter + 40,
                    height: baseDiameter + 32,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PlanetaryRingPainter(
                          isFront: false,
                          activeAmount: activeAmount,
                          glowColor: item.glowColor,
                          primaryColor: item.primaryColor,
                          animValue: orbitAnimValue,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: baseDiameter,
                    height: baseDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (activeAmount > 0.08)
                          BoxShadow(
                            color: item.glowColor.withValues(
                              alpha: 0.65 * activeAmount,
                            ),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                item.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          item.primaryColor,
                                          item.glowColor
                                              .withValues(alpha: 0.4),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                color: Colors.black.withValues(
                                  alpha: 0.35 * (1.0 - activeAmount),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.95,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.45),
                                    ],
                                    stops: const [0.70, 1.0],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.35),
                                      Colors.white.withValues(alpha: 0.05),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.25),
                                    ],
                                    stops: const [0.0, 0.28, 0.65, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.lerp(
                                Colors.white.withValues(alpha: 0.20),
                                item.primaryColor,
                                activeAmount,
                              )!,
                              width: activeAmount > 0.5 ? 2.0 : 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: -20,
                    top: -16,
                    width: baseDiameter + 40,
                    height: baseDiameter + 32,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PlanetaryRingPainter(
                          isFront: true,
                          activeAmount: activeAmount,
                          glowColor: item.glowColor,
                          primaryColor: item.primaryColor,
                          animValue: orbitAnimValue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _CelestialOrreryPainter extends CustomPainter {
  final Offset pivot;
  final double orbitRadius;
  final double progress;
  final Color interpolatedColor;
  final double needleAngle;

  const _CelestialOrreryPainter({
    required this.pivot,
    required this.orbitRadius,
    required this.progress,
    required this.interpolatedColor,
    required this.needleAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 0.9;
    const startRad = 165.0 * math.pi / 180.0;
    const sweepRad = -150.0 * math.pi / 180.0;

    final orbitRect = Rect.fromCircle(center: pivot, radius: orbitRadius);
    canvas.drawArc(orbitRect, -startRad, -sweepRad, false, orbitPaint);
    final innerChronometerRadius = orbitRadius * 0.62;
    final innerRect =
        Rect.fromCircle(center: pivot, radius: innerChronometerRadius);

    canvas.drawArc(
      innerRect,
      -startRad,
      -sweepRad,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 0.8,
    );
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    const int totalTicks = 36;
    for (int t = 0; t <= totalTicks; t++) {
      final tickAngleDeg = 165.0 - t * (150.0 / totalTicks);
      final tickAngleRad = tickAngleDeg * math.pi / 180.0;
      final isMajor = t % 6 == 0;
      final tickLength = isMajor ? 5.0 : 2.5;

      final tX1 = pivot.dx + math.cos(tickAngleRad) * innerChronometerRadius;
      final tY1 = pivot.dy - math.sin(tickAngleRad) * innerChronometerRadius;
      final tX2 = pivot.dx +
          math.cos(tickAngleRad) * (innerChronometerRadius - tickLength);
      final tY2 = pivot.dy -
          math.sin(tickAngleRad) * (innerChronometerRadius - tickLength);

      tickPaint
        ..strokeWidth = isMajor ? 1.0 : 0.6
        ..color = isMajor
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.10);

      canvas.drawLine(Offset(tX1, tY1), Offset(tX2, tY2), tickPaint);
    }
    for (int i = 0; i < 6; i++) {
      final pAngle = (165.0 - i * 30.0) * math.pi / 180.0;
      final sX = pivot.dx + math.cos(pAngle) * (innerChronometerRadius + 2);
      final sY = pivot.dy - math.sin(pAngle) * (innerChronometerRadius + 2);
      final eX = pivot.dx + math.cos(pAngle) * (orbitRadius - 28);
      final eY = pivot.dy - math.sin(pAngle) * (orbitRadius - 28);

      canvas.drawLine(
        Offset(sX, sY),
        Offset(eX, eY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 0.6,
      );
    }
    final targetRadius = orbitRadius;
    final tipX = pivot.dx + math.cos(needleAngle) * targetRadius;
    final tipY = pivot.dy - math.sin(needleAngle) * targetRadius;
    canvas.drawLine(
      Offset(pivot.dx, pivot.dy + 3),
      Offset(tipX, tipY + 3),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.50)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawLine(
      pivot,
      Offset(tipX, tipY),
      Paint()
        ..color = interpolatedColor.withValues(alpha: 0.45)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawLine(
      pivot,
      Offset(tipX, tipY),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white,
            interpolatedColor,
          ],
          stops: const [0.15, 0.95],
        ).createShader(Rect.fromPoints(pivot, Offset(tipX, tipY)))
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(tipX, tipY),
      5.5,
      Paint()
        ..color = interpolatedColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawCircle(
      Offset(tipX, tipY),
      3.8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    canvas.drawCircle(
      Offset(tipX, tipY),
      1.8,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CelestialOrreryPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.interpolatedColor != interpolatedColor ||
      oldDelegate.needleAngle != needleAngle;
}
class _CentralCorePainter extends CustomPainter {
  final Offset pivot;
  final Color interpolatedColor;

  const _CentralCorePainter({
    required this.pivot,
    required this.interpolatedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double coreRadius = 38.0;
    canvas.drawCircle(
      pivot,
      coreRadius + 5,
      Paint()
        ..color = interpolatedColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      pivot,
      coreRadius,
      Paint()
        ..color = interpolatedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      pivot,
      coreRadius - 1.2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.9,
          colors: [
            const Color(0xFF192734),
            const Color(0xFF0C141C),
            const Color(0xFF03070A),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: pivot, radius: coreRadius)),
    );
    final glossPath = Path()
      ..addArc(
        Rect.fromCircle(center: pivot, radius: coreRadius - 3.0),
        math.pi * 0.9,
        math.pi * 0.7,
      );
    canvas.drawPath(
      glossPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    canvas.drawCircle(
      pivot,
      12.0,
      Paint()
        ..color = interpolatedColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      pivot,
      3.6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CentralCorePainter oldDelegate) =>
      oldDelegate.interpolatedColor != interpolatedColor;
}
class _PlanetaryRingPainter extends CustomPainter {
  final bool isFront;
  final double activeAmount;
  final Color glowColor;
  final Color primaryColor;
  final double animValue;

  const _PlanetaryRingPainter({
    required this.isFront,
    required this.activeAmount,
    required this.glowColor,
    required this.primaryColor,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.50);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-22.0 * math.pi / 180.0);

    final ringRadiusX = size.width * 0.48;
    final ringRadiusY = size.height * 0.20;

    final ringRect = Rect.fromCenter(
      center: Offset.zero,
      width: ringRadiusX * 2,
      height: ringRadiusY * 2,
    );
    final startAngle = isFront ? 0.0 : math.pi;
    const sweepAngle = math.pi;

    if (activeAmount > 0.05) {
      canvas.drawArc(
        ringRect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = glowColor.withValues(alpha: 0.45 * activeAmount)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawArc(
        ringRect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = Color.lerp(
            Colors.white,
            primaryColor,
            0.3,
          )!.withValues(alpha: 0.92 * activeAmount)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      final satAngle = (animValue * 2 * math.pi) % (2 * math.pi);
      final isSatInThisLayer = isFront
          ? (satAngle >= 0 && satAngle <= math.pi)
          : (satAngle > math.pi && satAngle < 2 * math.pi);

      if (isSatInThisLayer) {
        final satX = ringRadiusX * math.cos(satAngle);
        final satY = ringRadiusY * math.sin(satAngle);

        canvas.drawCircle(
          Offset(satX, satY),
          4.8,
          Paint()
            ..color = primaryColor.withValues(alpha: 0.80 * activeAmount)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );

        canvas.drawCircle(
          Offset(satX, satY),
          2.6,
          Paint()..color = Colors.white,
        );
      }
      final sat2Angle = (satAngle + math.pi * 0.85) % (2 * math.pi);
      final isSat2InThisLayer = isFront
          ? (sat2Angle >= 0 && sat2Angle <= math.pi)
          : (sat2Angle > math.pi && sat2Angle < 2 * math.pi);

      if (isSat2InThisLayer) {
        final sat2X = ringRadiusX * math.cos(sat2Angle);
        final sat2Y = ringRadiusY * math.sin(sat2Angle);

        canvas.drawCircle(
          Offset(sat2X, sat2Y),
          1.8,
          Paint()..color = Colors.white.withValues(alpha: 0.85 * activeAmount),
        );
      }
    } else {
      canvas.drawArc(
        ringRect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: isFront ? 0.16 : 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlanetaryRingPainter oldDelegate) =>
      oldDelegate.isFront != isFront ||
      oldDelegate.activeAmount != activeAmount ||
      oldDelegate.animValue != animValue ||
      oldDelegate.glowColor != glowColor;
}
