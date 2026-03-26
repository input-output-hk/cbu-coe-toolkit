# AAMM — Sample Report: HarmonicLabs/pebble-lsp

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
| **AI Readiness** | **20.31 / 100** | Navigate: 42.10, Understand: 30.25, Verify: 0. Penalties: -5. |
| **AI Adoption** | **0 / 100** | Code: None, Testing: None, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Traditional** | Low readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │  FERTILE    │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │              │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │ ★           │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## AI Readiness: 20.31 / 100

### Pillar 1: Navigate — 42.10 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **50** | 0.12 | max_depth=3, directories=15 |
| N2 | file_granularity | **0** | 0.13 | median_lines=1253, large_files=1, per_file_penalty=-2 |
| N3 | module_boundaries | **50** | 0.15 | workspace_files=0, package_manifests=0 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=7 (heuristic — override recommended) |
| N5 | code_consistency | **60** | 0.13 | linter=1, formatter=0, ci_enforced=0, configs=1 |
| N6 | cicd_pipeline | **0** | 0.15 | workflows=0, has_build=0, has_deploy=0, days_since_push=10 |
| N7 | reproducible_env | **60** | 0.12 | flake=0, flake_lock=0, docker=0, lockfile=3 |
| N8 | repo_foundations | **20** | 0.08 | codeowners=0, gitignore_cats=3(20), security_md=0 |

---

### Pillar 2: Understand — 30.25 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **40** | 0.30 | TypeScript, tsconfig exists but not fetched — override recommended |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **80** | 0.15 | readme_lines=107, desc=1, setup=0, usage=1, arch=1, contrib=1 |
| U4 | architecture_docs | **0** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 0 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** FAIL (zero tests — capped at 15)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **0** | 0.30 | ratio=0 (0 test / 2 source) |
| V2 | test_categorization | **0** | 0.20 | detected_categories=0 [] (heuristic — override recommended) |
| V3 | ci_test_execution | **0** | 0.30 | ci_test=0, ci_blocking=0 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 42.10 × 0.35 + 30.25 × 0.35 + 0 × 0.30
              = 25.31

Constraints: none applied

Penalties: -5
Readiness = 20.31
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
| **Testing** | None | 0 | ✗ no CI test execution detected | ✗ no AI config with Testing category | No AI presence |
| **Security** | None | 0 | ✗ no security scanning detected | ✗ no AI config with Security category | No AI presence |
| **Delivery** | None | 0 | ✗ build_workflow=false, issues=false (open=0) | ✗ no AI config with Delivery category | No AI presence |
| **Governance** | None | 0 | ✗ no AI config files | ✗ no usage expectations or .aiignore | No AI presence |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `HarmonicLabs/pebble-lsp` |
| Description | N/A |
| Default branch | `main` |
| Private | false |
| Primary language | TypeScript (99.1%) |
| Languages | TypeScript: 99.1%,JavaScript: 0.9% |
| Size | 4794 KB |
| Open issues | 0 |
| Stars | 0 |
| License | Apache-2.0 |
| Created | 2025-03-31T12:34:29Z |
| Last push | 2026-03-15T02:25:32Z |
| Tree entries | 71 |
| Source files | 2 |
| Test files | 0 |
| Directories | 15 |
| Max depth | 3 |

### Score Summary

```
Navigate   = 42.10  (weight 0.35)
Understand = 30.25  (weight 0.35)
Verify     = 0  (weight 0.30)

Readiness_raw = 25.31
Penalties: -5
Readiness = 20.31

Adoption composite = 0
  Code: None (0), Testing: None (0), Security: None (0), Delivery: None (0), Governance: None (0)

Quadrant: Traditional
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 1

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — Agent should sample .ts files for JSDoc/TSDoc comments. | override_recommended |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations

### Start AI Adoption

**Zero AI adoption detected.** Quick wins to establish AI presence:

1. **Add `CLAUDE.md`** (or equivalent AI config) with:
   - Architecture: module boundaries, key abstractions, state management approach
   - Conventions: naming, formatting (prettier config), preferred patterns
   - Testing: framework (jest/vitest), coverage expectations, E2E setup
   - Security: auth flows, sensitive data handling, trust boundaries

2. **Enable AI-assisted PR review** — lowest risk, highest immediate value. AI reviews documentation, test coverage gaps, and style consistency.

### Improve AI Understanding (Understand: 30.25/100)

- **Documentation coverage (U2=25):** Add TSDoc/JSDoc (`/** */`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **Architecture docs (U4=0):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

### Strengthen Verification (Verify: 0/100)

- **Test/source ratio (V1=0):** Ratio is 0 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Test categorization (V2=0):** Expand test types beyond what's currently detected. Add unit tests (if only integration/e2e exist) or property-based tests (e.g., fast-check for TypeScript, QuickCheck for Haskell) for richer AI verification.
- **Coverage config (V4=0):** Add coverage tool + threshold to CI.

