import 'package:anxiety_anchor/lifelines/not_today_screen.dart';
import 'package:anxiety_anchor/screens/advocacy_screen.dart';
import 'package:anxiety_anchor/screens/bridge_screen.dart';
import 'package:anxiety_anchor/screens/four_gates_screen.dart';
import 'package:anxiety_anchor/screens/resources_screen.dart';
import 'package:anxiety_anchor/screens/scram_screen.dart';
import 'package:anxiety_anchor/screens/sonic_pharmacy.dart';
import 'package:anxiety_anchor/services/telemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

/// Route smoke tests for Bridge outlet rows (tap) and named-route entry (deep-link style).
/// Run: `flutter test test/bridge_outlet_routes_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> popTopRoute(WidgetTester tester) async {
    final state = tester.state<NavigatorState>(
      find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byType(Navigator),
      ),
    );
    state.pop();
    await tester.pumpAndSettle();
  }

  group('Bridge monolith', () {
    testWidgets('shows SCRAM / 1.25s HOLD, never CHECKPOINT SAVED or KILL SWITCH',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMaterialAppWithL10n(
        tester,
        home: const BridgeScreen(),
      );

      expect(find.text('SCRAM'), findsOneWidget);
      expect(find.text('1.25s HOLD'), findsOneWidget);
      expect(find.text('CHECKPOINT SAVED'), findsNothing);
      expect(find.textContaining('KILL SWITCH'), findsNothing);
      expect(find.text('Continue from here'), findsNothing);
    });

    testWidgets('MAINTENANCE / LEDGER stays inside its outlet box',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMaterialAppWithL10n(
        tester,
        home: const BridgeScreen(),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('MAINTENANCE'), findsOneWidget);
      expect(find.textContaining('LEDGER'), findsOneWidget);

      final label = find.textContaining('MAINTENANCE');
      final textBox = tester.getRect(label);
      final outlet = tester.getRect(
        find.ancestor(of: label, matching: find.byType(InkWell)).first,
      );
      expect(textBox.left, greaterThanOrEqualTo(outlet.left));
      expect(textBox.right, lessThanOrEqualTo(outlet.right + 0.5));
      expect(textBox.top, greaterThanOrEqualTo(outlet.top));
      expect(textBox.bottom, lessThanOrEqualTo(outlet.bottom + 0.5));
    });

    testWidgets('1.25s hold opens /scram blank field, never /wormhole',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMaterialAppWithL10n(
        tester,
        home: const BridgeScreen(),
        routes: {
          '/scram': (_) => ScramScreen(
                blankDuration: const Duration(milliseconds: 80),
                logLedgerEntry: ({
                  required String type,
                  required String content,
                }) async {},
                haltVoice: () async {},
              ),
        },
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('SCRAM')),
      );
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();

      expect(find.byType(ScramScreen), findsOneWidget);
      expect(find.byType(BridgeScreen), findsOneWidget);
      await gesture.up();
    });
  });

  group('Bridge navigation', () {
    testWidgets('rows push /not-today, /pharmacy, /resources', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMaterialAppWithL10n(
        tester,
        home: const BridgeScreen(),
        routes: {
          '/not-today': (_) => const NotTodayScreen(),
          '/pharmacy': (_) => const SonicPharmacyScreen(),
          '/resources': (_) => const ResourcesScreen(),
          '/advocacy': (_) => const AdvocacyScreen(),
        },
      );

      await tester.tap(find.text('NOT TODAY'));
      await tester.pumpAndSettle();
      expect(find.byType(NotTodayScreen), findsOneWidget);
      await popTopRoute(tester);

      await tester.tap(find.text('ASMR'));
      await tester.pumpAndSettle();
      expect(find.byType(SonicPharmacyScreen), findsOneWidget);
      await popTopRoute(tester);

      await tester.tap(find.text('DICTIONARY'));
      await tester.pumpAndSettle();
      expect(find.byType(ResourcesScreen), findsOneWidget);
      await popTopRoute(tester);
    });

    testWidgets('ADVOCACY row pushes /advocacy route', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMaterialAppWithL10n(
        tester,
        home: const BridgeScreen(),
        routes: {
          '/advocacy': (_) => const AdvocacyScreen(),
        },
      );

      await tester.tap(find.text('ADVOCACY'));
      await tester.pumpAndSettle();
      expect(find.byType(AdvocacyScreen), findsOneWidget);
    });

    testWidgets(
        'FOUR GATES row pushes /four-gates and emits four_gates_tile_open',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      Telemetry.clear();
      addTearDown(Telemetry.clear);

      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMaterialAppWithL10n(
        tester,
        home: const BridgeScreen(),
        routes: {
          '/four-gates': (_) => const FourGatesScreen(),
        },
      );

      expect(find.text('FOUR GATES'), findsOneWidget);

      await tester.tap(find.text('FOUR GATES'));
      await tester.pumpAndSettle();

      expect(find.byType(FourGatesScreen), findsOneWidget);
      expect(
        Telemetry.events.any((e) => e['event'] == 'four_gates_tile_open'),
        isTrue,
        reason: 'Tapping the FOUR GATES outlet must emit '
            'four_gates_tile_open telemetry.',
      );
    });
  });

  group('Named routes (deep-link style)', () {
    testWidgets('/not-today', (tester) async {
      await pumpMaterialAppWithL10n(
        tester,
        initialRoute: '/not-today',
        routes: {
          '/not-today': (_) => const NotTodayScreen(),
        },
      );
      expect(find.byType(NotTodayScreen), findsOneWidget);
    });

    testWidgets('/pharmacy', (tester) async {
      await pumpMaterialAppWithL10n(
        tester,
        initialRoute: '/pharmacy',
        routes: {
          '/pharmacy': (_) => const SonicPharmacyScreen(),
        },
      );
      expect(find.text('ASMR PHARMACY'), findsOneWidget);
    });

    testWidgets('/resources', (tester) async {
      await pumpMaterialAppWithL10n(
        tester,
        initialRoute: '/resources',
        routes: {
          '/resources': (_) => const ResourcesScreen(),
        },
      );
      expect(find.text('AEGIS DEFINITIONS'), findsOneWidget);
    });

    testWidgets('/advocacy', (tester) async {
      await pumpMaterialAppWithL10n(
        tester,
        initialRoute: '/advocacy',
        routes: {
          '/advocacy': (_) => const AdvocacyScreen(),
        },
      );
      expect(find.byType(AdvocacyScreen), findsOneWidget);
    });
  });

  group('ResourcesScreen', () {
    testWidgets('renders with l10n (use pumpMaterialAppWithL10n, not pumpApp)', (tester) async {
      await pumpMaterialAppWithL10n(
        tester,
        home: const ResourcesScreen(),
      );
      expect(find.text('AEGIS DEFINITIONS'), findsOneWidget);
    });
  });
}
