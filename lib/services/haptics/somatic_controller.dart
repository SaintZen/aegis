import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

import 'package:anxiety_anchor/models/audit_cue.dart';
import 'package:anxiety_anchor/models/somatic_sequence.dart';
import 'package:anxiety_anchor/services/audio/somatic_audio_engine.dart';

class SomaticController {
  SomaticController({
    SomaticAudioEngine? audioEngine,
    Map<String, int> playbackOffsets = const {},
    bool muteAudio = false,
  })  : _audio = audioEngine ?? SomaticAudioEngine(),
        _playbackOffsets = playbackOffsets,
        _muteAudio = muteAudio;

  final SomaticAudioEngine _audio;
  final Map<String, int> _playbackOffsets;
  bool _muteAudio;
  final StreamController<AuditCue> _auditStream =
      StreamController<AuditCue>.broadcast();

  Stream<AuditCue> get auditStream => _auditStream.stream;

  StreamSubscription<Duration>? _positionSub;
  Timer? _hapticTimer;
  Timer? _tapTimer;
  Duration _lastPosition = Duration.zero;
  bool _running = false;
  int _baselineIntensity = 38;
  HapticProfile? _activeProfile;
  final AudioPlayer _frictionPlayer = AudioPlayer();
  bool _frictionReady = false;
  bool _frictionActive = false;

  Future<void> play(SomaticSequence sequence) async {
    if (_running) return;
    _running = true;
    await _audio.setAsset(sequence.audioAsset);
    _audio.setStealthMode(_muteAudio);
    if (_muteAudio) {
      await _audio.setVolume(0.0);
    } else {
      await _audio.setVolume(1.0);
    }
    _startHaptics(sequence);
    _positionSub?.cancel();
    final cues = List<AuditCue>.from(sequence.auditCues);
    var cueIndex = 0;
    var auditInProgress = false;
    _positionSub = _audio.positionStream.listen((position) async {
      _lastPosition = position;
      if (auditInProgress || cueIndex >= cues.length) return;
      final cue = cues[cueIndex];
      final triggerAt = _offsetTimestamp(cue.label, cue.at);
      if (position >= triggerAt) {
        auditInProgress = true;
        cueIndex += 1;
        _auditStream.add(cue);
        if (cue.pauseAudio) {
          await _audio.pause();
          await Future.delayed(cue.hold);
          if (_audio.processingState != ProcessingState.completed) {
            await _audio.play();
          }
        }
        auditInProgress = false;
      }
    });
    await _audio.play();
    await _audio.processingStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
    await stop();
  }

  Future<void> stop() async {
    _running = false;
    _positionSub?.cancel();
    _positionSub = null;
    _stopHaptics();
    await _audio.stop();
  }

  Future<void> emergencyStop() async {
    _running = false;
    _positionSub?.cancel();
    _positionSub = null;
    _stopHaptics();
    await _audio.stop();
    await stopFriction();
    Vibration.cancel();
  }

  Future<void> dispose() async {
    await stop();
    await _audio.dispose();
    await _frictionPlayer.dispose();
    await _auditStream.close();
  }

  void setBaselineIntensity(int intensity) {
    _baselineIntensity = intensity.clamp(1, 255);
    if (_running) {
      _startBaselineHum();
    }
  }

  void setMuteAudio(bool mute) {
    _muteAudio = mute;
    _audio.setStealthMode(mute);
    if (_running) {
      _audio.setVolume(mute ? 0.0 : 1.0);
    }
  }

  Future<void> playSystemVoice(String eventName) async {
    final shouldDuck =
        _activeProfile == HapticProfile.heavy40Hz || _activeProfile == HapticProfile.syncThrum;
    final original = _baselineIntensity;
    if (shouldDuck) {
      _baselineIntensity = (original * 0.5).round().clamp(1, 255);
      _startBaselineHum();
    }
    await _audio.playSystemVoice(eventName);
    if (shouldDuck) {
      _baselineIntensity = original;
      if (_running) {
        _startBaselineHum();
      }
    }
  }

  Future<void> startFriction({required double velocity}) async {
    await _ensureFrictionReady();
    if (!_frictionActive) {
      _frictionActive = true;
      await _frictionPlayer.play();
    }
    final normalized = (velocity / 30).clamp(0.0, 1.0);
    final intensity = (60 + (195 * normalized)).round();
    final onMs = (8 + (10 * normalized)).round();
    final offMs = (18 - (10 * normalized)).round().clamp(6, 18);
    final volume = 0.3 + (0.7 * normalized);
    await _frictionPlayer.setVolume(volume);
    if (await Vibration.hasAmplitudeControl() ?? false) {
      Vibration.vibrate(
        pattern: [0, onMs, offMs],
        intensities: [intensity.clamp(1, 255), 0, intensity.clamp(1, 255)],
      );
    } else {
      Vibration.vibrate(
        pattern: [0, onMs, offMs],
      );
    }
  }

  Future<void> stopFriction() async {
    _frictionActive = false;
    try {
      await _frictionPlayer.setVolume(0.0);
      await _frictionPlayer.stop();
      await _frictionPlayer.seek(Duration.zero);
    } finally {
      Vibration.cancel();
    }
  }

  Future<void> _ensureFrictionReady() async {
    if (_frictionReady) return;
    await _frictionPlayer.setLoopMode(LoopMode.one);
    await _frictionPlayer.setAsset('assets/audio/ice_scrapping.aac');
    _frictionReady = true;
  }

  void _startHaptics(SomaticSequence sequence) {
    _activeProfile = sequence.hapticProfile;
    switch (sequence.hapticProfile) {
      case HapticProfile.heavy40Hz:
        _baselineIntensity = 153;
        _startBaselineHum();
        break;
      case HapticProfile.staccato150ms:
        _startStaccato();
        break;
      case HapticProfile.linearRamp:
        _startRamp(sequence.rampSegments);
        break;
      case HapticProfile.syncThrum:
        _baselineIntensity = 38;
        _startBaselineHum();
        _startPulseTap();
        break;
    }
  }

  void _stopHaptics() {
    _activeProfile = null;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    _tapTimer?.cancel();
    _tapTimer = null;
    Vibration.cancel();
  }

  void _startBaselineHum() {
    _hapticTimer?.cancel();
    final intensity = _baselineIntensity;
    Vibration.vibrate(
      pattern: const [0, 12, 13],
      intensities: [intensity, 0, intensity],
      repeat: 1,
    );
  }

  void _startStaccato() {
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      HapticFeedback.mediumImpact();
    });
  }

  void _startPulseTap() {
    _tapTimer?.cancel();
    _tapTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      HapticFeedback.lightImpact();
    });
  }

  void _startRamp(List<HapticRampSegment> segments) {
    _hapticTimer?.cancel();
    if (segments.isEmpty) {
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        HapticFeedback.mediumImpact();
      });
      return;
    }
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      final posMs = _lastPosition.inMilliseconds;
      final active = segments.firstWhere(
        (segment) =>
            posMs >= segment.start.inMilliseconds &&
            posMs <= segment.end.inMilliseconds,
        orElse: () => const HapticRampSegment(
          start: Duration.zero,
          end: Duration.zero,
          startIntensity: 0,
          endIntensity: 0,
        ),
      );
      if (active.start == active.end) return;
      final durationMs =
          (active.end.inMilliseconds - active.start.inMilliseconds).toDouble();
      final progress =
          ((posMs - active.start.inMilliseconds) / durationMs).clamp(0.0, 1.0);
      final intensity = (active.startIntensity +
              (active.endIntensity - active.startIntensity) * progress) *
          255;
      if (await Vibration.hasAmplitudeControl() ?? false) {
        Vibration.vibrate(
          duration: 150,
          amplitude: intensity.round().clamp(1, 255),
        );
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  Duration _offsetTimestamp(String label, Duration base) {
    final key = label.toLowerCase();
    final offsetMs = _playbackOffsets[key] ?? 0;
    final adjusted = base.inMilliseconds + offsetMs;
    return Duration(milliseconds: adjusted < 0 ? 0 : adjusted);
  }
}
