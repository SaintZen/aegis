import 'package:flutter/widgets.dart';

/// Shared halt for looping beds and leftover players.
///
/// [AppLifecycleState.resumed] is the only state that may keep audio
/// running. Pause, hide, inactive, and detach all silence playback so
/// a spoken-word import or a looping bed cannot continue after the
/// operator leaves the foreground.
bool aegisLifecycleSilencesAudio(AppLifecycleState state) {
  return state != AppLifecycleState.resumed;
}

/// Imported spoken-word / personal library tracks play once.
/// Tapping a file is a one-shot, not an armed loop. Atmosphere tiles
/// on that surface are the only beds the operator can arm, and they
/// still halt on leave.
bool aegisImportedTrackLoops() => false;

/// Vista / vault / pharmacy texture / void / atmosphere beds may loop
/// only while the operator remains on that surface in the foreground.
bool aegisBedLoopsWhileOnSurface({required bool operatorOnSurface}) {
  return operatorOnSurface;
}
