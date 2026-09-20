import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/kinetic_voice_engine.dart';

/// SCRAM — Priority 0 blank field.
///
/// Replaces Kill Switch. Not the Void. A 1.25s hold on the Monolith
/// opens a ninety-second blank field so the operator's world can reset.
/// The field is empty. No copy. No skip. Snap, then return to Bridge.
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

  Future<void> _logActivation() async {
    final log = widget.logLedgerEntry ?? AegisLogService.logLedgerEntry;
    await log(
      type: ScramScreen.ledgerType,
      content: 'BLANK FIELD',
    );
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _blankTimer?.cancel();
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    // pop() completes the field. maybePop honors PopScope.canPop,
    // which stays false until a rebuild — the operator cannot skip.
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
      child: const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: SizedBox.expand(),
      ),
    );
  }
}
