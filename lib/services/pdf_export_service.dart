import 'dart:io';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'dart:typed_data';

import 'package:anxiety_anchor/services/aegis_log_service.dart';

/// Exports AEGIS System Audit Report as a PDF with Tabular Ledger layout.
/// Black Box style: monospaced, clean borders, no diatribes.
class PDFExportService {
  static String _generateReportId() {
    final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final r = Random().nextInt(0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return 'UUID-$t-$r';
  }

  /// Export audit entries to PDF. Optionally pass [userNameOrId] for the subject line.
  /// Returns the saved file, or null if no entries.
  static Future<File?> exportAuditReport({
    String? userNameOrId,
    bool showPrintPreview = false,
  }) async {
    final entries = await AegisLogService.getEntries();
    if (entries.isEmpty) return null;

    final reportId = _generateReportId();
    final pdfBytes = await _buildPdf(entries, reportId: reportId);
    final directory = await getTemporaryDirectory();
    final fileName =
        'AEGIS_Audit_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);

    if (showPrintPreview) {
      await Printing.layoutPdf(
        onLayout: (format) async => Uint8List.fromList(pdfBytes),
        name: fileName,
      );
    }

    return file;
  }

  static Future<List<int>> _buildPdf(
    List<AegisLogEntry> entries, {
    required String reportId,
  }) async {
    final doc = pw.Document();
    final monoFont = pw.Font.courier();

    final sortedEntries = [...entries]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final hollowEntries =
        sortedEntries.where(_isHollowAegisEntry).toList(growable: false);
    final auditEntries =
        sortedEntries.where((e) => !_isHollowAegisEntry(e)).toList();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: monoFont,
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          _buildHeader(reportId, monoFont),
          pw.SizedBox(height: 24),
          _buildHollowSection(hollowEntries, monoFont),
          pw.SizedBox(height: 20),
          _buildDataTable(auditEntries, monoFont, hollowEntries.isNotEmpty),
        ],
      ),
    );

    return doc.save();
  }

  static bool _isHollowAegisEntry(AegisLogEntry e) {
    final lt = e.ledgerType?.toLowerCase() ?? '';
    if (lt.contains('hollow')) return true;
    return e.toolName.toLowerCase().contains('hollow');
  }

  /// PDF_SECTION: THE HOLLOW — ENTRY: TIMESTAMP, CONTENT (full).
  static pw.Widget _buildHollowSection(
    List<AegisLogEntry> entries,
    pw.Font monoFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'THE HOLLOW',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.6,
            color: PdfColors.black,
            font: monoFont,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.35),
            1: pw.FlexColumnWidth(3.15),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _headerCell('TIMESTAMP', monoFont),
                _headerCell('CONTENT', monoFont),
              ],
            ),
            if (entries.isEmpty)
              pw.TableRow(
                children: [
                  _bodyCell('—', monoFont),
                  _bodyCell('No entries recorded', monoFont),
                ],
              )
            else
              ...entries.map(
                (e) => pw.TableRow(
                  children: [
                    _bodyCell(e.timestamp.toIso8601String(), monoFont),
                    _bodyCell(
                      (e.signalInput != null && e.signalInput!.isNotEmpty)
                          ? e.signalInput!
                          : '—',
                      monoFont,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildHeader(String reportId, pw.Font monoFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        color: PdfColors.white,
      ),
      child: pw.Text(
        'INTERNAL DOCUMENT: AEGIS STABILITY AUDIT REPORT  ID: $reportId  SYSTEM STATUS: ACTIVE',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1.2,
          color: PdfColors.black,
          font: monoFont,
        ),
      ),
    );
  }

  static const int _signalMaxLength = 60;

  static pw.Widget _buildDataTable(
    List<AegisLogEntry> entries,
    pw.Font monoFont,
    bool hasHollowSection,
  ) {
    final rows = entries
        .map(
          (e) => pw.TableRow(
            children: [
              _bodyCell(
                '${e.timestamp.month}/${e.timestamp.day}/${e.timestamp.year % 100} '
                '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}',
                monoFont,
              ),
              _bodyCell(
                (e.ledgerType != null && e.ledgerType!.isNotEmpty)
                    ? e.ledgerType!
                    : _mapToolToProtocol(e.toolName),
                monoFont,
              ),
              _bodyCell(_formatSignalInput(e.signalInput), monoFont),
              _bodyCell(_mapStatusToLedger(e.status), monoFont),
            ],
          ),
        )
        .toList();

    if (rows.isEmpty) {
      rows.add(
        pw.TableRow(
          children: [
            _bodyCell('—', monoFont),
            _bodyCell('—', monoFont),
            _bodyCell(
              hasHollowSection
                  ? 'No additional audit rows (see THE HOLLOW section).'
                  : 'No entries recorded',
              monoFont,
            ),
            _bodyCell('—', monoFont),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(3),
        3: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _headerCell('TIMESTAMP', monoFont),
            _headerCell('PROTOCOL', monoFont),
            _headerCell('SIGNAL INPUT (THE 7TH SENSE)', monoFont),
            _headerCell('STATUS', monoFont),
          ],
        ),
        ...rows,
      ],
    );
  }

  static String _mapToolToProtocol(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('void')) return 'THE VOID';
    if (lower.contains('hollow')) return 'THE HOLLOW';
    if (lower.contains('frost') || lower.contains('ice') || lower.contains('scraper')) {
      return 'THE FROST';
    }
    if (lower.contains('anchor') || lower.contains('kinetic') ||
        lower.contains('pulse') || lower.contains('wall') ||
        lower.contains('breath') || lower.contains('vault')) {
      return 'THE ANCHOR';
    }
    return toolName.toUpperCase();
  }

  static String _formatSignalInput(String? signalInput) {
    if (signalInput == null || signalInput.isEmpty) {
      return '[REDACTED/PURGED]';
    }
    final truncated = signalInput.length > _signalMaxLength
        ? '${signalInput.substring(0, _signalMaxLength)}…'
        : signalInput;
    return '"$truncated"';
  }

  static String _mapStatusToLedger(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'STABILIZED';
      case 'acknowledged':
        return 'RECORDED';
      case 'aborted':
      case 'failure':
      case 'purged':
      case 'incomplete':
        return 'CLEAR';
      default:
        return status.toUpperCase();
    }
  }

  static pw.Widget _headerCell(String text, pw.Font monoFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
          font: monoFont,
        ),
      ),
    );
  }

  static pw.Widget _bodyCell(String text, pw.Font monoFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.black,
          font: monoFont,
        ),
      ),
    );
  }

}
