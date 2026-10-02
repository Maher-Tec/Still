import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
class WhisperEventService {
  static final WhisperEventService _instance = WhisperEventService._internal();
  factory WhisperEventService() => _instance;
  WhisperEventService._internal();

  final Random _random = Random();
  Timer? _eventTimer;
  AudioPlayer? _whisperPlayer;
  VoidCallback? onFlickerEvent;
  bool soundEnabled = false;
  bool _isRunning = false;
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleNextEvent();
  }
  Future<void> stop() async {
    _isRunning = false;
    _eventTimer?.cancel();
    _eventTimer = null;
    await _whisperPlayer?.stop();
    await _whisperPlayer?.dispose();
    _whisperPlayer = null;
  }

  void _scheduleNextEvent() {
    if (!_isRunning) return;
    _eventTimer?.cancel();
    final minSeconds = 600;
    final maxSeconds = 1200;
    final delaySeconds = minSeconds + _random.nextInt(maxSeconds - minSeconds);

    _eventTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isRunning) return;
      _triggerEvent();
      _scheduleNextEvent();
    });
  }

  void _triggerEvent() {
    if (soundEnabled && _random.nextBool()) {
      _triggerAudioWhisper();
    } else {
      _triggerVisualFlicker();
    }
  }

  Future<void> _triggerAudioWhisper() async {
    try {
      _whisperPlayer?.dispose();
      _whisperPlayer = AudioPlayer();
      await _whisperPlayer!.setVolume(0.02);
      await _whisperPlayer!.play(AssetSource('audio/whisper_tone.mp3'));
    } catch (e) {
    }
  }

  void _triggerVisualFlicker() {
    onFlickerEvent?.call();
  }
  Future<void> dispose() {
    return stop();
  }
}
class WhisperFlicker extends StatefulWidget {
  final Widget child;

  const WhisperFlicker({super.key, required this.child});

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
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.03),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
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
            1 + _animation.value,
            0,
            0,
            0,
            0,
            0,
            1 + _animation.value,
            0,
            0,
            0,
            0,
            0,
            1 + _animation.value,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: widget.child,
        );
      },
    );
  }
}
