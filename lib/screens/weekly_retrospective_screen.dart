import 'package:flutter/material.dart';

import 'package:anxiety_anchor/services/clinical_log_service.dart';

class WeeklyRetrospectiveScreen extends StatefulWidget {
  const WeeklyRetrospectiveScreen({super.key});

  @override
  State<WeeklyRetrospectiveScreen> createState() =>
      _WeeklyRetrospectiveScreenState();
}

class _WeeklyRetrospectiveScreenState extends State<WeeklyRetrospectiveScreen> {
  String? _selectedWeather;
  int? _sleepQuality;
  int? _socialBattery;
  bool _hasSaved = false;

  void _selectWeather(String label) {
    setState(() => _selectedWeather = label);
    _trySaveWeekly();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'THE WHOLE WEEK',
              style: TextStyle(
                color: Color(0xFF738678),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'How was the weather in your mind?',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _weatherIcon('☀️', 'Bright'),
                _weatherIcon('🌤️', 'Clearing'),
                _weatherIcon('☁️', 'Overcast'),
                _weatherIcon('🌩️', 'Stormy'),
              ],
            ),
            const SizedBox(height: 40),
            _buildVitalsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSection() {
    return Column(
      children: [
        _sectionHeader('SLEEP QUALITY'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _vitalIcon('🌑', 'Restless', 1, _sleepQuality, (value) {
              setState(() => _sleepQuality = value);
              _trySaveWeekly();
            }),
            _vitalIcon('🌓', 'Broken', 2, _sleepQuality, (value) {
              setState(() => _sleepQuality = value);
              _trySaveWeekly();
            }),
            _vitalIcon('🌕', 'Restored', 3, _sleepQuality, (value) {
              setState(() => _sleepQuality = value);
              _trySaveWeekly();
            }),
          ],
        ),
        const SizedBox(height: 30),
        _sectionHeader('PERIMETER LOAD'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _vitalIcon('📵', 'Isolated', 1, _socialBattery, (value) {
              setState(() => _socialBattery = value);
              _trySaveWeekly();
            }),
            _vitalIcon('💬', 'Brief', 2, _socialBattery, (value) {
              setState(() => _socialBattery = value);
              _trySaveWeekly();
            }),
            _vitalIcon('🤝', 'Connected', 3, _socialBattery, (value) {
              setState(() => _socialBattery = value);
              _trySaveWeekly();
            }),
          ],
        ),
      ],
    );
  }

  Future<void> _trySaveWeekly() async {
    final weather = _selectedWeather;
    final sleep = _sleepQuality;
    final social = _socialBattery;
    if (weather == null || sleep == null || social == null || _hasSaved) {
      return;
    }
    _hasSaved = true;
    await ClinicalLogService.saveWeeklyRetrospective(
      weather: weather,
      sleepScore: sleep,
      socialScore: social,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF738678),
          letterSpacing: 3,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _vitalIcon(
    String emoji,
    String label,
    int value,
    int? selected,
    ValueChanged<int> onSelected,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF738678).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF738678) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherIcon(String emoji, String label) {
    final isSelected = _selectedWeather == label;
    return GestureDetector(
      onTap: () => _selectWeather(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF738678).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF738678) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
