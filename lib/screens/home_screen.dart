import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'package:anxiety_anchor/l10n/app_localizations.dart';

import 'package:anxiety_anchor/audio/atmosphere_mixer.dart';
import 'package:anxiety_anchor/widgets/branded_anchor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _engineThrumAsset =
      'assets/audio/engine/engine_thrum_40hz.mp3';
  static const int _hapticPulseMs = 100;

  final AudioPlayer _enginePlayer = AudioPlayer();
  Timer? _hapticTimer;
  bool _engineReady = false;
  bool _engineActive = false;

  @override
  void initState() {
    super.initState();
    _prepareEngineThrum();
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _enginePlayer.dispose();
    super.dispose();
  }

  Future<void> _prepareEngineThrum() async {
    try {
      await _enginePlayer.setLoopMode(LoopMode.one);
      await _enginePlayer.setAsset(_engineThrumAsset);
      _engineReady = true;
    } catch (e) {
      debugPrint('Engine thrum missing: $e');
      _engineReady = false;
    }
  }

  Future<void> _startEngineThrum() async {
    if (_engineActive || !_engineReady) return;
    _engineActive = true;
    try {
      await _enginePlayer.setVolume(1.0);
      await _enginePlayer.play();
    } catch (e) {
      debugPrint('Engine thrum play failed: $e');
    }
    _startHaptics();
  }

  Future<void> _stopEngineThrum() async {
    if (!_engineActive) return;
    _engineActive = false;
    _stopHaptics();
    try {
      await _enginePlayer.setVolume(0.0);
      await Future.delayed(const Duration(milliseconds: 100));
      await _enginePlayer.pause();
      await _enginePlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Engine thrum stop failed: $e');
    }
  }

  void _startHaptics() {
    _hapticTimer?.cancel();
    _hapticTimer =
        Timer.periodic(const Duration(milliseconds: _hapticPulseMs), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopHaptics() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  static const TextStyle _footerLinkStyle = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 11,
    color: Color(0xFF0D47A1),
    decoration: TextDecoration.underline,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAnchorCore(context, l10n),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/terms-of-use'),
                  child: Text(l10n.terms_of_use_label, style: _footerLinkStyle),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/privacy'),
                  child: Text(l10n.privacy_notice_label, style: _footerLinkStyle),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              'Caution: If you feel dizzy or lightheaded, let go and breathe '
              'normally. Your body is just catching up.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.35),
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorCore(BuildContext context, AppLocalizations l10n) {
    final anchorSize = MediaQuery.of(context).size.width * 0.4;
    return GestureDetector(
      onTap: () => _onAnchorPressed(context),
      onLongPressStart: (_) => _startEngineThrum(),
      onLongPressEnd: (_) => _stopEngineThrum(),
      onLongPressCancel: () => _stopEngineThrum(),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: anchorSize,
              height: anchorSize,
              child: Center(
                child: BrandedAnchor(
                  size: anchorSize,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ANCHOR ME NOW',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                    letterSpacing: 4.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    l10n.anchor_motto_latin,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'RobotoMono',
                      fontSize: 13,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.anchor_motto_translation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'RobotoMono',
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAnchorPressed(BuildContext context) {
    HapticFeedback.heavyImpact();
    AtmosphereMixer().playTrack('wind.mp3', volume: 0.3);
    _navigateToBreathing(context);
  }

  void _navigateToBreathing(BuildContext context) {
    Navigator.pushNamed(context, '/rescue-breathing');
  }

}
