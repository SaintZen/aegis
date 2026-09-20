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
