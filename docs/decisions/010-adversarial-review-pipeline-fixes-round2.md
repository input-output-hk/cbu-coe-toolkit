# ADR-010: Adversarial Review Pipeline Fixes — Round 2

**Date:** 2026-03-26 · **Status:** Accepted
**Applies to:** `scripts/aamm/score-readiness.sh`, `scripts/aamm/review-scores.sh`, `models/ai-augmentation-maturity/readiness-scoring.md`

## Rule

Nine additional scoring pipeline bugs are fixed, discovered by dispatching adversarial review agents on scan output for cardano-node, mithril, and lace-platform. Peer-reviewed before implementation.

| Bug | Signal | Fix | Impact |
|-----|--------|-----|--------|
| U2 ignores doc-coverage.json | U2 | Fallback to `doc-coverage.json` when `sampled_u2_*` yields 0 pub items | mithril U2: 25→100 |
| V1 no Rust inline test override | V1 | Auto-detect `#[cfg(test)]` in sampled files, bump V1 when >50% have inline tests | mithril V1: 25→50 |
| Branch protection 404 = false penalty | BP | Treat 404 same as 403 — check PR review rate as counter-evidence | All 3: -5→0 |
| N5 misses npm/nx CI patterns | N5 | Add `check:lint`, `check:format`, `nx --target=lint`, `cargo fmt` to CI detection | lace-platform N5: 80→100 |
| V2 misses unit tests (.test.ts, #[cfg(test)]) | V2 | Detect `.test.ts` (excluding E2E dirs), Rust inline tests, CI frameworks, visual regression | All 3: V2→100 |
| U5 misses contract-first architecture | U5 | Detect `packages/contract/` directories + schema deps (zod, io-ts, yup, joi) | lace-platform U5: 0→50 |
| review-scores.sh no N5 fallback for TS/Rust | N5 | Add TypeScript (npm/nx) and Rust (clippy/rustfmt) CI detection as review correction | Safety net |
| Domain supplementary signals note-only | Domain | Apply `_inferred` corrections when strong file evidence exists | cardano-node generators |
| `grep -c` returns `0\n0` under pipefail | All | Replace `|| echo 0` with `|| true` + `${var:-0}` default | Fixes silent script death |

## Anti-patterns

- Do NOT use `grep -c ... || echo 0` with `set -euo pipefail` — grep outputs "0" AND exits 1, then `|| echo 0` adds another "0" = `0\n0`. Use `|| true` and `${var:-0}` instead.
- Do NOT assume `.test.ts` = unit test without checking directory context — E2E directories contain `.test.ts` files too.
- Do NOT scan `node_modules/` in the tree — the collection step explicitly excludes it.
- Do NOT change scoring behavior without updating `readiness-scoring.md` — per CLAUDE.md sync protocol.

## Context

After ADR-007 fixed 6 bugs, a second round of adversarial review (dispatching 3 parallel reviewer agents for cardano-node, mithril, lace-platform) found 18 additional issues per repo. 9 were pipeline bugs; the rest were annotation/evidence improvements. The adversarial review pattern proved highly effective — reviewer agents challenged each of the 17 readiness signals from both CoE and team perspectives.

Plan was peer-reviewed before implementation. 3 blocking issues were addressed: B1 (false positive on .test.ts), B2 (dead code node_modules scan), B3 (spec sync required).

## Consequences

- **Changed:** `score-readiness.sh` (N5, U2, U5, V1, V2, BP detection), `review-scores.sh` (N5 TS/Rust, domain corrections), `readiness-scoring.md` (N5, V2, U5 spec sync)
- **Score impact:** cardano-node +11.6, mithril +15.3, lace-platform +11.5 readiness points
- **New pattern established:** Adversarial review as standard scan step (added to skill, backlog item P1 #3)
- **Scan skill updated:** `SKILL.md` now has correct invocation instructions (source zshrc, cd to toolkit, no pipe, no subagents for bash)
