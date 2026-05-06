import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/calibration_service.dart';
import 'package:anxiety_anchor/services/usage_log_service.dart';

enum _HollowMode { implicit, triggered, overload, vigilance, unknown }

/// The Hollow — Passive Sonar Array.
/// Expanding indigo ripples, centered text input, no pop-ups.
class HollowScreen extends StatefulWidget {
  const HollowScreen({super.key});

  @override
  State<HollowScreen> createState() => _HollowScreenState();
}

class _HollowScreenState extends State<HollowScreen>
    with TickerProviderStateMixin {
  static const String _hollowLedgerTag = 'Hollow / 7th Sense Input';
  static const Color _indigo = Color(0xFF4B0082);
  static const Color _wellTop = Colors.black;
  static const Color _wellBottom = Color(0xFF001220);

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _centerColumnKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();
  final GlobalKey _overlayStackKey = GlobalKey();

  /// Vertical fraction (0..1, top→bottom) for Unknown stone center; updated after layout.
  double _unknownStoneDy = 0.70;

  late AnimationController _rippleController;
  late AnimationController _glowController;
  final List<_RippleState> _ripples = [];
  static const Duration _rippleDuration = Duration(seconds: 5);
  static const Duration _rippleInterval = Duration(milliseconds: 2500);
  Timer? _rippleTimer;
  Timer? _repaintTimer;
  DateTime? _sessionStart;
  _HollowMode _mode = _HollowMode.unknown;
  bool _modeInitialized = false;
  int? _selectedReasonIndex;
  bool _showHollow = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _confirmationVisible = false;
  double _confirmationOpacity = 0;
  bool _commitActionFadeOut = false;
  bool _commitInProgress = false;
  static const List<_ReasonItem> _reasons = [
    _ReasonItem(
      id: 'implicit',
      label: 'Implicit',
      definition: 'A body-held reaction without a clear memory attached.',
      mode: _HollowMode.implicit,
    ),
    _ReasonItem(
      id: 'triggered',
      label: 'Triggered',
      definition: 'Something in the present echoed an old pattern.',
      mode: _HollowMode.triggered,
    ),
    _ReasonItem(
      id: 'overload',
      label: 'Overload',
      definition: 'Your system reacted faster than your mind could process.',
      mode: _HollowMode.overload,
    ),
    _ReasonItem(
      id: 'vigilance',
      label: 'Vigilance',
      definition: 'Your body was scanning for danger, even if nothing was wrong.',
      mode: _HollowMode.vigilance,
    ),
    _ReasonItem(
      id: 'unknown',
      label: 'Unknown',
      definition: 'Sometimes anxiety appears with no clear cause at all.',
      mode: _HollowMode.unknown,
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _rippleController = AnimationController(
      vsync: this,
      duration: _rippleDuration,
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sessionStart = DateTime.now();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
    _startCountdown();
    _startRippleLoop();
    _repaintTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) setState(() {});
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 5;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _showHollow = true);
        return;
      }
      setState(() => _countdownSeconds -= 1);
    });
  }

  void _startRippleLoop() {
    _addRipple();
    _rippleTimer = Timer.periodic(_rippleInterval, (_) {
      if (mounted) _addRipple();
    });
  }

  void _addRipple() {
    if (!mounted) return;
    if (CalibrationService.hapticIntensitySync > 0) {
      CalibrationService.fireTacticalFeedback(fallback: HapticIntensity.light);
    }
    setState(() {
      _ripples.add(_RippleState(DateTime.now()));
      _triggerGlow();
    });
    // Prune old ripples (keep last ~4)
    while (_ripples.length > 4) {
      _ripples.removeAt(0);
    }
  }

  void _triggerGlow() {
    _glowController.forward(from: 0);
    _glowController.forward().then((_) {
      if (mounted) _glowController.reverse();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _rippleTimer?.cancel();
    _repaintTimer?.cancel();
    _rippleController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _logSession();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _logSession() async {
    if (_sessionStart == null) return;
    final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
    if (elapsed > 0) {
      await UsageLogService.logAnchorUsage(
        flavor: 'The Hollow',
        durationSeconds: elapsed,
      );
    }
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      await AegisLogService.logLedgerEntry(
        type: _hollowLedgerTag,
        content: text,
      );
    }
  }

  Future<void> _commitEntry() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _commitInProgress) return;
    setState(() {
      _commitInProgress = true;
      _commitActionFadeOut = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await AegisLogService.logLedgerEntry(
      type: _hollowLedgerTag,
      content: text,
    );
    if (!mounted) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _commitActionFadeOut = false;
      _commitInProgress = false;
    });
    await _flashEntryCommitted();
  }

  /// Ephemeral confirmation — 1.5s total, no modal, no haptics.
  Future<void> _flashEntryCommitted() async {
    if (!mounted) return;
    setState(() {
      _confirmationVisible = true;
      _confirmationOpacity = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _confirmationOpacity = 1);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _confirmationOpacity = 0);
    await Future<void>.delayed(const Duration(milliseconds: 680));
    if (!mounted) return;
    setState(() => _confirmationVisible = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_modeInitialized) return;
    _modeInitialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _mode = _modeFromString(args);
    } else {
      _mode = _HollowMode.unknown;
    }
  }

  _HollowMode _modeFromString(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'implicit':
        return _HollowMode.implicit;
      case 'triggered':
        return _HollowMode.triggered;
      case 'overload':
        return _HollowMode.overload;
      case 'vigilance':
        return _HollowMode.vigilance;
      default:
        return _HollowMode.unknown;
    }
  }

  String _movementDefinition() {
    switch (_mode) {
      case _HollowMode.implicit:
        return 'Slow, deep expansion/contraction';
      case _HollowMode.triggered:
        return 'Double-thump haptic pulse';
      case _HollowMode.overload:
        return 'Fast pulses that visibly slow down';
      case _HollowMode.vigilance:
        return 'A solid, unwavering glow';
      case _HollowMode.unknown:
        return 'Fading in and out like a mist';
    }
  }

  String _groundingTruth() {
    switch (_mode) {
      case _HollowMode.implicit:
        return 'A body-held reaction without a clear memory attached.';
      case _HollowMode.triggered:
        return 'Something in the present echoed an old pattern.';
      case _HollowMode.overload:
        return 'Your system reacted faster than your mind could process.';
      case _HollowMode.vigilance:
        return 'Your body was scanning for danger, even if nothing was wrong.';
      case _HollowMode.unknown:
        return 'Sometimes anxiety appears with no clear cause at all.';
    }
  }

  double _ringScale(double seconds) {
    switch (_mode) {
      case _HollowMode.implicit:
        // Slow, deep pulses.
        return 1.0 + (math.sin(seconds * math.pi * 2 / 5.2) * 0.05);
      case _HollowMode.triggered:
        // Double-pulse (heartbeat-like).
        final cycle = seconds % 1.25;
        var bump = 0.0;
        if (cycle < 0.12) {
          bump = math.sin((cycle / 0.12) * math.pi) * 0.06;
        } else if (cycle > 0.22 && cycle < 0.34) {
          bump = math.sin(((cycle - 0.22) / 0.12) * math.pi) * 0.045;
        }
        return 1.0 + bump;
      case _HollowMode.overload:
        // Rapid pulse that gradually slows down.
        final freq = math.max(0.8, 2.8 - (seconds * 0.1));
        return 1.0 + (math.sin(seconds * math.pi * 2 * freq) * 0.045);
      case _HollowMode.vigilance:
        // Steady, unmoving glow.
        return 1.0;
      case _HollowMode.unknown:
        // Soft, fading and reappearing pulse.
        return 1.0 + (math.sin(seconds * math.pi * 2 / 6.2) * 0.025);
    }
  }

  double _ringGlow(double seconds) {
    switch (_mode) {
      case _HollowMode.vigilance:
        return 0.28;
      case _HollowMode.unknown:
        return 0.16 + ((math.sin(seconds * math.pi * 2 / 6.2) + 1) * 0.06);
      default:
        return 0.22;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showHollow) {
      return Scaffold(
        backgroundColor: _wellTop,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ENTER THE WELL',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 4,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$_countdownSeconds',
                style: TextStyle(
                  color: _indigo.withOpacity(0.9),
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Turn device sideways',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _wellTop,
      body: PopScope(
        canPop: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Philosophy line (above header)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 24,
              right: 24,
              child: Text(
                'The Body Remembers. The Mind is Blind.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            // Sub-surface "Well" depth gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_wellTop, _wellBottom],
                ),
              ),
            ),
            // Well image with stones (words go on each stone)
            Positioned.fill(
              child: Image.asset(
                'assets/images/hollow/hollow_well.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Expanding indigo ripples
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RipplePainter(
                    ripples: _ripples,
                    indigo: _indigo,
                    intervalMs: _rippleInterval.inMilliseconds,
                    durationMs: _rippleDuration.inMilliseconds,
                  ),
                );
              },
            ),
            // Center breathing ring: primary visual focus.
            Center(
              child: AnimatedBuilder(
                animation: _rippleController,
                builder: (context, _) {
                  final seconds = _sessionStart == null
                      ? 0.0
                      : DateTime.now().difference(_sessionStart!).inMilliseconds /
                          1000.0;
                  final pulse = _ringScale(seconds);
                  final ringGlow = _ringGlow(seconds);
                  return Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _indigo.withOpacity(ringGlow),
                            blurRadius: 26,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 7th Sense input block: header, field, commit, confirmation
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, _) {
                      final glow = 0.4 + (_glowController.value * 0.5);
                      return Column(
                        key: _centerColumnKey,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'THE HOLLOW',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'RobotoMono',
                              fontSize: 14,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '7th Sense Input',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontFamily: 'RobotoMono',
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '7TH SENSE SIGNAL',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontFamily: 'RobotoMono',
                              fontSize: 9,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              TextField(
                                key: _inputFieldKey,
                                controller: _textController,
                                focusNode: _focusNode,
                                maxLines: 5,
                                minLines: 3,
                                keyboardType: TextInputType.multiline,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(glow),
                                  fontSize: 15,
                                  height: 1.45,
                                  letterSpacing: 0.3,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'RobotoMono',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Describe what you feel',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.28),
                                    fontSize: 14,
                                    fontFamily: 'RobotoMono',
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.35),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide:
                                        BorderSide(color: Color(0xFF2A2A2A)),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide:
                                        BorderSide(color: Color(0xFF2A2A2A)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                      color: _indigo.withOpacity(0.65),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    40,
                                  ),
                                  counterText: '',
                                ),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 5,
                                child: Builder(
                                  builder: (context) {
                                    final hasText =
                                        _textController.text.trim().isNotEmpty;
                                    // Hidden when empty; fades in on input; fades out on commit.
                                    final opacity = !hasText
                                        ? 0.0
                                        : (_commitActionFadeOut ? 0.0 : 1.0);
                                    return AnimatedOpacity(
                                      opacity: opacity,
                                      duration:
                                          const Duration(milliseconds: 280),
                                      child: IgnorePointer(
                                        ignoring: _commitInProgress ||
                                            !hasText,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: _commitEntry,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            widthFactor: 1,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 6,
                                              ),
                                              child: Text(
                                                'COMMIT ENTRY',
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontFamily: 'RobotoMono',
                                                  fontSize: 9,
                                                  letterSpacing: 0.7,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white
                                                      .withOpacity(0.34),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_confirmationVisible) ...[
                            const SizedBox(height: 8),
                            AnimatedOpacity(
                              opacity: _confirmationOpacity,
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                'ENTRY COMMITTED',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontFamily: 'RobotoMono',
                                  fontSize: 8,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Stones above the field so labels receive taps; clear of center signal column.
            _buildReasonWellOverlay(),
          ],
        ),
      ),
    );
  }

  /// Stone positions as fraction of width (dx) and height (dy). Index 4 (Unknown) uses [_unknownStoneDy].
  Offset _stoneFraction(int index) {
    switch (index) {
      case 0:
        return const Offset(0.5, 0.22);
      case 1:
        return const Offset(0.88, 0.30);
      case 2:
        return const Offset(0.14, 0.50);
      case 3:
        // Vigilance: same edge as Triggered (right), away from center signal / chat column.
        return const Offset(0.88, 0.74);
      case 4:
        return Offset(0.14, _unknownStoneDy);
      default:
        return const Offset(0.5, 0.5);
    }
  }

  /// Places Unknown below the 7th Sense field (or whole column) using layout, then stack-local dy.
  void _recomputeUnknownStoneY(double stackHeight) {
    if (stackHeight <= 0) return;
    final stackCtx = _overlayStackKey.currentContext;
    final stackBox = stackCtx?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;

    final stackTop = stackBox.localToGlobal(Offset.zero).dy;
    final screenHeight = MediaQuery.sizeOf(stackCtx!).height;
    const margin = 24.0;
    const halfStone = 60.0;

    double safeYNorm;
    final inputBox =
        _inputFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (inputBox != null && inputBox.hasSize) {
      final inputBottom =
          inputBox.localToGlobal(Offset.zero).dy + inputBox.size.height;
      safeYNorm = ((inputBottom + margin) / screenHeight).clamp(0.05, 0.95);
    } else {
      final columnBox =
          _centerColumnKey.currentContext?.findRenderObject() as RenderBox?;
      if (columnBox != null && columnBox.hasSize) {
        final columnBottom =
            columnBox.localToGlobal(Offset.zero).dy + columnBox.size.height;
        safeYNorm = ((columnBottom + margin) / screenHeight).clamp(0.05, 0.95);
      } else {
        safeYNorm = 0.70;
      }
    }

    // Stone center global Y: line below input/column + half item (matches _positionOnStone 120×120).
    final centerYGlobal = safeYNorm * screenHeight + halfStone;
    final yCenterLocal = centerYGlobal - stackTop;
    final dy = (yCenterLocal / stackHeight).clamp(0.12, 0.90);

    if ((dy - _unknownStoneDy).abs() > 0.008) {
      setState(() => _unknownStoneDy = dy);
    }
  }

  Widget _buildReasonWellOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _recomputeUnknownStoneY(h);
          });

          final w = constraints.maxWidth;
          final noneSelected = _selectedReasonIndex == null;

          return Stack(
            key: _overlayStackKey,
            children: [
              for (var i = 0; i < _reasons.length; i++) ...[
                _positionOnStone(
                  width: w,
                  height: h,
                  fraction: _stoneFraction(i),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedReasonIndex = i;
                        _mode = _reasons[i].mode;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 350),
                      opacity: (_selectedReasonIndex == i)
                          ? 1.0
                          : (noneSelected ? 0.85 : 0.35),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 350),
                        scale: (_selectedReasonIndex == i)
                            ? 1.08
                            : (noneSelected ? 1.0 : 0.9),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_selectedReasonIndex == i)
                              AnimatedBuilder(
                                animation: _rippleController,
                                builder: (context, _) {
                                  final seconds = _sessionStart == null
                                      ? 0.0
                                      : DateTime.now()
                                              .difference(_sessionStart!)
                                              .inMilliseconds /
                                          1000.0;
                                  return Transform.scale(
                                    scale: _ringScale(seconds),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.purpleAccent
                                              .withOpacity(0.7),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.purpleAccent
                                                .withOpacity(0.4),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Text(
                              _reasons[i].label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: (_selectedReasonIndex == i)
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (_selectedReasonIndex != null) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedReasonIndex = null;
                          _mode = _HollowMode.unknown;
                        });
                      },
                      child: Text(
                        'Reset the Well',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 10,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 52,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Padding(
                        key: ValueKey('def_$_selectedReasonIndex'),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _reasons[_selectedReasonIndex!].definition,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Places [child] so its center is at (fraction.dx * width, fraction.dy * height) — on a stone.
  Widget _positionOnStone({
    required double width,
    required double height,
    required Offset fraction,
    required Widget child,
  }) {
    const itemWidth = 120.0;
    const itemHeight = 120.0;
    final x = width * fraction.dx - itemWidth / 2;
    final y = height * fraction.dy - itemHeight / 2;
    return Positioned(
      left: x.clamp(0.0, width - itemWidth),
      top: y.clamp(0.0, height - itemHeight),
      width: itemWidth,
      height: itemHeight,
      child: Center(child: child),
    );
  }
}

class _ReasonItem {
  const _ReasonItem({
    required this.id,
    required this.label,
    required this.definition,
    required this.mode,
  });

  final String id;
  final String label;
  final String definition;
  final _HollowMode mode;
}

class _RippleState {
  _RippleState(this.startedAt);
  final DateTime startedAt;
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.ripples,
    required this.indigo,
    required this.intervalMs,
    required this.durationMs,
  });

  final List<_RippleState> ripples;
  final Color indigo;
  final int intervalMs;
  final int durationMs;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.8;

    for (final r in ripples) {
      final elapsed = DateTime.now().difference(r.startedAt).inMilliseconds;
      final progress = (elapsed / durationMs).clamp(0.0, 1.0);
      final radius = progress * maxRadius;
      final opacity = (1.0 - progress) * 0.6;
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = indigo.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}
