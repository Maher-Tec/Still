import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
class AmbientToneService {
  static final AmbientToneService _instance = AmbientToneService._internal();
  factory AmbientToneService() => _instance;
  AmbientToneService._internal();

  AudioPlayer? _player;
  AudioPlayer? _startingPlayer;
  Timer? _fadeTimer;
  double _currentVolume = 0.0;
  bool _isPlaying = false;
  int _generation = 0;
  static const double _targetVolume = 0.04;
  static const double _fadeInDuration = 5.0;
  static const int _fadeSteps = 10;

  static const Map<int, String> _moodAssets = {
    0: 'audio/dusk.mp3',
    1: 'audio/Midnight.mp3',
    2: 'audio/Eclipse.mp3',
    3: 'audio/Emerald.mp3',
    4: 'audio/Aurora.mp3',
    5: 'audio/Dawn.mp3',
  };

  String? _currentAsset;
  Future<void> start({int moodIndex = 0}) async {
    final asset = _moodAssets[moodIndex] ?? _moodAssets[0]!;
    if (_isPlaying && _currentAsset == asset) return;
    await stop();
    final generation = ++_generation;
    final player = AudioPlayer();
    _startingPlayer = player;

    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.0);
      _currentVolume = 0.0;

      await player.play(AssetSource(asset));
      if (generation != _generation) {
        await player.stop();
        await player.dispose();
        return;
      }
      _player = player;
      _currentAsset = asset;
      _startingPlayer = null;
      _isPlaying = true;
      _fadeIn();
    } catch (e) {
      if (identical(_startingPlayer, player)) _startingPlayer = null;
      await player.dispose();
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
  Future<void> stop() async {
    _generation++;
    _fadeTimer?.cancel();
    _isPlaying = false;
    final startingPlayer = _startingPlayer;
    _startingPlayer = null;
    await startingPlayer?.stop();
    await startingPlayer?.dispose();
    await _player?.stop();
    await _player?.dispose();
    _player = null;
    _currentAsset = null;
    _currentVolume = 0.0;
  }
  Future<void> dispose() async {
    await stop();
  }
}
