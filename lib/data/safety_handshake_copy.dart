/// Locked copy for the Safety Handshake entry gate.
///
/// Canonical backlog item: plain-English "Not a Doctor" entry gate.
/// Used by [SafetyGateScreen] and the Calibration re-read dialog so the
/// two surfaces cannot drift.
///
/// Voice: Aegis instrument, third-person where possible. Legal acceptance
/// remains first-person on the checkbox (operator-direct by spec).
/// Forbidden therapy verbs are not used: help, feelings, support, cope,
/// comfort, healing, kindness, self-care, gentle, soothe, validate.
class SafetyHandshakeCopy {
  SafetyHandshakeCopy._();

  static const String title = 'SAFETY HANDSHAKE';

  static const String lineInstrument =
      'Aegis is an industrial somatic stabilization instrument.';

  static const String lineNotADoctor = 'Aegis is not a doctor.';

  static const String lineNotADevice = 'Aegis is not a medical device.';

  static const String lineNoAdvice =
      'Aegis does not diagnose, treat, or give medical advice.';

  static const String lineNoReplacement =
      'Aegis does not replace professional care.';

  static const String lineCrisis =
      'If a crisis is in progress, contact emergency services immediately.';

  static const String lineFullLegal =
      'Full legal text: Bridge → Full Disclaimer.';

  static const String crisisLinesLabel = 'CRISIS LINES';

  static const String sensoryHeading = 'SENSORY CAUTIONS';

  static const String frostCaution =
      'The Frost: use caution with cold exposure if circulatory or skin sensitivity is present.';

  static const String hollowCaution =
      'The Hollow: keep haptic intensity at a tolerable level.';

  static const String checkboxLabel =
      'I understand Aegis is not a doctor and is not medical treatment.';

  static const String enterLabel = 'ENTER';

  static const String rereadLabel = 'Re-read Safety Handshake';

  /// Every operator-facing string in this handshake. Used by tests to
  /// assert doctrine (no therapy verbs; "Not a Doctor" present).
  static const List<String> allOperatorFacing = [
    title,
    lineInstrument,
    lineNotADoctor,
    lineNotADevice,
    lineNoAdvice,
    lineNoReplacement,
    lineCrisis,
    lineFullLegal,
    crisisLinesLabel,
    sensoryHeading,
    frostCaution,
    hollowCaution,
    checkboxLabel,
    enterLabel,
    rereadLabel,
  ];
}
