import 'package:anxiety_anchor/models/audit_cue.dart';

enum HapticProfile {
  heavy40Hz,
  staccato150ms,
  linearRamp,
  syncThrum,
}

class HapticRampSegment {
  const HapticRampSegment({
    required this.start,
    required this.end,
    this.startIntensity = 0.2,
    this.endIntensity = 1.0,
  });

  final Duration start;
  final Duration end;
  final double startIntensity;
  final double endIntensity;
}

class SomaticSequence {
  const SomaticSequence({
    required this.id,
    required this.audioAsset,
    required this.hapticProfile,
    this.auditCues = const [],
    this.rampSegments = const [],
  });

  final String id;
  final String audioAsset;
  final HapticProfile hapticProfile;
  final List<AuditCue> auditCues;
  final List<HapticRampSegment> rampSegments;
}
