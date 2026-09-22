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

/// Pocket protocols. They land on a bus or in a meeting with the
/// instrument closed. OVERRIDE does not draw from this deck — a phone
/// rumble would break stealth.
const KineticScript lobeScript = KineticScript(
  id: 'stealth_lobe',
  title: 'LOBE',
  command: 'Pinch. Hold. Release.',
  description: 'Earlobe hold with zero outward motion',
  instructions:
      'Left earlobe between thumb and finger. Pinch, hold, release. '
      'Three holds. No sound.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousSqueeze,
);

const KineticScript toesScript = KineticScript(
  id: 'stealth_toes',
  title: 'TOES',
  command: 'Clench. Hold. Release.',
  description: 'Shoe clench under a seat',
  instructions:
      'Toes clench inside the shoe. Hold. Release. Seat stays still.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousSqueeze,
);

const KineticScript jawScript = KineticScript(
  id: 'stealth_jaw',
  title: 'JAW',
  command: 'Tongue. Slack. Hold.',
  description: 'Tongue-to-palate hold, jaw slack',
  instructions:
      'Tongue to the roof of the mouth. Jaw slack. Teeth do not meet.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousPush,
);

const KineticScript fistScript = KineticScript(
  id: 'stealth_fist',
  title: 'FIST',
  command: 'Squeeze. Hold. Open.',
  description: 'Hidden isometric in a pocket or under a table',
  instructions:
      'One fist in the pocket or under the table. Squeeze, hold, open. '
      'No visible motion.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousSqueeze,
);

const KineticScript heelScript = KineticScript(
  id: 'stealth_heel',
  title: 'HEEL',
  command: 'Press. Hold. Release.',
  description: 'Seated heel press into the floor',
  instructions:
      'One heel presses the floor. Hold. Release. Chair does not move.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousPush,
);

const KineticScript thumbScript = KineticScript(
  id: 'stealth_thumb',
  title: 'THUMB',
  command: 'Press. Hold. Open.',
  description: 'Hidden thumb press into the opposite palm',
  instructions:
      'Thumb presses the opposite palm. Hidden. Three holds.',
  audioAsset: '',
  hapticPattern: KineticHapticPattern.continuousSqueeze,
);

const List<KineticScript> kineticStealthDeck = [
  lobeScript,
  toesScript,
  jawScript,
  fistScript,
  heelScript,
  thumbScript,
];

/// Menu instruments plus field protocols. OVERRIDE draws from this deck.
/// Temporary landing is the win. SWAP if the current instrument does not.
/// Stealth / poor-man cards stay out — they land with the phone down.
List<KineticScript> get kineticOptionDeck => <KineticScript>[
      ...kineticScriptCards,
      ...kineticFieldDeck,
    ];

KineticScript? kineticScriptById(String id) {
  for (final script in kineticOptionDeck) {
    if (script.id == id) return script;
  }
  for (final script in kineticStealthDeck) {
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
    case 'stealth_lobe':
      return 'LOBE';
    case 'stealth_toes':
      return 'TOES';
    case 'stealth_jaw':
      return 'JAW';
    case 'stealth_fist':
      return 'FIST';
    case 'stealth_heel':
      return 'HEEL';
    case 'stealth_thumb':
      return 'THUMB';
    default:
      return exerciseKey.replaceAll('_', ' ').toUpperCase();
  }
}

bool isKineticStealthProtocol(String exerciseKey) {
  for (final script in kineticStealthDeck) {
    if (script.id == exerciseKey) return true;
  }
  return false;
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
