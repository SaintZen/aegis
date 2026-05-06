# Accessibility smoke test (QA record)

Run on **one Android** and **one iOS** build (or emulator). Attach results to the release PR.

## Setup

- [ ] Screen reader on: **TalkBack** (Android) or **VoiceOver** (iOS).
- [ ] Start from cold launch; log app version and device/OS.

## Global

- [ ] **AEGIS HUD** (shield + label): read order makes sense; not duplicated in a confusing way.
- [ ] **Bottom navigation**: four tabs reachable in order; focus moves predictably.

## Bridge

- [ ] **Monolith** area: focus lands on interactive controls; long-press kill path does not trap focus.
- [ ] **Outlets** (NOT TODAY, ASMR, DICTIONARY, ADVOCACY): each activatable; label matches visible text.

## ASMR Pharmacy

- [ ] Playback sheet: **PLAY/PAUSE**, volume/output, waveform region (if present) have usable focus.
- [ ] No critical control only exposed by color.

## Vistas / Island

- [ ] Mode strip **VISTA / VOICE / KINETIC** and **MENU / ACTIVE** readable and tappable.

## Contrast (quick)

- [ ] Primary body text readable against `#0A0A0A` / `#121212` in bright room (subjective OK/Fail).

## Notes

| Area | Pass/Fail | Tester | Date |
|------|-----------|--------|------|
| TalkBack | | | |
| VoiceOver | | | |
