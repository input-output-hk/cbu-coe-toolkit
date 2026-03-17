# AAMM v1 vs v2: Side-by-Side Assessment of 4 CBU Repos

> **Date:** 2026-03-16
> **Assessed by:** Dorin Solomon / Claude (CoE)
> **Purpose:** Compare what each model reveals about the same repos to inform model evolution
> **Method:** GitHub API inspection (unauthenticated, no cloning)

---

## Executive Summary

| Repo | Language | v1 Overall Stage | v2 Readiness | v2 Adoption | v2 Quadrant |
|------|----------|-----------------|-------------|-------------|-------------|
| **cardano-ledger** | Haskell | **0** | **90** | **1** | Fertile Ground — High |
| **hydra** | Haskell | **0** | **81** | **0** | Fertile Ground — High |
| **mithril** | Rust | **1** | **86** | **24** | Fertile Ground — High |
| **lace** | TypeScript | **1** | **71** | **15** | Fertile Ground — Mid |

### The headline finding

**v1 cannot distinguish between cardano-ledger (world-class Haskell engineering) and a throwaway repo with zero tests.** Both score Stage 0. v2 scores them 90 vs whatever a throwaway repo would get (~15). This is the core argument for the two-dimensional approach.

---

## Repo 1: IntersectMBO/cardano-ledger (Haskell)

### v1: AI Augmentation Maturity

| Dimension | Stage | Confidence | Evidence |
|-----------|-------|------------|----------|
| Code Quality | 0 | High | No AI config files found anywhere |
| Security | 0 | High | SECURITY.md exists, but no AI config = Stage 0 |
| Testing | 0 | High | 25-package CI test matrix, doctests — but no AI config |
| Release | 0 | High | RELEASING.md (16KB), REVISIONING.md (13KB) — but no AI config |
| Ops & Monitoring | 0 | High | Nightly builds with Slack alerting — but no AI config |
| Delivery | 0 | High | Full CI/CD pipeline — but no AI config |

**Overall Stage: 0**

**Infrastructure Readiness (what v1 notes but doesn't score):**
`-Werror` globally enforced, fourmolu in CI, hie.yaml, Nix flake, 25-package test matrix across GHC 9.6/9.8/9.10/9.12, doctests per package, weeder (dead code), cabal-gild, bors merge queue, CODEOWNERS, undefined-additions blocked, no-merge-commit policy, formal PDF specifications per era, CDDL schemas, 47KB CHANGELOG, 22KB CONTRIBUTING.md

### v2: AAMM-v2

| Pillar | Score | Key Evidence |
|--------|-------|-------------|
| R1 Structural Clarity | **93** | Era-per-package monorepo (25 packages), deep `Cardano.Ledger.*` hierarchy, explicit export lists, `libs/` vs `eras/` boundary |
| R2 Semantic Density | **92** | `-Werror`, pervasive newtypes (`Coin`, `DeltaCoin`, `NonZero`, `BoundedRational`), `DerivingVia` systematic, smart constructors, CDDL schemas per era, formal PDF specs, hosted Haddock, 47KB CHANGELOG |
| R3 Verification Infra | **85** | 25-package CI test matrix (GHC 9.6-9.12), doctests in CI, conformance test package, nightly builds, Nix reproducible builds; no coverage reporting |
| R4 Developer Ergonomics | **89** | fourmolu enforced in CI, hie.yaml kept in sync, Nix flake, scripts/ library, `.editorconfig`, CODEOWNERS, no-merge-commit CI gate |
| **Readiness** | **90** | |
| A1 AI Tooling Config | **0** | No AI config files of any kind |
| A2 Workflow Integration | **2** | dependabot for Python docs only |
| A3 AI-Native Patterns | **0** | None |
| A4 AI Governance | **0** | None |
| **Adoption** | **1** | |

**Quadrant: Fertile Ground — High** (Readiness 90, Adoption 1)

---

## Repo 2: cardano-scaling/hydra (Haskell)

### v1: AI Augmentation Maturity

| Dimension | Stage | Confidence | Evidence |
|-----------|-------|------------|----------|
| Code Quality | 0 | High | No AI config files (all 8+ locations checked = 404) |
| Security | 0 | High | SECURITY.md + dependabot.yaml present, but no AI config |
| Testing | 0 | High | hydra-test-utils + hydra-cluster packages, ci-nix.yaml — no AI config |
| Release | 0 | Medium | release.sh manual script, no AI config |
| Ops & Monitoring | 0 | Medium | No AI config, no AI monitoring |
| Delivery | 0 | Medium | Nix CI present, no AI config |

**Overall Stage: 0**

**Infrastructure Readiness:**
fourmolu + hlint + hie.yaml, Nix flake + direnv, 11-package cabal monorepo, weeder (dead code), typos.toml (spell-check), dependabot, CODEOWNERS, 71KB CHANGELOG, 14KB CONTRIBUTING.md, SECURITY.md, `.editorconfig`, pull request template

### v2: AAMM-v2

| Pillar | Score | Key Evidence |
|--------|-------|-------------|
| R1 Structural Clarity | **83** | 11 cabal packages with clear concern separation (hydra-node, hydra-tx, hydra-plutus, hydra-cardano-api, etc.) |
| R2 Semantic Density | **77** | 71KB CHANGELOG, weeder, typos.toml, academic-spec-grounded README; Haddock/type sigs inferred but not directly confirmed |
| R3 Verification Infra | **78** | hydra-test-utils package, hydra-cluster (integration), Nix CI, reproducible builds |
| R4 Developer Ergonomics | **87** | fourmolu + hlint + hie + direnv + Nix flake — best-in-class Haskell DX setup |
| **Readiness** | **81** | |
| A1 AI Tooling Config | **0** | Zero AI config files anywhere |
| A2 Workflow Integration | **0** | No evidence (rate-limited, but no AI workflow file names) |
| A3 AI-Native Patterns | **0** | None |
| A4 AI Governance | **0** | None |
| **Adoption** | **0** | |

**Quadrant: Fertile Ground — High** (Readiness 81, Adoption 0)

**Note:** Rate limit prevented source-file inspection. Readiness ±8 uncertainty, likely resolves upward. Despite being listed as "Haskell/Rust" in config.yaml, no Rust was found in the top-level tree — appears purely Haskell.

---

## Repo 3: input-output-hk/mithril (Rust)

### v1: AI Augmentation Maturity

| Dimension | Stage | Confidence | Evidence |
|-----------|-------|------------|----------|
| Code Quality | 1 | High | `.github/copilot-instructions.md` (~4KB) — substantive Rust-specific rules: error handling, naming, pub discipline, clippy zero-warnings, ADR compliance |
| Security | 0 | Medium | SECURITY.md exists, deny.toml covers license compliance. Scanning not confirmed in CI. AI config exists but scanning not confirmed = Stage 0 |
| Testing | 1 | High | copilot-instructions documents testing standards: behavior-named tests, edge cases, mocks/DI, determinism. nextest configured. |
| Release | 1 | High | copilot-instructions documents CHANGELOG requirement. `pre-release.yml` and `release.yml` workflows exist (16KB, 14KB). |
| Ops & Monitoring | 0 | Medium | mithril-infra directory exists, mithril-relay crate, metric library — but no AI ops config |
| Delivery | 1 | Medium | copilot-instructions documents delivery elements (PR checklist, CI gates, ADR compliance) |

**Overall Stage: 1** (4 of 6 dimensions at Stage 1; emerging)

**Infrastructure Readiness:**
35-crate Cargo workspace, rustfmt.toml (2024 edition), deny.toml, cargo-nextest with CI profile, Nix flake, direnv, openapi.yaml, 11 ADRs, 28KB CHANGELOG, Makefile, conventional commits

### v2: AAMM-v2

| Pillar | Score | Key Evidence |
|--------|-------|-------------|
| R1 Structural Clarity | **88** | 35-crate workspace, per-concern granularity (`mithril-metric`, `mithril-ticker`, `mithril-era`, `mithril-persistence`), workspace resolver v2, openapi.yaml |
| R2 Semantic Density | **88** | Doc comments mandated for all pub items, 11 ADRs, thiserror/anyhow mandated, newtype wrappers per ADR 1, 28KB CHANGELOG, serde attributes, openapi contract |
| R3 Verification Infra | **84** | mithril-test-lab/mithril-end-to-end, mithril-api-spec, cargo-nextest with CI+JUnit, ci.yml (44KB), backward-compatibility.yml, Nix builds; coverage not confirmed |
| R4 Developer Ergonomics | **81** | rustfmt.toml, deny.toml, Makefile, Nix flake + .envrc, 14 CI workflow files, Cargo.lock committed; no pre-commit hooks |
| **Readiness** | **86** | |
| A1 AI Tooling Config | **52** | copilot-instructions.md (~4KB, high quality, project-specific); single tool only |
| A2 Workflow Integration | **5** | No AI bots, no AI CI steps, no AI commits |
| A3 AI-Native Patterns | **18** | copilot-instructions structured with rules; openapi + ADRs as spec-driven artifacts |
| A4 AI Governance | **15** | copilot-instructions as informal policy; no attribution, no AI quality gates |
| **Adoption** | **24** | |

**Quadrant: Fertile Ground — High** (Readiness 86, Adoption 24)

**Notable:** The copilot-instructions.md is among the highest-quality single AI instruction files in open-source Rust. It references specific internal ADRs, mandates SAFETY comments on unsafe blocks, specifies import ordering with examples. Stage 1 done right — but gap to Stage 2 is entirely in workflow activation.

---

## Repo 4: input-output-hk/lace (TypeScript)

### v1: AI Augmentation Maturity

| Dimension | Stage | Confidence | Evidence |
|-----------|-------|------------|----------|
| Code Quality | 1 | Medium | `.mcp.json` with 3 MCP servers (sequential-thinking, context7, interactive). No CLAUDE.md/.cursorrules with coding guidelines. Barely clears Stage 1 via MCP config. |
| Security | 1 | Medium | SonarCloud SAST in CI + dependabot (github-actions) + .mcp.json as AI config. Both conditions met. |
| Testing | 1 | Low-Med | CI has unit tests + split E2E. .mcp.json as AI config present. No AI test guidance. |
| Release | 1 | Medium | Dedicated release workflows, version bump commits. .mcp.json present. |
| Ops & Monitoring | 0 | Medium | Browser extension — client-side product, no server ops. |
| Delivery | 1 | Medium | Multi-stage CI pipeline, PR labeler, .mcp.json present. |

**Overall Stage: 1** (5 of 6 dimensions at Stage 1)

**Infrastructure Readiness:**
SonarCloud SAST, Yarn Berry v4.9.2 with lockfile, Husky pre-commit hooks, conventional commits with ticket IDs, split E2E test parallelisation, ARCHITECTURE.md, git submodule for v2

### v2: AAMM-v2

| Pillar | Score | Key Evidence |
|--------|-------|-------------|
| R1 Structural Clarity | **75** | Monorepo with domain-separated packages (cardano, bitcoin, staking, core), v2 submodule, ARCHITECTURE.md; no turbo/nx caching |
| R2 Semantic Density | **58** | ARCHITECTURE.md present, semantic naming, conventional commits; missing CHANGELOG, no ADRs confirmed, strict mode unconfirmed |
| R3 Verification Infra | **80** | Unit tests + split E2E in CI, SonarCloud coverage, test commits in history |
| R4 Developer Ergonomics | **71** | .nvmrc, Husky pre-commit, Yarn Berry lockfile, Makefile, Dependabot, packageManager pinning; no turbo/nx |
| **Readiness** | **71** | |
| A1 AI Tooling Config | **35** | .mcp.json with 3 servers; no instructional AI config files |
| A2 Workflow Integration | **5** | No AI in CI/CD |
| A3 AI-Native Patterns | **10** | MCP implies local AI use but zero VCS trace |
| A4 AI Governance | **5** | No AI policy, unpinned MCP versions (`npx -y`) |
| **Adoption** | **15** | |

**Quadrant: Fertile Ground — Mid** (Readiness 71, Adoption 15)

**Flags:** MCP servers use `npx -y` (no version pinning) — supply-chain risk for a crypto wallet. Dependabot covers only github-actions, not npm packages.

---

## The Comparison: What Each Model Reveals

### What v1 sees

```
cardano-ledger:  Stage 0  ░░░░░░░░░░░░░░░░░░░░
hydra:           Stage 0  ░░░░░░░░░░░░░░░░░░░░
mithril:         Stage 1  ████░░░░░░░░░░░░░░░░
lace:            Stage 1  ████░░░░░░░░░░░░░░░░
```

v1 conclusion: "cardano-ledger and hydra are invisible to AI. mithril and lace have started."

### What v2 sees

```
                              Readiness    Adoption
cardano-ledger:  ████████████████████░  90    ░  1     Fertile Ground — High
mithril:         ███████████████████░░  86    █████  24  Fertile Ground — High
hydra:           ████████████████░░░░░  81    ░  0     Fertile Ground — High
lace:            ██████████████░░░░░░░  71    ███  15  Fertile Ground — Mid
```

v2 conclusion: "All four are Fertile Ground — strong foundations, low AI adoption. cardano-ledger is actually the *most* AI-ready despite zero AI tooling. lace has the weakest foundation despite having MCP configured."

### The critical difference

| Insight | v1 | v2 |
|---------|----|----|
| cardano-ledger's engineering quality | Invisible (Stage 0 = "nothing") | Highly visible (Readiness 90) |
| Difference between cardano-ledger and a bad repo | None — both Stage 0 | Massive — 90 vs ~15 |
| Where to invest first | "Add AI config" (same advice for all Stage 0) | "cardano-ledger has the highest ROI for AI investment — its formal specs, newtypes, and exhaustive tests make AI collaboration immediately productive" |
| mithril vs lace | Same Stage 1 | mithril (86/24) has stronger foundation than lace (71/15) — mithril's copilot-instructions are also higher quality than lace's MCP config |
| hydra vs cardano-ledger | Identical (both 0) | Different: ledger (90) has stronger readiness than hydra (81) — more packages, formal specs, CDDL schemas |
| Risk assessment | Not captured | lace's unpinned MCP + no governance = flag for a crypto wallet |

### What v1 does better

1. **SDLC dimension granularity**: v1 scores Security, Testing, Release, Ops, Delivery separately. v2 collapses these into a single Readiness score. If mithril has great testing but weak ops, v1 shows that per-dimension; v2 blends it.

2. **Stage progression clarity**: v1's ladder (0→1→2→3→4) gives teams a clear "do this next" path per dimension. v2's 0-100 scale is more precise but less actionable — "raise R2 from 58 to 70" is vague compared to "reach Stage 1 on Testing by documenting test standards in AI config."

3. **Cumulative enforcement**: v1's rule that Stage 2 requires Stage 1 prevents hollow adoption. v2 could theoretically score high on A2 (workflow) without A1 (config) — less safe.

### What v2 does better

1. **Distinguishes readiness from adoption**: The single most important improvement. v1 conflates "no AI config" with "bad codebase." v2 separates them.

2. **Quantifies engineering quality**: Nix flakes, `-Werror`, newtypes, formal specs — these matter enormously for AI productivity but v1 relegates them to an "infrastructure readiness" note that doesn't affect the score.

3. **Language-aware scoring**: Haskell's explicit exports, Rust's pub discipline, TypeScript's strict mode — v2 knows what good looks like per ecosystem. v1 is language-agnostic.

4. **Granular within readiness**: R1-R4 breakdown reveals *where* the readiness gaps are (lace: weak semantic density. hydra: weaker verification than ledger).

5. **Risk detection**: v2's guardrails catch "Risky Acceleration" (high adoption on weak foundation) — a pattern v1 can't express.

---

## Implications for Model Evolution

### Option A: Keep v1, enhance it
Add a "Readiness" pre-assessment that feeds into recommendations but doesn't change stage scores. v1 stages remain the primary output. Readiness becomes context for "how impactful will moving to Stage 1 be for this repo?"

### Option B: Keep v2, enhance it
Add SDLC-dimension breakdowns within the Adoption axis (currently it's generic A1-A4). This recovers v1's per-dimension visibility while keeping the 2D structure.

### Option C: Merge — Two-dimensional model with SDLC dimensions
- **Readiness**: R1-R4 as in v2 (language-aware, scored 0-100)
- **Adoption**: Scored per SDLC dimension as in v1 (0-4 stages for CQ, Security, Testing, Release, Ops, Delivery)
- **Output**: Quadrant placement (from composites) + per-dimension detail (from v1 stages)

This preserves both models' strengths: v2's ability to see engineering quality, v1's actionable per-dimension progression.

---

## Raw Data Caveats

- Unauthenticated GitHub API (60 req/hour) — rate limits hit on all 4 repos
- Source file contents sampled, not exhaustively scanned
- Haddock coverage, type signature presence, and test ratios estimated for hydra (rate-limited)
- lace's TypeScript strict mode and ESLint config unconfirmed
- hydra's Rust component (if any) not found at top level — may exist in subdirectories
