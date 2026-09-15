import 'package:anxiety_anchor/models/vault_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit coverage for [VaultEntry] release + clock-skew logic — the core of the
/// "vault locks up past the 24h timer" fix. All timings are relative to
/// `DateTime.now()` so the getters are exercised exactly as the UI sees them.
void main() {
  VaultEntry entry({
    required Duration lockedAgo,
    Duration? duration,
    String text = 'signal',
  }) =>
      VaultEntry(
        originalText: text,
        lockedAt: DateTime.now().subtract(lockedAgo),
        duration: duration ?? VaultEntry.defaultLockDuration,
      );

  group('release detection', () {
    test('fresh 24h seal is not released', () {
      final e = entry(lockedAgo: const Duration(minutes: 1));
      expect(e.isReleased, isFalse);
      expect(e.isReadyForReflection, isFalse);
      expect(e.remainingTimeClamped, greaterThan(Duration.zero));
    });

    test('seal past 24h is released with zero remaining', () {
      final e = entry(lockedAgo: const Duration(hours: 25));
      expect(e.isReleased, isTrue);
      expect(e.isReadyForReflection, isTrue);
      expect(e.remainingTimeClamped, Duration.zero);
    });

    test('release fires exactly at the seal boundary', () {
      final e = entry(lockedAgo: const Duration(hours: 24, seconds: 1));
      expect(e.isReleased, isTrue);
    });
  });

  group('clock-skew clamping', () {
    test('backward clock cannot show more than the seal duration', () {
      // lockedAt in the future simulates the device clock jumping backward
      // after the seal was written.
      final e = VaultEntry(
        originalText: 'signal',
        lockedAt: DateTime.now().add(const Duration(hours: 5)),
        duration: const Duration(hours: 24),
      );
      expect(e.remainingTimeClamped, lessThanOrEqualTo(const Duration(hours: 24)));
      expect(e.remainingTimeClamped, greaterThan(Duration.zero));
    });

    test('remainingTimeClamped never goes negative', () {
      final e = entry(lockedAgo: const Duration(days: 3));
      expect(e.remainingTimeClamped, Duration.zero);
    });
  });

  group('reflection window', () {
    test('within first 8h → reflection window open, discard allowed', () {
      final e = entry(lockedAgo: const Duration(hours: 1));
      expect(e.isInReflectionWindow, isTrue);
      expect(e.isInSealedRetentionPhase, isFalse);
      expect(e.shouldAppearInAuditPdf, isFalse);
      expect(e.reflectionRemainingTimeClamped, greaterThan(Duration.zero));
    });

    test('after 8h → sealed retention, eligible for audit PDF', () {
      final e = entry(lockedAgo: const Duration(hours: 9));
      expect(e.isInReflectionWindow, isFalse);
      expect(e.isInSealedRetentionPhase, isTrue);
      expect(e.shouldAppearInAuditPdf, isTrue);
      expect(e.reflectionRemainingTimeClamped, Duration.zero);
    });

    test('reflection window is capped for short seals', () {
      final e = entry(
        lockedAgo: const Duration(minutes: 1),
        duration: const Duration(hours: 2),
      );
      // Effective reflection duration is capped by the (shorter) seal length.
      expect(
        e.reflectionRemainingTimeClamped,
        lessThanOrEqualTo(const Duration(hours: 2)),
      );
    });
  });

  group('serialization round-trip', () {
    test('toJson/fromJson preserves signal verbatim and timing', () {
      final original = VaultEntry(
        originalText: 'My 7th sense is telling me something is off.',
        lockedAt: DateTime.parse('2026-04-18T12:00:00.000'),
        duration: const Duration(hours: 24),
        isResolved: true,
      );
      final restored = VaultEntry.fromJson(original.toJson());
      expect(restored.originalText, original.originalText);
      expect(restored.lockedAt, original.lockedAt);
      expect(restored.duration, original.duration);
      expect(restored.isResolved, isTrue);
      expect(restored.unlockTime, original.unlockTime);
    });
  });
}
