# AAMM — Sample Report: IntersectMBO/cardano-node

**Model version:** 1.0 · **Scan date:** 2026-03-26 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **65.40 / 100** | Navigate: 98.70, Understand: 46.75, Verify: 65.00. Penalties: -5. |
| **AI Adoption** | **0 / 100** | Code: None, Testing: None, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (cardano-node)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## Domain Profile: High-assurance

**Detected via:** description

**AI Value Framing:** AI as adversarial reviewer/challenger/auditor on critical code; quality driver on docs/tests/PRs; code generator only on boilerplate/serialization

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
| Formal spec presence | ✗ | Not detected |
| Conformance testing | ✗ | Not detected |
| Generator discipline | ✗ | cover/classify=0, custom Arbitrary=0, adversarial=0 |
| Concurrency testing (io-sim) | ✓ | io-sim=1 |
| Benchmark regression | ✓ | files=521, dirs=164, CI regression=0 |
| Strict evaluation discipline | ✗ | StrictData/BangPatterns=0 |
| .aiignore on critical paths | ✗ | 0 |

### Domain Risk Flags

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | Benchmarks without CI regression detection | Benchmarks exist but no CI-based regression alerting detected |

---

## AI Readiness: 65.40 / 100

### Pillar 1: Navigate — 98.70 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=9, directories=355 |
| N2 | file_granularity | **90** | 0.13 | median_lines=74, large_files=10, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=1, package_manifests=15 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=15 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_linter=1, ci_formatter=1, configs=3 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=16, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=1, lockfile=1 |
| N8 | repo_foundations | **100** | 0.08 | codeowners=1, gitignore_cats=4(35), security_md=1 |

---

### Pillar 2: Understand — 46.75 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | Haskell → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **25** | 0.25 | Agent sampled 1 haskell files: 0/1 pub items documented (0%) → score 25 |
| U3 | readme_substance | **20** | 0.15 | readme_lines=66, desc=1, setup=0, usage=0, arch=0, contrib=0 |
| U4 | architecture_docs | **0** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **50** | 0.15 | schema_files=1 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 65.00 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (100 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **50** | 0.30 | ratio=.250 (100 test / 399 source) |
| V2 | test_categorization | **100** | 0.20 | detected_categories=3 [unit,property,golden] (heuristic — override recommended) |
| V3 | ci_test_execution | **100** | 0.30 | ci_test=1, ci_blocking=1, ci_on_main=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 98.70 × 0.35 + 46.75 × 0.35 + 65.00 × 0.30
              = 70.40

Constraints: none applied

Penalties: -5
Readiness = 65.40
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
| **Security** | None | 0 | ✗ no security scanning detected | ✗ no AI config with Security category | No AI presence |
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=116) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✗ no AI config files | ✗ no usage expectations or .aiignore | No AI presence |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `IntersectMBO/cardano-node` |
| Description | The core component that is used to participate in a Cardano decentralised blockchain. |
| Default branch | `master` |
| Private | false |
| Primary language | Haskell (78.4%) |
| Languages | Haskell: 78.4%,Shell: 12.4%,Nix: 8.2%,Python: 0.4%,C: 0.2% |
| Size | 123063 KB |
| Open issues | 116 |
| Stars | 3178 |
| License | Apache-2.0 |
| Created | 2019-05-23T20:12:22Z |
| Last push | 2026-03-26T07:32:05Z |
| Tree entries | 1527 |
| Source files | 399 |
| Test files | 100 |
| Directories | 355 |
| Max depth | 9 |

### Score Summary

```
Navigate   = 98.70  (weight 0.35)
Understand = 46.75  (weight 0.35)
Verify     = 65.00  (weight 0.30)

Readiness_raw = 70.40
Penalties: -5
Readiness = 65.40

Adoption composite = 0
  Code: None (0), Testing: None (0), Security: None (0), Delivery: None (0), Governance: None (0)

Quadrant: Fertile Ground
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 4

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| domain_generators | warning | 26 generator files (Gen*.hs/Generators.hs) found but none were sampled. Sampling strategy missed generator-specific files. cover/classify/Arbitrary likely present. | resample_recommended |
| domain_conformance | info | No conformance/ directory, but 3 spec-derived test files found (ThreadNet/SpecTest patterns). Conformance testing likely happens through different naming conventions. | verify_manually |
| domain_strict | info | StrictData/BangPatterns not found in .cabal default-extensions or CI files. This repo may use per-module pragmas instead of project-wide defaults. | info_only |
| nav_und_gap | warning | Navigate (98.70) >> Understand (46.75). Well-structured codebase but AI can't understand intent. Typically means docs/comments gap. High-impact improvement area. | operator_attention |

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


### High-Assurance AI Value

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

### Improve AI Understanding (Understand: 46.75/100)

- **Documentation coverage (U2=25):** Add Haddock comments (`{- | -}` / `-- |`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **README substance (U3=20):** Add Architecture and Usage sections to README. AI agents read README first — a good README multiplies AI effectiveness across all tasks.
- **Architecture docs (U4=0):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

