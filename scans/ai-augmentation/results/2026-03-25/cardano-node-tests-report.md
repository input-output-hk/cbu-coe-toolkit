# AAMM — Sample Report: IntersectMBO/cardano-node-tests

**Model version:** 1.0 · **Scan date:** 2026-03-25 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **53.32 / 100** | Navigate: 71.76, Understand: 19.75, Verify: 71.00. Penalties: -0. |
| **AI Adoption** | **16.50 / 100** | Code: Configured, Testing: Configured, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (cardano-node-tests)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## Domain Profile: Blockchain

**Detected via:** description

**AI Value Framing:** AI as adversarial reviewer/challenger/auditor on critical code; quality driver on docs/tests/PRs; code generator only on boilerplate/serialization

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
| Formal spec presence | ✗ | Not detected |
| Conformance testing | ✗ | Not detected |
| Generator discipline | ✗ | cover/classify=0, custom Arbitrary=0, adversarial=0 |
| Concurrency testing (io-sim) | ✗ | io-sim=0 |
| Benchmark regression | ✗ | files=0, dirs=0, CI regression=0 |
| Strict evaluation discipline | ✗ | StrictData/BangPatterns=0 |
| .aiignore on critical paths | ✗ | 0 |

### Domain Risk Flags

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | No benchmark regression detection | Performance-sensitive blockchain code without benchmarks |

---

## AI Readiness: 53.32 / 100

### Pillar 1: Navigate — 71.76 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=7, directories=47 |
| N2 | file_granularity | **92** | 0.13 | median_lines=104, large_files=4, per_file_penalty=-8 |
| N3 | module_boundaries | **50** | 0.15 | workspace_files=0, package_manifests=0 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=10 (heuristic — override recommended) |
| N5 | code_consistency | **40** | 0.13 | linter=0, formatter=0, ci_enforced=1, configs=1 |
| N6 | cicd_pipeline | **50** | 0.15 | workflows=13, has_build=0, has_deploy=0, days_since_push=1 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=1 |
| N8 | repo_foundations | **45** | 0.08 | codeowners=0, gitignore_cats=3(20), security_md=1 |

---

### Pillar 2: Understand — 19.75 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **25** | 0.30 | Python — dynamically typed (override if type hints found) |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **40** | 0.15 | readme_lines=254, desc=1, setup=1, usage=0, arch=0, contrib=0 |
| U4 | architecture_docs | **0** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 71.00 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (108 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **100** | 0.30 | ratio=1.661 (108 test / 65 source) |
| V2 | test_categorization | **25** | 0.20 | detected_categories=0 [] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **60** | 0.20 | coverage_tool=1, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 71.76 × 0.35 + 19.75 × 0.35 + 71.00 × 0.30
              = 53.32

Constraints: none applied

Penalties: -0
Readiness = 53.32
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | NO | -0 | N/A |

---

## AI Adoption: 16.50 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | 2 found — AGENTS.md,CLAUDE.md |
| **L2_commits** | L2 | None —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | None —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | Configured | 33 | ✓ linter=1, codeowners=0 | ✓ AI config AGENTS.md: 5/8 categories, includes Architecture + Conventions | Configured but no active AI signals in last 30 PRs/50 commits |
| **Testing** | Configured | 33 | ✓ test execution found in CI workflows | ✓ AI config AGENTS.md: 5/8 categories, includes Testing | Configured but no active AI signals in last 30 PRs/50 commits |
| **Security** | None | 0 | ✓ security scanning in CI | ✗ no AI config with Security category | Practice active, no AI config |
| **Delivery** | None | 0 | ✗ build_workflow=false, issues=true (open=44) | ✓ AI config AGENTS.md: 5/8 categories, includes Delivery | AI config present, practice not active |
| **Governance** | None | 0 | ✓ 2 AI config files in tree, 0 in submodules | ✗ usage expectations found but no .aiignore | Practice active, no AI config |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `IntersectMBO/cardano-node-tests` |
| Description | System and end-to-end (E2E) tests for cardano-node. |
| Default branch | `master` |
| Private | false |
| Primary language | Python (98.4%) |
| Languages | Python: 98.4%,Shell: 1.5%,Makefile: 0.1%,Nix: 0.1%,CSS: 0% |
| Size | 20779 KB |
| Open issues | 44 |
| Stars | 59 |
| License | Apache-2.0 |
| Created | 2020-08-12T08:06:11Z |
| Last push | 2026-03-24T11:06:41Z |
| Tree entries | 858 |
| Source files | 65 |
| Test files | 108 |
| Directories | 47 |
| Max depth | 7 |

### Score Summary

```
Navigate   = 71.76  (weight 0.35)
Understand = 19.75  (weight 0.35)
Verify     = 71.00  (weight 0.30)

Readiness_raw = 53.32
Penalties: -0
Readiness = 53.32

Adoption composite = 16.50
  Code: Configured (33), Testing: Configured (33), Security: None (0), Delivery: None (0), Governance: None (0)

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


### Blockchain-Specific AI Value

Frame AI as **adversarial reviewer**, not code generator, on critical paths:

| AI Role | Where to Apply | Example |
|---------|---------------|---------|
| **Threat modeler** | Core logic, validation | "What if input is malformed? What if amounts overflow?" |
| **Completeness auditor** | Test coverage | "Spec defines N rules, tests cover M — identify gaps" |
| **Security reviewer** | Auth, crypto, key mgmt | "Review all security-critical paths for common vulnerabilities" |
| **Performance challenger** | Hot paths | "Identify O(n²) patterns, unnecessary allocations, missing caching" |
| **API/interface reviewer** | Module boundaries | "Review error types, input validation, contract consistency" |
| **Documentation driver** | API docs, README, ADRs | "Generate docs for all exported public interfaces" |

**Add `.aiignore`** excluding consensus/crypto paths — signals mature AI governance and prevents AI from generating code in critical modules.

### Improve AI Understanding (Understand: 19.75/100)

- **Documentation coverage (U2=25):** Add doc comments to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **README substance (U3=40):** Add Architecture and Usage sections to README. AI agents read README first — a good README multiplies AI effectiveness across all tasks.
- **Architecture docs (U4=0):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

