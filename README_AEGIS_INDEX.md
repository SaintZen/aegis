# README_AEGIS_INDEX

```text
AEGIS SYSTEM INDEX :: CENTRAL HUB :: V1.0
LAYOUT MODE       :: MONOSPACED / TECHNICAL
SCOPE             :: LOGIC + PROTOCOLS + DEFINITIONS + CORE HARDWARE
```

## `CANONICAL DOCUMENT LINKS`

- [`aegis-core.mdc`](.cursor/rules/aegis-core.mdc)  `:: MASTER LOGIC CONSTRAINTS`
- [`AEGIS_OPERATOR_MANUAL.md`](AEGIS_OPERATOR_MANUAL.md)  `:: SYSTEM ARCHITECTURE + OPERATIONS`
- [`AEGIS_GLOSSARY.md`](AEGIS_GLOSSARY.md)  `:: UNIFIED TERMINOLOGY`

## `EXTENDED SPEC REFERENCES`

- [`AEGIS_SOMATIC_PROTOCOL_LIBRARY.md`](AEGIS_SOMATIC_PROTOCOL_LIBRARY.md)  `:: SOMATIC PROCEDURE SET`
- [`AEGIS_DEPTH_INDEX.md`](AEGIS_DEPTH_INDEX.md)  `:: STRATA PERSISTENCE MODEL`
- [`AEGIS_KILL_SWITCH_SPECIFICATION.md`](AEGIS_KILL_SWITCH_SPECIFICATION.md)  `:: OVERRIDE PATHWAY`

## `CORE IMPLEMENTATION PATHS`

```text
BRIDGE SURFACE      -> lib/screens/bridge_screen.dart
LAB DIAGNOSTIC ARC  -> lib/screens/anxiety_lab_screen.dart
HOLLOW INTERFACE    -> lib/screens/hollow_screen.dart
VAULT CONTAINMENT   -> lib/screens/worry_vault_screen.dart
VOID PURGE ENGINE   -> lib/screens/wormhole_screen.dart
LEDGER EXPORT       -> lib/services/pdf_generator_service.dart
```

## `COLD SCAN TARGETS`

```text
STRING FILTERS      :: "social" | "soft" | "clinical"
SCAN DOMAIN         :: lib/**/*.dart UI STRINGS
BRIDGE BASELINE     :: #000000 FLOOR + READY STATUS
```

## `VERIFICATION SNAPSHOT`

```text
CHECKPOINT          :: ACTIVE
BRIDGE FLOOR        :: 0xFF000000
BRIDGE STATUS       :: READY
EXPORT MODE         :: Printing.layoutPdf (DIRECT STREAM)
```
