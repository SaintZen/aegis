import 'package:anxiety_anchor/models/vault_model.dart';
import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/pdf_generator_service.dart';
import 'package:anxiety_anchor/services/vault_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('vault maps to THE VAULT, not THE ANCHOR', () {
    expect(PdfGeneratorService.debugMapToProtocol('The Vault'), 'THE VAULT');
    expect(PdfGeneratorService.debugMapToProtocol('THE VAULT'), 'THE VAULT');
    expect(
      PdfGeneratorService.debugMapToProtocol('Rescue Breath'),
      'THE ANCHOR',
    );
  });

  test('4/8 REFLECTION ledger rows are vault-section items', () {
    final entry = AegisLogEntry(
      toolName: 'The Vault',
      status: 'Acknowledged',
      timestamp: DateTime.utc(2026, 9, 20, 12),
      signalInput: 'Sealed signal after the morning pass.',
      ledgerType: '4/8 REFLECTION',
    );
    expect(PdfGeneratorService.debugIsVaultReflection(entry), isTrue);
  });

  test('vault deposit is withheld during the 8h reflection window', () {
    final lockedAt = DateTime.utc(2026, 9, 20, 6);
    final entry = VaultEntry(
      originalText: 'A long sealed signal that must survive the 80-char table cap '
          'so the doctor log is not missing line items from the vault.',
      lockedAt: lockedAt,
      duration: const Duration(hours: 24),
    );
    expect(
      PdfGeneratorService.debugVaultAppearsInPdf(
        entry,
        lockedAt.add(const Duration(hours: 7)),
      ),
      isFalse,
    );
    expect(
      PdfGeneratorService.debugVaultAppearsInPdf(
        entry,
        lockedAt.add(const Duration(hours: 8)),
      ),
      isTrue,
    );
  });

  test('THROW AWAY during reflection drops the archive row', () async {
    final service = VaultService();
    final lockedAt = DateTime.now().subtract(const Duration(hours: 1));
    await service.saveEntry(
      VaultEntry(
        originalText: 'discard me',
        lockedAt: lockedAt,
        duration: const Duration(hours: 24),
      ),
    );
    final afterWindow = DateTime.now().add(const Duration(hours: 10));
    expect(
      (await service.loadAuditArchive(now: afterWindow)).length,
      1,
    );
    await service.clearVault();
    expect(await service.loadEntry(), isNull);
    expect(
      (await service.loadAuditArchive(now: afterWindow)).length,
      0,
    );
  });

  test('vault deposit past 8h stays in the archive after clear', () async {
    final service = VaultService();
    final lockedAt = DateTime.now().subtract(const Duration(hours: 9));
    const text =
        'Full vault signal retained for the doctor PDF after reflection. '
        'This line is longer than the eighty-character main-table cap so '
        'THE VAULT section keeps the whole deposit.';
    await service.saveEntry(
      VaultEntry(
        originalText: text,
        lockedAt: lockedAt,
        duration: const Duration(hours: 24),
      ),
    );
    await service.clearVault();
    final archived = await service.loadAuditArchive();
    expect(archived, hasLength(1));
    expect(archived.single.originalText, text);
    expect(archived.single.originalText.length, greaterThan(80));
  });
}
