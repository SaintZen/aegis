import 'package:anxiety_anchor/screens/scram_screen.dart';
import 'package:anxiety_anchor/screens/wormhole_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('blank field is ninety seconds — midpoint of 1–2 minutes', () {
    expect(ScramScreen.defaultBlankDuration, const Duration(seconds: 90));
    expect(ScramScreen.ledgerType, 'SCRAM');
    expect(ScramScreen.exitInk.r, greaterThan(0.85));
  });

  testWidgets('SCRAM is a blank field, not the Void', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? loggedType;
    String? loggedContent;
    var halted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ScramScreen(
                        blankDuration: const Duration(milliseconds: 80),
                        logLedgerEntry: ({
                          required String type,
                          required String content,
                        }) async {
                          loggedType = type;
                          loggedContent = content;
                        },
                        haltVoice: () async {
                          halted = true;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('ARM'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('ARM'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ScramScreen), findsOneWidget);
    expect(find.byType(WormholeScreen), findsNothing);
    expect(find.text(ScramScreen.exitLabel), findsOneWidget);
    expect(find.textContaining('VOID'), findsNothing);
    expect(find.textContaining('PURGE'), findsNothing);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(ScramScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, const Color(0xFF000000));

    expect(loggedType, 'SCRAM');
    expect(loggedContent, 'BLANK FIELD');
    expect(halted, isTrue);

    // Operator cannot skip the field.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.maybePop();
    await tester.pump();
    expect(find.byType(ScramScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    expect(find.byType(ScramScreen), findsNothing);
    expect(find.text('ARM'), findsOneWidget);
  });

  testWidgets('EXIT aborts the blank field before the timer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final contents = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ScramScreen(
                        blankDuration: const Duration(seconds: 90),
                        logLedgerEntry: ({
                          required String type,
                          required String content,
                        }) async {
                          contents.add(content);
                        },
                        haltVoice: () async {},
                      ),
                    ),
                  );
                },
                child: const Text('ARM'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('ARM'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ScramScreen), findsOneWidget);
    final exit = find.byKey(const Key('scram_exit'));
    expect(exit, findsOneWidget);
    await tester.ensureVisible(exit);
    await tester.tap(exit);
    await tester.pumpAndSettle();

    expect(find.byType(ScramScreen), findsNothing);
    expect(find.text('ARM'), findsOneWidget);
    expect(contents, contains('BLANK FIELD'));
    expect(contents, contains('EXIT'));
  });
}
