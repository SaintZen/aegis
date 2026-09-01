import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Locked marks for every Aegis PDF, including operator exports sent to a
/// clinician. Stays on this side of the HIPAA line: Aegis does not transmit
/// a medical record; the operator elects to send a technical export.
///
/// Do not claim HIPAA compliance. Do not use therapy verbs.
class PdfTransmittal {
  PdfTransmittal._();

  static const String title = 'TRANSMITTAL - NOT A MEDICAL RECORD';

  static const String banner =
      'AEGIS EXPORT - NOT A DOCTOR. NOT A MEDICAL RECORD. NOT A DIAGNOSIS.';

  static const String shareText =
      'Aegis technical export. Not a doctor. Not a medical record. Not a diagnosis.';

  static const String lineInstrument =
      'Aegis is an industrial somatic stabilization instrument.';

  static const String lineNotADoctor = 'Aegis is not a doctor.';

  static const String lineNotADevice = 'Aegis is not a medical device.';

  static const String lineNoAdvice =
      'This file does not diagnose, treat, or give medical advice.';

  static const String lineNotARecord =
      'This file is not a medical record and is not a substitute for professional care.';

  static const String lineElection =
      'The operator elected to produce this export. Sending it to a third party, '
      'including a clinician, is the operator\'s action - not a transmission by Aegis.';

  static const List<String> allOperatorFacing = [
    title,
    banner,
    shareText,
    lineInstrument,
    lineNotADoctor,
    lineNotADevice,
    lineNoAdvice,
    lineNotARecord,
    lineElection,
  ];

  /// Full cover block. Rendered once at the start of the document,
  /// before any audit / Four Gates / journal sections.
  static pw.Widget cover(pw.Font monoFont) {
    final body = pw.TextStyle(
      fontSize: 9,
      height: 1.35,
      color: PdfColors.black,
      font: monoFont,
    );
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8,
              color: PdfColors.black,
              font: monoFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(lineInstrument, style: body),
          pw.Text(lineNotADoctor, style: body),
          pw.Text(lineNotADevice, style: body),
          pw.SizedBox(height: 6),
          pw.Text(lineNoAdvice, style: body),
          pw.Text(lineNotARecord, style: body),
          pw.SizedBox(height: 6),
          pw.Text(lineElection, style: body),
        ],
      ),
    );
  }

  /// One-line stamp on every page so a clinician cannot miss it.
  static pw.Widget pageFooter(pw.Font monoFont) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        banner,
        style: pw.TextStyle(
          fontSize: 7,
          letterSpacing: 0.4,
          color: PdfColors.black,
          font: monoFont,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
}
