import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Ambient Tone Service
/// 
/// Low neutral presence tone - barely audible.
/// Characteristics:
/// - No melody, no rhythm, no nature, no emotion
/// - Frequency range: 30-60 Hz base
/// - Volume: 3-6%
/// - Fade in: 4-6s
/// - Fade out: instant on app exit
/// 
/// The sound should feel like: the electricity in a quiet room.
/// If users say "nice sound" → wrong.
/// If they forget it exists → correct.
class AmbientToneService {
  static final AmbientToneService _instance = AmbientToneService._internal();
  factory AmbientToneService() => _instance;
  AmbientToneService._internal();

  AudioPlayer? _player;
  Timer? _fadeTimer;
  double _currentVolume = 0.0;
  bool _isPlaying = false;

  // Volume range: 3-6%
  static const double _targetVolume = 0.04; // 4%
  static const double _fadeInDuration = 5.0; // 5 seconds
  static const int _fadeSteps = 50;

  /// Start ambient tone with slow fade in
  Future<void> start() async {
    if (_isPlaying) return;
    
    try {
      _player = AudioPlayer();
      
      // Set to loop mode
      await _player!.setReleaseMode(ReleaseMode.loop);
      
      // Start at zero volume
      await _player!.setVolume(0.0);
      _currentVolume = 0.0;
      
      // Play the ambient tone
      await _player!.play(AssetSource('audio/ambient_tone.mp3'));
      _isPlaying = true;
      
      // Fade in slowly
      _fadeIn();
    } catch (e) {
      // Silently fail - sound is optional
      debugPrint('Ambient tone unavailable: $e');
    }
  }

  void _fadeIn() {
    _fadeTimer?.cancel();
    
    final stepDuration = Duration(
      milliseconds: (_fadeInDuration * 1000 / _fadeSteps).round(),
    );
    final volumeStep = _targetVolume / _fadeSteps;
    
    _fadeTimer = Timer.periodic(stepDuration, (timer) {
      _currentVolume = min(_currentVolume + volumeStep, _targetVolume);
      _player?.setVolume(_currentVolume);
      
      if (_currentVolume >= _targetVolume) {
        timer.cancel();
      }
    });
  }

  /// Stop ambient tone immediately (no fade out)
  Future<void> stop() async {
    _fadeTimer?.cancel();
    _isPlaying = false;
    
    // Instant stop - the app does not acknowledge departure
    await _player?.stop();
    await _player?.dispose();
    _player = null;
    _currentVolume = 0.0;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
  }
}
