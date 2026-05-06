import 'dart:async';

import 'package:flutter/material.dart';

import 'package:anxiety_anchor/models/vault_model.dart';
import 'package:anxiety_anchor/widgets/vault_reflection_panel.dart';

/// Aegis industrial orange (accent actions only).
const Color _aegisOrange = Color(0xFFFF8C00);

enum _VaultUiPhase {
  earlyReflection,
  sealedCountdown,
  unlockFlash,
  finalReflection,
}

/// Vault timeline: 8h reflection window (discard allowed) → sealed retention →
/// full release → final reflection (discard / re-lock).
/// Audit PDF includes the vault row only after the reflection window ends.
class VaultTimerView extends StatefulWidget {
  const VaultTimerView({
    super.key,
    required this.entry,
    required this.onShrug,
    required this.onStillHeavy,
  });

  final VaultEntry entry;
  final VoidCallback onShrug;
  final VoidCallback onStillHeavy;

  @override
  State<VaultTimerView> createState() => _VaultTimerViewState();
}

class _VaultTimerViewState extends State<VaultTimerView> {
  Timer? _ticker;
  late _VaultUiPhase _phase;

  @override
  void initState() {
    super.initState();
    _bootstrapPhase();
  }

  void _bootstrapPhase() {
    final e = widget.entry;
    if (e.remainingTime <= Duration.zero) {
      _phase = _VaultUiPhase.unlockFlash;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runUnlockFlash();
      });
      return;
    }
    if (e.isInReflectionWindow) {
      _phase = _VaultUiPhase.earlyReflection;
    } else {
      _phase = _VaultUiPhase.sealedCountdown;
    }
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    if (_phase == _VaultUiPhase.unlockFlash ||
        _phase == _VaultUiPhase.finalReflection) {
      return;
    }

    final e = widget.entry;

    if (_phase == _VaultUiPhase.earlyReflection) {
      if (e.remainingTime <= Duration.zero) {
        _ticker?.cancel();
        _runUnlockFlash();
        return;
      }
      if (!e.isInReflectionWindow) {
        setState(() => _phase = _VaultUiPhase.sealedCountdown);
      } else {
        setState(() {});
      }
      return;
    }

    if (_phase == _VaultUiPhase.sealedCountdown) {
      if (e.remainingTime <= Duration.zero) {
        _ticker?.cancel();
        _runUnlockFlash();
        return;
      }
      setState(() {});
    }
  }

  Future<void> _runUnlockFlash() async {
    _ticker?.cancel();
    if (!mounted) return;
    setState(() => _phase = _VaultUiPhase.unlockFlash);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _phase = _VaultUiPhase.finalReflection);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _VaultUiPhase.earlyReflection:
        return _buildEarlyReflection();
      case _VaultUiPhase.sealedCountdown:
        return _buildSealedCountdown();
      case _VaultUiPhase.unlockFlash:
        return _buildUnlockFlashPhase();
      case _VaultUiPhase.finalReflection:
        return _buildFinalReflection();
    }
  }

  Widget _aegisBlackShell({required Widget child}) {
    return ColoredBox(color: Colors.black, child: child);
  }

  String _formatVaultRemaining(Duration r) {
    if (r.isNegative) return '00:00';
    final sec = r.inSeconds;
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildEarlyReflection() {
    final clock = _formatVaultRemaining(widget.entry.reflectionRemainingTime);
    return _aegisBlackShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'REFLECTION WINDOW',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'RobotoMono',
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              clock,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w400,
                fontFamily: 'RobotoMono',
                color: Colors.white,
                letterSpacing: 4,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Until audit retention',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontFamily: 'RobotoMono',
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 20),
            const VaultReflectionPanel(),
            const SizedBox(height: 20),
            Text(
              'Sealed signal',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontFamily: 'RobotoMono',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                widget.entry.originalText,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.5,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Discard removes this signal from audit export. After this window '
              'closes, the record is retained for technical audit PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontFamily: 'RobotoMono',
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: widget.onShrug,
                  style: TextButton.styleFrom(
                    foregroundColor: _aegisOrange,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    'THROW AWAY',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onStillHeavy,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: const Text(
                    'RE-LOCK',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSealedCountdown() {
    final clock = _formatVaultRemaining(widget.entry.remainingTime);
    return _aegisBlackShell(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AUDIT RETAINED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontFamily: 'RobotoMono',
                  fontSize: 12,
                  letterSpacing: 2.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Technical audit PDF may include this vault row.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                clock,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'RobotoMono',
                  color: Colors.white,
                  letterSpacing: 4,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Full release',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockFlashPhase() {
    return ColoredBox(
      color: Colors.black,
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.14),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildFinalReflection() {
    return ColoredBox(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'POST-UNLOCK REFLECTION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontFamily: 'RobotoMono',
                fontSize: 10,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const VaultReflectionPanel(),
            const SizedBox(height: 24),
            Text(
              'Released signal',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontFamily: 'RobotoMono',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                widget.entry.originalText,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.5,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nominal load? Discard. Sustained load? Re-lock.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                fontFamily: 'RobotoMono',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: widget.onShrug,
                  style: TextButton.styleFrom(
                    foregroundColor: _aegisOrange,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    'THROW AWAY',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onStillHeavy,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: const Text(
                    'RE-LOCK',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
