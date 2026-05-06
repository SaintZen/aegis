import 'package:anxiety_anchor/services/telemetry.dart';
import 'package:anxiety_anchor/widgets/dictionary_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  setUp(Telemetry.clear);
  tearDown(Telemetry.clear);

  testWidgets('DictionaryScreen renders title and emits telemetry', (tester) async {
    await pumpMaterialAppWithL10n(
      tester,
      home: const DictionaryScreen(),
    );

    expect(find.text('Dictionary'), findsOneWidget);
    expect(
      Telemetry.events.any((e) => e['event'] == 'dictionary_view'),
      isTrue,
    );
  });
}
