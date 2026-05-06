import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

import 'package:anxiety_anchor/services/usage_log_service.dart';
import 'package:anxiety_anchor/services/vault_service.dart';
import 'package:anxiety_anchor/models/vault_model.dart';
import 'package:anxiety_anchor/widgets/vault_intake_panel.dart';
import 'package:anxiety_anchor/widgets/vault_timer_view.dart';

class WorryVaultScreen extends StatefulWidget {
  const WorryVaultScreen({super.key});

  @override
  State<WorryVaultScreen> createState() => _WorryVaultScreenState();
}

class _WorryVaultScreenState extends State<WorryVaultScreen>
    with SingleTickerProviderStateMixin {
  static const String _vaultVideoPath = 'assets/videos/vault_door.mp4';
  static const String _vaultVideoFileName = 'vault_door.mp4';
  String get _vaultAssetPath =>
      kIsWeb ? _vaultVideoPath.replaceFirst('assets/', '') : _vaultVideoPath;
  VideoPlayerController? _controller;
  final TextEditingController _worryController = TextEditingController();
  bool _isLocked = false;
  Timer? _timer;
  Timer? _lockoutTimer;
  Timer? _frostFrameTimer;
  int _secondsRemaining = 300;
  String? _videoError;
  DateTime? _lockoutEndsAt;
  int _frostFrameIndex = 0;
  late final AnimationController _frostController;
  final AudioPlayer _vaultSfx = AudioPlayer();
  final AudioPlayer _vaultAmbience = AudioPlayer();
  final AudioPlayer _systemVoice = AudioPlayer();
  bool _closeSoundPlayed = false;
  bool _showScriptBox = false;
  bool _hasShownScriptBox = false;
  bool _mediaUnlocked = false;
  bool _mediaPrepared = false;
  final Stopwatch _vaultStopwatch = Stopwatch();
  bool _showChat = false;
  /// Last [VideoPlayerValue.size] seen; used to [setState] when Android reports 0×0 until first frame.
  Size _lastVaultVideoSize = Size.zero;
  int _diveSeconds = 5;
  final VaultService _vaultService = VaultService();
  VaultEntry? _vaultArchive;
  bool _vaultReady = false;
  bool _showDive = false;
  Timer? _diveTimer;
  Timer? _scriptBoxTimer;
  bool _isDrifting = false;
  final List<String> _frostFrames = List.generate(
    19,
    (index) =>
        'assets/images/frost/frost_screen_${(index + 1).toString().padLeft(2, '0')}.jpg',
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _frostController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _checkLockStatus();
    _initializeVideo();
    _prepareVaultAudio();
    // Unlock SFX/ambience after boot; door video starts when dive completes (see [_startDiveTimer]).
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _mediaUnlocked = true);
    });
    _showChat = true;
  }

  void _onOrientationChange(Orientation orientation) {
    if (orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _initializeVideo() async {
    final previous = _controller;
    if (previous != null) {
      previous.removeListener(_onVaultVideoControllerUpdate);
      await previous.dispose();
      _controller = null;
      _lastVaultVideoSize = Size.zero;
    }

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.asset(
        _vaultAssetPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
    } catch (e) {
      debugPrint('Vault asset load failed, falling back to local: $e');
      controller?.dispose();
      controller = null;
    }

    if (controller == null) {
      if (!kIsWeb) {
        try {
          final localFile = await _bootloadVaultAsset(
            assetPath: _vaultVideoPath,
            fileName: _vaultVideoFileName,
          );
          controller = VideoPlayerController.file(
            localFile,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
          await controller.initialize();
        } catch (e) {
          debugPrint('Vault local fallback failed: $e');
          if (mounted) {
            setState(() => _videoError = e.toString());
          }
          controller?.dispose();
          return;
        }
      } else {
        if (mounted) {
          setState(() => _videoError = 'Web fallback unavailable');
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    } else {
      _controller = controller;
    }
    _controller?.addListener(_onVaultVideoControllerUpdate);
    await _controller?.setVolume(1.0);
    await _controller?.setLooping(false);
    await _controller?.seekTo(Duration.zero);
  }

  void _onVaultVideoControllerUpdate() {
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      final sz = c.value.size;
      if (sz.width != _lastVaultVideoSize.width ||
          sz.height != _lastVaultVideoSize.height) {
        _lastVaultVideoSize = sz;
        if (mounted) setState(() {});
      }
    }
    _handleVaultVideoProgress();
  }

  void _handleVaultVideoProgress() {
    if (_hasShownScriptBox || _scriptBoxTimer != null || !_showDive) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    if (duration == Duration.zero) return;
    if (controller.value.position >= duration && !controller.value.isPlaying) {
      if (!mounted) return;
      _scheduleScriptBoxReveal(Duration.zero);
    }
  }

  void _startVaultSession() {
    if (_vaultStopwatch.isRunning) return;
    _vaultStopwatch
      ..reset()
      ..start();
  }

  Future<void> _logVaultSession() async {
    if (!_vaultStopwatch.isRunning) return;
    _vaultStopwatch.stop();
    final elapsed = _vaultStopwatch.elapsed.inSeconds;
    await UsageLogService.logAnchorUsage(
      flavor: 'The Vault',
      durationSeconds: elapsed == 0 ? 1 : elapsed,
    );
    _vaultStopwatch.reset();
  }

  Future<File> _bootloadVaultAsset({
    required String assetPath,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    if (await file.exists() && await file.length() > 0) {
      return file;
    }
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _lockVault() {
    setState(() {
      _isLocked = true;
      _secondsRemaining = 300;
    });
    _closeSoundPlayed = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          if (!_closeSoundPlayed) {
            _playVaultClose();
          }
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sealTheVault() async {
    HapticFeedback.lightImpact();

    // Capture ISO timestamp and full content immediately upon Release gesture
    final lockedAt = DateTime.now();
    final originalText = _worryController.text.trim();
    if (originalText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Intake empty. Enter signal text before SEAL VAULT.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final entry = VaultEntry(
      originalText: originalText,
      lockedAt: lockedAt,
      duration: VaultEntry.defaultLockDuration,
    );

    await _logVaultSession();
    if (_controller == null) {
      await _initializeVideo();
    }

    // Commit to local storage first; spin animation only fires after success
    await _vaultService.saveEntry(entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'vault_lockout_until',
      entry.unlockTime.toIso8601String(),
    );

    setState(() {
      _lockoutEndsAt = entry.unlockTime;
      _vaultArchive = entry;
      _isLocked = true;
      _vaultReady = false;
    });
    _startLockoutTicker();

    // Brief intake dismiss, then door video
    final controller = _controller;
    if (controller != null) {
      setState(() => _isDrifting = true);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _showScriptBox = false;
        _hasShownScriptBox = false;
        _isDrifting = false;
      });
      await controller.seekTo(Duration.zero);
      if (_mediaUnlocked) {
        await controller.play();
      }
    }

    _worryController.clear();
    _playVaultClose();
    _lockVault();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _showVaultLockedMessage();
    });
  }

  void _showVaultLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vault sealed. 8h reflection window — discard removes audit export. '
          'Then retention until full release.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _logVaultSession();
    _timer?.cancel();
    _lockoutTimer?.cancel();
    _frostFrameTimer?.cancel();
    _diveTimer?.cancel();
    _scriptBoxTimer?.cancel();
    _worryController.dispose();
    _controller?.removeListener(_onVaultVideoControllerUpdate);
    _controller?.dispose();
    _frostController.dispose();
    _vaultSfx.dispose();
    _vaultAmbience.dispose();
    _systemVoice.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _playVaultOpen() async {
    if (!_mediaUnlocked) return;
    try {
      if (!_mediaPrepared) {
        await _prepareVaultAudio();
      }
      await _vaultSfx.setAsset('assets/audio/vault/vault_open.mp3');
      await _vaultSfx.play();
    } catch (e) {
      debugPrint('Vault open audio missing: $e');
    }
  }

  Future<void> _playVaultClose() async {
    if (_closeSoundPlayed) return;
    if (!_mediaUnlocked) return;
    _closeSoundPlayed = true;
    try {
      if (!_mediaPrepared) {
        await _prepareVaultAudio();
      }
      await _vaultSfx.setAsset('assets/audio/vault/vault_close.mp3');
      await _vaultSfx.play();
    } catch (e) {
      debugPrint('Vault close audio missing: $e');
    }
  }

  Future<void> _startVaultAmbiance() async {
    if (!_mediaUnlocked) return;
    try {
      if (!_mediaPrepared) {
        await _prepareVaultAudio();
      }
      await _vaultAmbience.setLoopMode(LoopMode.one);
      await _vaultAmbience.setAsset('assets/audio/vault/vault_ambiance.mp3');
      await _vaultAmbience.play();
    } catch (e) {
      debugPrint('Vault ambiance missing: $e');
    }
  }

  Future<void> _prepareVaultAudio() async {
    if (_mediaPrepared) return;
    try {
      await _vaultSfx.setAsset('assets/audio/vault/vault_open.mp3');
      await _vaultAmbience.setAsset('assets/audio/vault/vault_ambiance.mp3');
      _mediaPrepared = true;
    } catch (e) {
      debugPrint('Vault audio preload failed: $e');
    }
  }

  Future<void> _startVaultMedia() async {
    final controller = _controller;
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isPlaying) {
      await controller.play();
    }
    await _startVaultAmbiance();
    await _playVaultOpen();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        _onOrientationChange(orientation);
        final isPortrait = orientation == Orientation.portrait;
        if (isPortrait) {
          _resetDive();
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOutCubic,
          child: isPortrait
              ? _buildRotationPrompt()
              : _build5SecondDive(context),
        );
      },
    );
  }

  void _startDiveTimer() {
    if (_diveTimer != null || _showDive) return;
    _diveSeconds = 5;
    _diveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_diveSeconds <= 1) {
        timer.cancel();
        _diveTimer = null;
        setState(() {
          _showDive = true;
          _mediaUnlocked = true;
        });
        _beginVaultDoorVideoPlayback();
        return;
      }
      setState(() => _diveSeconds -= 1);
    });
  }

  /// Full-screen vault door MP4: seek to start, play, open SFX + ambience when countdown ends.
  Future<void> _beginVaultDoorVideoPlayback() async {
    if (!mounted) return;
    var c = _controller;
    if (c == null || !c.value.isInitialized) {
      await _initializeVideo();
      c = _controller;
    }
    if (!mounted || c == null || !c.value.isInitialized) return;
    try {
      await c.setLooping(false);
      await c.seekTo(Duration.zero);
      await c.setVolume(1.0);
      await c.play();
    } catch (e) {
      debugPrint('Vault door video play failed: $e');
    }
    if (!mounted) return;
    if (!_mediaPrepared) {
      await _prepareVaultAudio();
    }
    await _playVaultOpen();
    await _startVaultAmbiance();
  }

  void _resetDive() {
    _diveTimer?.cancel();
    _diveTimer = null;
    _scriptBoxTimer?.cancel();
    _scriptBoxTimer = null;
    _diveSeconds = 5;
    _showDive = false;
    _showScriptBox = false;
    _hasShownScriptBox = false;
    _isDrifting = false;
  }

  void _scheduleScriptBoxReveal(Duration delay) {
    if (_hasShownScriptBox) return;
    _scriptBoxTimer?.cancel();
    _scriptBoxTimer = Timer(delay, () {
      if (!mounted) return;
      _scriptBoxTimer = null;
      setState(() {
        _showScriptBox = true;
        _hasShownScriptBox = true;
        _isDrifting = false;
      });
      _startVaultSession();
    });
  }

  Widget _build5SecondDive(BuildContext context) {
    _startDiveTimer();
    if (_showDive) {
      return _buildVaultVideoStack(context);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DIVE IN',
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$_diveSeconds',
              style: const TextStyle(
                color: Color(0xFF738678),
                fontSize: 72,
                fontWeight: FontWeight.w200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultVideoStack(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: _buildVaultVideoFullScreen(),
                ),
                if (_vaultArchive != null)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                          child: VaultTimerView(
                            key: ValueKey<String>(
                              _vaultArchive!.lockedAt.toIso8601String(),
                            ),
                            entry: _vaultArchive!,
                            onShrug: _handleVaultShrug,
                            onStillHeavy: _handleStillHeavy,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_showScriptBox)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.92),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                          child: SingleChildScrollView(
                            child: VaultIntakePanel(
                              controller: _worryController,
                              onSeal: _sealTheVault,
                              enabled: !_isDrifting && !_isLocked,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: _buildVoidButton(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Full-screen cover; avoids 0×0 [VideoPlayerValue.size] on Android before the first decoded frame.
  Widget _vaultVideoPlayerCover(VideoPlayerController controller) {
    final sz = controller.value.size;
    double cw = sz.width;
    double ch = sz.height;
    if (cw <= 0 || ch <= 0) {
      final ar = controller.value.aspectRatio;
      if (ar > 0 && ar.isFinite) {
        ch = 1080;
        cw = ar * ch;
      } else {
        cw = 1920;
        ch = 1080;
      }
    }
    return FittedBox(
      fit: BoxFit.cover,
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: cw,
        height: ch,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildVaultVideoFullScreen() {
    if (_videoError != null) {
      return Container(color: Colors.black);
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }
    return _vaultVideoPlayerCover(controller);
  }

  Widget _buildRotationPrompt() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.screen_rotation,
              color: Color(0xFF738678),
              size: 50,
            ),
            const SizedBox(height: 20),
            Text(
              'ROTATE FOR VAULT',
              style: TextStyle(
                color: const Color(0xFF738678).withOpacity(0.8),
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoidButton() {
    return SizedBox(
      width: 200,
      child: OutlinedButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.pushNamed(context, '/wormhole');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SECURE FOUNDATION',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your foundation is stored locally and encrypted. '
              'You are the only person with access to this perimeter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultVideoCircle() {
    if (_videoError != null) {
      return _buildVaultVideoPlaceholderCircle(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Video error: $_videoError',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return _buildVaultVideoPlaceholderCircle();
    }

    return SizedBox(
      height: 280,
      width: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(150),
        child: _vaultVideoPlayerCover(_controller!),
      ),
    );
  }

  Widget _buildVaultVideoPlaceholderCircle({Widget? child}) {
    return SizedBox(
      height: 280,
      width: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(150),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF001A33),
                Color(0xFF0D47A1),
                Color(0xFF0A0A0A),
              ],
            ),
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPlaceholderGradient(),
        if (_videoError == null &&
            _controller != null &&
            _controller!.value.isInitialized)
          _vaultVideoPlayerCover(_controller!),
        if (_videoError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Video error: $_videoError',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF001A33),
            const Color(0xFF0D47A1),
            const Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            center: const Alignment(0.2, -0.3),
            colors: [
              Colors.blueGrey.withOpacity(0.25),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVaultShrug() async {
    HapticFeedback.mediumImpact();
    await _playSystemSuccess();
    await _clearVaultState();
    if (!mounted) return;
    setState(() {
      _vaultReady = false;
      _vaultArchive = null;
    });
  }

  Future<void> _handleStillHeavy() async {
    if (!mounted || _vaultArchive == null) return;
    final text = _vaultArchive!.originalText;
    final chosen = await showDialog<Duration>(
      context: context,
      builder: (ctx) => const _ReLockDurationDialog(),
    );
    if (!mounted || chosen == null) return;
    HapticFeedback.mediumImpact();
    await _startLockoutTimer(
      originalText: text,
      selectedDuration: chosen,
    );
    _lockVault();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _reVaultArchive() async {
    final archive = _vaultArchive;
    final text = archive?.originalText ?? '';
    final duration = archive?.duration ?? VaultEntry.defaultLockDuration;
    await _startLockoutTimer(
      originalText: text,
      selectedDuration: duration,
    );
    if (!mounted) return;
    setState(() {
      _vaultReady = false;
      _vaultArchive = null;
      _isLocked = true;
    });
    _lockVault();
  }

  Future<void> _playSystemSuccess() async {
    try {
      await _systemVoice.setAsset(
        'assets/audio/affirmations/system/log_success.mp3',
      );
      await _systemVoice.play();
    } catch (_) {}
  }

  Future<void> _clearVaultState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vault_lockout_until');
    await _vaultService.clearVault();
    _lockoutTimer?.cancel();
    _lockoutEndsAt = null;
    _isLocked = false;
    _vaultReady = false;
    _vaultArchive = null;
  }

  Future<void> _showEmergencyAccessDialog() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('INTAKE ACTIVE. EMERGENCY ACCESS DISABLED.'),
      ),
    );
  }

  void _startFrostAnimation() {
    _frostFrameTimer?.cancel();
    _frostFrameIndex = 0;
    _frostController.stop();
    _frostController.reset();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _frostController.forward();
      _frostFrameTimer =
          Timer.periodic(const Duration(milliseconds: 180), (t) {
        if (!mounted) return;
        if (_frostFrameIndex < _frostFrames.length - 1) {
          setState(() => _frostFrameIndex += 1);
        } else {
          t.cancel();
        }
      });
    });
  }

  Widget _buildFrostOverlay() {
    if (!_isLocked) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _frostController,
      child: Image.asset(
        _frostFrames[_frostFrameIndex],
        fit: BoxFit.cover,
      ),
    );
  }

  String _formatRemaining() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _checkLockStatus() async {
    final vaultState = await _vaultService.loadEntry();
    if (vaultState != null) {
      setState(() {
        _isLocked = true;
        _lockoutEndsAt = vaultState.unlockTime;
        _vaultArchive = vaultState;
        _vaultReady = vaultState.isReadyForReflection;
      });
      if (!vaultState.isReadyForReflection) {
        _startLockoutTicker();
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lockoutEndsAt = prefs.getString('vault_lockout_until');
    if (lockoutEndsAt == null) {
      return;
    }
    final lockoutTime = DateTime.tryParse(lockoutEndsAt);
    if (lockoutTime == null) {
      return;
    }
    if (DateTime.now().isBefore(lockoutTime)) {
      setState(() {
        _isLocked = true;
        _lockoutEndsAt = lockoutTime;
      });
      _startLockoutTicker();
    }
  }

  Future<void> _startLockoutTimer({
    required String originalText,
    required Duration selectedDuration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lockedAt = DateTime.now();
    final endsAt = lockedAt.add(selectedDuration);
    await prefs.setString('vault_lockout_until', endsAt.toIso8601String());
    final entry = VaultEntry(
      originalText: originalText,
      lockedAt: lockedAt,
      duration: selectedDuration,
    );
    await _vaultService.saveEntry(entry);
    setState(() {
      _lockoutEndsAt = endsAt;
      _vaultArchive = entry;
      _isLocked = true;
      _vaultReady = false;
    });
    _startLockoutTicker();
  }

  void _startLockoutTicker() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final endsAt = _lockoutEndsAt;
      if (endsAt == null) {
        timer.cancel();
        return;
      }
      if (DateTime.now().isAfter(endsAt)) {
        timer.cancel();
        setState(() {
          _vaultReady = true;
        });
      } else {
        setState(() {});
      }
    });
  }

}

/// Dialog to choose how long to re-lock the same worry (4h, 8h "next morning", 24h).
class _ReLockDurationDialog extends StatelessWidget {
  const _ReLockDurationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1D21),
      title: const Text(
        'Re-lock for',
        style: TextStyle(color: Colors.white70),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Lock the same signal again until:',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(context, 4, '4h'),
              const SizedBox(width: 8),
              _chip(context, 8, '8h'),
              const SizedBox(width: 8),
              _chip(context, 24, '24h'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '8h ≈ next morning',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, int hours, String label) {
    final duration = Duration(hours: hours);
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(duration),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.cyan,
        side: const BorderSide(color: Colors.cyan),
      ),
      child: Text(label),
    );
  }
}
