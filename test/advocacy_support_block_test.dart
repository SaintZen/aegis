import 'package:anxiety_anchor/data/advocacy_support_links.dart';
import 'package:anxiety_anchor/l10n/app_localizations.dart';
import 'package:anxiety_anchor/services/telemetry.dart';
import 'package:anxiety_anchor/widgets/advocacy_support_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/launch_helper_mock.dart';

void main() {
  setUp(() {
    LaunchHelperMock.clear();
    Telemetry.clear();
  });

  tearDown(() {
    LaunchHelperMock.clear();
    Telemetry.clear();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  testWidgets('tapping a tile opens its URL and emits telemetry',
      (tester) async {
    await tester.pumpWidget(
      wrap(AdvocacySupportBlock(
        launchCallback: LaunchHelperMock.launchUrlHelper,
      )),
    );
    await tester.pumpAndSettle();

    final tile = find.byType(ListTile).first;
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(LaunchHelperMock.opened, isNotEmpty);
    expect(
      LaunchHelperMock.opened.first.startsWith('https://'),
      isTrue,
      reason:
          'First tile must open an https:// URL (got ${LaunchHelperMock.opened.first})',
    );

    final expectedId = shieldDirectoryLiveEntries.first.id;
    expect(
      Telemetry.events.any(
        (e) =>
            e['event'] == 'advocacy_support_link_tap' &&
            (e['payload'] as Map)['link_id'] == expectedId &&
            (e['payload'] as Map)['action'] == 'open',
      ),
      isTrue,
      reason: 'Expected open-action telemetry for id=$expectedId',
    );
  });

  testWidgets('category chips filter the visible rows', (tester) async {
    await tester.pumpWidget(
      wrap(AdvocacySupportBlock(
        launchCallback: LaunchHelperMock.launchUrlHelper,
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('VA Facility Locator'), findsOneWidget);

    final schoolChip = find.widgetWithText(
      InkWell,
      advocacySupportCategoryLabels['education_school']!,
    );
    expect(schoolChip, findsOneWidget);
    await tester.tap(schoolChip);
    await tester.pumpAndSettle();

    expect(find.text('VA Facility Locator'), findsNothing);
    expect(find.text('Parent Center Hub'), findsOneWidget);
  });

  testWidgets('search narrows to matching titles', (tester) async {
    await tester.pumpWidget(
      wrap(AdvocacySupportBlock(
        launchCallback: LaunchHelperMock.launchUrlHelper,
      )),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'wrights');
    await tester.pumpAndSettle();

    expect(find.text('Wrightslaw'), findsOneWidget);
    expect(find.text('VA Facility Locator'), findsNothing);
  });
}
