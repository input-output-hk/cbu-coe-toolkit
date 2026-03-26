# ADR-004: Scoring methodology corrections

**Date:** 2026-03-26 · **Status:** Accepted
**Applies to:** `scripts/aamm/score-readiness.sh`, `scripts/aamm/review-scores.sh`, `scripts/aamm/collect-readiness.sh`, `scripts/aamm/generate-report.sh`, `models/ai-augmentation-maturity/readiness-scoring.md`

## Rule

Scoring detection must use specific tool names (not generic keywords), check all plausible locations (not just one), and track per-tool CI enforcement (not a single boolean). Evidence strings in markdown must escape pipe characters.

## Anti-patterns

- **Generic regex matching:** `coverage` matches non-coverage strings, `--min` matches `--minimize-conflict-set`. Always use specific tool names (`codecov`, `hpc`, `tarpaulin`) and require context for threshold detection (`coverage.*threshold`, not `--min`).
- **Single-source detection:** Concluding "tool absent" from one check (e.g., `.hlint.yaml` in tree). Nix projects define tools in `flake.nix`. Always check: tree files, `flake.nix`, CI workflows, package manifests.
- **Single CI boolean:** `CI_LINT=1` can't distinguish "formatter in CI" from "linter in CI." Use `CI_LINTER` + `CI_FORMATTER` separately. Score 100 only when BOTH are CI-enforced.
- **Hardcoded heading level:** `## *` misses `#` (H1) headings. Use `#{1,6} *` for any heading level.
- **Unescaped pipes in markdown:** Haddock syntax `-- |` breaks markdown table columns. Escape `|` as `\|` in all evidence strings.

## Context

Exhaustive rescan of cardano-ledger (session 7) found 5 scoring bugs: N5 false negative (hlint in flake.nix invisible), U2 never sampled, U3 missed H1 headings, V4 false positive (generic regex), N5 CI over-counted (single boolean). Original score 80.07 had correct total by accident — composition was fundamentally wrong (V4=100 when actual=0).

## Consequences

- **Changed:** score-readiness.sh (N5 per-tool CI, U3 heading regex, V4 specific regex), collect-readiness.sh (flake.nix fetch), review-scores.sh (per-tool CI), generate-report.sh (pipe escaping), readiness-scoring.md (N5/U3/V4 spec updates)
- **Must maintain:** When adding new detection patterns, use specific tool names. When adding new regex for CI, test against real workflow files for false matches.
