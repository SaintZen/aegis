import 'package:flutter/material.dart';

import 'package:anxiety_anchor/services/clinical_log_service.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({
    super.key,
    this.tool = 'Blackhole',
    this.initialStressLevel = 5,
  });

  final String tool;
  final double initialStressLevel;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  double _currentFeeling = 5;

  double get _delta => widget.initialStressLevel - _currentFeeling;

  Future<void> _saveClinicalEntry() async {
    await ClinicalLogService.saveClinicalEntry(
      tool: widget.tool,
      preValue: widget.initialStressLevel,
      postValue: _currentFeeling,
    );
  }

  Widget _buildReliefSummary() {
    return Column(
      children: [
        if (_delta > 0) ...[
          Text(
            '-${_delta.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Color(0xFF738678),
              fontSize: 80,
              fontWeight: FontWeight.w200,
            ),
          ),
          const Text(
            'PRESSURE RELEASED',
            style: TextStyle(
              color: Colors.white38,
              letterSpacing: 4,
              fontSize: 10,
            ),
          ),
        ] else ...[
          const Text(
            'SYSTEM STABILIZED',
            style: TextStyle(
              color: Color(0xFF738678),
              letterSpacing: 2,
            ),
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.greenAccent,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'RELEASED',
              style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 4),
            ),
            const SizedBox(height: 28),
            Column(
              children: [
                const Text(
                  'HOW IS YOUR SPIRIT NOW?',
                  style: TextStyle(
                    color: Color(0xFF738678),
                    letterSpacing: 2,
                  ),
                ),
                Slider(
                  value: _currentFeeling,
                  min: 1,
                  max: 10,
                  activeColor: const Color(0xFF738678),
                  inactiveColor: Colors.grey,
                  onChanged: (val) => setState(() => _currentFeeling = val),
                ),
                Text(
                  _currentFeeling < 4 ? 'Grounded' : 'Still Heavy',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 20),
                _buildReliefSummary(),
              ],
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                await _saveClinicalEntry();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text(
                'RETURN TO CALM',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
