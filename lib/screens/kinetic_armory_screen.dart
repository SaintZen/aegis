import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'package:anxiety_anchor/services/kinetic_voice_engine.dart';
import 'package:anxiety_anchor/services/haptics/somatic_controller.dart';
import 'package:anxiety_anchor/services/intel_export_service.dart';

class KineticArmoryScreen extends StatefulWidget {
  const KineticArmoryScreen({super.key});

  @override
  State<KineticArmoryScreen> createState() => _KineticArmoryScreenState();
}

class _KineticArmoryScreenState extends State<KineticArmoryScreen> {
  Timer? _killTimer;
  bool _stealthMode = false;
  List<String> _recommendations = const [];
  SomaticController? _somaticController;

  @override
  void dispose() {
    _killTimer?.cancel();
    _somaticController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStealthMode();
  }

  Future<void> _loadStealthMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isStealth = prefs.getBool('stealth_mode') ?? false;
    final recs = prefs.getStringList('armory_recommendations') ?? <String>[];
    if (mounted) {
      setState(() {
        _stealthMode = isStealth;
        _recommendations = recs;
      });
    }
    _somaticController = SomaticController(muteAudio: isStealth);
  }

  Future<void> _toggleStealthMode() async {
    final prefs = await SharedPreferences.getInstance();
    final updated = !_stealthMode;
    await prefs.setBool('stealth_mode', updated);
    if (mounted) {
      setState(() => _stealthMode = updated);
    }
    _somaticController?.setMuteAudio(updated);
  }

  void _startKillTimer() {
    _killTimer?.cancel();
    _killTimer = Timer(const Duration(seconds: 3), _emergencyStop);
  }

  void _cancelKillTimer() {
    _killTimer?.cancel();
    _killTimer = null;
  }

  Future<void> _emergencyStop() async {
    await KineticVoiceEngine.emergencyStop();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _exportIntel() async {
    final file = await IntelExportService.exportIntel();
    if (!mounted) return;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed.'),
        ),
      );
      return;
    }
    await _somaticController?.playSystemVoice('log_report');
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Tactical Neuro-Stability Log',
    );
    await file.delete();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _TacticalCard(
        title: 'WALL PUSH',
        exerciseType: 'wall_push',
        icon: Icons.back_hand,
        glowColor: const Color(0xFFFFBF00),
        recommended: _recommendations.contains('wall_push'),
      ),
      _TacticalCard(
        title: 'THE SHAKE',
        exerciseType: 'somatic_shaking',
        icon: Icons.vibration,
        glowColor: const Color(0xFFFFFFFF),
        recommended: _recommendations.contains('somatic_shaking'),
      ),
      _TacticalCard(
        title: 'ISOMETRIC',
        exerciseType: 'muscle_clench',
        icon: Icons.fitness_center,
        glowColor: const Color(0xFFD4AF37),
        recommended: _recommendations.contains('muscle_clench'),
      ),
      _TacticalCard(
        title: 'THE PULSE',
        exerciseType: 'pulse',
        icon: Icons.monitor_heart,
        glowColor: const Color(0xFF00FFFF),
        recommended: _recommendations.contains('pulse'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Kinetic Armory'),
        actions: [
          IconButton(
            tooltip: 'Export Intel',
            icon: const Icon(Icons.download, color: Colors.white70),
            onPressed: _exportIntel,
          ),
          IconButton(
            tooltip: _stealthMode ? 'Stealth: On' : 'Stealth: Off',
            icon: Icon(
              _stealthMode ? Icons.vibration : Icons.volume_up,
              color: Colors.white70,
            ),
            onPressed: _toggleStealthMode,
          ),
        ],
      ),
      body: GestureDetector(
        onLongPressStart: (_) => _startKillTimer(),
        onLongPressEnd: (_) => _cancelKillTimer(),
        onLongPressCancel: _cancelKillTimer,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Color(0xFF1B1B1B),
                Color(0xFF121212),
              ],
              radius: 0.85,
              center: Alignment(0.0, -0.1),
            ),
          ),
          child: GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: cards
                .map((card) => _TacticalCardTile(
                      card: card,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/kinetic-action',
                        arguments: card.exerciseType,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TacticalCard {
  const _TacticalCard({
    required this.title,
    required this.exerciseType,
    required this.icon,
    required this.glowColor,
    required this.recommended,
  });

  final String title;
  final String exerciseType;
  final IconData icon;
  final Color glowColor;
  final bool recommended;
}

class _TacticalCardTile extends StatelessWidget {
  const _TacticalCardTile({required this.card, required this.onTap});

  final _TacticalCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glow = card.glowColor;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: glow.withOpacity(card.recommended ? 1.0 : 0.7),
                width: card.recommended ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withOpacity(card.recommended ? 0.6 : 0.35),
                  blurRadius: card.recommended ? 26 : 18,
                  spreadRadius: card.recommended ? 3 : 1,
                ),
                BoxShadow(
                  color: glow.withOpacity(card.recommended ? 0.35 : 0.2),
                  blurRadius: card.recommended ? 46 : 36,
                  spreadRadius: card.recommended ? 6 : 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(card.icon, color: glow, size: 34),
                const Spacer(),
                Text(
                  card.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Tap to launch',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (card.recommended) ...[
                      const SizedBox(width: 6),
                      Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          color: glow.withOpacity(0.9),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
