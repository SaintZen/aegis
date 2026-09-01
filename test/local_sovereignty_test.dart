import 'package:anxiety_anchor/screens/privacy_policy_screen.dart';
import 'package:anxiety_anchor/services/local_sovereignty.dart';
import 'package:anxiety_anchor/widgets/sovereignty_veil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocalSovereignty.debugChannel = null;
    debugDefaultTargetPlatformOverride = null;
  });

  test('veil is on for inactive, paused, and hidden; off for resumed', () {
    expect(sovereigntyVeilForState(AppLifecycleState.inactive), isTrue);
    expect(sovereigntyVeilForState(AppLifecycleState.paused), isTrue);
    expect(sovereigntyVeilForState(AppLifecycleState.hidden), isTrue);
    expect(sovereigntyVeilForState(AppLifecycleState.resumed), isFalse);
    expect(sovereigntyVeilForState(AppLifecycleState.detached), isFalse);
  });

  testWidgets('SovereigntyVeil covers the surface when visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SovereigntyVeil(visible: true)),
    );
    expect(find.text('AEGIS'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: SovereigntyVeil(visible: false)),
    );
    expect(find.text('AEGIS'), findsNothing);
  });

  testWidgets('privacy screen states cloud backup is excluded', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    expect(find.text('CLOUD BACKUP'), findsOneWidget);
    expect(find.textContaining('iCloud Backup'), findsOneWidget);
    expect(find.textContaining('Google cloud backup'), findsOneWidget);
  });

  test('seal is a no-op off iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var invoked = false;
    const channel = MethodChannel('com.zwischenzug.aegis/sovereignty.test');
    LocalSovereignty.debugChannel = channel;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      invoked = true;
      return null;
    });
    await LocalSovereignty.seal();
    expect(invoked, isFalse);
  });

  test('seal invokes the iOS backup-exclusion channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var invoked = false;
    const channel = MethodChannel('com.zwischenzug.aegis/sovereignty.test');
    LocalSovereignty.debugChannel = channel;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'sealFromBackup');
      invoked = true;
      return null;
    });
    await LocalSovereignty.seal();
    expect(invoked, isTrue);
  });
}
