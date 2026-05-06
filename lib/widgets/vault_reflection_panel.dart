import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/services/aegis_log_service.dart';

/// 4/8 REFLECTION — Aegis panel: ledger field, COMMIT (writes audit row), DISCARD (local clear).
/// Ledger TYPE written to `aegis_log.json`; included in Technical Audit PDF when committed.
const Color _aegisOrange = Color(0xFFFF8C00);

class VaultReflectionPanel extends StatefulWidget {
  const VaultReflectionPanel({super.key});

  static const String ledgerType = '4/8 REFLECTION';

  @override
  State<VaultReflectionPanel> createState() => _VaultReflectionPanelState();
}

class _VaultReflectionPanelState extends State<VaultReflectionPanel> {
  final TextEditingController _controller = TextEditingController();
  bool _commitInProgress = false;
  bool _commitFadeOut = false;
  bool _confirmationVisible = false;
  double _confirmationOpacity = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _discardDraft() {
    HapticFeedback.lightImpact();
    _controller.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _confirmationVisible = false;
      _confirmationOpacity = 0;
    });
  }

  Future<void> _commit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _commitInProgress) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _commitInProgress = true;
      _commitFadeOut = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await AegisLogService.logLedgerEntry(
      type: VaultReflectionPanel.ledgerType,
      content: text,
    );
    if (!mounted) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _commitFadeOut = false;
      _commitInProgress = false;
    });
    await _flashSaved();
  }

  Future<void> _flashSaved() async {
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
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF001220),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 36,
                color: _aegisOrange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '4/8 REFLECTION',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Technical ledger field · commit writes to audit log · discard clears draft only',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontFamily: 'RobotoMono',
                        fontSize: 9,
                        letterSpacing: 0.2,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              fontSize: 14,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'Reflection text (optional)…',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.28),
                fontFamily: 'RobotoMono',
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.4),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFF2A3A48)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFF2A3A48)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: _commitInProgress ? null : _discardDraft,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  side: const BorderSide(color: Colors.white24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'DISCARD DRAFT',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: hasText && !_commitFadeOut ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: (hasText && !_commitInProgress) ? _commit : null,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: _aegisOrange,
                    disabledForegroundColor: Colors.white38,
                    disabledBackgroundColor: Colors.white10,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'COMMIT ENTRY',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_confirmationVisible) ...[
            const SizedBox(height: 10),
            AnimatedOpacity(
              opacity: _confirmationOpacity,
              duration: const Duration(milliseconds: 220),
              child: Text(
                'ENTRY SAVED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
