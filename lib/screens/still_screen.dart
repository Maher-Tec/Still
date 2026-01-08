import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/widgets/subtle_gradient.dart';
import 'package:still/widgets/micro_grain.dart';
import 'package:still/widgets/presence_glow.dart';
import 'package:still/services/ambient_tone_service.dart';
import 'package:still/services/whisper_event_service.dart';

/// The STILL Screen - The Space
/// 
/// This IS the app.
/// 
/// Features:
/// - Subtle depth parallax (accelerometer-based)
/// - Color breathing (5-minute hue shift)
/// - Rare whisper events (every 10-20 min)
/// 
/// INTERACTION RULES (CRITICAL):
/// - Tapping does nothing
/// - Long-press does nothing
/// - Swiping does nothing
class StillScreen extends StatefulWidget {
  const StillScreen({super.key});

  @override
  State<StillScreen> createState() => _StillScreenState();
}

class _StillScreenState extends State<StillScreen> with WidgetsBindingObserver {
  final AmbientToneService _ambientTone = AmbientToneService();
  final WhisperEventService _whisperService = WhisperEventService();
  
  // Parallax state
  double _parallaxX = 0.0;
  double _parallaxY = 0.0;
  StreamSubscription? _accelerometerSubscription;
  
  // Flicker key
  final GlobalKey<WhisperFlickerState> _flickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start ambient tone
    _ambientTone.start();
    
    // Start whisper events
    _whisperService.onFlickerEvent = _onFlicker;
    _whisperService.start();
    
    // Start accelerometer for parallax
    _startAccelerometer();
  }

  void _startAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      setState(() {
        // Normalize accelerometer values to -1 to 1 range
        // Clamp to prevent extreme values
        _parallaxX = (event.x / 10).clamp(-1.0, 1.0);
        _parallaxY = (event.y / 10).clamp(-1.0, 1.0);
      });
    });
  }

  void _onFlicker() {
    _flickerKey.currentState?.flicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambientTone.stop();
    _whisperService.stop();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      _ambientTone.stop();
      _whisperService.stop();
    } else if (state == AppLifecycleState.resumed) {
      _ambientTone.start();
      _whisperService.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getAdaptiveBackground(),
      body: GestureDetector(
        // Absorb all touches - do nothing
        onTap: () {},
        onLongPress: () {},
        onDoubleTap: () {},
        onVerticalDragStart: (_) {},
        onHorizontalDragStart: (_) {},
        behavior: HitTestBehavior.opaque,
        child: WhisperFlicker(
          key: _flickerKey,
          child: Stack(
            children: [
              // Layer 1: Ultra-slow gradient drift with parallax
              Positioned.fill(
                child: SubtleGradient(
                  parallaxX: _parallaxX,
                  parallaxY: _parallaxY,
                ),
              ),
              
              // Layer 2: Presence glow (centered, soft) with parallax offset
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                    _parallaxX * 5, // 5px max shift
                    _parallaxY * 3,
                  ),
                  child: const PresenceGlow(),
                ),
              ),
              
              // Layer 3: Micro grain overlay
              const Positioned.fill(
                child: MicroGrain(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
