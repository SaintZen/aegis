import 'dart:math';

/// Cross-instrument loop cut. Sensory domains only: Breath, Vista,
/// Frost, Voice. If ice scrape is not landing, the next draw is Breath
/// or Vista — not another scrape, not Kinetic, not a write-in utility.
///
/// Not in this deck: Kinetic, Bridge, Hollow, Vault, Void, SCRAM,
/// Four Gates, Not Today, Advocacy. Those stay elected or written.
class CutTarget {
  const CutTarget({
    required this.id,
    required this.route,
    this.arguments,
  });

  final String id;
  final String route;
  final Object? arguments;
}

const CutTarget breathCut = CutTarget(
  id: 'breath',
  route: '/rescue-breathing',
);

const CutTarget vistaCut = CutTarget(
  id: 'vista',
  route: '/island',
  arguments: 'vista',
);

const CutTarget frostCut = CutTarget(
  id: 'frost',
  route: '/scraper',
);

const CutTarget voiceCut = CutTarget(
  id: 'voice',
  route: '/island',
  arguments: 'voice',
);

const List<CutTarget> cutDeck = [
  breathCut,
  vistaCut,
  frostCut,
  voiceCut,
];

CutTarget? cutTargetById(String id) {
  for (final target in cutDeck) {
    if (target.id == id) return target;
  }
  return null;
}

/// Next domain. Never repeats [previousId] when the deck has more than
/// one entry.
CutTarget pickCut({
  String? previousId,
  int Function(int max)? roll,
}) {
  final ids = cutDeck.map((t) => t.id).toList(growable: false);
  final next = roll ?? Random().nextInt;
  if (ids.isEmpty) return breathCut;
  var pick = ids[next(ids.length)];
  if (previousId != null && ids.length > 1) {
    var guard = 0;
    while (pick == previousId && guard < 12) {
      pick = ids[next(ids.length)];
      guard += 1;
    }
    if (pick == previousId) {
      pick = ids.firstWhere((id) => id != previousId);
    }
  }
  return cutTargetById(pick) ?? breathCut;
}
