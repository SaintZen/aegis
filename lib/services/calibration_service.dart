import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted calibration settings for haptics, audio, motion, and PDF export.
class CalibrationService {
  CalibrationService._();

  static const String _keyHapticIntensity = 'calibration_haptic_intensity';
  static const String _keyEntrainmentAudio = 'calibration_entrainment_audio';
  static const String _keyReducedMotion = 'calibration_reduced_motion';
  static const String _keyPdfIncludeTimestamps = 'calibration_pdf_include_timestamps';
  static const String _keyPdfAnonymize = 'calibration_pdf_anonymize';
  static const String _keyPulseEntrainmentBpm = 'calibration_pulse_entrainment_bpm';
  static const String _keyHighVisibility = 'calibration_high_visibility';
  static const String _keySootheMode = 'calibration_soothe_mode';

  static const double _defaultHapticIntensity = 1.0;
  static const int _defaultPulseEntrainmentBpm = 60;

  static double? _cachedHapticIntensity;
  static int? _cachedPulseEntrainmentBpm;
  static bool? _cachedHighVisibility;
  static bool? _cachedSootheMode;
  static bool? _cachedReducedMotion;
  static bool? _cachedPdfIncludeTimestamps;
  static bool? _cachedPdfAnonymize;

  static Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedHapticIntensity = prefs.getDouble(_keyHapticIntensity) ?? _defaultHapticIntensity;
    _cachedReducedMotion = prefs.getBool(_keyReducedMotion) ?? false;
    _cachedPdfIncludeTimestamps = prefs.getBool(_keyPdfIncludeTimestamps) ?? true;
    _cachedPdfAnonymize = prefs.getBool(_keyPdfAnonymize) ?? false;
    _cachedPulseEntrainmentBpm = prefs.getInt(_keyPulseEntrainmentBpm) ?? _defaultPulseEntrainmentBpm;
    _cachedHighVisibility = prefs.getBool(_keyHighVisibility) ?? false;
    _cachedSootheMode = prefs.getBool(_keySootheMode) ?? false;
    highVisibilityNotifier.value = _cachedHighVisibility ?? false;
    sootheModeNotifier.value = _cachedSootheMode ?? false;
  }

  static Future<bool> getSootheMode() async {
    if (_cachedSootheMode == null) await _loadCache();
    return _cachedSootheMode ?? false;
  }

  static Future<void> setSootheMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySootheMode, value);
    _cachedSootheMode = value;
    sootheModeNotifier.value = value;
  }

  /// Sync access to cached soothe mode. Use after preload().
  static bool get sootheModeSync => _cachedSootheMode ?? false;

  /// Notifier for app-wide theme rebuild when soothe mode changes.
  static final ValueNotifier<bool> sootheModeNotifier = ValueNotifier<bool>(false);

  /// Call at app launch to load user calibrations before the Lab screen builds.
  static Future<void> preload() async {
    await _loadCache();
  }

  /// Sync access to cached haptic intensity. Use after preload() for zero-call skip when intensity is 0.
  static double get hapticIntensitySync =>
      _cachedHapticIntensity ?? _defaultHapticIntensity;

  static Future<bool> getHighVisibility() async {
    if (_cachedHighVisibility == null) await _loadCache();
    return _cachedHighVisibility ?? false;
  }

  static Future<void> setHighVisibility(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighVisibility, value);
    _cachedHighVisibility = value;
    highVisibilityNotifier.value = value;
  }

  /// Sync access to cached high visibility. Use after preload().
  static bool get highVisibilitySync => _cachedHighVisibility ?? false;

  /// Notifier for app-wide theme rebuild when high visibility changes.
  static final ValueNotifier<bool> highVisibilityNotifier =
      ValueNotifier<bool>(false);

  static Future<int> getPulseEntrainmentBpm() async {
    if (_cachedPulseEntrainmentBpm == null) await _loadCache();
    return _cachedPulseEntrainmentBpm ?? _defaultPulseEntrainmentBpm;
  }

  static Future<void> setPulseEntrainmentBpm(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = value.clamp(50, 70);
    await prefs.setInt(_keyPulseEntrainmentBpm, clamped);
    _cachedPulseEntrainmentBpm = clamped;
  }

  static Future<double> getHapticIntensity() async {
    if (_cachedHapticIntensity == null) await _loadCache();
    return _cachedHapticIntensity ?? _defaultHapticIntensity;
  }

  static Future<void> setHapticIntensity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = value.clamp(0.0, 1.0);
    await prefs.setDouble(_keyHapticIntensity, clamped);
    _cachedHapticIntensity = clamped;
  }

  static Future<bool> getEntrainmentAudio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEntrainmentAudio) ?? true;
  }

  static Future<void> setEntrainmentAudio(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEntrainmentAudio, value);
  }

  static Future<bool> getReducedMotion() async {
    if (_cachedReducedMotion == null) await _loadCache();
    return _cachedReducedMotion ?? false;
  }

  static Future<void> setReducedMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReducedMotion, value);
    _cachedReducedMotion = value;
  }

  static Future<bool> getPdfIncludeTimestamps() async {
    if (_cachedPdfIncludeTimestamps == null) await _loadCache();
    return _cachedPdfIncludeTimestamps ?? true;
  }

  static Future<void> setPdfIncludeTimestamps(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPdfIncludeTimestamps, value);
    _cachedPdfIncludeTimestamps = value;
  }

  static Future<bool> getPdfAnonymize() async {
    if (_cachedPdfAnonymize == null) await _loadCache();
    return _cachedPdfAnonymize ?? false;
  }

  static Future<void> setPdfAnonymize(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPdfAnonymize, value);
    _cachedPdfAnonymize = value;
  }

  /// Fire haptic feedback scaled by stored intensity.
  /// Call this instead of HapticFeedback directly for Hollow/Frost.
  static Future<void> fireTacticalFeedback({
    HapticIntensity fallback = HapticIntensity.medium,
  }) async {
    final scale = await getHapticIntensity();
    if (scale <= 0) return;
    if (scale < 0.33) {
      HapticFeedback.selectionClick();
    } else if (scale < 0.66) {
      HapticFeedback.lightImpact();
    } else {
      switch (fallback) {
        case HapticIntensity.light:
          HapticFeedback.lightImpact();
          break;
        case HapticIntensity.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticIntensity.heavy:
          HapticFeedback.heavyImpact();
          break;
      }
    }
  }

  /// Scale vibration amplitude (0-255) by stored haptic intensity.
  static Future<int> scaleVibrationAmplitude(int baseAmplitude) async {
    final scale = await getHapticIntensity();
    return (baseAmplitude * scale).round().clamp(20, 255);
  }
}

enum HapticIntensity { light, medium, heavy }
