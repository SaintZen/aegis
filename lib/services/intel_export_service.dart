import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:anxiety_anchor/services/usage_log_service.dart';

class IntelExportService {
  static Future<File?> exportIntel() async {
    final entries = await UsageLogService.getEntries();
    final pdfBytes = await _buildPdf(entries);
    final directory = await getTemporaryDirectory();
    final fileName =
        'Tactical_NeuroStability_Log_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  static Future<List<int>> _buildPdf(List<UsageLogEntry> entries) async {
    final doc = pw.Document();
    final dateFormatter = DateFormat('MMM dd, yyyy • HH:mm');

    final hollowSeconds =
        entries.where((e) => e.flavor == 'The Hollow').fold<int>(
              0,
              (sum, e) => sum + e.durationSeconds,
            );
    final voidCount =
        entries.where((e) => e.flavor == 'The Void').length;
    final frostSeconds =
        entries.where((e) => e.flavor == 'Scraping Ice').fold<int>(
              0,
              (sum, e) => sum + e.durationSeconds,
            );

    // Duration stored in seconds; round to nearest minute for display
    final hollowMinutes = (hollowSeconds / 60).round();
    final frostMinutes = (frostSeconds / 60).round();

    final activityLog = entries
        .where((e) =>
            e.flavor == 'The Hollow' ||
            e.flavor == 'The Void' ||
            e.flavor == 'Scraping Ice' ||
            e.flavor == 'The Vault')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent = activityLog.take(50).toList();

    final monoFont = pw.Font.courier();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: monoFont,
            bold: pw.Font.helveticaBold(),
          ),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16),
          child: pw.Center(
            child: pw.Text(
              'Confidentiality',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
                font: monoFont,
              ),
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Tactical Neuro-Stability Log',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
              color: PdfColors.grey900,
              font: monoFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            DateFormat('MMMM d, yyyy').format(DateTime.now()),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              font: monoFont,
            ),
          ),
          pw.SizedBox(height: 24),
          _buildSection(
            'Section 1: Somatic Anchoring',
            'Somatic Intrusion Stabilization',
            'Total time in The Hollow',
            '$hollowMinutes min',
          ),
          pw.SizedBox(height: 16),
          _buildSection(
            'Section 2: System Purge',
            'Cognitive Load Management',
            'Items processed via The Void',
            '$voidCount',
          ),
          pw.SizedBox(height: 16),
          _buildSection(
            'Section 3: Sensory Grounding',
            'Peripheral Nervous System Regulation',
            'Usage of The Frost',
            '$frostMinutes min',
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'ACTIVITY LOG (Timestamp, Duration, Tool)',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
              letterSpacing: 1.2,
              font: monoFont,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildActivityTable(recent, dateFormatter),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSection(
    String title,
    String subtitle,
    String label,
    String value,
  ) {
    final mono = pw.Font.courier();
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
              font: mono,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              font: mono,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 9, font: mono),
              ),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: mono,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildActivityTable(
    List<UsageLogEntry> entries,
    DateFormat formatter,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _header('Timestamp'),
            _header('Duration'),
            _header('Tool'),
          ],
        ),
        ...entries.map((entry) {
          final toolLabel = _toolLabel(entry.flavor);
          final durationStr = entry.durationSeconds > 0
              ? '${entry.durationSeconds}s'
              : '1 item';
          return pw.TableRow(
            children: [
              _cell(formatter.format(entry.timestamp)),
              _cell(durationStr),
              _cell(toolLabel),
            ],
          );
        }),
      ],
    );
  }

  static String _toolLabel(String flavor) {
    switch (flavor) {
      case 'The Hollow':
        return 'The Hollow';
      case 'The Void':
        return 'The Void';
      case 'Scraping Ice':
        return 'The Frost';
      case 'The Vault':
        return 'The Vault';
      default:
        return flavor;
    }
  }

  static pw.Widget _header(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
          font: pw.Font.courier(),
        ),
      ),
    );
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          font: pw.Font.courier(),
        ),
      ),
    );
  }
}
