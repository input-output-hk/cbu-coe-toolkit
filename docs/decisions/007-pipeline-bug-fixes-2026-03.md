# ADR-007: Pipeline Bug Fixes — March 2026 Adversarial Review

**Date:** 2026-03-26 · **Status:** Accepted
**Applies to:** `scripts/aamm/collect-readiness.sh`, `scripts/aamm/score-readiness.sh`, `models/ai-augmentation-maturity/readiness-scoring.md`

## Rule

Six deterministic script bugs are fixed. Each bug reproduced on every scan regardless of repo. All changes are backwards-compatible: corrected scores are higher or equal to automated scores (no false inflation).

| Bug | Fix |
|-----|-----|
| Workflow fetch capped at 4 (alphabetical) | Changed to `head -20` |
| CODEOWNERS checked in root only | Now checks root, `.github/`, `docs/` (all valid per GitHub spec) |
| U3 heading regex fails on emoji prefixes | Added `.{0,20}` before keyword to allow up to 20 chars of prefix |
| U2 always returns default 25 | Collects 5 representative source files at scan time; scores by language |
| V3 cannot distinguish PR-only (80) from PR+main (100) | Detects `push: branches: main/master` alongside `pull_request` trigger |
| tsconfig.base.json (NX/Turborepo) not fetched for U1 | Falls back to `tsconfig.base.json` / `tsconfig.app.json` when no root `tsconfig.json` |

## Anti-patterns

- Do NOT set `head -N` on the workflow fetch without a comment explaining why — the cap caused 7+ wrong scores across 3 repos.
- Do NOT grep for CODEOWNERS with `select(.path == "CODEOWNERS")` — always check all three GitHub locations.
- Do NOT use `cargo-deny` (any subcommand) as a proxy for CVE scanning — `check licenses` is not CVE scanning. See ADR-008.

## Context

Adversarial re-scan of mithril (Rust), cardano-node (Haskell), lace-platform (TypeScript) on 2026-03-26 found 18 issues. Six were deterministic script bugs reproduced on every scan. Score drift from these bugs alone: mithril +4.2, cardano-node +7.6, lace-platform +3.1 readiness points.

The U2 bug (always returning 25) is the highest-impact: U2 weight is 0.25 in the Understand pillar (0.35), meaning it affects ~8.75% of total readiness. Autonomous sampling removes the need for manual override on standard languages (Rust, Haskell, TypeScript, Python).

## Consequences

- **Changed:** `collect-readiness.sh` (workflow cap, CODEOWNERS, `.nvmrc`, tsconfig fallback, U2 sampling), `score-readiness.sh` (U3 regex, V3 trigger detection, U2 scoring from samples), `readiness-scoring.md` (U1/U2/U3/V3 How-to-measure)
- **Must maintain:** U2 sampling file naming convention is `sampled_u2_N_<safe-path>` — score script globs `sampled_u2_*` to find them. If collect step changes the naming, score step must match.
- **Language coverage for U2 sampling:** Rust (`///`), Haskell (`-- |`), TypeScript (`/**`), Python (`"""`). Other languages fall back to default 25 with override note.
