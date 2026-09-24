import 'package:anxiety_anchor/scripts/kinetic_scripts.dart';
import 'package:anxiety_anchor/services/pdf_generator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kinetic protocol is three somatic reps', () {
    expect(kineticRepCount, 3);
    expect(kineticScripts.length, 4);
    for (final script in kineticScripts.values) {
      expect(script.sublist(1, 4), everyElement(contains('_rep.')));
    }
  });

  test('doctor PDF names the instrument, never a pose tally', () {
    expect(kineticInstrumentLabel('wall_push'), 'WALL PUSH');
    expect(kineticInstrumentLabel('somatic_shaking'), 'THE SHAKE');
    expect(kineticInstrumentLabel('muscle_clench'), 'ISOMETRIC');
    expect(kineticInstrumentLabel('pulse'), 'THE PULSE');
    expect(kineticInstrumentLabel('wall_push'), isNot(contains('x')));
    expect(kineticInstrumentLabel('wall_push'), isNot(contains('82')));
  });

  test('OVERRIDE never repeats the previous instrument', () {
    expect(kineticFieldDeck.length, 6);
    expect(kineticStealthDeck.length, 6);
    expect(kineticOptionDeck.length, 4);
    expect(kineticScripts.length, 4);
    expect(
      kineticOptionDeck.map((s) => s.id),
      isNot(contains('stealth_lobe')),
    );
    expect(
      kineticOptionDeck.map((s) => s.id),
      isNot(contains('hot_car')),
    );

    final locked = pickKineticOverride(
      previousId: 'wall_push',
      roll: (_) => kineticOptionDeck.indexWhere((s) => s.id == 'wall_push'),
    );
    expect(locked, isNot('wall_push'));
    expect(kineticOptionDeck.map((s) => s.id), contains(locked));
    expect(locked, isNot('hot_car'));

    expect(kineticInstrumentLabel('hot_car'), 'HOT CAR');
    expect(kineticInstrumentLabel('winter_subzero'), 'WINTER');
    expect(kineticInstrumentLabel('summer_heatwave'), 'HEATWAVE');
    expect(kineticInstrumentLabel('stall_reset'), 'STALL');
    expect(kineticInstrumentLabel('headphones_dark'), 'HEADPHONES');
    expect(kineticInstrumentLabel('sink_wash'), 'SINK');
    expect(isKineticProtocolTool('HOT CAR'), isTrue);
    expect(isKineticProtocolTool('HEATWAVE'), isTrue);
    expect(PdfGeneratorService.debugMapToProtocol('HOT CAR'), 'THE KINETIC');
    expect(PdfGeneratorService.debugMapToProtocol('HEADPHONES'), 'THE KINETIC');
    expect(kineticInstrumentLabel('stealth_lobe'), 'LOBE');
    expect(kineticInstrumentLabel('stealth_toes'), 'TOES');
    expect(kineticInstrumentLabel('stealth_jaw'), 'JAW');
    expect(isKineticStealthProtocol('stealth_lobe'), isTrue);
    expect(isKineticStealthProtocol('hot_car'), isFalse);
    for (final script in kineticFieldDeck) {
      expect(script.instructions.toLowerCase(), isNot(contains('clench the wheel')));
      expect(script.instructions.split(RegExp(r'\s+')).length, greaterThan(12));
    }
    expect(hotCarScript.instructions, contains('Hands off the wheel'));
    expect(headphonesDarkScript.instructions, contains('Cover the eyes'));

    final lowSig = pickKineticLowSig(
      previousId: 'stealth_lobe',
      roll: (_) => kineticStealthDeck.indexWhere((s) => s.id == 'stealth_lobe'),
    );
    expect(lowSig, isNot('stealth_lobe'));
    expect(kineticStealthDeck.map((s) => s.id), contains(lowSig));
  });

  test('audit protocol is THE KINETIC, not THE ANCHOR', () {
    expect(PdfGeneratorService.debugMapToProtocol('Kinetic'), 'THE KINETIC');
    expect(PdfGeneratorService.debugMapToProtocol('Wall Push'), 'THE KINETIC');
    expect(PdfGeneratorService.debugMapToProtocol('The Shake'), 'THE KINETIC');
    expect(PdfGeneratorService.debugMapToProtocol('Isometric'), 'THE KINETIC');
    expect(PdfGeneratorService.debugMapToProtocol('The Pulse'), 'THE KINETIC');
    expect(isKineticProtocolTool(kineticLedgerTool), isTrue);
    expect(PdfGeneratorService.debugMapToProtocol('Rescue Breath'), 'THE ANCHOR');
    expect(PdfGeneratorService.debugMapToProtocol('The Vault'), 'THE VAULT');
  });
}
