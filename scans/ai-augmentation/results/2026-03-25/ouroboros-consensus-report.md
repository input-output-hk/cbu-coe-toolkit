# AAMM — Sample Report: IntersectMBO/ouroboros-consensus

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
| **AI Readiness** | **71.89 / 100** | Navigate: 98.70, Understand: 64.00, Verify: 66.50. Penalties: -5. |
| **AI Adoption** | **0 / 100** | Code: None, Testing: None, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (ouroboros-consensus)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## Domain Profile: Blockchain

**Detected via:** repo topics, description, .agda files (82), formal-spec dirs, .cddl files (13)

**AI Value Framing:** AI as adversarial reviewer/challenger/auditor on critical code; quality driver on docs/tests/PRs; code generator only on boilerplate/serialization

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
| Formal spec presence | ✓ | 82 .agda files, 1 formal-spec dirs, 13 .cddl files |
| Conformance testing | ✓ | 23 conformance dirs, oracle=0 |
| Generator discipline | ✓ | cover/classify=1, custom Arbitrary=1, adversarial=1 |
| Concurrency testing (io-sim) | ✓ | io-sim=1 |
| Benchmark regression | ✓ | files=10, dirs=11, CI regression=1 |
| Strict evaluation discipline | ✗ | StrictData/BangPatterns=0 |
| .aiignore on critical paths | ✗ | 0 |

---

## AI Readiness: 71.89 / 100

### Pillar 1: Navigate — 98.70 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=11, directories=493 |
| N2 | file_granularity | **90** | 0.13 | median_lines=107, large_files=5, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=3, package_manifests=5 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=10 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_enforced=1, configs=2 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=3, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=2 |
| N8 | repo_foundations | **100** | 0.08 | codeowners=1, gitignore_cats=4(35), security_md=1 |

---

### Pillar 2: Understand — 64.00 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | Haskell → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **60** | 0.15 | readme_lines=186, desc=1, setup=1, usage=1, arch=0, contrib=0 |
| U4 | architecture_docs | **25** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **100** | 0.15 | schema_files=13 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 66.50 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (276 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **75** | 0.30 | ratio=.665 (276 test / 415 source) |
| V2 | test_categorization | **100** | 0.20 | detected_categories=5 [unit,property,golden,conformance,spec/bdd] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=1 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 98.70 × 0.35 + 64.00 × 0.35 + 66.50 × 0.30
              = 76.89

Constraints: none applied

Penalties: -5
Readiness = 71.89
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
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=478) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✗ no AI config files | ✗ no usage expectations or .aiignore | No AI presence |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `IntersectMBO/ouroboros-consensus` |
| Description | Implementation of a Consensus Layer for the Ouroboros family of protocols |
| Default branch | `main` |
| Private | false |
| Primary language | Haskell (99%) |
| Languages | Haskell: 99%,Shell: 0.5%,Nix: 0.3%,Gnuplot: 0.1%,Python: 0% |
| Size | 69099 KB |
| Open issues | 478 |
| Stars | 63 |
| License | Apache-2.0 |
| Created | 2022-12-06T11:54:50Z |
| Last push | 2026-03-25T13:11:02Z |
| Tree entries | 3195 |
| Source files | 415 |
| Test files | 276 |
| Directories | 493 |
| Max depth | 11 |

### Score Summary

```
Navigate   = 98.70  (weight 0.35)
Understand = 64.00  (weight 0.35)
Verify     = 66.50  (weight 0.30)

Readiness_raw = 76.89
Penalties: -5
Readiness = 71.89

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
| domain_strict | info | StrictData/BangPatterns not found in .cabal default-extensions or CI files. This repo may use per-module pragmas instead of project-wide defaults. | info_only |

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

### Improve AI Understanding (Understand: 64.00/100)

- **Documentation coverage (U2=25):** Add Haddock comments (`{- | -}` / `-- |`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **Architecture docs (U4=25):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

