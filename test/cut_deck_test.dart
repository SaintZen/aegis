import 'package:anxiety_anchor/scripts/cut_deck.dart';
import 'package:anxiety_anchor/widgets/cut_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CutMemory.lastId = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  test('CUT deck is loop-break domains, not elected instruments', () {
    expect(
      cutDeck.map((t) => t.id).toList(),
      ['breath', 'vista', 'frost', 'voice'],
    );
    expect(cutDeck.map((t) => t.route), isNot(contains('/scram')));
    expect(cutDeck.map((t) => t.route), isNot(contains('/wormhole')));
    expect(cutDeck.map((t) => t.route), isNot(contains('/four-gates')));
    expect(cutDeck.map((t) => t.route), isNot(contains('/vault')));
    expect(cutDeck.map((t) => t.route), isNot(contains('/hollow')));
    expect(cutDeck.map((t) => t.id), isNot(contains('kinetic')));
  });

  test('CUT never repeats the domain that is not landing', () {
    final locked = pickCut(
      previousId: 'frost',
      roll: (_) => cutDeck.indexWhere((t) => t.id == 'frost'),
    );
    expect(locked.id, isNot('frost'));
    expect(cutDeck.map((t) => t.id), contains(locked.id));
  });

  testWidgets('CUT from frost opens a different instrument', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: Center(child: CutControl(currentId: 'frost')),
        ),
        routes: {
          '/rescue-breathing': (_) => const Scaffold(body: Text('BREATH')),
          '/island': (_) => const Scaffold(body: Text('ISLAND')),
          '/scraper': (_) => const Scaffold(body: Text('FROST')),
          '/hollow': (_) => const Scaffold(body: Text('HOLLOW')),
          '/bridge': (_) => const Scaffold(body: Text('BRIDGE')),
        },
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('aegis_cut')), findsOneWidget);
    expect(find.text('[ CUT ]'), findsOneWidget);

    await tester.tap(find.byKey(const Key('aegis_cut')));
    await tester.pumpAndSettle();

    expect(find.text('FROST'), findsNothing);
    expect(find.text('HOLLOW'), findsNothing);
    expect(find.text('BRIDGE'), findsNothing);
    expect(
      find.text('BREATH').evaluate().isNotEmpty ||
          find.text('ISLAND').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
