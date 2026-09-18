import 'dart:typed_data';

import 'package:anxiety_anchor/services/aegis_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-trip + migration coverage for [AegisCrypto]. Uses the test key
/// override so no platform keystore channel is required.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Deterministic 256-bit key for tests (not a real key).
    AegisCrypto.debugKeyOverride =
        Uint8List.fromList(List<int>.generate(32, (i) => i));
  });

  tearDown(() {
    AegisCrypto.debugKeyOverride = null;
  });

  final crypto = AegisCrypto.instance;

  test('encrypt then decrypt returns the original text verbatim', () async {
    const plain = 'My 7th sense is telling me the deploy will fail. — °∆✓';
    final enc = await crypto.encryptString(plain);
    expect(crypto.isEncrypted(enc), isTrue);
    expect(enc, isNot(contains(plain)));
    final round = await crypto.decryptString(enc);
    expect(round, plain);
  });

  test('ciphertext differs each time (random IV) but decrypts equal', () async {
    const plain = 'same input';
    final a = await crypto.encryptString(plain);
    final b = await crypto.encryptString(plain);
    expect(a, isNot(equals(b)));
    expect(await crypto.decryptString(a), plain);
    expect(await crypto.decryptString(b), plain);
  });

  test('legacy plaintext passes through decrypt unchanged (migration)',
      () async {
    const legacy = '{"originalText":"old plaintext entry"}';
    expect(crypto.isEncrypted(legacy), isFalse);
    expect(await crypto.decryptString(legacy), legacy);
  });

  test('empty string round-trips', () async {
    final enc = await crypto.encryptString('');
    expect(crypto.isEncrypted(enc), isTrue);
    expect(await crypto.decryptString(enc), '');
  });
}
