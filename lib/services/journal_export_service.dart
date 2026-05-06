import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:anxiety_anchor/models/advocacy_log_entry.dart';
import 'package:anxiety_anchor/models/journal_entry.dart';
import 'package:anxiety_anchor/services/advocacy_log_service.dart';
import 'package:anxiety_anchor/services/calibration_service.dart';
import 'package:anxiety_anchor/services/clinical_log_service.dart';

class JournalExportService {
  static Future<File?> exportToDoctor(
    List<JournalEntry> entries, {
    bool showPrintPreview = false,
    String? patientNote,
  }) async {
    if (entries.isEmpty) {
      return null;
    }

    final pdfBytes = await _buildPdfBytes(entries, patientNote: patientNote);
    final directory = await getTemporaryDirectory();
    final fileName =
        'Xanadu_Summary_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);

    if (showPrintPreview) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: fileName,
      );
    }

    return file;
  }

  static Future<Uint8List> _buildPdfBytes(
    List<JournalEntry> entries, {
    String? patientNote,
  }) async {
    final includeTimestamps = await CalibrationService.getPdfIncludeTimestamps();
    final anonymize = await CalibrationService.getPdfAnonymize();
    final trendValues = _buildTrendValues(entries);
    final insights = _buildInsightsText(trendValues);
    final chartBytes = await _renderChartImage(trendValues);
    final averageWeekMood = _averageFromValues(trendValues);
    final symptomaticFrequency = anonymize
        ? '—'
        : _buildSymptomaticFrequency(entries);
    final currentProtocol = _buildCurrentProtocol(entries);
    final clinicalEntries = await ClinicalLogService.getEntries();
    final weeklySummary = await ClinicalLogService.getLatestWeeklySummary();
    final efficacyStats = ClinicalLogService.aggregateEfficacy(clinicalEntries);
    final advocacyEntries = AdvocacyLogService.getTemplates();
    const commissionerUrl =
        'https://content.naic.org/state-insurance-departments';
    const sovereigntyDisclaimer =
        'Note: Insurance laws vary by state. Consult your State Insurance '
        'Commissioner for local statutory requirements.';
    final doc = pw.Document();
    final logoBytes = await rootBundle.load('assets/images/app_symbol.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final dateFormatter = DateFormat('MMM dd, yyyy - hh:mm a');

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(32),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            sovereigntyDisclaimer,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 48,
                height: 48,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFF5252),
                  shape: pw.BoxShape.circle,
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Image(logo),
              ),
              pw.SizedBox(width: 16),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ANCHOR ME NOW',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.Text(
                    'Technical Report',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  if (includeTimestamps && !anonymize)
                    pw.Text(
                      'Generated on: ${dateFormatter.format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  pw.SizedBox(height: 6),
                  _buildBaselineBar(averageWeekMood),
          pw.SizedBox(height: 16),
          _buildWeeklySnapshot(weeklySummary),
          if (patientNote != null && patientNote.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildObservationBlock(patientNote),
          ],
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(4),
            },
            children: [
              _buildMetaRow('Symptomatic Frequency', symptomaticFrequency),
              _buildMetaRow('Current Protocol', currentProtocol),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Technical Insights',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            insights,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.Image(
            pw.MemoryImage(chartBytes),
            height: 160,
            fit: pw.BoxFit.contain,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Tool Efficacy',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildHeaderCell('Tool'),
                  _buildHeaderCell('Usage Count'),
                  _buildHeaderCell('Avg. Pre-Stress'),
                  _buildHeaderCell('Avg. Post-Stress'),
                  _buildHeaderCell('Delta'),
                ],
              ),
              ..._buildEfficacyRows(efficacyStats),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(4),
            },
            headers: includeTimestamps
                ? const ['Date', 'Mood', 'Entry']
                : const ['Session', 'Mood', 'Entry'],
            data: entries
                .asMap()
                .entries
                .map(
                  (e) => [
                    includeTimestamps
                        ? (anonymize ? '—' : dateFormatter.format(e.value.timestamp))
                        : '${e.key + 1}',
                    anonymize ? '—' : e.value.mood.toString(),
                    anonymize ? '[redacted]' : e.value.note,
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 20),
          _buildAdvocacyLogSection(advocacyEntries),
          pw.SizedBox(height: 12),
          _buildResourcesSection(commissionerUrl),
        ],
      ),
    );

    return doc.save();
  }

  static List<double> _buildTrendValues(List<JournalEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recent = sorted.length > 7
        ? sorted.sublist(sorted.length - 7)
        : sorted;
    return recent.map((entry) => entry.distressLevel.toDouble()).toList();
  }

  static pw.TableRow _buildMetaRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: PdfColors.grey200,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  static pw.Widget _buildBodyCell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        value,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static String _buildSymptomaticFrequency(List<JournalEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final count = entries.where((entry) => entry.timestamp.isAfter(cutoff)).length;
    return '$count entries / 7 days';
  }

  static String _buildCurrentProtocol(List<JournalEntry> entries) {
    return entries.isEmpty ? 'Not reported' : 'Not reported';
  }

  static String _buildInsightsText(List<double> values) {
    final average =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
    final trend = values.length < 2
        ? 'Stable'
        : (values.last > values.first ? 'Rising' : 'Declining');
    final peak = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    return 'Weekly trend: $trend | Avg intensity: ${average.toStringAsFixed(1)} | Peak: ${peak.toStringAsFixed(1)}\n'
        'Objective Evidence: This chart shows that anxiety passes over time. '
        'Insights can surface patterns you might miss while overwhelmed, and the PDF helps show active participation in recovery.';
  }

  static double _averageFromValues(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  static pw.Widget _buildBaselineBar(double averageMood) {
    const barWidth = 120.0;
    const barHeight = 8.0;
    const markerWidth = 2.0;
    const markerHeight = 14.0;
    const labelWidth = 64.0;
    final normalized = (averageMood / 10).clamp(0.0, 1.0);
    final markerLeft = (barWidth * normalized) - (markerWidth / 2);
    final labelLeft = (barWidth * normalized) - (labelWidth / 2);
    final labelText = 'Baseline: ${averageMood.toStringAsFixed(1)}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Weekly Baseline',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Stack(
          children: [
            pw.Container(
              width: barWidth,
              height: barHeight,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(4),
                gradient: const pw.LinearGradient(
                  colors: [
                    PdfColor.fromInt(0xFFFFC107),
                    PdfColor.fromInt(0xFF26A69A),
                  ],
                ),
              ),
            ),
            pw.Positioned(
              left: labelLeft,
              top: -16,
              child: pw.Container(
                width: labelWidth,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  labelText,
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ),
            pw.Positioned(
              left: markerLeft,
              top: -(markerHeight - barHeight) / 2,
              child: pw.Container(
                width: markerWidth,
                height: markerHeight,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey900,
                  borderRadius: pw.BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildWeeklySnapshot(Map<String, dynamic> summary) {
    final weather = summary['weather'] as String?;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSnapshotCard(
          'Mind Weather',
          weather == null ? 'N/A' : '${_getWeatherEmoji(weather)} $weather',
        ),
        _buildSnapshotCard('Sleep Quality', _mapSleep(summary['sleep'])),
        _buildSnapshotCard('Social Battery', _mapSocial(summary['social'])),
      ],
    );
  }

  static pw.Widget _buildAdvocacyLogSection(
    List<AdvocacyLogEntry> entries,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Advocacy Log',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        if (entries.isEmpty)
          pw.Text(
            'No advocacy templates documented yet.',
            style: const pw.TextStyle(fontSize: 9),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(4),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildHeaderCell('Template'),
                  _buildHeaderCell('Purpose'),
                  _buildHeaderCell('Summary'),
                ],
              ),
              ...entries.map(
                (entry) => pw.TableRow(
                  children: [
                    _buildBodyCell(entry.title),
                    _buildBodyCell(entry.purpose),
                    _buildBodyCell(entry.summary),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildResourcesSection(String commissionerUrl) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resources',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.UrlLink(
          destination: commissionerUrl,
          child: pw.Text(
            'Find My State Commissioner (NAIC)',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blue700,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  static List<pw.TableRow> _buildEfficacyRows(
    Map<String, ToolStats> stats,
  ) {
    if (stats.isEmpty) {
      return [
        pw.TableRow(
          children: [
            _buildBodyCell('No data'),
            _buildBodyCell('-'),
            _buildBodyCell('-'),
            _buildBodyCell('-'),
            _buildBodyCell('-'),
          ],
        ),
      ];
    }

    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.avgDelta.compareTo(a.value.avgDelta));
    return entries.map((entry) {
      final value = entry.value;
      return pw.TableRow(
        children: [
          _buildBodyCell(entry.key),
          _buildBodyCell(value.count.toString()),
          _buildBodyCell(value.avgPre.toStringAsFixed(1)),
          _buildBodyCell(value.avgPost.toStringAsFixed(1)),
          _buildBodyCell(
            value.avgDelta >= 0
                ? '-${value.avgDelta.toStringAsFixed(1)}'
                : value.avgDelta.toStringAsFixed(1),
          ),
        ],
      );
    }).toList();
  }

  static pw.Widget _buildSnapshotCard(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _mapSleep(dynamic sleep) {
    switch (sleep) {
      case 1:
        return '🌑 Restless';
      case 2:
        return '🌓 Broken';
      case 3:
        return '🌕 Restored';
      default:
        return 'N/A';
    }
  }

  static String _mapSocial(dynamic social) {
    switch (social) {
      case 1:
        return '📵 Isolated';
      case 2:
        return '💬 Brief';
      case 3:
        return '🤝 Connected';
      default:
        return 'N/A';
    }
  }

  static pw.Widget _buildObservationBlock(String note) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Personal Context',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            note.trim(),
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static String _getWeatherEmoji(String? weather) {
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

  static Future<Uint8List> _renderChartImage(List<double> values) async {
    const width = 600.0;
    const height = 240.0;
    const padding = 30.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final background = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, width, height),
      background,
    );

    final gridPaint = ui.Paint()
      ..color = const ui.Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 5; i++) {
      final y = padding + (i * (height - padding * 2) / 5);
      canvas.drawLine(
        ui.Offset(padding, y),
        ui.Offset(width - padding, y),
        gridPaint,
      );
    }

    if (values.isEmpty) {
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    }

    final maxValue = 10.0;
    final stepX = (width - padding * 2) / (values.length - 1);
    final linePaint = ui.Paint()
      ..color = const ui.Color(0xFF2EC4B6)
      ..strokeWidth = 4
      ..style = ui.PaintingStyle.stroke;

    final path = ui.Path();
    for (var i = 0; i < values.length; i++) {
      final x = padding + (i * stepX);
      final y = padding +
          ((maxValue - values[i]) / maxValue) * (height - padding * 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final pointPaint = ui.Paint()..color = const ui.Color(0xFF2EC4B6);
    for (var i = 0; i < values.length; i++) {
      final x = padding + (i * stepX);
      final y = padding +
          ((maxValue - values[i]) / maxValue) * (height - padding * 2);
      canvas.drawCircle(ui.Offset(x, y), 4, pointPaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
