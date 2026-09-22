import 'dart:math';

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

const KineticScript hotCarScript = KineticScript(
  id: 'hot_car',
  title: 'HOT CAR',
  command: 'Vent. Clench. Release.',
  description: 'Cabin heat dump plus wheel isometric',
  instructions:
      'Aim the A/C at the inner wrists and the side of the neck. '
      'Both hands clench the wheel, hold, release. Repeat.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousSqueeze,
);

const KineticScript winterSubzeroScript = KineticScript(
  id: 'winter_subzero',
  title: 'WINTER',
  command: 'Heels. Vent. Hold.',
  description: 'Floorboard press plus cabin heat transfer',
  instructions:
      'Heels press into the floorboards. Hands on the defroster vent. '
      'Stay in the cabin. Do not step into open cold.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousPush,
);

const KineticScript summerHeatwaveScript = KineticScript(
  id: 'summer_heatwave',
  title: 'HEATWAVE',
  command: 'Wrist. Exhale. Hold.',
  description: 'Cool metal on the wrists plus pursed-lip dump',
  instructions:
      'Press a cold metal or condensation surface to the inner wrists. '
      'Slow pursed-lip exhale through the teeth. Stay in shade or airflow.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.rapidShake,
);

const KineticScript stallResetScript = KineticScript(
  id: 'stall_reset',
  title: 'STALL',
  command: 'Palms. Heels. Still.',
  description: 'Silent isometric with zero outward motion',
  instructions:
      'Palms press together at the sternum. Heels press the floor. '
      'No sound. No visible movement.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousSqueeze,
);

const KineticScript headphonesDarkScript = KineticScript(
  id: 'headphones_dark',
  title: 'HEADPHONES',
  command: 'Cover. Cut. Hold.',
  description: 'Audio and visual cut using the engine bed',
  instructions:
      'Eyes covered. Engine thrum only. Cut incoming voice and light.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousPush,
);

const KineticScript sinkWashScript = KineticScript(
  id: 'sink_wash',
  title: 'SINK',
  command: 'Wrist. Neck. Stop.',
  description: 'Cold-water thermal dump at a restroom sink',
  instructions:
      'Cold water on the inner wrists, then the back of the neck. '
      'Thirty seconds. Stop.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.rapidShake,
);

const List<KineticScript> kineticFieldDeck = [
  hotCarScript,
  winterSubzeroScript,
  summerHeatwaveScript,
  stallResetScript,
  headphonesDarkScript,
  sinkWashScript,
];

/// Menu instruments plus field protocols. OVERRIDE draws from this deck.
/// Temporary landing is the win. SWAP if the current instrument does not.
List<KineticScript> get kineticOptionDeck => <KineticScript>[
      ...kineticScriptCards,
      ...kineticFieldDeck,
    ];

KineticScript? kineticScriptById(String id) {
  for (final script in kineticOptionDeck) {
    if (script.id == id) return script;
  }
  return null;
}

/// Next instrument for OVERRIDE / SWAP. Never repeats [previousId] when
/// the deck has more than one entry.
String pickKineticOverride({
  String? previousId,
  int Function(int max)? roll,
}) {
  final ids = kineticOptionDeck.map((s) => s.id).toList(growable: false);
  final next = roll ?? Random().nextInt;
  if (ids.isEmpty) return wallPushScript.id;
  var pick = ids[next(ids.length)];
  if (previousId == null || ids.length == 1) return pick;
  var guard = 0;
  while (pick == previousId && guard < 12) {
    pick = ids[next(ids.length)];
    guard += 1;
  }
  if (pick == previousId) {
    pick = ids.firstWhere((id) => id != previousId);
  }
  return pick;
}

/// Canonical Aegis-log tool name. Protocol maps to THE KINETIC.
const String kineticLedgerTool = 'Kinetic';

/// Each Kinetic instrument runs this many somatic reps.
/// One pass does not break the loop.
const int kineticRepCount = 3;

/// Doctor-PDF Signal Input: instrument name only. No counts, no pose tally.
String kineticInstrumentLabel(String exerciseKey) {
  switch (exerciseKey) {
    case 'wall_push':
    case 'wall_pushups':
      return 'WALL PUSH';
    case 'somatic_shaking':
    case 'tense_release':
      return 'THE SHAKE';
    case 'muscle_clench':
      return 'ISOMETRIC';
    case 'pulse':
      return 'THE PULSE';
    case 'hot_car':
      return 'HOT CAR';
    case 'winter_subzero':
      return 'WINTER';
    case 'summer_heatwave':
      return 'HEATWAVE';
    case 'stall_reset':
      return 'STALL';
    case 'headphones_dark':
      return 'HEADPHONES';
    case 'sink_wash':
      return 'SINK';
    default:
      return exerciseKey.replaceAll('_', ' ').toUpperCase();
  }
}

/// True when an Aegis-log toolName is a Kinetic instrument.
bool isKineticProtocolTool(String toolName) {
  final lower = toolName.toLowerCase();
  return lower.contains('kinetic') ||
      lower.contains('wall push') ||
      lower.contains('the shake') ||
      lower.contains('isometric') ||
      lower.contains('the pulse') ||
      lower.contains('somatic_shaking') ||
      lower.contains('wall_push') ||
      lower.contains('hot car') ||
      lower.contains('heatwave') ||
      lower.contains('stall') ||
      lower.contains('headphones') ||
      lower.contains('sink') ||
      lower.contains('winter') ||
      lower == 'pulse';
}

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
