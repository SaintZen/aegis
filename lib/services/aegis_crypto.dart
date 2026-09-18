import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// At-rest encryption for the Aegis personal-content stores (Vault signals,
/// Ledger, Four Gates evidence, diaries).
///
/// A single random 256-bit key is generated once and held in the platform
/// keystore — iOS Keychain / Android EncryptedSharedPreferences+Keystore — via
/// [FlutterSecureStorage]. Payloads are AES-GCM encrypted and wrapped in a
/// versioned envelope so legacy plaintext can be migrated transparently on
/// read (see [decryptString]).
///
/// Platform note: on web the key lives in localStorage, so web encryption is
/// best-effort obfuscation, not true security — real protection is on-device.
///
/// Data note: the key is device-bound and not backed up. Uninstalling the app
/// or losing the device makes encrypted data unrecoverable — consistent with
/// Aegis's existing local-only, no-cloud-backup design.
class AegisCrypto {
  AegisCrypto._();
  static final AegisCrypto instance = AegisCrypto._();

  static const String _keyStorageKey = 'aegis_enc_key_v1';
  static const String _prefix = 'aegis-enc:v1:';
  static const int _ivLength = 12; // 96-bit nonce, standard for AES-GCM

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Encrypter? _encrypter;

  /// Test-only override: when set, this key is used instead of the keystore so
  /// unit tests can exercise round-trips without a platform channel. Never set
  /// in production code.
  static Uint8List? debugKeyOverride;

  Future<Encrypter> _ensureEncrypter() async {
    final existing = _encrypter;
    if (existing != null) return existing;

    Uint8List keyBytes;
    if (debugKeyOverride != null) {
      keyBytes = debugKeyOverride!;
    } else {
      var b64 = await _storage.read(key: _keyStorageKey);
      if (b64 == null || b64.isEmpty) {
        final rnd = Random.secure();
        keyBytes =
            Uint8List.fromList(List.generate(32, (_) => rnd.nextInt(256)));
        await _storage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
      } else {
        keyBytes = base64Decode(b64);
      }
    }
    final encrypter = Encrypter(AES(Key(keyBytes), mode: AESMode.gcm));
    _encrypter = encrypter;
    return encrypter;
  }

  /// True when [value] is an Aegis encryption envelope (vs. legacy plaintext).
  bool isEncrypted(String value) => value.startsWith(_prefix);

  /// AES-GCM encrypts [plaintext] and returns a versioned envelope:
  /// `aegis-enc:v1:<base64 iv>:<base64 ciphertext+tag>`.
  Future<String> encryptString(String plaintext) async {
    final encrypter = await _ensureEncrypter();
    final iv = IV.fromSecureRandom(_ivLength);
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '$_prefix${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypts an Aegis envelope. If [value] is not an envelope it is returned
  /// unchanged — legacy plaintext passthrough so callers migrate on next write.
  Future<String> decryptString(String value) async {
    if (!isEncrypted(value)) return value;
    final encrypter = await _ensureEncrypter();
    final body = value.substring(_prefix.length);
    final sep = body.indexOf(':');
    if (sep < 0) return value;
    final iv = IV(base64Decode(body.substring(0, sep)));
    final cipher = Encrypted.fromBase64(body.substring(sep + 1));
    return encrypter.decrypt(cipher, iv: iv);
  }
}
