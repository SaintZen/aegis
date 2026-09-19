/// Locked copy for the first-run Instrument Tour.
///
/// Compresses the Aegis operator manual Signal Flow and the Four Gates
/// doctrine paragraph. The tour names instruments. It does not interpret
/// the signal, run a protocol, or widen the Four Gates interception window.
///
/// Voice: Aegis instrument, third-person ("the operator", "the instrument").
/// Forbidden therapy verbs are not used: help, feelings, support, cope,
/// comfort, healing, kindness, self-care, gentle, soothe, validate.
class InstrumentTourCopy {
  InstrumentTourCopy._();

  static const String title = 'INSTRUMENT TOUR';

  static const String preambleLine1 =
      'Aegis is an Industrial Somatic Stabilization Instrument.';

  static const String preambleLine2 =
      'This briefing names the instruments. It does not interpret the signal.';

  static const String skipLabel = 'SKIP TOUR';

  static const String nextLabel = 'NEXT STATION';

  static const String enterLabel = 'ENTER BRIDGE';

  static const String stationIndexPrefix = 'STATION';

  static const List<InstrumentTourStation> stations = [
    InstrumentTourStation(
      id: 'bridge',
      name: 'BRIDGE',
      body:
          'The operational surface. Cold, symmetrical, stable. '
          'The operator\'s reference plane. The imagination does not rewrite it.',
    ),
    InstrumentTourStation(
      id: 'hollow',
      name: 'THE HOLLOW',
      body:
          'Additive. The 7th-sense container. Signal Input is preserved '
          'verbatim. It is a presence, not a tool.',
    ),
    InstrumentTourStation(
      id: 'vault',
      name: 'THE VAULT',
      body:
          'Non-ruminative containment. The Vault holds the signal without '
          'display or commentary. Hollow entries remain Somatic Signals.',
    ),
    InstrumentTourStation(
      id: 'void',
      name: 'THE VOID',
      body:
          'Subtractive purge. The Void is the only protocol that triggers '
          '[REDACTED/PURGED]. Status: CLEAR.',
    ),
    InstrumentTourStation(
      id: 'ledger',
      name: 'THE LEDGER',
      body:
          'The durable record. Monospaced. The imagination cannot rewrite it.',
    ),
    InstrumentTourStation(
      id: 'four_gates',
      name: 'FOUR GATES',
      body:
          'A temporal interceptor. It activates in the narrow interval '
          'between an operator assigning the label "failure" to an event '
          'and the imagination generating catastrophic projections. '
          'The instrument tests whether failure was structurally possible. '
          'If any precondition is absent, the event is classified as overload. '
          'The ledger output is the durable record.',
    ),
    InstrumentTourStation(
      id: 'scram',
      name: 'SCRAM',
      body:
          'Priority 0. Somatic override pathway. 1.25-second long press '
          'on the Monolith. Universal interrupt. Immediate drop into the Void. '
          'Named for the reactor emergency-shutdown: decisive and protective, '
          'never violent.',
    ),
  ];

  /// Every operator-facing string. Tests lock doctrine and voice.
  static List<String> get allOperatorFacing => <String>[
        title,
        preambleLine1,
        preambleLine2,
        skipLabel,
        nextLabel,
        enterLabel,
        for (final station in stations) ...[station.name, station.body],
      ];
}

class InstrumentTourStation {
  const InstrumentTourStation({
    required this.id,
    required this.name,
    required this.body,
  });

  final String id;
  final String name;
  final String body;
}
