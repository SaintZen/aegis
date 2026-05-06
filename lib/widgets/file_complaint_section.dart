import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:anxiety_anchor/widgets/contact_row.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// FILE_COMPLAINT
/// ├── HEADER (title + subtitle)
/// ├── STATE REGULATOR (NAIC locator — covers all 50 US states)
/// ├── USA — FEDERAL CHANNELS (CMS, DOL, HHS)
/// ├── SUPPORTING MATERIALS (generated template PDF + file_picker evidence)
/// └── CONTACT (operator / mailto)
///
/// SCOPE: USA-only. The complaint flow is shaped around US health
/// insurance disputes; international ombudsmen are intentionally NOT
/// listed to avoid implying jurisdictional coverage we haven't
/// validated. The state row uses the NAIC locator so adding a single
/// US state never re-locks the rest of the country.
class FileComplaintSection extends StatefulWidget {
  const FileComplaintSection({super.key});

  @override
  State<FileComplaintSection> createState() => _FileComplaintSectionState();
}

class _FileComplaintSectionState extends State<FileComplaintSection> {
  // State regulator locator — covers all 50 US states. Replaces the
  // earlier Nebraska-only links so adding any single state never
  // re-locks the rest of the country.
  static const String _usaNaicLocator =
      'https://content.naic.org/state-insurance-departments';

  // USA federal channels.
  static const String _cmsAppeals =
      'https://www.healthcare.gov/marketplace-appeals/';
  static const String _dolErisaAsk =
      'https://www.dol.gov/agencies/ebsa/about-ebsa/ask-a-question/ask-ebsa';
  static const String _hhsOcr =
      'https://ocrportal.hhs.gov/ocr/smartscreen/main.jsf';

  static const String _aegisComplaintTemplate = '''
AEGIS — REGULATORY COMPLAINT (STRUCTURE)

Use neutral, dated entries. Attach copies; keep originals.

1. HEADER
   Date filed: _______________
   Agency / portal: _______________
   Re: Complaint regarding _______________

2. PARTIES
   Complainant (you): _______________
   Respondent (insurer, employer, entity): _______________
   Policy / member / claim ID (if any): _______________

3. SUMMARY
   Brief factual summary (what happened, in order):

   _________________________________________________
   _________________________________________________

4. TIMELINE
   YYYY-MM-DD — Event
   (add rows)

5. ISSUES / BASIS
   Denial reason cited: _______________
   Statute / contract section you rely on (if known): _______________

6. RELIEF REQUESTED
   What outcome you want (specific): _______________

7. ATTACHMENT INDEX
   A. _______________
   B. _______________

Signature / date: _______________
''';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) ok = await launchUrl(uri);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link. $url'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Internal PDF: generated Aegis-formatted template, then share sheet.
  Future<void> _downloadComplaintTemplate() async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Text(
              'AEGIS — COMPLAINT TEMPLATE',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.courier(),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Aegis-formatted structure for regulatory filings.',
              style: pw.TextStyle(
                fontSize: 9,
                font: pw.Font.courier(),
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              _aegisComplaintTemplate,
              style: pw.TextStyle(
                fontSize: 9,
                lineSpacing: 1.35,
                font: pw.Font.courier(),
              ),
            ),
          ],
        ),
      );
      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/aegis_complaint_template.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Aegis complaint template',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not build PDF: $e')),
      );
    }
  }

  Future<void> _pickEvidence() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected.')),
      );
      return;
    }
    final names = result.files.map((f) => f.name).take(5).join(', ');
    final more = result.files.length > 5 ? '…' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected (${result.files.length}): $names$more'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FILE COMPLAINT',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              fontSize: 16,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'External regulatory channels',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontFamily: 'RobotoMono',
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'STATE REGULATOR'),
          const SizedBox(height: 8),
          _externalRow(
            title: 'NAIC — State Insurance Regulator Locator',
            url: _usaNaicLocator,
            subtext: 'Find the insurance department for any US state',
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'USA — FEDERAL CHANNELS'),
          const SizedBox(height: 8),
          _externalRow(
            title: 'CMS — Marketplace Appeals',
            url: _cmsAppeals,
            subtext: 'Coverage and claim disputes',
          ),
          _externalRow(
            title: 'DOL — ERISA Complaints',
            url: _dolErisaAsk,
            subtext: 'Employer-sponsored plan issues',
          ),
          _externalRow(
            title: 'HHS — Civil Rights Complaint',
            url: _hhsOcr,
            subtext: 'Discrimination or procedural violations',
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'SUPPORTING MATERIALS'),
          const SizedBox(height: 8),
          SupportingMaterialsWidget(
            onDownloadTemplate: _downloadComplaintTemplate,
            onPickEvidence: _pickEvidence,
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'CONTACT'),
          const SizedBox(height: 8),
          const ContactRow(
            title: 'Zwischenzug Corestone LLC',
            subtitle: 'Operational architecture & support',
            mailto: null,
          ),
          const ContactRow(
            title: 'zwischenzug.admin@proton.me',
            subtitle: 'Direct contact for assistance',
            mailto: 'zwischenzug.admin@proton.me',
          ),
        ],
      ),
    );
  }

  Widget _externalRow({
    required String title,
    required String url,
    required String subtext,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      splashColor: Colors.white10,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'RobotoMono',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtext,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontFamily: 'RobotoMono',
                fontSize: 10,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              url,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontFamily: 'RobotoMono',
                fontSize: 9,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  static const Color _color = Color(0xFF5C5C5C);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _color,
        fontFamily: 'RobotoMono',
        fontSize: 10,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Template download + evidence picker rows for [FileComplaintSection].
class SupportingMaterialsWidget extends StatelessWidget {
  const SupportingMaterialsWidget({
    super.key,
    required this.onDownloadTemplate,
    required this.onPickEvidence,
  });

  final Future<void> Function() onDownloadTemplate;
  final Future<void> Function() onPickEvidence;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _complaintActionRow(
          title: 'Download Complaint Template',
          subtext: 'Aegis-formatted structure',
          onTap: () => onDownloadTemplate(),
        ),
        _complaintActionRow(
          title: 'Upload Evidence',
          subtext: 'Screenshots, PDFs, timelines',
          onTap: () => onPickEvidence(),
        ),
      ],
    );
  }
}

Widget _complaintActionRow({
  required String title,
  required String subtext,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    splashColor: Colors.white10,
    highlightColor: Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtext,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontFamily: 'RobotoMono',
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
  );
}
