import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AegisLogService {
  static const _fileName = 'aegis_log.json';

  /// Ledger-native row: TYPE, TIMESTAMP (ISO8601), CONTENT only.
  /// [content] is stored exactly as provided—no filler.
  static Future<void> logLedgerEntry({
    required String type,
    required String content,
  }) async {
    final entry = <String, dynamic>{
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'content': content,
    };
    final file = await _logFile();
    final existing = await _readEntries(file);
    existing.add(entry);
    await file.writeAsString(jsonEncode(existing));
  }

  /// Logs an audit entry (tool/session shape). [signalInput] stored exactly as provided.
  static Future<void> logEntry({
    required String toolName,
    required String status,
    String? signalInput,
  }) async {
    final entry = <String, dynamic>{
      'toolName': toolName,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      if (signalInput != null && signalInput.isNotEmpty) 'signalInput': signalInput,
    };
    final file = await _logFile();
    final existing = await _readEntries(file);
    existing.add(entry);
    await file.writeAsString(jsonEncode(existing));
  }

  static Future<File> _logFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Map<String, dynamic>>> _readEntries(File file) async {
    if (!await file.exists()) return <Map<String, dynamic>>[];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<List<AegisLogEntry>> getEntries() async {
    final file = await _logFile();
    final raw = await _readEntries(file);
    return raw
        .map((entry) => AegisLogEntry.fromJson(entry))
        .whereType<AegisLogEntry>()
        .toList();
  }

  /// Maps ledger TYPE string to internal toolName for protocol / void rules.
  static String toolNameFromLedgerType(String type) {
    final l = type.toLowerCase();
    if (l.contains('void')) return 'The Void';
    if (l.contains('hollow')) return 'The Hollow';
    if (l.contains('frost') ||
        l.contains('ice') ||
        l.contains('scraper')) {
      return 'Frost Scraper';
    }
    if (l.contains('vault') || l.contains('4/8')) {
      return 'The Vault';
    }
    return type;
  }
}

class AegisLogEntry {
  const AegisLogEntry({
    required this.toolName,
    required this.status,
    required this.timestamp,
    this.signalInput,
    this.ledgerType,
  });

  final String toolName;
  final String status;
  final DateTime timestamp;
  final String? signalInput;
  /// Ledger TYPE (JSON `type`, or legacy `tag`).
  final String? ledgerType;

  static AegisLogEntry? fromJson(Map<String, dynamic> json) {
    final timestampRaw = json['timestamp'];
    if (timestampRaw is! String) return null;
    final ts = DateTime.tryParse(timestampRaw) ?? DateTime.now();

    final typeStr = json['type'];
    final type = typeStr is String && typeStr.isNotEmpty ? typeStr : null;
    final legacyTag = json['tag'];
    final tag = legacyTag is String && legacyTag.isNotEmpty ? legacyTag : null;
    final ledgerType = type ?? tag;

    final tool = json['toolName'];

    // LEDGER_ENTRY: type + timestamp + content (no toolName)
    if (tool == null && type != null) {
      final content = json['content'];
      return AegisLogEntry(
        toolName: AegisLogService.toolNameFromLedgerType(type),
        status: 'Acknowledged',
        timestamp: ts,
        signalInput: content is String ? content : null,
        ledgerType: type,
      );
    }

    if (tool is! String) return null;
    final statusRaw = json['status'];
    if (statusRaw is! String) return null;

    final signal = json['signalInput'];
    return AegisLogEntry(
      toolName: tool,
      status: statusRaw,
      timestamp: ts,
      signalInput: signal is String ? signal : null,
      ledgerType: ledgerType,
    );
  }

  /// Formats entry for audit log display: [M/d/yy | HH:mm] SIG: "..." | STATUS: X
  static String formatAuditEntry(
    AegisLogEntry e, {
    int signalMaxLength = 60,
    String Function(String) mapStatus = _identity,
  }) {
    final date = '${e.timestamp.month}/${e.timestamp.day}/${e.timestamp.year % 100}';
    final time = '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}';
    final sig = e.signalInput ?? '';
    final sigDisplay = sig.length > signalMaxLength
        ? '${sig.substring(0, signalMaxLength)}…'
        : sig;
    final sigQuoted = sigDisplay.isEmpty ? '—' : '"$sigDisplay"';
    final status = mapStatus(e.status);
    return '[$date | $time] SIG: $sigQuoted | STATUS: $status';
  }

  static String _identity(String s) => s;
}
