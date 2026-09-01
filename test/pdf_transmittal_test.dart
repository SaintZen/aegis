import 'dart:convert';
import 'dart:io';

import 'package:anxiety_anchor/data/pdf_transmittal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  const forbidden = [
    'help',
    'feelings',
    'support',
    'cope',
    'comfort',
    'healing',
    'kindness',
    'self-care',
    'gentle',
    'soothe',
    'validate',
    'HIPAA compliant',
    'HIPAA-compliant',
  ];

  test('operator-facing transmittal copy is locked', () {
    expect(PdfTransmittal.title, 'TRANSMITTAL - NOT A MEDICAL RECORD');
    expect(
      PdfTransmittal.banner,
      'AEGIS EXPORT - NOT A DOCTOR. NOT A MEDICAL RECORD. NOT A DIAGNOSIS.',
    );
    expect(PdfTransmittal.shareText, contains('Not a doctor'));
    expect(PdfTransmittal.shareText, contains('Not a medical record'));
    expect(PdfTransmittal.lineNotADoctor, 'Aegis is not a doctor.');
    expect(PdfTransmittal.lineNotADevice, 'Aegis is not a medical device.');
    expect(PdfTransmittal.lineElection, contains('operator elected'));
    expect(PdfTransmittal.lineElection, contains('not a transmission by Aegis'));
  });

  test('transmittal copy does not claim HIPAA or use therapy verbs', () {
    final blob = PdfTransmittal.allOperatorFacing.join('\n').toLowerCase();
    for (final word in forbidden) {
      expect(blob, isNot(contains(word.toLowerCase())), reason: word);
    }
  });

  test('cover + footer bytes carry the transmittal stamp', () async {
    final doc = pw.Document(compress: false);
    final mono = pw.Font.courier();
    doc.addPage(
      pw.MultiPage(
        footer: (context) => PdfTransmittal.pageFooter(mono),
        build: (context) => [
          PdfTransmittal.cover(mono),
          pw.SizedBox(height: 12),
          pw.Text('LEDGER BODY', style: pw.TextStyle(font: mono)),
        ],
      ),
    );
    final ascii = latin1.decode(await doc.save(), allowInvalid: true);
    final tokens = RegExp(r'\[\(([^)]+)\)\]TJ')
        .allMatches(ascii)
        .map((m) => m.group(1)!)
        .join(' ');
    expect(tokens, contains('TRANSMITTAL'));
    expect(tokens, contains('NOT A MEDICAL RECORD'));
    expect(tokens, contains('NOT A DOCTOR'));
    expect(tokens, contains('NOT A DIAGNOSIS'));
    expect(tokens, contains('operator elected'));
  });

  test('every PDF writer stamps cover, footer, and sealed temp', () {
    const writers = [
      'lib/services/pdf_generator_service.dart',
      'lib/services/pdf_export_service.dart',
      'lib/services/journal_export_service.dart',
      'lib/services/intel_export_service.dart',
      'lib/widgets/file_complaint_section.dart',
    ];
    for (final path in writers) {
      final src = File(path).readAsStringSync();
      expect(src, contains('PdfTransmittal.cover'), reason: path);
      expect(src, contains('PdfTransmittal.pageFooter'), reason: path);
      expect(src, contains('writeSealedTemp'), reason: path);
    }
    final preview = File('lib/screens/pdf_preview_screen.dart').readAsStringSync();
    expect(preview, contains('PdfTransmittal.shareText'));
    expect(preview, isNot(contains('My Protocol Report')));
    final journal = File('lib/services/journal_export_service.dart').readAsStringSync();
    expect(journal, contains('Aegis_Doctor_Transmittal_'));
    expect(journal, isNot(contains('Xanadu_Summary_')));
  });

  test('Four Gates PDF section headers remain locked after the cover', () {
    final src = File('lib/services/pdf_generator_service.dart').readAsStringSync();
    const headers = [
      'FOUR GATES — VERDICT RECORDS',
      'WEEKLY STRATA — OVERLOAD / FAILURE / RATIFIED',
      'RATIFICATION RECORDS',
      'PENDING RE-TEST CONTRACTS',
      'DOCTRINE — TEMPORAL INTEGRITY OF FOUR GATES',
    ];
    var last = -1;
    for (final header in headers) {
      final at = src.indexOf(header);
      expect(at, greaterThan(last), reason: header);
      last = at;
    }
    expect(
      src.indexOf('PdfTransmittal.cover'),
      lessThan(src.indexOf('FOUR GATES — VERDICT RECORDS')),
    );
  });
}
