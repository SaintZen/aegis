/// In-memory event log for tests and future analytics wiring.
/// Call [clear] in test `setUp` / `tearDown` for deterministic runs.
class Telemetry {
  static final List<Map<String, dynamic>> events = [];

  static void emit(String event, [Map<String, dynamic>? payload]) {
    // Keep tests deterministic: store events for assertions
    events.add({'event': event, 'payload': payload ?? {}});
  }

  static void clear() => events.clear();
}
