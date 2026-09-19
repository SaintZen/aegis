import 'package:anxiety_anchor/data/advocacy_support_links.dart';
import 'package:anxiety_anchor/screens/advocacy_screen.dart';
import 'package:anxiety_anchor/screens/fiduciary_truth_screen.dart';
import 'package:anxiety_anchor/screens/rules_of_engagement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets(
      'Advocacy screen matches the Bridge tile and keeps the directory sealed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMaterialAppWithL10n(
      tester,
      home: const AdvocacyScreen(),
      routes: {
        '/fiduciary-truth': (_) => const FiduciaryTruthScreen(),
        '/rules-of-engagement': (_) => const RulesOfEngagementScreen(),
      },
    );

    expect(find.text('ADVOCACY'), findsOneWidget);
    expect(find.text('Shield'), findsNothing);
    expect(find.text('External Routing'), findsOneWidget);
    expect(find.text('FILE COMPLAINT'), findsOneWidget);
    expect(find.text('988 Suicide & Crisis Lifeline'), findsOneWidget);
    expect(find.text('Rules of Engagement'), findsOneWidget);
    expect(find.text('State DOE Complaint Portal'), findsNothing);
    expect(find.textContaining('example.org'), findsNothing);

    await tester.ensureVisible(find.text('Open Rules'));
    await tester.tap(find.text('Open Rules'));
    await tester.pumpAndSettle();
    expect(find.byType(RulesOfEngagementScreen), findsOneWidget);
  });

  testWidgets('Read the Details opens fiduciary truth', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMaterialAppWithL10n(
      tester,
      home: const AdvocacyScreen(),
      routes: {
        '/fiduciary-truth': (_) => const FiduciaryTruthScreen(),
        '/rules-of-engagement': (_) => const RulesOfEngagementScreen(),
      },
    );

    await tester.ensureVisible(find.text('Read the Details'));
    await tester.tap(find.text('Read the Details'));
    await tester.pumpAndSettle();
    expect(find.byType(FiduciaryTruthScreen), findsOneWidget);
  });
}
