# Anxiety Anchor AEGIS Operator README

This document is a concise technical reference for engineers, QA, and release operators. It covers app flow, key screens and routes, services, data assets, tests, and pre-release tasks.

## Quick commands

```bash
flutter gen-l10n
flutter analyze
flutter test
```

## App shell and core flow

- SafetyGateScreen enforces legal/safety acceptance.
- SystemInitializationScreen performs one-time asset bootstrap and SharedPreferences init.
- Main UI is a four-tab shell with a global AEGIS HUD overlay via MaterialApp.builder.
- Dark theme with CalibrationService toggles for high-visibility and soothe mode.
- Localization via generated AppLocalizations (English present).

## Pillars and notable routes

- Anchor (HomeScreen): anchor UI, engine thrum, motto, Terms/Privacy links.
- Vistas (IslandScreen): vista video/audio previews, affirmations, kinetic/voice engine.
- Lab (AnxietyLabScreen): Hollow, Void, Vault, Frost, PDF hooks, exercise library.
- Bridge (BridgeScreen): Monolith, long-press kill switch → Wormhole, AUDIT/print, MAINTENANCE/LEDGER, outlets: NOT TODAY, ASMR, DICTIONARY, ADVOCACY.

Key routes:

- /dictionary
- /privacy
- /terms-of-use
- /kinetic-voice, /kinetic-armory, /kinetic-action

## Services and data

- CalibrationService, VaultService, UsageLogService, AegisLogService, AdvocacyLogService.
- PdfGeneratorService, PdfExportService, JournalExportService.
- KineticVoiceEngine, SomaticController.
- Telemetry: debug emitter (clearable).
- Data files: lib/data/dictionary_entries.dart, lib/data/advocacy_support_links.dart

## Media and assets

- Vista loops, vault door video, frost frames, anchor thrum, pharmacy AAC loops.
- Large media copied into app documents at init for reliable playback.

## Tests and helpers

- Tests under test/ (dictionary, advocacy block, bridge routes).
- Test helper: test/helpers/launch_helper_mock.dart
- Telemetry.clear() used in setUp/tearDown.

## Pre-release checklist

- Replace placeholder URLs in lib/data/advocacy_support_links.dart with vetted, lawyer-approved links.
- Legal review of Terms of Use, Privacy, and Support Resources intro/disclaimer.
- Ensure Support Resources are excluded from audit PDF exports or add explicit exclusion logic.
- Run full test matrix and static analysis:
  - flutter pub get
  - flutter gen-l10n
  - flutter analyze
  - flutter test --coverage
- Accessibility pass: TalkBack/VoiceOver, focus management, color contrast.
- Plan telemetry production wiring and privacy disclosure in Terms/Privacy.

## Quick grep pointers

- lib/data/dictionary_entries.dart
- lib/data/advocacy_support_links.dart
- lib/widgets/dictionary_screen.dart
- lib/widgets/advocacy_support_block.dart
- lib/services/telemetry.dart
- lib/utils/launch_helper.dart
- test/advocacy_support_block_test.dart
- test/helpers/launch_helper_mock.dart

## Owners and reviewers

- Content / Legal: review placeholder URLs and Terms/Privacy.
- QA / Accessibility: run screen reader and focus tests.
- Engineering Lead: CI, telemetry production wiring.
- Release Manager: confirm legal sign-off before public release.
