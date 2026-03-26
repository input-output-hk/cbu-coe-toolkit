# AAMM — Sample Report: input-output-hk/io-sim

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
| **AI Readiness** | **47.90 / 100** | Navigate: 72.07, Understand: 39.25, Verify: 46.50. Penalties: -5. |
| **AI Adoption** | **0 / 100** | Code: None, Testing: None, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (io-sim)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## AI Readiness: 47.90 / 100

### Pillar 1: Navigate — 72.07 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=8, directories=73 |
| N2 | file_granularity | **94** | 0.13 | median_lines=46, large_files=3, per_file_penalty=-6 |
| N3 | module_boundaries | **75** | 0.15 | workspace_files=1, package_manifests=2 |
| N4 | separation_of_concerns | **75** | 0.12 | top_level_dirs=4 (heuristic — override recommended) |
| N5 | code_consistency | **60** | 0.13 | linter=0, formatter=1, ci_enforced=0, configs=1 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=3, has_build=1, has_deploy=1, days_since_push=5 |
| N7 | reproducible_env | **0** | 0.12 | flake=0, flake_lock=0, docker=0, lockfile=0 |
| N8 | repo_foundations | **60** | 0.08 | codeowners=0, gitignore_cats=4(35), security_md=1 |

---

### Pillar 2: Understand — 39.25 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | Haskell → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **20** | 0.15 | readme_lines=87, desc=1, setup=0, usage=0, arch=0, contrib=0 |
| U4 | architecture_docs | **0** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 46.50 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (11 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **25** | 0.30 | ratio=.196 (11 test / 56 source) |
| V2 | test_categorization | **75** | 0.20 | detected_categories=2 [property,unit] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 72.07 × 0.35 + 39.25 × 0.35 + 46.50 × 0.30
              = 52.90

Constraints: none applied

Penalties: -5
Readiness = 47.90
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
| **Code** | None | 0 | ✓ linter=1, codeowners=0 | ✗ no AI config with Architecture + Conventions | Practice active, no AI config |
| **Testing** | None | 0 | ✓ test execution found in CI workflows | ✗ no AI config with Testing category | Practice active, no AI config |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover Haskell | ✗ no AI config with Security category | No AI presence |
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=28) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✗ no AI config files | ✗ no usage expectations or .aiignore | No AI presence |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/io-sim` |
| Description | Haskell's IO simulator which closely follows core packages (base, async, stm). |
| Default branch | `main` |
| Private | false |
| Primary language | Haskell (99.9%) |
| Languages | Haskell: 99.9%,Shell: 0.1% |
| Size | 2085 KB |
| Open issues | 28 |
| Stars | 53 |
| License | Apache-2.0 |
| Created | 2022-05-13T14:59:24Z |
| Last push | 2026-03-19T15:24:03Z |
| Tree entries | 173 |
| Source files | 56 |
| Test files | 11 |
| Directories | 73 |
| Max depth | 8 |

### Score Summary

```
Navigate   = 72.07  (weight 0.35)
Understand = 39.25  (weight 0.35)
Verify     = 46.50  (weight 0.30)

Readiness_raw = 52.90
Penalties: -5
Readiness = 47.90

Adoption composite = 0
  Code: None (0), Testing: None (0), Security: None (0), Delivery: None (0), Governance: None (0)

Quadrant: Fertile Ground
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 1

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — Haskell repos typically have Haddock docs. Agent should sample 10 largest + 5 most recent .hs files for {- | -} / -- | doc comments. | override_recommended |

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

### Improve AI Understanding (Understand: 39.25/100)

- **Documentation coverage (U2=25):** Add Haddock comments (`{- | -}` / `-- |`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **README substance (U3=20):** Add Architecture and Usage sections to README. AI agents read README first — a good README multiplies AI effectiveness across all tasks.
- **Architecture docs (U4=0):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

### Strengthen Verification (Verify: 46.50/100)

- **Test/source ratio (V1=25):** Ratio is .196 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Coverage config (V4=0):** Consider HPC integration or property test coverage reporting. For property-heavy repos, conformance completeness metrics (% of spec rules tested) may be more meaningful than line coverage.

