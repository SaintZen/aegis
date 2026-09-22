import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/kinetic_voice_engine.dart';

/// SCRAM — Priority 0 blank field.
///
/// Replaces Kill Switch. Not the Void. A 1.25s hold on the Monolith
/// opens a ninety-second blank field so the operator's world can reset.
/// The field is empty. System back does not skip it. EXIT aborts
/// the field if the operator must leave.
class ScramScreen extends StatefulWidget {
  const ScramScreen({
    super.key,
    this.blankDuration = defaultBlankDuration,
    this.logLedgerEntry,
    this.haltVoice,
  });

  /// Midpoint of the 1–2 minute blank field.
  static const Duration defaultBlankDuration = Duration(seconds: 90);

  static const String ledgerType = 'SCRAM';

  static const String exitLabel = 'EXIT';

  final Duration blankDuration;
  final Future<void> Function({
    required String type,
    required String content,
  })? logLedgerEntry;
  final Future<void> Function()? haltVoice;

  @override
  State<ScramScreen> createState() => _ScramScreenState();
}

class _ScramScreenState extends State<ScramScreen> {
  Timer? _blankTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    unawaited((widget.haltVoice ?? KineticVoiceEngine.emergencyStop)());
    unawaited(_logActivation());
    _blankTimer = Timer(widget.blankDuration, _finish);
  }

  Future<void> _log(String content) async {
    final log = widget.logLedgerEntry ?? AegisLogService.logLedgerEntry;
    await log(
      type: ScramScreen.ledgerType,
      content: content,
    );
  }

  Future<void> _logActivation() => _log('BLANK FIELD');

  void _exit() {
    unawaited(_log('EXIT'));
    _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _blankTimer?.cancel();
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    // pop() completes the field. maybePop honors PopScope.canPop,
    // which stays false — system back cannot skip. EXIT calls pop().
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  void dispose() {
    _blankTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _finished,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              key: const Key('scram_exit'),
              onPressed: _exit,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                minimumSize: const Size(72, 44),
              ),
              child: const Text(
                ScramScreen.exitLabel,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
