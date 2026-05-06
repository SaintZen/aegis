class TacticalBriefing {
  const TacticalBriefing({
    required this.title,
    required this.mechanism,
    required this.tacticalNugget,
  });

  final String title;
  final String mechanism;
  final String tacticalNugget;

  static const List<TacticalBriefing> entries = [
    TacticalBriefing(
      title: 'The Somatic Reset (The Frost Screen)',
      mechanism: 'Sensory Gating & Cross-Modal Grounding',
      tacticalNugget:
          "The 'Scraping' sound you hear when moving your finger across the "
          'Frost Screen is intentional Somatic Friction. By creating a physical '
          "and auditory 'mismatch' with the smooth glass of your phone, we "
          "force the brain to stop 'floating' in a panic loop and reconnect "
          'with the immediate physical reality of your hand. It turns your '
          'screen into a physical anchor.',
    ),
    TacticalBriefing(
      title: 'The Auditory Anchor (ASMR & Resonance)',
      mechanism: 'Auditory Brainstem Response (ABR)',
      tacticalNugget:
          'High-arousal anxiety makes you hypersensitive to high-pitched, '
          "'staccato' sounds (scanning for threats). Our ASMR layers use "
          'Low-Frequency Resonance to stimulate the Vagus Nerve. This '
          "signals the body to initiate a 'Biological Brake,' manually "
          'lowering your heart rate and dampening the acoustic startle response.',
    ),
    TacticalBriefing(
      title: 'The Decompression Buffer (The Vault 5-Sec Delay)',
      mechanism: 'Parasympathetic Pacing',
      tacticalNugget:
          'The theory: The 5-second delay before the Vault opens acts as a '
          'Neurological Air-Lock. Just as a diver must decompress to avoid the '
          '\'bends,\' a panicked mind may need a transition period. Use these 5 '
          'seconds for one "Box Breath." Users have reported that when the vault '
          'opens, they feel more receptive to visual and auditory grounding.',
    ),
    TacticalBriefing(
      title: 'The Administrative Shield (Advocacy & Paper Trail)',
      mechanism: 'Cognitive Offloading & Contemporaneous Documentation',
      tacticalNugget:
          "The premise: Panic may cause 'Executive Function Brownout'—the "
          'inability to find the right words. Templates may act as a prosthetic '
          'prefrontal cortex. Writing a "Recap Email" immediately after a '
          'conflict creates a contemporaneous record. In disputes, the party '
          'with the most consistent, dated documentation often has an advantage.',
    ),
  ];
}
