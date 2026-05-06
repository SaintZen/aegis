import 'package:just_audio/just_audio.dart';

class SomaticAudioEngine {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _systemPlayer = AudioPlayer();
  bool _stealthMode = false;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<ProcessingState> get processingStream =>
      _player.processingStateStream;

  Future<void> setAsset(String assetPath) async {
    await _player.setAsset(assetPath);
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  void setStealthMode(bool enabled) {
    _stealthMode = enabled;
  }

  Future<void> playSystemVoice(String eventName) async {
    if (_stealthMode) return;
    final assetPath = eventName.startsWith('assets/')
        ? eventName
        : 'assets/audio/affirmations/system/$eventName.mp3';
    try {
      await _systemPlayer.setAsset(assetPath);
      await _systemPlayer.play();
      await _systemPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
    } catch (_) {
      // No-op if system voice asset is missing.
    }
  }

  ProcessingState get processingState => _player.processingState;

  Future<void> dispose() async {
    await _player.dispose();
    await _systemPlayer.dispose();
  }
}
