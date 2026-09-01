import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps Aegis data off vendor cloud backup.
///
/// iOS: marks Documents, Application Support, and Preferences as
/// excluded from iCloud / Finder backup (`NSURLIsExcludedFromBackupKey`).
/// Android: no-op here — cloud backup is disabled in the manifest.
///
/// Four Gates doctrine §8: runs are local-only. iCloud Backup would
/// transmit ledger contents to a remote service; this seal exists to
/// prevent that path. No HIPAA claim is made.
class LocalSovereignty {
  LocalSovereignty._();

  static const MethodChannel _channel =
      MethodChannel('com.zwischenzug.aegis/sovereignty');

  /// Test seam. When set, [seal] invokes this channel instead of [_channel].
  static MethodChannel? debugChannel;

  static MethodChannel get _effective => debugChannel ?? _channel;

  /// Re-apply backup-exclusion flags. Safe to call after every file write.
  /// Missing native plugin (tests, desktop) is a no-op.
  static Future<void> seal() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _effective.invokeMethod<void>('sealFromBackup');
    } on MissingPluginException {
      // Host without the iOS channel — tests, desktop, or pre-engine.
    } catch (_) {
      // Backup exclusion must never crash the instrument.
    }
  }
}
