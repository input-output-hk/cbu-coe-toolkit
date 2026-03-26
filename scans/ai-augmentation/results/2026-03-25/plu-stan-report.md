# AAMM — Sample Report: input-output-hk/plu-stan

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
| **AI Readiness** | **57.12 / 100** | Navigate: 82.99, Understand: 48.25, Verify: 54.00. Penalties: -5. |
| **AI Adoption** | **16.50 / 100** | Code: Configured, Testing: Configured, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (plu-stan)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## AI Readiness: 57.12 / 100

### Pillar 1: Navigate — 82.99 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **75** | 0.12 | max_depth=4, directories=27 |
| N2 | file_granularity | **98** | 0.13 | median_lines=67, large_files=1, per_file_penalty=-2 |
| N3 | module_boundaries | **75** | 0.15 | workspace_files=1, package_manifests=1 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=7 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_enforced=1, configs=2 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=2, has_build=1, has_deploy=1, days_since_push=4 |
| N7 | reproducible_env | **60** | 0.12 | flake=0, flake_lock=0, docker=0, lockfile=1 |
| N8 | repo_foundations | **35** | 0.08 | codeowners=0, gitignore_cats=5(35), security_md=0 |

---

### Pillar 2: Understand — 48.25 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | Haskell → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **80** | 0.15 | readme_lines=164, desc=1, setup=1, usage=1, arch=0, contrib=1 |
| U4 | architecture_docs | **0** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 54.00 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (14 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **50** | 0.30 | ratio=.250 (14 test / 56 source) |
| V2 | test_categorization | **75** | 0.20 | detected_categories=2 [property,spec/bdd] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 82.99 × 0.35 + 48.25 × 0.35 + 54.00 × 0.30
              = 62.12

Constraints: none applied

Penalties: -5
Readiness = 57.12
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 16.50 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | 1 found — AGENTS.md |
| **L2_commits** | L2 | None —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | None —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | Configured | 33 | ✓ linter=1, codeowners=0 | ✓ AI config AGENTS.md: 6/8 categories, includes Architecture + Conventions | Configured but no active AI signals in last 30 PRs/50 commits |
| **Testing** | Configured | 33 | ✓ test execution found in CI workflows | ✓ AI config AGENTS.md: 6/8 categories, includes Testing | Configured but no active AI signals in last 30 PRs/50 commits |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover Haskell | ✓ AI config AGENTS.md: 6/8 categories, includes Security | AI config present, practice not active |
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=10) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✓ 1 AI config files in tree, 0 in submodules | ✗ usage expectations found but no .aiignore | Practice active, no AI config |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/plu-stan` |
| Description | Static Analyzer for PlutusTx based on the Haskell STAN static analyzer |
| Default branch | `main` |
| Private | false |
| Primary language | Haskell (56.3%) |
| Languages | Haskell: 56.3%,HTML: 41.6%,TypeScript: 2%,Shell: 0% |
| Size | 832 KB |
| Open issues | 10 |
| Stars | 4 |
| License | MPL-2.0 |
| Created | 2024-07-02T09:54:19Z |
| Last push | 2026-03-20T16:26:07Z |
| Tree entries | 144 |
| Source files | 56 |
| Test files | 14 |
| Directories | 27 |
| Max depth | 4 |

### Score Summary

```
Navigate   = 82.99  (weight 0.35)
Understand = 48.25  (weight 0.35)
Verify     = 54.00  (weight 0.30)

Readiness_raw = 62.12
Penalties: -5
Readiness = 57.12

Adoption composite = 16.50
  Code: Configured (33), Testing: Configured (33), Security: None (0), Delivery: None (0), Governance: None (0)

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

### Improve AI Understanding (Understand: 48.25/100)

- **Documentation coverage (U2=25):** Add Haddock comments (`{- | -}` / `-- |`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **Architecture docs (U4=0):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

### Strengthen Verification (Verify: 54.00/100)

- **Coverage config (V4=0):** Consider HPC integration or property test coverage reporting. For property-heavy repos, conformance completeness metrics (% of spec rules tested) may be more meaningful than line coverage.

