import 'dart:convert';
import 'dart:typed_data';

import 'package:anxiety_anchor/models/vault_model.dart';
import 'package:anxiety_anchor/services/aegis_crypto.dart';
import 'package:anxiety_anchor/services/vault_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration coverage for [VaultService] at-rest encryption. Uses the
/// in-memory SharedPreferences mock and the AegisCrypto test-key override so no
/// platform channels are touched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageKey = 'aegis_vault_data';
  const signal = 'My 7th sense is telling me the deploy will fail.';

  VaultEntry makeEntry() => VaultEntry(
        originalText: signal,
        lockedAt: DateTime.parse('2026-04-18T12:00:00.000'),
        duration: const Duration(hours: 24),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AegisCrypto.debugKeyOverride =
        Uint8List.fromList(List<int>.generate(32, (i) => (i * 7) % 256));
  });

  tearDown(() {
    AegisCrypto.debugKeyOverride = null;
  });

  test('saveEntry writes ciphertext at rest — never the plaintext signal',
      () async {
    await VaultService().saveEntry(makeEntry());

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    expect(raw, isNotNull);
    // Stored as the Aegis encryption envelope, not readable JSON.
    expect(raw!.startsWith('aegis-enc:v1:'), isTrue);
    // The operator's verbatim signal must not appear in the stored blob.
    expect(raw.contains(signal), isFalse);
    expect(raw.contains('originalText'), isFalse);
  });

  test('loadEntry decrypts back to the original entry verbatim', () async {
    final service = VaultService();
    await service.saveEntry(makeEntry());

    final loaded = await service.loadEntry();
    expect(loaded, isNotNull);
    expect(loaded!.originalText, signal); // preserved verbatim (doctrine)
    expect(loaded.duration, const Duration(hours: 24));
    expect(loaded.lockedAt, DateTime.parse('2026-04-18T12:00:00.000'));
  });

  test('legacy plaintext entry still loads (transparent migration)', () async {
    // Simulate an entry written before encryption existed.
    final plaintext = jsonEncode(makeEntry().toJson());
    SharedPreferences.setMockInitialValues({storageKey: plaintext});

    final loaded = await VaultService().loadEntry();
    expect(loaded, isNotNull);
    expect(loaded!.originalText, signal);
  });

  test('clearVault removes the stored entry', () async {
    final service = VaultService();
    await service.saveEntry(makeEntry());
    await service.clearVault();
    expect(await service.loadEntry(), isNull);
  });
}
