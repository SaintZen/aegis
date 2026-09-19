import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/data/instrument_tour_copy.dart';

/// First-run instrument briefing. Fires once after System Initialization
/// and before the Bridge shell.
///
/// This is a naming pass, not a protocol. It must never trap the operator:
/// [InstrumentTourCopy.skipLabel] is armed from the first frame. Completing
/// or skipping writes [prefsKey] so the briefing does not repeat.
///
/// Four Gates appears here as a named interceptor only. The tour does not
/// open the gates, collect answers, or insert latency in front of GATE 1.
class InstrumentTourScreen extends StatefulWidget {
  const InstrumentTourScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  static const String prefsKey = 'instrument_tour_completed';

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<InstrumentTourScreen> createState() => _InstrumentTourScreenState();
}

class _InstrumentTourScreenState extends State<InstrumentTourScreen> {
  /// Matches [SonicPharmacyScreen] so the global AEGIS HUD does not
  /// collide with the station title.
  static const double _kAegisHudReserve = 42.0;

  int _index = 0;
  bool _finishing = false;

  int get _stationCount => InstrumentTourCopy.stations.length;

  bool get _isLast => _index >= _stationCount - 1;

  InstrumentTourStation get _station => InstrumentTourCopy.stations[_index];

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await InstrumentTourScreen.markCompleted();
    if (!mounted) return;
    widget.onComplete();
  }

  void _next() {
    if (_isLast) {
      unawaited(_finish());
      return;
    }
    setState(() => _index += 1);
  }

  @override
  Widget build(BuildContext context) {
    final station = _station;
    final stationOrdinal = (_index + 1).toString().padLeft(2, '0');
    final stationTotal = _stationCount.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24 + _kAegisHudReserve, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                InstrumentTourCopy.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                InstrumentTourCopy.preambleLine1,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                InstrumentTourCopy.preambleLine2,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '${InstrumentTourCopy.stationIndexPrefix} $stationOrdinal / $stationTotal',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                station.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                station.body,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _finishing ? null : _finish,
                  child: const Text(InstrumentTourCopy.skipLabel),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishing ? null : _next,
                  child: Text(
                    _isLast
                        ? InstrumentTourCopy.enterLabel
                        : InstrumentTourCopy.nextLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
