import 'package:anxiety_anchor/data/advocacy_support_links.dart';
import 'package:anxiety_anchor/models/shield_directory_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShieldDirectoryEntry', () {
    test('rejects example.* hosts via hasValidUrl', () {
      final bad = ShieldDirectoryEntry(
        id: 'x',
        category: 'crisis_immediate',
        title: 't',
        description: 'd',
        url: 'https://example.org/foo',
        verifiedAt: DateTime.utc(2026, 1, 1),
      );
      expect(bad.hasValidUrl, isFalse);
    });

    test('accepts plain https hosts via hasValidUrl', () {
      final good = ShieldDirectoryEntry(
        id: 'x',
        category: 'crisis_immediate',
        title: 't',
        description: 'd',
        url: 'https://988lifeline.org',
        verifiedAt: DateTime.utc(2026, 1, 1),
      );
      expect(good.hasValidUrl, isTrue);
    });

    test('telUri strips formatting', () {
      final e = ShieldDirectoryEntry(
        id: 'x',
        category: 'crisis_immediate',
        title: 't',
        description: 'd',
        url: 'https://example-ok.test',
        phone: '1-800-656-4673',
        verifiedAt: DateTime.utc(2026, 1, 1),
      );
      expect(e.telUri, 'tel:18006564673');
    });

    test('telUri is null when phone absent', () {
      final e = ShieldDirectoryEntry(
        id: 'x',
        category: 'crisis_immediate',
        title: 't',
        description: 'd',
        url: 'https://988lifeline.org',
        verifiedAt: DateTime.utc(2026, 1, 1),
      );
      expect(e.telUri, isNull);
    });
  });

  group('shieldDirectoryLiveEntries', () {
    test('contains no placeholder rows', () {
      expect(
        shieldDirectoryLiveEntries.every((e) => !e.placeholder),
        isTrue,
      );
    });

    test('every live row passes hasValidUrl (no example.*)', () {
      for (final e in shieldDirectoryLiveEntries) {
        expect(
          e.hasValidUrl,
          isTrue,
          reason: 'Bad URL for id=${e.id}: ${e.url}',
        );
      }
    });

    test('ids are unique across all entries', () {
      final ids = shieldDirectoryEntries.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every live row uses a declared category id', () {
      final declared = advocacySupportCategoryOrder.toSet();
      for (final e in shieldDirectoryLiveEntries) {
        expect(
          declared.contains(e.category),
          isTrue,
          reason: 'Unknown category "${e.category}" on id=${e.id}',
        );
      }
    });

    test('every declared category has a label', () {
      for (final id in advocacySupportCategoryOrder) {
        expect(
          advocacySupportCategoryLabels.containsKey(id),
          isTrue,
          reason: 'Missing label for category "$id"',
        );
      }
    });
  });
}
