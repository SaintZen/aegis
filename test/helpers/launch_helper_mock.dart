import 'package:flutter/material.dart';

/// Records URLs passed to [launchUrlHelper] for widget / integration tests.
/// Call [clear] in `tearDown` for deterministic runs.
class LaunchHelperMock {
  static final List<String> opened = [];

  static Future<void> launchUrlHelper(BuildContext context, String url) async {
    opened.add(url);
    // Simulate success
    return;
  }

  static void clear() => opened.clear();
}
