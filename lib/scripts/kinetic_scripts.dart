class KineticScript {
  const KineticScript({
    required this.id,
    required this.title,
    required this.command,
    required this.description,
    required this.instructions,
    required this.audioAsset,
    required this.hapticPattern,
  });

  final String id;
  final String title;
  final String command;
  final String description;
  final String instructions;
  final String audioAsset;
  final KineticHapticPattern hapticPattern;

  String get exerciseKey => id;
}

enum KineticHapticPattern {
  continuousPush,
  rapidShake,
  continuousSqueeze,
}

const KineticScript wallPushScript = KineticScript(
  id: 'wall_push',
  title: 'Wall Push',
  command: 'Push... hold... and release.',
  description: 'Grounding push against a wall',
  instructions:
      'Find a flat wall and push against it as if you are trying to move the '
      'entire building away from you.',
  audioAsset: 'audio/kinetic_wall_push.mp3',
  hapticPattern: KineticHapticPattern.continuousPush,
);

const KineticScript somaticShakingScript = KineticScript(
  id: 'somatic_shaking',
  title: 'The Shake',
  command: 'Shake it out. Faster. And stop.',
  description: 'Rapid shaking to discharge energy',
  instructions:
      'Relax your arms and shake your hands rapidly, like you are flicking '
      'water off your fingertips.',
  audioAsset: 'audio/kinetic_somatic_shaking.mp3',
  hapticPattern: KineticHapticPattern.rapidShake,
);

const KineticScript muscleClenchScript = KineticScript(
  id: 'muscle_clench',
  title: 'Isometric',
  command: 'Pull... 3, 2, 1... relax.',
  description: 'Isometric pull to stabilize',
  instructions:
      'Interlock your fingers in front of your chest and pull your hands '
      'apart as hard as you can without letting go.',
  audioAsset: 'audio/kinetic_muscle_clench.mp3',
  hapticPattern: KineticHapticPattern.continuousSqueeze,
);

const KineticScript pulseScript = KineticScript(
  id: 'pulse',
  title: 'The Pulse',
  command: 'One. Two. Three. Four.',
  description: 'Rhythmic tapping to entrain movement',
  instructions:
      'Tap your feet or fingers on a hard surface to match the rhythm of the '
      'count.',
  audioAsset: 'audio/kinetic_pulse.mp3',
  hapticPattern: KineticHapticPattern.rapidShake,
);

const List<KineticScript> kineticScriptCards = [
  wallPushScript,
  somaticShakingScript,
  muscleClenchScript,
  pulseScript,
];

final Map<String, List<String>> kineticScripts = {
  'wall_push': [
    'audio/kinetic/wall_push_primer.wav',
    'audio/kinetic/wall_push_rep.wav',
    'audio/kinetic/wall_push_rep.wav',
    'audio/kinetic/wall_push_rep.wav',
    'audio/exit.mp3',
  ],
  'somatic_shaking': [
    'audio/kinetic/shake_primer.wav',
    'audio/kinetic/shake_rep.wav',
    'audio/kinetic/shake_rep.wav',
    'audio/kinetic/shake_rep.wav',
    'audio/exit.mp3',
  ],
  'muscle_clench': [
    'audio/kinetic/iso_primer.wav',
    'audio/kinetic/iso_rep.wav',
    'audio/kinetic/iso_rep.wav',
    'audio/kinetic/iso_rep.wav',
    'audio/exit.mp3',
  ],
  'pulse': [
    'audio/kinetic/pulse_primer.wav',
    'audio/kinetic/pulse_rep.wav',
    'audio/kinetic/pulse_rep.wav',
    'audio/kinetic/pulse_rep.wav',
    'audio/exit.mp3',
  ],
};
