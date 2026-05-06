import 'package:flutter/material.dart';

import 'package:anxiety_anchor/services/calibration_service.dart';
import 'package:anxiety_anchor/widgets/emergency_crisis_sheet.dart';

/// Calibration: Haptic intensity, audio, reduced motion, PDF config, safety.
/// When [embedded] is true, only the scroll body is returned (no Scaffold) for
/// use inside [BridgeMaintenanceLedgerScreen].
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  double _hapticIntensity = 1.0;
  int _pulseEntrainmentBpm = 60;
  bool _entrainmentAudio = true;
  bool _reducedMotion = false;
  bool _highVisibility = false;
  bool _sootheMode = false;
  bool _pdfIncludeTimestamps = true;
  bool _pdfAnonymize = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final intensity = await CalibrationService.getHapticIntensity();
    final bpm = await CalibrationService.getPulseEntrainmentBpm();
    final audio = await CalibrationService.getEntrainmentAudio();
    final motion = await CalibrationService.getReducedMotion();
    final highVis = await CalibrationService.getHighVisibility();
    final soothe = await CalibrationService.getSootheMode();
    final timestamps = await CalibrationService.getPdfIncludeTimestamps();
    final anonymize = await CalibrationService.getPdfAnonymize();
    if (mounted) {
      setState(() {
        _hapticIntensity = intensity;
        _pulseEntrainmentBpm = bpm;
        _entrainmentAudio = audio;
        _reducedMotion = motion;
        _highVisibility = highVis;
        _sootheMode = soothe;
        _pdfIncludeTimestamps = timestamps;
        _pdfAnonymize = anonymize;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.white54))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Tactical Feedback'),
                  _buildSliderRow(
                    'Tactical Feedback Intensity',
                    value: _hapticIntensity,
                    onChanged: (v) {
                      setState(() => _hapticIntensity = v);
                      CalibrationService.setHapticIntensity(v);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Rhythm Calibration'),
                  _buildBpmSliderRow(
                    'Pulse Entrainment Frequency',
                    subtitle: '60 BPM (Heart Rate standard)',
                    value: _pulseEntrainmentBpm,
                    min: 50,
                    max: 70,
                    onChanged: (v) {
                      setState(() => _pulseEntrainmentBpm = v.round());
                      CalibrationService.setPulseEntrainmentBpm(v.round());
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Audio'),
                  _buildSwitchRow(
                    'Entrainment Audio',
                    value: _entrainmentAudio,
                    onChanged: (v) {
                      setState(() => _entrainmentAudio = v);
                      CalibrationService.setEntrainmentAudio(v);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Visual Sensitivity'),
                  _buildSwitchRow(
                    'Reduced Motion',
                    subtitle: 'Simplifies breathing animations for dizziness',
                    value: _reducedMotion,
                    onChanged: (v) {
                      setState(() => _reducedMotion = v);
                      CalibrationService.setReducedMotion(v);
                    },
                  ),
                  _buildSwitchRow(
                    'High Visibility / Outdoor',
                    subtitle: 'Solid borders, heavier labels, white text with shadow',
                    value: _highVisibility,
                    onChanged: (v) {
                      setState(() => _highVisibility = v);
                      CalibrationService.setHighVisibility(v);
                    },
                  ),
                  _buildSwitchRow(
                    'Soothe Mode (Monochrome)',
                    subtitle: 'Obsidian, Slate, Silver only—no indigo or blue',
                    value: _sootheMode,
                    onChanged: (v) {
                      setState(() => _sootheMode = v);
                      CalibrationService.setSootheMode(v);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('PDF Configuration'),
                  _buildSwitchRow(
                    'Include Timestamps in Log',
                    value: _pdfIncludeTimestamps,
                    onChanged: (v) {
                      setState(() => _pdfIncludeTimestamps = v);
                      CalibrationService.setPdfIncludeTimestamps(v);
                    },
                  ),
                  _buildSwitchRow(
                    'Anonymize All Data',
                    value: _pdfAnonymize,
                    onChanged: (v) {
                      setState(() => _pdfAnonymize = v);
                      CalibrationService.setPdfAnonymize(v);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Safety'),
                  _buildSafetyResetButton(),
                ],
              ),
            );

    if (widget.embedded) {
      return ColoredBox(
        color: const Color(0xFF0A0A0A),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'Calibration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.amber.shade200,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    String label, {
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFBF00),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFFFFBF00),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmSliderRow(
    String label, {
    String? subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value BPM',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFBF00),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFFFFBF00),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String label, {
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFFBF00),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showOperationalDisclaimer,
        icon: const Icon(Icons.description_outlined, size: 20),
        label: const Text('Re-read Operational Disclaimer'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: Colors.amber,
          side: const BorderSide(color: Colors.amber),
        ),
      ),
    );
  }

  void _showOperationalDisclaimer() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1116),
          title: const Text('Operational Disclaimer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'AnxietyAnchor is a grounding tool for stress management and '
                  'entertainment purposes. It is not a medical device. It does not '
                  'provide diagnosis, treatment, or medical advice. If you are in '
                  'crisis, please contact professional emergency services immediately.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sensory Cautions',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "• The Frost: Use caution with cold exposure if you have "
                  "circulatory or skin sensitivities.\n"
                  "• The Hollow: Use haptic thrums at a comfortable intensity.",
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    EmergencyCrisisSheet.show(context);
                  },
                  icon: const Icon(Icons.emergency, color: Colors.redAccent),
                  label: const Text(
                    'Get Professional Help',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
