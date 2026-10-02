import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still/core/app_colors.dart';
import 'package:still/services/ambient_tone_service.dart';
import 'package:still/services/whisper_event_service.dart';
import 'package:still/widgets/ambient_water_scene.dart';
import 'package:still/widgets/mode_dial.dart';

enum BreathRhythm {
  box('Box Breathing', 4, 4, 4, 4, '4-4-4-4 balance & focus'),
  calm('Deep Calm', 4, 7, 8, 0, '4-7-8 parasympathetic release'),
  flow('Gentle Flow', 4, 0, 4, 0, '4-4 coherent natural flow');

  final String title;
  final int inhale;
  final int holdIn;
  final int exhale;
  final int holdOut;
  final String subtitle;

  const BreathRhythm(
    this.title,
    this.inhale,
    this.holdIn,
    this.exhale,
    this.holdOut,
    this.subtitle,
  );

  int get totalDuration => inhale + holdIn + exhale + holdOut;
}
class StillScreen extends StatefulWidget {
  final bool soundEnabled;
  final bool motionEnabled;
  final bool hapticsEnabled;
  final int initialMoodIndex;

  const StillScreen({
    super.key,
    this.soundEnabled = false,
    this.motionEnabled = true,
    this.hapticsEnabled = false,
    this.initialMoodIndex = 0,
  });

  @override
  State<StillScreen> createState() => _StillScreenState();
}

class _StillScreenState extends State<StillScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AmbientToneService _ambientTone;
  late final WhisperEventService _whisperService;
  bool _isActive = false;

  late final AnimationController _settleController;
  late final AnimationController _hudVisibilityController;
  late final AnimationController _breathController;

  late WaterMood _mood;
  late final ValueNotifier<double> _dialProgressNotifier;
  late final ValueNotifier<Offset> _parallaxNotifier;

  late bool _soundEnabled;
  late bool _motionEnabled;
  late bool _hapticsEnabled;
  bool _breathPacerEnabled = false;
  BreathRhythm _breathRhythm = BreathRhythm.box;

  Timer? _stillnessTimer;
  Timer? _hudInactivityTimer;
  Timer? _sleepTimer;
  int _sleepTimerMinutesRemaining = 0;

  double? _previousX;
  double? _previousY;
  double? _previousZ;

  static const double _tiltUpdateThreshold = 0.035;
  StreamSubscription? _accelerometerSubscription;
  int _stillnessSeconds = 0;
  Timer? _sessionDurationTimer;
  final GlobalKey<WhisperFlickerState> _flickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ambientTone = AmbientToneService();
    _soundEnabled = widget.soundEnabled;
    _motionEnabled = widget.motionEnabled;
    _hapticsEnabled = widget.hapticsEnabled;
    _mood = WaterMood
        .values[widget.initialMoodIndex.clamp(0, WaterMood.values.length - 1)];
    _dialProgressNotifier = ValueNotifier<double>(_mood.index.toDouble());
    _parallaxNotifier = ValueNotifier<Offset>(Offset.zero);
    _whisperService = WhisperEventService()..soundEnabled = _soundEnabled;

    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _hudVisibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );

    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _breathRhythm.totalDuration),
    );

    WidgetsBinding.instance.addObserver(this);
    _whisperService.onFlickerEvent = _onFlicker;

    _loadStoredPreferences();
    _activate();
    _resetHudInactivityTimer();
  }

  Future<void> _loadStoredPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final breathPref = prefs.getBool('breath_pacer_enabled') ?? false;
    final rhythmIndex = prefs.getInt('breath_rhythm_index') ?? 0;
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _breathPacerEnabled = breathPref;
        _breathRhythm = BreathRhythm
            .values[rhythmIndex.clamp(0, BreathRhythm.values.length - 1)];
      });
      if (_breathPacerEnabled) {
        _startBreathPacer();
      }
    });
  }

  void _resetHudInactivityTimer() {
    _hudInactivityTimer?.cancel();
    if (_hudVisibilityController.value < 1.0) {
      _hudVisibilityController.forward();
    }
    _hudInactivityTimer = Timer(const Duration(milliseconds: 5500), () {
      if (mounted) {
        _hudVisibilityController.reverse();
      }
    });
  }

  void _onUserInteraction() {
    _resetHudInactivityTimer();
  }

  void _startBreathPacer() {
    _breathController.duration = Duration(seconds: _breathRhythm.totalDuration);
    _breathController.repeat();
  }

  void _stopBreathPacer() {
    _breathController.stop();
    _breathController.reset();
  }

  void _activate() {
    if (_isActive) return;
    _isActive = true;
    if (_soundEnabled) _ambientTone.start(moodIndex: _mood.index);
    _whisperService.start();
    if (_accelerometerSubscription == null) _startAccelerometer();

    _sessionDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_settleController.value > 0.8) {
        _stillnessSeconds++;
      }
    });
  }

  Future<void> _deactivate() async {
    if (!_isActive) return;
    _isActive = false;
    final subscription = _accelerometerSubscription;
    _accelerometerSubscription = null;
    _stillnessTimer?.cancel();
    _stillnessTimer = null;
    _hudInactivityTimer?.cancel();
    _hudInactivityTimer = null;
    _sessionDurationTimer?.cancel();
    _previousX = null;
    _previousY = null;
    _previousZ = null;
    _settleController.stop();
    await subscription?.cancel();
    _parallaxNotifier.value = Offset.zero;
    await _ambientTone.stop();
    await _whisperService.stop();
  }

  void _startAccelerometer() {
    if (!_motionEnabled) return;
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted || !_isActive) return;
      final previousX = _previousX;
      final previousY = _previousY;
      final previousZ = _previousZ;
      _previousX = event.x;
      _previousY = event.y;
      _previousZ = event.z;

      if (previousX != null && previousY != null && previousZ != null) {
        final change = math.sqrt(
          math.pow(event.x - previousX, 2) +
              math.pow(event.y - previousY, 2) +
              math.pow(event.z - previousZ, 2),
        );
        _updateStillness(change);
      }

      final nextX = (event.x / 10).clamp(-1.0, 1.0);
      final nextY = (event.y / 10).clamp(-1.0, 1.0);
      if ((nextX - _parallaxNotifier.value.dx).abs() >= _tiltUpdateThreshold ||
          (nextY - _parallaxNotifier.value.dy).abs() >= _tiltUpdateThreshold) {
        _parallaxNotifier.value = Offset(nextX, nextY);
      }
    });
  }

  void _updateStillness(double accelerationChange) {
    if (accelerationChange > 0.8) {
      _stillnessTimer?.cancel();
      _stillnessTimer = null;
      if (_settleController.value > 0 &&
          _settleController.status != AnimationStatus.reverse) {
        _settleController.animateTo(
          0,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    if (_stillnessTimer == null && _settleController.value < 1) {
      _stillnessTimer = Timer(const Duration(seconds: 3), () {
        _stillnessTimer = null;
        if (_isActive && mounted) {
          _settleController.animateTo(1, curve: Curves.easeInOut);
          if (_hapticsEnabled) {
            HapticFeedback.mediumImpact();
          }
        }
      });
    }
  }

  void _onFlicker() {
    _flickerKey.currentState?.flicker();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _setMood(WaterMood mood) async {
    if (_mood == mood) return;
    if (_hapticsEnabled) HapticFeedback.selectionClick();
    _dialProgressNotifier.value = mood.index.toDouble();
    setState(() {
      _mood = mood;
    });
    if (_soundEnabled && _isActive) {
      await _ambientTone.start(moodIndex: mood.index);
    }
    await _saveSetting('scene_mood', mood.index);
    _onUserInteraction();
  }

  void _toggleBreathPacer() {
    if (_hapticsEnabled) HapticFeedback.selectionClick();
    setState(() {
      _breathPacerEnabled = !_breathPacerEnabled;
      if (_breathPacerEnabled) {
        _startBreathPacer();
      } else {
        _stopBreathPacer();
      }
    });
    _saveSetting('breath_pacer_enabled', _breathPacerEnabled);
    _onUserInteraction();
  }

  void _toggleSound() async {
    if (_hapticsEnabled) HapticFeedback.selectionClick();
    final newValue = !_soundEnabled;
    setState(() => _soundEnabled = newValue);
    _whisperService.soundEnabled = newValue;
    if (newValue && _isActive) {
      _ambientTone.start(moodIndex: _mood.index);
    } else {
      await _ambientTone.stop();
    }
    await _saveSetting('sound_enabled', newValue);
    _onUserInteraction();
  }

  void _startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes == 0) {
      setState(() => _sleepTimerMinutesRemaining = 0);
      return;
    }

    setState(() => _sleepTimerMinutesRemaining = minutes);
    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) return;
      if (_sleepTimerMinutesRemaining <= 1) {
        timer.cancel();
        _sleepTimerMinutesRemaining = 0;
        _deactivate();
        setState(() {});
      } else {
        setState(() => _sleepTimerMinutesRemaining--);
      }
    });
  }

  (double, String) _calculateBreathProgress(double animationValue) {
    final total = _breathRhythm.totalDuration.toDouble();
    final currentSeconds = animationValue * total;

    final inhaleEnd = _breathRhythm.inhale.toDouble();
    final holdInEnd = inhaleEnd + _breathRhythm.holdIn;
    final exhaleEnd = holdInEnd + _breathRhythm.exhale;

    if (currentSeconds <= inhaleEnd) {
      final t = (currentSeconds / inhaleEnd).clamp(0.0, 1.0);
      return (Curves.easeInOut.transform(t), 'Inhale');
    } else if (currentSeconds <= holdInEnd) {
      return (1.0, 'Hold');
    } else if (currentSeconds <= exhaleEnd) {
      final t = ((currentSeconds - holdInEnd) / _breathRhythm.exhale).clamp(
        0.0,
        1.0,
      );
      return (1.0 - Curves.easeInOut.transform(t), 'Exhale');
    } else {
      return (0.0, 'Rest');
    }
  }

  Future<void> _openSettings() async {
    _onUserInteraction();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C131A).withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setSheetState) => FractionallySizedBox(
                heightFactor: 0.9,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Text(
                              'Atmosphere & Sanctuary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.8,
                                color: Color(0xFFF0F4F4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mindful stillness accrued: ${_stillnessSeconds ~/ 60}m ${_stillnessSeconds % 60}s',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(
                              0xFF88E4D0,
                            ).withValues(alpha: 0.85),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'SCENE ATMOSPHERE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: Color(0xFF82949E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.1,
                          children: WaterMood.values.map((mood) {
                            final selected = _mood == mood;
                            return GestureDetector(
                              onTap: () {
                                _setMood(mood);
                                setSheetState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(
                                          0xFF1B3B3F,
                                        ).withValues(alpha: 0.7)
                                      : const Color(
                                          0xFF141E28,
                                        ).withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF5FF6D1)
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: selected ? 1.4 : 0.7,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          mood.displayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: selected
                                                ? const Color(0xFFE6FFF9)
                                                : const Color(0xFFC7D4D8),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (selected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 15,
                                            color: Color(0xFF5FF6D1),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      mood.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 28),
                        const Text(
                          'BREATH PACER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: Color(0xFF82949E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingRow(
                          'Guided Breath Ring',
                          'Ethereal visual rhythm around the celestial light',
                          _breathPacerEnabled,
                          (value) async {
                            setSheetState(() => _breathPacerEnabled = value);
                            setState(() {
                              _breathPacerEnabled = value;
                              if (value) {
                                _startBreathPacer();
                              } else {
                                _stopBreathPacer();
                              }
                            });
                            await _saveSetting('breath_pacer_enabled', value);
                          },
                        ),
                        if (_breathPacerEnabled) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: BreathRhythm.values.map((rhythm) {
                              final isSelected = _breathRhythm == rhythm;
                              return ChoiceChip(
                                label: Text(rhythm.title),
                                selected: isSelected,
                                showCheckmark: false,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? const Color(0xFF04201D)
                                      : const Color(0xFFE2EBEB),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                selectedColor: const Color(0xFF5FF6D1),
                                backgroundColor: const Color(0xFF141F28),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF5FF6D1)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (_) async {
                                  setSheetState(() => _breathRhythm = rhythm);
                                  setState(() {
                                    _breathRhythm = rhythm;
                                    _startBreathPacer();
                                  });
                                  await _saveSetting(
                                    'breath_rhythm_index',
                                    rhythm.index,
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 28),
                        const Text(
                          'SENSORY & SOUND',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: Color(0xFF82949E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingRow(
                          'Ambient Tone',
                          'Quiet resonant hum of pure presence',
                          _soundEnabled,
                          (value) async {
                            setSheetState(() => _soundEnabled = value);
                            setState(() => _soundEnabled = value);
                            _whisperService.soundEnabled = value;
                            if (value && _isActive) {
                              _ambientTone.start(moodIndex: _mood.index);
                            } else {
                              await _ambientTone.stop();
                            }
                            await _saveSetting('sound_enabled', value);
                          },
                        ),
                        _settingRow(
                          'Phone Tilt & Parallax',
                          'Fluid motion response to phone movement',
                          _motionEnabled,
                          (value) async {
                            setSheetState(() => _motionEnabled = value);
                            setState(() {
                              _motionEnabled = value;
                              if (value && _isActive) {
                                _startAccelerometer();
                              } else {
                                _accelerometerSubscription?.cancel();
                                _accelerometerSubscription = null;
                              }
                            });
                            await _saveSetting('motion_enabled', value);
                          },
                        ),
                        _settingRow(
                          'Precision Haptics',
                          'Delicate touch vibrations on water ripples',
                          _hapticsEnabled,
                          (value) async {
                            setSheetState(() => _hapticsEnabled = value);
                            setState(() => _hapticsEnabled = value);
                            await _saveSetting('haptics_enabled', value);
                          },
                        ),

                        const SizedBox(height: 28),
                        const Text(
                          'WIND-DOWN SLEEP TIMER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: Color(0xFF82949E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [0, 5, 15, 30, 45, 60].map((mins) {
                            final isCurrent =
                                _sleepTimerMinutesRemaining == mins;
                            return ChoiceChip(
                              label: Text(mins == 0 ? 'Off' : '$mins min'),
                              selected: isCurrent,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: isCurrent
                                    ? const Color(0xFF04201D)
                                    : const Color(0xFFE2EBEB),
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              selectedColor: const Color(0xFF5FF6D1),
                              backgroundColor: const Color(0xFF141F28),
                              side: BorderSide(
                                color: isCurrent
                                    ? const Color(0xFF5FF6D1)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (_) {
                                _startSleepTimer(mins);
                                setSheetState(() {});
                              },
                            );
                          }).toList(),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(height: 1, color: Color(0x22FFFFFF)),
                        ),

                        const Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFF5FF6D1),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Private & Offline by Design',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFD6E2E4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'STILL is a zero-demand space. All preferences, timer sessions, and motion processing remain 100% on this device. No trackers, no accounts, no connectivity requirements.',
                          style: TextStyle(
                            color: Color(0xFF90A3A8),
                            height: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingRow(
    String title,
    String subtitle,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFEDF3F3),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF5FF6D1),
            inactiveTrackColor: const Color(0xFF1E2D38),
            inactiveThumbColor: const Color(0xFFA5B4BA),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deactivate());
    _dialProgressNotifier.dispose();
    _parallaxNotifier.dispose();
    _settleController.dispose();
    _hudVisibilityController.dispose();
    _breathController.dispose();
    _sleepTimer?.cancel();
    _sessionDurationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activate();
    } else {
      unawaited(_deactivate());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: WhisperFlicker(
        key: _flickerKey,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _settleController,
            _hudVisibilityController,
            _breathController,
          ]),
          builder: (context, child) {
            final (breathProgress, breathPhaseText) = _breathPacerEnabled
                ? _calculateBreathProgress(_breathController.value)
                : (0.0, '');

            return Listener(
              onPointerDown: (_) => _onUserInteraction(),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ValueListenableBuilder<Offset>(
                      valueListenable: _parallaxNotifier,
                      builder: (context, tilt, _) {
                        return ValueListenableBuilder<double>(
                          valueListenable: _dialProgressNotifier,
                          builder: (context, moodVal, _) {
                            return AmbientWaterScene(
                              tiltX: tilt.dx,
                              tiltY: tilt.dy,
                              stillness: _settleController.value,
                              moodValue: moodVal,
                              motionEnabled: _motionEnabled,
                              hapticsEnabled: _hapticsEnabled,
                              breathPacerActive: _breathPacerEnabled,
                              breathProgress: breathProgress,
                              breathPhaseText: breathPhaseText,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_breathPacerEnabled)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.44,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: 0.85,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            breathPhaseText.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFAEDE0),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 4.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _hudVisibilityController,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'STILL',
                                        style: TextStyle(
                                          color: Color(0xFFF7ECE0),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _sleepTimerMinutesRemaining > 0
                                            ? 'Sleep timer: $_sleepTimerMinutesRemaining min'
                                            : 'A sanctuary to pause',
                                        style: TextStyle(
                                          color: const Color(
                                            0xFFA2B4B8,
                                          ).withValues(alpha: 0.8),
                                          fontSize: 11,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  _frostedIconButton(
                                    icon: _breathPacerEnabled
                                        ? Icons.spa
                                        : Icons.spa_outlined,
                                    isActive: _breathPacerEnabled,
                                    tooltip: 'Breath Pacer Guide',
                                    onPressed: _toggleBreathPacer,
                                  ),
                                  const SizedBox(width: 8),
                                  _frostedIconButton(
                                    icon: _soundEnabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    isActive: _soundEnabled,
                                    tooltip: 'Ambient Sound',
                                    onPressed: _toggleSound,
                                  ),
                                  const SizedBox(width: 8),
                                  _frostedIconButton(
                                    icon: Icons.tune_rounded,
                                    isActive: false,
                                    tooltip: 'Sanctuary Settings',
                                    onPressed: _openSettings,
                                  ),
                                ],
                              ),

                              const Spacer(),
                              Center(child: _orbitFloatingButton()),

                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  _settleController.value > 0.8
                                      ? 'Stillness settled. Resting on glass.'
                                      : 'Draw on water to ripple · Tap orbit to change atmosphere',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(
                                      0xFFECECE4,
                                    ).withValues(alpha: 0.55),
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _frostedIconButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF5FF6D1).withValues(alpha: 0.22)
                  : const Color(0xFF0C161F).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF5FF6D1).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? const Color(0xFF5FF6D1)
                  : const Color(0xFFE4EFEF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orbitFloatingButton() {
    final activeItem = kModeDialItems[_mood.index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: _openOrbitSelector,
          borderRadius: BorderRadius.circular(26),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF070F16).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: activeItem.primaryColor.withValues(alpha: 0.45),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeItem.glowColor.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeItem.primaryColor.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(activeItem.imagePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  activeItem.title,
                  style: TextStyle(
                    color: activeItem.primaryColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.2,
                    shadows: [
                      Shadow(
                        color: activeItem.primaryColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.expand_less_rounded,
                  size: 18,
                  color: activeItem.primaryColor.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openOrbitSelector() async {
    _onUserInteraction();
    if (_hapticsEnabled) HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF070E14).withValues(alpha: 0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final currentItem = kModeDialItems[_mood.index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.blur_on_rounded,
                          size: 16,
                          color: currentItem.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CELESTIAL ORBIT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    ModeDial(
                      selectedMood: _mood,
                      hapticsEnabled: _hapticsEnabled,
                      onProgressChanged: (progress) {
                        _dialProgressNotifier.value = progress;
                      },
                      onMoodChanged: (mood) {
                        _setMood(mood);
                        setSheetState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
