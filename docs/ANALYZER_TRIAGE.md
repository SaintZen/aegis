# Analyzer triage (CI / `flutter analyze`)

`flutter analyze` may report hundreds of **info**-level items (e.g. deprecated `withOpacity`) while **errors** must be zero for a healthy build.

## Priority

1. Fix all **`error`** lines first (undefined names, invalid const, missing getters).
2. Triage **`warning`** (unused members, dead null-aware).
3. Schedule **`info`** (deprecations, style) over time or per-directory.

## CI behavior

- GitHub Actions runs `flutter analyze` — non-zero exit fails the job if the analyzer returns issues at configured severity.
- To treat **warnings as non-blocking** temporarily, adjust `analysis_options.yaml` or fix warnings; avoid blanket `ignore_for_file` on `lib/` without review.

## Low-noise commands

```bash
dart fix --dry-run
dart fix --apply   # after review
```

## Deprecation batch

Replacing `Color.withOpacity(x)` with `withValues(alpha: x)` can be done incrementally by directory to keep PRs reviewable.
