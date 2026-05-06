import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;

import 'package:anxiety_anchor/services/usage_log_service.dart';
import 'package:anxiety_anchor/utils/pharmacy_temp_asset.dart';

// --- Data -----------------------------------------------------------------

class PharmacySound {
  const PharmacySound({
    required this.name,
    required this.asset,
    required this.subtext,
  });

  final String name;
  final String asset;
  final String subtext;
}

/// Short text protocol; opens instruction sheet + Begin (no audio).
class PharmacyMicroExercise {
  const PharmacyMicroExercise({
    required this.title,
    required this.subtext,
    required this.instruction,
  });

  final String title;
  final String subtext;
  final String instruction;
}

// --- Screen ---------------------------------------------------------------

class SonicPharmacyScreen extends StatefulWidget {
  const SonicPharmacyScreen({super.key});

  @override
  State<SonicPharmacyScreen> createState() => _SonicPharmacyScreenState();
}

class _SonicPharmacyScreenState extends State<SonicPharmacyScreen> {
  /// Clears the global AEGIS HUD row drawn in [MaterialApp]'s builder (shield + label).
  static const double _kAegisHudReserve = 42.0;

  final Stopwatch _sessionStopwatch = Stopwatch();
  String? _sessionFlavor;
  double? _swipeDownStartY;

  static const List<PharmacySound> _tactileMechanical = [
    PharmacySound(
      name: 'Glass tapping',
      asset: 'Glass_Tapping.aac',
      subtext: 'Rhythmic contact on glass surface',
    ),
    PharmacySound(
      name: 'Marker on paper',
      asset: 'Marker_on_Paper.aac',
      subtext: 'Writing drag across paper fiber',
    ),
    PharmacySound(
      name: 'Plastic rustle',
      asset: 'Plastic_Bag_Rustles.aac',
      subtext: 'Crinkle and shift, low-mid grain',
    ),
    PharmacySound(
      name: 'Chopsticks',
      asset: 'Chopsticks.aac',
      subtext: 'Wood-on-ceramic taps and clicks',
    ),
  ];

  static const List<PharmacySound> _closeTexture = [
    PharmacySound(
      name: 'Mouth clicks',
      asset: 'Mouth_Clicks.aac',
      subtext: 'Dry oral clicks, close-mic',
    ),
    PharmacySound(
      name: 'Bubble wrap',
      asset: 'Bubble_Wrap.aac',
      subtext: 'Pop and squeeze texture loop',
    ),
    PharmacySound(
      name: 'Hair brushing',
      asset: 'Brushing_Hair.aac',
      subtext: 'Bristle pass, steady stroke',
    ),
  ];

  static const List<PharmacySound> _texturalAccent = [
    PharmacySound(
      name: 'Crystals',
      asset: 'Crystals.aac',
      subtext: 'High-frequency sparkle reset',
    ),
    PharmacySound(
      name: 'Velcro',
      asset: 'Velcro.aac',
      subtext: 'Gritty tactile pulse',
    ),
    PharmacySound(
      name: 'Single Chime',
      asset: 'Single_Chime.aac',
      subtext: 'Brief tonal anchor',
    ),
  ];

  static const List<PharmacyMicroExercise> _microExercises = [
    PharmacyMicroExercise(
      title: 'Four-count exhale',
      subtext: 'Short breath protocol',
      instruction: 'Exhale for four slow counts. Repeat at your pace. '
          'Nasal or mouth — no force. Stop when steady.',
    ),
  ];

  static const Color _headerGray = Color(0xFF5C5C5C);

  @override
  void dispose() {
    _finishSessionLog();
    super.dispose();
  }

  Future<void> _finishSessionLog() async {
    if (!_sessionStopwatch.isRunning) return;
    _sessionStopwatch.stop();
    final sec = _sessionStopwatch.elapsed.inSeconds;
    final flavor = _sessionFlavor;
    if (flavor != null && sec >= 0) {
      await UsageLogService.logAnchorUsage(
        flavor: flavor,
        durationSeconds: sec == 0 ? 1 : sec,
      );
    }
    _sessionFlavor = null;
    _sessionStopwatch.reset();
  }

  Future<void> _openPlaybackPanel(PharmacySound sound) async {
    await _finishSessionLog();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: const Color(0xDD000000),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.hardEdge,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _FlatPlaybackPanel(
            title: sound.name,
            assetPath: 'assets/audio/pharmacy/${sound.asset}',
            onFlavorStart: (name) {
              _sessionFlavor = name;
              _sessionStopwatch
                ..reset()
                ..start();
            },
            onFlavorStop: () async {
              await _finishSessionLog();
            },
          ),
        );
      },
    );

    await _finishSessionLog();
    if (mounted) setState(() {});
  }

  Future<void> _openMicroPanel(PharmacyMicroExercise ex) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: const Color(0xDD000000),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.hardEdge,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Material(
          color: const Color(0xFF0A0A0A),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ex.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'RobotoMono',
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  ex.instruction,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontFamily: 'RobotoMono',
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001220),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      'BEGIN',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _maybePopOnSwipeDown(DragEndDetails d) {
    final v = d.primaryVelocity;
    if (v != null && v > 280 && (_swipeDownStartY ?? 999) < 100) {
      Navigator.maybePop(context);
    }
    _swipeDownStartY = null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: _kAegisHudReserve),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (details) {
                    _swipeDownStartY = details.globalPosition.dy;
                  },
                  onVerticalDragEnd: _maybePopOnSwipeDown,
                  child: SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 40,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
                    physics: const ClampingScrollPhysics(),
                    children: [
                      const Text(
                        'ASMR PHARMACY',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'RobotoMono',
                          fontSize: 15,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Immediate sensory triggers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontFamily: 'RobotoMono',
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionHeader('TACTILE / MECHANICAL'),
                      const SizedBox(height: 10),
                      ..._tactileMechanical.map(_buildAudioRow),
                      const SizedBox(height: 22),
                      _sectionHeader('CLOSE-MIC / TEXTURE'),
                      const SizedBox(height: 10),
                      ..._closeTexture.map(_buildAudioRow),
                      const SizedBox(height: 22),
                      _sectionHeader('TEXTURAL / ACCENT'),
                      const SizedBox(height: 10),
                      ..._texturalAccent.map(_buildAudioRow),
                      const SizedBox(height: 22),
                      _sectionHeader('MICRO-EXERCISES'),
                      const SizedBox(height: 10),
                      ..._microExercises.map(_buildMicroRow),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String uppercaseTitle) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        uppercaseTitle,
        style: const TextStyle(
          color: _headerGray,
          fontFamily: 'RobotoMono',
          fontSize: 10,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildAudioRow(PharmacySound s) {
    return InkWell(
      onTap: () => _openPlaybackPanel(s),
      splashColor: Colors.white10,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'RobotoMono',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.42),
                fontFamily: 'RobotoMono',
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroRow(PharmacyMicroExercise ex) {
    return InkWell(
      onTap: () => _openMicroPanel(ex),
      splashColor: Colors.white10,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ex.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'RobotoMono',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ex.subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.42),
                fontFamily: 'RobotoMono',
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet: extracted waveform + transport, output level, PLAY/PAUSE.
/// Mobile uses [audio_waveforms] (file path); web/other uses [just_audio] without waveform.
class _FlatPlaybackPanel extends StatefulWidget {
  const _FlatPlaybackPanel({
    required this.title,
    required this.assetPath,
    required this.onFlavorStart,
    required this.onFlavorStop,
  });

  final String title;
  final String assetPath;
  final void Function(String flavor) onFlavorStart;
  final Future<void> Function() onFlavorStop;

  @override
  State<_FlatPlaybackPanel> createState() => _FlatPlaybackPanelState();
}

class _FlatPlaybackPanelState extends State<_FlatPlaybackPanel> {
  static const Duration _kSessionCap = Duration(minutes: 20);

  PlayerController? _pc;
  ja.AudioPlayer? _ja;
  double _volume = 0.65;
  bool _prepared = false;
  String? _error;
  Timer? _sessionCapTimer;

  bool get _useNativeWaveform => _pc != null;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      final path = await copyBundledAssetToTemp(widget.assetPath);
      if (!mounted) return;
      if (path != null) {
        final pc = PlayerController();
        try {
          pc.updateFrequency = UpdateFrequency.high;
          await pc.preparePlayer(
            path: path,
            volume: _volume,
            shouldExtractWaveform: true,
            noOfSamplesPerSecond: 22,
          );
          await pc.setFinishMode(finishMode: FinishMode.loop);
          if (!mounted) {
            pc.dispose();
            return;
          }
          _pc = pc;
        } catch (_) {
          pc.dispose();
          rethrow;
        }
      } else {
        final player = ja.AudioPlayer();
        await player.setLoopMode(ja.LoopMode.one);
        await player.setVolume(_volume);
        await player.setAsset(widget.assetPath);
        if (!mounted) {
          await player.dispose();
          return;
        }
        _ja = player;
      }
      if (mounted) setState(() => _prepared = true);
    } catch (e) {
      debugPrint('Pharmacy load failed: $e');
      if (mounted) setState(() => _error = 'Load failed');
    }
  }

  Future<void> _applyVolume(double v) async {
    final clamped = v.clamp(0.0, 1.0);
    setState(() => _volume = clamped);
    if (_pc != null) {
      await _pc!.setVolume(clamped);
    } else if (_ja != null) {
      await _ja!.setVolume(clamped);
    }
  }

  void _startSessionCap() {
    _sessionCapTimer?.cancel();
    _sessionCapTimer = Timer(_kSessionCap, () {
      if (!mounted) return;
      unawaited(_pause());
    });
  }

  void _clearSessionCap() {
    _sessionCapTimer?.cancel();
    _sessionCapTimer = null;
  }

  Future<void> _play() async {
    if (!_prepared) return;
    widget.onFlavorStart(widget.title);
    if (_pc != null) {
      await _pc!.startPlayer();
    } else if (_ja != null) {
      await _ja!.play();
    }
    _startSessionCap();
    if (mounted) setState(() {});
  }

  Future<void> _pause() async {
    if (_pc != null) {
      await _pc!.pausePlayer();
    } else if (_ja != null) {
      await _ja!.pause();
    }
    _clearSessionCap();
    await widget.onFlavorStop();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _clearSessionCap();
    if (_pc != null) {
      unawaited(_pc!.stopPlayer());
      _pc!.dispose();
    }
    unawaited(_ja?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0A0A),
      elevation: 0,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: !_prepared
            ? _buildLoadingOrError(context)
            : (_useNativeWaveform
                ? ListenableBuilder(
                    listenable: _pc!,
                    builder: (context, _) {
                      final playing = _pc!.playerState == PlayerState.playing;
                      return _buildControlsColumn(
                        context: context,
                        playing: playing,
                        waveform: _buildWaveform(context),
                      );
                    },
                  )
                : StreamBuilder<ja.PlayerState>(
                    stream: _ja!.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return _buildControlsColumn(
                        context: context,
                        playing: playing,
                        waveform: _buildFallbackProgress(context),
                      );
                    },
                  )),
      ),
    );
  }

  Widget _buildLoadingOrError(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'RobotoMono',
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'RobotoMono',
              fontSize: 12,
            ),
          ),
        ] else ...[
          const SizedBox(height: 32),
          const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildControlsColumn({
    required BuildContext context,
    required bool playing,
    required Widget waveform,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'RobotoMono',
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'RobotoMono',
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'SIGNAL ENVELOPE',
          style: TextStyle(
            color: Color(0xFF5C5C5C),
            fontFamily: 'RobotoMono',
            fontSize: 9,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        waveform,
        const SizedBox(height: 14),
        Text(
          'Start low. Increase output to match hardware.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.38),
            fontFamily: 'RobotoMono',
            fontSize: 10,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 72,
              child: Text(
                'OUTPUT',
                style: TextStyle(
                  color: Color(0xFF5C5C5C),
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: _volume,
                  min: 0,
                  max: 1,
                  onChanged: _prepared ? _applyVolume : null,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${(_volume * 100).round()}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed:
                    _prepared && !playing ? () => unawaited(_play()) : null,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: playing ? () => unawaited(_pause()) : null,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'PAUSE',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveform(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 40;
    final h = 72.0;
    return AudioFileWaveforms(
      size: Size(w, h),
      playerController: _pc!,
      waveformType: WaveformType.fitWidth,
      continuousWaveform: true,
      enableSeekGesture: true,
      backgroundColor: const Color(0xFF0A0A0A),
      playerWaveStyle: PlayerWaveStyle(
        fixedWaveColor: Colors.white.withOpacity(0.22),
        liveWaveColor: const Color(0xFF8FA8B8),
        seekLineColor: Colors.white70,
        waveThickness: 2,
        spacing: 4,
        scaleFactor: 72,
        backgroundColor: const Color(0xFF0A0A0A),
        showSeekLine: true,
      ),
    );
  }

  Widget _buildFallbackProgress(BuildContext context) {
    final ja = _ja;
    if (ja == null) {
      return SizedBox(
        height: 72,
        child: Center(
          child: Text(
            _prepared ? '' : '…',
            style: TextStyle(color: Colors.white.withOpacity(0.35)),
          ),
        ),
      );
    }
    return StreamBuilder<Duration>(
      stream: ja.positionStream,
      initialData: ja.position,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = ja.duration ?? Duration.zero;
        final total = dur.inMilliseconds <= 0 ? 1 : dur.inMilliseconds;
        final p = (pos.inMilliseconds / total).clamp(0.0, 1.0);
        return SizedBox(
          height: 72,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LinearProgressIndicator(
              value: p,
              minHeight: 3,
              backgroundColor: Colors.white12,
              color: const Color(0xFF8FA8B8),
            ),
          ),
        );
      },
    );
  }
}
