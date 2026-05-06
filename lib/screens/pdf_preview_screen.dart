import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:anxiety_anchor/services/clinical_log_service.dart';
import 'package:anxiety_anchor/services/journal_export_service.dart';
import 'package:anxiety_anchor/models/journal_entry.dart';

class PDFPreviewScreen extends StatefulWidget {
  const PDFPreviewScreen({super.key, this.entries = const []});

  final List<JournalEntry> entries;

  @override
  State<PDFPreviewScreen> createState() => _PDFPreviewScreenState();
}

class _PDFPreviewScreenState extends State<PDFPreviewScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'REPORT PREVIEW',
          style: TextStyle(letterSpacing: 2, fontSize: 14),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPreviewData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF738678)),
            );
          }

          final data = snapshot.data ?? <String, dynamic>{};
          final weekly =
              data['weekly'] as Map<String, dynamic>? ?? <String, dynamic>{};
          final stats =
              data['stats'] as Map<String, ToolStats>? ?? <String, ToolStats>{};

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader('WEEKLY VITALS'),
              _buildVitalsRow(weekly),
              const SizedBox(height: 30),
              _buildSectionHeader('TOP SENSORY ANCHORS'),
              _buildEfficacyPreview(stats),
              _buildInsightSummary(
                stats,
                weekly['weather'] as String?,
              ),
              const SizedBox(height: 24),
              _buildNotesField(),
              const SizedBox(height: 50),
              _buildExportButton(context),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadPreviewData() async {
    final logs = await ClinicalLogService.getEntries();
    final weekly = await ClinicalLogService.getLatestWeeklySummary();
    final stats = ClinicalLogService.aggregateEfficacy(logs);
    return {
      'weekly': weekly,
      'stats': stats,
    };
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF738678),
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PERSONAL CONTEXT (OPTIONAL)'),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText:
                'E.g., Work was high-stress this week, or started new breathing exercises...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsRow(Map<String, dynamic> weekly) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _vitalPreview('Weather', _getWeatherValue(weekly['weather'])),
          _vitalPreview('Sleep', _getSleepIcon(weekly['sleep'])),
          _vitalPreview('Perimeter', _getSocialIcon(weekly['social'])),
        ],
      ),
    );
  }

  Widget _vitalPreview(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  String _getWeatherValue(dynamic weather) {
    if (weather is! String) return '⚪';
    final emoji = _getWeatherEmoji(weather);
    return '$emoji $weather';
  }

  String _getWeatherEmoji(String? weather) {
    switch (weather) {
      case 'Bright':
        return '☀️';
      case 'Clearing':
        return '🌤️';
      case 'Overcast':
        return '☁️';
      case 'Stormy':
        return '🌩️';
      default:
        return '⚪';
    }
  }

  String _getSleepIcon(dynamic sleep) {
    switch (sleep) {
      case 1:
        return '🌑';
      case 2:
        return '🌓';
      case 3:
        return '🌕';
      default:
        return '⚪';
    }
  }

  String _getSocialIcon(dynamic social) {
    switch (social) {
      case 1:
        return '📵';
      case 2:
        return '💬';
      case 3:
        return '🤝';
      default:
        return '⚪';
    }
  }

  Widget _buildEfficacyPreview(Map<String, ToolStats> stats) {
    if (stats.isEmpty) {
      return const Text(
        'No protocol data yet.',
        style: TextStyle(color: Colors.white54),
      );
    }

    final sortedTools = stats.entries.toList()
      ..sort((a, b) => b.value.avgDelta.compareTo(a.value.avgDelta));
    return Column(
      children: sortedTools.map((entry) {
        final isBest = entry == sortedTools.first;
        final value = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isBest
                ? const Color(0xFF738678).withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: isBest
                ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBest)
                    const Text(
                      '⭐ HIGHEST RELIEF',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Text(
                '-${value.avgDelta.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Color(0xFF738678),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    final canExport = widget.entries.isNotEmpty && !_isGenerating;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canExport ? () => _handleExport(context) : null,
        icon: _isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(_isGenerating ? 'GENERATING...' : 'EXPORT PDF'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF738678),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
        ),
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    setState(() => _isGenerating = true);
    try {
      final file = await JournalExportService.exportToDoctor(
        widget.entries,
        patientNote: _notesController.text,
      );
      if (file == null) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Protocol Report',
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Widget _buildInsightSummary(
    Map<String, ToolStats> stats,
    String? weather,
  ) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }
    final bestTool = stats.entries
        .reduce((a, b) => a.value.avgDelta >= b.value.avgDelta ? a : b)
        .key;
    final weatherLabel = weather ?? 'Unknown';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        "INSIGHT: You found the most relief during '$weatherLabel' weather using the $bestTool anchor. Consider prioritizing this tool during high-load events.",
        style: const TextStyle(
          color: Color(0xFF738678),
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }
}
