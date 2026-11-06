import 'package:audioplayers/audioplayers.dart';

class AtmosphereMixer {
  AtmosphereMixer._internal();

  static final AtmosphereMixer _instance = AtmosphereMixer._internal();

  factory AtmosphereMixer() => _instance;

  final Map<String, AudioPlayer> _players = {};

  bool get hasActiveTracks => _players.isNotEmpty;

  Future<void> playTrack(String fileName, {double volume = 0.3}) async {
    final existing = _players[fileName];
    if (existing != null) {
      await existing.setVolume(volume);
      return;
    }

    final player = AudioPlayer();
    try {
      await player.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume);
      await player.play(AssetSource('audio/$fileName'));
      _players[fileName] = player;
    } catch (_) {
      await player.stop();
      await player.dispose();
    }
  }

  Future<void> stopTrack(String fileName) async {
    final player = _players.remove(fileName);
    await player?.stop();
    await player?.dispose();
  }

  Future<void> stopAll() async {
    for (final player in _players.values) {
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.stop();
      } catch (_) {}
      await player.dispose();
    }
    _players.clear();
  }

  Future<void> playOnly(String fileName, {double volume = 0.3}) async {
    await stopAll();
    await playTrack(fileName, volume: volume);
  }
}
