import 'package:anxiety_anchor/audio/audio_halt.dart';
import 'package:anxiety_anchor/screens/island_screen.dart';
import 'package:anxiety_anchor/screens/personal_audio_library_screen.dart';
import 'package:anxiety_anchor/screens/sonic_pharmacy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('imported spoken-word tracks never loop', () {
    expect(aegisImportedTrackLoops(), isFalse);
    expect(personalAudioImportedTrackLoops(), isFalse);
  });

  test('beds loop only while the operator is on the surface', () {
    expect(aegisBedLoopsWhileOnSurface(operatorOnSurface: true), isTrue);
    expect(aegisBedLoopsWhileOnSurface(operatorOnSurface: false), isFalse);
    expect(
      pharmacyTextureLoopsWhilePanelOpen(panelOpen: true),
      isTrue,
    );
    expect(
      pharmacyTextureLoopsWhilePanelOpen(panelOpen: false),
      isFalse,
    );
  });

  test('shared halt silences every non-resumed lifecycle state', () {
    expect(aegisLifecycleSilencesAudio(AppLifecycleState.resumed), isFalse);
    expect(aegisLifecycleSilencesAudio(AppLifecycleState.inactive), isTrue);
    expect(aegisLifecycleSilencesAudio(AppLifecycleState.hidden), isTrue);
    expect(aegisLifecycleSilencesAudio(AppLifecycleState.paused), isTrue);
    expect(aegisLifecycleSilencesAudio(AppLifecycleState.detached), isTrue);
    expect(
      personalAudioLifecycleSilencesAudio(AppLifecycleState.paused),
      isTrue,
    );
    expect(
      islandLifecycleSilencesAudio(AppLifecycleState.hidden),
      isTrue,
    );
  });

  testWidgets('personal audio library halt on pause does not throw',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PersonalAudioLibraryScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Personal Audio Library'), findsOneWidget);
    expect(find.text('Import a music or spoken-word file.'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byType(PersonalAudioLibraryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
