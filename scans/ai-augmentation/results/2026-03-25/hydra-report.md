# AAMM — Sample Report: cardano-scaling/hydra

**Model version:** 1.0 · **Scan date:** 2026-03-25 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **67.01 / 100** | Navigate: 98.28, Understand: 50.50, Verify: 66.50. Penalties: -5. |
| **AI Adoption** | **0 / 100** | Code: None, Testing: None, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (hydra)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## Domain Profile: Blockchain

**Detected via:** repo topics

**AI Value Framing:** AI as adversarial reviewer/challenger/auditor on critical code; quality driver on docs/tests/PRs; code generator only on boilerplate/serialization

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
| Formal spec presence | ✗ | Not detected |
| Conformance testing | ✗ | Not detected |
| Generator discipline | ✓ | cover/classify=1, custom Arbitrary=1, adversarial=1 |
| Concurrency testing (io-sim) | ✓ | io-sim=1 |
| Benchmark regression | ✓ | files=13, dirs=7, CI regression=1 |
| Strict evaluation discipline | ✓ | StrictData/BangPatterns=1 |
| .aiignore on critical paths | ✗ | 0 |

---

## AI Readiness: 67.01 / 100

### Pillar 1: Navigate — 98.28 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=7, directories=270 |
| N2 | file_granularity | **96** | 0.13 | median_lines=59, large_files=2, per_file_penalty=-4 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=1, package_manifests=12 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=18 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_enforced=1, configs=4 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=10, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=2 |
| N8 | repo_foundations | **85** | 0.08 | codeowners=1, gitignore_cats=2(20), security_md=1 |

---

### Pillar 2: Understand — 50.50 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | Haskell → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **20** | 0.15 | readme_lines=100, desc=1, setup=0, usage=0, arch=0, contrib=0 |
| U4 | architecture_docs | **75** | 0.15 | adrs=32, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 66.50 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (129 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **75** | 0.30 | ratio=.697 (129 test / 185 source) |
| V2 | test_categorization | **100** | 0.20 | detected_categories=4 [property,golden,spec/bdd,unit] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 98.28 × 0.35 + 50.50 × 0.35 + 66.50 × 0.30
              = 72.01

Constraints: none applied

Penalties: -5
Readiness = 67.01
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 0 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | None —  |
| **L2_commits** | L2 | None —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | None —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | None | 0 | ✓ linter=1, codeowners=1 | ✗ no AI config with Architecture + Conventions | Practice active, no AI config |
| **Testing** | None | 0 | ✓ test execution found in CI workflows | ✗ no AI config with Testing category | Practice active, no AI config |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover Haskell | ✗ no AI config with Security category | No AI presence |
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=113) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✗ no AI config files | ✗ no usage expectations or .aiignore | No AI presence |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `cardano-scaling/hydra` |
| Description | Implementation of the Hydra Head protocol |
| Default branch | `master` |
| Private | false |
| Primary language | Haskell (94.5%) |
| Languages | Haskell: 94.5%,Nix: 2.6%,Shell: 1.4%,HCL: 0.7%,Aiken: 0.5% |
| Size | 326426 KB |
| Open issues | 113 |
| Stars | 334 |
| License | Apache-2.0 |
| Created | 2021-03-01T13:45:19Z |
| Last push | 2026-03-25T11:41:07Z |
| Tree entries | 1170 |
| Source files | 185 |
| Test files | 129 |
| Directories | 270 |
| Max depth | 7 |

### Score Summary

```
Navigate   = 98.28  (weight 0.35)
Understand = 50.50  (weight 0.35)
Verify     = 66.50  (weight 0.30)

Readiness_raw = 72.01
Penalties: -5
Readiness = 67.01

Adoption composite = 0
  Code: None (0), Testing: None (0), Security: None (0), Delivery: None (0), Governance: None (0)

Quadrant: Fertile Ground
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 2

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — Haskell repos typically have Haddock docs. Agent should sample 10 largest + 5 most recent .hs files for {- | -} / -- | doc comments. | override_recommended |
| nav_und_gap | warning | Navigate (98.28) >> Understand (50.50). Well-structured codebase but AI can't understand intent. Typically means docs/comments gap. High-impact improvement area. | operator_attention |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations

### Start AI Adoption

**Zero AI adoption detected.** Quick wins to establish AI presence:

1. **Add `CLAUDE.md`** (or equivalent AI config) with:
   - Architecture: module boundaries, package structure, key abstractions
   - Conventions: Haskell idioms, strictness policy, export conventions
   - Testing: test framework (hspec/tasty/QuickCheck), how to run tests, coverage expectations
   - Build system: Nix + Cabal setup, GHC version, how to enter dev shell
   - Security: which modules handle crypto/consensus (where AI should review, not generate)

2. **Enable AI-assisted PR review** — lowest risk, highest immediate value. AI reviews documentation, test coverage gaps, and style consistency.


### Blockchain-Specific AI Value

Frame AI as **adversarial reviewer**, not code generator, on critical paths:

| AI Role | Where to Apply | Example |
|---------|---------------|---------|
| **Threat modeler** | Ledger rules, tx validation | "What if amount overflows? What if block has 0 txs?" |
| **Completeness auditor** | Conformance tests | "Spec defines 14 UTXO rules, tests cover 11 — missing rules 7, 12, 14" |
| **Generator quality reviewer** | Property tests | "genBlock never produces >100 txs, cover shows 0% on txCount>50" |
| **Performance challenger** | Hot paths | "This fold on Map.union is O(n×m) per block — benchmark?" |
| **API/interface reviewer** | Cross-component boundaries | "Error type for applyTx doesn't distinguish recoverable from fatal" |
| **Documentation driver** | Haddock, README, ADRs | "Generate docs for all exported types in this era module" |

**Add `.aiignore`** excluding consensus/crypto paths — signals mature AI governance and prevents AI from generating code in critical modules.

### Improve AI Understanding (Understand: 50.50/100)

- **Documentation coverage (U2=25):** Add Haddock comments (`{- | -}` / `-- |`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **README substance (U3=20):** Add Architecture and Usage sections to README. AI agents read README first — a good README multiplies AI effectiveness across all tasks.

