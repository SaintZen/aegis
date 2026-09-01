import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/data/safety_handshake_copy.dart';
import 'package:anxiety_anchor/widgets/emergency_crisis_sheet.dart';

/// First-time Safety Handshake: plain-English "Not a Doctor" entry gate.
/// Persists acceptance via shared_preferences.
class SafetyGateScreen extends StatefulWidget {
  const SafetyGateScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  /// SharedPreferences key for handshake acceptance.
  /// Kept stable so operators who already passed the gate are not re-prompted.
  static const String prefsKey = 'safety_gate_accepted';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  @override
  State<SafetyGateScreen> createState() => _SafetyGateScreenState();
}

class _SafetyGateScreenState extends State<SafetyGateScreen> {
  static const Color _bg = Color(0xFF000000);
  static const Color _navy = Color(0xFF001220);
  static const Color _gold = Color(0xFFFFBF00);
  static const String _mono = 'RobotoMono';

  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _checkboxChecked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 24;
    if (atBottom != _hasScrolledToBottom && mounted) {
      setState(() => _hasScrolledToBottom = atBottom);
    }
  }

  bool get _canEnter => _hasScrolledToBottom && _checkboxChecked;

  Future<void> _onEnter() async {
    if (!_canEnter) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SafetyGateScreen.prefsKey, true);
    if (mounted) {
      widget.onAccepted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                SafetyHandshakeCopy.title,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: _mono,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                SafetyHandshakeCopy.lineNotADoctor,
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.95),
                  fontFamily: _mono,
                  fontSize: 13,
                  letterSpacing: 0.6,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  color: _navy,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _body(SafetyHandshakeCopy.lineInstrument),
                        const SizedBox(height: 12),
                        _body(SafetyHandshakeCopy.lineNotADoctor),
                        const SizedBox(height: 8),
                        _body(SafetyHandshakeCopy.lineNotADevice),
                        const SizedBox(height: 8),
                        _body(SafetyHandshakeCopy.lineNoAdvice),
                        const SizedBox(height: 8),
                        _body(SafetyHandshakeCopy.lineNoReplacement),
                        const SizedBox(height: 16),
                        _body(SafetyHandshakeCopy.lineCrisis),
                        const SizedBox(height: 16),
                        Text(
                          SafetyHandshakeCopy.lineFullLegal,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontFamily: _mono,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          key: const Key('safety-handshake-crisis-lines'),
                          onPressed: () => EmergencyCrisisSheet.show(context),
                          icon: const Icon(
                            Icons.emergency,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            SafetyHandshakeCopy.crisisLinesLabel,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontFamily: _mono,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          SafetyHandshakeCopy.sensoryHeading,
                          style: TextStyle(
                            color: Colors.amber.shade200,
                            fontFamily: _mono,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBullet(SafetyHandshakeCopy.frostCaution),
                        const SizedBox(height: 8),
                        _buildBullet(SafetyHandshakeCopy.hollowCaution),
                        const SizedBox(height: 32),
                        _buildCheckboxSection(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('safety-handshake-enter'),
                  onPressed: _canEnter ? _onEnter : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _canEnter ? _gold : Colors.white24,
                    foregroundColor: _canEnter ? Colors.black : Colors.white54,
                    disabledBackgroundColor: Colors.white24,
                    disabledForegroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    SafetyHandshakeCopy.enterLabel,
                    style: TextStyle(
                      fontFamily: _mono,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontFamily: _mono,
        fontSize: 14,
        height: 1.55,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            color: Colors.amber.shade200,
            fontFamily: _mono,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontFamily: _mono,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxSection() {
    return GestureDetector(
      onTap: () => setState(() => _checkboxChecked = !_checkboxChecked),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              key: const Key('safety-handshake-checkbox'),
              value: _checkboxChecked,
              onChanged: (v) => setState(() => _checkboxChecked = v ?? false),
              activeColor: _gold,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _gold;
                }
                return Colors.white24;
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                SafetyHandshakeCopy.checkboxLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: _mono,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
