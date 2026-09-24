import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

import 'package:anxiety_anchor/audio/audio_halt.dart';
import 'package:anxiety_anchor/scripts/kinetic_scripts.dart';
import 'package:anxiety_anchor/services/kinetic_voice_engine.dart';
import 'package:anxiety_anchor/services/usage_log_service.dart';
import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/widgets/affirmations_library.dart';
import 'package:anxiety_anchor/widgets/cut_control.dart';

/// Vista beds and Kinetic voice halt when the operator leaves the
/// foreground. [AppLifecycleState.resumed] is the only state that may
/// restore audio. Closing the app, switching away, or hiding the
/// surface all silence the looping beds.
bool islandLifecycleSilencesAudio(AppLifecycleState state) {
  return aegisLifecycleSilencesAudio(state);
}

enum _IslandMode { vista, voice, kinetic }
enum _KineticView { menu, active }
enum _PulsePhase {
  none,
  matchBeat,
  matchThrum,
  actionPulse,
  auditPause,
  closingLoop,
}

class IslandScreen extends StatefulWidget {
  const IslandScreen({super.key, this.initialMode});

  /// `vista`, `kinetic`, or `voice`. CUT lands on vista or voice.
  final String? initialMode;

  @override
  State<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends State<IslandScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const List<_VistaOption> _vistas = [
    _VistaOption('Mountain Bell', 'assets/videos/mountain_bell.mp4'),
    _VistaOption('Monastery', 'assets/videos/monastery.mp4'),
    _VistaOption('Desert Oasis', 'assets/videos/desert_oasis.mp4'),
  ];

  _IslandMode _mode = _IslandMode.vista;
  _IslandMode _lastPortraitMode = _IslandMode.vista;
  bool _isLandscape = false;

  int _selectedVistaIndex = 0;
  VideoPlayerController? _fullController;
  String? _fullError;
  late final PageController _vistaPageController;
  final AudioPlayer _vistaAudio = AudioPlayer();
  final AudioPlayer _missionControlPlayer = AudioPlayer();
  int _activeVistaAudioIndex = -1;
  bool _isExecutingSequence = false;
  int _currentRep = 0;
  final Stopwatch _vistaStopwatch = Stopwatch();
  _KineticView _kineticView = _KineticView.menu;
  bool _userHasSelectedVista = false;
  bool _sessionHalted = false;
  bool _kineticLogged = false;
  String? _activeExerciseKey;
  String? _expandedStealthId;
  String? _expandedFieldId;
  int _kineticGeneration = 0;
  DateTime? _tumblerTickAt;
  _PulsePhase _pulsePhase = _PulsePhase.none;
  bool _closingFlashOn = false;
  String _auditText = 'VISION CLEAR';
  Timer? _shakeHapticTimer;
  Timer? _isometricRampTimer;
  Timer? _pulseTapTimer;
  int _pulseBaselineIntensity = 38;
  bool _pulseMatched = false;
  late final AnimationController _pulseVisualController;
  late final Animation<double> _pulseVisualAnimation;
  final Map<String, double> _playbackOffsets = const {
    'vision': -150,
    'feet': -150,
    'head': -150,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == 'kinetic') {
      _mode = _IslandMode.kinetic;
      _lastPortraitMode = _IslandMode.kinetic;
    } else if (widget.initialMode == 'voice') {
      _mode = _IslandMode.voice;
      _lastPortraitMode = _IslandMode.voice;
    }
    WidgetsBinding.instance.addObserver(this);
    _vistaPageController = PageController(initialPage: _selectedVistaIndex);
    _vistaAudio.setVolume(0.0);
    _vistaAudio.stop();
    KineticVoiceEngine.primeSilence();
    _pulseVisualController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseVisualAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseVisualController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionHalted = true;
    _shakeHapticTimer?.cancel();
    _isometricRampTimer?.cancel();
    _pulseTapTimer?.cancel();
    _pulseVisualController.dispose();
    unawaited(_logVistaSession());
    _vistaPageController.dispose();
    _fullController?.dispose();
    unawaited(_vistaAudio.stop().whenComplete(_vistaAudio.dispose));
    unawaited(
      _missionControlPlayer.stop().whenComplete(_missionControlPlayer.dispose),
    );
    unawaited(KineticVoiceEngine.emergencyStop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (islandLifecycleSilencesAudio(state)) {
      unawaited(_silenceForBackground());
      return;
    }
    if (_sessionHalted) return;
    unawaited(_restoreIslandOnForeground());
  }

  Future<void> _silenceForBackground() async {
    await _stopVistaAudio();
    try {
      await _missionControlPlayer.stop();
    } catch (e) {
      debugPrint('Mission control stop failed: $e');
    }
    await KineticVoiceEngine.emergencyStop();
    try {
      await _fullController?.pause();
    } catch (e) {
      debugPrint('Vista video pause failed: $e');
    }
    _stopShakeStaccato();
    _stopIsometricRamp();
    _stopPulseTapLoop();
    _stopPulseVisualPulse();
    if (!mounted) return;
    if (_isExecutingSequence) {
      _kineticGeneration += 1;
      final key = _activeExerciseKey;
      setState(() {
        _isExecutingSequence = false;
        _currentRep = 0;
        _kineticView = _KineticView.active;
        _activeExerciseKey = null;
        _pulsePhase = _PulsePhase.none;
      });
      if (key != null) {
        unawaited(_logKineticUse(key, 'Aborted'));
      }
    }
  }

  Future<void> _restoreIslandOnForeground() async {
    if (!mounted) return;
    if (_isLandscape) {
      try {
        await _fullController?.play();
      } catch (e) {
        debugPrint('Vista video resume failed: $e');
      }
    }
    if (_mode == _IslandMode.vista && _userHasSelectedVista) {
      await _playVistaAudio(_selectedVistaIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateOrientation(
      MediaQuery.of(context).orientation == Orientation.landscape,
      initializeOnly: true,
    );
  }

  @override
  void didChangeMetrics() {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    _updateOrientation(size.width > size.height);
  }

  void _setMode(_IslandMode mode) {
    if (_isLandscape || _mode == mode) return;
    setState(() => _mode = mode);
    if (mode == _IslandMode.vista) {
      _playVistaAudio(_selectedVistaIndex);
    } else {
      _stopVistaAudio();
    }
  }

  void _updateOrientation(bool isLandscape, {bool initializeOnly = false}) {
    if (_isLandscape == isLandscape && !initializeOnly) return;
    if (isLandscape) {
      _lastPortraitMode = _mode;
      _mode = _IslandMode.vista;
      _loadFullVista();
      _playVistaAudio(_selectedVistaIndex);
      _syncVistaPagerToSelection();
    } else {
      _fullController?.dispose();
      _fullController = null;
      _fullError = null;
      if (_lastPortraitMode != _IslandMode.vista) {
        _mode = _lastPortraitMode;
      }
      if (_mode == _IslandMode.vista) {
        _playVistaAudio(_selectedVistaIndex);
      } else {
        _stopVistaAudio();
      }
    }
    if (!initializeOnly) {
      setState(() => _isLandscape = isLandscape);
    } else {
      _isLandscape = isLandscape;
    }
  }

  double getNeonSize(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape ? 280 : 180;
  }

  /// Upper bound for READY / rep / audit words so FittedBox can fit them on-screen.
  double _kineticNeonDisplaySize(BuildContext context) {
    final mq = MediaQuery.of(context);
    final shortest = mq.size.shortestSide;
    final isLandscape = mq.orientation == Orientation.landscape;
    final base = isLandscape ? 280.0 : 180.0;
    return math.min(base, shortest * 0.42);
  }

  Future<void> _loadFullVista() async {
    final current = _fullController;
    _fullController = null;
    await current?.dispose();

    VideoPlayerController? controller;
    final videoPath = _vistas[_selectedVistaIndex].assetPath;
    try {
      final assetPath =
          kIsWeb ? videoPath.replaceFirst('assets/', '') : videoPath;
      controller = VideoPlayerController.asset(
        assetPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
    } catch (e) {
      controller?.dispose();
      if (mounted) {
        setState(() => _fullError = e.toString());
      }
      return;
    }

    await controller.setVolume(0.0);
    await controller.setLooping(true);
    await controller.play();
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() {
      _fullError = null;
      _fullController = controller;
    });
    _playVistaAudio(_selectedVistaIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          Positioned.fill(child: _buildModeContent()),
          if (!_isLandscape)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildModeToggle(),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _setMode(_IslandMode.kinetic),
              child: KineticNeonShield(
                isActive: _mode == _IslandMode.kinetic,
              ),
            ),
          ),
          if (!_isLandscape &&
              !_isExecutingSequence &&
              ModalRoute.of(context)?.settings.name == '/island')
            Positioned(
              top: 88,
              right: 16,
              child: CutControl(
                compact: true,
                currentId:
                    _mode == _IslandMode.voice ? 'voice' : 'vista',
              ),
            ),
          if (_isExecutingSequence)
            Positioned.fill(
              child: Stack(
                children: [
                  RawGestureDetector(
                    gestures: {
                      LongPressGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              LongPressGestureRecognizer>(
                        () => LongPressGestureRecognizer(
                          duration: const Duration(milliseconds: 800),
                        ),
                        (instance) {
                          instance.onLongPress = _killSwitch;
                        },
                      ),
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: _kineticOverlayColor(),
                      child: Center(
                        child: _buildActiveExerciseView(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: SafeArea(child: _buildSwapAction()),
                  ),
                ],
              ),
            ),
          if (_isLandscape && _mode == _IslandMode.vista)
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: _buildVistaDots(),
            ),
        ],
      ),
    );
  }

  Widget _buildModeContent() {
    switch (_mode) {
      case _IslandMode.vista:
        return _isLandscape ? _buildFullVistaBackground() : _buildVistaGrid();
      case _IslandMode.voice:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
            child: const AffirmationsLibraryScreen(embedded: true),
          ),
        );
      case _IslandMode.kinetic:
        return _buildKineticPanel();
    }
  }

  Widget _buildModeToggle() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            _buildModeChip('VISTA', _IslandMode.vista),
            const SizedBox(width: 8),
            _buildModeChip('VOICE', _IslandMode.voice),
            const SizedBox(width: 8),
            _buildModeChip('KINETIC', _IslandMode.kinetic),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, _IslandMode mode) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.white38 : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(selected ? 0.95 : 0.7),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVistaGrid() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
      itemCount: _vistas.length,
      itemBuilder: (context, index) {
        final vista = _vistas[index];
        return _VistaPreviewCard(
          label: vista.label,
          assetPath: vista.assetPath,
          onTap: () {
            setState(() {
              _selectedVistaIndex = index;
              _userHasSelectedVista = true;
            });
            if (_mode == _IslandMode.vista) {
              _playVistaAudio(index);
            }
          },
        );
      },
    );
  }

  Widget _buildFullVistaBackground() {
    return PageView.builder(
      key: const ValueKey('vista_landscape_pager'),
      controller: _vistaPageController,
      itemCount: _vistas.length,
      onPageChanged: _onVistaPageChanged,
      itemBuilder: (context, index) => _buildVistaPage(index),
    );
  }

  void _onVistaPageChanged(int index) {
    if (_selectedVistaIndex == index) return;
    setState(() {
      _selectedVistaIndex = index;
      _userHasSelectedVista = true;
    });
    _loadFullVista();
    _playVistaAudio(index);
  }

  void _syncVistaPagerToSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isLandscape) return;
      if (!_vistaPageController.hasClients) return;
      final current = _vistaPageController.page?.round() ??
          _vistaPageController.initialPage;
      if (current == _selectedVistaIndex) return;
      _vistaPageController.jumpToPage(_selectedVistaIndex);
    });
  }

  Widget _buildVistaPage(int index) {
    if (index != _selectedVistaIndex || _fullError != null) {
      return _buildFallback();
    }
    final controller = _fullController;
    if (controller == null || !controller.value.isInitialized) {
      return _buildFallback();
    }
    final fit = _isMountainVista(_vistas[index].assetPath)
        ? BoxFit.fitHeight
        : BoxFit.cover;
    return FittedBox(
      fit: fit,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildVistaDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_vistas.length, (index) {
        final selected = index == _selectedVistaIndex;
        return GestureDetector(
          onTap: () {
            setState(() => _userHasSelectedVista = true);
            if (_vistaPageController.hasClients) {
              _vistaPageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              );
              return;
            }
            setState(() => _selectedVistaIndex = index);
            _loadFullVista();
            _playVistaAudio(index);
          },
          child: Container(
            width: selected ? 10 : 8,
            height: selected ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(selected ? 0.9 : 0.45),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF001A33),
    );
  }

  bool _isMountainVista(String assetPath) {
    return assetPath.endsWith('mountain_bell.mp4');
  }

  Future<void> _startVistaSession() async {
    if (_vistaStopwatch.isRunning) return;
    _vistaStopwatch
      ..reset()
      ..start();
  }

  Future<void> _logVistaSession() async {
    if (!_vistaStopwatch.isRunning) return;
    _vistaStopwatch.stop();
    final elapsed = _vistaStopwatch.elapsed.inSeconds;
    await UsageLogService.logAnchorUsage(
      flavor: 'The Vista',
      durationSeconds: elapsed == 0 ? 1 : elapsed,
    );
    _vistaStopwatch.reset();
  }

  Future<void> _playVistaAudio(int index) async {
    if (!_userHasSelectedVista) return;
    if (_activeVistaAudioIndex == index && _vistaAudio.playing) return;
    final audioPath = _vistaAudioPathForIndex(index);
    try {
      await _logVistaSession();
      await _vistaAudio.setLoopMode(LoopMode.one);
      await _vistaAudio.setVolume(1.0);
      await _vistaAudio.setAsset(audioPath);
      await _vistaAudio.play();
      _activeVistaAudioIndex = index;
      await _startVistaSession();
    } catch (e) {
      debugPrint('Vista audio failed: $e');
      _activeVistaAudioIndex = -1;
    }
  }

  Future<void> _stopVistaAudio() async {
    try {
      await _vistaAudio.setLoopMode(LoopMode.off);
      await _vistaAudio.setVolume(0.0);
      await _vistaAudio.stop();
    } catch (e) {
      debugPrint('Vista audio stop failed: $e');
    } finally {
      _activeVistaAudioIndex = -1;
      await _logVistaSession();
    }
  }

  String _resolveAudioAsset(String assetPath) {
    if (assetPath.startsWith('assets/')) {
      return assetPath;
    }
    return 'assets/$assetPath';
  }

  Future<void> _playMissionClip(String assetPath) async {
    final resolved = _resolveAudioAsset(assetPath);
    await _missionControlPlayer.setAsset(resolved);
    await _missionControlPlayer.play();
    await _missionControlPlayer.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
  }

  Future<void> startThreeRepSequence(String exerciseIntro) async {
    await _vistaAudio.setVolume(0.0);

    await _playMissionClip(exerciseIntro);

    for (int i = 1; i <= 3; i++) {
      final pauseSeconds = (i == 1) ? 4 : 3;
      await Future.delayed(Duration(seconds: pauseSeconds));
      await _playMissionClip('audio/rep_$i.mp3');
    }

    await _playMissionClip('audio/exit_island.mp3');

    await _vistaAudio.setVolume(1.0);

    if (!mounted) return;
    Navigator.pop(context);
  }

  bool _sequenceAlive(int gen) {
    return mounted && !_sessionHalted && gen == _kineticGeneration;
  }

  Future<void> _haltKineticMotion() async {
    _stopShakeStaccato();
    _stopIsometricRamp();
    _stopPulseTapLoop();
    _stopPulseVisualPulse();
    await KineticVoiceEngine.emergencyStop();
  }

  Future<void> playKineticSequence(String exerciseKey) async {
    if (kineticScriptById(exerciseKey) == null) return;
    final clips = kineticScripts[exerciseKey];
    final gen = ++_kineticGeneration;

    setState(() {
      _isExecutingSequence = true;
      _currentRep = 0;
      _kineticView = _KineticView.active;
      _activeExerciseKey = exerciseKey;
      _kineticLogged = false;
      _pulsePhase = _PulsePhase.none;
    });

    await _haltKineticMotion();
    if (!mounted || gen != _kineticGeneration) return;

    await _vistaAudio.setVolume(0.0);
    if (exerciseKey == 'pulse') {
      _setPulsePhase(_PulsePhase.matchBeat);
      _startPulseVisualPulse(const Duration(milliseconds: 1000));
      _pulseBaselineIntensity = 38;
      _pulseMatched = false;
      await KineticVoiceEngine.startPulseBaseline(_pulseBaselineIntensity);
      _startPulseTapLoop();
    }
    if (exerciseKey == 'headphones_dark') {
      await KineticVoiceEngine.startEngineThrum();
    }

    try {
      // Primer orients. The three reps are the instrument — one pass
      // does not break the loop.
      await KineticVoiceEngine.playPrimer(exerciseKey);
      if (!_sequenceAlive(gen)) return;

      for (int i = 1; i <= kineticRepCount; i++) {
        await Future.delayed(const Duration(seconds: 2));
        if (!_sequenceAlive(gen)) return;
        setState(() => _currentRep = i);
        _startProtocolHaptics(exerciseKey);
        await _cueKineticRep(exerciseKey, i);
        if (!_sequenceAlive(gen)) return;
        await KineticVoiceEngine.playRep(exerciseKey);
        _stopProtocolHaptics(exerciseKey);
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!_sequenceAlive(gen)) return;
      if (exerciseKey == 'pulse') {
        await _runClosingLoop();
      }
      if (clips != null && clips.length > 4) {
        try {
          await _playMissionClip(clips[4]);
        } catch (e) {
          debugPrint('Kinetic exit clip failed: $e');
        }
      }
      if (_sequenceAlive(gen)) {
        await _logKineticUse(exerciseKey, 'Acknowledged');
      }
    } finally {
      if (gen == _kineticGeneration) {
        if (exerciseKey == 'pulse') {
          await KineticVoiceEngine.stopPulseThrum();
        }
        if (gen == _kineticGeneration && exerciseKey == 'pulse') {
          _setPulsePhase(_PulsePhase.none);
          _stopPulseVisualPulse();
          _stopPulseTapLoop();
        }
        if (exerciseKey == 'somatic_shaking' || exerciseKey == 'tense_release') {
          _stopShakeStaccato();
          await KineticVoiceEngine.stopPulseThrum();
        }
        if (exerciseKey == 'muscle_clench') {
          _stopIsometricRamp();
          await KineticVoiceEngine.stopPulseThrum();
        }
        if (exerciseKey == 'headphones_dark') {
          await KineticVoiceEngine.stopEngineThrum();
        }
        _stopShakeStaccato();
        _stopIsometricRamp();
        await _vistaAudio.setVolume(0.0);
        if (_sequenceAlive(gen)) {
          setState(() {
            _isExecutingSequence = false;
            _currentRep = 0;
            _kineticView = _KineticView.menu;
            _mode = _IslandMode.kinetic;
            _activeExerciseKey = null;
          });
        }
      }
    }
  }

  void _startProtocolHaptics(String exerciseKey) {
    if (exerciseKey == 'pulse') return;
    final pattern = kineticScriptById(exerciseKey)?.hapticPattern;
    _setPulsePhase(_PulsePhase.actionPulse);
    switch (pattern) {
      case KineticHapticPattern.continuousSqueeze:
        _startPulseVisualPulse(const Duration(milliseconds: 1600));
        unawaited(_startIsometricRamp(const Duration(seconds: 4)));
        break;
      case KineticHapticPattern.rapidShake:
        _startPulseVisualPulse(const Duration(milliseconds: 900));
        _startShakeStaccato(
          microClick: exerciseKey != 'somatic_shaking' &&
              exerciseKey != 'tense_release',
        );
        break;
      case KineticHapticPattern.continuousPush:
      default:
        _startPulseVisualPulse(const Duration(milliseconds: 900));
        break;
    }
  }

  void _stopProtocolHaptics(String exerciseKey) {
    if (exerciseKey == 'pulse') return;
    _stopPulseVisualPulse();
    _setPulsePhase(_PulsePhase.none);
    final pattern = kineticScriptById(exerciseKey)?.hapticPattern;
    if (pattern == KineticHapticPattern.continuousSqueeze) {
      _triggerIsometricRelease();
    }
    if (pattern == KineticHapticPattern.rapidShake) {
      _stopShakeStaccato();
    }
  }

  Future<void> _launchOverride() async {
    final next = pickKineticOverride(previousId: _activeExerciseKey);
    HapticFeedback.heavyImpact();
    await playKineticSequence(next);
  }

  void _onTumblerDrag(DragUpdateDetails details) {
    final now = DateTime.now();
    final last = _tumblerTickAt;
    if (last != null && now.difference(last).inMilliseconds < 80) {
      return;
    }
    _tumblerTickAt = now;
    HapticFeedback.selectionClick();
  }

  void _onTumblerEnd(DragEndDetails details) {
    HapticFeedback.heavyImpact();
    unawaited(_launchOverride());
  }

  /// Silent draw. No rumble — LOW SIG is for when the phone stays down.
  void _drawLowSig() {
    final next = pickKineticLowSig(previousId: _expandedStealthId);
    setState(() => _expandedStealthId = next);
  }

  /// FIELD glance stays on the card. The rumble is the instrument.
  void _toggleFieldCard(KineticScript script) {
    final closing = _expandedFieldId == script.id;
    setState(() => _expandedFieldId = closing ? null : script.id);
    if (closing) {
      _kineticGeneration += 1;
      unawaited(_haltFieldHaptics(script.id));
      return;
    }
    unawaited(_runFieldHaptics(script.id));
  }

  Future<void> _runFieldHaptics(String exerciseKey) async {
    final gen = ++_kineticGeneration;
    _kineticLogged = false;
    await _haltKineticMotion();
    if (!_sequenceAlive(gen)) return;
    if (exerciseKey == 'headphones_dark') {
      await KineticVoiceEngine.startEngineThrum();
    }
    try {
      for (var i = 1; i <= kineticRepCount; i++) {
        if (!_sequenceAlive(gen)) return;
        _startProtocolHaptics(exerciseKey);
        await KineticVoiceEngine.playRep(exerciseKey);
        _stopProtocolHaptics(exerciseKey);
      }
      if (_sequenceAlive(gen)) {
        await _logKineticUse(exerciseKey, 'Acknowledged');
      }
    } finally {
      if (gen == _kineticGeneration) {
        await _haltFieldHaptics(exerciseKey);
      }
    }
  }

  Future<void> _haltFieldHaptics(String exerciseKey) async {
    _stopProtocolHaptics(exerciseKey);
    _stopShakeStaccato();
    _stopIsometricRamp();
    if (exerciseKey == 'headphones_dark') {
      await KineticVoiceEngine.stopEngineThrum();
    }
  }

  String _vistaAudioPathForIndex(int index) {
    switch (index) {
      case 0:
        return 'assets/audio/vistas/nadir_chant.mp3';
      case 1:
        return 'assets/audio/vistas/monastery_wind.mp3';
      case 2:
      default:
        return 'assets/audio/vistas/oasis_water.mp3';
    }
  }

  Widget _buildKineticPanel() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Column(
          children: [
            const Text(
              'KINETIC',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildKineticSubViewRow(),
            const SizedBox(height: 16),
            const Text(
              'OPTION DECK. Draw. SWAP if it does not land.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'RobotoMono',
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: _kineticView == _KineticView.active
                    ? _buildActiveExerciseView()
                    : _buildKineticMenu(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menu vs active exercise surface only — VISTA / VOICE / KINETIC live in [_buildModeToggle].
  Widget _buildKineticSubViewRow() {
    return Row(
      children: [
        Expanded(
          child: _buildKineticToggleChip(
            label: 'MENU',
            selected: _kineticView == _KineticView.menu,
            onTap: () => setState(() {
              _mode = _IslandMode.kinetic;
              _kineticView = _KineticView.menu;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKineticToggleChip(
            label: 'ACTIVE',
            selected: _kineticView == _KineticView.active,
            onTap: () => setState(() {
              _mode = _IslandMode.kinetic;
              _kineticView = _KineticView.active;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildKineticToggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.white38 : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(selected ? 0.95 : 0.7),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveExerciseView() {
    if (!_isExecutingSequence) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SELECT A SEQUENCE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'OVERRIDE fires a random instrument. SWAP rerolls.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 20),
          _buildKineticMenu(),
        ],
      );
    }

    final isPulse = _activeExerciseKey == 'pulse';
    final isAudit = _pulsePhase == _PulsePhase.auditPause;
    final displayText =
        isAudit ? _auditText : (_currentRep > 0 ? '$_currentRep' : 'READY');
    final neonDisplay = _kineticNeonDisplaySize(context);
    final textStyle = isAudit
        ? TextStyle(
            fontSize: (neonDisplay * 1.1).clamp(48, 400),
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontFamily: 'Roboto',
            color: Colors.white,
            shadows: const [
              Shadow(blurRadius: 18, color: Colors.white),
              Shadow(blurRadius: 36, color: Colors.white70),
            ],
          )
        : TextStyle(
            fontSize: neonDisplay,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto',
            letterSpacing: 3,
            color: const Color(0xFFFF5F1F),
            shadows: [
              const Shadow(
                blurRadius: 30,
                color: Color(0xFFFF5F1F),
              ),
              Shadow(
                blurRadius: 60,
                color: const Color(0xFFFF5F1F).withOpacity(0.5),
              ),
            ],
          );

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_pulsePhase != _PulsePhase.none) _buildPulseShieldVisual(),
          if (isAudit) _buildAuditOverlay(displayText, textStyle),
          if (!isAudit)
            _buildScaledKineticLabel(displayText, textStyle),
        ],
      ),
    );
  }

  /// Neon labels: bound width *and* height so "READY" always fits the viewport.
  Widget _buildScaledKineticLabel(String text, TextStyle style) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final maxW = size.width * 0.88;
    final maxH = math.max(80.0, (size.height - pad.vertical) * 0.28);
    return SizedBox(
      width: maxW,
      height: maxH,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: Text(
          text,
          style: style,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }

  Widget _buildAuditOverlay(String text, TextStyle style) {
    return Opacity(
      opacity: 1.0,
      child: _buildScaledKineticLabel(text, style),
    );
  }

  Color _kineticOverlayColor() {
    if (_pulsePhase == _PulsePhase.auditPause) {
      if (_activeExerciseKey == 'pulse' && _auditText == 'VISION') {
        return const Color(0xFFE8F2FF);
      }
      return const Color(0xFF0D1F33);
    }
    if (_pulsePhase == _PulsePhase.actionPulse) {
      if (_activeExerciseKey == 'somatic_shaking' ||
          _activeExerciseKey == 'tense_release') {
        return Color.lerp(
              Colors.black,
              Colors.white,
              0.08 + (0.12 * _pulseVisualAnimation.value),
            ) ??
            Colors.black;
      }
      if (_activeExerciseKey == 'muscle_clench') {
        return Color.lerp(
              Colors.black,
              const Color(0xFFFFD36A),
              0.12 + (0.22 * _pulseVisualAnimation.value),
            ) ??
            Colors.black;
      }
      return Color.lerp(
            Colors.black,
            const Color(0xFFFFB347),
            0.15 + (0.25 * _pulseVisualAnimation.value),
          ) ??
          Colors.black;
    }
    return Colors.black;
  }

  Widget _buildPulseShieldVisual() {
    final pulseValue = _pulseVisualAnimation.value;
    Color glowColor = Colors.transparent;
    double intensity = 0.0;

    switch (_pulsePhase) {
      case _PulsePhase.matchBeat:
        glowColor = Color.lerp(
              const Color(0xFF0D2A4A),
              const Color(0xFF34E5FF),
              pulseValue,
            ) ??
            const Color(0xFF34E5FF);
        intensity = 0.35 + (0.55 * pulseValue);
        break;
      case _PulsePhase.matchThrum:
        glowColor = const Color(0xFFFFB347);
        intensity = 0.85;
        break;
      case _PulsePhase.actionPulse:
        if (_activeExerciseKey == 'somatic_shaking' ||
            _activeExerciseKey == 'tense_release') {
          glowColor = Colors.white;
          intensity = 0.2 + (0.35 * pulseValue);
        } else if (_activeExerciseKey == 'muscle_clench') {
          glowColor = const Color(0xFFFFD36A);
          intensity = 0.4 + (0.5 * pulseValue);
        } else {
          glowColor = const Color(0xFFFFB347);
          intensity = 0.35 + (0.55 * pulseValue);
        }
        break;
      case _PulsePhase.auditPause:
        if (_activeExerciseKey == 'pulse' && _auditText == 'VISION') {
          glowColor = Colors.white;
          intensity = 0.45 + (0.35 * pulseValue);
        } else if (_activeExerciseKey == 'muscle_clench') {
          glowColor = const Color(0xFF6BC4FF);
          intensity = 0.45 + (0.35 * pulseValue);
        } else {
          glowColor = const Color(0xFF0B2A4A);
          intensity = 0.55 + (0.35 * pulseValue);
        }
        break;
      case _PulsePhase.closingLoop:
        glowColor = _closingFlashOn ? const Color(0xFF39FF14) : Colors.transparent;
        intensity = _closingFlashOn ? 1.0 : 0.0;
        break;
      case _PulsePhase.none:
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: getNeonSize(context) * 0.9,
      height: getNeonSize(context) * 0.9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.15),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.5 * intensity),
            blurRadius: 40 * intensity,
            spreadRadius: 6 * intensity,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.25 * intensity),
            blurRadius: 80 * intensity,
            spreadRadius: 12 * intensity,
          ),
        ],
        border: Border.all(
          color: glowColor.withOpacity(0.35 + (0.3 * intensity)),
          width: 2,
        ),
      ),
    );
  }

  Future<void> _runAuditPause({required String exerciseKey}) async {
    if (!mounted) return;
    _auditText = exerciseKey == 'pulse' ? 'VISION' : 'FEEL YOUR FEET';
    _setPulsePhase(_PulsePhase.auditPause);
    _startPulseVisualPulse(const Duration(milliseconds: 2000));
    await Future.delayed(const Duration(milliseconds: 2000));
    _stopPulseVisualPulse();
  }

  Future<void> _triggerAuditWindow(AuditMarker marker) async {
    if (!mounted) return;
    _auditText = marker.label;
    _setPulsePhase(_PulsePhase.auditPause);
    _startPulseVisualPulse(marker.hold);
    if (_activeExerciseKey == 'somatic_shaking' ||
        _activeExerciseKey == 'tense_release') {
      _stopShakeStaccato();
      await KineticVoiceEngine.startPulseHumLow();
    }
    if (_activeExerciseKey == 'muscle_clench') {
      _stopIsometricRamp();
      await KineticVoiceEngine.startPulseHumLow();
    }
    if (_activeExerciseKey == 'pulse') {
      if (marker.label == 'FEEL FEET') {
        await KineticVoiceEngine.startPulseBaseline(26);
      }
    }
    if (marker.label == 'LOCKED') {
      await _fadePulseExit(marker.hold);
      _stopPulseVisualPulse();
      _setPulsePhase(_PulsePhase.none);
      return;
    }
    await Future.delayed(marker.hold);
    _stopPulseVisualPulse();
    if (_activeExerciseKey == 'somatic_shaking' ||
        _activeExerciseKey == 'tense_release' ||
        kineticScriptById(_activeExerciseKey ?? '')?.hapticPattern ==
            KineticHapticPattern.rapidShake) {
      await KineticVoiceEngine.stopPulseThrum();
      if (_pulsePhase == _PulsePhase.actionPulse) {
        _startShakeStaccato(
          microClick: _activeExerciseKey != 'somatic_shaking' &&
              _activeExerciseKey != 'tense_release',
        );
      }
    }
    if (_activeExerciseKey == 'muscle_clench') {
      await KineticVoiceEngine.stopPulseThrum();
    }
    if (_activeExerciseKey == 'pulse') {
      if (marker.label == 'FEEL FEET') {
        await KineticVoiceEngine.startPulseBaseline(_pulseBaselineIntensity);
      }
    }
    _setPulsePhase(_PulsePhase.none);
  }

  Future<void> _runClosingLoop() async {
    if (!mounted) return;
    _setPulsePhase(_PulsePhase.closingLoop);
    _stopPulseVisualPulse();
    await KineticVoiceEngine.stopPulseThrum();
    await KineticVoiceEngine.triggerTripleTap();
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() => _closingFlashOn = true);
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _closingFlashOn = false);
      await Future.delayed(const Duration(milliseconds: 80));
    }
    _closingFlashOn = false;
    _setPulsePhase(_PulsePhase.none);
  }

  void _setPulsePhase(_PulsePhase phase) {
    if (_pulsePhase == phase) return;
    setState(() => _pulsePhase = phase);
  }

  void _startPulseVisualPulse(Duration duration) {
    _pulseVisualController
      ..duration = duration
      ..reset()
      ..repeat(reverse: true);
  }

  void _stopPulseVisualPulse() {
    if (_pulseVisualController.isAnimating) {
      _pulseVisualController.stop();
    }
  }

  void _startShakeStaccato({bool microClick = false}) {
    _shakeHapticTimer?.cancel();
    _shakeHapticTimer =
        Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (microClick) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _stopShakeStaccato() {
    _shakeHapticTimer?.cancel();
    _shakeHapticTimer = null;
  }

  Future<void> _logKineticUse(String exerciseKey, String status) async {
    if (_kineticLogged) return;
    _kineticLogged = true;
    await AegisLogService.logEntry(
      toolName: kineticLedgerTool,
      status: status,
      signalInput: kineticInstrumentLabel(exerciseKey),
    );
  }

  Future<void> _cueKineticRep(String exerciseKey, int rep) async {
    final labels = _kineticRepCues(exerciseKey);
    if (rep < 1 || rep > labels.length) return;
    await _triggerAuditWindow(
      AuditMarker(
        at: Duration.zero,
        label: labels[rep - 1],
        hold: const Duration(milliseconds: 1200),
      ),
    );
  }

  List<String> _kineticRepCues(String exerciseKey) {
    switch (exerciseKey) {
      case 'wall_push':
      case 'wall_pushups':
        return const ['VISION', 'FEET', 'HEAD'];
      case 'somatic_shaking':
      case 'tense_release':
        return const ['VISION', 'FEET', 'GROUNDED'];
      case 'muscle_clench':
        return const ['BREATHE', 'VISION', 'STATUS: GREEN'];
      case 'pulse':
        return const ['FEEL FEET', 'VISION', 'HOLD'];
      case 'hot_car':
        return const ['SEAT', 'WRIST', 'RELEASE'];
      case 'winter_subzero':
        return const ['HEELS', 'VENT', 'HOLD'];
      case 'summer_heatwave':
        return const ['WRIST', 'EXHALE', 'HOLD'];
      case 'stall_reset':
        return const ['PALMS', 'HEELS', 'STILL'];
      case 'headphones_dark':
        return const ['COVER', 'CUT', 'HOLD'];
      case 'sink_wash':
        return const ['WRIST', 'NECK', 'STOP'];
      default:
        return const ['HOLD', 'HOLD', 'HOLD'];
    }
  }

  Future<void> _killSwitch() async {
    if (!_isExecutingSequence) return;
    _kineticGeneration += 1;
    final key = _activeExerciseKey;
    _stopShakeStaccato();
    _stopIsometricRamp();
    _stopPulseTapLoop();
    await KineticVoiceEngine.stopPulseThrum();
    await KineticVoiceEngine.stopVoice();
    _setPulsePhase(_PulsePhase.none);
    _stopPulseVisualPulse();
    if (key != null) {
      await _logKineticUse(key, 'Aborted');
    }
    if (!mounted) return;
    setState(() {
      _isExecutingSequence = false;
      _currentRep = 0;
      _kineticView = _KineticView.menu;
      _mode = _IslandMode.kinetic;
      _activeExerciseKey = null;
    });
  }

  Future<void> _handlePulseMarker(TrackMarker marker) async {
    if (!mounted) return;
    if (marker.key == 'match_thrum') {
      _pulseMatched = true;
      _pulseBaselineIntensity = 102;
      await KineticVoiceEngine.startPulseBaseline(_pulseBaselineIntensity);
    }
  }

  void _startPulseTapLoop() {
    _pulseTapTimer?.cancel();
    _pulseTapTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      HapticFeedback.lightImpact();
    });
  }

  void _stopPulseTapLoop() {
    _pulseTapTimer?.cancel();
    _pulseTapTimer = null;
  }

  Future<void> _fadePulseExit(Duration duration) async {
    _stopPulseTapLoop();
    final steps = (duration.inMilliseconds / 500).ceil().clamp(1, 12);
    final stepMs = (duration.inMilliseconds / steps).round();
    final startIntensity = _pulseBaselineIntensity;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final intensity = (startIntensity * (1 - t)).round();
      await KineticVoiceEngine.startPulseBaseline(intensity.clamp(0, 255));
      await KineticVoiceEngine.setVoiceVolume((1 - t).clamp(0.0, 1.0));
      await Future.delayed(Duration(milliseconds: stepMs));
    }
    await KineticVoiceEngine.stopPulseThrum();
  }

  Future<void> _handleIsometricMarker(TrackMarker marker) async {
    if (!mounted) return;
    switch (marker.key) {
      case 'clench_start_1':
      case 'clench_start_2':
        await _startIsometricRamp(const Duration(seconds: 7));
        break;
      case 'clench_end_1':
      case 'clench_end_2':
        _stopIsometricRamp();
        break;
      case 'release_1':
      case 'release_2':
        _triggerIsometricRelease();
        break;
    }
  }

  Future<void> _startIsometricRamp(Duration duration) async {
    _stopIsometricRamp();
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    final hasAmplitude = await Vibration.hasAmplitudeControl() ?? false;
    final totalMs = duration.inMilliseconds;
    const stepMs = 150;
    final steps = (totalMs / stepMs).ceil().clamp(1, 200);
    var step = 0;
    _isometricRampTimer = Timer.periodic(
      const Duration(milliseconds: stepMs),
      (_) {
        final t = (step / steps).clamp(0.0, 1.0);
        final intensity = (0.2 + (0.8 * t)) * 255;
        if (hasAmplitude) {
          Vibration.vibrate(
            duration: stepMs,
            amplitude: intensity.round().clamp(1, 255),
          );
        } else {
          HapticFeedback.mediumImpact();
        }
        step += 1;
        if (step > steps) {
          _stopIsometricRamp();
        }
      },
    );
  }

  void _stopIsometricRamp() {
    _isometricRampTimer?.cancel();
    _isometricRampTimer = null;
    Vibration.cancel();
  }

  void _triggerIsometricRelease() {
    _stopIsometricRamp();
    HapticFeedback.heavyImpact();
  }

  Duration _auditTimestamp({required Duration base, required String key}) {
    final offsetMs = _playbackOffsets[key] ?? 0;
    final adjustedMs = base.inMilliseconds + offsetMs.round();
    return Duration(milliseconds: adjustedMs < 0 ? 0 : adjustedMs);
  }

  Widget _buildKineticMenu() {
    final cards = [
      _KineticCardSpec(
        title: 'Wall Push',
        exerciseKey: 'wall_push',
        icon: Icons.back_hand,
        glowColor: const Color(0xFFFFB347),
      ),
      _KineticCardSpec(
        title: 'The Shake',
        exerciseKey: 'somatic_shaking',
        icon: Icons.vibration,
        glowColor: Colors.white,
      ),
      _KineticCardSpec(
        title: 'Isometric',
        exerciseKey: 'muscle_clench',
        icon: Icons.fitness_center,
        glowColor: const Color(0xFFFFD36A),
      ),
      _KineticCardSpec(
        title: 'The Pulse',
        exerciseKey: 'pulse',
        icon: Icons.monitor_heart,
        glowColor: const Color(0xFF34E5FF),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOverrideControl(),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.82,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards.map((card) => _buildKineticCard(card)).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'FIELD',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vehicle stopped. Read the card. Hands off the wheel.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 8),
        ...kineticFieldDeck.map(_buildFieldRow),
        const SizedBox(height: 20),
        const Text(
          'LOW SIG',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'No instrument. Bus or meeting. Phone stays down.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 8),
        _buildLowSigDraw(),
        const SizedBox(height: 8),
        ...kineticStealthDeck.map(_buildStealthRow),
      ],
    );
  }

  Widget _buildOverrideControl() {
    return GestureDetector(
      key: const Key('kinetic_override'),
      onTap: () => unawaited(_launchOverride()),
      onVerticalDragUpdate: _onTumblerDrag,
      onVerticalDragEnd: _onTumblerEnd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Text(
          '[ OVERRIDE ]',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            fontFamily: 'RobotoMono',
          ),
        ),
      ),
    );
  }

  Widget _buildSwapAction() {
    final key = _activeExerciseKey;
    final script = key == null ? null : kineticScriptById(key);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (script != null) ...[
          Text(
            script.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.4,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            script.command,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          key: const Key('kinetic_swap'),
          onTap: () => unawaited(_launchOverride()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white38),
            ),
            child: const Text(
              'SWAP',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
                fontFamily: 'RobotoMono',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLowSigDraw() {
    return GestureDetector(
      key: const Key('kinetic_low_sig_draw'),
      onTap: _drawLowSig,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white38),
        ),
        child: const Text(
          '[ DRAW ]',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w700,
            fontFamily: 'RobotoMono',
          ),
        ),
      ),
    );
  }

  Widget _buildStealthRow(KineticScript script) {
    final expanded = _expandedStealthId == script.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: Key('kinetic_stealth_${script.id}'),
        onTap: () => setState(() {
          _expandedStealthId = expanded ? null : script.id;
        }),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: expanded ? Colors.white54 : Colors.white24,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                script.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                script.command,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'RobotoMono',
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Text(
                  script.instructions,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow(KineticScript script) {
    final expanded = _expandedFieldId == script.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: Key('kinetic_field_${script.id}'),
        onTap: () => _toggleFieldCard(script),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: expanded ? Colors.white54 : Colors.white24,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                script.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                script.command,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'RobotoMono',
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Text(
                  script.instructions,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKineticCard(_KineticCardSpec card) {
    final glow = card.glowColor;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => playKineticSequence(card.exerciseKey),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: glow.withOpacity(0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.35),
              blurRadius: 22,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: glow.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(card.icon, color: glow, size: 32),
            const Spacer(),
            Text(
              card.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to launch',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KineticCardSpec {
  const _KineticCardSpec({
    required this.title,
    required this.exerciseKey,
    required this.icon,
    required this.glowColor,
  });

  final String title;
  final String exerciseKey;
  final IconData icon;
  final Color glowColor;
}

class _VistaOption {
  const _VistaOption(this.label, this.assetPath);

  final String label;
  final String assetPath;
}

class _VistaPreviewCard extends StatefulWidget {
  const _VistaPreviewCard({
    required this.label,
    required this.assetPath,
    this.onTap,
  });

  final String label;
  final String assetPath;
  final VoidCallback? onTap;

  @override
  State<_VistaPreviewCard> createState() => _VistaPreviewCardState();
}

class _VistaPreviewCardState extends State<_VistaPreviewCard> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePreview() async {
    VideoPlayerController? controller;
    try {
      final assetPath = kIsWeb
          ? widget.assetPath.replaceFirst('assets/', '')
          : widget.assetPath;
      controller = VideoPlayerController.asset(
        assetPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
    } catch (e) {
      controller?.dispose();
      if (mounted) {
        setState(() => _error = e.toString());
      }
      return;
    }

    await controller.setVolume(0.0);
    await controller.setLooping(true);
    await controller.play();
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: _buildVideoLayer(),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_error != null) {
      return _buildFallback();
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildFallback();
    }
    final fit = widget.assetPath.endsWith('mountain_bell.mp4')
        ? BoxFit.fitHeight
        : BoxFit.cover;
    return FittedBox(
      fit: fit,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF001A33),
      child: Center(
        child: _error == null
            ? const CircularProgressIndicator(color: Colors.white24)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Video error: $_error',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}

class KineticNeonShield extends StatefulWidget {
  final bool isActive;

  const KineticNeonShield({super.key, required this.isActive});

  @override
  State<KineticNeonShield> createState() => _KineticNeonShieldState();
}

class _KineticNeonShieldState extends State<KineticNeonShield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _glowAnimation = Tween<double>(begin: 10.0, end: 40.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant KineticNeonShield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      child: const Icon(
        Icons.shield,
        size: 40,
        color: Color(0xFFFFAC81),
      ),
      builder: (context, child) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5F1F).withOpacity(0.8),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
              BoxShadow(
                color: const Color(0xFFFFAC81).withOpacity(0.5),
                blurRadius: _glowAnimation.value * 2,
              ),
            ],
          ),
          child: Center(child: child),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
