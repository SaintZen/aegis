import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';


class KineticVoiceEngine {
  static final AudioPlayer _voicePlayer = AudioPlayer();
  static final AudioPlayer _enginePlayer = AudioPlayer();
  static bool _engineReady = false;
  static bool _engineActive = false;
  static bool _pulseActive = false;
  static const String _engineAsset = 'assets/audio/engine/engine_thrum_40hz.mp3';
  static const int _pulseOnMs = 12;
  static const int _pulseOffMs = 13;
  static const int _pulseBaseIntensity = 90;
  static const int _pulseBoostIntensity = 130;
  static const int _pulseLowIntensity = 60;
  static const int _pulseBeatOnMs = 60;
  static const int _pulseBeatOffMs = 940;
  static const int _pulseBeatIntensity = 120;
  static const int _tripleTapOnMs = 60;
  static const int _tripleTapGapMs = 80;

  static const String _legacyBasePath = 'assets/audio/kinetic/';
  static const String _promptBasePath = 'assets/audio/kinetic_prompts/';
  static const Map<String, String> _exerciseTrackAudio = {
    'wall_push': 'assets/audio/kinetic_prompts/wall_push.mp3',
    'wall_pushups': 'assets/audio/kinetic_prompts/wall_push.mp3',
    'somatic_shaking': 'assets/audio/kinetic_prompts/the_shake.mp3',
    'tense_release': 'assets/audio/kinetic_prompts/the_shake.mp3',
    'muscle_clench': 'assets/audio/kinetic_prompts/isometric.mp3',
    'pulse': 'assets/audio/kinetic_prompts/the_pulse.mp3',
  };

  static const Map<String, _AudioSpec> _exerciseAudio = {
    'wall_push': _AudioSpec(_legacyBasePath, 'wall_push'),
    'wall_pushups': _AudioSpec(_legacyBasePath, 'wall_push'),
    'somatic_shaking': _AudioSpec(_legacyBasePath, 'shake'),
    'tense_release': _AudioSpec(_legacyBasePath, 'shake'),
    'muscle_clench': _AudioSpec(_legacyBasePath, 'iso'),
    'pulse': _AudioSpec(_legacyBasePath, 'pulse'),
    'level_01': _AudioSpec(_promptBasePath, 'level_01'),
    'level_02': _AudioSpec(_promptBasePath, 'level_02'),
    'level_03': _AudioSpec(_promptBasePath, 'level_03'),
    'level_04': _AudioSpec(_promptBasePath, 'level_04'),
    'level_05': _AudioSpec(_promptBasePath, 'level_05'),
    'level_06': _AudioSpec(_promptBasePath, 'level_06'),
  };

  static Future<void> playPrimer(String exerciseId) async {
    final trackAsset = _exerciseTrackAudio[exerciseId];
    final spec = _exerciseAudio[exerciseId];
    if (trackAsset == null && spec == null) return;
    final assetPath = trackAsset ??
        _resolveAssetPath('${spec!.basePath}${spec.prefix}_primer.wav');
    await _voicePlayer.setVolume(1.0);
    await _voicePlayer.setAsset(assetPath);
    await _voicePlayer.play();
    await _voicePlayer.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
  }

  static Future<void> playRep(String exerciseId) async {
    final trackAsset = _exerciseTrackAudio[exerciseId];
    final spec = _exerciseAudio[exerciseId];
    if (trackAsset == null && spec == null) return;
    final assetPath = trackAsset ??
        _resolveAssetPath('${spec!.basePath}${spec.prefix}_rep.wav');
    await _voicePlayer.setVolume(1.0);
    await _voicePlayer.setAsset(assetPath);
    await _voicePlayer.play();
    HapticFeedback.heavyImpact();
    await _voicePlayer.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
  }

  static Future<void> primeSilence() async {
    await _voicePlayer.stop();
    await _voicePlayer.setVolume(0.0);
  }

  static Future<void> playArtlistVoiceCount(int rep) async {
    if (rep < 1) return;
    final assetPath = 'assets/audio/rep_$rep.mp3';
    await _voicePlayer.setAsset(assetPath);
    await _voicePlayer.play();
    HapticFeedback.heavyImpact();
    await _voicePlayer.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
  }

  static Future<void> setVoiceVolume(double volume) async {
    await _voicePlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  static Future<void> stopVoice() async {
    try {
      await _voicePlayer.stop();
    } catch (e) {
      debugPrint('Voice stop failed: $e');
    }
  }

  static Future<void> emergencyStop() async {
    await stopVoice();
    await stopPulseThrum();
    await stopEngineThrum();
    Vibration.cancel();
  }

  static Future<void> playTrackWithAudits({
    required String exerciseId,
    required List<AuditMarker> audits,
    required Future<void> Function(AuditMarker marker) onAudit,
    List<TrackMarker> markers = const [],
    Future<void> Function(TrackMarker marker)? onMarker,
  }) async {
    final trackAsset = _exerciseTrackAudio[exerciseId];
    final spec = _exerciseAudio[exerciseId];
    if (trackAsset == null && spec == null) return;
    final assetPath = trackAsset ??
        _resolveAssetPath('${spec!.basePath}${spec.prefix}_primer.wav');
    await _voicePlayer.setVolume(1.0);
    await _voicePlayer.setAsset(assetPath);
    await _voicePlayer.play();

    var auditIndex = 0;
    var markerIndex = 0;
    var auditInProgress = false;
    final subscription = _voicePlayer.positionStream.listen((position) async {
      if (auditInProgress) return;
      if (auditIndex < audits.length) {
        final audit = audits[auditIndex];
        if (position >= audit.at) {
          auditInProgress = true;
          auditIndex += 1;
          await _voicePlayer.pause();
          await onAudit(audit);
          if (_voicePlayer.processingState != ProcessingState.completed) {
            await _voicePlayer.play();
          }
          auditInProgress = false;
          return;
        }
      }
      if (markerIndex < markers.length && onMarker != null) {
        final marker = markers[markerIndex];
        if (position >= marker.at) {
          markerIndex += 1;
          await onMarker(marker);
        }
      }
    });

    await _voicePlayer.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
    await subscription.cancel();
  }

  static Future<void> startEngineThrum() async {
    if (_engineActive) return;
    _engineActive = true;
    try {
      if (!_engineReady) {
        await _enginePlayer.setLoopMode(LoopMode.one);
        await _enginePlayer.setAsset(_engineAsset);
        _engineReady = true;
      }
      await _enginePlayer.setVolume(1.0);
      await _enginePlayer.play();
    } catch (e) {
      debugPrint('Engine thrum play failed: $e');
    }
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: const [0, 120, 80, 120],
        intensities: const [255, 0, 255, 0],
        repeat: 0,
      );
    }
  }

  static Future<void> stopEngineThrum() async {
    if (!_engineActive) return;
    _engineActive = false;
    Vibration.cancel();
    try {
      await _enginePlayer.setVolume(0.0);
      await Future.delayed(const Duration(milliseconds: 100));
      await _enginePlayer.pause();
      await _enginePlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Engine thrum stop failed: $e');
    }
  }

  static Future<void> startPulseThrum({bool boosted = false}) async {
    final intensity = boosted ? _pulseBoostIntensity : _pulseBaseIntensity;
    await _startPulseVibration(
      onMs: _pulseOnMs,
      offMs: _pulseOffMs,
      intensity: intensity,
    );
  }

  static Future<void> boostPulseThrum() async {
    await _startPulseVibration(
      onMs: _pulseOnMs,
      offMs: _pulseOffMs,
      intensity: _pulseBoostIntensity,
    );
  }

  static Future<void> startPulseHumLow() async {
    await _startPulseVibration(
      onMs: _pulseOnMs,
      offMs: _pulseOffMs,
      intensity: _pulseLowIntensity,
    );
  }

  static Future<void> startPulseBaseline(int intensity) async {
    await _startPulseVibration(
      onMs: _pulseOnMs,
      offMs: _pulseOffMs,
      intensity: intensity,
    );
  }

  static Future<void> startPulseBeat() async {
    await _startPulseVibration(
      onMs: _pulseBeatOnMs,
      offMs: _pulseBeatOffMs,
      intensity: _pulseBeatIntensity,
    );
  }

  static Future<void> triggerTripleTap() async {
    if (!await _hasVibration()) return;
    if (await Vibration.hasAmplitudeControl() ?? false) {
      Vibration.vibrate(
        pattern: const [
          0,
          _tripleTapOnMs,
          _tripleTapGapMs,
          _tripleTapOnMs,
          _tripleTapGapMs,
          _tripleTapOnMs,
        ],
        intensities: const [200, 0, 200, 0, 200, 0],
      );
    } else {
      Vibration.vibrate(
        pattern: const [
          0,
          _tripleTapOnMs,
          _tripleTapGapMs,
          _tripleTapOnMs,
          _tripleTapGapMs,
          _tripleTapOnMs,
        ],
      );
    }
  }

  static Future<void> stopPulseThrum() async {
    if (!_pulseActive) return;
    _pulseActive = false;
    Vibration.cancel();
  }

  static Future<void> _startPulseVibration({
    required int onMs,
    required int offMs,
    required int intensity,
  }) async {
    if (!await _hasVibration()) return;
    _pulseActive = true;
    Vibration.cancel();
    final clamped = intensity.clamp(1, 255);
    if (await Vibration.hasAmplitudeControl() ?? false) {
      Vibration.vibrate(
        pattern: [0, onMs, offMs],
        intensities: [clamped, 0, clamped],
        repeat: 1,
      );
    } else {
      Vibration.vibrate(
        pattern: [0, onMs, offMs],
        repeat: 1,
      );
    }
  }

  static Future<bool> _hasVibration() async {
    return await Vibration.hasVibrator() ?? false;
  }

  static String _resolveAssetPath(String assetPath) {
    if (assetPath.startsWith('assets/')) {
      return assetPath;
    }
    return 'assets/$assetPath';
  }
}

class _AudioSpec {
  const _AudioSpec(this.basePath, this.prefix);

  final String basePath;
  final String prefix;
}

class AuditMarker {
  const AuditMarker({
    required this.at,
    required this.label,
    required this.hold,
  });

  final Duration at;
  final String label;
  final Duration hold;
}

class TrackMarker {
  const TrackMarker({
    required this.at,
    required this.key,
  });

  final Duration at;
  final String key;
}
