import 'package:anxiety_anchor/screens/scram_screen.dart';
import 'package:anxiety_anchor/screens/wormhole_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('blank field is ninety seconds — midpoint of 1–2 minutes', () {
    expect(ScramScreen.blankDuration, const Duration(seconds: 90));
    expect(ScramScreen.ledgerType, 'SCRAM');
  });

  testWidgets('SCRAM is a blank field, not the Void', (tester) async {
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
    expect(
      find.descendant(
        of: find.byType(ScramScreen),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
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
}
