class AuditCue {
  const AuditCue({
    required this.label,
    required this.at,
    required this.hold,
    this.pauseAudio = false,
  });

  final String label;
  final Duration at;
  final Duration hold;
  final bool pauseAudio;
}
