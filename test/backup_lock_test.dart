import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android cloud backup is locked off', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );

    final backup = File('android/app/src/main/res/xml/backup_rules.xml').readAsStringSync();
    expect(backup, contains('sharedpref'));
    expect(backup, contains('exclude'));

    final extraction =
        File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    expect(extraction, contains('cloud-backup'));
    expect(extraction, contains('device-transfer'));
  });

  test('iOS sandbox is excluded from iCloud Backup', () {
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegate, contains('isExcludedFromBackup'));
    expect(delegate, contains('excludeSandboxFromCloudBackup'));
    expect(delegate, contains('.documentDirectory'));
    expect(delegate, contains('.libraryDirectory'));
  });
}
