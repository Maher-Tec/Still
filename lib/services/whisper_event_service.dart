import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Whisper Event Service
/// 
/// Rare, random events that occur once every 10-20 minutes.
/// Either a soft tone or a subtle light flicker.
/// 
/// CRITICAL: These must be unexpected, not rhythmic.
/// The user should never anticipate when the next event will occur.
class WhisperEventService {
  static final WhisperEventService _instance = WhisperEventService._internal();
  factory WhisperEventService() => _instance;
  WhisperEventService._internal();

  final Random _random = Random();
  Timer? _eventTimer;
  AudioPlayer? _whisperPlayer;
  
  // Callback for visual flicker events
  VoidCallback? onFlickerEvent;

  /// Start the whisper event scheduler
  void start() {
    _scheduleNextEvent();
  }

  /// Stop all whisper events
  void stop() {
    _eventTimer?.cancel();
    _eventTimer = null;
    _whisperPlayer?.dispose();
    _whisperPlayer = null;
  }

  void _scheduleNextEvent() {
    _eventTimer?.cancel();
    
    // Random interval: 10-20 minutes (600-1200 seconds)
    final minSeconds = 600;
    final maxSeconds = 1200;
    final delaySeconds = minSeconds + _random.nextInt(maxSeconds - minSeconds);
    
    _eventTimer = Timer(Duration(seconds: delaySeconds), () {
      _triggerEvent();
      _scheduleNextEvent(); // Schedule next event
    });
  }

  void _triggerEvent() {
    // 50/50 chance: audio whisper or visual flicker
    if (_random.nextBool()) {
      _triggerAudioWhisper();
    } else {
      _triggerVisualFlicker();
    }
  }

  Future<void> _triggerAudioWhisper() async {
    try {
      _whisperPlayer?.dispose();
      _whisperPlayer = AudioPlayer();
      
      // Very quiet whisper tone
      await _whisperPlayer!.setVolume(0.02); // 2% volume
      await _whisperPlayer!.play(AssetSource('audio/whisper_tone.mp3'));
    } catch (e) {
      // Silently fail - sound is optional
    }
  }

  void _triggerVisualFlicker() {
    onFlickerEvent?.call();
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}

/// Widget that displays a subtle flicker effect
class WhisperFlicker extends StatefulWidget {
  final Widget child;

  const WhisperFlicker({
    super.key,
    required this.child,
  });

  @override
  State<WhisperFlicker> createState() => WhisperFlickerState();
}

class WhisperFlickerState extends State<WhisperFlicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Subtle flicker curve: quick brighten, slow fade
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.03), // 3% brightness increase
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.03, end: 0.0),
        weight: 80,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger a flicker effect
  void flicker() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[
            1 + _animation.value, 0, 0, 0, 0,
            0, 1 + _animation.value, 0, 0, 0,
            0, 0, 1 + _animation.value, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: widget.child,
        );
      },
    );
  }
}
