# AAMM — Sample Report: input-output-hk/Lean-blaster

**Model version:** 1.0 · **Scan date:** 2026-03-25 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO VULNERABILITY MONITORING | See evidence log |
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |
| 🟡 Medium | Active without foundation | AI activity signals found but Configured gate not met (no substantive AI config) |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **23.11 / 100** | Navigate: 58.10, Understand: 30.25, Verify: 24.00. Penalties: -15. |
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

## AI Readiness: 23.11 / 100

### Pillar 1: Navigate — 58.10 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=5, directories=37 |
| N2 | file_granularity | **100** | 0.13 | median_lines=0, large_files=0, per_file_penalty=-0 |
| N3 | module_boundaries | **50** | 0.15 | workspace_files=0, package_manifests=0 |
| N4 | separation_of_concerns | **75** | 0.12 | top_level_dirs=4 (heuristic — override recommended) |
| N5 | code_consistency | **0** | 0.13 | linter=0, formatter=0, ci_enforced=0, configs=0 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=2, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **0** | 0.12 | flake=0, flake_lock=0, docker=0, lockfile=0 |
| N8 | repo_foundations | **20** | 0.08 | codeowners=0, gitignore_cats=2(20), security_md=0 |

---

### Pillar 2: Understand — 30.25 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **40** | 0.30 | Lean — requires manual type safety assessment |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **80** | 0.15 | readme_lines=648, desc=1, setup=1, usage=1, arch=0, contrib=1 |
| U4 | architecture_docs | **0** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 24.00 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (0 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **0** | 0.30 | ratio=0 (0 test / 0 source) |
| V2 | test_categorization | **0** | 0.20 | detected_categories=0 [] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 58.10 × 0.35 + 30.25 × 0.35 + 24.00 × 0.30
              = 38.11

Constraints: none applied

Penalties: -15
Readiness = 23.11
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | **YES** | -10 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 0 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | None —  |
| **L2_commits** | L2 | None —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | 3 found —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | None | 0 | ✗ linter=0, codeowners=0 | ✗ no AI config with Architecture + Conventions | No AI presence |
| **Testing** | None | 0 | ✓ test execution found in CI workflows | ✗ no AI config with Testing category | Practice active, no AI config |
| **Security** | None | 0 | ✗ no security scanning detected | ✗ no AI config with Security category | No AI presence |
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=55) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✗ no AI config files | ✗ no usage expectations or .aiignore | No AI presence |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/Lean-blaster` |
| Description | SMT-based reasoning core for Lean4 |
| Default branch | `main` |
| Private | false |
| Primary language | Lean (99.9%) |
| Languages | Lean: 99.9%,Makefile: 0.1%,Shell: 0.1% |
| Size | 1373 KB |
| Open issues | 55 |
| Stars | 33 |
| License | Apache-2.0 |
| Created | 2025-09-12T12:46:32Z |
| Last push | 2026-03-24T15:24:47Z |
| Tree entries | 250 |
| Source files | 0 |
| Test files | 0 |
| Directories | 37 |
| Max depth | 5 |

### Score Summary

```
Navigate   = 58.10  (weight 0.35)
Understand = 30.25  (weight 0.35)
Verify     = 24.00  (weight 0.30)

Readiness_raw = 38.11
Penalties: -15
Readiness = 23.11

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
| U2 | info | Default score (25) — requires agent file content analysis. | override_recommended |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations

### Start AI Adoption

**Zero AI adoption detected.** Quick wins to establish AI presence:

1. **Add `CLAUDE.md`** (or equivalent AI config) with:
   - Architecture, Conventions, Testing, Security (minimum 3 of 8 categories)

2. **Enable AI-assisted PR review** — lowest risk, highest immediate value. AI reviews documentation, test coverage gaps, and style consistency.

### Improve AI Understanding (Understand: 30.25/100)

- **Documentation coverage (U2=25):** Add doc comments to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **Architecture docs (U4=0):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

### Strengthen Verification (Verify: 24.00/100)

- **Test/source ratio (V1=0):** Ratio is 0 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Test categorization (V2=0):** Expand test types beyond what's currently detected. Add unit tests (if only integration/e2e exist) or property-based tests (e.g., fast-check for TypeScript, QuickCheck for Haskell) for richer AI verification.
- **Coverage config (V4=0):** Add coverage tool + threshold to CI.

