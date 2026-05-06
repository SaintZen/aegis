import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/widgets/emergency_crisis_sheet.dart';

/// First-time entry gate with operational disclaimer and sensory cautions.
/// Persists acceptance via shared_preferences.
class SafetyGateScreen extends StatefulWidget {
  const SafetyGateScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  static const String _prefsKey = 'safety_gate_accepted';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  @override
  State<SafetyGateScreen> createState() => _SafetyGateScreenState();
}

class _SafetyGateScreenState extends State<SafetyGateScreen> {

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

  Future<void> _onEnterLab() async {
    if (!_canEnter) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SafetyGateScreen._prefsKey, true);
    if (mounted) {
      widget.onAccepted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Operational Disclaimer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AnxietyAnchor is for entertainment and personal grounding '
                        'only. It is not a medical device and not a substitute for '
                        'a doctor or professional care. It does not provide '
                        'diagnosis, treatment, or medical advice. If you are in '
                        'crisis, contact professional or emergency services immediately.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Full legal disclaimer and coverage: see Bridge → Full Disclaimer.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => EmergencyCrisisSheet.show(context),
                        icon: const Icon(Icons.emergency, color: Colors.redAccent),
                        label: const Text(
                          'Get Professional Help',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Sensory Cautions',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBullet(
                        "The Frost: Use caution with cold exposure if you have "
                        "circulatory or skin sensitivities.",
                      ),
                      const SizedBox(height: 8),
                      _buildBullet(
                        "The Hollow: Use haptic thrums at a comfortable intensity.",
                      ),
                      const SizedBox(height: 32),
                      _buildCheckboxSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canEnter ? _onEnterLab : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _canEnter
                        ? const Color(0xFFFFBF00)
                        : Colors.white24,
                    foregroundColor: _canEnter ? Colors.black : Colors.white54,
                  ),
                  child: const Text('Enter Lab'),
                ),
              ),
            ],
          ),
        ),
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
            fontSize: 16,
            height: 1.5,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
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
              value: _checkboxChecked,
              onChanged: (v) => setState(() => _checkboxChecked = v ?? false),
              activeColor: const Color(0xFFFFBF00),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFFFBF00);
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
                'I understand this is a grounding tool, not medical treatment.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
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
