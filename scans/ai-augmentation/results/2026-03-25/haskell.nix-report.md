# AAMM — Sample Report: input-output-hk/haskell.nix

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
| **AI Readiness** | **54.99 / 100** | Navigate: 81.80, Understand: 28.75, Verify: 71.00. Penalties: -5. |
| **AI Adoption** | **0 / 100** | Code: None, Testing: None, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (haskell.nix)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## AI Readiness: 54.99 / 100

### Pillar 1: Navigate — 81.80 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=5, directories=999 |
| N2 | file_granularity | **100** | 0.13 | median_lines=38, large_files=0, per_file_penalty=-0 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=18, package_manifests=48 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=16 (heuristic — override recommended) |
| N5 | code_consistency | **0** | 0.13 | linter=0, formatter=0, ci_enforced=1, configs=0 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=8, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=1 |
| N8 | repo_foundations | **35** | 0.08 | codeowners=0, gitignore_cats=4(35), security_md=0 |

---

### Pillar 2: Understand — 28.75 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **40** | 0.30 | Nix — requires manual type safety assessment |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **20** | 0.15 | readme_lines=33, desc=1, setup=0, usage=0, arch=0, contrib=0 |
| U4 | architecture_docs | **50** | 0.15 | adrs=0, architecture_md=2 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 71.00 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (117 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **100** | 0.30 | ratio=3.000 (117 test / 39 source) |
| V2 | test_categorization | **25** | 0.20 | detected_categories=0 [] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **60** | 0.20 | coverage_tool=1, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 81.80 × 0.35 + 28.75 × 0.35 + 71.00 × 0.30
              = 59.99

Constraints: none applied

Penalties: -5
Readiness = 54.99
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
| **Code** | None | 0 | ✗ linter=0, codeowners=0 | ✗ no AI config with Architecture + Conventions | No AI presence |
| **Testing** | None | 0 | ✓ test execution found in CI workflows | ✗ no AI config with Testing category | Practice active, no AI config |
| **Security** | None | 0 | ✗ no security scanning detected | ✗ no AI config with Security category | No AI presence |
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=168) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✗ no AI config files | ✗ no usage expectations or .aiignore | No AI presence |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/haskell.nix` |
| Description | Alternative Haskell Infrastructure for Nixpkgs |
| Default branch | `master` |
| Private | false |
| Primary language | Nix (87.6%) |
| Languages | Nix: 87.6%,Haskell: 11.8%,Shell: 0.6%,C: 0%,Makefile: 0% |
| Size | 24284 KB |
| Open issues | 168 |
| Stars | 622 |
| License | Apache-2.0 |
| Created | 2018-04-20T16:00:09Z |
| Last push | 2026-03-25T00:58:39Z |
| Tree entries | 6523 |
| Source files | 39 |
| Test files | 117 |
| Directories | 999 |
| Max depth | 5 |

### Score Summary

```
Navigate   = 81.80  (weight 0.35)
Understand = 28.75  (weight 0.35)
Verify     = 71.00  (weight 0.30)

Readiness_raw = 59.99
Penalties: -5
Readiness = 54.99

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
| U2 | info | Default score (25) — requires agent file content analysis. | override_recommended |
| V1_V2_mismatch | info | High test ratio (V1=100) but low categorization (V2=25). Many test files exist but few distinct test types detected. May indicate monolithic test suite or detection gaps. | verify_manually |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations

### Start AI Adoption

**Zero AI adoption detected.** Quick wins to establish AI presence:

1. **Add `CLAUDE.md`** (or equivalent AI config) with:
   - Architecture, Conventions, Testing, Security (minimum 3 of 8 categories)

2. **Enable AI-assisted PR review** — lowest risk, highest immediate value. AI reviews documentation, test coverage gaps, and style consistency.

### Improve AI Understanding (Understand: 28.75/100)

- **Documentation coverage (U2=25):** Add doc comments to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **README substance (U3=20):** Add Architecture and Usage sections to README. AI agents read README first — a good README multiplies AI effectiveness across all tasks.

