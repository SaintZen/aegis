import 'package:anxiety_anchor/lifelines/not_today_screen.dart';
import 'package:anxiety_anchor/services/boundary_identity_service.dart';
import 'package:anxiety_anchor/widgets/not_today_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('injectScript fills recipient and operator name', () {
    const template =
        "Hi [Name],\n\nI need to step away today.\n\nBest,\n[Your Name]";
    final out = NotTodaySheet.injectScript(template, 'Alex', 'Shawn');
    expect(out, contains('Hi Alex'));
    expect(out, contains('Shawn'));
    expect(out.contains('[Name]'), isFalse);
    expect(out.contains('[Your Name]'), isFalse);
  });

  test('BoundaryIdentityService stores the operator name', () async {
    expect(await BoundaryIdentityService.getDisplayName(), '');
    await BoundaryIdentityService.setDisplayName('  Shawn  ');
    expect(await BoundaryIdentityService.getDisplayName(), 'Shawn');
  });

  testWidgets('quick scripts expose name fields and persist the signature',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMaterialAppWithL10n(
      tester,
      home: const NotTodayScreen(),
    );

    await tester.tap(find.text('Quick refusal scripts'));
    await tester.pumpAndSettle();

    expect(find.text('— not set in Settings —'), findsNothing);
    expect(find.byKey(const Key('not_today_operator_name')), findsOneWidget);
    expect(find.byKey(const Key('not_today_recipient')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('not_today_operator_name')),
      'Shawn',
    );
    await tester.enterText(
      find.byKey(const Key('not_today_recipient')),
      'Alex',
    );
    await tester.pump();

    expect(await BoundaryIdentityService.getDisplayName(), 'Shawn');

    await tester.tap(find.text('Hi [Name],').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Hi Alex'), findsWidgets);
    expect(find.textContaining('Shawn'), findsWidgets);
    expect(find.text('COPY'), findsOneWidget);
  });
}
