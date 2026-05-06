import 'dart:io';
import 'dart:typed_data';

import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/pending_retest_store.dart';
import 'package:anxiety_anchor/services/vault_service.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates a Technical Audit Log PDF.
/// Data sources for this export only: [VaultService] (vault row) + [AegisLogService] (ledger/audit rows).
/// Support Resources / advocacy link taps are not written to the Aegis log and do not appear here.
/// Data: WorryVault (VaultService) + Aegis log entries.
/// CRUCIAL: Hollow is ADDITIVE (gives shape to feeling) — preserve full Signal Input. NEVER redact.
/// Void is SUBTRACTIVE (shreds thought) — show [REDACTED/PURGED], status CLEAR.
/// Aesthetic: Technical Ledger — monospace, tables, timestamps. No clinical jargon.
class PdfGeneratorService {
  static const int _signalMaxLength = 80;

  /// Export audit log as PDF. Technical Ledger style.
  /// Hollow: full Signal Input (additive). Void: [REDACTED/PURGED], CLEAR (subtractive).
  static Future<void> exportAuditLog() async {
    final data = await _buildAuditPdfDataWithPlaceholder();
    final pdfBytes = await _buildPdf(data);
    final fileName =
        'Technical_Audit_Log_${DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now())}.pdf';
    await Printing.layoutPdf(
      onLayout: (format) async => Uint8List.fromList(pdfBytes),
      name: fileName,
    );
  }

  /// Generate and save the Technical Audit Log PDF.
  /// Always returns a file; generates placeholder when no data.
  static Future<File?> generateTechnicalAuditLog({
    bool showPrintPreview = false,
  }) async {
    final data = await _buildAuditPdfDataWithPlaceholder();

    final pdfBytes = await _buildPdf(data);
    final directory = await getTemporaryDirectory();
    final fileName =
        'Technical_Audit_Log_${DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now())}.pdf';
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

  /// Canonical Aegis-log `type` value for Four Gates runs.
  /// Kept in sync with `fourGatesLedgerType` in `four_gates_screen.dart`.
  static const String _fourGatesLedgerType = 'FOUR_GATES';

  static bool _isHollowAegisEntry(AegisLogEntry e) {
    final lt = e.ledgerType?.toLowerCase() ?? '';
    if (lt.contains('hollow')) return true;
    return e.toolName.toLowerCase().contains('hollow');
  }

  static bool _isFourGatesAegisEntry(AegisLogEntry e) {
    return (e.ledgerType ?? '').toUpperCase() == _fourGatesLedgerType;
  }

  static Future<_AuditPdfData> _buildAuditPdfData() async {
    final hollowEntries = <_HollowPdfEntry>[];
    final fourGatesEntries = <_FourGatesPdfEntry>[];
    final rows = <_AuditRow>[];

    final vaultEntry = await VaultService().loadEntry();
    if (vaultEntry != null && vaultEntry.shouldAppearInAuditPdf) {
      rows.add(_AuditRow(
        timestamp: vaultEntry.lockedAt,
        protocol: 'THE VAULT',
        signalText: vaultEntry.originalText,
        isVoid: false,
        status: vaultEntry.isResolved ? 'STABILIZED' : 'RECORDED',
      ));
    }

    final aegisEntries = await AegisLogService.getEntries();
    for (final e in aegisEntries) {
      if (_isHollowAegisEntry(e)) {
        hollowEntries.add(_HollowPdfEntry(
          timestamp: e.timestamp,
          content: e.signalInput ?? '',
        ));
        continue;
      }
      // Four Gates runs are bucketed into their own verbatim section so the
      // monospaced ledger body is preserved and never truncated by the
      // 80-char Signal Input cap of the main table.
      if (_isFourGatesAegisEntry(e)) {
        fourGatesEntries.add(_FourGatesPdfEntry(
          timestamp: e.timestamp,
          body: e.signalInput ?? '',
        ));
        continue;
      }
      final protocolKey = _mapToProtocol(e.toolName);
      final isVoid = protocolKey == 'THE VOID';
      final protocolLabel =
          (e.ledgerType != null && e.ledgerType!.isNotEmpty)
              ? e.ledgerType!
              : protocolKey;
      rows.add(_AuditRow(
        timestamp: e.timestamp,
        protocol: protocolLabel,
        signalText: e.signalInput,
        isVoid: isVoid,
        status: isVoid ? 'CLEAR' : _mapStatus(e.status),
      ));
    }

    rows.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    hollowEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    fourGatesEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Phase 1.4-C-3 / canonical-sections: pull both ratified and
    // pending re-test contracts. Best-effort — a SharedPreferences
    // failure must not brick the PDF export.
    var ratified = const <PendingRetest>[];
    var pending = const <PendingRetest>[];
    try {
      final store = PendingRetestStore();
      ratified = await store.loadRatified();
      final all = await store.load();
      pending = all
          .where((r) => r.status == PendingRetestStatus.pending)
          .toList(growable: false);
    } catch (_) {
      // Fall through with the empty lists. The PDF will simply render
      // no RATIFIED column data and skip both temporal-arc sections.
    }

    return _AuditPdfData(
      hollowEntries: hollowEntries,
      fourGatesEntries: fourGatesEntries,
      auditRows: rows,
      ratifiedRetests: ratified,
      pendingRetests: pending,
    );
  }

  static Future<_AuditPdfData> _buildAuditPdfDataWithPlaceholder() async {
    final data = await _buildAuditPdfData();
    if (data.auditRows.isEmpty) {
      final hasOtherSections =
          data.hollowEntries.isNotEmpty || data.fourGatesEntries.isNotEmpty;
      return _AuditPdfData(
        hollowEntries: data.hollowEntries,
        fourGatesEntries: data.fourGatesEntries,
        auditRows: [
          _AuditRow(
            timestamp: DateTime.now(),
            protocol: '—',
            signalText: hasOtherSections
                ? 'No additional audit rows (see THE HOLLOW / FOUR GATES sections).'
                : 'No entries recorded',
            isVoid: false,
            status: '—',
          ),
        ],
        ratifiedRetests: data.ratifiedRetests,
        pendingRetests: data.pendingRetests,
      );
    }
    return data;
  }

  static String _mapToProtocol(String toolName) {
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

  static String _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'acknowledged':
        return 'RECORDED';
      case 'aborted':
      case 'failure':
      case 'purged':
      case 'incomplete':
        return 'PURGED';
      default:
        return status.toUpperCase();
    }
  }

  static Future<List<int>> _buildPdf(_AuditPdfData data) async {
    final doc = pw.Document();
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
        build: (context) => [
          _buildHeader(monoFont),
          pw.SizedBox(height: 24),
          _buildHollowSection(data.hollowEntries, monoFont),
          pw.SizedBox(height: 20),
          // (1) FOUR GATES — VERDICT RECORDS: doctrine + verbatim runs.
          _buildFourGatesSection(
            data.fourGatesEntries,
            monoFont,
          ),
          pw.SizedBox(height: 20),
          // (2) WEEKLY STRATA — OVERLOAD / FAILURE / RATIFIED.
          _buildWeeklyStrata(
            data.fourGatesEntries,
            data.ratifiedRetests,
            monoFont,
          ),
          if (data.ratifiedRetests.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            // (3) RATIFICATION RECORDS: paired verbatim originals.
            _buildRatificationRecords(data.ratifiedRetests, monoFont),
          ],
          if (data.pendingRetests.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            // (4) PENDING RE-TEST CONTRACTS.
            _buildPendingRetests(data.pendingRetests, monoFont),
          ],
          pw.SizedBox(height: 20),
          // (5) DOCTRINE — TEMPORAL INTEGRITY OF FOUR GATES.
          _buildTemporalIntegrityDoctrine(monoFont),
          pw.SizedBox(height: 20),
          _buildDataTable(data.auditRows, monoFont),
        ],
      ),
    );

    return doc.save();
  }

  /// PDF_SECTION: THE HOLLOW — each ENTRY: TIMESTAMP (ISO8601), CONTENT (full, additive).
  static pw.Widget _buildHollowSection(
    List<_HollowPdfEntry> entries,
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
                      e.content.isEmpty ? '—' : e.content,
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

  /// PDF_SECTION 1: FOUR GATES — VERDICT RECORDS.
  ///
  /// Section layout (canonical order, locked by `four-gates-doctrine.mdc`):
  ///   1. Title — "FOUR GATES — VERDICT RECORDS"
  ///   2. Counter-imagination doctrine (existing block — answers WHY
  ///      this instrument exists; complementary to the temporal-integrity
  ///      doctrine that closes the Four Gates domain at the end).
  ///   3. Purpose + Interpretation Note (canonical operator-grade copy
  ///      preserved verbatim from the spec the user authored).
  ///   4. Verbatim run bodies, newest-first, each preserving the full
  ///      multi-line ledger output produced by `FourGatesRun.formatLedger()`.
  ///      No 80-char truncation is applied — the body IS the canonical
  ///      record.
  static pw.Widget _buildFourGatesSection(
    List<_FourGatesPdfEntry> entries,
    pw.Font monoFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FOUR GATES — VERDICT RECORDS',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            font: monoFont,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildFourGatesDoctrine(monoFont),
        pw.SizedBox(height: 8),
        _sectionPreamble(
          monoFont,
          purpose:
              'This section lists every FOUR GATES run in chronological '
              'order. Each entry is a verbatim record of the operator\'s '
              'evidence and the resulting verdict.',
          interpretationNote:
              'A FAILURE verdict is not a mistake, error, or personal '
              'deficit. It is a structural checkpoint indicating that one '
              'or more gates did not open under the conditions present at '
              'that moment. The system records this without judgment.',
        ),
        pw.SizedBox(height: 10),
        if (entries.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Text(
              'No runs recorded',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.black,
                font: monoFont,
              ),
            ),
          )
        else
          ...entries.map(
            (e) => pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    e.timestamp.toIso8601String(),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                      font: monoFont,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    e.body.isEmpty ? '—' : e.body,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.black,
                      font: monoFont,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Renders a small `Purpose / Interpretation Note` block under a
  /// section header. Both inputs preserve the canonical operator-grade
  /// copy authored by the user; if either is null, that label is
  /// omitted entirely so the preamble stays compact.
  static pw.Widget _sectionPreamble(
    pw.Font monoFont, {
    String? purpose,
    String? interpretationNote,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (purpose != null) ...[
            pw.Text(
              'PURPOSE',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
                font: monoFont,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              purpose,
              style: pw.TextStyle(
                fontSize: 8,
                lineSpacing: 1.4,
                color: PdfColors.grey800,
                font: monoFont,
              ),
            ),
          ],
          if (purpose != null && interpretationNote != null)
            pw.SizedBox(height: 6),
          if (interpretationNote != null) ...[
            pw.Text(
              'INTERPRETATION NOTE',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
                font: monoFont,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              interpretationNote,
              style: pw.TextStyle(
                fontSize: 8,
                lineSpacing: 1.4,
                color: PdfColors.grey800,
                font: monoFont,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Canonical Four Gates doctrine — verbatim from
  /// `.cursor/rules/four-gates-doctrine.mdc` (§1) and
  /// `lib/models/four_gates_run.dart` (file-level dartdoc).
  /// This string is the SINGLE SOURCE OF TRUTH for the PDF surface.
  /// If the canonical doctrine changes, update this constant in lockstep.
  static const String _fourGatesDoctrine =
      'Four Gates is a temporal interceptor. It activates in the narrow '
      'interval between an operator assigning the label "failure" to an '
      'event and the imagination generating catastrophic projections. '
      'The instrument tests whether failure was structurally possible by '
      'evaluating four preconditions: capacity, visibility, optionality, '
      'and election. If any precondition is absent, the event is '
      'classified as overload, and overload does not authorize escalation '
      'or self-destructive interpretation. The ledger output is the '
      'durable record that the imagination cannot rewrite.';

  static pw.Widget _buildFourGatesDoctrine(pw.Font monoFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DOCTRINE',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              font: monoFont,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _fourGatesDoctrine,
            style: pw.TextStyle(
              fontSize: 8,
              lineSpacing: 1.4,
              color: PdfColors.grey800,
              font: monoFont,
            ),
          ),
        ],
      ),
    );
  }

  /// PDF_SECTION 2: WEEKLY STRATA — OVERLOAD / FAILURE / RATIFIED.
  ///
  /// Top-level section as of the canonical-sections refactor. Newest
  /// week first.
  ///
  /// RATIFIED column (Phase 1.4-C-3): count of FAILURE verdicts in the
  /// row's week that have been re-tested at the 24h boundary. The
  /// invariant `ratifiedCount <= failureCount` always holds: a week
  /// can never report more ratifications than there were FAILUREs to
  /// ratify. The verdict (CONFIRMED vs OVERTURNED) is intentionally
  /// rolled up here — the breakdown lives in RATIFICATION RECORDS,
  /// where each pair is shown explicitly.
  ///
  /// The OVERLOAD / FAILURE wording in the preamble is doctrinally
  /// canonical (any CLOSED gate → OVERLOAD; all OPEN → FAILURE) — see
  /// `four_gates_run.dart`. Do not paraphrase; readers cross-reference
  /// this against actual ledger bodies above.
  static pw.Widget _buildWeeklyStrata(
    List<_FourGatesPdfEntry> entries,
    List<PendingRetest> ratifiedRetests,
    pw.Font monoFont,
  ) {
    final strata = _bucketFourGatesByWeek(
      entries,
      ratifiedRetests: ratifiedRetests,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'WEEKLY STRATA — OVERLOAD / FAILURE / RATIFIED',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            font: monoFont,
          ),
        ),
        pw.SizedBox(height: 8),
        _sectionPreamble(
          monoFont,
          purpose:
              'This table summarizes weekly counts of:\n'
              '  OVERLOAD — at least one gate CLOSED (event was '
              'structurally constrained)\n'
              '  FAILURE  — all four gates OPEN (event was elective; '
              'verdict is provisional pending 24h re-test)\n'
              '  RATIFIED — re-tests that confirmed or overturned a '
              'prior FAILURE',
          interpretationNote:
              'The RATIFIED column reflects the outcome of temporal '
              'contracts. Re-tests do not create new verdicts for '
              'strata; they resolve existing ones.',
        ),
        pw.SizedBox(height: 8),
        if (strata.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Text(
              'No weekly strata to display',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.black,
                font: monoFont,
              ),
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _headerCell('WEEK OF (Mon)', monoFont),
                  _headerCell('OVERLOAD', monoFont),
                  _headerCell('FAILURE', monoFont),
                  _headerCell('RATIFIED', monoFont),
                ],
              ),
              ...strata.map(
                (row) => pw.TableRow(
                  children: [
                    _bodyCell(_isoDate(row.weekStart), monoFont),
                    _bodyCell(row.overloadCount.toString(), monoFont),
                    _bodyCell(row.failureCount.toString(), monoFont),
                    _bodyCell(row.ratifiedCount.toString(), monoFont),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// PDF_SECTION 3: RATIFICATION RECORDS.
  ///
  /// One block per ratified [PendingRetest], newest-ratified-first.
  /// Each block is **self-contained**: it carries the verbatim original
  /// FAILURE ledger (reconstructed deterministically from
  /// `PendingRetest.originalGates` + `originalRunAt`) alongside the
  /// metadata pair (contract id, verdict, both timestamps).
  ///
  /// The ratifying run's verbatim ledger is intentionally NOT duplicated
  /// here — it already lives in FOUR GATES — VERDICT RECORDS above,
  /// and the contract id is shared. This section's job is to make the
  /// originals legible in their ratification context, not to clone the
  /// audit log.
  static pw.Widget _buildRatificationRecords(
    List<PendingRetest> records,
    pw.Font monoFont,
  ) {
    final ratified = records.where((r) => r.isRatified).toList()
      ..sort((a, b) {
        final aAt = a.ratifiedAt ?? a.dueAt;
        final bAt = b.ratifiedAt ?? b.dueAt;
        return bAt.compareTo(aAt);
      });
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RATIFICATION RECORDS',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            font: monoFont,
          ),
        ),
        pw.SizedBox(height: 8),
        _sectionPreamble(
          monoFont,
          purpose:
              'This section pairs each FAILURE that generated a 24-hour '
              'contract with its corresponding re-test. Each record '
              'shows the original FAILURE (verbatim), the contract ID, '
              'the re-test verdict (CONFIRMED or OVERTURNED), and '
              'timestamps for both events.',
          interpretationNote:
              'A re-test is not a second opinion. It is a temporal '
              're-encounter with the same event after conditions have '
              'changed. The operator\'s evidence is re-collected blind, '
              'with optional access to the original text. This preserves '
              'the integrity of the ledger and prevents imagination '
              'drift.',
        ),
        pw.SizedBox(height: 10),
        ...ratified.map(
          (r) => _buildRatificationRecord(r, monoFont),
        ),
      ],
    );
  }

  /// One paired record block within RATIFICATION RECORDS.
  ///
  /// Layout:
  ///   - Verdict header (CONFIRMED / OVERTURNED, bold)
  ///   - 4-row metadata table (contract id / original / ratified at /
  ///     verdict)
  ///   - Verbatim original FAILURE ledger, reconstructed from the
  ///     contract's `originalGates` so the section reads end-to-end
  ///     without forcing the doctor to flip back to VERDICT RECORDS.
  static pw.Widget _buildRatificationRecord(
    PendingRetest r,
    pw.Font monoFont,
  ) {
    final verdict = r.status == PendingRetestStatus.ratifiedConfirmed
        ? 'CONFIRMED'
        : 'OVERTURNED';
    final originalLedger = FourGatesRun(
      runAt: r.originalRunAt,
      gates: r.originalGates,
    ).formatLedger();
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RATIFICATION — $verdict',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: monoFont,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.0),
              1: pw.FlexColumnWidth(2.5),
            },
            children: [
              pw.TableRow(children: [
                _bodyCell('CONTRACT ID', monoFont),
                _bodyCell(r.id, monoFont),
              ]),
              pw.TableRow(children: [
                _bodyCell('ORIGINAL', monoFont),
                _bodyCell(r.originalRunAt.toIso8601String(), monoFont),
              ]),
              pw.TableRow(children: [
                _bodyCell('RATIFIED AT', monoFont),
                _bodyCell(
                  (r.ratifiedAt ?? r.dueAt).toIso8601String(),
                  monoFont,
                ),
              ]),
              pw.TableRow(children: [
                _bodyCell('VERDICT', monoFont),
                _bodyCell(verdict, monoFont),
              ]),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'ORIGINAL FAILURE (verbatim):',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              font: monoFont,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border:
                  pw.Border.all(color: PdfColors.grey700, width: 0.4),
            ),
            child: pw.Text(
              originalLedger,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.black,
                font: monoFont,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PDF_SECTION 4: PENDING RE-TEST CONTRACTS.
  ///
  /// Lists active 24-hour contracts that have not yet been ratified.
  /// Doctrine: a pending contract is a structural fact, not an overdue
  /// task. Pending contracts do not expire — see Q5 (LIVES FOREVER) in
  /// the Phase 1.4-C directional answers.
  ///
  /// The status column is always literal `PENDING` because the section
  /// only renders when there is at least one record matching that status
  /// (rendering is gated in `_buildPdf`).
  static pw.Widget _buildPendingRetests(
    List<PendingRetest> pending,
    pw.Font monoFont,
  ) {
    final rows = pending
        .where((r) => r.status == PendingRetestStatus.pending)
        .toList()
      ..sort((a, b) => b.dueAt.compareTo(a.dueAt));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PENDING RE-TEST CONTRACTS',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            font: monoFont,
          ),
        ),
        pw.SizedBox(height: 8),
        _sectionPreamble(
          monoFont,
          purpose:
              'This section lists any active 24-hour contracts that have '
              'not yet been ratified. Each entry includes the contract '
              'ID, timestamp of the original FAILURE, due time for '
              're-test, and current status (pending).',
          interpretationNote:
              'A pending contract is not an error or overdue task. It is '
              'a structural fact: the operator has not yet re-encountered '
              'the event. Pending contracts do not expire.',
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.4),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.6),
            3: pw.FlexColumnWidth(1.0),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _headerCell('CONTRACT ID', monoFont),
                _headerCell('ORIGINAL FAILURE', monoFont),
                _headerCell('DUE AT', monoFont),
                _headerCell('STATUS', monoFont),
              ],
            ),
            ...rows.map(
              (r) => pw.TableRow(
                children: [
                  _bodyCell(r.id, monoFont),
                  _bodyCell(r.originalRunAt.toIso8601String(), monoFont),
                  _bodyCell(r.dueAt.toIso8601String(), monoFont),
                  _bodyCell('PENDING', monoFont),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// PDF_SECTION 5: DOCTRINE — TEMPORAL INTEGRITY OF FOUR GATES.
  ///
  /// Closes the FOUR GATES domain with the operating-rules doctrine.
  /// Complementary to (not redundant with) the counter-imagination
  /// doctrine that opens VERDICT RECORDS:
  ///   - Counter-imagination doctrine answers WHY this exists.
  ///   - Temporal-integrity doctrine answers HOW the timestamps,
  ///     contracts, and ratifications operate.
  ///
  /// Both are canonical and locked by `four-gates-doctrine.mdc`.
  static pw.Widget _buildTemporalIntegrityDoctrine(pw.Font monoFont) {
    const bullets = <String>[
      'Every FAILURE emits a 24-hour contract.',
      'A re-test collects fresh evidence; original evidence is hidden '
          'unless revealed.',
      'A re-test may CONFIRM or OVERTURN the original verdict.',
      'A re-test FAILURE emits a new contract (chain continues).',
      'An OVERLOAD re-test ends the chain.',
      'Ledger entries are immutable; re-tests do not modify originals.',
      'The PDF reflects the full temporal arc without interpretation '
          'or judgment.',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DOCTRINE — TEMPORAL INTEGRITY OF FOUR GATES',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            font: monoFont,
          ),
        ),
        pw.SizedBox(height: 8),
        _sectionPreamble(
          monoFont,
          purpose:
              'This section explains the temporal rules governing '
              'FAILURE, re-tests, and ratification.',
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DOCTRINE SUMMARY',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                  font: monoFont,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 6),
              ...bullets.map(
                (b) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 12,
                        child: pw.Text(
                          '·',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.black,
                            font: monoFont,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          b,
                          style: pw.TextStyle(
                            fontSize: 9,
                            lineSpacing: 1.4,
                            color: PdfColors.black,
                            font: monoFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Buckets [entries] into Monday-anchored weeks and returns rows
  /// sorted newest-first. Entries whose verbatim ledger body cannot be
  /// classified are silently excluded from the counts (they still
  /// appear verbatim in the runs list below the strata).
  ///
  /// [ratifiedRetests] (Phase 1.4-C-3) attribute their RATIFIED count
  /// to the **week of the original FAILURE** (i.e. `originalRunAt`),
  /// not the week of the ratifying re-test. This makes each row read
  /// as a self-contained question: "of the FAILUREs I logged in this
  /// week, how many have I gone back to ratify?"
  ///
  /// Re-test runs themselves (audit entries whose body wears a
  /// `[RE-TEST OF ...]` header) are deliberately EXCLUDED from the
  /// FAILURE / OVERLOAD counts to avoid double-counting: they are not
  /// fresh verdicts, they are ratifications of an earlier verdict.
  static List<_FourGatesStrataRow> _bucketFourGatesByWeek(
    List<_FourGatesPdfEntry> entries, {
    List<PendingRetest> ratifiedRetests = const <PendingRetest>[],
  }) {
    final byWeek = <DateTime, _FourGatesStrataRow>{};
    for (final e in entries) {
      // Skip ratification entries — see doc-comment.
      if (_isRatificationBody(e.body)) continue;
      final verdict = _classifyFourGatesContent(e.body);
      if (verdict == null) continue; // unclassifiable — skip the count
      final monday = _mondayOf(e.timestamp);
      final row = byWeek.putIfAbsent(
        monday,
        () => _FourGatesStrataRow(weekStart: monday),
      );
      switch (verdict) {
        case _FourGatesVerdict.failure:
          row.failureCount += 1;
          break;
        case _FourGatesVerdict.overload:
          row.overloadCount += 1;
          break;
      }
    }

    // Attribute RATIFIED counts to the original FAILURE's week.
    for (final r in ratifiedRetests) {
      if (!r.isRatified) continue; // defensive — pending records ignored
      final monday = _mondayOf(r.originalRunAt);
      final row = byWeek.putIfAbsent(
        monday,
        () => _FourGatesStrataRow(weekStart: monday),
      );
      row.ratifiedCount += 1;
    }

    final rows = byWeek.values.toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return rows;
  }

  /// Returns `true` if [body] starts with the `[RE-TEST OF <id>]`
  /// header that [PendingRetest.ratificationLedgerHeader] emits.
  /// Used to keep ratifications out of the OVERLOAD / FAILURE counts.
  static bool _isRatificationBody(String body) {
    return body.startsWith('[RE-TEST OF ');
  }

  /// Parses a verbatim `FourGatesRun.formatLedger()` body for its
  /// STATUS line. Returns `null` for legacy or malformed content so
  /// the strata count never lies.
  static _FourGatesVerdict? _classifyFourGatesContent(String content) {
    // Match ` STATUS:           FAILURE ` or ` STATUS:           OVERLOAD `.
    final match = RegExp(
      r'^STATUS:\s*(FAILURE|OVERLOAD)\s*$',
      multiLine: true,
    ).firstMatch(content);
    if (match == null) return null;
    return match.group(1) == 'FAILURE'
        ? _FourGatesVerdict.failure
        : _FourGatesVerdict.overload;
  }

  /// Returns the Monday at 00:00 (local) of the week containing [d].
  static DateTime _mondayOf(DateTime d) {
    final daysFromMonday = (d.weekday - DateTime.monday) % 7;
    final monday = DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: daysFromMonday));
    return monday;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Test seams ──────────────────────────────────────────────────────────
  // Public-but-test-only wrappers around the strata internals. They exist
  // so unit tests can verify that the FOUR GATES strata bucketer remains
  // correctly coupled to the format of `FourGatesRun.formatLedger()`. If
  // either format drifts, these tests fire first.

  /// Returns `'FAILURE'`, `'OVERLOAD'`, or `null` for the verbatim ledger
  /// body produced by `FourGatesRun.formatLedger()`.
  @visibleForTesting
  static String? debugClassifyFourGatesContent(String content) {
    final v = _classifyFourGatesContent(content);
    if (v == null) return null;
    return v == _FourGatesVerdict.failure ? 'FAILURE' : 'OVERLOAD';
  }

  /// Buckets the supplied parallel (timestamp, body) lists by
  /// Monday-anchored week and returns the same shape the PDF strata table
  /// renders. Result rows are
  /// `{weekStart: DateTime, overload: int, failure: int, ratified: int}`,
  /// newest-first.
  ///
  /// `timestamps` and `bodies` must be the same length. `ratifiedRetests`
  /// is the Phase 1.4-C-3 input: each ratified contract increments its
  /// row by `originalRunAt`'s week.
  @visibleForTesting
  static List<Map<String, Object>> debugBucketFourGatesByWeek(
    List<DateTime> timestamps,
    List<String> bodies, {
    List<PendingRetest> ratifiedRetests = const <PendingRetest>[],
  }) {
    assert(
      timestamps.length == bodies.length,
      'timestamps and bodies must be parallel',
    );
    final pdfEntries = <_FourGatesPdfEntry>[
      for (var i = 0; i < timestamps.length; i++)
        _FourGatesPdfEntry(timestamp: timestamps[i], body: bodies[i]),
    ];
    return _bucketFourGatesByWeek(
      pdfEntries,
      ratifiedRetests: ratifiedRetests,
    )
        .map((r) => <String, Object>{
              'weekStart': r.weekStart,
              'overload': r.overloadCount,
              'failure': r.failureCount,
              'ratified': r.ratifiedCount,
            })
        .toList(growable: false);
  }

  /// Pure-function counterpart of [_buildRatificationRecords] for unit
  /// tests. Each row is
  /// `{originalRunAt: DateTime, ratifiedAt: DateTime, ratifyingRunAt:
  /// DateTime, verdict: 'CONFIRMED'|'OVERTURNED', originalId: String}`,
  /// newest-ratified-first (matches the PDF section ordering).
  ///
  /// Pending contracts are silently excluded — they have nothing to
  /// report yet.
  @visibleForTesting
  static List<Map<String, Object>> debugBuildRatificationRows(
    List<PendingRetest> records,
  ) {
    final ratified = records.where((r) => r.isRatified).toList()
      ..sort((a, b) {
        final aAt = a.ratifiedAt ?? a.dueAt;
        final bAt = b.ratifiedAt ?? b.dueAt;
        return bAt.compareTo(aAt);
      });
    return ratified
        .map((r) => <String, Object>{
              'originalId': r.id,
              'originalRunAt': r.originalRunAt,
              'ratifiedAt': r.ratifiedAt!,
              'ratifyingRunAt': r.ratifyingRunAt!,
              'verdict':
                  r.status == PendingRetestStatus.ratifiedConfirmed
                      ? 'CONFIRMED'
                      : 'OVERTURNED',
            })
        .toList(growable: false);
  }

  /// Pure-function counterpart to `_buildPendingRetests`. Filters down
  /// to status == pending, sorts newest-due-first, and projects to a
  /// stable map shape for assertions. Mirrors `debugBuildRatificationRows`.
  @visibleForTesting
  static List<Map<String, Object>> debugBuildPendingRetestRows(
    List<PendingRetest> records,
  ) {
    final pending = records
        .where((r) => r.status == PendingRetestStatus.pending)
        .toList()
      ..sort((a, b) => b.dueAt.compareTo(a.dueAt));
    return pending
        .map((r) => <String, Object>{
              'id': r.id,
              'originalRunAt': r.originalRunAt,
              'dueAt': r.dueAt,
              'status': 'PENDING',
            })
        .toList(growable: false);
  }

  static pw.Widget _buildHeader(pw.Font monoFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TECHNICAL AUDIT LOG',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: monoFont,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Data Source: WorryVault Local Storage',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.black,
              font: monoFont,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDataTable(List<_AuditRow> rows, pw.Font monoFont) {
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
            _headerCell('Incident Timestamp', monoFont),
            _headerCell('Intervention Protocol', monoFont),
            _headerCell('Signal Input (7th Sense)', monoFont),
            _headerCell('Status', monoFont),
          ],
        ),
        ...rows.map((r) => pw.TableRow(
              children: [
                _bodyCell(
                  DateFormat('yyyy-MM-dd HH:mm').format(r.timestamp),
                  monoFont,
                ),
                _bodyCell(r.protocol, monoFont),
                _bodyCell(_formatSignal(r), monoFont),
                _bodyCell(r.status, monoFont),
              ],
            )),
      ],
    );
  }

  /// Hollow = ADDITIVE: preserve full Signal Input. Void = SUBTRACTIVE: [REDACTED/PURGED].
  /// DO NOT redact Hollow text in Vault or PDF.
  static String _formatSignal(_AuditRow r) {
    if (r.isVoid) return '[REDACTED/PURGED]';
    final text = r.signalText ?? '';
    if (text.isEmpty) return '—';
    return text.length > _signalMaxLength
        ? '${text.substring(0, _signalMaxLength)}…'
        : text;
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

class _HollowPdfEntry {
  const _HollowPdfEntry({required this.timestamp, required this.content});

  final DateTime timestamp;
  final String content;
}

class _FourGatesPdfEntry {
  const _FourGatesPdfEntry({required this.timestamp, required this.body});

  final DateTime timestamp;
  final String body;
}

/// One row of the FOUR GATES strata table.
/// Counts mutate as the bucketer walks entries.
class _FourGatesStrataRow {
  _FourGatesStrataRow({required this.weekStart});

  final DateTime weekStart;
  int overloadCount = 0;
  int failureCount = 0;
  // Phase 1.4-C-3: count of FAILURE verdicts in this week that have
  // been ratified (CONFIRMED or OVERTURNED) by a 24h re-test.
  // Always satisfies `ratifiedCount <= failureCount` per week.
  int ratifiedCount = 0;
}

enum _FourGatesVerdict { failure, overload }

class _AuditPdfData {
  const _AuditPdfData({
    required this.hollowEntries,
    required this.fourGatesEntries,
    required this.auditRows,
    this.ratifiedRetests = const <PendingRetest>[],
    this.pendingRetests = const <PendingRetest>[],
  });

  final List<_HollowPdfEntry> hollowEntries;
  final List<_FourGatesPdfEntry> fourGatesEntries;
  final List<_AuditRow> auditRows;

  /// Phase 1.4-C-3: ratified re-test contracts loaded from
  /// [PendingRetestStore]. Used to (a) enrich the WEEKLY STRATA
  /// table with a RATIFIED column attributed to the original FAILURE's
  /// week and (b) populate the RATIFICATION RECORDS section.
  final List<PendingRetest> ratifiedRetests;

  /// Pending (un-ratified) re-test contracts loaded from
  /// [PendingRetestStore]. Drives the PENDING RE-TEST CONTRACTS section.
  /// Doctrine: a pending contract is a structural fact, not an overdue
  /// task — it lives forever until the operator returns to ratify.
  final List<PendingRetest> pendingRetests;
}

class _AuditRow {
  _AuditRow({
    required this.timestamp,
    required this.protocol,
    required this.signalText,
    required this.isVoid,
    required this.status,
  });

  final DateTime timestamp;
  final String protocol;
  final String? signalText;
  final bool isVoid;
  final String status;
}

