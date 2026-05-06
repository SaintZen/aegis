/// Default vault seal: 24h full lock. First 8h (capped by total duration) =
/// reflection window — signal may be discarded; after that it is retained for
/// technical audit PDF export until final release.
class VaultLockTimerSpec {
  VaultLockTimerSpec._();

  static const int durationSeconds = 86400; // 24 hours

  static Duration get lockDuration => const Duration(seconds: durationSeconds);

  /// Reflection window before audit PDF may include this vault row.
  static const Duration auditReflectionWindow = Duration(hours: 8);
}

class VaultEntry {
  final String originalText;
  final DateTime lockedAt;
  final Duration duration;
  bool isResolved;

  static Duration get defaultLockDuration => VaultLockTimerSpec.lockDuration;

  VaultEntry({
    required this.originalText,
    required this.lockedAt,
    required this.duration,
    this.isResolved = false,
  });

  DateTime get unlockTime => lockedAt.add(duration);
  bool get isReadyForReflection => DateTime.now().isAfter(unlockTime);

  /// Time after which the signal is eligible for clinical / audit PDF (discard no longer applies).
  Duration get _effectiveReflectionDuration {
    final cap = VaultLockTimerSpec.auditReflectionWindow;
    return duration < cap ? duration : cap;
  }

  DateTime get reflectionEndsAt => lockedAt.add(_effectiveReflectionDuration);

  /// True while user may discard the sealed signal before audit retention.
  bool get isInReflectionWindow {
    final now = DateTime.now();
    return now.isBefore(reflectionEndsAt) && now.isBefore(unlockTime);
  }

  /// After reflection window, before full unlock (24h lock with 8h reflection).
  bool get isInSealedRetentionPhase {
    final now = DateTime.now();
    return !now.isBefore(reflectionEndsAt) && now.isBefore(unlockTime);
  }

  Duration get reflectionRemainingTime =>
      reflectionEndsAt.difference(DateTime.now());

  Duration get remainingTime => unlockTime.difference(DateTime.now());

  /// PDF / audit table: include vault row only after reflection window closes.
  bool get shouldAppearInAuditPdf =>
      !DateTime.now().isBefore(reflectionEndsAt);

  // Serialization for persistent storage
  Map<String, dynamic> toJson() => {
        'originalText': originalText,
        'lockedAt': lockedAt.toIso8601String(),
        'durationMillis': duration.inMilliseconds,
        'isResolved': isResolved,
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
        originalText: json['originalText'],
        lockedAt: DateTime.parse(json['lockedAt']),
        duration: Duration(milliseconds: json['durationMillis']),
        isResolved: json['isResolved'] ?? false,
      );
}
