# PR: Prepare release — tests, docs, CI

## Summary

- Add test helper `pumpApp` / `pumpMaterialAppWithL10n` and update tests to provide `AppLocalizations`.
- Add operator reference (`docs/AEGIS_OPERATOR_README.md`) and CI workflow (`.github/workflows/flutter-ci.yml`) for `gen-l10n`, `analyze`, and tests.
- Fixes local test failures and prepares branch for CI runs.

## Checklist

- [ ] CI runs and `gen-l10n` completes successfully.
- [ ] `flutter analyze` passes or warnings triaged.
- [ ] `flutter test` passes in CI.
- [ ] Legal to replace placeholder advocacy URLs before public release.
- [ ] Accessibility smoke test results attached.

## Reviewers

- Engineering lead  
- QA lead  
- Legal  
- Accessibility owner

---

## Review guidance and blockers

**Legal / Content**
- `lib/data/advocacy_support_links.dart` currently contains placeholder URLs such as `https://example.org/...` and `https://example.edu/...`. These are real placeholder links in the code and must be replaced with vetted, lawyer‑approved URLs before any public release. Do not merge until legal signs off or explicitly defers replacement in writing.

**QA / Accessibility**
- Run the Accessibility Smoke Test in `docs/ACCESSIBILITY_SMOKE_TEST.md` and attach results to this PR. QA should confirm TalkBack/VoiceOver behavior, focus order for dialogs and sheets, and color contrast in both default and high‑visibility modes.

**Engineering**
- Confirm CI workflow runs `flutter gen-l10n` before tests and that the pinned Flutter SDK or agreed channel is used. If `flutter analyze` reports many warnings, follow `docs/ANALYZER_TRIAGE.md` to triage and apply `dart fix --apply` where safe.
- Telemetry is currently a debug/in-memory emitter. Either wire a production emitter with a privacy review or create a tracked ticket for post‑release wiring. Ensure no PII is emitted.

---

## Suggested PR comment to pin blockers

Do not merge until legal replaces placeholder advocacy URLs and signs off on Terms/Privacy.

QA: please run the Accessibility Smoke Test in `docs/ACCESSIBILITY_SMOKE_TEST.md` and attach results here.

Engineering: CI must be green (gen-l10n, analyze, test). If analyze shows warnings, run `dart fix --apply` and push fixes or document triage in `docs/ANALYZER_TRIAGE.md`.

---

## Quick commands for reviewers

```bash
# fetch remote main for diffs
git fetch origin main

# run localization generation and tests locally
flutter pub get
flutter gen-l10n
flutter analyze
flutter test --coverage
```
